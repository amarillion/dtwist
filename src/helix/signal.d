module helix.signal;

import helix.util.math;

struct Signal(T) {
	void delegate(T)[] listeners;

	void add(void delegate(T) f) {
		listeners ~= f;
	}

	void dispatch(T t) {
		foreach (f; listeners) {
			f(t);
		}
	}

	// TODO - removing listeners
}

struct ChangeEvent(T) {
	T oldValue;
	T newValue;
}

struct Model(T) {

	// allow direct access without get()
	// always returns a ref, can't be used on const objects.
	alias get this;

	/** initialize with a value immediately. Does not (can not) trigger an event */
	this(T initial) {
		this._val = initial;
	}

	Signal!(ChangeEvent!T) onChange;
	private T _val;

	void set (T newVal) {
		if (newVal != _val) {
			T oldVal = _val;
			_val = newVal;
			onChange.dispatch(ChangeEvent!T(oldVal, newVal));
		}
	}

	T dup() const {
		return _val;
	}

	/** get always returns a reference, never a copy. It can not be called on const Models. Use dup() if you have a const object. */
	auto ref T get() {
		return _val;
	}

	// assigning to this model value directly modifies it and triggers event.
	ref opAssign(T value) {
		set(value);
		return this;
	}

	// modifying object with '+=', '*=' etc, modifies value and triggers an event.
	ref opOpAssign(string op)(auto ref const T rhs) {
		mixin ("set (_val " ~ op ~ " rhs);");
		return this;
	}

	ref opUnary(string op)() if ((op == "++") || (op == "--")) {
		mixin ("T temp = _val; temp " ~ op ~ "; set(temp);");
		return this;
	}

	/* relaxed definition of opEquals, only compares _val, not onChange */
	bool opEquals()(auto ref const Model!T rhs) const {
		return _val == rhs._val;
	}

	/* comparison with wrapped type directly */
	bool opEquals()(auto ref const T rhs) const {
		return _val == rhs;
	}

}

unittest {
	ChangeEvent!int[] events;
	
	auto m = Model!int();
	m.onChange.add((e) { events ~= e; });

	// check initialization
	assert(m.get() == int.init);

	// assignment triggers event
	m.set(99);
	assert(events.length == 1);
	assert(events[$-1].newValue == 99);

	// if value remains the same, no event is triggered
	m.set(99); 
	assert(events.length == 1);

	// after assignment, getters reflect model value;
	assert(m.get() == 99);

	// alternative getter
	assert(m == 99);

	// alternative setter
	m = 100;
	assert(m.get() == 100);

	// alternative getter also triggered event
	assert(events.length == 2);
	assert(events[$-1].newValue == 100);

	// opOpAssign overloading
	m += 10; 
	assert(events.length == 3);
	assert(events[$-1].newValue == 110);

	// if value doesn't change, no event is triggered
	m += 0; 
	assert(events.length == 3);

	// opUnary overloading, pre-increment
	const pre = m++;
	assert(pre.dup() == 110);
	assert(events.length == 4);
	assert(events[$-1].newValue == 111);
	assert(m.get() == 111);

	// opUnary overloading, post-increment
	const post = ++m;
	assert(post.dup() == 112);
	assert(events.length == 5);
	assert(events[$-1].newValue == 112);
	assert(m.get() == 112);

	// binary operators work by default through alias this.
	assert(m.get() - 100 == 12);
	assert(m.get() > 100);
	assert(m.get() <= 112);

	// test equality
	auto n = Model!int(112);
	assert(m.get() == n.get());
	// assert(m == n); // doesn't compile
	assert(m.get() == n);
	assert(m == n.get());
}

unittest {

	struct Person {
		string firstName;
		string lastName;
	}

	Model!Person a;

	// use a reference to person, and modify it
	a.get().firstName = "Hello";
	assert(a.get().firstName == "Hello"); // succeeds

	// this also uses a reference to person
	a.firstName = "World";
	assert(a.firstName == "World"); // succeeds

	const Model!Person b;
	// following won't compile:
	// b.get().firstName = "Beeh";
	// b.firstName = "Beeh";

	immutable Model!Person c;
	c.dup().firstName = "Two"; // now you get a copy...
	// assert(c.dup().firstName == "Two"); // fails

	// c.firstName = "Three"; // does not compile


	class PersonEncapsulator {
		private Model!Person _p;
		@property Person p() const { return _p.dup(); }
	}

	auto pe = new PersonEncapsulator();
	Person px = pe.p;
}


struct RangeModel(T) {

	Signal!(ChangeEvent!(T)) onChange;
	private T _val;
	private T min;
	private T max;

	this(T initial, T min, T max) {
		this.min = min;
		this.max = max;
		_val = initial;
	}
	
	void set (T val) {
		T newVal = bound(min, val, max);
		if (newVal != _val) {
			T oldVal = _val;
			_val = newVal;
			onChange.dispatch(ChangeEvent!T(oldVal, _val));
		}		
	}
 
	T get() {
		return _val;
	}
}


