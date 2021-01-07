# Generates an infinite world using a layered approach, and allows the user to
# remove and add planets, which changes subsequent layers accordingly.
# This is accomplished with a new modifications dictionary that holds special
# objects, in this case a planet removing/adding dictionary.
extends LayeredWorld


## A dictionary of forced planet or erased planets
var modifications := {}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# Calculate the sector based on the mouse position in the world
		var click_position: Vector2 = get_global_mouse_position()
		
		var sector_key := Vector2(
			int((click_position.x - _half_sector_size) / sector_size),
			int((click_position.y - _half_sector_size) / sector_size)
		)

		# If there is not already a planet in the sector, left mouse button adds it
		# to the mouse click position
		if event.button_index == BUTTON_LEFT:
			if not _sectors.has(sector_key):
				return
			
			if not _sectors[sector_key].size() > 2:
				return
			
			if not _sectors[sector_key][1].size() == 0:
				return
			
			if not modifications.has(sector_key):
				modifications[sector_key] = {}
				
			modifications[sector_key].force_planet = true
			modifications[sector_key].position = click_position
			modifications[sector_key].remove_generated_planet = false
			
			_sectors = {}
			generate()

		# If there is a planet in the sector and it corresponds to the location
		# clicked by the mouse, erase it from the world.
		elif event.button_index == BUTTON_RIGHT:
			if not _sectors.has(sector_key):
				return
			
			if not _sectors[sector_key].size() > 2:
				return
			
			if not _sectors[sector_key][1].size() > 0:
				return
			
			var planet_position: Vector2 = _sectors[sector_key][1].position
			var planet_size: float = abs(_sectors[sector_key][1].size)
			
			if click_position.distance_to(planet_position) < (96 * (1.0 + planet_size)):
				if not modifications.has(sector_key):
					modifications[sector_key] = {}
				
				modifications[sector_key].remove_generated_planet = true
				modifications[sector_key].force_planet = false
				
			
			_sectors = {}
			generate()


# Checks the sector's points. If they are close enough together, a random planet
# is generated. In addition, forces planets or removes generated planets based
# on player click. This is persistent so even after leaving and coming back,
# the new planet or removed planet should still be there/gone.
func _generate_planets_at(x: int, y: int) -> void:
	var key := Vector2(x,y)

	if _sectors.has(key) and _sectors[key].size() >= 2:
		return

	var sector_data: Array = _sectors[key][0]
	var area: float = abs(
		sector_data[0].x * (sector_data[1].y - sector_data[2].y) +
		sector_data[1].x * (sector_data[2].y - sector_data[0].y) +
		sector_data[2].x * (sector_data[0].y - sector_data[1].y)
	) / 2.0

	var should_remove_planet: bool = (
		modifications.has(key)
		and modifications[key].has("remove_generated_planet")
		and modifications[key].remove_generated_planet
	)

	var should_force_planet: bool = (
		modifications.has(key)
		and modifications[key].has("force_planet")
		and modifications[key].force_planet
	)

	if not should_remove_planet and should_force_planet:
		_sectors[key].append(
			{
				"position":modifications[key].position,
				"size": 1.0
			}
		)
	elif not should_remove_planet and area < planet_generation_threshold:
		_sectors[key].append(
			{
				"position":(sector_data[0] + sector_data[1] + sector_data[2]) / 3.0,
				"size": 1.0 - area/(planet_generation_threshold/5.0)
			}
		)
	else:
		_sectors[key].append({})
