import hxd.Perlin;
import hxd.Timer;
import h3d.scene.fwd.DirLight;
import h3d.scene.Mesh;
import hxd.res.DefaultFont;

class Main extends hxd.App {
	static inline var DEBUG_FPS_UPDATE_INTERVAL = 0.25;

	var debugText:h2d.Text;
	var time:Float;
	var debugTimeBeforeFPSUpdate = 0.0;

	override function init() {
		// var prim = new h3d.prim.MeshPrimitive
		debugText = new h2d.Text(DefaultFont.get(), s2d);
		debugText.text = "Hello World!";

		var prim = new h3d.prim.Cube();
		prim.translate(-0.5, -0.5, -0.5);
		prim.addNormals();
		var meshInstance = new Mesh(prim, s3d);
		meshInstance.material.color.setColor(0xffaa44);

		var sunLight = new DirLight(new h3d.Vector(1, 1.25, -1.5), s3d);
		var lightSystem = cast(s3d.lightSystem, h3d.scene.fwd.LightSystem);
		lightSystem.ambientLight.set(0.1, 0.1, 0.1);

		// Let's do voxels, because of course

		hxd.Res.initEmbed();

		var atlas = hxd.Res.atlas.toTexture();
		var voxelMaterial = h3d.mat.Material.create(atlas);
		voxelMaterial.texture.filter = h3d.mat.Data.Filter.Nearest;

		var chunkSize = 16;
		var voxels = VoxelBuffer.makeCubic(chunkSize + 2 * Mesher.PAD);

		var cr = 16;
		for (cx in -cr...cr) {
			for (cy in -cr...cr) {
				for (cz in -2...4) {
					var originX = cx * chunkSize;
					var originY = cy * chunkSize;
					var originZ = cz * chunkSize;
					generateChunkVoxels(voxels, originX - Mesher.PAD, originY - Mesher.PAD, originZ - Mesher.PAD);
					var voxelPrim = Mesher.build(voxels);
					var voxelMesh = new Mesh(voxelPrim, s3d);
					voxelMesh.setPosition(originX, originY, originZ);
					voxelMesh.material = voxelMaterial;
				}
			}
		}

		var camera = s3d.camera;
		camera.fovY = 80;
	}

	static function generateChunkVoxels(voxels:VoxelBuffer, originX:Int, originY:Int, originZ:Int) {
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

				var n1 = 40.0 * perlin.perlin(seed, x * 0.01 + noiseOffsetX, y * 0.01 + noiseOffsetY, 4);
				var n2 = perlin.perlin(seed + 1, x * 0.02 + noiseOffsetX, y * 0.02 + noiseOffsetX, 3);

				for (rz in 0...voxels.sizeZ) {
					var z = originZ + rz;

					// var sd = z - 10 + 4.0 * (Math.sin(x * 0.2) + Math.cos(y * 0.2));
					var sd = z - 10 + n1;

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

	override function update(dt:Float) {
		super.update(dt);
		time += dt * 0.2;

		//    Z
		//    |
		//    o---X
		//   /
		//  Y
		var camDistance = 120.0;
		var camera = s3d.camera;
		camera.pos.set(camDistance * Math.cos(time), camDistance * Math.sin(time), 50.0);

		debugTimeBeforeFPSUpdate -= dt;
		if (debugTimeBeforeFPSUpdate <= 0.0) {
			debugTimeBeforeFPSUpdate = DEBUG_FPS_UPDATE_INTERVAL;
			debugText.text = 'FPS: ${Timer.fps()}';
		}
	}

	static function main() {
		new Main();
	}
}
