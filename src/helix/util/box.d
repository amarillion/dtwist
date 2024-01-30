module helix.util.box;

import helix.util.vec;
import helix.util.coordrange;

/** 
 * An n-dimensional box.
 */
struct Box(int N, T) {
	alias Coord = vec!(N, T);
	
	Coord pos;
	Coord size;

	/* use pos.x instead */
	deprecated @property T x() { return pos.x; }
	/* use pos.y instead */
	deprecated @property T y() { return pos.y; }
	/* use size.x instead */
	deprecated @property T w() { return size.x; }
	/* use size.y instead */
	deprecated @property T h() { return size.y; }
	
	@property T x2() { return pos.x + size.x; }
	@property T y2() { return pos.y + size.y; }
	
	static if (N == 2) {
		this(T x, T y, T w, T h) {
			this.pos = vec!(2, T)(x, y);
			this.size = vec!(2, T)(w, h);
		}
	}

	this(Coord _pos, Coord _size) {
		this.pos = _pos;
		this.size = _size;
	}

	@property 
	CoordRange!(vec!(N, T)) coordrange() {
		return CoordRange!(vec!(N, T))(pos, pos + size);
	}

	/* Test if a point falls inside this box */
	bool contains(vec!(N, T) x) const {
		foreach(i; 0..N) {
			if (x.val[i] < pos.val[i] || x.val[i] >= pos.val[i] + size.val[i]) { return false; }
		}
		return true;
	}

	bool overlaps(Box!(N,T) b) const {
		Coord a1 = this.pos;
		Coord a2 = this.pos + this.size;
		Coord b1 = b.pos;
		Coord b2 = b.pos + b.size;

		foreach(i; 0..N) {
			if (a2.val[i] <= b1.val[i] || a1.val[i] >= b2.val[i]) return false;
		}
		return true;
	}

	// use "auto ref const" to allow Lval and Rval here.
	int opCmp()(auto ref const Box!(N, T) s) const {
		// sort first by pos, then by size
		if (pos == s.pos) {
			return size.opCmp(s.size);
		}
		return pos.opCmp(s.pos);
	}

	Box!(N, T) intersection(const Box!(N, T) other) const {
		vec!(N, T) p1 = pos.eachMax(other.pos);
		vec!(N, T) p2 = (pos + size).eachMin(other.pos + other.size);
		return Box!(N, T)(p1, p2 - p1);
	}
}

alias Rect(T) = Box!(2, T);
deprecated alias Rectangle = Box!(2, int);

alias Cuboid(T) = Box!(3, T);
alias Hyperrect(T) = Box!(4, T);

unittest {	
	auto unit = Rect!int(Point(1,1), Point(1, 1));
	assert (unit.contains(Point(0, 1)) == false);
	assert (unit.contains(Point(1, 1)) == true);
	assert (unit.contains(Point(2, 1)) == false);
}

unittest {
	Cuboid!int a = Cuboid!int(vec3i(0, 0, 0), vec3i(5, 3, 4));
	Cuboid!int b = Cuboid!int(vec3i(-2, 1, 2), vec3i(5, 4, 3));
	Cuboid!int c = Cuboid!int(vec3i(1,1,1), vec3i(1,1,1));

	vec3i p1 = vec3i(2, 1, 2);
	vec3i p2 = vec3i(8,0,0);

	assert(a.contains(p1));
	assert(b.contains(p1));
	assert(!a.contains(p2));
	assert(!b.contains(p2));
	
	assert(a.overlaps(a));
	assert(b.overlaps(b));
	assert(c.overlaps(c));

	assert(a.overlaps(b));
	assert(b.overlaps(a));
	assert(c.overlaps(a));
	assert(!c.overlaps(b));
}