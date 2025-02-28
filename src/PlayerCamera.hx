import h3d.Vector;
import h3d.scene.Scene;

class PlayerCamera {
	public var enabled(default, set): Bool = false;

	var scene: Scene;
	var yaw: Float = 0.0;
	var pitch: Float = 0.0;
	var yawDelta: Float = 0.0;
	var pitchDelta: Float = 0.0;
	var sensitivity: Float = 0.002;

	public function new(s3d: Scene) {
		scene = s3d;
	}

	function set_enabled(e: Bool) {
		if (e == enabled) {
			return e;
		}
		enabled = e;

		if (enabled) {
			// Capture mouse
			var window = hxd.Window.getInstance();
			window.setCursorPos(Std.int(window.width / 2), Std.int(window.height / 2));
			window.mouseMode = Relative(onRelativeMouseEvent, true);
		} else {
			// Restore mouse
			var window = hxd.Window.getInstance();
			window.mouseMode = Absolute;
		}

		return enabled;
	}

	function get_enabled(): Bool {
		return enabled;
	}

	public function update() {
		yaw = hxd.Math.angle(yaw + yawDelta);
		pitch = hxd.Math.clamp(pitch + pitchDelta, -Math.PI / 2 + 0.001, Math.PI / 2 - 0.001);

		yawDelta = 0.0;
		pitchDelta = 0.0;

		var dirX = Math.cos(yaw) * Math.cos(pitch);
		var dirY = Math.sin(yaw) * Math.cos(pitch);
		var dirZ = Math.sin(pitch);

		var camera = scene.camera;
		camera.target.load(camera.pos + new h3d.Vector(dirX, dirY, dirZ));
	}

	function onRelativeMouseEvent(event: hxd.Event) {
		yawDelta += event.relX * sensitivity;
		pitchDelta -= event.relY * sensitivity;
	}
}
