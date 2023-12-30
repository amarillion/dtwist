module helix.allegro.shader;

import helix.allegro.bitmap;
import allegro5.allegro;
import allegro5.shader;
import std.string : toStringz;
import std.format : format;
import std.conv : to;


class ShaderException : Exception {
	this(string msg, string file= __FILE__, size_t line = __LINE__) {
		super(msg, file, line);
	}
}

/**
Wrapper and builder for 

ALLEGRO_SHADER*
al_create_shader
al_attach_shader_source
al_build_shader

Checks return codes: Shader compilation errors are turned into ShaderExceptions.
*/
class Shader {

	private ALLEGRO_SHADER *shader;
	
	ALLEGRO_SHADER* ptr() {
		return shader;
	}

	private this() {}

	static Shader ofFragment(string fragmentShaderSource) {
		const char *vertexShaderSource = al_get_default_shader_source(
			ALLEGRO_SHADER_PLATFORM.ALLEGRO_SHADER_AUTO, 
			ALLEGRO_SHADER_TYPE.ALLEGRO_VERTEX_SHADER
		);

		return Shader.ofShaders(vertexShaderSource, toStringz(fragmentShaderSource));
	}

	static Shader ofVertex(string vertexShaderSource) {
		const char *fragmentShaderSource = al_get_default_shader_source(
			ALLEGRO_SHADER_PLATFORM.ALLEGRO_SHADER_AUTO, 
			ALLEGRO_SHADER_TYPE.ALLEGRO_PIXEL_SHADER
		);

		return Shader.ofShaders(toStringz(vertexShaderSource), fragmentShaderSource);		
	}

	static Shader ofShaders(string vertexShaderSource, string fragmentShaderSource) {
		return Shader.ofShaders(toStringz(vertexShaderSource), toStringz(fragmentShaderSource));
	}
	
	private static Shader ofShaders(const char* vertexShaderSource, const char *fragmentShaderSource) {
		ALLEGRO_SHADER *shader = null;
		
		string raise(string msg, string file= __FILE__, size_t line = __LINE__) {
			throw new ShaderException(format("%s: %s\n", msg, to!string(al_get_shader_log(shader))), file, line);
		}

		shader = al_create_shader(ALLEGRO_SHADER_PLATFORM.ALLEGRO_SHADER_AUTO);
		if(!shader) raise("al_create_shader failed");

		bool ok = al_attach_shader_source(shader, ALLEGRO_SHADER_TYPE.ALLEGRO_PIXEL_SHADER, fragmentShaderSource);
		if (!ok) raise("al_attach_shader_source failed");

		ok = al_attach_shader_source(shader, ALLEGRO_SHADER_TYPE.ALLEGRO_VERTEX_SHADER, vertexShaderSource);
		if (!ok) raise("al_attach_shader_source failed");

		ok = al_build_shader(shader);
		if (!ok) raise("al_build_shader failed");
		assert(ok);

		Shader result = new Shader();
		result.shader = shader;
		return result;
	}

	struct UniformSetter {
		UniformSetter withFloat(string name, float value) {
			al_set_shader_float(toStringz(name), value);
			return this;
		}

		UniformSetter withIntVector(string name, int[] value, int width, int height) {
			assert(width * height <= value.length);
			al_set_shader_int_vector(toStringz(name), width, value.ptr, height);
			return this;
		}

		UniformSetter withInt(string name, int value) {
			al_set_shader_int(toStringz(name), value);
			return this;
		}

		UniformSetter withSampler(string name, Bitmap value, int unit = 1) {
			al_set_shader_sampler(toStringz(name), value.ptr, unit);
			return this;
		}
	}

	//TODO: add facility for al_set_shader*
	UniformSetter use(bool enabled = true) {
		if (enabled) {
			al_use_shader(shader);
		}
		else {
			al_use_shader(null);
		}
		return UniformSetter();
	}

}
