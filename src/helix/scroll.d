module helix.scroll;

import helix.component;
import helix.color;
import helix.mainloop;
import helix.util.vec;
import helix.util.rect;
import helix.layout;
import helix.widgets;
import helix.signal;
static import helix.util.math;

import std.stdio;
import std.algorithm;
import std.conv;

import allegro5.allegro;

class ScrollPane : Component
{
	ScrollBar sbh, sbv;
	ViewPort vp;

	this(MainLoop window, Component _scrollable) {
		super(window, "scrollpane");

		vp = new ViewPort(window);
		vp.setRelative(0,0,16,16,0,0,LayoutRule.STRETCH,LayoutRule.STRETCH);
		vp.setScrollable(_scrollable);
		addChild(vp);

		sbh = new ScrollBar(window, ScrollBar.Orientation.HORIZONTAL, vp);
		sbh.setScrollable(_scrollable);
		sbh.setRelative(0,0,16,0,16,16,LayoutRule.STRETCH,LayoutRule.END);
		addChild(sbh);

		sbv = new ScrollBar(window, ScrollBar.Orientation.VERTICAL, vp);
		sbv.setScrollable(_scrollable);
		sbv.setRelative(0,0,0,16,16,16,LayoutRule.END,LayoutRule.STRETCH);
		addChild(sbv);

		_scrollable.onResize.add((e) { 
			if (e.newValue.w != e.oldValue.w) {
				sbh.updateSliderSize();
			}
			if (e.newValue.h != e.oldValue.h) {
				sbv.updateSliderSize();
			}
		});

		vp.onScroll.add((e) { 
			const delta = e.newValue - e.oldValue;
			if (delta.x != 0) {
				sbh.updateSliderSize();
			}
			if (delta.y != 0) {
				sbv.updateSliderSize();
			}
		});
	}

}

class ViewPort : Component {

	public void move (double deltax, double deltay) {
		int viewx = offset.x + cast(int)(deltax);
		viewx = helix.util.math.bound(0, viewx, cast(int)(scrollable.getPreferredSize().x - w));
		setOffsetX(viewx);

		int viewy = offset.y + cast(int)(deltay);
		viewy = helix.util.math.bound(0, viewy, cast(int)(scrollable.getPreferredSize().y - h));
		setOffsetY(viewy);
	}

	private Model!Point _offset;
	@property Point offset() const { return _offset.dup(); }

	/** event fired whenever offset changes. onScroll is just an alias for offset.onChange  */
	@property ref Signal!(ChangeEvent!Point) onScroll() { return _offset.onChange; }

	final void setOffsetY(double value) {
		const oldVal = _offset.get(); 
		_offset.set(Point(oldVal.x, to!int(value)));
	}
	
	final void setOffsetX(double value) { 
		const oldVal = _offset.get(); 
		_offset.set(Point(to!int(value), oldVal.y));
	}

	this(MainLoop window) {
		super(window, "viewport");
	}

	void setScrollable(Component value) {
		if (scrollable != value) {
			scrollable = value;
			clearChildren();
			addChild(scrollable);
		}
	}
	
	private Component scrollable;

	override void draw(GraphicsContext gc) {
		int ocx, ocy, ocw, och;
		al_get_clipping_rectangle(&ocx, &ocy, &ocw, &och);

		Rectangle clientRect = shape;
		al_set_clipping_rectangle (clientRect.x, clientRect.y, clientRect.w, clientRect.h);

		GraphicsContext gc2 = new GraphicsContext();
		gc2.area = gc.area;
		gc2.offset = offset;

		scrollable.draw(gc2);

		al_set_clipping_rectangle(ocx, ocy, ocw, och);
	}

}

class Slider : Component
{
	private Signal!double onSliderPositionChanged;
	private double rangeMin = 0;
	private double rangeMax = 0;

	private ScrollBar.Orientation orientation;
	
	this(MainLoop window, ScrollBar.Orientation orientation)
	{
		super(window, "slider");
		this.orientation = orientation;
	}
	
	private double mouse_relative_to_slider_edge = 0; // difference between left / top and capture start
	bool captured = false;
	
	override void onMouseUp (Point p)
	{
		super.onMouseUp(p);
		captured = false;
	}
	
	override void onMouseDown (Point p)
	{
		super.onMouseDown(p);
		captured = true;
		switch (orientation)
		{		
			case ScrollBar.Orientation.VERTICAL:
				mouse_relative_to_slider_edge = p.y - y;
				break;
			case ScrollBar.Orientation.HORIZONTAL:
				mouse_relative_to_slider_edge = p.x - x;
				break;
			default:
				assert (0);
		}
		window.captureMouse(this, p);
	}
	
	override void onMouseMove (Point p)
	{
		if (captured)
		{
			double new_slider_edge;
			double slider_size;
			
			switch (orientation)
			{
				case ScrollBar.Orientation.HORIZONTAL:
					new_slider_edge = p.x - mouse_relative_to_slider_edge;
					slider_size = w;
					break;
				case ScrollBar.Orientation.VERTICAL:
					new_slider_edge = p.y - mouse_relative_to_slider_edge;
					slider_size = h;
					break;
				default:
					assert (false);
			}
			
			double pos = new_slider_edge - rangeMin;
			double range = (rangeMax - rangeMin) - slider_size;
			double fraction = range == 0 ? 0 : pos / range;
			if (fraction < 0) fraction = 0;
			if (fraction > 1) fraction = 1;
	
			// We don't actually change the slider directly
			// we update the parent scrollable and rely on the 
			// scrolllistener to move the slider in response.
			onSliderPositionChanged.dispatch(fraction);
		}
	}
}

