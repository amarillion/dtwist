module text;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_font;
import helix.component;
import helix.color;
import std.stdio;
import std.conv;
import helix.mainloop;
import std.algorithm;
import helix.util.vec;

class TextField : Component
{
	class DocumentModel
	{
		private string text;
		
		public void insert (int pos, string val)
		{
			assert (pos >= 0); 
			if (pos >= text.length)
			{
				text ~= val;
			}
			else if (pos == 0)
			{
				text = val ~ text;
			}
			else
			{
				text = text[0..pos] ~ val ~ text[pos..$];
			}
		}
		
		public string getText()
		{
			return text;
		}
		
		public void del (int pos)
		{
			assert (pos >= 0);
			if (text.length == 0)
			{
				// nothing to delete
			} 
			else if (pos == 0)
			{
				text = text[1..$];
			}
			else if (pos >= text.length)
			{
				// nothing to delete 
			}
			else
			{
				text = text[0..pos] ~ text[(pos+1)..$];
			}
		}
		
		public void backspace (int pos)
		{
			assert (pos >= 0); 
			if (pos == 0)
			{
				// nothing to delete
			}
			else if (pos == 1)
			{
				text = text[1..$];
			}
			else if (pos >= text.length)
			{
				text = text[0..($-1)];
			}
			else
			{
				text = text[0..(pos-1)] ~ text[pos..$];
			} 
		}

	}
	
	int cursor = 0;
	int cursorx = 0;
	
	private void updateCursor()
	{
		assert (cursor >= 0);
		cursorx = al_get_text_width (getStyle().getFont().ptr, cast(const char*)(doc.text[0..cursor] ~ '\0'));
		blink = 0;
		// dirty = true; //TODO
	}
	
	DocumentModel doc;
	this(MainLoop window, string value = "")
	{
		super(window, "textinput");
		canFocus = true;
		doc = new DocumentModel();

		auto style = getStyle();

		doc.text = value;
		// w = resource.getIntProperty("button.width"); //TODO
		// h = resource.getIntProperty("button.height"); // TODO
		w = 100; //TODO
		h = 20;
		cursorBlinkRate = 10; to!int(style.getNumber("blinkrate"));
		
		// layout = LayoutRule.MANUAL; //TODO
	}
	
	int blink = 0;
	
	override void draw(GraphicsContext gc)
	{
		auto style = getStyle();
		
		drawBackground(style);
		drawBorder(style);

		ALLEGRO_COLOR color = style.getColor("color");
		al_draw_text(style.getFont().ptr, color, x, y, ALLEGRO_ALIGN_LEFT, cast(const char*) (doc.text ~ '\0'));
		
		if (focused && blink >= 0)
		{
			//TODO: configure cursor color
			ALLEGRO_COLOR cursorColor = style.getColor("cursor-color");
			al_draw_line (x + cursorx + 1, y, x + cursorx + 1, y + h, cursorColor, 1);
		}
	}
	
	override void onMouseDown (Point p)
	{
		// TODO -> make part of standard component, if 'wantsFocus' is true.
		// if (parent)
		// {
		// 	parent.requestFocus(this);
		// }
	}
	
	override void gainFocus()
	{
		blink = 0;
		// dirty = true;
	}
	
	int cursorBlinkRate;
	 
	override void update()
	{
		blink++;
		
		if (blink == 0)
		{
			// dirty = true;
		}
		
		if (blink > cursorBlinkRate) 
		{
			blink = -cursorBlinkRate;
			// dirty = true;
		}
	}
	
	public override bool onKey(int code, int c, int mod)
	{
		switch (code)
		{
			case ALLEGRO_KEY_DELETE:
				doc.del(cursor);
				return true;
			
			case ALLEGRO_KEY_BACKSPACE:
				doc.backspace(cursor);
				cursor = max (0, cursor - 1);
				updateCursor();
				return true;
			
			case ALLEGRO_KEY_LEFT:
				cursor = max (0, cursor - 1);
				updateCursor();
				return true;
			
			case ALLEGRO_KEY_RIGHT:
				cursor = min (cast(int)doc.text.length, cursor + 1);
				updateCursor();
				return true;
				
			case ALLEGRO_KEY_ENTER:
				onAction.dispatch(ComponentEvent(this));
				return true;
				
			default:
				if (c >= ' ')
				{
					// append character to text
					doc.insert(cursor, to!string (cast(dchar)c));
					cursor++;
					updateCursor();
					// dirty = true; // TODO mark dirty via listener mechanism
					return true;
				}
				break;
			
		}
		return false;
		
	}
}