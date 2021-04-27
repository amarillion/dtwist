module helix.allegro.audiostream;

import allegro5.allegro_audio;
import std.string;
import std.exception;

class AudioStream {
	private ALLEGRO_AUDIO_STREAM *_ptr;

	private this(ALLEGRO_AUDIO_STREAM* val) {
		_ptr = val;
	}

	@property ALLEGRO_AUDIO_STREAM* ptr() {
		return _ptr;
	}

	static AudioStream load(string filename, size_t buffer_count, uint samples) {
		ALLEGRO_AUDIO_STREAM *data = al_load_audio_stream(toStringz(filename), buffer_count, samples);
		// improve error handling by throwing an exception here
		enforce(data != null, format("Something went wrong while loading %s", filename)); //TODO: refer to allegro error
		return new AudioStream(data);
	}

	~this() {
		if (_ptr != null) {
			al_destroy_audio_stream(_ptr);
			_ptr = null;
		}
	}
}