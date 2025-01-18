import h3d.mat.Material;
import h3d.scene.Mesh;

class Main extends hxd.App {
	static inline var CHUNK_SIZE = 32;

	var pendingChunks:Array<Vector3i> = [];
	var chunkMaterial: Material;
	var meshingVoxelBuffer: VoxelBuffer;
	var debugDisplay: DebugDisplay;
	var playerCamera: PlayerCamera;

	function new() {
		h3d.mat.MaterialSetup.current = new h3d.mat.PbrMaterialSetup();
		super();
	}

	override function init() {
		debugDisplay = new DebugDisplay(s2d);
		playerCamera = new PlayerCamera(s3d);

		{
			var prim = new h3d.prim.Cube();
			prim.translate(-0.5, -0.5, -0.5);
			prim.addNormals();
			var meshInstance = new Mesh(prim, s3d);
			meshInstance.material.color.setColor(0xffaa44);
		}

		// var lightSystem = cast(s3d.lightSystem, h3d.scene.fwd.LightSystem);
		// lightSystem.ambientLight.set(0.2, 0.2, 0.2);
		var lightSystem = cast(s3d.lightSystem, h3d.scene.pbr.LightSystem);

		var pbrRenderer = cast(s3d.renderer, h3d.scene.pbr.Renderer);
		// pbrRenderer.effects.push(new h3d.shader.Di);
		// TODO I'd like shadows to be darker while not making the sky dimmer.
		pbrRenderer.env.power = 0.5;

		// TODO How do I get fog?
		// I could use a custom shader on all objects, but it sounds a bit tedious.
		// It could be a screen effect, but apparently it requires a custom renderer?

		// Let's do voxels, because of course

		hxd.Res.initEmbed();

		var sunLight = new h3d.scene.pbr.DirLight(new h3d.Vector(1, 1.25, -1.5), s3d);
		sunLight.shadows.mode = Dynamic;
		sunLight.shadows.bias = 0.005;

		var atlas = hxd.Res.atlas.toTexture();
		chunkMaterial = h3d.mat.Material.create(atlas);
		chunkMaterial.texture.filter = h3d.mat.Data.Filter.Nearest;
		chunkMaterial.mainPass.enableLights = true;
		chunkMaterial.shadows = true;

		meshingVoxelBuffer = VoxelBuffer.makeCubic(CHUNK_SIZE + 2 * Mesher.PAD);

		var cr = 8;
		for (cx in -cr...cr) {
			for (cy in -cr...cr) {
				for (cz in -2...4) {
					pendingChunks.push(new Vector3i(cx, cy, cz));
				}
			}
		}

		pendingChunks.sort(comparePendingChunks);

		var camera = s3d.camera;
		camera.fovY = 80;
	}

	function comparePendingChunks(a:Vector3i, b:Vector3i):Int {
		// TODO Take this from camera location and don't allocate
		var interest = new Vector3i(0, 0, 0);
		var da = a.distanceToSq(interest);
		var db = b.distanceToSq(interest);
		// Closest comes last
		if (da < db) {
			return 1;
		} else if (da > db) {
			return -1;
		}
		return 0;
	}

	override function update(dt:Float) {
		super.update(dt);

		playerCamera.update(dt);

		updateChunkLoading();

		debugDisplay.update(dt, pendingChunks.length);
	}

	function updateChunkLoading() {
		var timeBeforeS = haxe.Timer.stamp();
		final budgetS = 0.25 / 60.0;

		while (pendingChunks.length > 0) {
			var cpos : Vector3i = pendingChunks.pop();
		
			var originX = cpos.x * CHUNK_SIZE;
			var originY = cpos.y * CHUNK_SIZE;
			var originZ = cpos.z * CHUNK_SIZE;

			ChunkGenerator.generateChunkVoxels(meshingVoxelBuffer, originX, originY, originZ);

			var meshPrim = Mesher.build(meshingVoxelBuffer);
			
			// Empty?
			if (meshPrim != null) {
				var mesh = new Mesh(meshPrim, chunkMaterial, s3d);
				mesh.setPosition(originX, originY, originZ);
			}

			var nowS = haxe.Timer.stamp();
			if (nowS - timeBeforeS >= budgetS) {
				break;
			}
		}
	}

	static function main() {
		new Main();
	}
}
