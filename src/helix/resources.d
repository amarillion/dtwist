module helix.resources;

import allegro5.allegro_font;
import allegro5.allegro;
import allegro5.allegro_acodec;
import allegro5.allegro_audio;
import std.path;
import std.json;
import std.stdio;
import std.format : format;
import std.string : toStringz;
import std.file : readText;
import helix.allegro.bitmap;
import helix.allegro.sample;
import helix.allegro.audiostream;
import helix.allegro.font;
import helix.signal;

/*
struct ResourceHandle(T) {
	string fname;
	Signal onReload;
	T resource;

	this(fname) {
		this.fname = fname;
	}

	T get()
	
	load(fname) {

	}

	reload(fname) {
	}

	// check if given file resource is out-of-date
	refresh() {

	}
}
*/

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

// Dummy implementations to make generic code compile
void refresh(Bitmap) {}
void refresh(Sample) {}
void refresh(AudioStream) {}

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
	struct ResourceMap(T) {
		private T[string] data;

		void put(string key, T value) {
			data[key] = value;
		}

		auto opIndex(string key) {
			assert (key in data, format("There is no resource named [%s]", key));
			return data[key];
		}

		~this() {
			foreach (f; data) {
				destroy(f);
			}
			data = null;
		}

		void refresh() {
			// check all resources for being out-of-date...
			foreach (f; data) {
				f.refresh();
			}
		}
	}

	/**
		Remembers file locations.
		For each size requested, reloads font on demand.
	*/
	class FontLoader : FontWrapper {
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

	public ResourceMap!FontWrapper fonts;
	public ResourceMap!Bitmap bitmaps;
	public ResourceMap!Sample samples;
	public ResourceMap!AudioStream music;
	public ResourceMap!GlslLoader shaders;
	private JSONValue[string] jsons;
	
	private JSONValue loadJson(string filename) {
		File file = File(filename, "rt");
		char[] buffer;
		while (!file.eof()) {
			buffer ~= file.readln();
		}
		// TODO: find streaming parser to support large files
		JSONValue result = parseJSON(buffer);
		return result;
	}

	class GlslLoader {
		string fname;
		FileInfo finfo;
		Signal!void onReload;
		string resource;

		this(string fname) {
			this.fname = fname;
			finfo = FileInfo(fname);
		}

		string get() { return resource; }
		
		alias get this; // automatic converstion to the GLSL source

		void load() {
			resource = readText(fname);
		}

		// check if given file resource is out-of-date
		void refresh() {
			if (finfo.isRecentlyModified()) {
				finfo.update();
				load();
				onReload.dispatch();
			}
		}
	}

	public void addFile(string filename)
	{
		string ext = extension(filename); // ext includes '.'
		string base = baseName(stripExtension(filename));
		
		if (ext == ".ttf") {
			fonts.put(base, new FontLoader(filename));
		}
		else if (ext == ".png") {
			Bitmap bmp = Bitmap.load(filename);
			bitmaps.put(base, bmp);
		}
		else if (ext == ".json") {
			jsons[base] = loadJson(filename);
		}
		else if (ext == ".ogg") {
			Sample sample = Sample.load(filename);
			samples.put(base, sample);
		}
		else if (ext == ".glsl") {
			// TODO use allegro file routines to allow loading via physfs...
			GlslLoader loader = new GlslLoader(filename);
			loader.load();
			shaders.put(base, loader);
		}
	}
	
	public void addMusicFile(string filename) {
		// string ext = extension(filename); // ext includes '.'
		string base = baseName(stripExtension(filename));

		auto temp = AudioStream.load(filename, 4, 2048); //TODO: correct values for al_load_audio_stream
		assert (temp, format ("error loading Music %s", filename));
		al_set_audio_stream_playmode(temp.ptr, ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_LOOP);
		music.put(base, temp);
	}

	public JSONValue getJSON(string name) {
		assert (name in jsons, format("There is no JSON named [%s]", name)); 
		return jsons[name];
	}

	void refreshAll() {
		//TODO: loop over all resource maps, not just the one...
		shaders.refresh();
	}
}