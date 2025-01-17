class Vector3i {
	public var x:Int;
	public var y:Int;
	public var z:Int;

	public function new(x:Int, y:Int, z:Int) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public inline function distanceToSq(other:Vector3i):Int {
		var dx = x - other.x;
		var dy = y - other.y;
		var dz = z - other.z;
		return dx * dx + dy * dy + dz * dz;
	}
}
