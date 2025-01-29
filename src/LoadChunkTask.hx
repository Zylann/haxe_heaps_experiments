import Main.Constants;
import Task.TaskContext;

class LoadChunkTask extends Task {
	public var chunkX: Int;
	public var chunkY: Int;
	public var chunkZ: Int;
	var outputList: MPSCList<LoadChunkTask>;
	public var outputPrim: VoxelMeshPrimitive;

	static var meshingVoxelBufferPerThread : Array<VoxelBuffer> = [];

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
		interestX: Int, 
		interestY: Int, 
		interestZ: Int, 
		outputList: MPSCList<LoadChunkTask>
	) {
		chunkX = cx;
		chunkY = cy;
		chunkZ = cz;
		this.outputList = outputList;
		priority = 100 - Vector3i.cChebychevDistance(cx, cy, cz, interestX, interestY, interestZ);
	}

	public override function run(context:TaskContext) {
		var originX = chunkX * Constants.CHUNK_SIZE - Mesher.PAD;
		var originY = chunkY * Constants.CHUNK_SIZE - Mesher.PAD;
		var originZ = chunkZ * Constants.CHUNK_SIZE - Mesher.PAD;

		var meshingVoxelBuffer = meshingVoxelBufferPerThread[context.threadIndex];

		ChunkGenerator.generateChunkVoxels(meshingVoxelBuffer, originX, originY, originZ);

		outputPrim = Mesher.build(meshingVoxelBuffer);

		outputList.push(this);
	}
}
