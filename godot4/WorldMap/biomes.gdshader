shader_type canvas_item;


const float UNCERTAINTY = 1e-2;
const float SPAN = 1e-1;

const float COLDEST = 0.025;
const float COLDER = 0.075;
const float COLD = 0.3;
const float HOT = 0.55;

const float DRYER = 0.15;
const float DRY = 0.35;
const float WET = 0.65;
const float WETTER = 0.85;

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


// A step-wise color map for assigning flat colors to the water/land masses and biomes.
uniform sampler2D color_map : hint_default_black;
// We pass in the `color_map.gradient.offsets` array as a `sampler2D` as we need the positions of
// the gradient offsets to determine water and land masses.
uniform sampler2D color_map_offsets : hint_default_black;
// The following three variables are noise values for height, heat and moisture.
uniform sampler2D height_map : hint_default_black;
uniform sampler2D heat_map : hint_default_black;
uniform sampler2D moisture_map : hint_default_black;
// GDScript generated texture with linear rivers for post-processing in the shader.
uniform sampler2D rivers_map : hint_default_black;

// This is the value of `color_map.gradient.offsets.size()`. We need it to get values
// at the given indices.
uniform int color_map_offsets_n = 0;
// We calculate the next two variables on the CPU and we use them to normalize the noise values.
// This way we get the most out of the `[0, 1]` range.
uniform vec2 heat_map_minmax = vec2(0.0, 1.0);
uniform vec2 moisture_map_minmax = vec2(0.0, 1.0);


// Gets value at index from 1D array passed in as data texture from GDScript.
float get_array_at(sampler2D array, int index) {
	return texelFetch(array, ivec2(index, 0), 0).r;
}


// Gets the offset value for a given biome type (`ICE` through `TROPICAL_RAINFOREST`).
// This is used to assign a color to the biome using the discretized GradientTexture.
float get_biome(int index) {
	return get_array_at(color_map_offsets, color_map_offsets_n - index - 1) - UNCERTAINTY;
}

// Normalizes a value knowing the min/max range for that value.
float normalized(float x, vec2 minmax) {
	return (x - minmax.x) / (minmax.y - minmax.x);
}

// Remaps a normalized value to the interval [-span, span].
float normalized_remap(float x, float span) {
	return (2.0 * x - 1.0) * span;
}


void fragment() {
	float height = texture(height_map, UV).r;
	float heat = normalized(texture(heat_map, UV).r, heat_map_minmax);
	float moisture = normalized(texture(moisture_map, UV).r, moisture_map_minmax);
	float uv_perturbation = normalized_remap(height * moisture, SPAN);
	float river = texture(rivers_map, UV + uv_perturbation).r;
	float river_blured = textureLod(rivers_map, UV + uv_perturbation, 3.0).r;

	heat *= pow(sin(PI * UV.y), 2.0);
	moisture = max(moisture, step(UNCERTAINTY, river_blured));
	float rivers_level = get_array_at(color_map_offsets, 1) + UNCERTAINTY;
	height = mix(height, rivers_level, river);
	
	// Default `biome` to `height` before calculating the type with the legend table.
	float biome = height;
	// Define the height value above which landmass starts.
	float land_level = get_array_at(color_map_offsets, 2) - UNCERTAINTY;
	if (height > land_level) {
		int type = -1;
		// `ice_level` is the 12th (2nd to last) color stop.
		float ice_level = get_array_at(color_map_offsets, 11) + UNCERTAINTY;
		// The rest of the if statements are based on the biome legend table except for
		// this first test where we assign `ICE` to noise values that satisfy
		// `height > ice_level` as well.
		//
		// We follow the same pattern each time:
		// 1. Test heat values (columns in the legend)
		// 2. Test moisture values (rows in the legend)
		if (heat < COLDEST || height > ice_level) {
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
		// At this step we just need to get the appropriate value level for the given biome `type`.
		biome = get_biome(type);
	}

	// NOTE the use of `biome`
	COLOR = texture(color_map, vec2(biome, 0));
}