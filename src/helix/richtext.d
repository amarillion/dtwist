module helix.richtext;

import helix.component;
import helix.widgets;
import helix.layout;
import helix.util.vec;
import helix.mainloop;
import helix.style;
import helix.allegro.bitmap;

import allegro5.allegro;
import allegro5.allegro_font;

import std.exception;
import std.string;
import std.conv : to;
import std.regex;
import helix.util.math;

import helix.allegro.font;
import helix.textstyle;
import helix.util.browser;
import std.stdio; // debug
import std.json;

enum defaultLineHeight = 16; // For lines with nothing in it. TODO: should depend on current font...

private class Context {
	MainLoop window;
	Point cursor;
	int lineHeight;
	int maxWidth;

	private StyleData style;
	StyleData getStyle() { return style; }

	this(MainLoop window, int maxWidth, StyleData parentStyle) {
		this.style = parentStyle;
		cursor = Point(0);
		this.window = window;
		this.maxWidth = maxWidth;
		this.lineHeight = defaultLineHeight;
	}

	void nextLine() {
		cursor = Point(0, cursor.y + lineHeight);
		lineHeight = defaultLineHeight;
	}

	int remain() {
		return maxWidth - cursor.x;
	}
}

/** 
A fragment of a document that carries a single style.
Could be a piece of text, a break, or an inline image.
Fragments do not have a reified layout. Call Fragment.layout() to turn this section of a document into components with a specific layout.
*/
interface Fragment {
	Component[] layout(Context context);
}

private class TextFragment : Fragment {

	private string text;
	private string styleName;
	private Style parentStyle;
	private string[string] props; // mostly used for link urls at the moment.

	this(string text, string styleName = "default", string[string] props = null) { 
		this.text = text; 
		this.styleName = styleName; 
		this.props = props;
	}

	Component[] layout(Context context) {
		TextSpan span = styleName == "a" 
			? new Link(context.window, props["url"]) 
			: new TextSpan(context.window, styleName);
		span.text = text;
		span.initialIndent = context.cursor.x;
		span.setAncestorStyle(context.getStyle());
		int totalHeight;
		int originalY = context.cursor.y;
		int lineHeight;
		span.calculateLayout(context.maxWidth, lineHeight, totalHeight, context.cursor);
		context.lineHeight = max(context.lineHeight, lineHeight);
		span.setRelative(0, originalY, 0, 0, 0, totalHeight, LayoutRule.STRETCH, LayoutRule.BEGIN);
		return [ span ];
	}
}

private class InlineImage : Fragment {
	private Bitmap bitmap;
	
	this(Bitmap bitmap) {
		enforce(bitmap !is null);
		this.bitmap = bitmap;
	}

	Component[] layout(Context context) {
		ImageComponent img = new ImageComponent(context.window);
		img.img = bitmap;
		const w = bitmap.w;
		const h = bitmap.h;
		img.setRelative(context.cursor.x, context.cursor.y, 0, 0, w, h, LayoutRule.BEGIN, LayoutRule.BEGIN);
		
		//TODO: move to new line if there is no space left for image...
		context.cursor.x = context.cursor.x + w; //TODO add margin?
		context.lineHeight = max(context.lineHeight, h);
		return [ img ];
	}
}

private class LineBreak : Fragment {
	Component[] layout(Context context) {
		context.nextLine();
		return [];
	}	
}

private class ParagraphBreak : Fragment {

	Component[] layout(Context context) {
		context.nextLine();
		context.nextLine();
		return [];
	}
}

private class Indent : Fragment {

	Component[] layout(Context context) {
		context.cursor.x = context.cursor.x + 32; //TODO customizable...
		return [];
	}

}

/** 
A section of text with a uniform style
at a specific position, rendered and clickable (for links...)

The text will be broken accross multiple lines depending on 
the width available, for example:

`
................This piece
of text is a TextSpan that
spans multiple lines......
`

Multiple textspans together form a piece of rich text, the bounding
boxes of the textspans could overlap.

Some properties of text spans:

* all text carries the same text style
* may span multiple lines
* optionally breaks at / ignores hard line breaks ('\\n')
* will insert soft line breaks
* first line may have hanging indent
* Stretches of whitespace (including tabs) are collapsed

*/
class TextSpan : Component {

	this(MainLoop window, string styleName) {
		super(window, styleName);
	}

	int initialIndent;
	bool ignoreHardBreaks = true;
	
	struct Line {
		int xofst;
		int w;
		immutable(char)* line;
	}
	Line[] lines;

	private static void softBreaks(ref Line[] lines, string line, ref int xofst, int maxWidth, Font font) {
		if (line.empty) return; // do not insert empty newLine in this case...
		
		string sep = "";
		Line prevLine = Line(xofst, 0, toStringz("")); // in case first word doesn't fit, we start with an empty line
		string currentString = "";
		
		// Merge whitespace, remove tabs
		foreach(word; line.splitter(regex(`\s+`))) {
			// line.splitter has an oddity that we rely on in this case
			// if there is leading whitespace, the first word is the empty string
			// this is useful, because we want a leading whitespace in the output as well.
			currentString ~= sep; 
			currentString ~= word;
			sep = " ";
			// There was a weird bug here - lz & currentString point to same memory even though toStringz should have made a copy...
			// we force duplication with .dup
			immutable(char)*lz = toStringz(currentString.dup); 
			int ww = al_get_text_width(font.ptr, lz);

			if (xofst + ww > maxWidth) {
				lines ~= prevLine;
				currentString = word;
				xofst = 0;
				lz = toStringz(currentString);
				ww = al_get_text_width(font.ptr, lz);
			}

			prevLine = Line(xofst, ww, lz);
		}

		lines ~= prevLine;
		xofst = prevLine.xofst + prevLine.w;

	}

