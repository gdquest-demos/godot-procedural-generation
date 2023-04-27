class_name WorldMapUtils


# Normalizes a value from a noise generator based on the noise's minimum and maximum range.
static func normalize_noise(value: float, minmax := Vector2(-1, 1)) -> float:
	return remap(value, minmax.x, minmax.y, 0, 1)


# Normalizes the components of a 2D vector individually and returns them as a new Vector2.
# Intended to use with the minmax range of a noise generator.
static func normalize_noise_vector2(value: Vector2) -> Vector2:
	return Vector2(normalize_noise(value.x), normalize_noise(value.y))


# Returns the minimum and maximum value of a noise texture as a Vector2.
static func get_minmax_noise(texture: NoiseTexture2D) -> Vector2:
	var out := Vector2(INF, -INF)
	for x in texture.width:
		for y in texture.height:
			var value := texture.noise.get_noise_2d(x, y)
			out.x = min(out.x, value)
			out.y = max(out.y, value)
	return out
