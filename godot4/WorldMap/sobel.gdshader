shader_type canvas_item;


uniform vec4 edge_color : source_color;
uniform vec2 edge_width = vec2(0.1);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


float sobel(sampler2D tex, vec2 uv, vec2 pixel_size) {
	vec2 edge_width_pixel = edge_width * pixel_size;

	vec4 h = vec4(0.0);
	vec4 v = vec4(0.0);

	h +=       texture(tex, uv + vec2(-1.0, -1.0) * edge_width_pixel);
	h -=       texture(tex, uv + vec2( 0.0, -1.0) * edge_width_pixel);
	h += 2.0 * texture(tex, uv + vec2(-1.0,  0.0) * edge_width_pixel);
	h -= 2.0 * texture(tex, uv + vec2( 1.0,  0.0) * edge_width_pixel);
	h +=       texture(tex, uv + vec2(-1.0,  1.0) * edge_width_pixel);
	h -=       texture(tex, uv + vec2( 1.0,  1.0) * edge_width_pixel);

	v +=       texture(tex, uv + vec2(-1.0, -1.0) * edge_width_pixel);
	v += 2.0 * texture(tex, uv + vec2( 0.0, -1.0) * edge_width_pixel);
	v +=       texture(tex, uv + vec2( 1.0, -1.0) * edge_width_pixel);
	v -=       texture(tex, uv + vec2(-1.0,  1.0) * edge_width_pixel);
	v -= 2.0 * texture(tex, uv + vec2( 0.0,  1.0) * edge_width_pixel);
	v -=       texture(tex, uv + vec2( 1.0,  1.0) * edge_width_pixel);

	return sqrt(dot(h, h) + dot(v, v));
}


void fragment() {
	float s = sobel(SCREEN_TEXTURE, SCREEN_UV, SCREEN_PIXEL_SIZE);
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = mix(COLOR, edge_color, s);
}