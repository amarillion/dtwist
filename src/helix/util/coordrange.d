module helix.util.coordrange;

import helix.util.vec;

/**
	Range over all coordinates in a grid (or higher dimensional equivalent)
	Between two cornes start and end (exclusive, so never quite reaching end)
	
	First fills in x-axis, then y-axis, then higher axes.
*/
struct CoordRange(T) {
	
	T pos, start, end;

	/* End is exclusive */
	this(T start, T endExclusive) {
		pos = start;
		this.start = start;
		this.end = endExclusive;
	}

	this(T endExclusive) {
		this(T(0), endExclusive);
	}

	T front() {
		return pos;
	}

	void popFront() {
		pos.val[0]++;
		foreach (i; 0 .. pos.val.length - 1) {
			if (pos.val[i] > end.val[i] - 1) {
				pos.val[i] = start.val[i];
				pos.val[i+1]++;
			}
			else {
				break;
			}
		}
	}

	bool empty() const {
		return pos.val[$-1] >= end.val[$-1]; 
	}

}

alias PointRange = CoordRange!Point;

/**
Range, moving over a grid (or higher-dimension equivalent) 
from a fixed start, with a fixed delta, for a fixed number of steps.
*/
struct Walk(T) {
	T pos;
	T delta;
	int remain;

	this(T start, T delta, int steps) {
		pos = start;
		this.delta = delta;
		remain = steps;
	}

	T front() {
		return pos;
	}

	void popFront() {
		remain--;
		pos = pos + delta;
	}

	bool empty() const {
		return remain <= 0;
	}
}