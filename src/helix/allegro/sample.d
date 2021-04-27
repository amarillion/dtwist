module helix.allegro.sample;

import allegro5.allegro_audio;
import std.string;
import std.exception;

class Sample {
	private ALLEGRO_SAMPLE *_ptr;

	private this(ALLEGRO_SAMPLE* val) {
		_ptr = val;
	}

	@property ALLEGRO_SAMPLE* ptr() {
		return _ptr;
	}

	static Sample load(string filename) {
		ALLEGRO_SAMPLE *samp = al_load_sample(toStringz(filename));
		// improve error handling by throwing an exception here
		enforce(samp != null, format("Something went wrong while loading %s", filename)); //TODO: refer to allegro error
		return new Sample(samp);
	}

	~this() {
		if (_ptr != null) {
			al_destroy_sample(_ptr);
			_ptr = null;
		}
	}
}