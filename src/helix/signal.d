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

	Signal!(ChangeEvent!T) onChange;
	private T _val;

	void set (T newVal) {
		if (newVal != _val) {
			T oldVal = _val;
			_val = newVal;
			onChange.dispatch(ChangeEvent!T(oldVal, newVal));
		}
	}
 
	T get() {
		return _val;
	}
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
