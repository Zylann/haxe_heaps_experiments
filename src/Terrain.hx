import haxe.Exception;
import haxe.ds.Vector;
import util.MPSCList;
import util.Vector3i;
import util.Box3i;
import util.Task;
import util.ThreadedTaskRunner;

class Terrain {
	public var sizeInChunks(default, null): Vector3i;

	public var renderer: TerrainRenderer;

	var generator: ChunkGenerator;

	// Fixed-size for now
	var chunks: Vector<TerrainChunk>;
	var taskRunner: ThreadedTaskRunner;
	var chunkLoadingOutput: MPSCList<LoadChunkTask> = new MPSCList<LoadChunkTask>();

	public function new(sizeInChunks: Vector3i, taskRunner: ThreadedTaskRunner) {
		if (!sizeInChunks.isValidSize()) {
			throw new Exception("Invalid size");
		}
		if (sizeInChunks.getVolume() > 65536) {
			throw new Exception("Too big");
		}
		this.sizeInChunks = sizeInChunks;
		chunks = new Vector<TerrainChunk>(sizeInChunks.getVolume());

		this.taskRunner = taskRunner;

		generator = new ChunkGenerator();
	}

	public inline function getChunk(cpos: Vector3i): TerrainChunk {
		if (!sizeInChunks.containsPoint(cpos)) {
			return null;
		}
		var index = cpos.getXYZIndex(sizeInChunks);
		return chunks[index];
	}

	public function getVoxel(x: Int, y: Int, z: Int, defaultValue: Int = 0): Int {
		var pos = new Vector3i(x, y, z);
		var cpos = pos >> Constants.CHUNK_SIZE_PO2;
		var chunk = getChunk(cpos);
		if (chunk == null) {
			return defaultValue;
		}
		var rpos = pos & Constants.CHUNK_SIZE_MASK;
		return chunk.voxels.getVoxel(rpos.x, rpos.y, rpos.z);
	}

	public function loadAllChunks() {
		var tasks = new Array<util.Task>();

		for (cz in 0...sizeInChunks.z) {
			for (cy in 0...sizeInChunks.y) {
				for (cx in 0...sizeInChunks.x) {
					var chunkIndex = new Vector3i(cx, cy, cz).getXYZIndex(sizeInChunks);
					if (chunks[chunkIndex] != null) {
						continue;
					}

					// TODO Fill in interest position
					var task = new LoadChunkTask(
						new Vector3i(cx, cy, cz),
						Vector3i.splat(0),
						generator,
						chunkLoadingOutput
					);
					tasks.push(task);
				}
			}
		}

		taskRunner.pushTasks(tasks);
	}

	public function isAreaLoaded(bounds: h3d.col.Bounds): Bool {
		var box = Box3i.fromFloatBounds(bounds);
		box.downscale(Constants.CHUNK_SIZE);
		box.clip(new Box3i(0, 0, 0, sizeInChunks.x, sizeInChunks.y, sizeInChunks.z));

		for (cz in box.minZ...box.maxZ) {
			for (cy in box.minY...box.maxY) {
				for (cx in box.minX...box.maxX) {
					var chunk = getChunk(new Vector3i(cx, cy, cz));
					if (chunk == null) {
						return false;
					}
				}
			}
		}
		return true;
	}

	public function update() {
		chunkLoadingOutput.beginConsume();

		for (task in chunkLoadingOutput.readerList) {
			var chunkIndex = new Vector3i(task.chunkX, task.chunkY, task.chunkZ).getXYZIndex(sizeInChunks);

			if (chunks[chunkIndex] == null) {
				chunks[chunkIndex] = task.outputChunk;
			} else {
				throw new Exception("Didn't expect to have to load a chunk that is already loaded");
			}

			renderer.onChunkLoaded(task.chunkX, task.chunkY, task.chunkZ);
		}

		chunkLoadingOutput.endConsume();
	}
}

class TerrainChunk {
	public var voxels: VoxelBuffer;
	public var cowRefCount: haxe.atomic.AtomicInt;

	public inline function new() {
		voxels = VoxelBuffer.makeCubic(Constants.CHUNK_SIZE);
		cowRefCount = new haxe.atomic.AtomicInt(1);
	}

	public inline function clone(): TerrainChunk {
		var d = new TerrainChunk();
		d.voxels = voxels.clone();
		return d;
	}

	// Call this when giving access to a new thread
	public inline function acquireShared() {
		cowRefCount.add(1);
	}

	// Call this when releasing access from a thread (must not acquire ever again after that)
	public inline function releaseShared() {
		cowRefCount.sub(1);
	}

	// Call this before modifying voxels.
	// The returned value must replace the reference the caller has
	public inline function makeExclusive(): TerrainChunk {
		var rc = cowRefCount.load();
		if (rc > 1) {
			// Another thread can potentially read this. Make a local copy.
			return clone();
		}
		return this;
	}
}

class LoadChunkTask extends util.Task {
	public var chunkX: Int;
	public var chunkY: Int;
	public var chunkZ: Int;

	var generator: ChunkGenerator;

	var outputList: MPSCList<LoadChunkTask>;

	public var outputChunk: TerrainChunk;

	public inline function new(
		chunkPosition: Vector3i,
		interestChunkPosition: Vector3i,
		generator: ChunkGenerator,
		outputList: MPSCList<LoadChunkTask>
	) {
		chunkX = chunkPosition.x;
		chunkY = chunkPosition.y;
		chunkZ = chunkPosition.z;
		this.outputList = outputList;
		priority = 100 - chunkPosition.chebychevDistance(interestChunkPosition);
		this.generator = generator;
	}

	public override function run(context: TaskContext) {
		var originX = chunkX * Constants.CHUNK_SIZE;
		var originY = chunkY * Constants.CHUNK_SIZE;
		var originZ = chunkZ * Constants.CHUNK_SIZE;

		outputChunk = new TerrainChunk();

		generator.generateChunkVoxels(outputChunk.voxels, originX, originY, originZ);

		outputList.push(this);
	}
}
