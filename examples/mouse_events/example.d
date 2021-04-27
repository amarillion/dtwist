import helix.mainloop;
import helix.component;
import helix.widgets;
import helix.layout;
import std.stdio;

import allegro5.allegro;

class MainState : Component {

	this(MainLoop window) {
		super(window, "default" /* TODO: unnecessary... */);
		
		Button button = new Button(window);
		button.text = "Test button";
		button.setRelative(0, 0, 0, 0, 200, 32, LayoutRule.CENTER, LayoutRule.CENTER);
		button.onAction.add({ writeln ("Button clicked"); });
		addChild(button);

		Button button2 = new Button(window);
		button2.text = "Disabled button";
		button2.setRelative(0, 80, 0, 0, 200, 32, LayoutRule.CENTER, LayoutRule.CENTER);
		button2.disabled = true;
		button2.onAction.add({ writeln ("Button2 clicked"); });
		addChild(button2);
	}
}


void main()
{
	al_run_allegro({

		al_init();
		auto mainloop = new MainLoop("mouse_events_example");
		mainloop.init();
		
		writefln("%s", mainloop.styles.getStyle("button"));
		writefln("%s", mainloop.styles.getStyle("button", "selected"));

		mainloop.addState("MainState", new MainState(mainloop));
		mainloop.switchState("MainState"); // TODO: if there is only one state, no need to switch to it...

		mainloop.run();

		return 0;
	});

}