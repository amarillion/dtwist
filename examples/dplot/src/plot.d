module plot;

import std.math;
import std.conv;
import std.stdio;
import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_font;
import helix.component;
import helix.color;
import helix.mainloop;
import helix.layout;
import helix.style;

class PlotArea : Component
{
	this(MainLoop window) {
		super(window, "default");
	}

	interface Series
	{
		double f(int idx);
	}
	
//	class TimeSeries : Series
//	{
//		
//	}
	
	class FunctionWrapper : Series
	{
		double delegate (double) func;
		
		this (double delegate (double) _func)
		{
			func = _func;
		}
		
		override double f(int idx)
		{
			return func(toPlotX (idx + x + marginx));
		}
	}
	
	//TODO: grid lines, axis labels
	//TODO: plot time series data
	
	double xaxStart = 0;
	double xaxEnd = 2 * PI;
	
	double majorTickX = 1;
	
	// note axis inverted, start is at bottom
	double yaxStart = -1;
	double yaxEnd = 1;
	
	double majorTickY = 0.5;
	
	// plot margins
	double marginx = 30;
	double marginy = 30;
	
	double ploth()
	{
		return h - (2 * marginy);
	}
	
	double plotw()
	{
		return w - (2 * marginx);
	}
	
	double plotLeft()
	{
		return x + marginx;
	}
	
	double plotTop()
	{
		return y + marginy;
	}
	
	double plotRight()
	{
		return x + w - marginx;
	}
	
	double plotBottom()
	{
		return y + h - marginy;
	}
	
	double toPlotX (double screenx)
	{
		return (screenx - plotLeft()) / plotw() * (xaxEnd - xaxStart);		
	}
	
	double toPlotY (double screeny)
	{
		return (screeny - plotTop()) / ploth() * (yaxEnd - yaxStart);		
	}
	
	double toScreenX (double plotx)
	{
		return plotLeft() + (plotw() / (xaxEnd - xaxStart)) * plotx;
	}
	
	double toScreenY (double ploty)
	{
		return plotTop() + (ploth() / (yaxEnd - yaxStart)) * (yaxEnd - ploty);		
	}
	
	// series data
	Series[] series = []; 
	
	void addSeries(double delegate(double) func)
	{
		series ~= new FunctionWrapper (func);
	}
	
	ALLEGRO_COLOR[] colors = [ Color.RED, Color.GREEN, Color.BLUE, Color.MAGENTA, Color.CYAN ];
	
	override void draw(GraphicsContext gc) 
	{	
		Style style = getStyle();
		auto font = style.getFont();
		al_draw_filled_rectangle (x, y, x + w, y + h, Color.WHITE);

		// draw horizontal ticks / grid lines
		for (double ploty = majorTickY * (cast(int)(yaxStart / majorTickY)); ploty <= yaxEnd; ploty += majorTickY)
		{
			double screeny = toScreenY(ploty);
			al_draw_line(plotLeft(), screeny, plotRight(), screeny, Color.GREY, 1);
			al_draw_text(font.ptr, Color.GREY, plotLeft(), screeny, ALLEGRO_ALIGN_RIGHT, cast(const char*) (to!string(ploty) ~ '\0'));
		}

		// x-axis
		al_draw_line(plotLeft(), plotBottom(), plotRight(), plotBottom(), Color.BLUE, 1);
		
		// draw vertical ticks / grid lines
		for (double plotx = majorTickX * (cast(int)(xaxStart / majorTickX)); plotx <= xaxEnd; plotx += majorTickX)
		{
			double screenx = toScreenX(plotx);
			al_draw_line(screenx, plotTop(), screenx, plotBottom(), Color.GREY, 1);
			al_draw_text(font.ptr, Color.GREY, screenx, y + h - (marginy / 2), ALLEGRO_ALIGN_CENTRE, cast(const char*) (to!string(plotx) ~ '\0'));
		}
		
		// y-axis
		al_draw_line(plotLeft(), plotTop(), plotLeft(), plotBottom(), Color.BLUE, 1);
		
		//TODO: build into component system.
		al_set_clipping_rectangle (cast(int)plotLeft(), cast(int)plotTop(), 
			cast(int)plotw(), cast(int)ploth());

		// convert xpx to xax
		foreach (ulong i; 0 .. series.length)
		{
			for (int idx = 0; idx < plotw(); idx++)
			{
				// function
				double yax = series[i].f(cast(int)idx);
				// convert yax back to ypx
				double ypx = toScreenY (yax);
				
				al_put_pixel (cast(int)(plotLeft() + idx), cast(int)(ypx), colors[i % colors.length]);
			} 
		}

		al_reset_clipping_rectangle();
	}

}
