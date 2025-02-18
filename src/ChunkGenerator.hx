import hxd.Perlin;

class ChunkGenerator {
	public static function generateChunkVoxels(voxels:VoxelBuffer, originX:Int, originY:Int, originZ:Int) {
		var perlin = new Perlin();
		var seed = 131183;

		// TODO Apparently hxd.Perlin returns garbage if any coordinate is negative.
		// This is not good for infinite terrain usage.
		var noiseOffsetX = 1000.0;
		var noiseOffsetY = 1000.0;

		for (ry in 0...voxels.sizeY) {
			var y = originY + ry;
			for (rx in 0...voxels.sizeX) {
				var x = originX + rx;

				var height = 50 + 30.0 * perlin.perlin(seed, x * 0.01 + noiseOffsetX, y * 0.01 + noiseOffsetY, 4);
				var n2 = perlin.perlin(seed + 1, x * 0.02 + noiseOffsetX, y * 0.02 + noiseOffsetX, 3);

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
