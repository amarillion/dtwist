module helix.scroll;

import helix.component;
import helix.color;
import helix.mainloop;
import helix.util.vec;
import helix.layout;
import helix.widgets;
import helix.signal;

import std.stdio;
import std.algorithm;
import std.conv;

import allegro5.allegro;

/**
A scrollable is a component that is only partially shown, with scrollbars on the side.
Any component that implements the scrollable interface can be added to a scrollpane. 

A scrollable is also the model, i.e. the autoritative source, for scrolling positions.
*/
interface Scrollable
{
	public void move(double deltax, double deltay);
	public void setOffsetY(double value);
	public void setOffsetX(double value);
	public double getViewportWidth();
	public double getViewportHeight();
	public double getOffsetX();
	public double getOffsetY();
}

class ScrollPane : Component
{
	ScrollBar sb1, sb2;
	
	this(MainLoop window, Scrollable child)
	{
		super(window, "scrollpane");

		sb1 = new ScrollBar(window, ScrollBar.Orientation.HORIZONTAL);
		sb1.setScrollable(child);
		sb1.setRelative(0,0,16,0,16,16,LayoutRule.STRETCH,LayoutRule.END);
		addChild(sb1);

		sb2 = new ScrollBar(window, ScrollBar.Orientation.VERTICAL);
		sb2.setScrollable(child);
		sb2.setRelative(0,0,0,16,16,16,LayoutRule.END,LayoutRule.STRETCH);
		addChild(sb2);
		
		//TODO: make cast unnecessary
		(cast(Component)child).setRelative (0,0,16,16,0,0,LayoutRule.STRETCH,LayoutRule.STRETCH);
		addChild(cast(Component)child);
		(cast(Component)child).onResize.add((e) { this.updateScrollBars(); });
		(cast(Component)child).onScroll.add((e) { this.updateScrollBars(); });

	}
	
	void updateScrollBars()
	{
		sb1.updateSliderSize();
		sb2.updateSliderSize();
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
	
	Orientation orientation;
	
	this(MainLoop window) {
		super(window, "slider");

		onResize.add(e => updateSliderSize());
	}
	
	private void updateSliderSize()
	{
		double sliderSize = min_slider_size, pos = 0;
		double offset, viewportsize, preferredsize, sliderarea;
		
		if (orientation == Orientation.HORIZONTAL)
		{
			sliderarea = (w - (2 * short_side));
			if (scrollable)
			{
				offset = scrollable.getOffsetX();
				viewportsize = scrollable.getViewportWidth();

				// TODO: get rid of cast
				preferredsize = (cast(Component)scrollable).getPreferredSize().x;
			}
		}
		else
		{
			sliderarea = (h - (2 * short_side));
			if (scrollable)
			{
				offset = scrollable.getOffsetY();
				viewportsize = scrollable.getViewportHeight();
				preferredsize = (cast(Component)scrollable).getPreferredSize().y;
			}
		}
		
		if (scrollable)
		{
			// if viewportsize is too high, or preferredsize is 0, the fraction will be 1. 
			double fraction = (preferredsize == 0) ? 1 : min (1.0, viewportsize / preferredsize);
			
			sliderSize = max(min_slider_size, sliderarea * fraction);
			
			double delta = preferredsize - viewportsize;
			pos = (sliderarea - sliderSize) * ((delta == 0) ? 0 : offset / delta);			
		}
		
		if (orientation == Orientation.HORIZONTAL) {
			slider.setRelative(to!int(short_side + pos), 0, 0, 0, to!int(sliderSize), 16, LayoutRule.BEGIN, LayoutRule.BEGIN);
			window.calculateLayout(this); //TODO: can this be triggered automatically?
			slider.rangeMin = x + short_side;			
			slider.rangeMax = x + w - short_side;		
		}
		else
		{
			slider.setRelative(0, to!int(short_side + pos), 0, 0, 16, to!int(sliderSize), LayoutRule.BEGIN, LayoutRule.BEGIN);
			window.calculateLayout(this); //TODO: can this be triggered automatically?
			slider.rangeMin = y + short_side;			
			slider.rangeMax = y + h - short_side;		
		}
	}
	
	private double short_side;
	private double min_slider_size;
	
	this(MainLoop window, Orientation _orientation) {
		super(window, "scrollbar");
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
		updateSliderSize();	
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
				double offset = fraction * ((cast(Component)scrollable).getPreferredSize().x - scrollable.getViewportHeight());
				scrollable.setOffsetY(offset);
			}
			break;
			case Orientation.HORIZONTAL:
			{
				double offset = fraction * ((cast(Component)scrollable).getPreferredSize().y - scrollable.getViewportWidth());
				scrollable.setOffsetX(offset);
			}
			break;
			default: assert(false);
		}		
	}
	
	void onMove(double deltax, double deltay)
	{
		if (scrollable) 
		{
			scrollable.move (deltax, deltay);
		}
	}
	
	private Scrollable scrollable;
	
	void setScrollable (Scrollable value)
	{
		scrollable = value;
		updateSliderSize();
	}
	
	private ALLEGRO_COLOR bg;
	
}
