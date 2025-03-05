package ui;

class InitComponents {
	static function init() {
		#if macro
		domkit.Macros.registerComponentsPath("ui.$Comp");
		#end
	}
}
