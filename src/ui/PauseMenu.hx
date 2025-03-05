package ui;

@:uiComp("pause-menu")
class PauseMenu extends h2d.Flow implements h2d.domkit.Object {
	static var SRC = <pause-menu layout="vertical">
        <text class="h1" text={"Pause"}/>
		<button("Continue") public id="continueButton"/>
		<button("Quit") public id="quitButton"/>
    </pause-menu>

	public function new(?parent: h2d.Object) {
		super(parent);
		initComponent();

		// Just to block the mouse
		// TODO Actually we need to block it on the whole screen somehow,
		// otherwise the player controller would catch it and enable the FPS controller locking the mouse
		enableInteractive = true;
	}
}

@:uiComp("button")
class Button extends h2d.Flow implements h2d.domkit.Object {
	static var SRC = <button>
		<text public id="label" />
	</button>

	public var text(get, set): String;

	public function new(text: String, ?parent: h2d.Object) {
		super(parent);
		initComponent();

		this.text = text;

		enableInteractive = true;

		interactive.onClick = function(_) {
			onClick();
		}
		interactive.onOver = function(_) {
			dom.hover = true;
		};
		interactive.onOut = function(_) {
			dom.hover = false;
		};
		interactive.onPush = function(_) {
			dom.active = true;
		};
		interactive.onRelease = function(_) {
			dom.active = false;
		};
	}

	public dynamic function onClick() {}

	function get_text() {
		return label.text;
	}

	function set_text(s) {
		label.text = s;
		return s;
	}
}
