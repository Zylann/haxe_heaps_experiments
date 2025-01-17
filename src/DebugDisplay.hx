import hxd.Timer;
import hxd.res.DefaultFont;

class DebugDisplay {
	static inline var FPS_UPDATE_INTERVAL = 0.25;

	var textObject: h2d.Text;
	var timeBeforeFPSUpdate = 0.0;
	var displayedFPS = 0.0;

	public function new(s2d: h2d.Scene) {
		textObject = new h2d.Text(DefaultFont.get(), s2d);
	}

	public function update(dt: Float, pendingChunksCount: Int) {
		timeBeforeFPSUpdate -= dt;
		if (timeBeforeFPSUpdate <= 0.0) {
			timeBeforeFPSUpdate = FPS_UPDATE_INTERVAL;
			displayedFPS = Timer.fps();
		}
		textObject.text = 'FPS: ${displayedFPS}\nLoading chunks: ${pendingChunksCount}';
	}
}