	void calculateLayout(int maxWidth, out int lineHeight, out int totalHeight, ref Point cursor) {
		assert(text != "", "must set text before calculateLayout()");
		Style style = getStyle();
		Font font = style.getFont();

		int w = al_get_text_width(font.ptr, toStringz(text));
		
		lines = [];
		int xofst = initialIndent;

		// newline characters as hard breaks
		if (ignoreHardBreaks) {
			softBreaks(lines, text, xofst, maxWidth, font);
		}
		else {
			foreach (l; text.split("\n")) {
				softBreaks(lines, l, xofst, maxWidth, font);
				xofst = 0;
			}
		}

		const lineNum = to!int(lines.length);
		lineHeight = font.lineHeight;
		totalHeight = lineNum * lineHeight;

		// update cursor
		cursor = Point(cursor.x + w, cursor.y + (lineNum - 1) * lineHeight);
	}

	override void draw(GraphicsContext gc) {
		const state = disabled ? 2 : (selected ? 1 : (hover ? 3 : 0));
		Style style = getStyle(state);
		
		// TODO render multiple lines...
		if (text != "") {
			assert (!lines.empty, "Must invoke calculateLayout() before draw()");

			ALLEGRO_COLOR color = style.getColor("color");
			Font font = style.getFont();

			void delegate(float x, float y, in char *text) draw_styled_text = 
				(style.getString("text-decoration") == "underline") 
				? (x, y, text) => draw_text_with_underline(font.ptr, color, x, y, ALLEGRO_ALIGN_LEFT, text) 
				: (x, y, text) => al_draw_text(font.ptr, color, x, y, ALLEGRO_ALIGN_LEFT, text);

			int yco = y;
			int xco = x;
			int lh = font.lineHeight;
			foreach(l; lines) {
				draw_styled_text(xco + l.xofst, yco, l.line);
				xco = x;
				yco += lh;
			}
			
			
		}
	}
}

/** 
	a textSpan that is clickable and opens a url in a browser window 

	TODO: change mouse cursor when hovering over an url.
*/
class Link : TextSpan {

	string url;

	this(MainLoop window, string _url = null) {
		super(window, "a");
		this.url = _url;
		this.onAction.add(() => this.onClick());
	}

	private void onClick() {
		openUrl(url);
	}

	override void onMouseDown(Point p) {
		if (!disabled) {
			onAction.dispatch();
			
		}
	}

}

class RichTextBuilder {

	private Fragment[] Fragments;
	
	Fragment[] build() { 
		return Fragments;
	}

	/** same as .text(), but treats newlines as hard line breaks */
	RichTextBuilder lines(string text) {
		foreach (l; text.split("\n")) {
			if (!l.empty) {
				Fragments ~= new TextFragment(l);
			}
			Fragments ~= new LineBreak();
		}
		return this;
	}
	
	/** ignores hard line breaks. If you need them, use .lines() instead */
	RichTextBuilder text(string text) {
		Fragments ~= new TextFragment(text);
		return this;
	}

	RichTextBuilder br() {
		Fragments ~= new LineBreak();
		return this;
	}

	RichTextBuilder p() {
		Fragments ~= new ParagraphBreak();
		return this;
	}

	RichTextBuilder indent() {
		Fragments ~= new Indent();
		return this;
	}

	RichTextBuilder img(Bitmap bitmap) {
		Fragments ~= new InlineImage(bitmap);
		return this;
	}

	RichTextBuilder h1(string text) {
		Fragments ~= new TextFragment(text, "h1");
		Fragments ~= new ParagraphBreak();
		return this;
	}

	RichTextBuilder b(string text) {
		Fragments ~= new TextFragment(text, "b");
		return this;
	}

	RichTextBuilder i(string text) {
		Fragments ~= new TextFragment(text, "i");
		return this;
	}

	RichTextBuilder link(string text, string url) {
		Fragments ~= new TextFragment(text, "a", ["url": url]);
		return this;
	}
}

class RichText : Component {

	this(MainLoop window) {
		super(window, "default");
		sizeRule = SizeRule.HEIGHT_DEPENDS_ON_WIDTH;
	}

	private Fragment[] Fragments;
	bool dirty = true;

	void setFragments(Fragment[] Fragments) {
		clearChildren();
		this.Fragments = Fragments;
		dirty = true;
	}

	override int calculateHeight(int inputWidth) { return 200; /* TODO */ }

	override void draw(GraphicsContext gc) {
		if (dirty) {
			Context context = new Context(window, shape.w, getStyle().data /* TODO: should be private */);
			foreach (fragment; Fragments) {
				Component[] clist = fragment.layout(context);
				foreach(c; clist) {
					addChild(c);
				}
			}
			dirty = false;
			window.calculateLayout(this);
		}
		super.draw(gc);
	}

}