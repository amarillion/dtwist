module helix.widgets;

import helix.component;
import helix.mainloop;
import helix.util.vec;

import allegro5.allegro;
import allegro5.allegro_font;
import std.array;
import std.string : toStringz;

import helix.allegro.bitmap;
import helix.allegro.font;

import std.stdio;

class ImageComponent : Component {

	Bitmap img = null;

	this(MainLoop window) {
		super(window, "img");
	}

	override void draw(GraphicsContext gc) {
		assert(img);
		
		// stretch mode...
		// TODO: allow other drawing modes...
		int iw = img.w;
		int ih = img.h;
		al_draw_scaled_bitmap(img.ptr, 0, 0, iw, ih, x, y, w, h, 0);
	}
}

class Button : Component {

	this(MainLoop window, string text, void delegate(ComponentEvent) action) {
		this(window);
		this.text = text;
		this.onAction.add(action);
		canFocus = true;
	}

	this(MainLoop window) {
		super(window, "button");
	}

	override void onMouseUp(Point p) {
		this.selected = false;
	}

	override void onMouseDown(Point p) {
		if (!disabled) {
			onAction.dispatch(ComponentEvent(this));
		}
		this.selected = true;
	}
}

class PreformattedText : Component {
	
	this(MainLoop window) {
		super(window, "pre");
	}

	override void draw(GraphicsContext gc) {
		// given component width...
		auto style = getStyle();
		Font font = style.getFont();
		ALLEGRO_COLOR color = style.getColor("color");
			
		// split text by newlines...
		int y = this.shape.y;
		const th = font.lineHeight;
		
		foreach(line; text.split("\n")) {
			al_draw_text(font.ptr, color, this.shape.x, y,  ALLEGRO_ALIGN_LEFT, toStringz(line));
			y += th;
		}
	}
}

/** 
	Simple single-line text component.
	No word-wrapping...
*/
class Label : Component {
	this(MainLoop window, string text) { super(window, "default"); this.text = text; }
}
