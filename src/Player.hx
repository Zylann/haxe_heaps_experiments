import util.Vector3i;
import h3d.scene.Graphics;
import util.DDA;
import h3d.col.Bounds;
import hxd.Key;
import h3d.scene.Scene;
import h3d.Vector;

class Player {
	public var isControllerEnabled(get, set): Bool;

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
	var gravityEnabled: Bool = true;
	var gravity: Float = 50.0;
	var jumpVelocity: Float = 12.0;
	var grounded: Bool = false;
	var blockOutline: BlockOutline;

	public function new(scene: Scene, terrain: Terrain) {
		this.scene = scene;
		this.terrain = terrain;
		cameraController = new PlayerCamera(scene);
		blockOutline = new BlockOutline(scene);
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

		if (cameraController.enabled) {
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

		// TODO Optimize allocation
		var aabb = new Bounds();
		aabb.xMin = -boxSizeX * 0.5;
		aabb.yMin = -boxSizeY * 0.5;
		aabb.zMin = 0.0;
		aabb.xMax = boxSizeX * 0.5;
		aabb.yMax = boxSizeY * 0.5;
		aabb.zMax = boxSizeZ;
		aabb.offset(position.x, position.y, position.z);

		var camera = scene.camera;

		if (terrain.isAreaLoaded(aabb)) {
			var forwardFlat = camera.getForward();
			forwardFlat.z = 0.0;
			forwardFlat.normalize();

			var rightFlat = camera.getRight();
			rightFlat.z = 0.0;
			rightFlat.normalize();

			var up = new Vector(0, 0, 1);
			var invInertia = 1.0 / Math.max(inertia, 0.00001);

			if (gravityEnabled) {
				var velocityZ = velocity.z;
				velocityZ -= gravity * deltaTime;

				if (grounded && inputZ > 0.0) {
					// Jump
					velocityZ = jumpVelocity;
				}

				var motorDir = forwardFlat * inputY + rightFlat * inputX;
				var targetHorizontalVelocity = motorDir * speed;

				velocity.lerp(velocity, targetHorizontalVelocity, hxd.Math.clamp(deltaTime * invInertia, 0.0, 1.0));
				velocity.z = velocityZ;
				//
			} else {
				// Fly mode

				var motorDir = forwardFlat * inputY + rightFlat * inputX + up * inputZ;
				var targetVelocity = motorDir * speed;

				velocity.lerp(velocity, targetVelocity, hxd.Math.clamp(deltaTime * invInertia, 0.0, 1.0));
			}

			var motion = velocity * deltaTime;
			var motionZBeforeCollision = motion.z;

			BoxPhysics.slideMotion(aabb, motion, terrain);

			if (motionZBeforeCollision < 0.0 && motion.z > motionZBeforeCollision) {
				grounded = true;
			} else if (Math.abs(motion.z) > 0.001) {
				grounded = false;
			}

			position.load(position + motion);

			if (deltaTime > 0.0) {
				// Apply potential effects of collision to velocity
				velocity.load(motion * (1.0 / deltaTime));
			}
		}

		camera.pos.load(position);
		camera.pos.z += headZ;

		cameraController.update();

		util.DebugDisplay.setText("Position", '${position}');
		util.DebugDisplay.setText("LookDir", '${camera.getForward()}');

		updatePointer();
	}

	function updatePointer() {
		var camera = scene.camera;

		var rayState = new util.DDAState();
		var hitVoxelID = 0;

		var hasHit = util.DDA.voxelRaycast(camera.pos, camera.getForward(), (state: util.DDAState) -> {
			var v = terrain.getVoxel(state.hitPosition.x, state.hitPosition.y, state.hitPosition.z);
			return v != 0;
		}, 10.0, rayState);

		if (hasHit) {
			hitVoxelID = terrain.getVoxel(rayState.hitPosition.x, rayState.hitPosition.y, rayState.hitPosition.z);
			util.DebugDisplay.setText("Pointed voxel", '${rayState.hitPosition}');

			blockOutline.setPosition(rayState.hitPosition);
		}

		blockOutline.setVoxel(hitVoxelID);
	}

	function set_isControllerEnabled(value: Bool): Bool {
		return cameraController.enabled = value;
	}

	function get_isControllerEnabled(): Bool {
		return cameraController.enabled;
	}
}

class BlockOutline {
	var graphics: h3d.scene.Graphics;
	var voxelId: Int = 0;

	public function new(scene: h3d.scene.Scene) {
		graphics = new Graphics(scene);
	}

	public inline function setPosition(pos: Vector3i): Void {
		graphics.x = pos.x;
		graphics.y = pos.y;
		graphics.z = pos.z;
	}

	public function setVoxel(newVoxelID: Int) {
		if (voxelId == newVoxelID) {
			return;
		}

		voxelId = newVoxelID;

		if (voxelId == 0) {
			graphics.visible = false;
			return;
		}

		graphics.visible = true;

		for (side in Cube.sideVertices) {
			graphics.moveTo(side[0], side[1], side[2]);
			graphics.lineTo(side[3], side[4], side[5]);
			graphics.lineTo(side[6], side[7], side[8]);
			graphics.lineTo(side[9], side[10], side[11]);
		}
	}
}
