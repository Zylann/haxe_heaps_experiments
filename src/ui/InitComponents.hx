package ui;

class InitComponents {
	static function init() {
		// TODO Why is VSCode constantly highlighting this as an error, despite compiling?
		domkit.Macros.registerComponentsPath("ui.$Comp");
	}
}
