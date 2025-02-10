import hxd.Math;

class Vector3i {
	public var x:Int;
	public var y:Int;
	public var z:Int;

	public inline function new(x:Int, y:Int, z:Int) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public inline function distanceToSq(other:Vector3i):Int {
		return cDistanceSq(x, y, z, other.x, other.y, other.z);
	}

	public static inline function cDistance(x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int): Float {
		return Math.sqrt(cDistance(x1, y1, z1, x2, y2, z2));
	}

	public static inline function cDistanceSq(x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int): Int {
		return cLengthSq(x2 - x1, y2 - y1, z2 - z1);
	}

	public static inline function cLengthSq(x: Int, y: Int, z: Int): Int {
		return x * x + y * y + z * z;
	}

	public static inline function cChebychevDistance(x1: Int, y1: Int, z1: Int, x2: Int, y2: Int, z2: Int): Int {
		var dx = Math.iabs(x2 - x1);
		var dy = Math.iabs(y2 - y1);
		var dz = Math.iabs(z2 - z1);
		return Math.imax(Math.imax(dx, dy), dz);
	}
}
