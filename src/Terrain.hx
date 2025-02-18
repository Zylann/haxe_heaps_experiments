import Task.TaskContext;
import haxe.Exception;
import haxe.ds.Vector;

class Terrain {
	public var sizeInChunks(default, null):Vector3i;

    public var renderer: TerrainRenderer;

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
    }

    public inline function getChunk(cpos: Vector3i): TerrainChunk {
        if (!sizeInChunks.containsPoint(cpos)) {
            return null;
        }
        var index = cpos.getXYZIndex(sizeInChunks);
        return chunks[index];
    }

    public function loadAllChunks() {
        var tasks = new Array<Task>();

        for(cz in 0...sizeInChunks.z) {
            for(cy in 0...sizeInChunks.y) {
                for(cx in 0...sizeInChunks.x) {
                    var chunkIndex = new Vector3i(cx, cy, cz).getXYZIndex(sizeInChunks);
                    if (chunks[chunkIndex] != null) {
                        continue;
                    }

                    // TODO Fill in interest position
                    var task = new LoadChunkTask(cx, cy, cz, 0, 0, 0, chunkLoadingOutput);
					tasks.push(task);
                }
            }
        }

        taskRunner.pushTasks(tasks);
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

class LoadChunkTask extends Task {
	public var chunkX: Int;
	public var chunkY: Int;
	public var chunkZ: Int;
	var outputList: MPSCList<LoadChunkTask>;
	public var outputChunk: TerrainChunk;

	public function new(
		cx: Int, 
		cy: Int, 
		cz: Int, 
		interestX: Int, 
		interestY: Int, 
		interestZ: Int, 
		outputList: MPSCList<LoadChunkTask>
	) {
		chunkX = cx;
		chunkY = cy;
		chunkZ = cz;
		this.outputList = outputList;
		priority = 100 - new Vector3i(cx, cy, cz).chebychevDistance(new Vector3i(interestX, interestY, interestZ));
	}

	public override function run(context:TaskContext) {
		var originX = chunkX * Constants.CHUNK_SIZE;
		var originY = chunkY * Constants.CHUNK_SIZE;
		var originZ = chunkZ * Constants.CHUNK_SIZE;

        outputChunk = new TerrainChunk();

		ChunkGenerator.generateChunkVoxels(outputChunk.voxels, originX, originY, originZ);

		outputList.push(this);
	}
}

