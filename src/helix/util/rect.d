module helix.util.rect;

import helix.util.math;
import helix.util.vec;

struct rect(T)
{
	T x;
	T y;
	T w;
	T h;

	@property T x2() const { return x + w; }
	@property T y2() const { return y + h; }
	
	//TODO: choose doubles or Rectangles as parameter for overlaps and Intersection
	bool overlaps (T _x, T _y, T _w, T _h) const
	{
		const xoverlap = (_x < x + w) && (_x + _w > x);
		const yoverlap = (_y < y + h) && (_y + _h > y);  
		return xoverlap && yoverlap;
	}
	
	rect!T intersection(const Rectangle!T other) const
	{
		T x1 = max (x, other.x);
		T y1 = max (y, other.y);
		T x2 = min (x + w, other.x + other.w);
		T y2 = min (y + h, other.y + other.h); 
		return rect!(T)(x1, y1, x2 - x1, y2 - y1);
	}

	bool contains(const vec!(2, T) p) const {
		return (p.x >= x && p.x < x + w && p.y >= y && p.y < y + h);
	}
}

alias Rectangle = rect!(int);
