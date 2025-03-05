package util;

import sys.thread.Mutex;

// Basic specialization of a multi-producer single-consumer list.
// Producers append over time, consumer reads the whole list (hence not really a queue, rather a subset of it).
// Intented as an output for background tasks to be read by the main thread.
class MPSCList<T> {
	var writerList: Array<T> = [];

	// TODO Expose an iterator?
	public var readerList: Array<T> = [];

	// TODO Don't have a mutex on targets that have no threads?
	var mutex: Mutex = new Mutex();

	public function new() {}

	public function push(item: T) {
		mutex.acquire();
		writerList.push(item);
		mutex.release();
	}

	public function beginConsume() {
		if (readerList.length == 0) {
			if (mutex.tryAcquire()) {
				// Swap lists
				var temp = writerList;
				writerList = readerList;
				readerList = temp;
				mutex.release();
			}
		}
	}

	public inline function endConsume() {
		readerList.resize(0);
	}

	public inline function consume(): MPSCListConsumerIterator<T> {
		beginConsume();
		return new MPSCListConsumerIterator<T>(readerList);
	}
}

class MPSCListConsumerIterator<T> {
	var readerList: Array<T>;
	var i: Int = 0;

	public inline function new(a: Array<T>) {
		readerList = a;
	}

	public inline function hasNext(): Bool {
		return i < readerList.length;
	}

	public inline function next(): T {
		var v = readerList[i];
		i += 1;
		if (!hasNext()) {
			readerList.resize(0);
		}
		return v;
	}
}
