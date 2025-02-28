import hxd.Window;
import hxd.Key;
import TerrainRenderer.MeshChunkTask;
import h3d.scene.Mesh;

class Main extends hxd.App {
	var debugDisplay: DebugDisplay;
	var player: Player;
	var terrain: Terrain;
	var terrainRenderer: TerrainRenderer;
	var taskRunner: ThreadedTaskRunner;
	var uiCenter: h2d.Flow;
	var pauseMenu: PauseMenu;
	var uiStyle: h2d.domkit.Style;

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

		player = new Player(s3d, terrain);
		player.setPosition(10, 10, 50);

		// UI

		var window = Window.getInstance();
		window.onClose = function() {
			cleanup();
			return true;
		}

		uiStyle = new h2d.domkit.Style();
		uiStyle.load(hxd.Res.style);

		uiCenter = new h2d.Flow(s2d);
		uiCenter.horizontalAlign = uiCenter.verticalAlign = Middle;
		onResize();

		pauseMenu = new PauseMenu(uiCenter);
		pauseMenu.continueButton.onClick = function() {
			setPause(false);
		};
		pauseMenu.quitButton.onClick = function() {
			// Usually programs simply have to get to the end of their "main" function to exit, after cleaning up.
			// All I could find on samples and Discord questions is hxd.System.exit(),
			// but that's a brutal exit, terminating the process.
			//
			// hxd.System.exit();
			//
			// Reading the code of the main loop, I figured closing the Window is closer to what I want.
			// However, it seems we still have to execute cleanup ourselves.
			// I wonder how Heaps cleans up its own things on exit?
			//
			// Anyways, for now I do this manually and set my own onClose handler.
			if (window.onClose()) {
				window.close();
			}
		};

		uiStyle.addObject(pauseMenu);

		// Allow debugging using middle click
		uiStyle.allowInspect = true;

		s3d.addEventListener(onScene3DEvent);
	}

	override function onResize() {
		// Cover whole screen
		uiCenter.minWidth = uiCenter.maxWidth = s2d.width;
		uiCenter.minHeight = uiCenter.maxHeight = s2d.height;
	}

	override function update(dt: Float) {
		super.update(dt);

		player.update(dt);

		terrain.update();
		terrainRenderer.update();

		uiStyle.sync(dt);

		debugDisplay.update(dt);
		DebugDisplay.setText("Pending tasks", '${taskRunner.getPendingTasksCount()}');
	}

	function setPause(paused: Bool): Void {
		player.isControllerEnabled = !paused;
		pauseMenu.visible = paused;
	}

	function onScene3DEvent(event: hxd.Event) {
		if (player.isControllerEnabled) {
			switch (event.kind) {
				case EKeyDown:
					if (event.keyCode == Key.ESCAPE) {
						setPause(true);
					}

				default:
			}
		} else {
			switch (event.kind) {
				case EKeyDown:
					if (event.keyCode == Key.ESCAPE) {
						setPause(false);
					}

				case EPush:
					if (pauseMenu.visible == false) {
						player.isControllerEnabled = true;
					}

				default:
			}
		}
	}

	function cleanup() {
		// We want background tasks to finish, they might be important (saving?)
		taskRunner.dispose();
	}

	// TODO What is `dispose` for? It isn't called by anything
	// override function dispose() {
	// 	cleanup();
	// 	super.dispose();
	// }

	static function main() {
		new Main();
	}
}
