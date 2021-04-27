module helix.allegro.font;

import allegro5.allegro_font;
import std.string;
import std.exception;

/**
Wrapper that performs memory management on ALLEGRO_FONT *
*/
class Font {
	private ALLEGRO_FONT *_ptr;

	@property ALLEGRO_FONT* ptr() {
		return _ptr;
	}

	@property int lineHeight() {
		return al_get_font_line_height(_ptr);
	}

	static Font builtin() {
		return new Font(al_create_builtin_font());
	}

	static Font load(string filename, int size, int flags) {
		ALLEGRO_FONT *data = al_load_font(toStringz(filename), size, flags);
		// improve error handling by throwing an exception here
		enforce(data != null, format("Something went wrong while loading %s", filename)); //TODO: refer to allegro error
		return new Font(data);
	}

	private this(ALLEGRO_FONT* val) {
		_ptr = val;
	}

	~this() {
		if (_ptr != null) {
			al_destroy_font(_ptr);
			_ptr = null;
		}
	}
}
