package util;

#if debug
import haxe.exceptions.ArgumentException;
#end
import h3d.col.Bounds;

// 3D axis-aligned integer bounds
class Box3i {
	// Inclusive minimum
	public var minX: Int = 0;
	public var minY: Int = 0;
	public var minZ: Int = 0;

	// Exclusive maximum
	public var maxX: Int = 0;
	public var maxY: Int = 0;
	public var maxZ: Int = 0;

	public inline function new(minX: Int, minY: Int, minZ: Int, maxX: Int, maxY: Int, maxZ: Int) {
		#if debug
		if (maxX < minX) {
			throw new ArgumentException("maxX must be equal or greater than minX");
		}
		if (maxY < minY) {
			throw new ArgumentException("maxY must be equal or greater than minY");
		}
		if (maxZ < minZ) {
			throw new ArgumentException("maxZ must be equal or greater than minZ");
		}
		#end

		this.minX = minX;
		this.minY = minY;
		this.minZ = minZ;

		this.maxX = maxX;
		this.maxY = maxY;
		this.maxZ = maxZ;
	}

	public static inline function fromFloatBounds(bounds: Bounds): Box3i {
		return new Box3i(
			Std.int(Math.floor(bounds.xMin)),
			Std.int(Math.floor(bounds.yMin)),
			Std.int(Math.floor(bounds.zMin)),

			Std.int(Math.ceil(bounds.xMax)),
			Std.int(Math.ceil(bounds.yMax)),
			Std.int(Math.ceil(bounds.zMax))
		);
	}

	public inline function downscale(step: Int): Void {
		minX = floorDiv(minX, step);
		minY = floorDiv(minY, step);
		minZ = floorDiv(minZ, step);

		maxX = ceilDiv(maxX, step);
		maxY = ceilDiv(maxY, step);
		maxZ = ceilDiv(maxZ, step);
	}

	public inline function clip(other: Box3i): Void {
		minX = hxd.Math.iclamp(minX, other.minX, other.maxX);
		maxX = hxd.Math.iclamp(maxX, other.minX, other.maxX);

		minY = hxd.Math.iclamp(minY, other.minY, other.maxY);
		maxY = hxd.Math.iclamp(maxY, other.minY, other.maxY);

		minZ = hxd.Math.iclamp(minZ, other.minZ, other.maxZ);
		maxZ = hxd.Math.iclamp(maxZ, other.minZ, other.maxZ);
	}

	// public inline function forEachCell(f: (x: Int, y: Int, z: Int) -> Void): Void {
	// 	for (z in minZ...maxZ) {
	// 		for (y in minY...maxY) {
	// 			for (x in minX...maxX) {
	// 				f(x, y, z);
	// 			}
	// 		}
	// 	}
	// }

	static inline function floorDiv(x: Int, d: Int): Int {
		#if debug
		if (x <= 0) {
			throw new ArgumentException("x must be positive and non-zero");
		}
		#end
		if (x >= 0) {
			return Std.int(x / d);
		} else {
			return Std.int((x - d + 1) / d);
		}
	}

	static inline function ceilDiv(x: Int, d: Int): Int {
		#if debug
		if (x <= 0) {
			throw new ArgumentException("x must be positive and non-zero");
		}
		#end
		if (x >= 0) {
			return Std.int((x + d - 1) / d);
		} else {
			return Std.int(x / d);
		}
	}
}
