package util;

import util.Task.TaskContext;
import haxe.Exception;
import sys.thread.Semaphore;
import sys.thread.Mutex;
import sys.thread.Thread;

class TaskPriorityComparer {
	public function new() {}

	public inline function compare(a: Task, b: Task): Bool {
		return a.priority < b.priority;
	}
}

// Runs background tasks over multiple threads. Tasks can be sorted by priority.
class ThreadedTaskRunner {
	// Tasks that have just been scheduled but not added to the main queue.
	// It is separate from the pickup queue to minimize locking times on threads that schedule tasks.
	var stagedTasks: Array<Task> = [];
	var stagedTasksMutex: Mutex = new Mutex();
	// How many threads are in waiting state.
	// Must lock `stagedTasksMutex`.
	var waitingThreadsCount: Int = 0;

	var tasksCount: Int = 0;

	// Tasks that may be picked by threads.
	var pendingTasks: PriorityQueue<Task, TaskPriorityComparer>;
	var pendingTasksMutex: Mutex = new Mutex();
	var tempTaskList: Array<Task> = [];

	var threads: Array<Thread> = [];

	var active: Bool = true;

	var semaphore: Semaphore = new Semaphore(0);

	public function new(numThreads: Int) {
		pendingTasks = new PriorityQueue<Task, TaskPriorityComparer>(new TaskPriorityComparer());

		for (threadIndex in 0...numThreads) {
			var thread = Thread.create(() -> threadLoop(threadIndex));
			threads.push(thread);
		}
	}

	public function pushTasks(newTasks: Array<Task>) {
		if (newTasks.length == 0) {
			return;
		}

		var needWake = false;

		{
			stagedTasksMutex.acquire();

			// TODO No optimal "addAll" method that could be optimized on static targets?
			for (newTask in newTasks) {
				stagedTasks.push(newTask);
			}
			needWake = waitingThreadsCount > 0;
			tasksCount += newTasks.length;

			stagedTasksMutex.release();
		}

		if (needWake) {
			semaphore.release();
		}
	}

	public function getThreadCount(): Int {
		return threads.length;
	}

	public function getPendingTasksCount(): Int {
		var count: Int = 0;
		stagedTasksMutex.acquire();
		count = tasksCount;
		stagedTasksMutex.release();
		return count;
	}

	public function dispose() {
		if (!active) {
			throw new Exception("Dispose should not be called twice");
		}

		waitForAllTasks();

		// Notify all threads to exit their loop
		active = false;
		for (thread in threads) {
			semaphore.release();
		}

		// Haxe Threads don't have a `join` or `dispose` method. Does that mean we don't cleanup anything from here?
	}

	function waitForAllTasks() {
		// Assumes we no longer schedule tasks. This is meant to be used on application shutdown.

		trace("Waiting for all tasks to finish...");

		while (true) {
			var count = getPendingTasksCount();
			if (count < 0) {
				trace("Task count went negative?");
				break;
			} else if (count == 0) {
				break;
			} else {
				Sys.sleep(0.002);
			}
		}
	}

	function threadLoop(threadIndex: Int) {
		trace('Starting thread ${threadIndex}');

		var waking = false;
		var doneTaskCountComingFromQueue: Int = 0;

		var taskContext = new TaskContext(threadIndex);

		while (active) {
			var task: Task = null;
			var wakeMore: Bool = false;
			var needWait: Bool = false;

			// Task pickup
			{
				pendingTasksMutex.acquire();

				// Sync point with staging queue
				{
					stagedTasksMutex.acquire();

					// Swap staging lists
					var temp = stagedTasks;
					stagedTasks = tempTaskList;
					tempTaskList = temp;

					if (stagedTasks.length != 0) {
						throw new Exception("Invalid state");
					}

					// Update the count of pending tasks by subtracting the amount we've done before that sync point
					tasksCount -= doneTaskCountComingFromQueue;
					doneTaskCountComingFromQueue = 0;

					if (pendingTasks.count == 0 && tempTaskList.length == 0) {
						// The thread will go to wait
						needWait = true;
						waitingThreadsCount += 1;
					} else {
						// We assume the thread will pick a task soon
						if (waking) {
							// Unregister current thread from waiting count
							waitingThreadsCount -= 1;
						}
						if (waitingThreadsCount > 0) {
							// There may be more tasks to pick so we'll wake one more thread
							wakeMore = true;
						}
					}

					stagedTasksMutex.release();
				}

				// Append and sort new tasks
				for (task in tempTaskList) {
					pendingTasks.push(task);
				}
				tempTaskList.resize(0);

				task = pendingTasks.pop();

				if (task != null) {
					if (needWait) {
						throw new Exception("Unexpected state");
					}
				}

				pendingTasksMutex.release();
			}

			waking = false;

			if (needWait) {
				// Wait here until new tasks are added
				semaphore.acquire();
				waking = true;
				continue;
			}

			if (wakeMore) {
				semaphore.release();
			}

			task.run(taskContext);

			doneTaskCountComingFromQueue += 1;
		}
	}
}
