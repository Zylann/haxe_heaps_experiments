import TerrainRenderer.MeshChunkTask;
import h3d.scene.Mesh;

class Main extends hxd.App {
	var debugDisplay: DebugDisplay;
	var player: Player;
	var terrain: Terrain;
	var terrainRenderer: TerrainRenderer;
	var taskRunner: ThreadedTaskRunner;

	function new() {
		var backgroundThreadCount = 4;

		taskRunner = new ThreadedTaskRunner(backgroundThreadCount);

		MeshChunkTask.initThreadLocals(backgroundThreadCount);

		h3d.mat.MaterialSetup.current = new h3d.mat.PbrMaterialSetup();

		super();
	}

	override function init() {
		debugDisplay = new DebugDisplay(s2d);

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
		var chunkMaterial = h3d.mat.Material.create(atlas);
		chunkMaterial.texture.filter = h3d.mat.Data.Filter.Nearest;
		chunkMaterial.mainPass.enableLights = true;
		chunkMaterial.shadows = true;

		terrain = new Terrain(new Vector3i(12, 12, 5), taskRunner);

		terrainRenderer = new TerrainRenderer(terrain, s3d, taskRunner, chunkMaterial);
		terrain.renderer = terrainRenderer;

		terrain.loadAllChunks();

		var camera = s3d.camera;
		camera.fovY = 80;

		player = new Player(s3d);
	}

	override function update(dt: Float) {
		super.update(dt);

		player.update(dt);

		terrain.update();
		terrainRenderer.update();

		debugDisplay.update(dt);
		DebugDisplay.setText("Pending tasks", '${taskRunner.getPendingTasksCount()}');
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
