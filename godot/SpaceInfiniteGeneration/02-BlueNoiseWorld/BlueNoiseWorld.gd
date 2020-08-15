# An extension of world generator that generates a world full of asteroids using
# blue noise: noise that is padded out so that asteroids are not pushed up
# against one another but are still in random positions inside their sectors.
extends WorldGenerator

export var Asteroid: PackedScene
export var asteroid_density := 3
export var sector_margin_proportion := 0.1
export var sub_sector_margin_proportion := 0.1

var margined_sub_sector_size: Vector2

onready var sector_margin := sector_size * sector_margin_proportion
onready var sub_sector_size := (sector_size - sector_margin * 2) / asteroid_density
onready var sub_sector_margin := sub_sector_size * sub_sector_margin_proportion

onready var grid_drawer := $GridDrawer
onready var player := $Player


func _ready() -> void:
	sub_sector_size -= sub_sector_margin * 2
	margined_sub_sector_size = Vector2(
		sub_sector_margin * 2 + sub_sector_size, sub_sector_margin * 2 + sub_sector_size
	)

	generate()
	grid_drawer.setup(sector_size, sector_count)


func _physics_process(_delta: float) -> void:
	var sector_offset := Vector2.ZERO

	var sector_location := current_sector * sector_size

	if player.global_position.distance_squared_to(sector_location) > sector_size_square:
		sector_offset = (player.global_position - sector_location) / sector_size
		sector_offset.x = int(sector_offset.x)
		sector_offset.y = int(sector_offset.y)

		update_sector(sector_offset)
		grid_drawer.move_grid_to(current_sector)


# Generates a seed_x_y seed. Splits the sector into x sub-sectors with some
# padding, and generates x asteroids, picking a new random sub-sector each time.
func _generate_at(x_id: int, y_id: int) -> void:
	if sectors.has(Vector2(x_id, y_id)):
		return

	var reset_seed := "%s_%s_%s" % [start_seed, x_id, y_id]
	rng.seed = reset_seed.hash()

	var top_left := Vector2(
		x_id * sector_size - half_sector_size + sector_margin,
		y_id * sector_size - half_sector_size + sector_margin
	)

	var sector_data := []
	var rolled_indices := []

	for _i in range(asteroid_density):
		var x := rng.randi_range(0, asteroid_density - 1)
		var y := rng.randi_range(0, asteroid_density - 1)
		var index := y * asteroid_density + x

		while index in rolled_indices:
			x = rng.randi_range(0, asteroid_density - 1)
			y = rng.randi_range(0, asteroid_density - 1)
			index = y * asteroid_density + x

		rolled_indices.append(index)

		var minimum := Vector2(
			top_left.x + margined_sub_sector_size.x * x + sub_sector_margin,
			top_left.y + margined_sub_sector_size.y * y + sub_sector_margin
		)
		var maximum := minimum + Vector2(sub_sector_size, sub_sector_size)

		var new_position := Vector2(
			rng.randf_range(minimum.x, maximum.x), rng.randf_range(minimum.y, maximum.y)
		)

		var asteroid := Asteroid.instance()
		add_child(asteroid)
		asteroid.position = new_position
		asteroid.rotation = rng.randf_range(-PI, PI)
		asteroid.scale *= rng.randf_range(0.2, 1.0)
		sector_data.append(asteroid)

	sectors[Vector2(x_id, y_id)] = sector_data
