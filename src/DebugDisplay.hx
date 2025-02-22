import hl.Gc;
import hxd.Timer;
import hxd.res.DefaultFont;

class DebugDisplay {
	static inline var FPS_UPDATE_INTERVAL = 0.25;
	static inline var UPDATE_INTERVAL = 0.1;

	var textObject: h2d.Text;
	var timeBeforeFPSUpdate = 0.0;
	var timeBeforeUpdate = 0.0;
	var displayedFPS = 0.0;
	var stringBuffer: StringBuf = new StringBuf();

	public function new(s2d: h2d.Scene) {
		textObject = new h2d.Text(DefaultFont.get(), s2d);
	}

	public function update(dt: Float, pendingTasksCount: Int) {
		timeBeforeFPSUpdate -= dt;
		if (timeBeforeFPSUpdate <= 0.0) {
			timeBeforeFPSUpdate = FPS_UPDATE_INTERVAL;
			displayedFPS = Timer.fps();
		}

		timeBeforeUpdate -= dt;
		if (timeBeforeUpdate <= 0.0) {
			timeBeforeUpdate = UPDATE_INTERVAL;
			updateText(pendingTasksCount);
		}
	}

	function updateText(pendingTasksCount: Int) {
		var gcStats = Gc.stats();

		var gcTotalAllocated = gcStats.totalAllocated;
		var gcCurrentMemory = gcStats.currentMemory;

		// 		textObject.text = '
		// FPS: ${displayedFPS}
		// Pending tasks: ${pendingTasksCount}
		// GC total allocated: ${gcTotalAllocated}
		// GC current memory: ${gcCurrentMemory}';

		// StringBuf doesn't have any clear or reset method, which implies it has to be
		// re-created each frame. It should be avoidable.
		// See https://github.com/HaxeFoundation/haxe/pull/11848
		var sb = new StringBuf();

		sb.add("FPS: ");
		sb.add(displayedFPS);
		sb.add("\n");

		sb.add("Pending tasks: ");
		sb.add(pendingTasksCount);
		sb.add("\n");

		sb.add("GC total allocated: ");
		sb.add(gcTotalAllocated);
		sb.add("\n");

		sb.add("GC current memory: ");
		sb.add(gcCurrentMemory);
		sb.add("\n");

		textObject.text = sb.toString();

		// An even more extreme approach could be to write our own zero-allocation text drawable?
	}
}
