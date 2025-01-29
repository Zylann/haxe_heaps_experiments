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

	public function new(){}

	public function push(item: T) {
		// TODO Does Haxe have any mechanism similar to RAII, or simply `defer`? Would be super useful
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

	public function endConsume() {
		readerList.resize(0);
	}
}
