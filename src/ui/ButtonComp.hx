package ui;

@:uiComp("button")
class ButtonComp extends h2d.Flow implements h2d.domkit.Object {
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
