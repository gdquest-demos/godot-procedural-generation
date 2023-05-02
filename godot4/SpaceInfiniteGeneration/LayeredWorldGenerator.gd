# Generates an infinite world using a layered approach, allowing each layer to
# access the previous layers' data. Each layer is smaller than the next, so they
# can also access their neighbors' data.
class_name LayeredWorldGenerator
extends WorldGenerator

const PLANET_BASE_SIZE := 96
const MOON_BASE_SIZE := 32
const ASTEROID_BASE_SIZE := 16

# Used to calculate the 8 neighbors around any one sector.
const NEIGHBORS := [
	Vector2(1, 0),
	Vector2(1, 1),
	Vector2(0, 1),
	Vector2(-1, 1),
	Vector2(-1, 0),
	Vector2(-1, -1),
	Vector2(0, -1),
	Vector2(1, -1)
]
const LAYERS = {
	seeds = [],
	planet = {},
	moons = [],
	travel_lanes = [],
	asteroids = [],
}

## Hides or shows the grid and the planetary seeding points.
@export var show_debug := false : set = _set_show_debug

## Percentage to keep the planetary seeding points away from the sector edges.
@export var sector_margin_proportion := 0.1

## The maximum area covered by the three seeding vertices for a planet to form.
@export var planet_generation_area_threshold := 5000.0

## The probability of a moon being generated next to a planet.
@export var moon_generation_chance := 1.1 / 3.0
@export var max_moon_count := 5

## The probability of asteroids being generated next to a planet.
@export var asteroid_generation_chance := 3.0 / 4.0
## The maximum number of asteroids we can generate in one sector.
@export var max_asteroid_count := 10

## The pixel value of the margin calculated from the margin percentage
@onready var _sector_margin := sector_size * sector_margin_proportion

@onready var _player := $Player
@onready var _grid_drawer := $GridDrawer

func _ready() -> void:
	generate()
	_grid_drawer.setup(sector_size, sector_axis_count)
	_grid_drawer.visible = show_debug


## Generates the world with a layered approach. Each layer requires another
## layer before it to already be generated. Seeds are generated first and
## furthest from the center, then planets one row/column less, then moons one
## row/column less, then travel lanes, then asteroids nearest to the player.
## This creates our world's layers, each one smaller than the one before it, but
## all contained within the player's view (normally.)
func generate() -> void:
	var index : int = -1
	for layer in LAYERS:
		index += 1
		for x in range(
			
			_current_sector.x - _half_sector_count + index,
#			0 - _half_sector_count + index,
#			-8,
			_current_sector.x + _half_sector_count - index
#			0 + _half_sector_count - index
#			_current_sector.x
		):
			for y in range(
				_current_sector.y - _half_sector_count + index,
				_current_sector.y + _half_sector_count - index
			):
				var sector = Vector2(x, y)
				match layer:
					"seeds":
						# Initialize the sector's data at the start.
						if not _sectors.has(sector):
							_sectors[sector] = LAYERS.duplicate(true)
						_generate_seeds_at(sector)
					"planet":
						_generate_planets_at(sector)
					"moons":
						_generate_moons_at(sector)
					"travel_lanes":
						_generate_travel_lanes_at(sector)
					"asteroids":
						_generate_asteroids_at(sector)
	queue_redraw()


# Draws the generated data.
func _draw() -> void:
	for data in _sectors.values():
		# Draw seeding points.
		if show_debug and data.seeds:
			for point in data.seeds:
				draw_circle(point, 12, Color(0.5, 0.5, 0.5, 0.5))

		if data.planet:
			draw_circle(data.planet.position, PLANET_BASE_SIZE * data.planet.scale, Color.BISQUE)
		for moon in data.moons:
			draw_circle(moon.position, MOON_BASE_SIZE * moon.scale, Color.AQUAMARINE)
		for path in data.travel_lanes:
			var start: Vector2 = path.source
			var end: Vector2 = path.destination
			draw_line(start, end, Color.CORNFLOWER_BLUE, 6.0)
		for asteroid in data.asteroids:
			draw_circle(asteroid.position, ASTEROID_BASE_SIZE * asteroid.scale, Color.ORANGE_RED)


