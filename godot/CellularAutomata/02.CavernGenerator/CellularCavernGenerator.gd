## Generates a cavern using an algorithm based on celular automata.
extends Node2D

signal dungeon_generation_started
signal dungeon_generation_completed

enum CellType { WALL, FLOOR }

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

const MAP_SIZE := Vector2(80, 45)

var _wall_conversion := 4 setget set_wall_conversion
var _floor_conversion := 4 setget set_floor_conversion

var _step_count := 10 setget set_step_count
var _step_time := 0.1 setget set_step_time
var _wall_chance := 0.5 setget set_wall_chance

var _map := {}

onready var _tilemap := $TileMapDungeon


func _ready() -> void:
	generate_new_dungeon()


func generate_new_dungeon() -> void:
	emit_signal("dungeon_generation_started")

	_map = _generate_random_map()

	# We slow down the generation and draw it for visualization purposes.
	for step in _step_count:
		if _step_time > 0:
			_paint_map()
			yield(get_tree().create_timer(_step_time), "timeout")
		_map = _advance_simulation(_map)

	_paint_map()
	emit_signal("dungeon_generation_completed")


## Generates a dictionary representing a map with random walls and floors.
func _generate_random_map() -> Dictionary:
	var map := {}
	for x in range(MAP_SIZE.x):
		for y in range(MAP_SIZE.y):
			map[Vector2(x, y)] = CellType.WALL if randf() < _wall_chance else CellType.FLOOR
	return map


## Advances the cellular automata simulation by one step
func _advance_simulation(input_map: Dictionary) -> Dictionary:
	var map := {}
	for cell in input_map:
		var floor_neighbor_count = _count_floor_neighbors(cell)
		if input_map[cell] == CellType.FLOOR:
			if floor_neighbor_count < _wall_conversion:
				map[cell] = CellType.WALL
			else:
				map[cell] = input_map[cell]
		else:
			map[cell] = (
				CellType.FLOOR
				if floor_neighbor_count > _floor_conversion
				else CellType.WALL
			)
	return map


## Draws tiles on the tilemap.
func _paint_map() -> void:
	for cell in _map:
		_tilemap.set_cellv(cell, _map[cell])


## Returns the number of neighboring cells that are of type FLOOR.
func _count_floor_neighbors(location: Vector2) -> int:
	var count = 0
	for neighbor in CELL_NEIGHBORS:
		var check_location = location + neighbor
		if not _map.has(check_location):
			continue
		if _map[check_location] == CellType.FLOOR:
			count += 1
	return count


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
