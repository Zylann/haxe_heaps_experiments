import haxe.Exception;
import h3d.col.Bounds;
import h3d.Vector;

class BoxPhysics {
	public static function slideMotion(box: h3d.col.Bounds, motion: Vector, terrain: Terrain): Void {
		var expandedBox = expandWithVector(box, motion);
		var potentialEnvironmentBoxes = collectEnvironmentBoxes(expandedBox, terrain);
		slideMotionWithBoxes(box, motion, potentialEnvironmentBoxes);
	}

	static function collectEnvironmentBoxes(queryBox: Bounds, terrain: Terrain): Array<Bounds> {
		// TODO Optimize allocations
		var potentialBoxes: Array<Bounds> = [];

		var minX = Std.int(Math.floor(queryBox.xMin));
		var minY = Std.int(Math.floor(queryBox.yMin));
		var minZ = Std.int(Math.floor(queryBox.zMin));

		var maxX = Std.int(Math.ceil(queryBox.xMax));
		var maxY = Std.int(Math.ceil(queryBox.yMax));
		var maxZ = Std.int(Math.ceil(queryBox.zMax));

		for (z in minZ...maxZ) {
			for (y in minY...maxY) {
				for (x in minX...maxX) {
					var v = terrain.getVoxel(x, y, z);

					if (v != 0) {
						var box = new Bounds();

						box.xMin = x;
						box.yMin = y;
						box.zMin = z;

						box.xMax = x + 1;
						box.yMax = y + 1;
						box.zMax = z + 1;

						potentialBoxes.push(box);
					}
				}
			}
		}

		return potentialBoxes;
	}

	static inline function expandWithVector(box: h3d.col.Bounds, v: Vector): Bounds {
		var newBox = box.clone();

		if (v.x > 0) {
			newBox.xMax += v.x;
		} else if (v.x < 0) {
			newBox.xMin += v.x;
		}

		if (v.y > 0) {
			newBox.yMax += v.y;
		} else if (v.y < 0) {
			newBox.yMin += v.y;
		}

		if (v.z > 0) {
			newBox.zMax += v.z;
		} else if (v.z < 0) {
			newBox.zMin += v.z;
		}

		return newBox;
	}

	static inline function swizzleBox(a: h3d.col.Bounds, i: Int, j: Int, k: Int): Bounds {
		// This is usually simpler to implement in C++ but in Haxe we have to use switches,
		// and rely heavily on inlining

		var b = new Bounds();

		switch (i) {
			case 0:
				b.xMin = a.xMin;
				b.xMax = a.xMax;
			case 1:
				b.xMin = a.yMin;
				b.xMax = a.yMax;
			case 2:
				b.xMin = a.zMin;
				b.xMax = a.zMax;
			default:
				throw new Exception("Invalid index");
		}

		switch (j) {
			case 0:
				b.yMin = a.xMin;
				b.yMax = a.xMax;
			case 1:
				b.yMin = a.yMin;
				b.yMax = a.yMax;
			case 2:
				b.yMin = a.zMin;
				b.yMax = a.zMax;
			default:
				throw new Exception("Invalid index");
		}

		switch (k) {
			case 0:
				b.zMin = a.xMin;
				b.zMax = a.xMax;
			case 1:
				b.zMin = a.yMin;
				b.zMax = a.yMax;
			case 2:
				b.zMin = a.zMin;
				b.zMax = a.zMax;
			default:
				throw new Exception("Invalid index");
		}

		return b;
	}

	// Clamps passed motion in the X axis to eventually prevent `inBox` from colliding with `inOther`,
	// in a coordinate system where XYZ are swizzled according to `i, j, k` (this approach is used to avoid
	// having to rewrite 3 times the same function only with different coordinates)
	static inline function clampMotionInAxis(
		inBox: h3d.col.Bounds,
		motion: Float,
		inOther: h3d.col.Bounds,
		i: Int,
		j: Int,
		k: Int
	): Float {
		var EPSILON = 0.001;

		var box = swizzleBox(inBox, i, j, k);
		var other = swizzleBox(inOther, i, j, k);

		if (other.zMax <= box.zMin || other.zMin >= box.zMax) {
			// Boxes don't overlap in Z axis
			return motion;
		}

		if (other.yMax <= box.yMin || other.yMin >= box.yMax) {
			// Boxes don't overlap in Y axis
			return motion;
		}

		// Now figure out collision offset in the remaining axis, according to motion in that axis

		if (motion > 0.0 && box.xMax <= other.xMin) {
			var off = other.xMin - box.xMax - EPSILON;
			if (off < motion) {
				// Colliding, clamp motion
				motion = off;
			}
		}

		if (motion < 0.0 && box.xMin >= other.xMax) {
			var off = other.xMax - box.xMin + EPSILON;
			if (off > motion) {
				motion = off;
			}
		}

		return motion;
	}

	// Gets the transformed vector for moving a box and slide.
	// This algorithm is free from tunnelling for axis-aligned movement,
	// except in some high-speed diagonal cases or huge size differences:
	// For example, if a box is fast enough to have a diagonal motion jumping from A to B,
	// it will pass through C if that other box is the only other one:
	//
	//  o---o
	//  | A |
	//  o---o
	//          o---o
	//          | C |
	//          o---o
	//                  o---o
	//                  | B |
	//                  o---o
	//
	// TODO one way to fix this would be to try a "hot side" projection instead
	//
	static function slideMotionWithBoxes(box: Bounds, motion: Vector, environmentBoxes: Array<Bounds>): Void {
		// The bounding box is expanded to include it's estimated version at next update.
		// This also makes the algorithm tunnelling-free
		var expandedBox = expandWithVector(box, motion);

		// TODO Optimize allocations
		var collidingBoxes: Array<Bounds> = [];
		for (other in environmentBoxes) {
			if (expandedBox.collide(other)) {
				collidingBoxes.push(other);
			}
		}

		if (collidingBoxes.length == 0) {
			return;
		}

		// print("Colliding: ", collidingBoxes.size())

		var newMotion = motion.clone();

		for (other in environmentBoxes) {
			newMotion.y = clampMotionInAxis(box, newMotion.y, other, 1, 0, 2);
		}
		box.yMin += newMotion.y;
		box.yMax += newMotion.y;

		for (other in environmentBoxes) {
			newMotion.x = clampMotionInAxis(box, newMotion.x, other, 0, 1, 2);
		}
		box.xMin += newMotion.x;
		box.xMax += newMotion.x;

		for (other in environmentBoxes) {
			newMotion.z = clampMotionInAxis(box, newMotion.z, other, 2, 1, 0);
		}
		box.zMin += newMotion.z;
		box.zMax += newMotion.z;

		motion.load(newMotion);
	}
}
