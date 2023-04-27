extends Node2D

@export  var treasure_scene: PackedScene

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

var _wall_conversion := 4: set = set_wall_conversion
var _floor_conversion := 4: set = set_floor_conversion

var _step_count := 10: set = set_step_count
var _step_time := 0.1: set = set_step_time
var _wall_chance := 0.5: set = set_wall_chance
var _minimum_cavern_area := 50
var _minimum_distance_to_exit := 10
var _maximum_treasure := 10

var _map := {}

@onready var _tilemap: TileMap = $TileMapDungeon
@onready var _miner := $Miner
@onready var _exit := $Exit


func _ready() -> void:
	generate_new_dungeon()


func generate_new_dungeon() -> void:
	_map = _generate_random_map()

	for step in _step_count:
		if _step_time > 0:
			_paint_map()
			await get_tree().create_timer(_step_time).timeout

		_map = _advance_simulation()

	_remove_small_caverns()
	_paint_map()
	_position_start_and_exit()
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
		_tilemap.set_cell(0, cell, _map[cell],Vector2i.ZERO)
	var all_cells = _tilemap.get_used_cells_by_id(0,CellType.FLOOR)
	_tilemap.set_cells_terrain_connect(0, all_cells, 0, 0, false)

func _position_start_and_exit() -> void:
	var floor_cells = _tilemap.get_used_cells_by_id(0,CellType.FLOOR)
	if floor_cells.is_empty():
		return

	var miner_cell := Vector2.ZERO
	var exit_cell := Vector2.ZERO

	floor_cells.shuffle()

	while floor_cells:
		var cell = floor_cells.pop_back()

		if _count_floor_neighbors(cell) < 8:
			continue

		miner_cell = cell
		break

	while floor_cells:
		var cell : Vector2 = floor_cells.pop_back()

		if cell.distance_to(miner_cell) < _minimum_distance_to_exit:
			continue

		if _count_floor_neighbors(cell) < 8:
			continue

		exit_cell = cell
		break

	_miner.position = miner_cell * CELL_SIZE
	_exit.position = exit_cell * CELL_SIZE


func _add_treasure() -> void:

	for treasure in get_tree().get_nodes_in_group("treasure"):
		treasure.queue_free()

	var floor_cells = _tilemap.get_used_cells_by_id(0,CellType.FLOOR)
	var treasures_placed := 0

	var corner_subtiles := [Vector2i(0, 0), Vector2i(0, 2), Vector2i(2, 0), Vector2i(2, 2)]

	floor_cells.shuffle()

	while treasures_placed < _maximum_treasure and floor_cells:
		var cell = floor_cells.pop_back()

		var subtile = _tilemap.get_cell_atlas_coords(0,Vector2i(cell.x, cell.y))
		if not corner_subtiles.has(subtile):
			continue

		var treasure = treasure_scene.instantiate()
		var offset = (Vector2.ONE - Vector2(subtile)) * CELL_SIZE / 2
		treasure.position = Vector2(cell) * CELL_SIZE + offset
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
		var cell = _tilemap.local_to_map(pos)

		if _tilemap.get_cell_source_id(0,cell) == CellType.FLOOR:
			continue

		_tilemap.set_cell(0,cell, CellType.FLOOR,Vector2i.ZERO)
		var surrounding_cells := _tilemap.get_surrounding_cells(cell)
		var surrounding_floor_cells: Array[Vector2i] = []
		for surrounding_cell in surrounding_cells:
			if _tilemap.get_cell_source_id(0, surrounding_cell) == CellType.FLOOR:
				surrounding_floor_cells.push_back(surrounding_cell)
		_tilemap.set_cells_terrain_connect(0, surrounding_floor_cells, 0, 0, false)


# We use the setters below to update values when changing the sliders.
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
