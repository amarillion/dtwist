import helix.mainloop;
import helix.color;
import helix.component;
import helix.widgets;
import helix.layout;

import std.stdio;
import std.conv;
import std.math;
import std.json;

import allegro5.allegro;
import allegro5.allegro_primitives;

import plot;
import text;

class Engine : Component
{
	double a = 0.5;
	double b = -2.5;
	double c = + 2.5;
	
	this(MainLoop window)
	{	
		super(window, "default");

		auto pa = new PlotArea(window);
		pa.setRelative (120, 20, 20, 20, 0, 0, LayoutRule.STRETCH, LayoutRule.STRETCH);
		pa.addSeries((double x) { return a * x * x + b * x + c; }); 
		addChild (pa);
		
		Label lblA = new Label(window, "a=" ~ to!string(a));
		// TODO: auto-sizing
		// lblA.setPosition(20, 20);
		lblA.setRelative(20, 20, 0, 0, 80, 20, LayoutRule.BEGIN, LayoutRule.BEGIN);
		addChild (lblA);

		TextField txtA = new TextField (window, to!string(a));
		// txtA.setPosition(20, 40);
		txtA.setRelative(20, 40, 0, 0, 80, 20, LayoutRule.BEGIN, LayoutRule.BEGIN);
		txtA.onAction.add((e) { a = to!double(txtA.doc.getText()); /* pa.dirty = true; */ });
		addChild (txtA);
		
		Label lblB = new Label(window, "b=" ~ to!string(b));
		// lblB.setPosition(20, 60);
		lblB.setRelative(20, 60, 0, 0, 80, 20, LayoutRule.BEGIN, LayoutRule.BEGIN);
		addChild (lblB);

		TextField txtB = new TextField (window, to!string(b));
		// txtB.setPosition(20, 80);
		txtB.setRelative(20, 80, 0, 0, 80, 20, LayoutRule.BEGIN, LayoutRule.BEGIN);
		txtB.onAction.add((e) { b = to!double(txtB.doc.getText()); /* pa.dirty = true; */ });
		addChild (txtB);

		Label lblC = new Label(window, "c=" ~ to!string(c));
		// lblC.setPosition(20, 100);
		lblC.setRelative(20, 100, 0, 0, 80, 20, LayoutRule.BEGIN, LayoutRule.BEGIN);
		addChild (lblC);

		TextField txtC = new TextField (window, to!string(c));
		// txtC.setPosition(20, 120);
		txtC.setRelative(20, 120, 0, 0, 80, 20, LayoutRule.BEGIN, LayoutRule.BEGIN);
		txtC.onAction.add((e) { c = to!double(txtC.doc.getText()); /* pa.dirty = true; */ });
		addChild (txtC);
		
		//TODO
		// MenuBar mb = new MenuBar();
		// add (mb);
		
		// Menu mFile = new Menu("File");
		// mb.add (mFile);
		
		// Menu mFunction = new Menu("Function");
		// mb.add (mFunction);

		// mFile.add (new MenuItem("New"));
		// mFile.add (new MenuItem("Load"));
		// mFile.add (new MenuItem("Save"));
		// mFile.add (new MenuItem("Exit"));
		
	}
}

void main()
{
	al_run_allegro(
    {
        al_init();
		auto mainloop = new MainLoop();		
		mainloop.init();
		mainloop.styles.applyString(`{ 
			"body": { "background": "steelblue" },
			"textinput": { 
				"background": "white", 
				"border": "#888888", 
				"border-right": "#DDDDDD", 
				"border-bottom": "#DDDDDD", 
				"border-width": 2.0, 
				"color": "black",
				"cursor-color": "red",
				"blinkrate": 10,
			}
		}`);
		auto engine = new Engine(mainloop);
		mainloop.addState("MainState", engine);
		mainloop.switchState("MainState");
		mainloop.run();
		return 0;
	});

}