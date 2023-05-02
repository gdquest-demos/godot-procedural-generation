extends Node2D

enum PlantState { DEAD, ALIVE }

const NEIGHBORS := [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN,
	Vector2(-1, -1),
	Vector2(-1, 1),
	Vector2(1, -1),
	Vector2(1, 1)
]

@export var chance_to_start_alive := 0.52

var _map := {}
var _grid_size := Vector2(20, 11)

@onready var _tilemap: TileMap = $FoliageTileMap


func _ready() -> void:
	randomize()
	_initialize_map()
	_paint_map()


func _initialize_map() -> void:
	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			_map[Vector2(x, y)] = (
				PlantState.ALIVE
				if randf() < chance_to_start_alive
				else PlantState.DEAD
			)


func _count_alive_neighbors(location: Vector2) -> int:
	var count = 0

	for neighbor in NEIGHBORS:
		var neighbor_cell = location + neighbor
		var is_neighbor_outside_grid: bool = (
			neighbor_cell.x < 0
			or neighbor_cell.y < 0
			or neighbor_cell.x >= _grid_size.x
			or neighbor_cell.y >= _grid_size.y
		)

		if is_neighbor_outside_grid:
			continue

		if _map[neighbor_cell] == PlantState.ALIVE:
			count += 1

	return count


func update_grid() -> void:
	_map = _advance_simulation(_map)
	_paint_map()


func _advance_simulation(input_map: Dictionary) -> Dictionary:
	var new_map := {}

	for cell in input_map:
		var alive_count = _count_alive_neighbors(cell)

		if input_map[cell] == PlantState.ALIVE and alive_count > 2:
			new_map[cell] = PlantState.DEAD
		elif input_map[cell] == PlantState.DEAD and alive_count == 2:
			new_map[cell] = PlantState.ALIVE
		else:
			new_map[cell] = input_map[cell]

	return new_map


func _paint_map() -> void:
	for cell in _map:
		
		var flower_frame = PlantState.DEAD
		
		if _map[cell] == PlantState.ALIVE:
			flower_frame = 1 + randi() % 4
		
		_tilemap.set_cell(0,cell, flower_frame, Vector2i.ZERO)
