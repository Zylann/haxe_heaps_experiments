import h3d.col.Bounds;

class VoxelMeshPrimitive extends h3d.prim.MeshPrimitive {
	var fbuffer:hxd.FloatBuffer;
	var ibuffer:hxd.IndexBuffer;
	var bounds:Bounds;

	public function new(fbuffer:hxd.FloatBuffer, ibuffer:hxd.IndexBuffer, bounds:h3d.col.Bounds) {
		this.fbuffer = fbuffer;
		this.ibuffer = ibuffer;
		this.bounds = bounds;
	}

	override function alloc(engine:h3d.Engine) {
		dispose();
		var format = hxd.BufferFormat.POS3D_NORMAL_UV;
		buffer = h3d.Buffer.ofFloats(fbuffer, format);
		indexes = h3d.Indexes.alloc(ibuffer);
	}

	override function getBounds():Bounds {
		return bounds;
	}
}
