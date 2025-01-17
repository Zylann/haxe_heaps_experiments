import h3d.col.Bounds;

class VoxelMeshPrimitive extends h3d.prim.MeshPrimitive {
	var vertexBuffer:hxd.FloatBuffer;
	var indexBuffer:hxd.IndexBuffer;
	var bounds:Bounds;

	public function new(vertexBuffer:hxd.FloatBuffer, indexBuffer:hxd.IndexBuffer, bounds:h3d.col.Bounds) {
		this.vertexBuffer = vertexBuffer;
		this.indexBuffer = indexBuffer;
		this.bounds = bounds;
	}

	override function alloc(engine:h3d.Engine) {
		dispose();
		var format = hxd.BufferFormat.POS3D_NORMAL_UV;
		buffer = h3d.Buffer.ofFloats(vertexBuffer, format);
		indexes = h3d.Indexes.alloc(indexBuffer);
	}

	override function getBounds():Bounds {
		return bounds;
	}
}
