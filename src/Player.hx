import hxd.Key;
import h3d.scene.Scene;
import h3d.Vector;

class Player {
	var scene: Scene;
	var cameraController: PlayerCamera;
	var position: Vector = new Vector();
	var velocity: Vector = new Vector();
	var speed: Float = 10.0;
	var inertia: Float = 0.05;

	public function new(scene: Scene) {
		this.scene = scene;
		cameraController = new PlayerCamera(scene);
	}

	public function update(deltaTime: Float) {
		var inputX = 0.0;
		var inputY = 0.0;
		var inputZ = 0.0;

		if (cameraController.isEnabled()) {
			if (Key.isDown(Key.A)) {
				inputX = -1.0;
			}
			if (Key.isDown(Key.D)) {
				inputX = 1.0;
			}
			if (Key.isDown(Key.W)) {
				inputY = 1.0;
			}
			if (Key.isDown(Key.S)) {
				inputY = -1.0;
			}
			if (Key.isDown(Key.SPACE)) {
				inputZ = 1.0;
			}
			if (Key.isDown(Key.SHIFT)) {
				inputZ = -1.0;
			}
		}

		var camera = scene.camera;

		var forwardFlat = camera.getForward();
		forwardFlat.z = 0.0;
		forwardFlat.normalize();

		var rightFlat = camera.getRight();
		rightFlat.z = 0.0;
		rightFlat.normalize();

		var up = new Vector(0, 0, 1);

		var motorDir = forwardFlat * inputY + rightFlat * inputX + up * inputZ;
		var targetVelocity = motorDir * speed;
		var invInertia = 1.0 / Math.max(inertia, 0.00001);
		velocity.lerp(velocity, targetVelocity, hxd.Math.clamp(deltaTime * invInertia, 0.0, 1.0));

		var motion = velocity * deltaTime;
		position.load(position + motion);

		camera.pos.load(position);

		cameraController.update();
	}
}
