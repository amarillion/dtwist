module helix.style;

import std.json;
import allegro5.allegro;
import allegro5.allegro_font;
import allegro5.allegro_primitives;
import helix.color;
import std.conv;
import helix.resources;
import std.format: format;
import helix.allegro.font;
import helix.allegro.bitmap;
import std.array : appender;

private enum rootStyleData = parseJSON(`{
	"root": {
		"font": "builtin_font", 
		"font-size": 17, 
		"color": "white", 
		"background": "transparent",
		"outline": "transparent"
	},
	"body": {
		"background": "transparent"
	},
	"button": {
		"background": "#BBBBBB", 
		"border": "#888888", 
		"border-left": "#DDDDDD", 
		"border-top": "#DDDDDD", 
		"border-width": 2.0, 
		"color": "black"
	},
	"button[selected]": {
		"background": "#999999", 
		"border": "#888888", 
		"border-right": "#DDDDDD", 
		"border-bottom": "#DDDDDD", 
	},
	"button[hover]": {
		"background": "#9999BB", 
		"border": "#888888", 
		"border-left": "#DDDDDD", 
		"border-top": "#DDDDDD" 
	},
	"button[disabled]": {
		"color": "#888888",
		"background": "#444444",
		"border-width": 0.0
	},
	"button[focused]": {
		"outline": "yellow"
	},
	"panel": {
		"background": "#BBBBBB", 
		"border": "#888888",
		"border-left": "#DDDDDD", 
		"border-top": "#DDDDDD", 
		"border-width": 2.0, 
		"color": "black"
	},

	"pre": {
		"font-size": 14
	},

	"h1": {
		"font-size": 28
	},

	"a": {
		"color": "blue"
	},
	"a[hover]": {
		"text-decoration": "underline"
	},

	"b": {
		"color": "red"
	},
	"i": {
		"color": "white"
	},
	"scrollpane": {
		"background": "#333333"
	},
	"scrollbar": {
		"size": 16,
		"background": "#666666"
	},
	"slider": {
		"min-size": 8,
		"background": "#BBBBBB", 
		"border": "#888888", 
		"border-left": "#DDDDDD", 
		"border-top": "#DDDDDD", 
		"border-width": 2.0, 
	},
	"slider[selected]": {
		"background": "#999999", 
		"border": "#888888", 
		"border-right": "#DDDDDD", 
		"border-bottom": "#DDDDDD", 
	},
	"slider[hover]": {
		"background": "#9999BB", 
		"border": "#888888", 
		"border-left": "#DDDDDD", 
		"border-top": "#DDDDDD" 
	},

	"list": {
		"color": "#FFFFFF",
		"background": "#444444"
	},
	"list[selected]": {
		"color": "#00FF00"
	}
}
`);

private enum PropertyType {
	NUMBER, STRING, COLOR
}

private enum PropertyType[string] PROPERTY_TYPES = [
	// foreground color / text color
	"color": PropertyType.COLOR, 
	// background fill color. If transparent, no background
	"background": PropertyType.COLOR, 

	// border colors, for each direction
	"border-top": PropertyType.COLOR,
	"border-left": PropertyType.COLOR, 
	"border-right": PropertyType.COLOR,
	"border-bottom": PropertyType.COLOR,	
	// color of border
	"border": PropertyType.COLOR,
	// width in pixels
	"border-width": PropertyType.NUMBER,

	"font-size": PropertyType.NUMBER,
	"min-size": PropertyType.NUMBER,
	"size": PropertyType.NUMBER,
	"font": PropertyType.STRING,

	// underline
	"text-decoration": PropertyType.STRING,

	// cursor blink rate, for input fields
	"blinkrate": PropertyType.NUMBER,
	"cursor-color": PropertyType.COLOR,

	"outline": PropertyType.COLOR,
];

private enum string[string] fallbackProperties = [
	"border-top": "border",
	"border-left": "border",
	"border-right": "border",
	"border-bottom": "border",
];

/**
 a properties map with styles for a single component type, component state or specific component instance.
*/
class StyleData {

	ALLEGRO_COLOR[string] colors;
	double[string] numbers;
	string[string] strings;
	string name;

