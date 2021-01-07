# An extension of world generator that uses simple white noise with no padding
# to generate a world full of asteroids.
extends WorldGenerator

export var Asteroid: PackedScene
export var asteroid_density := 3

onready var grid_drawer := $GridDrawer
onready var player := $Player


func _ready() -> void:
	generate()
	grid_drawer.setup(sector_size, sector_axis_count)


func _physics_process(_delta: float) -> void:
	var sector_offset := Vector2.ZERO

	var sector_location := _current_sector * sector_size

	# Update the sector and grid if the player has moved far enough along to erase
	# the previous column/row and add a new column/row
	if player.global_position.distance_squared_to(sector_location) > _total_sector_count:
		sector_offset = (player.global_position - sector_location) / sector_size
		sector_offset = sector_offset.floor()

		_update_sectors(sector_offset)
		grid_drawer.move_grid_to(_current_sector)


# Generates a new seed in the form of seed_x_y and generates asteroids inside
# of the sector's bounds with random position, rotation and scale.
func _generate_sector(x_id: int, y_id: int) -> void:
	# If the sector has been generated already, don't generate it again
	if _sectors.has(Vector2(x_id, y_id)):
		return

	# Create a seed for the current sector. This resets the series of numbers
	# back to the start, which ensures the world generates the same every time
	# we use the same seed.
	_rng.seed = make_seed_for(x_id, y_id)

	# Calculate the sector boundaries based on the current x and y sector coords
	var bounds := [
		Vector2(x_id * sector_size - _half_sector_size, y_id * sector_size - _half_sector_size),
		Vector2(x_id * sector_size + _half_sector_size, y_id * sector_size + _half_sector_size),
	]

	var sector_data := []

	# Generates 3 purely random Vector2 in a square and assign an asteroid to it,
	# with a random angle and scale.
	for _i in range(asteroid_density):
		var new_position := Vector2(
			_rng.randf_range(bounds[0].x, bounds[1].x), _rng.randf_range(bounds[0].y, bounds[1].y)
		)

		var asteroid := Asteroid.instance()
		add_child(asteroid)
		asteroid.position = new_position
		asteroid.rotation = _rng.randf_range(-PI, PI)
		asteroid.scale *= _rng.randf_range(0.2, 1.0)
		sector_data.append(asteroid)

	# Keep track of the sector's assignment
	_sectors[Vector2(x_id, y_id)] = sector_data
