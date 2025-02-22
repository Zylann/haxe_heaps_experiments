import h3d.scene.Scene;
import h3d.scene.Mesh;
import Task.TaskContext;
import Terrain.TerrainChunk;
import haxe.ds.Vector;
import haxe.Exception;
import h3d.mat.Material;

class TerrainRenderer {
	var chunks: Array<TerrainRendererChunk>;
	var chunkNeighborCountersGrid: VoxelBuffer;
	var chunkFlagsGrid: VoxelBuffer;
	var terrain: Terrain;
	var scene: h3d.scene.Scene;
	var taskRunner: ThreadedTaskRunner;
	var meshingTasksOutput: MPSCList<MeshChunkTask>;
	var tasksToSchedule: Array<Task> = [];
	var material: Material;

	static inline var READY_COUNT = 3 * 3 * 3;

	public function new(terrain: Terrain, scene: h3d.scene.Scene, taskRunner: ThreadedTaskRunner, material: Material) {
		this.terrain = terrain;
		var s = terrain.sizeInChunks;

		chunks = [];
		chunks.resize(s.getVolume());

		chunkNeighborCountersGrid = new VoxelBuffer(s.x, s.y, s.z);
		chunkFlagsGrid = new VoxelBuffer(s.x, s.y, s.z);

		this.taskRunner = taskRunner;

		meshingTasksOutput = new MPSCList<MeshChunkTask>();

		this.material = material;
		this.scene = scene;
	}

	public function update() {
		if (tasksToSchedule.length > 0) {
			taskRunner.pushTasks(tasksToSchedule);
			tasksToSchedule.resize(0);
		}

		processChunkUpdates();
	}

	// Is that the same as hxd.Math.umod?
	inline function wrap(x: Int, d: Int): Int {
		return ((x % d) + d) % d;
	}

	public function onChunkLoaded(cposX: Int, cposY: Int, cposZ: Int) {
		var tcs = terrain.sizeInChunks;

		for (ncz in cposZ - 1...cposZ + 2) {
			for (ncy in cposY - 1...cposY + 2) {
				for (ncx in cposX - 1...cposX + 2) {
					// Note, this technique is usually for streaming infinite terrain,
					// but it turns out it might work too for finite terrain,
					// as long as all chunks are expected to be visible (counters at the edges would otherwise never
					// reach 27 because there are no actual neighbors, but wrapping makes it so)
					var wcx = wrap(ncx, tcs.x);
					var wcy = wrap(ncy, tcs.y);
					var wcz = wrap(ncz, tcs.z);

					var i = chunkNeighborCountersGrid.getIndex(wcx, wcy, wcz);
					var s = chunkNeighborCountersGrid.getVoxelAtIndex(i);
					s += 1;
					if (s > READY_COUNT) {
						throw new Exception("Unexpected count");
					}
					chunkNeighborCountersGrid.setVoxelAtIndex(i, s);

					if (s == READY_COUNT) {
						requestMesh(wcx, wcy, wcz);
					}
				}
			}
		}
	}

	function requestMesh(cposX: Int, cposY: Int, cposZ: Int) {
		var cpos = new Vector3i(cposX, cposY, cposZ);
		var chunkIndex = cpos.getXYZIndex(terrain.sizeInChunks);

		var chunkFlags = chunkFlagsGrid.getVoxelAtIndex(chunkIndex);
		if ((chunkFlags & TerrainRendererChunk.FLAG_MESHING) != 0) {
			// Already requested, just mark it so we update it again when the response arrives.
			chunkFlagsGrid.setVoxelAtIndex(chunkIndex, chunkFlags | TerrainRendererChunk.FLAG_MODIFIED_WHILE_MESHING);
		}

		chunkFlags |= TerrainRendererChunk.FLAG_MESHING;
		chunkFlagsGrid.setVoxelAtIndex(chunkIndex, chunkFlags);

		var nchunks = new Vector<TerrainChunk>(3 * 3 * 3);
		{
			var i: Int = 0;
			for (ncz in cposZ - 1...cposZ + 2) {
				for (ncy in cposY - 1...cposY + 2) {
					for (ncx in cposX - 1...cposX + 2) {
						var chunk = terrain.getChunk(new Vector3i(ncx, ncy, ncz));
						nchunks[i] = chunk;
						i += 1;
					}
				}
			}
		}

		// TODO Fill in interest position
		var task = new MeshChunkTask(cposX, cposY, cposZ, nchunks, 0, 0, 0, meshingTasksOutput);
		tasksToSchedule.push(task);
	}