	static StyleData fromJSONString(string name, string jsonStr) {
		return fromJSON(name, parseJSON(jsonStr));
	}

	static StyleData fromJSON(string name, JSONValue json) {
		StyleData result = new StyleData();
		result.name = name;

		foreach (key; json.object().keys()) {
			assert (key in PROPERTY_TYPES, format("Unexpected key [%s]", key));
			const type = PROPERTY_TYPES[key];
			final switch (type) {
				case PropertyType.COLOR:
					result.colors[key] = parseColor(json[key].str);
				break;
				case PropertyType.STRING:
					result.strings[key] = json[key].str;
				break;
				case PropertyType.NUMBER:
					if (json[key].type == JSONType.FLOAT) {
						result.numbers[key] = json[key].floating;
					}
					else {
						result.numbers[key] = json[key].integer;
					}
				break;
			}
		}

		return result;
	}

	override string toString() {
		auto strBuilder = appender!string;
		strBuilder.put(format!"Style: %s "(name));
		string sep = "";
		foreach(k, v; colors) {
			strBuilder.put(sep);
			strBuilder.put(format("%s: %s", k, formatColor(v)));
			sep = " ";
		}
		foreach(k, v; strings) {
			strBuilder.put(sep);
			strBuilder.put(format("%s: %s", k, v));
			sep = " ";
		}
		foreach(k, v; numbers) {
			strBuilder.put(sep);
			strBuilder.put(format("%s: %s", k, v));
			sep = " ";
		}
		return strBuilder.data;
	}
}

class StyleManager {
	
	private StyleData[string] rootStyleBySelector;
	private StyleData[string] themeStyleBySelector;
	private Style[string] styleCache;
	private ResourceManager resources;

	this(ResourceManager resources) {
		rootStyleBySelector = parseStyling(rootStyleData);
		this.resources = resources;
		initIcons();
	}

	private void makeIcon(string key, void delegate() draw) {
		Bitmap icon = Bitmap.create(16, 16);
		al_set_target_bitmap(icon.ptr);
		al_clear_to_color(Color.TRANSPARENT);
		draw();
		resources.bitmaps.put(key, icon);
	}

	// TODO: more generic way to initialize icons...
	private void initIcons() {
		ALLEGRO_BITMAP *saved = al_get_target_bitmap();

		makeIcon("icon-arrow-down", {
			float[] vertices = [ 15, 5,   1, 5,   8, 11 ];
			al_draw_filled_polygon(&vertices[0], to!int(vertices.length / 2), Color.DARK_BLUE);
		});
		makeIcon("icon-arrow-right", {
			float[] vertices = [ 5, 1,   5, 15,   11, 8 ];
			al_draw_filled_polygon(&vertices[0], to!int(vertices.length / 2), Color.DARK_BLUE);
		});
		makeIcon("icon-arrow-up", {
			float[] vertices = [ 1, 11,   15, 11,   8, 5 ];
			al_draw_filled_polygon(&vertices[0], to!int(vertices.length / 2), Color.DARK_BLUE);
		});
		makeIcon("icon-arrow-left", {
			float[] vertices = [ 11, 15,   11, 1,   5, 8 ];
			al_draw_filled_polygon(&vertices[0], to!int(vertices.length / 2), Color.DARK_BLUE);
		});
		
		al_set_target_bitmap(saved);
	}

	void applyJson(JSONValue jsonData) {
		StyleData[string] styling = parseStyling(jsonData);
		foreach(k, v; styling) {
			themeStyleBySelector[k] = v;
		}
	}

	void applyResource(string resourceKey) {
		applyJson(resources.jsons[resourceKey]);
	}

	void applyString(string jsonText) {
		applyJson(parseJSON(jsonText));
	}

	void applyDefaultStyle(string jsonText) {
		themeStyleBySelector["root"] = StyleData.fromJSON("root", parseJSON(jsonText));
	}

	private static StyleData[string] parseStyling(JSONValue styleMap) {
		StyleData[string] result;

		foreach (k, v; styleMap.object) {
			result[k] = StyleData.fromJSON(k, v);
		}
		return result;
	}

