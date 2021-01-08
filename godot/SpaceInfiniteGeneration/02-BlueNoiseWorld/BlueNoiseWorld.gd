# Generates a world full of asteroids using blue noise: a noise that is padded
# out so that asteroids are not pushed up against one another but are still in
# random positions inside their sectors.
class_name BlueNoiseWorldGenerator
extends WorldGenerator

export var Asteroid: PackedScene

## The number of asteroids to generate inside of any sector. Affects the number
## of sub-sectors to split the overall sector. For example, a value of 3 will
## split the sector into a 3x3 grid.
export var asteroid_density := 3

## The percentage of the full sector size to pad its margins by.
export var sector_margin_proportion := 0.1

## The percentage of any given subsector to pad their margins by.
export var sub_sector_margin_proportion := 0.1

var margined_sub_sector_size: Vector2

onready var _sector_margin := sector_size * sector_margin_proportion
onready var _sub_sector_size := (sector_size - _sector_margin * 2) / asteroid_density
onready var _sub_sector_margin := _sub_sector_size * sub_sector_margin_proportion

onready var _grid_drawer := $GridDrawer
onready var _player := $Player


func _ready() -> void:
	_sub_sector_size -= _sub_sector_margin * 2
	margined_sub_sector_size = Vector2(
		_sub_sector_margin * 2 + _sub_sector_size, _sub_sector_margin * 2 + _sub_sector_size
	)

	generate()
	_grid_drawer.setup(sector_size, sector_axis_count)


func _physics_process(_delta: float) -> void:
	var sector_offset := Vector2.ZERO

	var sector_location := _current_sector * sector_size

	if _player.global_position.distance_squared_to(sector_location) > _total_sector_count:
		sector_offset = (_player.global_position - sector_location) / sector_size
		sector_offset.x = int(sector_offset.x)
		sector_offset.y = int(sector_offset.y)

		_update_sectors(sector_offset)
		_grid_drawer.move_grid_to(_current_sector)


## Splits the sector into x sub-sectors with some padding, and generates x
## asteroids, picking a new random sub-sector each time. This results in a
## 'filtered' generation that prevents asteroids from spawning too close to the
## edges or each other.
func _generate_sector(x_id: int, y_id: int) -> void:
	if _sectors.has(Vector2(x_id, y_id)):
		return

	# Generate a seed for the current sector and reset the number series
	_rng.seed = make_seed_for(x_id, y_id)
	# We use the same seed for the global GDScript random number generator.
	# This affects the Array.shuffle() method we use below and makes it
	# deterministic.
	seed(_rng.seed)

	# Find the top left of the entire sector in world coordinates, and move it
	# right and down by the sector's padding.
	var top_left := Vector2(
		x_id * sector_size - _half_sector_size + _sector_margin,
		y_id * sector_size - _half_sector_size + _sector_margin
	)

	var sector_data := []
	var sub_sector_count := asteroid_density * asteroid_density
	# We generate as many indices as there are sub-sectors and shuffle the
	# numbers.
	var sector_indices = range(sub_sector_count)
	sector_indices.shuffle()

	for i in range(asteroid_density):
		# Calculate the sub-sector coordinates for this asteroid
		var x: int = sector_indices[i] / asteroid_density
		var y: int = sector_indices[i] - x * asteroid_density

		# Find the top left and bottom right of the sub-sector +/- its padding
		var minimum := Vector2(
			top_left.x + margined_sub_sector_size.x * x + _sub_sector_margin,
			top_left.y + margined_sub_sector_size.y * y + _sub_sector_margin
		)
		var maximum := (
			minimum
			+ Vector2(_sub_sector_size - _sub_sector_margin, _sub_sector_size - _sub_sector_margin)
		)

		# Generates a new asteroid inside of that sub-sector boundary.
		var asteroid := Asteroid.instance()
		add_child(asteroid)
		asteroid.position = Vector2(
			_rng.randf_range(minimum.x, maximum.x), _rng.randf_range(minimum.y, maximum.y)
		)
		asteroid.rotation = _rng.randf_range(-PI, PI)
		asteroid.scale *= _rng.randf_range(0.2, 1.0)
		sector_data.append(asteroid)

	_sectors[Vector2(x_id, y_id)] = sector_data
