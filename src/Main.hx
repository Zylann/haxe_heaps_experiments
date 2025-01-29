import h3d.mat.Material;
import h3d.scene.Mesh;

class Constants {
	public static inline var CHUNK_SIZE = 32;
}

class Main extends hxd.App {
	var chunkMaterial: Material;
	var debugDisplay: DebugDisplay;
	var playerCamera: PlayerCamera;
	// var loadChunkTaskPool: Array<LoadChunkTask> = [];

	var chunkLoadingOutput: MPSCList<LoadChunkTask> = new MPSCList<LoadChunkTask>();
	var taskRunner: ThreadedTaskRunner;

	function new() {
		var backgroundThreadCount = 4;

		taskRunner = new ThreadedTaskRunner(backgroundThreadCount);
		LoadChunkTask.initThreadLocals(backgroundThreadCount);

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

		var tasks : Array<Task> = [];
		var cr = 8;
		for (cx in -cr...cr) {
			for (cy in -cr...cr) {
				for (cz in -2...4) {
					var task = new LoadChunkTask(cx, cy, cz, 0, 0, 0, chunkLoadingOutput);
					tasks.push(task);
				}
			}
		}

		taskRunner.pushTasks(tasks);

		var camera = s3d.camera;
		camera.fovY = 80;
	}

	override function update(dt:Float) {
		super.update(dt);

		playerCamera.update(dt);

		updateChunkLoading();

		debugDisplay.update(dt, taskRunner.getPendingTasksCount());
	}

	function updateChunkLoading() {
		chunkLoadingOutput.beginConsume();

		for (task in chunkLoadingOutput.readerList) {
			var meshPrim = task.outputPrim;

			// Empty?
			if (meshPrim != null) {
				var mesh = new Mesh(meshPrim, chunkMaterial, s3d);

				var originX = task.chunkX * Constants.CHUNK_SIZE;
				var originY = task.chunkY * Constants.CHUNK_SIZE;
				var originZ = task.chunkZ * Constants.CHUNK_SIZE;

				mesh.setPosition(originX, originY, originZ);
			}

			// loadChunkTaskPool.push(task);
		}
		
		chunkLoadingOutput.endConsume();
	}

	// TODO Is it the right function to overload to handle shutdown?
	override function dispose() {
		taskRunner.dispose();
		super.dispose();
	}

	static function main() {
		new Main();
	}
}
