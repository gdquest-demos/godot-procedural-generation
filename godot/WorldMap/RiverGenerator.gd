class_name WorldMapRiverGenerator


const OFFSETS := [
	Vector2.ZERO,
	Vector2.RIGHT,
	Vector2.RIGHT + Vector2.UP,
	Vector2.UP,
	Vector2.LEFT + Vector2.UP,
	Vector2.LEFT,
	Vector2.LEFT + Vector2.DOWN,
	Vector2.DOWN,
	Vector2.RIGHT + Vector2.DOWN
]

const RIVERS_MAX_BRANCHES := 3
const BRANCH_LENGTH := Vector2(0.3, 0.65)
const BRANCH_ANGLE := Vector2(20, 45)


# Returns rivers generated from a noise-based height map as an image texture.
static func generate_rivers(
	rng: RandomNumberGenerator, texture: Texture2D, rivers_count: int, rivers_level: Vector2
) -> ImageTexture:
	var rivers := _generate_rivers(rng, texture, rivers_count, rivers_level)
	return _generate_rivers_texture(rivers, texture.get_width(), texture.get_height())


# Generate all rivers in the map as an array of pixel positions.
static func _generate_rivers(
	rng: RandomNumberGenerator, texture: Texture2D, rivers_count: int, rivers_level: Vector2
) -> Array:
	var out := []

	var available_start_positions := []
	var available_end_positions := []

	var image := texture.get_image()
	for x in range(texture.get_width()):
		for y in range(texture.get_height()):
			var noise := image.get_pixel(x, y).r
			if noise < rivers_level.x:
				available_start_positions.push_back(Vector2(x, y))
			elif rivers_level.y < noise:
				available_end_positions.push_back(Vector2(x, y))

	for _i in range(rivers_count):
		var river := _generate_river(rng, available_start_positions, available_end_positions)
		if river.is_empty():
			break
		out += river

	return out


static func _generate_river(
	rng: RandomNumberGenerator, available_start_positions: Array, available_end_positions: Array
) -> Array:
	var out := []
	if available_start_positions.is_empty():
		return out

	var r := rng.randi_range(0, available_start_positions.size() - 1)
	var start: Vector2 = available_start_positions[r]
	available_start_positions.remove_at(r)

	var end := Vector2.ZERO
	var min_distance := INF
	for position in available_end_positions:
		var distance: float = (position - start).length()
		if min_distance > distance:
			min_distance = distance
			end = position

	out.push_back([start, end])
	out += _generate_river_branches(rng, start, end)

	return out


static func _generate_river_branches(rng: RandomNumberGenerator, start: Vector2, end: Vector2) -> Array:
	var out := []

	var river_vector := end - start
	for _j in range(rng.randi_range(0, RIVERS_MAX_BRANCHES)):
		var branch_angle := deg_to_rad(rng.randf_range(BRANCH_ANGLE.x, BRANCH_ANGLE.y))
		if rng.randf() < 0.5:
			branch_angle *= -1

		var branch_length := rng.randf_range(BRANCH_LENGTH.x, BRANCH_LENGTH.y)
		var branch_start := start.lerp(end, rng.randf())
		var branch_end := (branch_start + branch_length * river_vector.rotated(branch_angle))
		out.push_back([branch_start, branch_end])

	return out


# Converts generated rivers array as an image texture.
static func _generate_rivers_texture(
	rivers: Array, width: int, height: int
) -> ImageTexture:
	var image := Image.create(width, height, true, Image.FORMAT_RF)

	for river in rivers:
		var distance: float = (river[1] - river[0]).length()
		var step := 1 / distance
		var t := 0.0
		while t <= 1:
			for offset in OFFSETS:
				var position: Vector2 = river[0].lerp(river[1], t) + offset
				if position.x < 0 or width <= position.x or position.y < 0 or height <= position.y:
					continue

				image.set_pixelv(position, Color(1, 0, 0, 0))
			t += step
	image.generate_mipmaps()

	var out := ImageTexture.create_from_image(image)
	return out
