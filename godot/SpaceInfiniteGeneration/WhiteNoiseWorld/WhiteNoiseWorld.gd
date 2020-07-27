extends WorldGenerator

export var Asteroid: PackedScene
export var asteroid_density := 3

onready var grid_drawer := $GridDrawer
onready var player := $Player


func _ready() -> void:
	_generate()
	grid_drawer.setup(sector_size, sector_count)


func _physics_process(_delta: float) -> void:
	var sector_offset := Vector2.ZERO

	var sector_location := current_sector * sector_size

	if player.global_position.distance_squared_to(sector_location) > sector_size_square:
		sector_offset = (player.global_position - sector_location) / sector_size
		sector_offset.x = int(sector_offset.x)
		sector_offset.y = int(sector_offset.y)

		_update_sector(sector_offset)
		grid_drawer.move_grid_to(current_sector)


func _generate_at(x_id: int, y_id: int) -> void:
	if sectors.has(Vector2(x_id, y_id)):
		return

	var reset_seed := "%s_%s_%s" % [start_seed, x_id, y_id]
	rng.seed = reset_seed.hash()

	var bounds := [
		Vector2(x_id * sector_size - half_sector_size, y_id * sector_size - half_sector_size),
		Vector2(x_id * sector_size + half_sector_size, y_id * sector_size + half_sector_size),
	]

	var sector_data := []

	for _i in range(asteroid_density):
		var new_position := Vector2(
			rng.randf_range(bounds[0].x, bounds[1].x), rng.randf_range(bounds[0].y, bounds[1].y)
		)

		var asteroid := Asteroid.instance()
		add_child(asteroid)
		asteroid.position = new_position
		asteroid.rotation = rng.randf_range(-PI, PI)
		asteroid.scale *= rng.randf_range(0.2, 1.0)
		sector_data.append(asteroid)

	sectors[Vector2(x_id, y_id)] = sector_data
