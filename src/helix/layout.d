module helix.layout;

import std.json;
import helix.util.box;
import std.exception;
import std.format;
import std.stdio;

enum LayoutRule {
	STRETCH, // take full parent width, minus margins
	BEGIN, // align to the top/left
	END, // align to the bottom/right
	CENTER // fixed width...
}

struct LayoutData {

	// NB: default values are equivalent to filling the full parent rect.
	int left;
	int top;
	
	int right;
	int bottom;
	
	int width;
	int height;
	
	LayoutRule horizontalRule = LayoutRule.STRETCH;
	LayoutRule verticalRule = LayoutRule.STRETCH;

	void fromJSON(JSONValue[string] jsonObj) {
		
		void setIntegerIfPossible(string key, ref int value) {
			if (key in jsonObj) {
				value = cast(int)jsonObj[key].integer;
			}
		}
		
		setIntegerIfPossible("top", top);
		setIntegerIfPossible("left", left);
		setIntegerIfPossible("bottom", bottom);
		setIntegerIfPossible("right", right);
		setIntegerIfPossible("width", width);
		setIntegerIfPossible("height", height);
		
		string rule = "stretch"; // default 
		if ("rule" in jsonObj) {
			rule = jsonObj["rule"].str;
		}

		LayoutRule[2][string] ruleMap = [
			"stretch":       [ LayoutRule.STRETCH, LayoutRule.STRETCH ],
			"top-left":      [ LayoutRule.BEGIN,   LayoutRule.BEGIN   ],
			"top-right":     [ LayoutRule.END,     LayoutRule.BEGIN   ],
			"bottom-left":   [ LayoutRule.BEGIN,   LayoutRule.END     ],
			"bottom-right":  [ LayoutRule.END,     LayoutRule.END     ],
			"stretch-left":  [ LayoutRule.BEGIN,   LayoutRule.STRETCH ],
			"stretch-right": [ LayoutRule.END,     LayoutRule.STRETCH ],
			"stretch-top":   [ LayoutRule.STRETCH, LayoutRule.BEGIN   ],
			"stretch-bottom":[ LayoutRule.STRETCH, LayoutRule.END     ],
			"center":        [ LayoutRule.CENTER,  LayoutRule.CENTER  ],
			//TODO: more variants of center rule...
		];

		enforce(rule in ruleMap, format("Unknown layout rule %s", rule));
		horizontalRule = ruleMap[rule][0];
		verticalRule = ruleMap[rule][1];
	}

	Rect!int calculate(Rect!int parent) {

		int[2] calculateAxis(int start, int end, int size, LayoutRule rule) {
			final switch (rule) {
				case LayoutRule.BEGIN: return [ start, size ];
				case LayoutRule.END: return [ end - size, size ];
				case LayoutRule.STRETCH: return [ start, end - start ];
				case LayoutRule.CENTER: return [ (end + start - size) / 2, size ];
			}
		}

		int[2] h = calculateAxis(parent.x + left, parent.x2 - right, width, horizontalRule);
		int[2] v = calculateAxis(parent.y + top, parent.y2 - bottom, height, verticalRule);

		if (h[1] == 0 || v[1] == 0) {
			writeln("Warn: component with zero-width or height is invisible...");
		}
		return Rectangle(h[0], v[0], h[1], v[1]);
	}
}
