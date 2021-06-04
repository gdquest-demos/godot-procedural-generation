extends Node2D

export (PackedScene) var treasure_scene

enum CellType { WALL, FLOOR }

const MAP_SIZE := Vector2(80, 45)
const CELL_SIZE := 64
const CELL_NEIGHBORS := [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN,
	Vector2(-1, -1),
	Vector2(-1, 1),
	Vector2(1, -1),
	Vector2(1, 1)
]

var _wall_conversion := 4 setget set_wall_conversion
var _floor_conversion := 4 setget set_floor_conversion

var _step_count := 10 setget set_step_count
var _step_time := 0.1 setget set_step_time
var _wall_chance := 0.5 setget set_wall_chance
var _minimum_cavern_area := 50
var _minimum_distance_to_exit := 10
var _maximum_treasure := 10

var _map := {}

onready var _tilemap := $TileMapDungeon
onready var _player := $Player
onready var _exit := $Exit


func _ready() -> void:
	generate_new_dungeon()


func generate_new_dungeon() -> void:
	for treasure in get_tree().get_nodes_in_group("treasure"):
		treasure.queue_free()

	_map = _generate_random_map()

	for step in _step_count:
		if _step_time > 0:
			_paint_map()
			yield(get_tree().create_timer(_step_time), "timeout")

		_map = _advance_simulation()

	_remove_small_caverns()
	_paint_map()
	_add_start_and_exit()
	_add_treasure()


func _generate_random_map() -> Dictionary:
	var map := {}
	for x in range(MAP_SIZE.x):
		for y in range(MAP_SIZE.y):
			map[Vector2(x, y)] = CellType.WALL if randf() < _wall_chance else CellType.FLOOR
	return map


func _advance_simulation() -> Dictionary:
	var new_map := {}
	for cell in _map:
		var floor_neighbor_count = _count_floor_neighbors(cell)
		if _map[cell] == CellType.WALL:
			new_map[cell] = (
				CellType.FLOOR
				if floor_neighbor_count > _floor_conversion
				else CellType.WALL
			)
		else:
			new_map[cell] = (
				CellType.WALL
				if 8 - floor_neighbor_count > _wall_conversion
				else CellType.FLOOR
			)
	return new_map


func _remove_small_caverns():
	var caverns = _find_caverns()

	for cavern_index in caverns:
		if caverns[cavern_index].size() < _minimum_cavern_area:
			for cell in caverns[cavern_index]:
				_map[cell] = CellType.WALL


func _find_caverns() -> Dictionary:
	var caverns = {}
	var map_copy = _map.duplicate(true)

	# We assign a unique id to each cavern to differentiate them.
	# When we paint the tiles, any cell with a value >= 1 is set to a floor tile.
	var cavern_index := 2
	
	for cell in map_copy:
		if not map_copy[cell] == CellType.FLOOR:
			continue
		caverns[cavern_index] = _assign_cavern(cell, cavern_index, map_copy)
		cavern_index += 1

	return caverns


func _assign_cavern(cell: Vector2, index: int, map: Dictionary) -> Array:
	var check_cells = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

	var queue := []
	var cavern_cells := []
	queue.append(cell)

	while queue:
		var current = queue.pop_front()
		
		if not map.has(current):
			continue
		
		if not map[current] == CellType.FLOOR:
			continue
		
		map[current] = index
		cavern_cells.append(current)
		
		for direction in check_cells:
			var neighbor = current + direction
			queue.append(neighbor)

	return cavern_cells


func _paint_map() -> void:
	for cell in _map:
		var cell_type = CellType.WALL if _map[cell] == CellType.WALL else CellType.FLOOR
		_tilemap.set_cellv(cell, cell_type)
	_tilemap.update_bitmask_region()


func _add_start_and_exit() -> void:
	var floor_cells = _tilemap.get_used_cells_by_id(CellType.FLOOR)
	if not floor_cells:
		return

	floor_cells.shuffle()
	var player_cell := Vector2.ZERO

	for floor_cell in floor_cells:
		if _count_floor_neighbors(floor_cell) > 7:
			player_cell = floor_cell
			break

	_player.position = player_cell * CELL_SIZE

	var exit_cell := Vector2.ZERO
	for floor_cell in floor_cells:
		if floor_cell.distance_to(player_cell) >= _minimum_distance_to_exit:
			if _count_floor_neighbors(floor_cell) > 7:
				exit_cell = floor_cell
				break

	_exit.position = exit_cell * CELL_SIZE


func _add_treasure() -> void:
	var floor_cells = _tilemap.get_used_cells_by_id(CellType.FLOOR)
	var treasures_placed := 0

	var corner_subtiles := [Vector2(0, 0), Vector2(0, 2), Vector2(2, 0), Vector2(2, 2)]

	floor_cells.shuffle()

	while treasures_placed < _maximum_treasure and floor_cells:
		var cell = floor_cells.pop_back()

		var subtile = _tilemap.get_cell_autotile_coord(cell.x, cell.y)

		if corner_subtiles.has(subtile):
			var treasure = treasure_scene.instance()
			# Offset the treasure based on which corner subtile the treasure appears in. This is based on the subtiles' position in relation to each other in the tileset.
			treasure.position = cell * CELL_SIZE + (subtile - Vector2(1, 1)) * -CELL_SIZE / 2
			add_child(treasure)
			treasures_placed += 1


func _count_floor_neighbors(location: Vector2) -> int:
	var count = 0
	for neighbor in CELL_NEIGHBORS:
		var check_location = location + neighbor
		if not _map.has(check_location):
			continue

		if _map[check_location] == CellType.FLOOR:
			count += 1

	return count


func remove_walls(global_positions: Array) -> void:
	for pos in global_positions:
		var cell = _tilemap.world_to_map(pos)

		if _tilemap.get_cellv(cell) == CellType.FLOOR:
			continue

		_tilemap.set_cellv(cell, CellType.FLOOR)
		_tilemap.update_bitmask_area(cell)
		# Subtiles (0, 3) and (1, 3) correspond to different versions of the floor tile.
		# We have this line to prevent them from appearing while digging.
		for n in CELL_NEIGHBORS:
			var variants := [Vector2(0, 3), Vector2(1, 3)]
			var subtile = _tilemap.get_cell_autotile_coord(cell.x + n.x, cell.y + n.y)

			if variants.has(subtile):
				_tilemap.set_cell(
					cell.x + n.x, cell.y + n.y, CellType.FLOOR, false, false, false, Vector2(1, 1)
				)


## We use the setters below to update values when changing the sliders.
func set_wall_chance(value: float) -> void:
	_wall_chance = value


func set_step_time(value: float) -> void:
	_step_time = value


func set_wall_conversion(value: int) -> void:
	_wall_conversion = value


func set_floor_conversion(value: int) -> void:
	_floor_conversion = value


func set_step_count(value: int) -> void:
	_step_count = value


func set_maximum_treasure(value: int) -> void:
	_maximum_treasure = value


func set_minimum_cavern_area(value) -> void:
	_minimum_cavern_area = value


func set_minimum_exit_distance(value) -> void:
	_minimum_distance_to_exit = value
