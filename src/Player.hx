import h3d.col.Bounds;
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
	var boxSizeX: Float = 0.8;
	var boxSizeY: Float = 0.8;
	var boxSizeZ: Float = 1.75;
	var headZ: Float = 1.6;
	var terrain: Terrain;

	public function new(scene: Scene, terrain: Terrain) {
		this.scene = scene;
		this.terrain = terrain;
		cameraController = new PlayerCamera(scene);
	}

	public function setPosition(x: Float, y: Float, z: Float): Void {
		position.x = x;
		position.y = y;
		position.z = z;
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

		// TODO Optimize allocation
		var aabb = new Bounds();
		aabb.xMin = -boxSizeX * 0.5;
		aabb.yMin = -boxSizeY * 0.5;
		aabb.zMin = 0.0;
		aabb.xMax = boxSizeX * 0.5;
		aabb.yMax = boxSizeY * 0.5;
		aabb.zMax = boxSizeZ;
		aabb.offset(position.x, position.y, position.z);

		BoxPhysics.slideMotion(aabb, motion, terrain);

		position.load(position + motion);

		camera.pos.load(position);
		camera.pos.z += headZ;

		if (deltaTime > 0.0) {
			// Apply potential effects of collision to velocity
			velocity.load(motion * (1.0 / deltaTime));
		}

		cameraController.update();

		DebugDisplay.setText("Position", '${position}');
		DebugDisplay.setText("LookDir", '${camera.getForward()}');
	}
}
