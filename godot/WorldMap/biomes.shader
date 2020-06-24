shader_type canvas_item;


const float RAND_SPAN = 2e-1;
const float E = 2e-3;
const float PI = 3.14159265358979323846;

const float COLDEST = 0.01;
const float COLDER = 0.05;
const float COLD = 0.2;
const float HOT = 0.475;

const float DRYER = 0.075;
const float DRY = 0.15;
const float WET = 0.25;
const float WETTER = 0.45;

const int ICE = 0;
const int TUNDRA = 1;
const int GRASSLAND = 2;
const int WOODLAND = 3;
const int BOREAL_FOREST = 4;
const int DESERT = 5;
const int SEASONAL_FOREST = 6;
const int TEMPERATE_RAINFOREST = 7;
const int SAVANNA = 8;
const int TROPICAL_RAINFOREST = 9;

uniform sampler2D color_map : hint_black;
uniform sampler2D color_map_offsets : hint_black;
uniform sampler2D height_map : hint_black;
uniform sampler2D heat_map : hint_black;
uniform sampler2D moisture_map : hint_black;
uniform sampler2D rivers_map : hint_black;

uniform vec2 texture_pixel_size = vec2(0.0, 0.0);
uniform int color_map_offsets_n = 0;
uniform float rivers_level = 0;
uniform vec2 heat_map_minmax = vec2(0.0, 1.0);
uniform vec2 moisture_map_minmax = vec2(0.0, 1.0);


float get_array_at(in sampler2D array, in int index) {
	return texelFetch(array, ivec2(index, 0), 0).r;
}


float get_biome(in int index) {
	if (index < 0 || color_map_offsets_n <= index)
		return 0.0;
	
	return get_array_at(color_map_offsets, color_map_offsets_n - index - 1) - E;
}


float normalized(in float x, in vec2 minmax) {
	return (x - minmax.x) / (minmax.y - minmax.x);
}


void fragment() {
	float height = texture(height_map, UV).r;
	float heat = normalized(texture(heat_map, UV).r, heat_map_minmax);
	float moisture = normalized(texture(moisture_map, UV).r, moisture_map_minmax);
	float river = texture(rivers_map, RAND_SPAN * vec2(height * moisture) - 0.5 * RAND_SPAN + UV).r;
	
	river = mix(height, river, step(river, height));
	heat *= pow(sin(PI * UV.y), 2.0);
	moisture *= 1.0 - height;
	moisture = max(moisture, step(0.1, textureLod(rivers_map, UV, 3.0).r));
	height = mix(height, rivers_level, river);
	
	float biome = height;
	if (biome >= get_array_at(color_map_offsets, 2) - E) {
		int type = -1;
		if (heat < COLDEST) {
			type = ICE;
		} else if (heat < COLDER) {
			type = TUNDRA;
		} else if (heat < COLD) {
			if (moisture < DRYER) {
				type = GRASSLAND;
			} else if (moisture < DRY) {
				type = WOODLAND;
			} else {
				type = BOREAL_FOREST;
			}
		} else if (heat < HOT) {
			if (moisture < DRYER) {
				type = DESERT;
			} else if (moisture < WET) {
				type = WOODLAND;
			} else if (moisture < WETTER) {
				type = SEASONAL_FOREST;
			} else {
				type = TEMPERATE_RAINFOREST;
			}
		} else {
			if (moisture < DRYER) {
				type = DESERT;
			} else if (moisture < WET) {
				type = SAVANNA;
			} else {
				type = TROPICAL_RAINFOREST;
			}
		}
		biome = get_biome(type);
	}
	
	vec4 color = texture(color_map, vec2(biome, 0));
	COLOR = color;
}