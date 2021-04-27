module helix.allegro.bitmap;

import allegro5.allegro;
import std.string;
import std.exception;

/**
Wrapper that performs automatic memory management on ALLEGRO_BITMAP *
*/
class Bitmap {
	private ALLEGRO_BITMAP *_ptr;

	@property ALLEGRO_BITMAP* ptr() {
		return _ptr;
	}

	@property int w() {
		return al_get_bitmap_width(_ptr);
	}

	@property int h() {
		return al_get_bitmap_height(_ptr);
	}

	static Bitmap create(int _w, int _h) {
		auto bmp = al_create_bitmap(_w, _h);
		enforce(bmp, "Something went wrong while creating bitmap"); //TODO refer to allegro error...
		return new Bitmap(bmp);
	}

	static Bitmap load(string filename) {
		ALLEGRO_BITMAP *bmp = al_load_bitmap(toStringz(filename));
		// improve error handling of al_load_bitmap by throwing an exception here
		enforce(bmp != null, format("Something went wrong while loading %s", filename)); //TODO: refer to allegro error
		return new Bitmap(bmp);
	}

	private this(ALLEGRO_BITMAP* val) {
		_ptr = val;
	}

	~this() {
		if (_ptr != null) {
			al_destroy_bitmap(_ptr);
			_ptr = null;
		}
	}
}

