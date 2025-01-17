import hxd.IndexBuffer;
import hxd.Math;

class Mesher {
	public static inline var PAD = 1;
	public static inline var ATLAS_TILES_PER_ROW = 4;

	static inline var AIR = 0;

	// Takes a padded 3D buffer of voxel data and turns it into a cubic voxel mesh.
	public static function build(voxels:VoxelBuffer):h3d.prim.MeshPrimitive {
		var vertices = new hxd.FloatBuffer();
		var quadCount = 0;

		var minX = 0;
		var minY = 0;
		var minZ = 0;
		var maxX = 0;
		var maxY = 0;
		var maxZ = 0;
		var boundsInitialized = false;

		var tileSizeNorm = 1.0 / ATLAS_TILES_PER_ROW;

		for (z in PAD...voxels.sizeZ - PAD) {
			for (y in PAD...voxels.sizeY - PAD) {
				for (x in PAD...voxels.sizeX - PAD) {
					// TODO Optimize: could be unchecked
					final v = voxels.getVoxel(x, y, z);
					if (v == AIR) {
						continue;
					}

					var hasSide = false;

					for (sideIndex in 0...Cube.SIDE_COUNT) {
						final sideNormal = Cube.sideNormals[sideIndex];
						final normalX = sideNormal[0];
						final normalY = sideNormal[1];
						final normalZ = sideNormal[2];

						// TODO Optimize: could be unchecked
						final nv = voxels.getVoxel(x + normalX, y + normalY, z + normalZ);
						if (nv != AIR) {
							continue;
						}

						hasSide = true;
						var sideVertices = Cube.sideVertices[sideIndex];

						for (i in 0...4) {
							final j = i * 3;

							// Position
							vertices.push(x - PAD + sideVertices[j + 0]);
							vertices.push(y - PAD + sideVertices[j + 1]);
							vertices.push(z - PAD + sideVertices[j + 2]);

							// Normal
							vertices.push(normalX);
							vertices.push(normalY);
							vertices.push(normalZ);

							// UV
							// TODO Eventually needs a table storing texture info for each voxel ID
							vertices.push((v - 1 + Cube.sideUVs[i][0]) * tileSizeNorm);
							vertices.push((Cube.sideUVs[i][1]) * tileSizeNorm);
						}

						quadCount += 1;
					}

					if (hasSide) {
						if (boundsInitialized) {
							minX = Math.imin(x, minX);
							minY = Math.imin(y, minY);
							minZ = Math.imin(z, minZ);

							maxX = Math.imax(x, minX);
							maxY = Math.imax(y, minY);
							maxZ = Math.imax(z, minZ);
						} else {
							minX = x;
							minY = y;
							minZ = z;

							maxX = x;
							maxY = y;
							maxZ = z;

							boundsInitialized = true;
						}
					}
				}
			}
		}

		if (vertices.length == 0) {
			return null;
		}

		// Generate index buffer, assuming we only use quads
		// TODO Optimization: could we re-use the same index buffer?
		// Doing this would need the ability to specify a custom triangle count in meshes,
		// instead of leaving it to the actual length of the index buffer
		var indices = new IndexBuffer();
		indices.grow(quadCount * 6);
		for (q in 0...quadCount) {
			var ii = q * 6;
			var i = q * 4;
			indices[ii + 0] = i + 1;
			indices[ii + 1] = i + 2;
			indices[ii + 2] = i + 0;
			indices[ii + 3] = i + 2;
			indices[ii + 4] = i + 3;
			indices[ii + 5] = i + 0;
		}

		var bounds = new h3d.col.Bounds();
		bounds.xMin = minX - PAD;
		bounds.yMin = minY - PAD;
		bounds.zMin = minZ - PAD;
		bounds.xMax = maxX - PAD + 1;
		bounds.yMax = maxY - PAD + 1;
		bounds.zMax = maxZ - PAD + 1;

		var prim = new VoxelMeshPrimitive(vertices, indices, bounds);
		return prim;
	}
}
