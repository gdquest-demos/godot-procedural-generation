extends Node2D

export var chance_to_start_alive := 0.52

enum PlantState { GROWN, DIED = -1 }

const _neighbors_moore := [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN,
	Vector2(-1, -1),
	Vector2(-1, 1),
	Vector2(1, -1),
	Vector2(1, 1)
]

var _map := {}
var _grid_size := Vector2(20, 11)

onready var _tilemap := $FoliageTileMap


func _ready() -> void:
	_initialize_map()
	_paint_map()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	var click_position: Vector2 = get_global_mouse_position()
	var grid_position: Vector2 = _tilemap.world_to_map(click_position)

	if not _map.has(grid_position):
		return

	if event.button_index == BUTTON_LEFT:
		_map[grid_position] = (
			PlantState.DIED
			if not _map[grid_position] == PlantState.DIED
			else PlantState.GROWN
		)
		_paint_map()


func _initialize_map() -> void:
	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			_map[Vector2(x, y)] = (
				PlantState.GROWN
				if randf() < chance_to_start_alive
				else PlantState.DIED
			)


func _count_alive_neighbors(map: Dictionary, location: Vector2) -> int:
	var count = 0

	for neighbor in _neighbors_moore:
		var check_location = location + neighbor

		if (
			check_location.x < 0
			or check_location.x >= _grid_size.x
			or check_location.y < 0
			or check_location.y >= _grid_size.y
		):
			continue

		if _map[check_location] == PlantState.GROWN:
			count += 1

	return count


func update_grid() -> void:
	_map = _step()
	_paint_map()


func _step() -> Dictionary:
	var _new_map := {}

	for cell in _map:
		var alive_count = _count_alive_neighbors(_map, cell)
		if _map[cell] == PlantState.GROWN:
			if alive_count < 2 or alive_count > 3:
				_new_map[cell] = PlantState.DIED
			elif alive_count == 2 or alive_count == 3:
				_new_map[cell] = _map[cell]
		elif alive_count == 3:
			_new_map[cell] = PlantState.GROWN
		else:
			_new_map[cell] = _map[cell]

	return _new_map


func _paint_map() -> void:
	_tilemap.clear()

	for cell in _map:
		_tilemap.set_cellv(cell, _map[cell])
