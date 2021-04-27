module helix.color;

import allegro5.allegro;
import allegro5.allegro_color;
import std.conv;
import std.regex;
import std.math;
import std.string : format, toStringz;

// for testing
import std.stdio;

enum Color : ALLEGRO_COLOR {
	BLACK      = ALLEGRO_COLOR (0, 0, 0, 1),
	BLUE       = ALLEGRO_COLOR (0, 0, 1, 1),
	RED        = ALLEGRO_COLOR (1, 0, 0, 1),
	GREEN      = ALLEGRO_COLOR (0, 1, 0, 1),
	WHITE      = ALLEGRO_COLOR (1, 1, 1, 1),
	DARK_BLUE  = ALLEGRO_COLOR (0, 0, 0.75, 1),
	DARK_GREEN = ALLEGRO_COLOR (0, 0.75, 0, 1),
	YELLOW     = ALLEGRO_COLOR (1, 1, 0, 1),
	GREY       = ALLEGRO_COLOR (0.5, 0.5, 0.5, 1),
	CYAN       = ALLEGRO_COLOR (0, 1, 1, 1),
	MAGENTA    = ALLEGRO_COLOR (1, 0, 1, 1),
	TRANSPARENT = ALLEGRO_COLOR (0, 0, 0, 0),
}

bool isTransparent(in ALLEGRO_COLOR color) {
	return color.a == 0;
}

ALLEGRO_COLOR parseColor(string s) {
	if (s == "transparent") return Color.TRANSPARENT;	

	if (s[0] == '#') {
		uint hex = to!uint(s[1..$], 16);
		
		uint popByte() {
			uint result =  hex & 0xFF;
			hex >>= 8;
			return result;
		}
		float a = 1.0;
		if (s.length > 7) {
			a = cast(float)popByte() / 255.0;
		}
		float b = cast(float)popByte() / 255.0;
		float g = cast(float)popByte() / 255.0;
		float r = cast(float)popByte() / 255.0;

		return ALLEGRO_COLOR(r, g, b, a);
	}

	// returns BLACK if color name not found.
	return al_color_name(toStringz(s));
}

private bool colorEq(ALLEGRO_COLOR a, ALLEGRO_COLOR b) {
	return 
		abs(a.r - b.r) < 0.01 &&
		abs(a.g - b.g) < 0.01 &&
		abs(a.b - b.b) < 0.01 &&
		abs(a.a - b.a) < 0.01;
}

string formatColor(ALLEGRO_COLOR v) {
	if (v.a == 1.0) {
		return format!"#%02x%02x%02x"(
			to!int(v.r * 255), to!int(v.g * 255), to!int(v.b * 255)
		);
	}
	else {
		return format!"#%02x%02x%02x%02x"(
			to!int(v.r * 255), to!int(v.g * 255), to!int(v.b * 255), to!int(v.a * 255)
		);
	}
}

unittest {
	assert (colorEq(parseColor("red"),        ALLEGRO_COLOR(1, 0, 0, 1)));
	assert (colorEq(parseColor("black"),      ALLEGRO_COLOR(0, 0, 0, 1)));
	assert (colorEq(parseColor("#20FF4080"),  ALLEGRO_COLOR(0.125, 1, 0.25, 0.5)));
	assert (colorEq(parseColor("#20FF40"),    ALLEGRO_COLOR(0.125, 1, 0.25, 1)));

	assert (!isTransparent(Color.BLACK));
	assert (!isTransparent(Color.WHITE));
	assert (isTransparent(Color.TRANSPARENT));
}
