module helix.resources;

import allegro5.allegro_font;
import allegro5.allegro;
import allegro5.allegro_acodec;
import allegro5.allegro_audio;
import std.path;
import std.json;
import std.stdio;
import std.exception : enforce;
import std.format : format;
import std.string : toStringz;
import std.file : readText;
import helix.allegro.bitmap;
import helix.allegro.sample;
import helix.allegro.audiostream;
import helix.allegro.font;
import helix.signal;

unittest {
	//TODO, make it like this: 
	/*
	resources.addSearchPath("./data");
	
	ALLEGRO_FONT *f1 = resources.fonts["Arial"].get(16);
	ALLEGRO_FONT *f2 = resources.fonts["builtin_font"].get();
	resources.fonts["Arial"].onReload.add(() => writeln("Font changed"));
	
	ALLEGRO_BITMAP *bitmap = resources.bitmaps["MyBitmap"].get();
	resources.bitmaps["MyBitmap"].onReload.add(() => writeln("Bitmap changed"));

	JSONNode n1 = resources.json["map1"].get();
	
	// transparently accesses the same file...
	Tilemap map = resources.tilemaps["map1"].get();
	
	resources.refreshAll();
	*/
}

struct FileInfo {

	import core.stdc.time : time_t;

	this(string filename) {
		this.filename = filename;
		update();
	}

	bool isRecentlyModified() const {
		ALLEGRO_FS_ENTRY *entry = al_create_fs_entry(toStringz(filename));
		time_t newLastModified = al_get_fs_entry_mtime(entry);
		al_destroy_fs_entry(entry);
		return (newLastModified > this.lastModified);
	}

	void update() {
		ALLEGRO_FS_ENTRY *entry = al_create_fs_entry(toStringz(filename));
		lastModified = al_get_fs_entry_mtime(entry);
		al_destroy_fs_entry(entry);
	}

	string filename;
	time_t lastModified;
}

class ResourceManager
{
	this() {
		fonts.put("builtin_font", new BuiltinFont());
	}

	interface FontWrapper {
		Font get(int size = 12);
		final void refresh() {}
	}

	/**
	ResourceMap is a wrapper for resource handles.
	It has ownership of the given resources, and ensures they are destroyed in time.

	This is a struct instead of a class so that it is destroyed at the same time as ResourceManager.

	Note that it's important that resource managers explicitly invoke destructors of handled objects. If we rely on GC, 
	they may not be destroyed before uninstall_system is called, and then the system crashes.
	*/
	struct ResourceMap(T, alias LoadFunc) {
		private T[string] data;
		private T[] archived;

		//corresponding file info. Note: generated resources have no corresponding files.
		private FileInfo[string] files;

		public Signal!void[string] onReload;

		public void put(string key, T value) {
			data[key] = value;
			onReload[key] = Signal!void();
		}

		/** 
		 * If a resource with this key already exists, putFile() is ignored.
		 * Params:
		 *   fname path to file to load.
		 */
		void putFile(string fname) {
			string key = baseName(stripExtension(fname));
			if (key in data) {
				return;
			}
			// TODO Allegro log file loading...
			// writefln("Loading type: key: %s file: %s", key, fname);
			T value = LoadFunc(fname);
			data[key] = value;
			files[key] = FileInfo(fname);
			onReload[key] = Signal!void();
		}

		auto opIndex(string key) {
			enforce(key in data, format("There is no resource named [%s]", key));
			return data[key];
		}

		~this() {
			foreach (f; data) {
				destroy(f);
			}
			foreach (f; archived) {
				destroy(f);
			}
			data = null;
			archived = null;
		}

		void refresh() {
			// check all files for being out-of-date...
			foreach (key, fileInfo; files) {
				if (fileInfo.isRecentlyModified()) {
					// TODO Allegro log: file refresh...
					fileInfo.update();
					T value = LoadFunc(fileInfo.filename);
					
					archived ~= data[key]; // To avoid memory leak, old value is moved to archive. 
					// It could still be in use somewhere in the game.
					
					data[key] = value;
					onReload[key].dispatch();
				}
			}
		}
	}

	/**
		Remembers file locations.
		For each size requested, reloads font on demand.
	*/
	static class FontLoader : FontWrapper {
		private string filename;
		private Font[int] fonts;
		
		Font get(int size = 12)
		{
			if (!(size in fonts))
			{
				auto font = Font.load(filename, size, 0);
				assert (font !is null);
				fonts[size] = font;
			}
			return fonts[size];
		}
		
		this(string fileVal)
		{
			filename = fileVal;
		}

		~this() {
			foreach (font; fonts) {
				destroy(font);
			}
			fonts = null;
		}
	}
	
	class BuiltinFont : FontWrapper {
		private Font cache = null;
		Font get(int size = 0 /* size param is ignored */) {
			if (!cache) {
				cache = Font.builtin();
			}
			return cache;
		}

		~this() {
			if (cache) {
				destroy(cache);
				cache = null;
			}
		}
	}

	public ResourceMap!(FontWrapper, fname => new FontLoader(fname)) fonts;
	public ResourceMap!(Bitmap, fname => Bitmap.load(fname)) bitmaps;
	public ResourceMap!(Sample, fname => Sample.load(fname)) samples;
	public ResourceMap!(AudioStream, fname => null) music; //NOTE no load function, use addMusicFile instead. Due to .ogg extension overlap...
	public ResourceMap!(string, (fname) => readText(fname)) shaders;
	public ResourceMap!(JSONValue, ResourceManager.loadJson) jsons;
	
	private static JSONValue loadJson(string filename) {
		File file = File(filename, "rt");
		char[] buffer;
		while (!file.eof()) {
			buffer ~= file.readln();
		}
		// TODO: find streaming parser to support large files
		JSONValue result = parseJSON(buffer);
		return result;
	}

	public void addFile(string filename)
	{
		string ext = extension(filename); // ext includes '.'
		if (ext == ".ttf") {
			fonts.putFile(filename);
		}
		else if (ext == ".png") {
			bitmaps.putFile(filename);
		}
		else if (ext == ".json") {
			jsons.putFile(filename);
		}
		else if (ext == ".ogg") {
			samples.putFile(filename);
		}
		else if (ext == ".glsl") {
			shaders.putFile(filename);
		}
		else {
			enforce(false, format("Unrecognized extension %s for file %s", ext, filename));
		}
	}

	/** extra load function due to .ogg extension overlap */
	public void addMusicFile(string filename) {
		// string ext = extension(filename); // ext includes '.'
		string base = baseName(stripExtension(filename));

		auto temp = AudioStream.load(filename, 4, 2048); //TODO: correct values for al_load_audio_stream
		assert (temp, format ("error loading Music %s", filename));
		al_set_audio_stream_playmode(temp.ptr, ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP);
		music.put(base, temp);
	}

	void refreshAll() {
		//TODO: loop using tuple...
		shaders.refresh();
		bitmaps.refresh();
		jsons.refresh();
		fonts.refresh();
		samples.refresh();
	}
}