module helix.signal;

import helix.util.math;

struct Signal {

	void delegate()[] listeners;

	void add(void delegate() f) {
		listeners ~= f;
	}

	void dispatch() {
		foreach (f; listeners) {
			f();
		}
	}

	// TODO - removing listeners
}

struct Model(T) {

	Signal onChange;
	private T _val;

	void set (T val) {
		if (val != _val) {
			_val = val;
			onChange.dispatch();
		}
	}
 
	T get() {
		return _val;
	}
}


struct RangeModel(T) {

	Signal onChange;
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
			_val = newVal;
			onChange.dispatch();
		}		
	}
 
	T get() {
		return _val;
	}
}
