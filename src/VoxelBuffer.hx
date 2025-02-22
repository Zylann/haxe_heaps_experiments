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

	public inline function clone(): VoxelBuffer {
		var d = new VoxelBuffer(sizeX, sizeY, sizeZ);
		d.data.blit(0, data, 0, data.length);
		return d;
	}

	public static function makeCubic(dim:Int):VoxelBuffer {
		return new VoxelBuffer(dim, dim, dim);
	}

	public function fill(v:Int) {
		data.fill(0, data.length, v);
	}

	public inline function getIndex(x:Int, y:Int, z:Int):Int {
		return x + sizeX * (y + sizeY * z);
	}

	public inline function isValidPosition(x:Int, y:Int, z:Int):Bool {
		return x >= 0 && y >= 0 && z >= 0;
	}

	public function getVoxel(x:Int, y:Int, z:Int):Int {
		if (!isValidPosition(x, y, z)) {
			throw new Exception("Invalid position");
		}
		var i = getIndex(x, y, z);
		return data.get(i);
	}

	public inline function getVoxelAtIndex(i: Int): Int {
		return data.get(i);
	}

	public function setVoxel(x:Int, y:Int, z:Int, v:Int) {
		if (!isValidPosition(x, y, z)) {
			throw new Exception("Invalid position");
		}
		var i = getIndex(x, y, z);
		data.set(i, v);
	}

	public inline function setVoxelAtIndex(i: Int, v: Int) {
		data.set(i, v);
	}

	public function paste(src: VoxelBuffer, pDstMinX: Int, pDstMinY: Int, pDstMinZ: Int) {
		var endX = pDstMinX + src.sizeX;
		var endY = pDstMinY + src.sizeY;
		var endZ = pDstMinZ + src.sizeZ;

		var clampedDstPosX = hxd.Math.iclamp(pDstMinX, 0, sizeX);
		var clampedDstPosY = hxd.Math.iclamp(pDstMinY, 0, sizeY);
		var clampedDstPosZ = hxd.Math.iclamp(pDstMinZ, 0, sizeZ);

		var clampedEndX = hxd.Math.iclamp(endX, 0, sizeX);
		var clampedEndY = hxd.Math.iclamp(endY, 0, sizeY);
		var clampedEndZ = hxd.Math.iclamp(endZ, 0, sizeZ);

		var clampedDstLenX = clampedEndX - clampedDstPosX;

		var dstX = clampedDstPosX;
		for (dstZ in clampedDstPosZ...clampedEndZ) {
			for (dstY in clampedDstPosY...clampedEndY) {
				var srcX = dstX - pDstMinX;
				var srcY = dstY - pDstMinY;
				var srcZ = dstZ - pDstMinZ;

				var srcI0 = srcX + src.sizeX * (srcY + src.sizeY * srcZ);
				var dstI0 = dstX + sizeX * (dstY + sizeY * dstZ);

				data.blit(dstI0, src.data, srcI0, clampedDstLenX);
			}
		}
	}
}
