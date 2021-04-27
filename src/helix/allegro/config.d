module helix.allegro.config;

import allegro5.allegro;
import std.conv;
import std.string;

T get_config(T) (ALLEGRO_CONFIG *config, string section, string key, T fallback) {
	const char *str = al_get_config_value(config, toStringz(section), toStringz(key));
	if (str == null) {
		return fallback;
	}
	T result = to!T(fromStringz(str));
	return result;
}

void set_config(T) (ALLEGRO_CONFIG *config, string section, string key, T value) {
	string valueStr = to!string(value);
	al_set_config_value(config, 
		toStringz(section), 
		toStringz(key),
		toStringz(valueStr));
}