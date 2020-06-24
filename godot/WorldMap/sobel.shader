shader_type canvas_item;


uniform vec4 edge_color : hint_color;
uniform vec2 delta = vec2(0.5);


float sobel(sampler2D tex, vec2 uv, vec2 pixel_size) {
	vec2 delta_pixel = delta * pixel_size;

	vec4 h = vec4(0.0);
	vec4 v = vec4(0.0);

	h +=       texture(tex, uv + vec2(-1.0, -1.0) * delta_pixel);
	h -=       texture(tex, uv + vec2( 0.0, -1.0) * delta_pixel);
	h += 2.0 * texture(tex, uv + vec2(-1.0,  0.0) * delta_pixel);
	h -= 2.0 * texture(tex, uv + vec2( 1.0,  0.0) * delta_pixel);
	h +=       texture(tex, uv + vec2(-1.0,  1.0) * delta_pixel);
	h -=       texture(tex, uv + vec2( 1.0,  1.0) * delta_pixel);

	v +=       texture(tex, uv + vec2(-1.0, -1.0) * delta_pixel);
	v += 2.0 * texture(tex, uv + vec2( 0.0, -1.0) * delta_pixel);
	v +=       texture(tex, uv + vec2( 1.0, -1.0) * delta_pixel);
	v -=       texture(tex, uv + vec2(-1.0,  1.0) * delta_pixel);
	v -= 2.0 * texture(tex, uv + vec2( 0.0,  1.0) * delta_pixel);
	v -=       texture(tex, uv + vec2( 1.0,  1.0) * delta_pixel);

	return sqrt(dot(h, h) + dot(v, v));
}


void fragment() {
	float s = sobel(SCREEN_TEXTURE, SCREEN_UV, SCREEN_PIXEL_SIZE);
	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = mix(COLOR, edge_color, s);
}