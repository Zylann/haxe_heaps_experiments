package util;

import haxe.Exception;
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
	var labels: Array<String> = [];
	var lines: Array<String> = [];

	static var singleton: DebugDisplay;

	// var stringBuffer: StringBuf = new StringBuf();

	public function new(s2d: h2d.Scene) {
		textObject = new h2d.Text(DefaultFont.get(), s2d);
		if (singleton != null) {
			throw new Exception("Only one instance allowed");
		}
		singleton = this;
	}

	public static inline function setText(label: String, line: String) {
		#if debug_display
		singleton.setTextInternal(label, line);
		#end
	}

	function setTextInternal(label: String, line: String) {
		var index = labels.indexOf(label);
		if (index == -1) {
			index = label.length;
			labels.push(label);
			lines.push("");
		}
		lines[index] = line;
	}

	public function update(dt: Float) {
		timeBeforeFPSUpdate -= dt;
		if (timeBeforeFPSUpdate <= 0.0) {
			timeBeforeFPSUpdate = FPS_UPDATE_INTERVAL;
			displayedFPS = Timer.fps();
		}

		timeBeforeUpdate -= dt;
		if (timeBeforeUpdate <= 0.0) {
			timeBeforeUpdate = UPDATE_INTERVAL;
			updateText();
		}
	}

	function updateText() {
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

		sb.add("GC total allocated: ");
		sb.add(gcTotalAllocated);
		sb.add("\n");

		sb.add("GC current memory: ");
		sb.add(gcCurrentMemory);
		sb.add("\n");

		for (index in 0...labels.length) {
			sb.add(labels[index]);
			sb.add(": ");
			sb.add(lines[index]);
			sb.add("\n");
		}

		textObject.text = sb.toString();

		// An even more extreme approach could be to write our own zero-allocation text drawable?
	}
}
