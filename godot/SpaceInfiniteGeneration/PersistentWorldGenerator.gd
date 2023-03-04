# Generates an infinite world using a layered approach, and allows the user to
# remove and add planets, which changes subsequent layers accordingly.
# This is accomplished with a new modifications dictionary that holds special
# objects, in this case a planet removing/adding dictionary.
class_name PersistentWorldGenerator
extends LayeredWorldGenerator

enum Actions { ADD_PLANET, REMOVE_PLANET }

## A dictionary of forced planet or erased planets
var _modifications := {}


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	# Calculate the sector based on the mouse position in the world
	var click_position: Vector2 = get_global_mouse_position()
	var sector := _find_sector(click_position)
	if not _sectors.has(sector):
		return

	# If there is not already a planet in the sector, left mouse button adds it
	# to the mouse click position
	if event.button_index == MOUSE_BUTTON_LEFT and _sectors[sector].planet.is_empty():
		if not _modifications.has(sector):
			_modifications[sector] = {}

		_modifications[sector].action = Actions.ADD_PLANET
		_modifications[sector].position = click_position
		_reset_world()

	# If there is a planet in the sector and it corresponds to the location
	# clicked by the mouse, erase it from the world.
	elif event.button_index == MOUSE_BUTTON_RIGHT and not _sectors[sector].planet.is_empty():
		if not _modifications.has(sector):
			_modifications[sector] = {}

		_modifications[sector].action = Actions.REMOVE_PLANET
		_reset_world()


func _reset_world() -> void:
	_sectors = {}
	generate()


# Checks the sector's points. If they are close enough together, a random planet
# is generated. In addition, forces planets or removes generated planets based
# on player click. This is persistent so even after leaving and coming back,
# the new planet or removed planet should still be there/gone.
func _generate_planets_at(sector: Vector2) -> void:
	var seeds: Array = _sectors[sector].seeds
	var area: float = _calculate_triangle_area(seeds[0], seeds[1], seeds[2])

	var action: int = _modifications[sector].action if _modifications.has(sector) else -1

	if action == Actions.ADD_PLANET:
		_sectors[sector].planet = {position = _modifications[sector].position, scale = 1.0}
	elif action == Actions.REMOVE_PLANET:
		_sectors[sector].planet = {}
	elif area < planet_generation_area_threshold:
		_sectors[sector].planet = {
			position = _calculate_triangle_epicenter(seeds[0], seeds[1], seeds[2]),
			scale = 1.0 - area / (planet_generation_area_threshold / 5.0)
		}


## Returns the grid coordinates of the sector given a global position inside
## that sector.
func _find_sector(world_position: Vector2) -> Vector2:
	return Vector2(
		floor((world_position.x - _half_sector_size) / sector_size) + 1,
		floor((world_position.y - _half_sector_size) / sector_size) + 1
	)
