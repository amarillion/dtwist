module helix.audio;

import allegro5.allegro;
import allegro5.allegro_audio;

import helix.signal;
import helix.allegro.config;
import std.stdio;

class AudioManager {

	private ALLEGRO_VOICE *voice;
	private ALLEGRO_AUDIO_STREAM *currentMusic;
	private ALLEGRO_MIXER *mixer;

	bool inited = false;
	bool soundInstalled = true;
	auto musicVolume = RangeModel!float(0.5, 0.0, 1.0);
	auto soundVolume = RangeModel!float(0.5, 0.0, 1.0);

	this() {
		currentMusic = null;
		musicVolume.onChange.add((e) {
			updateMusicVolume(e.newValue);
		});
	}

	bool isMusicOn() { return musicVolume.get() > 0; }
	bool isSoundOn() { return soundVolume.get() > 0; }
	bool isSoundInstalled() { return soundInstalled; }
	
	void initSound()
	{
		if (!al_install_audio()) {
			soundInstalled = false;
			writeln ("WARNING: Could not initialize sound. Sound is turned off.");
		}
		else {
			const success = al_reserve_samples(16);
			if (!success) {
				writeln ("Could not reserve samples");
			}
		}
		
		if (!isSoundInstalled()) { return; }

		voice = al_create_voice(44100, 
			ALLEGRO_AUDIO_DEPTH.ALLEGRO_AUDIO_DEPTH_INT16, 
			ALLEGRO_CHANNEL_CONF.ALLEGRO_CHANNEL_CONF_2);
		if (!voice) {
			writeln("Could not create ALLEGRO_VOICE.\n");	//TODO: log error.
		}

		mixer = al_create_mixer(44100, 
			ALLEGRO_AUDIO_DEPTH.ALLEGRO_AUDIO_DEPTH_FLOAT32, 
			ALLEGRO_CHANNEL_CONF.ALLEGRO_CHANNEL_CONF_2);
		if (!mixer) {
			writeln("Could not create ALLEGRO_MIXER.\n");	//TODO: log error.
		}

		if (!al_attach_mixer_to_voice(mixer, voice)) {
			writeln("al_attach_mixer_to_voice failed.\n");	//TODO: log error.
		}

		inited = true;
	}

	void getSoundFromConfig(ALLEGRO_CONFIG *config)
	{
		musicVolume.set(
			get_config!float(config, "twist", "musicVolume", musicVolume.get())
		);
		musicVolume.onChange.add((e) {
			set_config!float(config, "twist", "musicVolume", e.newValue);
		});

		soundVolume.set(
			get_config!float(config, "twist", "soundVolume", soundVolume.get())
		);

		soundVolume.onChange.add((e) {
			set_config!float(config, "twist", "soundVolume", e.newValue);
		});

	}

	void playSample (ALLEGRO_SAMPLE *s)
	{
		if (!(isSoundOn() && isSoundInstalled())) return;
		assert (s);

		bool success = al_play_sample (s, soundVolume.get(), 0.0, 1.0, 
			ALLEGRO_PLAYMODE.ALLEGRO_PLAYMODE_ONCE, null);
		if (!success) {
			writeln("Could not play sample"); //TODO: log error.
		}
	}

	void playMusic (ALLEGRO_AUDIO_STREAM *duh, float volume)
	{
		if (!isSoundInstalled()) return;
		if (!(isSoundOn() && isMusicOn())) return;
		if (currentMusic)
		{
			al_detach_audio_stream(currentMusic);
			currentMusic = null;
		}
		if (!al_attach_audio_stream_to_mixer(duh, mixer)) {
			writeln("al_attach_audio_stream_to_mixer failed.\n"); //TODO: log error.
		}
		currentMusic = duh;
		al_set_audio_stream_gain(currentMusic, volume * musicVolume.get());
	}

	void updateMusicVolume(float volume) {
		if (!isSoundInstalled()) return;

		if (currentMusic) {
			al_set_audio_stream_gain(currentMusic, volume);
		}
	}
			
	void stopMusic ()
	{
		if (currentMusic)
		{
			al_detach_audio_stream(currentMusic);
			currentMusic = null;
		}
	}

	void doneSound()
	{
		stopMusic();
	}

	~this() {
		if (soundInstalled) {
			stopMusic();
			al_destroy_mixer(mixer);
			al_destroy_voice(voice);
			al_uninstall_audio();
			soundInstalled = false;
		}
	}

}
