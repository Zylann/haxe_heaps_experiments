import fnl.FastNoiseLite;

class ChunkGenerator {
	var noise1: Noise;
	var noise2: Noise;

	public function new() {
		var seed = 131183;

		noise1 = new Noise(seed);
		noise1.frequency = 1.0 / 200.0;
		noise1.fractalType = FractalType.FBm;
		noise1.octaves = 4;

		noise2 = new Noise(seed + 1);
		noise2.frequency = 1.0 / 50.0;
		noise2.fractalType = FractalType.FBm;
		noise2.octaves = 3;
	}

	public function generateChunkVoxels(voxels: VoxelBuffer, originX: Int, originY: Int, originZ: Int) {
		for (ry in 0...voxels.sizeY) {
			var y = originY + ry;
			for (rx in 0...voxels.sizeX) {
				var x = originX + rx;

				var height = 50.0 + 30.0 * noise1.getNoise2D(x, y);
				var n2 = noise2.getNoise2D(x, y);

				for (rz in 0...voxels.sizeZ) {
					var z = originZ + rz;

					var sd = z - height;

					if (sd < 0.0) {
						var b = 1;
						if (n2 > 0.1) {
							b = 2;
						}

						voxels.setVoxel(rx, ry, rz, b);
					} else {
						voxels.setVoxel(rx, ry, rz, 0);
					}
				}
			}
		}
	}
}
