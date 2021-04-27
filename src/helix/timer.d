module helix.timer;

import helix.component;
import helix.mainloop;
import std.stdio;

class Timer : Component {

	void delegate() action;
	long remain;

	this(MainLoop window, long remain, void delegate() action) {
		super(window, "default");
		hidden = true;
		this.action = action;
		this.remain = remain;
	}

	override void draw(GraphicsContext gc) {}

	override void update() {
		if (killed) return;
		
		remain--;
		if (remain == 0) {
			action();
			kill();
		}
	}
}