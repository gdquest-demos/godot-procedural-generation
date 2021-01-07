# An extension of world generator that generates a world full of asteroids using
# blue noise: noise that is padded out so that asteroids are not pushed up
# against one another but are still in random positions inside their _sectors.
class_name BlueNoiseWorldGenerator
extends WorldGenerator

export var Asteroid: PackedScene

## The number of asteroids to generate inside of any sector. This will also
## be the number of sub-sectors to split the overrall sector into.
## I.E., 3 asteroids will split the sector into a 3x3 grid.
export var asteroid_density := 3

## The percentage of the full sector size to pad its margins by
export var sector_margin_proportion := 0.1

## The percentage of any given subsector to pad their margins by
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
	grid_drawer.setup(sector_size, sector_axis_count)


func _physics_process(_delta: float) -> void:
	var sector_offset := Vector2.ZERO

	var sector_location := _current_sector * sector_size

	if player.global_position.distance_squared_to(sector_location) > _total_sector_count:
		sector_offset = (player.global_position - sector_location) / sector_size
		sector_offset.x = int(sector_offset.x)
		sector_offset.y = int(sector_offset.y)

		_update_sectors(sector_offset)
		grid_drawer.move_grid_to(_current_sector)


## Generates a seed_x_y seed. Splits the sector into x sub-sectors with some
## padding, and generates x asteroids, picking a new random sub-sector each time.
## This results in a 'filtered' generation that prevents asteroids from spawning
## too close to the edges or each other.
func _generate_at(x_id: int, y_id: int) -> void:
	if _sectors.has(Vector2(x_id, y_id)):
		return

	# Generate a seed for the current sector and reset the number series
	_rng.seed = make_seed_for(x_id, y_id)

	# Find the top left of the entire sector in world coordinates, and move it
	# right and down by the sector's padding.
	var top_left := Vector2(
		x_id * sector_size - _half_sector_size + sector_margin,
		y_id * sector_size - _half_sector_size + sector_margin
	)

	var sector_data := []
	var rolled_indices := []

	for _i in range(asteroid_density):
		# Generate an index from [0..pow(asteroid_density^2)] to know which
		# sub-sector in the x by x grid will hold the next asteroid.
		var x := _rng.randi_range(0, asteroid_density - 1)
		var y := _rng.randi_range(0, asteroid_density - 1)
		var index := y * asteroid_density + x

		# We keep track of each rolled indices to make sure that no asteroid
		# has already been generated inside of any given sub-sector, re-rolling
		# until we find an empty one.
		while index in rolled_indices:
			x = _rng.randi_range(0, asteroid_density - 1)
			y = _rng.randi_range(0, asteroid_density - 1)
			index = y * asteroid_density + x

		rolled_indices.append(index)

		# Find the top left and bottom right of the sub-sector +/- its padding
		var minimum := Vector2(
			top_left.x + margined_sub_sector_size.x * x + sub_sector_margin,
			top_left.y + margined_sub_sector_size.y * y + sub_sector_margin
		)
		var maximum := (
			minimum 
			+ Vector2(sub_sector_size - sub_sector_margin, sub_sector_size - sub_sector_margin)
		)

		# Generate a new asteroid inside of that sub-sector boundary
		var new_position := Vector2(
			_rng.randf_range(minimum.x, maximum.x), _rng.randf_range(minimum.y, maximum.y)
		)

		var asteroid := Asteroid.instance()
		add_child(asteroid)
		asteroid.position = new_position
		asteroid.rotation = _rng.randf_range(-PI, PI)
		asteroid.scale *= _rng.randf_range(0.2, 1.0)
		sector_data.append(asteroid)

	_sectors[Vector2(x_id, y_id)] = sector_data
