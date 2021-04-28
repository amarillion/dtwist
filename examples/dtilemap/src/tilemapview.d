module tilemapview;

import helix.component;
import helix.util.grid;
import helix.tilemap;
import helix.util.coordrange;
import helix.util.vec;
import helix.mainloop;
import helix.signal;
import helix.color;
import helix.scroll;

import std.conv;

import allegro5.allegro;
import allegro5.allegro_primitives;

// TODO: generic grid view that can be used for tables as well?
class TilemapView : Component, Scrollable {

	Point offset;

	//TODO: system should provide more help in implementing these.
	// maybe they should be built into Component?
	override void move(double deltax, double deltay) {}
	override void setOffsetY(double value) { offset.y = to!int(value); onScroll.dispatch(); }
	override void setOffsetX(double value) { offset.x = to!int(value); onScroll.dispatch(); }
	
	override double getViewportWidth() { return w; }
	override double getViewportHeight() { return h; }
	override double getOffsetX() { return offset.x; }
	override double getOffsetY() { return offset.y; }
	
	override Point getPreferredSize() { return Point (_tileMap.pxWidth(), _tileMap.pxHeight()); }

	this(MainLoop window) {
		super(window, "default");
	}

	private TileMap _tileMap;
	@property void tileMap(TileMap value) {
		if (_tileMap != value) {
			_tileMap = value;
			//TODO: request relayout indirectly?
			window.calculateLayout(this);
		}
	}

	Model!Point selectedTile;

	override void draw(GraphicsContext gc) {
		if (_tileMap is null) { return; }
		Point ofst = Point(-x, -y) + offset;
		draw_tilemap(_tileMap, shape, ofst);
		
		Point mp = selectedTile.get();
		Point px1 = (mp * _tileMap.tilelist.tileSize) - ofst;
		Point px2 = px1 + _tileMap.tilelist.tileSize - 1;
		al_draw_rectangle(px1.x, px1.y, px2.x, px2.y, Color.WHITE, 1.0);
	}

	override void onMouseDown(Point p) {
		Point ofst = Point(-x, -y) + offset;
		Point mp = (p + ofst) / _tileMap.tilelist.tileSize;
		if (_tileMap.layers[0].inRange(mp)) {
			selectedTile.set(mp);
		}
	}

}