# Whenever the player changes sector, erase those that fall out of scope and generate new ones
func _physics_process(_delta: float) -> void:
	var sector_offset := Vector2.ZERO

	var sector_location := _current_sector * sector_size

	if _player.global_position.distance_squared_to(sector_location) > _sector_size_squared:
		sector_offset = (_player.global_position - sector_location) / sector_size
		sector_offset.x = int(sector_offset.x)
		sector_offset.y = int(sector_offset.y)

		_update_sectors(sector_offset)
		_grid_drawer.move_grid_to(_current_sector)


# Erases old sectors by difference, and generates new ones. Since our generation
# algorithm is more complex than the default generation, we override _update_along_axis
# to only delete and then call generate again to fill in any created gaps in the layers.
func _update_sectors(difference: Vector2) -> void:
	_update_along_axis(AXIS_X, difference.x)
	_update_along_axis(AXIS_Y, difference.y)
	generate()


## Seeds a triangle inside of the `sector`. The next layer can use these to make
## planets. Their overall density and proximity to one another may or may not
## birth a planet.
func _generate_seeds_at(sector: Vector2) -> void:
	if _sectors[sector].seeds:
		return

	# Create a seed for the current sector's triangular seeds
	_rng.seed = make_seed_for(sector.x, sector.y, "seeds")

	# Find the boundaries of the sector +/- some padding
	var half_size := Vector2(_half_sector_size, _half_sector_size)
	var margin := Vector2(_sector_margin, _sector_margin)
	var top_left := sector * sector_size - half_size + margin
	var bottom_right := sector * sector_size + half_size - margin

	# Generates 3 points to create a triangle using white noise.
	# These points' 'density' will be used to decide in the next layer whether
	# there should be a planet in this sector.
	var seeds := []
	for _i in range(3):
		var seed_position := Vector2(
			_rng.randf_range(top_left.x, bottom_right.x),
			_rng.randf_range(top_left.y, bottom_right.y)
		)
		seeds.append(seed_position)
	_sectors[sector].seeds = seeds


# Potentially generate a planet in a given sector. They can only be one planet
# in a sector.
func _generate_planets_at(sector: Vector2) -> void:
	if _sectors[sector].planet:
		return

	# Calculate the area created by the 3 seeded points.
	var vertices: Array = _sectors[sector].seeds
	var area := _calculate_triangle_area(vertices[0], vertices[1], vertices[2])

	# If the area is less than the generation threshold, create a planet appropriate
	# to the seeds' area.
	if area < planet_generation_area_threshold:
		_sectors[sector].planet = {
			position = _calculate_triangle_epicenter(vertices[0], vertices[1], vertices[2]),
			scale = 0.5 + area / (planet_generation_area_threshold / 2.0)
		}


# If there is a planet inside of a given sector, a loop begins and there is a
# chance of a moon being generated. The dice is rolled until it comes up
# negative.
func _generate_moons_at(sector: Vector2) -> void:
	if _sectors[sector].moons != []:
		return

	# Get the sector's planet layer and check if there is a planet. If there is
	# not, cancel and move checked.
	var planet: Dictionary = _sectors[sector].planet
	if planet.is_empty():
		return

	# Generate a seed for moons in the sector
	_rng.seed = make_seed_for(sector.x, sector.y, "moons")

	# Keeps track of the number of generated moons.
	var moon_count := 0
	# If we roll below the moon chance, generate a moon in an orbit's distance of the planet
	while _rng.randf() < moon_generation_chance or moon_count == max_moon_count:
		var random_offset: Vector2 = (
			Vector2.UP.rotated(_rng.randf_range(-PI, PI))
			* planet.scale
			* PLANET_BASE_SIZE
			* 3.0
		)
		moon_count += 1
		_sectors[sector].moons.append(
			{position = planet.position + random_offset, scale = planet.scale / 3.0}
		)


