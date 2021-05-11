extends Node2D

signal dungeon_generation_started
signal dungeon_generation_completed

export var _map_size := Vector2(80, 45)
export (PackedScene) var treasure_scene

enum CellType { WALL, FLOOR }

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
	emit_signal("dungeon_generation_started")

	for treasure in get_tree().get_nodes_in_group("treasure"):
		treasure.queue_free()

	_initialize_map()

	for step in _step_count:
		if _step_time > 0:
			_paint_map()
			yield(get_tree().create_timer(_step_time), "timeout")

		_map = _step()

	_remove_small_caverns()
	_paint_map()
	_add_start_and_exit()
	_add_treasure()
	emit_signal("dungeon_generation_completed")


func _initialize_map() -> void:
	for x in range(_map_size.x):
		for y in range(_map_size.y):
			_map[Vector2(x, y)] = CellType.WALL if randf() < _wall_chance else CellType.FLOOR


func _step() -> Dictionary:
	var _new_map := {}

	for cell in _map:
		var floor_neighbor_count = _count_floor_neighbors(cell)
		if _map[cell] == CellType.FLOOR:
			if floor_neighbor_count < _wall_conversion:
				_new_map[cell] = CellType.WALL
			else:
				_new_map[cell] = _map[cell]
		else:
			_new_map[cell] = (
				CellType.FLOOR
				if floor_neighbor_count > _floor_conversion
				else CellType.WALL
			)

	return _new_map


func _remove_small_caverns():
	var caverns = _find_caverns()

	for cavern in caverns:
		if caverns[cavern].size() < _minimum_cavern_area:
			for cell in caverns[cavern]:
				_map[cell] = CellType.WALL


func _find_caverns() -> Dictionary:
	var caverns = {}
	var map_copy = _map.duplicate(true)

	# We assign a unique id to each cavern to differentiate them.
	# When we paint the tiles, any cell with a value >= 1 is set to a floor tile.
	var cavern_index := 2

	for cell in _map:
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

		map[current] = index
		cavern_cells.append(current)
		for direction in check_cells:
			var neighbor = current + direction
			if map.has(neighbor):
				if queue.has(neighbor):
					continue

				if map[neighbor] == CellType.FLOOR:
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
	var player_cell = floor_cells.pop_back()
	_player.position = player_cell * CELL_SIZE

	var exit_cell := Vector2.ZERO
	while floor_cells:
		var check_cell = floor_cells.pop_back()
		if check_cell.distance_to(player_cell) >= _minimum_distance_to_exit:
			exit_cell = check_cell
			break

	_exit.position = exit_cell * CELL_SIZE


func _add_treasure() -> void:
	var floor_cells = _tilemap.get_used_cells_by_id(CellType.FLOOR)
	var treasures_placed := 0

	floor_cells.shuffle()

	while treasures_placed < _maximum_treasure and floor_cells:
		var cell = floor_cells.pop_back()

		if _count_floor_neighbors(cell) < 5:
			treasures_placed += 1
			var treasure = treasure_scene.instance()
			treasure.position = cell * CELL_SIZE
			add_child(treasure)


func _count_floor_neighbors(location: Vector2) -> int:
	var count = 0
	for neighbor in CELL_NEIGHBORS:
		var check_location = location + neighbor
		if not _map.has(check_location):
			continue

		if _map[check_location] == CellType.FLOOR:
			count += 1

	return count


func remove_wall(position_global: Vector2) -> void:
	var cell = _tilemap.world_to_map(position_global)

	if _tilemap.get_cellv(cell) == CellType.FLOOR:
		return

	_tilemap.set_cellv(cell, CellType.FLOOR)
	_tilemap.update_bitmask_area(cell)

	# Subtile (7, 5) corresponds to the different version of the floor tile.
	# We have this line to prevent it from appearing when digging.
	for n in CELL_NEIGHBORS:
		if _tilemap.get_cell_autotile_coord(cell.x + n.x, cell.y + n.y) == Vector2(7, 5):
			_tilemap.set_cell(
				cell.x + n.x, cell.y + n.y, CellType.FLOOR, false, false, false, Vector2(7, 4)
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
