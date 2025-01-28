import haxe.Exception;

class VoxelBuffer {
	static final MAX_DIMENSION = 255;

	// Int is at least 32-bit in Haxe, which is too big for the use case. And it depends on the platform.
	// Ideally this needs to be a packed array of 16-bit unsigned ints, or even bytes.
	var data:haxe.io.Bytes;

	public var sizeX(default, null):Int;
	public var sizeY(default, null):Int;
	public var sizeZ(default, null):Int;

	public function new(sizeX:Int, sizeY:Int, sizeZ:Int) {
		if (sizeX <= 0 || sizeY <= 0 || sizeZ <= 0) {
			throw new Exception("Invalid size");
		}
		if (sizeX > MAX_DIMENSION || sizeY > MAX_DIMENSION || sizeZ > MAX_DIMENSION) {
			throw new Exception("Size too big");
		}
		this.sizeX = sizeX;
		this.sizeY = sizeY;
		this.sizeZ = sizeZ;
		var volume = sizeX * sizeY * sizeZ;
		this.data = haxe.io.Bytes.alloc(volume);
	}

	public static function makeCubic(dim:Int):VoxelBuffer {
		return new VoxelBuffer(dim, dim, dim);
	}

	public function fill(v:Int) {
		data.fill(0, data.length, v);
	}

	public function getIndex(x:Int, y:Int, z:Int):Int {
		return x + sizeY * (y + sizeY * z);
	}

	public function isValidPosition(x:Int, y:Int, z:Int):Bool {
		return x >= 0 && y >= 0 && z >= 0;
	}

	public function getVoxel(x:Int, y:Int, z:Int):Int {
		if (!isValidPosition(x, y, z)) {
			throw new Exception("Invalid position");
		}
		var i = getIndex(x, y, z);
		return data.get(i);
	}

	public function setVoxel(x:Int, y:Int, z:Int, v:Int) {
		if (!isValidPosition(x, y, z)) {
			throw new Exception("Invalid position");
		}
		var i = getIndex(x, y, z);
		data.set(i, v);
	}
}