	function processChunkUpdates() {
		meshingTasksOutput.beginConsume();

		for (task in meshingTasksOutput.readerList) {
			var meshPrim = task.outputPrim;

			var chunkPos = new Vector3i(task.chunkX, task.chunkY, task.chunkZ);
			var chunkIndex = chunkPos.getXYZIndex(terrain.sizeInChunks);
			var chunk = chunks[chunkIndex];

			if (meshPrim == null) {
				// Empty
				// trace('Mesh ${chunkPos} is empty');

				if (chunk != null) {
					chunks[chunkIndex] = null;
					chunk.dispose();
				}
			} else {
				// trace('Mesh ${chunkPos} has stuff');

				if (chunk == null) {
					chunk = new TerrainRendererChunk(scene, chunkPos.x, chunkPos.y, chunkPos.z, meshPrim, material);
					chunks[chunkIndex] = chunk;
				} else {
					chunk.setMeshPrim(meshPrim);
				}
			}

			var chunkFlags = chunkFlagsGrid.getVoxelAtIndex(chunkIndex);
			chunkFlags &= ~TerrainRendererChunk.FLAG_MESHING;

			if ((chunkFlags & TerrainRendererChunk.FLAG_MODIFIED_WHILE_MESHING) != 0) {
				chunkFlags &= ~TerrainRendererChunk.FLAG_MODIFIED_WHILE_MESHING;
				requestMesh(chunkPos.x, chunkPos.y, chunkPos.z);
			}

			chunkFlagsGrid.setVoxelAtIndex(chunkIndex, chunkFlags);
		}

		meshingTasksOutput.endConsume();
	}
}

class TerrainRendererChunk {
	var mesh: Mesh;

	public static inline var FLAG_MESHING = 1;
	public static inline var FLAG_MODIFIED_WHILE_MESHING = 2;

	public function new(scene: Scene, cx: Int, cy: Int, cz: Int, initialPrim: VoxelMeshPrimitive, material: Material) {
		mesh = new h3d.scene.Mesh(initialPrim, material, scene);

		var originX = cx * Constants.CHUNK_SIZE;
		var originY = cy * Constants.CHUNK_SIZE;
		var originZ = cz * Constants.CHUNK_SIZE;

		mesh.setPosition(originX, originY, originZ);
	}

	public function setMeshPrim(prim: VoxelMeshPrimitive) {
		mesh.primitive = prim;
	}

	public function dispose() {
		mesh.remove();
	}
}

class MeshChunkTask extends Task {
	public var chunkX: Int;
	public var chunkY: Int;
	public var chunkZ: Int;
	public var chunks: Vector<TerrainChunk>;

	var outputList: MPSCList<MeshChunkTask>;

	public var outputPrim: VoxelMeshPrimitive;

	static var meshingVoxelBufferPerThread: Array<VoxelBuffer> = [];

	public static function initThreadLocals(threadCount: Int) {
		meshingVoxelBufferPerThread.resize(threadCount);

		for (i in 0...meshingVoxelBufferPerThread.length) {
			var vb = VoxelBuffer.makeCubic(Constants.CHUNK_SIZE + 2 * Mesher.PAD);
			meshingVoxelBufferPerThread[i] = vb;
		}
	}

	public function new(
		cx: Int,
		cy: Int,
		cz: Int,
		chunks: Vector<TerrainChunk>,
		interestX: Int,
		interestY: Int,
		interestZ: Int,
		outputList: MPSCList<MeshChunkTask>
	) {
		if (chunks.length != 3 * 3 * 3) {
			throw new Exception("Invalid chunks array length");
		}
		chunkX = cx;
		chunkY = cy;
		chunkZ = cz;
		for (chunk in chunks) {
			// Chunks can be null if on an edge of the terrain
			if (chunk != null) {
				chunk.acquireShared();
			}
		}
		this.chunks = chunks;
		this.outputList = outputList;
		priority = 100 - new Vector3i(cx, cy, cz).chebychevDistance(new Vector3i(interestX, interestY, interestZ));
	}

	public override function run(context: TaskContext) {
		var meshingVoxelBuffer = meshingVoxelBufferPerThread[context.threadIndex];

		{
			meshingVoxelBuffer.fill(0);

			var srcI = 0;
			for (rcz in -1...2) {
				for (rcy in -1...2) {
					for (rcx in -1...2) {
						var src = chunks[srcI];
						srcI += 1;

						if (src != null) {
							// TODO The formatter breaks this in unexpected ways
							// https://github.com/HaxeCheckstyle/haxe-formatter/issues/685
							// @formatter:off
							meshingVoxelBuffer.paste(
								src.voxels,
								rcx * Constants.CHUNK_SIZE + Mesher.PAD,
								rcy * Constants.CHUNK_SIZE + Mesher.PAD,
								rcz * Constants.CHUNK_SIZE + Mesher.PAD);
							// @formatter:on
							src.releaseShared();
						}
						// else {
						//     meshingVoxelBuffer.fillArea(
						//         rcx * Constants.CHUNK_SIZE,
						//         rcy * Constants.CHUNK_SIZE,
						//         rcz * Constants.CHUNK_SIZE,
						//         Constants.CHUNK_SIZE,
						//         Constants.CHUNK_SIZE,
						//         Constants.CHUNK_SIZE,
						//         0
						//     );
						// }
					}
				}
			}
		}

		outputPrim = Mesher.build(meshingVoxelBuffer);

		outputList.push(this);
	}
}
