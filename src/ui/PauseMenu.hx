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
