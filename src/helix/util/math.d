module helix.util.math;

/** lowest of the two, for any type that has opCmp */
T min(T) (T a, T b)
{
	return (a < b) ? a : b;
}

/** highest of the two, for any type that has opCmp */
T max(T) (T a, T b)
{
	return (a > b) ? a : b;
}

/** return val if val is between low or high.
	return low if val is below low.
	return high if val is above high.

	(if high is below low, then low is returned)
*/
T bound(T) (T low, T high, T val)
{
	return max(low, min (high, val));
}

void swap(T)(ref T a, ref T b) {
	T tmp = a;
	a = b;
	b = tmp;
}