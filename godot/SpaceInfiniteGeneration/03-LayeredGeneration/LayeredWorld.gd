extends BlueNoiseWorldGenerator


export var planet_formation_threshold := 10100.0
export var Planet: PackedScene


func generate() -> void:
	.generate()
	
	var left_bounds := current_sector.x - half_sector_count + 1
	var right_bounds := current_sector.x + half_sector_count - 2
	var top_bounds := current_sector.y - half_sector_count + 1
	var bottom_bounds := current_sector.y + half_sector_count - 2
	
	for x in range(left_bounds, right_bounds):
		for y in range(top_bounds, bottom_bounds):
			_planet_generate_at(x, y)


func _update_sector(difference: Vector2) -> void:
	._update_sector(difference)
	
	var left_bounds := current_sector.x - half_sector_count + 1
	var right_bounds := current_sector.x + half_sector_count - 2
	var top_bounds := current_sector.y - half_sector_count + 1
	var bottom_bounds := current_sector.y + half_sector_count - 2
	
	var sector_boundaries := [
		Vector2(left_bounds, top_bounds),
		Vector2(right_bounds, top_bounds),
		Vector2(right_bounds, bottom_bounds),
		Vector2(left_bounds, bottom_bounds)
	]
	
	for x in range(left_bounds+1, right_bounds-1):
		sector_boundaries.append(Vector2(x, top_bounds))
		sector_boundaries.append(Vector2(x, bottom_bounds))
	for y in range(top_bounds+1, bottom_bounds-1):
		sector_boundaries.append(Vector2(left_bounds, y))
		sector_boundaries.append(Vector2(right_bounds, y))
	
	for bound_sector in sector_boundaries:
		_planet_generate_at(bound_sector.x, bound_sector.y)


func _planet_generate_at(_x_id: int, _y_id: int) -> void:
	var current_key := Vector2(_x_id, _y_id)
	var sector_position := current_key * sector_size
	var max_distance := sqrt(sector_size_square)

	var asteroid_weight := 0.0

	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 and y == 0:
				continue

			var key := current_key + Vector2(x, y)
			var sector_data: Array = sectors[key]
			
			for asteroid in sector_data:
				if asteroid.is_in_group("asteroids"):
					var distance_weight: float = sector_position.distance_to(asteroid.global_position) * asteroid.scale.x
					asteroid_weight += distance_weight

	if asteroid_weight > planet_formation_threshold:
		rng.seed = make_seed_for(_x_id, _y_id, "planets")
		
		var planet := Planet.instance()
		add_child(planet)
		sectors[current_key].append(planet)
		planet.setup(rng)
		planet.global_position = sector_position + Vector2(rng.randf_range(-sector_size/4, sector_size/4), rng.randf_range(-sector_size/4, sector_size/4))
		planet.scale *= rng.randf_range(0.5, 1.5)
