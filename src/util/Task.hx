package util;

// Base class for background tasks
class Task {
	public var priority: Int;

	public function run(context: TaskContext) {}
}

// Passed to every task when executed.
class TaskContext {
	public var threadIndex(default, null): Int;

	public function new(threadIndex: Int) {
		this.threadIndex = threadIndex;
	}
}
