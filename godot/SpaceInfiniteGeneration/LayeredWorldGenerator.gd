# Generates an infinite world using a layered approach, allowing each layer to
# access the previous layers' data. Each layer is smaller than the next, so they
# can also access their neighbors' data.
class_name LayeredWorldGenerator
extends WorldGenerator


# Used to calculate the 8 neighbors around any one sector.
const NEIGHBORS := [
	Vector2(1, 0),
	Vector2(1,1),
	Vector2(0, 1),
	Vector2(-1, 1),
	Vector2(-1, 0),
	Vector2(-1, 1),
	Vector2(0, -1),
	Vector2(1, -1)
]

# Hides or shows the grid and the planetary seeding points
export var show_debug := false setget _set_show_debug

# Percentage to keep the planetary seeding points away from the sector edges
export var sector_margin_proportion := 0.1

# The maximum area made by the 3 seeding points for a planet to form.
# Higher == more planets
export var planet_generation_area_threshold := 5000.0

# The percentage chance of a moon being generated next to a planet.
export var moon_generation_chance := 1 / 3
export var max_moon_count := 5

# The pixel value of the margin calculated from the margin percentage
onready var _sector_margin := sector_size * sector_margin_proportion

onready var _player := $Player
onready var _grid_drawer := $GridDrawer


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
	for layer in range(0, 5):
		for x in range(_current_sector.x - _half_sector_count + layer, _current_sector.x + _half_sector_count - layer):
			for y in range(_current_sector.y - _half_sector_count + layer, _current_sector.y + _half_sector_count - layer):
				match layer:
					0:
						_generate_seeds_at(x, y)
					1:
						_generate_planets_at(x, y)
					2:
						_generate_moons_at(x, y)
					3:
						_generate_travel_lanes_at(x, y)
					4:
						_generate_asteroids_at(x, y)
	update()


# Draws the generated data.
func _draw() -> void:
	for key in _sectors.keys():
		# Draw seeding points.
		if show_debug and _sectors[key].size() > 0:
			for point in _sectors[key][0]:
				draw_circle(point, 12, Color(0.5, 0.5, 0.5, 0.5))

		# Planets.
		if _sectors[key].size() > 1 and _sectors[key][1].size() > 0:
			draw_circle(_sectors[key][1].position, 96 * (1.0 + _sectors[key][1].size), Color.bisque)

		# Moons.
		if _sectors[key].size() > 2:
			for moon in _sectors[key][2]:
				draw_circle(moon.position, 32 * (1.0 + moon.size), Color.aquamarine)

		# Travel lanes.
		if _sectors[key].size() > 3:
			for path in _sectors[key][3]:
				var start: Vector2 = path.source
				var end: Vector2 = path.destination
				draw_line(start, end, Color.cornflower, 6.0)

		# Asteroids.
		if _sectors[key].size() > 4:
			for asteroid in _sectors[key][4]:
				draw_circle(asteroid.position, 16 * (1.0 + asteroid.size), Color.orangered)


# Whenever the player changes sector, erase those that fall out of scope and generate new ones
func _physics_process(_delta: float) -> void:
	var sector_offset := Vector2.ZERO

	var sector_location := _current_sector * sector_size

	if _player.global_position.distance_squared_to(sector_location) > _total_sector_count:
		sector_offset = (_player.global_position - sector_location) / sector_size
		sector_offset.x = int(sector_offset.x)
		sector_offset.y = int(sector_offset.y)

		_update_sectors(sector_offset)
		_grid_drawer.move_grid_to(_current_sector)


# Erases old _sectors by difference, and generates new ones. Since our generation
# algorithm is more complex than the default generation, we override _update_along_axis
# to only delete and then call generate again to fill in any created gaps in the layers.
func _update_sectors(difference: Vector2) -> void:
	_update_along_axis(AXIS_X, difference.x)
	_update_along_axis(AXIS_Y, difference.y)
	generate()


## Seeds a triangle inside of the sector. The next layer can use these to make planets.
## Their overrall density and proximity to one another may or may not birth a planet.
func _generate_seeds_at(x: int, y: int) -> void:
	var key := Vector2(x,y)
	
	if _sectors.has(key) and _sectors[key].size() >= 1:
		return
	
	# Create a seed for the current sector's triangular seeds
	_rng.seed = make_seed_for(x, y, "seeds")
	
	# Find the boundaries of the sector +/- some padding
	var top_left := Vector2(
		x * sector_size - _half_sector_size + _sector_margin,
		y * sector_size - _half_sector_size + _sector_margin
	)
	
	var bottom_right := Vector2(
		x * sector_size + _half_sector_size - _sector_margin,
		y * sector_size + _half_sector_size - _sector_margin
	)
	
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
	
	if _sectors.has(key):
		_sectors[0] = seeds
	else:
		_sectors[key] = [seeds]


# Checks the sector's seeds. If they are close enough to each other (their area
# is small enough), a random planet is generated at their epicenter and is assigned
# a size inversely proportional to how small the seed triangle's area is.
func _generate_planets_at(x: int, y: int) -> void:
	var key := Vector2(x,y)
	
	if _sectors.has(key) and _sectors[key].size() >= 2:
		return
	
	# Calculate the area created by the 3 seeded points.
	var sector_data: Array = _sectors[key][0]
	var area: float = abs(
		sector_data[0].x * (sector_data[1].y - sector_data[2].y) +
		sector_data[1].x * (sector_data[2].y - sector_data[0].y) +
		sector_data[2].x * (sector_data[0].y - sector_data[1].y)
	) / 2.0
	
	# If the area is less than the generation threshold, create a planet appropriate
	# to the seeds' area.
	if area < planet_generation_area_threshold:
		_sectors[key].append(
			{
				"position":(sector_data[0] + sector_data[1] + sector_data[2]) / 3.0,
				"size": 1.0 - area/(planet_generation_area_threshold/5.0)
			}
		)
	else:
	# If not, place an empty dictionary. There can be nothing in this sector.
		_sectors[key].append({})


