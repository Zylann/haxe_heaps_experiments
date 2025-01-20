import haxe.ds.ReadOnlyArray;

// TODO No static class? Any equivalent?
// I tried putting this stuff at module-level, but it makes it tedious to import. Maybe I'm missing something?
class Cube {
	public static inline var SIDE_NEGATIVE_X = 0;
	public static inline var SIDE_POSITIVE_X = 1;
	public static inline var SIDE_NEGATIVE_Y = 2;
	public static inline var SIDE_POSITIVE_Y = 3;
	public static inline var SIDE_NEGATIVE_Z = 4;
	public static inline var SIDE_POSITIVE_Z = 5;
	public static inline var SIDE_COUNT = 6;

	public static final sideVertices:ReadOnlyArray<ReadOnlyArray<Float>> = [
		// @formatter:off
		[ // -X
			0, 0, 0,
			0, 0, 1,
			0, 1, 1,
			0, 1, 0,
		],
		[ // +X
			1, 0, 1,
			1, 0, 0,
			1, 1, 0,
			1, 1, 1,
		],
		[ // -Y
			1, 0, 1,
			0, 0, 1,
			0, 0, 0,
			1, 0, 0,
		],
		[ // +Y
			0, 1, 1,
			1, 1, 1,
			1, 1, 0,
			0, 1, 0,
		],
		[ // -Z
			1, 0, 0,
			0, 0, 0,
			0, 1, 0,
			1, 1, 0,
		],
		[ // +Z
			0, 0, 1,
			1, 0, 1,
			1, 1, 1,
			0, 1, 1,
		],
		// @formatter:on
	];

	public static final sideNormals:ReadOnlyArray<ReadOnlyArray<Int>> = [
		// @formatter:off
		[-1, 0, 0],
		[1, 0, 0],
		[0, -1, 0],
		[0, 1, 0],
		[0, 0, -1],
		[0, 0, 1]
		// @formatter:on
	];

	public static final sideUVs:ReadOnlyArray<ReadOnlyArray<Float>> = [
		// @formatter:off
		[0.0, 0.0],
		[1.0, 0.0],
		[1.0, 1.0],
		[0.0, 1.0]
		// @formatter:on
	];
}
