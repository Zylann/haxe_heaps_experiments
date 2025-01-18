import h3d.scene.Scene;

class PlayerCamera {
	var base: h3d.Camera;
	var animYaw: Float;

	public function new(s3d: Scene) {
		base = s3d.camera;
	}

	public function update(dt: Float) {
		animYaw += dt * 0.2;

		//    Z
		//    |
		//    o---X
		//   /
		//  Y
		var camDistance = 120.0;
		base.pos.set(camDistance * Math.cos(animYaw), camDistance * Math.sin(animYaw), 50.0);
	}
}
