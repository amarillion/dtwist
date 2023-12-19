module helix.component;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_image;
import allegro5.allegro_font;
import allegro5.allegro_ttf;
import allegro5.allegro_color;

import helix.util.math;
import helix.mainloop;
import helix.style;
import helix.signal;
import helix.util.rect;
import helix.util.vec;
import helix.layout;
import helix.color;
import helix.allegro.bitmap;
import helix.allegro.font;

import std.string;
import std.algorithm;
import std.range;
import std.json;
import std.conv;

class GraphicsContext
{
	Rectangle area;
	Point offset;
}

enum SizeRule {
	AUTO,
	HEIGHT_DEPENDS_ON_WIDTH,
	MANUAL
};

struct ComponentEvent {
	Component source;
}


/**
A component occupies an area (x,y,w,h) and 
knows how to draw itself. 

It does not need to opaquely fill the area,
i.e. it can be transparent or non-rectangular.

A component receives mouse events (if the mouse is over it)
or keyboard events (if it has keyboard focus).
*/
class Component
{		
	//TODO: encapsulate
	Component[] children;
	string type;
	string id;
	Bitmap icon;
	string text = null;

	//TODO: put collection of styles together more sensibly...
	protected Style[5] styleCache = [null, null, null, null, null]; // 0: normal, 1: selected, 2: disabled, 3: hover, 4: focused ...
	StyleData localStyle;
	StyleData ancestorStyle;
	
	protected MainLoop window = null;
	
	// FLAGS:
	bool selected = false; // indicates toggled, checked, pressed or selected state 
	bool hover = false; // indicates mouse is hovering over element - hover state.
	bool hidden = false; // invisible, draw() not called.
	bool focused = false; // used for keyboard focus. Display with outline.
	bool disabled = false; // grayed out
	bool invalid = false; // used for input validation
	bool readonly = false; // used for edit controls
	bool canFocus = false; // accepts the focus if clicked on or tabbed to.
	bool killed = false; // destroyed, waiting to be removed from parent.

	this(MainLoop window, string type) {
		this.window = window;
		this.type = type;
	}

	Style getStyle(int mode = 0) {	
		if (styleCache[mode] is null) {
			Style result;
			switch (mode) {
				case 0: result = window.styles.getStyle(type, "", ancestorStyle, localStyle); break;
				case 1: result = window.styles.getStyle(type, "selected", ancestorStyle, localStyle); break;
				case 2: result = window.styles.getStyle(type, "disabled", ancestorStyle, localStyle); break;
				case 3: result = window.styles.getStyle(type, "hover", ancestorStyle, localStyle); break;
				case 4: result = window.styles.getStyle(type, "focused", ancestorStyle, localStyle); break;
				default: assert(0);
			}
			styleCache[mode] = result;
		}
		return styleCache[mode];
	}

	/** 
		style override for this particular element,
		most specific, overrides all others
	 */
	void setLocalStyle(JSONValue value) {
		localStyle = StyleData.fromJSON("local", value);
		styleCache = [null, null, null, null, null]; // clear cache
	}

	/**
		style from one of the ancestors of this node.
		should be behind local style and type-specific styles
		(TODO: currently only applied to RichTextComponent)
	*/
	void setAncestorStyle(StyleData value) {
		ancestorStyle = value;
		styleCache = [null, null, null, null, null]; // clear cache
	}		

	void setText(string value) {
		text = value;
	}

	final void add(Component c) {
		children ~= c;
	}

	final void removeChild(Component c) {
		children = children.filter!(i => i != c).array;
	}

	// TODO: Deprecated -> use add()
	final void addChild(Component c) {
		add(c);
	}

	final void clearChildren() {
		children = [];
	}

	// NOTE: can not be set directly. Will always be derived from applyLayout.
	private Rectangle _shape;

	@property final Rectangle shape() {
		return this._shape;
	}

	protected SizeRule sizeRule = SizeRule.MANUAL; //TODO: part of layout data?
	// TODO: always AUTO unless manually set?
	private LayoutData layoutData;

	void layoutFromJSON(JSONValue[string] jsonObj) {
		layoutData.fromJSON(jsonObj);
	}

	/** calculate shape for this component. Non-recursive. */
	final void applyLayout(Rectangle parentRect) {
		// TODO - can this be done at the "layoutData" level? It doesn't have access to preferredSize... Pass as lazy parameter?
		if (sizeRule == SizeRule.AUTO) {
			const p = getPreferredSize();
			layoutData.width = p.x; 
			layoutData.height = p.y;
		}
		else if (sizeRule == SizeRule.HEIGHT_DEPENDS_ON_WIDTH) {
			layoutData.height = calculateHeight(layoutData.width);
		}
		
		const newShape = layoutData.calculate(parentRect);
		if (newShape != _shape) {
			const oldShape = _shape;
			_shape = newShape;
			this.onResize.dispatch(ChangeEvent!Rectangle(oldShape, newShape));
		}
	}

