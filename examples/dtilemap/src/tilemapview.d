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

import allegro5.allegro;
import allegro5.allegro_primitives;

// TODO: generic grid view that can be used for tables as well?
class TilemapView : Component, Scrollable {

	//TODO: system should provide more help in implementing these.
	// maybe they should be built into Component?
	override void move(double deltax, double deltay) {}
	override void setOffsetY(double value) {}
	override void setOffsetX(double value) {}
	
	override double getViewportWidth() { return w; }
	override double getViewportHeight() { return h; }
	override double getOffsetX() { return 0.0; }
	override double getOffsetY() { return 0.0; }
	
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
		Point ofst = Point(0);
		draw_tilemap(_tileMap, shape, ofst);
		
		Point p = selectedTile.get();
		Point p1 = p * _tileMap.tilelist.tileSize;
		Point p2 = p1 + _tileMap.tilelist.tileSize - 1;
		al_draw_rectangle(p1.x, p1.y, p2.x, p2.y, Color.WHITE, 1.0);
	}

	override void onMouseDown(Point p) {
		Point mp = p / _tileMap.tilelist.tileSize;
		if (_tileMap.layers[0].inRange(mp)) {
			selectedTile.set(mp);
		}
	}

}