# Generates an infinite world using a layered approach, allowing each layer to
# access the previous layers' data. Each layer is smaller than the next, so they
# can also access their neighbors' data.
extends WorldGenerator


# Hides or shows the grid and the planetary seeding points
export var show_debug := false setget _set_show_debug

# Percentage to keep the planetary seeding points away from the sector edges
export var sector_margin_proportion := 0.1

# The maximum area made by the 3 seeding points for a planet to form.
# Higher == more planets
export var planet_generation_threshold := 5000.0

onready var player := $Player
onready var grid_drawer := $GridDrawer

# The pixel value of the margin calculated from the margin percentage
onready var sector_margin := sector_size * sector_margin_proportion


func _ready() -> void:
	generate()
	grid_drawer.setup(sector_size, sector_count)
	grid_drawer.visible = show_debug


# Generates the world with a layered approach
func generate() -> void:
	for layer in range(0, 5):
		for x in range(current_sector.x - half_sector_count + layer, current_sector.x + half_sector_count - layer):
			for y in range(current_sector.y - half_sector_count + layer, current_sector.y + half_sector_count - layer):
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


# Draws the generated data
func _draw() -> void:
	for key in sectors.keys():
		if show_debug and sectors[key].size() > 0:
			for point in sectors[key][0]:
				draw_circle(point, 12, Color(0.5, 0.5, 0.5))
		if sectors[key].size() > 1 and sectors[key][1].size() > 0:
			draw_circle(sectors[key][1].position, 96 * (1.0 + sectors[key][1].size), Color.bisque)
		if sectors[key].size() > 2:
			for moon in sectors[key][2]:
				draw_circle(moon.position, 32 * (1.0 + moon.size), Color.aquamarine)
		if sectors[key].size() > 3:
			for path in sectors[key][3]:
				var start: Vector2 = path.source
				var end: Vector2 = path.destination
				draw_line(start, end, Color.cornflower, 4.0)
		if sectors[key].size() > 4:
			for asteroid in sectors[key][4]:
				draw_circle(asteroid.position, 16 * (1.0 + asteroid.size), Color.orangered)


# Whenever the player changes sector, erase those that fall out of scope and generate new ones
func _physics_process(_delta: float) -> void:
	var sector_offset := Vector2.ZERO

	var sector_location := current_sector * sector_size

	if player.global_position.distance_squared_to(sector_location) > sector_size_square:
		sector_offset = (player.global_position - sector_location) / sector_size
		sector_offset.x = int(sector_offset.x)
		sector_offset.y = int(sector_offset.y)

		_update_sector(sector_offset)
		grid_drawer.move_grid_to(current_sector)


# Erases old sectors by difference, and generates new ones
func _update_sector(difference: Vector2) -> void:
	_update_along_axis(AXIS_X, difference.x)
	_update_along_axis(AXIS_Y, difference.y)
	generate()


# Seeds a triangle inside of the sector. The next layer can use these to make planets.
func _generate_seeds_at(x: int, y: int) -> void:
	var key := Vector2(x,y)
	
	if sectors.has(key) and sectors[key].size() >= 1:
		return
	
	rng.seed = make_seed_for(x, y, "seeds")
	
	var top_left := Vector2(
		x * sector_size - half_sector_size + sector_margin,
		y * sector_size - half_sector_size + sector_margin
	)
	
	var bottom_right := Vector2(
		top_left.x + sector_size - sector_margin * 2,
		top_left.y + sector_size - sector_margin * 2
	)
	
	var seeds := []
	for _i in range(3):
		var seed_position := Vector2(
			rng.randf_range(top_left.x, bottom_right.x),
			rng.randf_range(top_left.y, bottom_right.y)
		)
		
		seeds.append(seed_position)
	
	if sectors.has(key):
		sectors[0] = seeds
	else:
		sectors[key] = [seeds]


# Checks the sector's points. If they are close enough together, a random planet
# is generated.
func _generate_planets_at(x: int, y: int) -> void:
	var key := Vector2(x,y)
	
	if sectors.has(key) and sectors[key].size() >= 2:
		return
	
	var sector_data: Array = sectors[key][0]
	var area: float = abs(
		sector_data[0].x * (sector_data[1].y - sector_data[2].y) +
		sector_data[1].x * (sector_data[2].y - sector_data[0].y) +
		sector_data[2].x * (sector_data[0].y - sector_data[1].y)
	) / 2.0
	
	if area < planet_generation_threshold:
		sectors[key].append(
			{
				"position":(sector_data[0] + sector_data[1] + sector_data[2]) / 3.0,
				"size": 1.0 - area/(planet_generation_threshold/5.0)
			}
		)
	else:
		sectors[key].append({})


