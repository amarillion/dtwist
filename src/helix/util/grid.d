module helix.util.grid;

import std.conv;

import helix.util.vec;
import helix.util.coordrange;

class Grid(int N, T) {
	T[] data;
	vec!(N, int) size;
	
	@property int width() const { return size.x; }
	@property int height() const { return size.y; }

	static if (N == 2) {
		this(int width, int height, T initialValue = T.init) {
			this(vec!(N, int)(width, height), initialValue);
		}
	}
	else static if (N == 3) {
		@property int depth() const { return size.z; }
		this(int width, int height, int depth, T initialValue = T.init) {
			this(vec!(N, int)(width, height, depth), initialValue);
		}
	}

	this(vec!(N, int) size, T initialValue = T.init) {
		this.size = size;
		data = [];
		data.length = size.x * size.y;
		if (initialValue !is T.init) {
			foreach(ref cell; data) {
				cell = initialValue;
			}
		}
	}

	bool inRange(vec!(N, int) p) const {
		auto zero = vec!(N, int)(0);
		return p.allGte(zero) && p.allLt(size);
	}

	size_t toIndex(vec!(N, int) p) const {
		size_t result = p.val[$ - 1];
		foreach (i; 1 .. N) {
			result *= size.val[$ - i - 1];
			result += p.val[$ - i - 1];
		}
		return result;
	}

	deprecated
	void set(const vec!(N, int) p, T val) {
		assert(inRange(p));
		data[toIndex(p)] = val;
	}

	deprecated
	ref T get(const vec!(N, int) p) {
		assert(inRange(p));
		return data[toIndex(p)];
	}

	// const version
	ref auto opIndex(const vec!(N, int) p) const {
		assert(inRange(p));
		return data[toIndex(p)];
	}

	// non-const version
	ref auto opIndex(const vec!(N, int) p) {
		assert(inRange(p));
		return data[toIndex(p)];
	}

	// TODO: also implement for N == 3...
	static if (N == 2) {
		string format(string cellSep = ", ", string lineSep = "\n") const {
			char[] result;
			int i = 0;
			
			const int lineSize = size.x;
			bool firstLine = true;
			bool firstCell = true;
			foreach (base; CoordRange!(vec!(N, int))(size)) {
				if (i % lineSize == 0 && !firstLine) {
					result ~= lineSep;
					firstCell = true;
				}
				if (!firstCell) result ~= cellSep;
				result ~= to!string(this[base]);
				i++;
				
				firstLine = false;
				firstCell = false;
			}
			return result.idup;
		}

		override string toString() const {
			return format();
		}
	}

	struct NodeRange {

		Grid!(N, T) parent;
		int pos = 0;
		int stride = 1;
		int remain;

		this(Grid!(N, T) parent, int stride = 1) {
			this.parent = parent;
			this.stride = stride;
			remain = to!int(parent.data.length);
		}

		/* use ref to support in place-modification */
		ref T front() {
			return parent.data[pos];
		}

		void popFront() {
			pos++;
			remain--;
		}

		bool empty() const {
			return remain <= 0;
		}
		
	}

	NodeRange eachNode() {
		return NodeRange(this);
	}
/*
	void eachNode(void delegate(T t) f) {
		foreach(ref d; data) {
			f(d);
		}
	}
*/
	NodeRange eachNodeCheckered() {
		const PRIME = 523;
		assert(data.length % PRIME != 0);
		return NodeRange(this, PRIME);
	}
}

unittest {
	// toIndex test
	auto grid = new Grid!(3, bool)(32, 16, 4);

	assert (grid.toIndex(vec3i(0, 0, 0)) == 0);
	assert (grid.toIndex(vec3i(1, 0, 0)) == 1);
	assert (grid.toIndex(vec3i(0, 1, 0)) == 32);
	assert (grid.toIndex(vec3i(0, 0, 1)) == 32 * 16);
	assert (grid.toIndex(vec3i(7, 7, 3)) == 7 + (32 * 7) + (16 * 32 * 3));

	// opIndex test
	auto grid2 = new Grid!(2, bool)(2, 2, false);
	assert (grid2[Point(0, 0)] == false);
	grid2[Point(0, 0)] = true;
	assert (grid2[Point(0, 1)] == false);

	const grid3 = grid2;
	assert (grid3[Point(0, 0)] == true);
	// grid3[Point(0, 0)] = false; // Does not compile...
}
