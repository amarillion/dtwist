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

	private Point _offset;
	@property Point offset() { return _offset; }

	//TODO: system should provide more help in implementing these.
	// maybe they should be built into Component?
	override void move(double deltax, double deltay) {}
	
	override void setOffsetY(double value) { 
		const oldVal = offset; 
		const newCoord = to!int(value);
		if (newCoord != oldVal.y) {
			_offset.y = newCoord;
			onScroll.dispatch(ChangeEvent!Point(oldVal, _offset));
		}
	}
	
	override void setOffsetX(double value) { 
		const oldVal = offset;
		const newCoord = to!int(value); 
		if (newCoord != oldVal.x) {
			_offset.x = newCoord;
			onScroll.dispatch(ChangeEvent!Point(oldVal, _offset)); 
		}
	}
	
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

	Model!Point cursor;

	override void draw(GraphicsContext gc) {
		if (_tileMap is null) { return; }
		Point ofst = Point(-x, -y) + offset;
		draw_tilemap(_tileMap, shape, ofst);
		
		const mp = cursor.get();
		Point px1 = (mp * _tileMap.tilelist.tileSize) - ofst;
		Point px2 = px1 + _tileMap.tilelist.tileSize - 1;
		al_draw_rectangle(px1.x, px1.y, px2.x, px2.y, Color.WHITE, 1.0);
	}

	override void onMouseDown(Point p) {
		const ofst = Point(-x, -y) + offset;
		Point mp = (p + ofst) / _tileMap.tilelist.tileSize;
		if (_tileMap.layers[0].inRange(mp)) {
			cursor.set(mp);
		}
	}

}