# If this sector has a planet, checks the 8 _sectors around it for neighbors.
# If there are planets in those _sectors, creates a lane between the two of them.
func _generate_travel_lanes_at(sector: Vector2) -> void:
	if _sectors[sector].travel_lanes:
		return

	# If there is no planet, don't generate anything.
	var planet: Dictionary = _sectors[sector].planet
	if planet.is_empty():
		return

	# Check each neighbor for a planet. If there is one, create a dictionary that
	# links the two worlds together with a line to indicate a trading partner.
	for neighbor in NEIGHBORS:
		var neighbor_sector: Vector2 = sector + neighbor
		if _sectors[neighbor_sector].planet.is_empty():
			continue

		var neighbor_position: Vector2 = _sectors[neighbor_sector].planet.position
		_sectors[sector].travel_lanes.append(
			{source = planet.position, destination = neighbor_position}
		)


# If this sector has a planet, does not have a moon and does not have any trade 
# lanes (because they'd have been cleared out by the traders/miners),
# then a loop begins and there is 75% chance to generate a random asteroid around it.
func _generate_asteroids_at(sector: Vector2) -> void:
	if _sectors[sector].asteroids:
		return

	# Check for planet, moons and travel lanes. If there is a planet and neither
	# moon or travel lane, begin generating an asteroid belt in an orbit.
	var planet: Dictionary = _sectors[sector].planet
	if planet.is_empty() or _sectors[sector].moons or _sectors[sector].travel_lanes:
		return

	_rng.seed = make_seed_for(sector.x, sector.y, "asteroids")

	# Keep rolling the dice until it comes up greater than 75%, creating a new
	# asteroid within an orbit's range of the planet
	var count := 0
	while _rng.randf() < asteroid_generation_chance and count < max_asteroid_count:
		count += 1

		var random_offset: Vector2 = (
			Vector2.UP.rotated(_rng.randf_range(-PI, PI))
			* planet.scale
			* PLANET_BASE_SIZE
			* _rng.randf_range(3.0, 4.0)
		)
		_sectors[sector].asteroids.append(
			{position = planet.position + random_offset, scale = planet.scale / 5.0}
		)


# Erases old _sectors. New ones are generated by the subsequent call to generate()
func _update_along_axis(axis: int, difference: float) -> void:
	if difference == 0 or (axis != AXIS_X and axis != AXIS_Y):
		return

	# Find the current sector's row/column
	var axis_current := _current_sector.x if axis == AXIS_X else _current_sector.y

	# Find the edges of the row/column, perpendicular to the axis we're updating
	var other_axis_min := (
		(_current_sector.y if axis == AXIS_X else _current_sector.x)
		- _half_sector_count
	)
	var other_axis_max := (
		(_current_sector.y if axis == AXIS_X else _current_sector.x)
		+ _half_sector_count
	)

	var axis_modifier: int = difference <= 0
	# For each row/column between where we were and where we are now
	for sector_index in range(1, abs(difference) + 1):
		var axis_key := int(axis_current + (_half_sector_count - axis_modifier) * -sign(difference))

		# Erase the entire row/column.
		for other in range(other_axis_min, other_axis_max):
			var key := Vector2(
				axis_key if axis == AXIS_X else other, other if axis == AXIS_X else axis_key
			)
			_sectors.erase(key)

	# Update the current sector for later reference
	if axis == AXIS_X:
		_current_sector.x += difference
	else:
		_current_sector.y += difference


func _set_show_debug(value: bool) -> void:
	show_debug = value
	if not is_inside_tree():
		await self.ready
	_grid_drawer.visible = show_debug
	queue_redraw()


## Returns the area of a triangle.
func _calculate_triangle_area(a: Vector2, b: Vector2, c: Vector2) -> float:
	return abs(a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)) / 2.0


func _calculate_triangle_epicenter(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	return (a + b + c) / 3.0