# If there is a planet inside of a given sector, a loop begins and there is a 33%
# chance of a moon being generated.
func _generate_moons_at(x: int, y: int) -> void:
	var key := Vector2(x,y)
	
	if sectors.has(key) and sectors[key].size() >= 3:
		return
	
	sectors[key].append([])
	var sector_data: Dictionary = sectors[key][1]
	if sector_data.size() == 0:
		return
	
	rng.seed = make_seed_for(x, y, "moons")
	
	var planet_position: Vector2 = sector_data.position
	var planet_size: float = (1.0 + sector_data.size)
	
	while rng.randf() < 0.334:
		sectors[key][2].append({"position": planet_position + Vector2.UP.rotated(rng.randf_range(-PI, PI)) * planet_size * 96 * 3.0, "size": planet_size / 10.0 })


# If this sector has a planet, checks the 8 sectors around it for neighbors.
# If there are planets in those sectors, creates a lane between the two of them.
func _generate_travel_lanes_at(x: int, y: int) -> void:
	var key := Vector2(x,y)
	
	if sectors.has(key) and sectors[key].size() >= 4:
		return
	
	sectors[key].append([])
	
	var sector_data: Dictionary = sectors[key][1]
	if sector_data.size() == 0:
		return
		
	var planet_position: Vector2 = sector_data.position
	
	var neighbors := [Vector2(1, 0), Vector2(1,1), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, 1), Vector2(0, -1), Vector2(1, -1)]
	
	for neighbor in neighbors:
		var neighbor_key: Vector2 = key + neighbor
		
		if sectors[neighbor_key][1].size() > 0:
			var neighbor_position: Vector2 = sectors[neighbor_key][1].position
			sectors[key][3].append({
				"source": planet_position,
				"destination": neighbor_position
			})


# If this sector has a planet, does not have a moon and does not have any trade 
# lanes (because they'd have been cleared out by the traders/miners),
# then a loop begins and there is 75% chance to generate a random asteroid around it.
func _generate_asteroids_at(x: int, y: int) -> void:
	var key := Vector2(x,y)
	
	if sectors.has(key) and sectors[key].size() >= 5:
		return
	
	sectors[key].append([])
	
	var planet_data: Dictionary = sectors[key][1]
	if planet_data.size() == 0:
		return
	
	var moon_data: Array = sectors[key][2]
	if moon_data.size() > 0:
		return
	
	var travel_data: Array = sectors[key][3]
	if travel_data.size() > 0:
		return
	
	rng.seed = make_seed_for(x, y, "asteroids")
	
	var planet_position: Vector2 = planet_data.position
	var planet_size: float = (1.0 + planet_data.size)
	
	while rng.randf() < 0.75:
		sectors[key][4].append({"position": planet_position + Vector2.UP.rotated(rng.randf_range(-PI, PI)) * planet_size * 96 * rng.randf_range(3.0, 4.0), "size": planet_size / 10.0 })


# Erases old sectors. New ones are generated by the subsequent call to generate()
func _update_along_axis(axis: int, difference: float) -> void:
	if difference == 0 or (axis != AXIS_X and axis != AXIS_Y):
		return

	# Find the current sector's row/column
	var axis_current := current_sector.x if axis == AXIS_X else current_sector.y
	
	# Find the edges of the row/column, perpendicular to the axis we're updating
	var other_axis_min := (
		(current_sector.y if axis == AXIS_X else current_sector.x)
		- half_sector_count
	)
	var other_axis_max := (
		(current_sector.y if axis == AXIS_X else current_sector.x)
		+ half_sector_count
	)
	
	# Because 0 is technically negative when comparing signs, we end up with
	# 1 more sector when moving in the negative direction than the positive one.
	# So when difference is positive, we end up in situations where sectors
	# aren't erased or added on time. This modifier is there to catch those
	# cases. It's 1 when positive, 0 otherwise, so we have an even count
	# on both positive and negative.
	var axis_modifier: int = difference <= 0

	# For each row/column between where we were and where we are now
	for sector_index in range(1, abs(difference) + 1):
		var axis_key := int(
			axis_current + (half_sector_count - axis_modifier) * -sign(difference)
		)
		
		# Erase the entire row/column.
		for other in range(other_axis_min, other_axis_max):
			var key := Vector2(
				axis_key if axis == AXIS_X else other, other if axis == AXIS_X else axis_key
			)

			if sectors.has(key):
				var sector_data: Array = sectors[key]
				for array in sector_data:
					for data in array:
						if data is Object and data.has_method("queue_free"):
							data.queue_free()
				var _found := sectors.erase(key)

	# Update the current sector for later reference
	if axis == AXIS_X:
		current_sector.x += difference
	else:
		current_sector.y += difference


func _set_show_debug(value: bool) -> void:
	show_debug = value
	grid_drawer.visible = show_debug
	update()
