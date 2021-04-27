module helix.util.browser;

import std.system;
import std.process;
import std.format;
import std.stdio; // debug

void openUrl(string url) {
	string cmd;
	switch (os) {
	case OS.win32: case OS.win64:
		cmd = format (`start "%s"`, url);
		break;
	default:
		cmd = format (`xdg-open "%s"`, url);
		break;
	}

	string[string] env;
	writefln("Running `%s`", cmd);
	spawnShell(cmd, env, Config.detached);
}