# If there is a planet inside of a given sector, a loop begins and there is a
# chance of a moon being generated. The die is rolled until it comes up negative.
func _generate_moons_at(x: int, y: int) -> void:
	var key := Vector2(x,y)
	
	if _sectors.has(key) and _sectors[key].size() >= 3:
		return
	
	# Get the sector's planet layer and check if there is a planet. If there is not,
	# cancel and move on.
	_sectors[key].append([])
	var sector_data: Dictionary = _sectors[key][1]
	if sector_data.size() == 0:
		return
	
	# Generate a seed for moons in the sector
	_rng.seed = make_seed_for(x, y, "moons")
	
	# Get the planet's position and size to determine moon orbit and location
	var planet_position: Vector2 = sector_data.position
	var planet_size: float = (1.0 + sector_data.size)
	
	var overflow_index := 0
	
	# If we roll below the moon chance, generate a moon in an orbit's distance of the planet
	while _rng.randf() < moon_generation_chance or overflow_index == max_moon_count:
		overflow_index += 1
		_sectors[key][2].append({
			"position": planet_position + Vector2.UP.rotated(_rng.randf_range(-PI, PI)) * planet_size * 96 * 3.0,
			"size": planet_size / 10.0 
		})


# If this sector has a planet, checks the 8 _sectors around it for neighbors.
# If there are planets in those _sectors, creates a lane between the two of them.
func _generate_travel_lanes_at(x: int, y: int) -> void:
	var key := Vector2(x,y)
	
	if _sectors.has(key) and _sectors[key].size() >= 4:
		return
	
	_sectors[key].append([])
	
	# If there is no planet, don't generate anything.
	var sector_data: Dictionary = _sectors[key][1]
	if sector_data.size() == 0:
		return
	
	var planet_position: Vector2 = sector_data.position
	
	# Check each neighbor for a planet. If there is one, create a dictionary that
	# links the two worlds together with a line to indicate a trading partner.
	for neighbor in NEIGHBORS:
		var neighbor_key: Vector2 = key + neighbor
		
		if _sectors[neighbor_key][1].size() > 0:
			var neighbor_position: Vector2 = _sectors[neighbor_key][1].position
			_sectors[key][3].append({
				"source": planet_position,
				"destination": neighbor_position
			})


# If this sector has a planet, does not have a moon and does not have any trade 
# lanes (because they'd have been cleared out by the traders/miners),
# then a loop begins and there is 75% chance to generate a random asteroid around it.
func _generate_asteroids_at(x: int, y: int) -> void:
	var key := Vector2(x,y)
	
	if _sectors.has(key) and _sectors[key].size() >= 5:
		return
	
	_sectors[key].append([])
	
	# Check for planet, moons and travel lanes. If there is a planet and neither
	# moon or travel lane, begin generating an asteroid belt in an orbit.
	var planet_data: Dictionary = _sectors[key][1]
	if planet_data.size() == 0:
		return
	
	var moon_data: Array = _sectors[key][2]
	if moon_data.size() > 0:
		return
	
	var travel_data: Array = _sectors[key][3]
	if travel_data.size() > 0:
		return
	
	_rng.seed = make_seed_for(x, y, "asteroids")
	
	var planet_position: Vector2 = planet_data.position
	var planet_size: float = (1.0 + planet_data.size)
	
	# Keep rolling the die until it comes up greater than 75%, creating a new
	# asteroid within an orbit's range of the planet
	while _rng.randf() < 0.75:
		_sectors[key][4].append(
			{"position": planet_position + Vector2.UP.rotated(_rng.randf_range(-PI, PI)) * planet_size * 96 * _rng.randf_range(3.0, 4.0),
			"size": planet_size / 10.0 
		})


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
	
	# Because 0 is technically negative when comparing signs, we end up with
	# 1 more sector when moving in the negative direction than the positive one.
	# So when difference is positive, we end up in situations where _sectors
	# aren't erased or added on time. This modifier is there to catch those
	# cases. It's 1 when positive, 0 otherwise, so we have an even count
	# on both positive and negative.
	var axis_modifier: int = difference <= 0

	# For each row/column between where we were and where we are now
	for sector_index in range(1, abs(difference) + 1):
		var axis_key := int(
			axis_current + (_half_sector_count - axis_modifier) * -sign(difference)
		)
		
		# Erase the entire row/column.
		for other in range(other_axis_min, other_axis_max):
			var key := Vector2(
				axis_key if axis == AXIS_X else other, other if axis == AXIS_X else axis_key
			)

			if _sectors.has(key):
				var sector_data: Array = _sectors[key]
				for array in sector_data:
					for data in array:
						if data is Object and data.has_method("queue_free"):
							data.queue_free()
				var _found := _sectors.erase(key)

	# Update the current sector for later reference
	if axis == AXIS_X:
		_current_sector.x += difference
	else:
		_current_sector.y += difference


func _set_show_debug(value: bool) -> void:
	show_debug = value
	if not is_inside_tree():
		yield(self, "ready")
	_grid_drawer.visible = show_debug
	update()