class ScrollBar : Component
{
	enum Orientation { HORIZONTAL, VERTICAL }
	
	private Component bDec;
	private Component bInc;
	private Slider slider;
	private ViewPort vp;

	Orientation orientation;
	
	private void updateSliderSize()
	{
		double sliderSize = min_slider_size, pos = 0;
		double offset, viewportsize, preferredsize, sliderarea;
		
		if (orientation == Orientation.HORIZONTAL)
		{
			sliderarea = (w - (2 * short_side));
			if (scrollable)
			{
				offset = vp.offset.x;
				viewportsize = vp.w;
				preferredsize = scrollable.getPreferredSize().x;
			}
		}
		else
		{
			sliderarea = (h - (2 * short_side));
			if (scrollable)
			{
				offset = vp.offset.y;
				viewportsize = vp.h;
				preferredsize = scrollable.getPreferredSize().y;
			}
		}
		
		if (scrollable)
		{
			// if viewportsize is too high, or preferredsize is 0, the fraction will be 1. 
			double fraction = (preferredsize == 0) ? 1 : min(1.0, viewportsize / preferredsize);
			
			sliderSize = max(min_slider_size, sliderarea * fraction);
			
			double delta = preferredsize - viewportsize;
			pos = (sliderarea - sliderSize) * ((delta == 0) ? 0 : offset / delta);			
		}
		
		if (orientation == Orientation.HORIZONTAL) {
			slider.setRelative(to!int(short_side + pos), 0, 0, 0, to!int(sliderSize), 0, LayoutRule.BEGIN, LayoutRule.STRETCH);
			window.calculateLayout(this); //TODO: can this be triggered automatically?
			slider.rangeMin = x + short_side;
			slider.rangeMax = x + w - short_side;
		}
		else
		{
			slider.setRelative(0, to!int(short_side + pos), 0, 0, 0, to!int(sliderSize), LayoutRule.STRETCH, LayoutRule.BEGIN);
			window.calculateLayout(this); //TODO: can this be triggered automatically?
			slider.rangeMin = y + short_side;
			slider.rangeMax = y + h - short_side;
		}
	}
	
	private double short_side;
	private double min_slider_size;
	
	this(MainLoop window, Orientation _orientation, ViewPort _vp) {
		super(window, "scrollbar");

		vp = _vp;
		short_side = getStyle().getNumber("size");

		//TODO: should this indrect style lookup be allowed?
		min_slider_size = window.styles.getStyle("slider").getNumber("min-size");
		
		int short_sidei = to!int(short_side);

		bDec = new Button(window);
		bInc = new Button(window);
			
		orientation = _orientation;
		if (orientation == Orientation.HORIZONTAL)
		{
			bDec.onAction.add ((e) { onMove(-4, 0); updateSliderSize(); });
			bDec.icon = window.resources.bitmaps["icon-arrow-left"];
			bDec.setRelative(0, 0, 0, 0, short_sidei, 0, LayoutRule.BEGIN, LayoutRule.STRETCH);
			bInc.onAction.add ((e) { onMove(4, 0); updateSliderSize(); });
			bInc.icon = window.resources.bitmaps["icon-arrow-right"];
			bInc.setRelative(0, 0, 0, 0, short_sidei, 0, LayoutRule.END, LayoutRule.STRETCH);
		}
		else
		{
			bDec.onAction.add((e) { onMove(0, -4); updateSliderSize(); });
			bDec.icon = window.resources.bitmaps["icon-arrow-up"];
			bDec.setRelative(0, 0, 0, 0, 0, short_sidei, LayoutRule.STRETCH, LayoutRule.BEGIN);
			bInc.onAction.add((e) { onMove(0, 4); updateSliderSize(); });
			bInc.icon = window.resources.bitmaps["icon-arrow-down"];
			bInc.setRelative(0, 0, 0, 0, 0, short_sidei, LayoutRule.STRETCH, LayoutRule.END);
		}
		slider = new Slider(window, orientation);
		slider.onSliderPositionChanged.add(e => onSliderPositionChanged(e));
		onResize.add((e) { updateSliderSize(); });
		addChild(bDec);
		addChild(bInc);
		addChild(slider);
	}
	
	private final void onSliderPositionChanged(double fraction)
	{
		if (!scrollable) return;
		
		switch (orientation)
		{
			case Orientation.VERTICAL:
			{
				const offset = fraction * (scrollable.getPreferredSize().y - vp.h);
				vp.setOffsetY(offset);
			}
			break;
			case Orientation.HORIZONTAL:
			{
				const offset = fraction * (scrollable.getPreferredSize().x - vp.w);
				vp.setOffsetX(offset);
			}
			break;
			default: assert(false);
		}		
	}
	
	void onMove(double deltax, double deltay)
	{
		vp.move (deltax, deltay);
	}
	
	private Component scrollable;
	
	void setScrollable(Component value)
	{
		scrollable = value;
		updateSliderSize();
	}
}
