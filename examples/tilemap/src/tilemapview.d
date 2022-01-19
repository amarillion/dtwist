module tilemapview;

import helix.component;
import helix.util.grid;
import helix.tilemap;
import helix.util.coordrange;
import helix.util.vec;
import helix.mainloop;
import helix.signal;
import helix.color;

import std.conv;

import allegro5.allegro;
import allegro5.allegro_primitives;

// TODO: generic grid view that can be used for tables as well?
class TilemapView : Component {

	override Point getPreferredSize() const { return Point (_tileMap.pxWidth(), _tileMap.pxHeight()); }

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
		Point ofst = Point(-x, -y) + gc.offset;
		draw_tilemap(_tileMap, shape, ofst);
		
		Point px1 = (cursor * _tileMap.tilelist.tileSize) - ofst;
		Point px2 = px1 + _tileMap.tilelist.tileSize - 1;
		al_draw_rectangle(px1.x, px1.y, px2.x, px2.y, Color.WHITE, 1.0);
	}

	override void onMouseDown(Point p) {
		const ofst = Point(-x, -y); //TODO + offset;
		Point mp = (p + ofst) / _tileMap.tilelist.tileSize;
		if (_tileMap.layers[0].inRange(mp)) {
			cursor = mp;
		}
	}

}