	//TODO: naming
	void calculateRecursive(Rectangle parentRect) {
		applyLayout(parentRect);
		
		foreach(child; children) {
			child.calculateRecursive(shape);
		}
	}

	// designed for overriding
	protected int calculateHeight(int width) {
		return 0;
	}

	// to be overridden by ViewPort only.
	@property
	Point offset() const { return Point(0); } 

	// designed for overriding
	Point getPreferredSize() {
		const width = getStyle().getNumber("width");
		const height = getStyle().getNumber("height");
		return Point(to!int(width), to!int(height));
	}

	void update() {
		if (killed) return;
		foreach(child; children) {
			child.update();
		}
		children = children.filter!(c => !c.killed).array;
	}

	void kill() {
		killed = true;
	}

	protected final void drawBackground(Style style) {
		ALLEGRO_COLOR background = style.getColor("background");
		if (!background.isTransparent()) {
			al_draw_filled_rectangle(x, y, x + w, y + h, background);
		}
	}

	protected final void drawBorder(Style style) {
		const borderWidth = style.getNumber("border-width");
		if (borderWidth > 0) {
			al_draw_line(x, y, x + w, y, style.getColor("border-top"), borderWidth);
			al_draw_line(x + w, y, x + w, y + h, style.getColor("border-right"), borderWidth);
			al_draw_line(x + w, y + h, x, y + h, style.getColor("border-bottom"), borderWidth);
			al_draw_line(x, y + h, x, y, style.getColor("border-left"), borderWidth);
		}
	}

	void draw(GraphicsContext gc) {
		if (killed || hidden) return;
		
		const state = disabled ? 2 : (selected ? 1 : (focused ? 4 : (hover ? 3 : 0)));
		Style style = getStyle(state);
		
		// render shadow
		// TODO

		drawBackground(style);		
		drawBorder(style);

		// render icon
		if (icon !is null) {
			int iw = icon.w;
			int ih = icon.h;
			al_draw_bitmap (icon.ptr, x + (w - iw) / 2, y + (h - ih) / 2, 0);
		}

		// render TextSpan
		if (text != "") {
			//TODO: use stringz...
			ALLEGRO_COLOR color = style.getColor("color");
			Font font = style.getFont();
			int th = font.lineHeight;
			al_draw_text(font.ptr, color, x + w / 2, y + (h - th) / 2, ALLEGRO_ALIGN_CENTER, toStringz(text));
		}

		// render focus outline...
		ALLEGRO_COLOR outlineColor = style.getColor("outline");
		if (outlineColor != Color.TRANSPARENT) {
			//TODO: make outline inset configurable...
			al_draw_rectangle(x + 4, y + 4, x + w - 8, y + h - 8, outlineColor, 1.0);
		}

		// TODO

		// and draw children.
		// TODO - should this be done by MainLoop/Window?
		foreach (child; children) {
			child.draw(gc);
		}
	}
	
	public final void setRelative(int x1, int y1, int x2, int y2, int _w, int _h, LayoutRule horizontalRule, LayoutRule verticalRule) {
		layoutData = LayoutData(x1, y1, x2, y2, _w, _h, horizontalRule, verticalRule);
	}

	/** 
		set both position and size together 
		@deprecated use layoutData instead.
	*/
	public final void setShape(int _x, int _y, int _w, int _h)
	{
		setRelative(_x, _y, 0, 0, _w, _h, LayoutRule.BEGIN, LayoutRule.BEGIN);
	}

	/** set both x and y together */
	public final void setPosition (int _x, int _y)
	{
		shape.x = _x;
		shape.y = _y;
	}	
	
	/** should return true if keyboard event is handled, false otherwise */
	public bool onKey(int code, int c, int mod) { return false; }
	
	Signal!ComponentEvent onAction;

	public void onMouseEnter() {
		hover = true;
	}

	public void onMouseLeave() {
		hover = false;
		selected = false;
	}
	
	public void onMouseMove(Point p) { }

	public void onMouseDown(Point p) { }

	public void onMouseUp(Point p) { }

	public void gainFocus() { 
		focused = true;
	}
		
	public void loseFocus() { 
		focused = false;
	}
	
	/**
		Called whenever the shape of this component has been recalculated 
	*/
	Signal!(ChangeEvent!Rectangle) onResize;

	public bool contains(Point p)
	{
		return shape.contains(p);
	}
	
	@property int x() { return shape.x; }
	@property int y() { return shape.y; }
	@property int w() { return shape.w; }
	@property int h() { return shape.h; }

	@property void x(int val) { shape.x = val; }
	@property void y(int val) { shape.y = val; }
	@property void w(int val) { shape.w = val; }
	@property void h(int val) { shape.h = val; }
}
