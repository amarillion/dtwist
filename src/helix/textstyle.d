module helix.textstyle;

import allegro5.allegro;
import allegro5.allegro_font;
import allegro5.allegro_primitives;
import std.conv;

private void calculate_bounds(const ALLEGRO_FONT *font, int alignment, int x, int y, 
	const char *text, out int x1, out int x2
) {
	const textw = al_get_text_width(font, text);
	switch (alignment)
	{
	case ALLEGRO_ALIGN_LEFT:
		x1 = x;
		x2 = x + textw;
		break;
	case ALLEGRO_ALIGN_RIGHT:
		x1 = x - textw;
		x2 = x;
		break;
	case ALLEGRO_ALIGN_CENTER:
		x1 = x - (textw / 2);
		x2 = x + (textw / 2);
		break;
	default:
		assert (0);
	}
}

void draw_text_with_underline(const ALLEGRO_FONT *font, ALLEGRO_COLOR color, 
	float x, float y, int alignment, const char *text
) {
	int x1 = 0, x2 = 0;
	calculate_bounds(font, alignment, to!int(x), to!int(y), text, x1, x2);
	const h = al_get_font_line_height(font);

	al_draw_text(font, color, x, y, alignment, text);
	al_draw_line(x1, y + h + 2, x2, y + h + 2, color, 1.0);
}
