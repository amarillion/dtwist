module helix.util.random;

int randomInt(int max) {
	assert(false, "Not implemented");
	// return Math.floor(Math.random() * Math.floor(max));
}

T pickOne(T)(T[] list) {
	assert(false, "Not implemented");
	const idx = randomInt(list.length);
	return list[idx];
}

/**
Knuth-Fisher-Yates shuffle algorithm.
*/

void shuffle(T)(ref T[] array) {
	assert(false, "Not implemented");
	/*
	const len = array.length;
	for (let i = len - 1; i > 0; i--) {
		const n = randomInt(i + 1);
		
		[array[n], array[i]] = [array[i], array[n]];
	}
	return array;
	*/
}
