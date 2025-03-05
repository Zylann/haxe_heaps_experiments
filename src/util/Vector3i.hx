package util;

import h3d.Vector;
import hxd.Math;

class Vector3iImpl {
	public var x: Int;
	public var y: Int;
	public var z: Int;

	public inline function new(x: Int, y: Int, z: Int) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public inline function load(from: Vector3i): Void {
		this.x = from.x;
		this.y = from.y;
		this.z = from.z;
	}

	public inline function distanceToSq(other: Vector3i): Int {
		return cDistanceSq(x, y, z, other.x, other.y, other.z);
	}

	public inline function isValidSize(): Bool {
		return x > 0 && y > 0 && z > 0;
	}

	public inline function getVolume(): Int {
		return x * y * z;
	}

	public inline function getXYZIndex(size: Vector3i): Int {
		return x + size.x * (y + size.y * z);
	}

	public inline function clone(): Vector3i {
		return new Vector3i(x, y, z);
	}

	public inline function toString() {
		return '{${x},${y},${z}}';
	}

	// When used as a size, tells if the point is in bounds
	public inline function containsPoint(pos: Vector3i): Bool {
		return pos.x >= 0 && pos.y >= 0 && pos.z >= 0 && pos.x < x && pos.y < y && pos.z < z;
	}

	public inline function mulScalar(i: Int): Vector3i {
		return new Vector3i(x * i, y * i, z * i);
	}

	public inline function divScalar(d: Float): Vector {
		return new Vector(x / d, y / d, z / d);
	}

	public inline function intDivScalar(i: Int) {
		return new Vector3i(Std.int(x / i), Std.int(y / i), Std.int(z / i));
	}

	public inline function chebychevDistance(other: Vector3i): Int {
		return cChebychevDistance(x, y, z, other.x, other.y, other.z);
	}

	//

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

@:forward
abstract Vector3i(Vector3iImpl) {
	public inline function new(x: Int, y: Int, z: Int) {
		this = new Vector3iImpl(x, y, z);
	}

	public static inline function splat(v: Int): Vector3i {
		return new Vector3i(v, v, v);
	}

	public static inline function fromFloor(v: Vector): Vector3i {
		return new Vector3i(Std.int(Math.floor(v.x)), Std.int(Math.floor(v.y)), Std.int(Math.floor(v.z)));
	}

	@:op(a * b)
	public inline function mulScalar(m: Int): Vector3i {
		return this.mulScalar(m);
	}

	@:op(a * b)
	public static inline function mulScalarPre(m: Int, v: Vector3i): Vector3i {
		return v.mulScalar(m);
	}

	@:op(a / b)
	public inline function divScalar(m: Float): Vector {
		return this.divScalar(m);
	}

	@:op(a >> b)
	public inline function rshift(s: Int): Vector3i {
		return new Vector3i(this.x >> s, this.y >> s, this.z >> s);
	}

	@:op(a & b)
	public inline function maskAnd(m: Int): Vector3i {
		return new Vector3i(this.x & m, this.y & m, this.z & m);
	}
}