	Style getStyle(string type, string modifier = "", StyleData ancestor = null, StyleData local = null) {
		const modifiedSelector = format("%s[%s]", type, modifier); 

		// we are going through the cascade of styles in order, from least specific to most specific

		// embedded fallback provided by library
		Style result = new Style(rootStyleBySelector["root"], resources);
		assert(result);

		// fallback provided by theme
		if ("root" in themeStyleBySelector) {
			result = new Style(themeStyleBySelector["root"], result);
		}
		
		// ancestor in the document hierarchy 
		if (ancestor) {
			result = new Style(ancestor, result);
		}
		
		// embedded typed styles (for types such as "button" or "h1")
		if (type in rootStyleData) {
			result = new Style(rootStyleBySelector[type], result);
		}

		// embedded typed style with state modifier (for types such as button[disabled] or a[hover])
		if (modifier && modifiedSelector in rootStyleBySelector) {
			result = new Style(rootStyleBySelector[modifiedSelector], result);
		}
		
		// theme typed style
		if (type in themeStyleBySelector) {
			result = new Style(themeStyleBySelector[type], result);
		}

		// theme typed style with state modifier
		if (modifier && modifiedSelector in themeStyleBySelector) {
			result = new Style(themeStyleBySelector[modifiedSelector], result);
		}

		// TODO: ancestor typed goes here
		// TODO: ancestor typed with state modifier goes here

		// local type data, supplied directly on element
		if (local) {
			result = new Style(local, result);
		}

		// TODO: local type data with state modifier goes here

		return result;
	}

}


class Style {

	StyleData data;
	Style parent;
	ResourceManager resources;

	//TODO: templatize for Color, Number and String
	ALLEGRO_COLOR getColor(string key) {
		assert (key in PROPERTY_TYPES && PROPERTY_TYPES[key] == PropertyType.COLOR, format("Unexpected key [%s]", key));
		if (key in data.colors) {
			return data.colors[key];
		}
		else if (key in fallbackProperties && fallbackProperties[key] in data.colors) {
			return data.colors[fallbackProperties[key]];
		}
		else if (parent) {
			return parent.getColor(key);
		}
		else {
			return Color.BLACK;
		}
	}

	//TODO: templatize for Color,Number and String
	double getNumber(string key) {
		assert (key in PROPERTY_TYPES && PROPERTY_TYPES[key] == PropertyType.NUMBER, format("Unexpected key [%s]", key));
		if (key in data.numbers) {
			return data.numbers[key];
		}
		else if (key in fallbackProperties && fallbackProperties[key] in data.numbers) {
			return data.numbers[fallbackProperties[key]];
		}
		else if (parent) {
			return parent.getNumber(key);
		}
		else {
			return double.nan;
		}
	}


	//TODO: templatize for Color,Number and String
	string getString(string key) {
		assert (key in PROPERTY_TYPES && PROPERTY_TYPES[key] == PropertyType.STRING, format("Unexpected key [%s]", key));
		if (key in data.strings) {
			return data.strings[key];
		}
		else if (key in fallbackProperties && fallbackProperties[key] in data.strings) {
			return data.strings[fallbackProperties[key]];
		}
		else if (parent) {
			return parent.getString(key);
		}
		else {
			return "";
		}
	}

	this(StyleData base, ResourceManager resources) {
		this.data = base;
		this.parent = null;
		this.resources = resources;
	}

	this(StyleData base, Style parent) {
		this.resources = parent.resources;
		this.data = base;
		this.parent = parent;
	}

	Font getFont() {
		const fontName = getString("font");
		const fontSize = getNumber("font-size");
		return resources.fonts[fontName].get(cast(int)fontSize);
	}

	override string toString() {
		auto strBuilder = appender!string;
		strBuilder.put(data.toString());
		if (parent) {
			strBuilder.put(format!"; parent: (%s)"(parent));
		}
		return strBuilder.data;
	}
}


unittest {
// 	parseColorStr()
}

unittest {
	// hardcoded typed + state, 
	// theme typed + state

	// Style fallback = new Style()
	// Style theme = new Style("", ["":""]);
}
