package util;

typedef Comparer<T> = {
	function compare(a: T, b: T): Bool;
}

@:generic
class PriorityQueue<TItem, TComparer: Comparer<TItem>> {
	var items: Array<TItem> = [];
	var comparer: TComparer;

	public var count(get, never): Int;

	public function new(comparer: TComparer) {
		this.comparer = comparer;
	}

	public function push(item: TItem) {
		items.push(item);
		heapPush(0, items.length - 1, 0, item, items, comparer);
	}

	public function pop(): Null<TItem> {
		if (items.length > 0) {
			heapPop2(0, items.length, items, comparer);
			// Note, removing from the end of the array means the Comparer is reversed:
			// Returning `true` means "a has lower priority than b"
			return items.pop();
		} else {
			return null;
		}
	}

	public inline function clear() {
		return items.resize(0);
	}

	inline function get_count(): Int {
		return items.length;
	}
}

// Binary heap functions
// Subset of SortArray ported from Godot Engine

@:generic
function heapPush<TItem, TComparer: Comparer<TItem>>(
	first: Int,
	holeIndex: Int,
	topIndex: Int,
	value: TItem,
	array: Array<TItem>,
	comparer: TComparer
) {
	var parent = intDiv(holeIndex - 1, 2);
	while (holeIndex > topIndex && comparer.compare(array[first + parent], value)) {
		array[first + holeIndex] = array[first + parent];
		holeIndex = parent;
		parent = intDiv(holeIndex - 1, 2);
	}
	array[first + holeIndex] = value;
}

@:generic
function heapPop<TItem, TComparer: Comparer<TItem>>(
	first: Int,
	last: Int,
	result: Int,
	value: TItem,
	array: Array<TItem>,
	comparer: TComparer
) {
	array[result] = array[first];
	heapAdjust(first, 0, last - first, value, array, comparer);
}

@:generic
inline function heapPop2<TItem, TComparer: Comparer<TItem>>(
	first: Int,
	last: Int,
	array: Array<TItem>,
	comparer: TComparer
) {
	heapPop(first, last - 1, last - 1, array[last - 1], array, comparer);
}

@:generic
function heapAdjust<TItem, TComparer: Comparer<TItem>>(
	first: Int,
	holeIndex: Int,
	len: Int,
	value: TItem,
	array: Array<TItem>,
	comparer: TComparer
) {
	var topIndex = holeIndex;
	var secondChild = 2 * holeIndex + 2;

	while (secondChild < len) {
		if (comparer.compare(array[first + secondChild], array[first + (secondChild - 1)])) {
			secondChild--;
		}

		array[first + holeIndex] = array[first + secondChild];
		holeIndex = secondChild;
		secondChild = 2 * (secondChild + 1);
	}

	if (secondChild == len) {
		array[first + holeIndex] = array[first + (secondChild - 1)];
		holeIndex = secondChild - 1;
	}

	heapPush(first, holeIndex, topIndex, value, array, comparer);
}

// Utils

inline function intDiv(a: Int, b: Int): Int {
	// Haxe considers the output of all divisions to be Float.
	// On static targets, this can be detrimental to performance if not casted properly.
	return Std.int(a / b);
}

// static inline function intFloorDivBy2(x: Int): Int {
//     return x >> 1;
// }
// Test

class IntLessComparer {
	public function new() {}

	public function compare(a: Int, b: Int): Bool {
		return a < b;
	}
}

function testPriorityQueue() {
	var queue = new PriorityQueue<Int, IntLessComparer>(new IntLessComparer());
	queue.push(3);
	queue.push(5);
	queue.push(2);
	queue.push(10);

	trace(queue.pop());
	trace(queue.pop());
	trace(queue.pop());
	trace(queue.pop());
	trace(queue.pop());
}
