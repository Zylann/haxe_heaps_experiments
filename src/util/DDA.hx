package util;

#if debug
import haxe.exceptions.ArgumentException;
import haxe.Exception;
#end
import h3d.Vector;

// Values known when crossing one cell.
// View of the cell where the ray goes from A to B:
//
//    |       /|
//  --o------A-o--
//    |prev /  |
//    |    /   |
//    |   /    |
//  --o--B-----o--
//    |current |
//
class DDAState {
	// Grid position of the cell we are coming from.
	public var hitPrevPosition: Vector3i = new Vector3i(0, 0, 0);
	// Distance along the ray where we entered the previous cell
	public var prevDistance: Float = 0.0;
	// Grid position of the cell we just hit
	public var hitPosition: Vector3i = new Vector3i(0, 0, 0);
	// Distance along the ray where we enter the hit cell
	public var distance: Float = 0.0;

	public function new() {}
}

class DDA {
	// Runs the DDA algorithms in 3D.
	public static inline function voxelRaycast(
		rayOrigin: Vector,
		rayDirection: Vector,
		predicate: (state: DDAState) -> Bool,
		maxDistance: Float,
		state: DDAState
	): Bool {
		checkNanVector(rayOrigin);
		checkNanVector(rayDirection);
		checkNanFloat(maxDistance);

		final huge: Float = 9999999.9;

		// Equation : p + v*t
		// p : ray start position (ray.pos)
		// v : ray orientation vector (ray.dir)
		// t : parametric variable = a distance if v is normalized

		// This raycasting technique is described here :
		// http://www.cse.yorku.ca/~amana/research/grid.pdf

		// See also https://www.youtube.com/watch?v=NbSee-XM7WA

		// Note : the grid is assumed to have 1-unit square cells.

		checkNormalized(rayDirection);

		// Initialisation

		// Voxel position
		state.hitPosition = Vector3i.fromFloor(rayOrigin);
		state.hitPrevPosition = state.hitPosition.clone();

		// Voxel step
		final xiStep: Int = if (rayDirection.x > 0) 1; else if (rayDirection.x < 0) -1; else 0;
		final yiStep: Int = if (rayDirection.y > 0) 1; else if (rayDirection.y < 0) -1; else 0;
		final ziStep: Int = if (rayDirection.z > 0) 1; else if (rayDirection.z < 0) -1; else 0;

		// Parametric voxel step
		final tdeltaX: Float = if (xiStep != 0) 1.0 / Math.abs(rayDirection.x); else huge;
		final tdeltaY: Float = if (yiStep != 0) 1.0 / Math.abs(rayDirection.y); else huge;
		final tdeltaZ: Float = if (ziStep != 0) 1.0 / Math.abs(rayDirection.z); else huge;

		// Parametric grid-cross
		var tcrossX: Float; // At which value of T we will cross a vertical line?
		var tcrossY: Float; // At which value of T we will cross a horizontal line?
		var tcrossZ: Float; // At which value of T we will cross a depth line?

		// X initialization
		if (xiStep != 0) {
			if (xiStep == 1) {
				tcrossX = (Math.ceil(rayOrigin.x) - rayOrigin.x) * tdeltaX;
			} else {
				tcrossX = (rayOrigin.x - Math.floor(rayOrigin.x)) * tdeltaX;
			}
		} else {
			tcrossX = huge; // Will never cross on X
		}

		// Y initialization
		if (yiStep != 0) {
			if (yiStep == 1) {
				tcrossY = (Math.ceil(rayOrigin.y) - rayOrigin.y) * tdeltaY;
			} else {
				tcrossY = (rayOrigin.y - Math.floor(rayOrigin.y)) * tdeltaY;
			}
		} else {
			tcrossY = huge; // Will never cross on X
		}

		// Z initialization
		if (ziStep != 0) {
			if (ziStep == 1) {
				tcrossZ = (Math.ceil(rayOrigin.z) - rayOrigin.z) * tdeltaZ;
			} else {
				tcrossZ = (rayOrigin.z - Math.floor(rayOrigin.z)) * tdeltaZ;
			}
		} else {
			tcrossZ = huge; // Will never cross on X
		}

		// Workaround for integer positions
		// Adapted from https://github.com/bulletphysics/bullet3/blob/3dbe5426bf7387e532c17df9a1c5e5a4972c298a/src/
		// BulletCollision/CollisionShapes/btHeightfieldTerrainShape.cpp#L418
		if (tcrossX == 0.0) {
			tcrossX += tdeltaX;
			// If going backwards, we should ignore the position we would get by the above flooring,
			// because the ray is not heading in that direction
			if (xiStep == -1) {
				state.hitPosition.x -= 1;
			}
		}

		if (tcrossY == 0.0) {
			tcrossY += tdeltaY;
			if (yiStep == -1) {
				state.hitPosition.y -= 1;
			}
		}

		if (tcrossZ == 0.0) {
			tcrossZ += tdeltaZ;
			if (ziStep == -1) {
				state.hitPosition.z -= 1;
			}
		}

		// Iteration

		var t: Float = 0.0;
		var tPrev: Float = 0.0;
		var hasHit = true;

		do {
			state.hitPrevPosition.load(state.hitPosition);
			tPrev = t;
			if (tcrossX < tcrossY) {
				if (tcrossX < tcrossZ) {
					// X collision
					// hit.prevPos.x = hit.pos.x;
					state.hitPosition.x += xiStep;
					if (tcrossX > maxDistance) {
						// TODO Why does this produce "Cannot inline a not final return"? What does it mean?
						// Had to workaround by forcing a unique return at the end of the function
						// return false;
						hasHit = false;
						break;
					}
					t = tcrossX;
					tcrossX += tdeltaX;
				} else {
					// Z collision (duplicate code)
					// hit.prevPos.z = hit.pos.z;
					state.hitPosition.z += ziStep;
					if (tcrossZ > maxDistance) {
						// return false;
						hasHit = false;
						break;
					}
					t = tcrossZ;
					tcrossZ += tdeltaZ;
				}
			} else {
				if (tcrossY < tcrossZ) {
					// Y collision
					// hit.prevPos.y = hit.pos.y;
					state.hitPosition.y += yiStep;
					if (tcrossY > maxDistance) {
						// return false;
						hasHit = false;
						break;
					}
					t = tcrossY;
					tcrossY += tdeltaY;
				} else {
					// Z collision (duplicate code)
					// hit.prevPos.z = hit.pos.z;
					state.hitPosition.z += ziStep;
					if (tcrossZ > maxDistance) {
						// return false;
						hasHit = false;
						break;
					}
					t = tcrossZ;
					tcrossZ += tdeltaZ;
				}
			}
		} while (!predicate(state));

		return hasHit;
	}

	static inline function hasNan(v: Vector): Bool {
		return Math.isNaN(v.x) || Math.isNaN(v.y) || Math.isNaN(v.z);
	}

	static inline function checkNanVector(v: Vector): Void {
		#if debug
		if (hasNan(v)) {
			throw new ArgumentException("Unexpected NaN");
		}
		#end
	}

	static inline function checkNormalized(v: Vector): Void {
		#if debug
		var lenSq = v.lengthSq();
		if (Math.abs(lenSq - 1.0) > 0.01) {
			throw new Exception("Vector is not normalized");
		}
		#end
	}

	static inline function checkNanFloat(x: Float): Void {
		#if debug
		if (Math.isNaN(x)) {
			throw new ArgumentException("Unexpected NaN");
		}
		#end
	}
}
