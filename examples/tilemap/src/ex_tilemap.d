module ex_tilemap;

import std.stdio;
import std.conv;
import std.math;
import std.json;
import std.format;

import allegro5.allegro;
import allegro5.allegro_font;
import allegro5.allegro_primitives;
import helix.mainloop;
import helix.component;
import helix.color;
import helix.widgets;
import helix.scroll;
import helix.tilemap;
import helix.layout;
import helix.util.vec;

import tilemapview;

class Engine : Component {
	Label l1;
	Label lblCursor;
	Button b1;

	// tilelist
	ScrollPane sp;
	TilemapView tmv;
	
	int count = 0;

	this(MainLoop window) {
		super(window, "default"); //TODO: window should be set by root component. No need to pass in constructor.

		l1 = new Label (window, "Hello World");
		addChild (l1);
		
		b1 = new Button(window, "Button", (e) { count++; b1.text = "pressed #" ~ to!string (count); });
		b1.setShape(50, 50, 200, 16); //TODO: some default width & height
		addChild (b1);


		TileMap tileMap = TileMap.fromTiledJSON(window.resources.getJSON("level4-tiled"));
		tileMap.tilelist.bmp = window.resources.bitmaps["tiles"];

		tmv = new TilemapView(window);
		tmv.tileMap = tileMap;

		auto labelFormatter = (Point p) => format("Cursor at %s", p);
		lblCursor = new Label (window, labelFormatter(tmv.cursor.get()));
		addChild (lblCursor);
		// TODO: left-align style
		lblCursor.setRelative(16, 0, 16, 16, 0, 16, LayoutRule.STRETCH, LayoutRule.END);
		lblCursor.setLocalStyle(parseJSON(`{ "font-size": 32, "color": "yellow" }`)); //TODO: alternative without JSON
		tmv.cursor.onChange.add((e) { lblCursor.text = labelFormatter(e.newValue); });

		//TODO: hide / show scrollbars automatically
		sp = new ScrollPane(window, tmv);
		sp.setRelative(16, 16, 16, 64, 0, 0, LayoutRule.STRETCH, LayoutRule.STRETCH);
		addChild (sp);
	}	
}

void main()
{	
	al_run_allegro({
		al_init();
		auto mainloop = new MainLoop(MainConfig.of.appName("ex_tilemap").targetFps(30));
		mainloop.init();
		
		//TODO: glob
		//TODO: auto-refresh
		mainloop.resources.addFile("data/DejaVuSans.ttf");
		mainloop.resources.addFile("data/style.json");
		mainloop.resources.addFile("data/tiles.png");
		mainloop.resources.addFile("data/level4-tiled.json");

		mainloop.styles.applyResource("style");

		mainloop.addState("MainState", new Engine(mainloop));
		mainloop.switchState("MainState"); //TODO: shoud automatically switch state if there is only one.

		mainloop.run();

		return 0;
	});
}