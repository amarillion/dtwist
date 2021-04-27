module helix.util.vec;
import std.conv;
import helix.util.math;

struct vec(int N, V) {
	V[N] val;
	
	@property V x() const { return val[0]; }
	@property void x(V v) { val[0] = v; }
	
	@property V y() const { return val[1]; }
	@property void y(V v) { val[1] = v; }

	static if (N > 2) {
		@property V z() const { return val[2]; }
		@property void z(V v) { val[2] = v; }
	}

	static if (N > 3) {
		@property V w() const { return val[3]; }
		@property void w(V v) { val[3] = v; }
	}

	this(V x, V y, V z = 0, V w = 0) {
		static if (N == 4) {
			val = [x, y, z, w];
		}
		static if (N == 3) {
			val = [x, y, z];
		}
		static if (N == 2) {
			val = [x, y];
		}
	}

	this(V init) {
		foreach (i; 0..N) {
			val[i] = init;
		}
	}

	vec!(N, V) eachMin(const vec!(N, V) p) const {
		vec!(N, V) result;
		foreach (i; 0..N) {
			result.val[i] = min(p.val[i], val[i]);
		}
		return result;
	}

	vec!(N, V) eachMax(const vec!(N, V) p) const {
		vec!(N, V) result;
		foreach (i; 0..N) {
			result.val[i] = max(p.val[i], val[i]);
		}
		return result;
	}

	bool allLt(U)(const vec!(N, U) p) const {
		foreach (i; 0..N) {
			if (!(val[i] < p.val[i])) {
				return false;
			}
		}
		return true;
	}

	bool allGte(U)(const vec!(N, U) p) const {
		foreach (i; 0..N) {
			if (!(val[i] >= p.val[i])) {
				return false;
			}
		}
		return true;
	}

	/** combine two vectors */
	vec!(N, V) opBinary(string op)(vec!(N, V) rhs) const if (op == "-" || op == "+" || op == "*" || op == "/") {
		vec!(N, V) result;
		result.val[] = mixin("val[]" ~ op ~ "rhs.val[]");
		return result;
	}

	/** combine vector and scalar */
	vec!(N, V) opBinary(string op)(V rhs) const if (op == "-" || op == "+" || op == "*" || op == "/") {
		vec!(N, V) result;
		result.val[] = mixin("val[]" ~ op ~ "rhs");
		return result;
	}

	string toString() {
		bool first = true;
		char[] result = ['['];
		foreach(i; val) {
			if (!first) {
				result ~= ", ".dup;
			}
			first = false;
			result ~= to!string(i);
		}
		result ~= ']';
		return result.idup;
	}
}

alias vec2i = vec!(2, int);
alias Point = vec!(2, int);
alias vec3i = vec!(3, int);
alias vec4i = vec!(4, int);

unittest {
	auto a = vec2i(1, 0);
	auto b = vec2i(2, 3);
	
	assert(b.allGte(a));
	assert(a.allLt(b));
	assert(!a.allGte(b));
	assert(!b.allLt(a));

	const c = vec2i(0, 4);
	const d = vec2i(2, 4);

	assert(d.allGte(c));
	assert(!c.allLt(d));

	assert (a.eachMax(c) == vec2i(1, 4));
	assert (b.eachMin(c) == vec2i(0, 3));
}
