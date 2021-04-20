extends Node2D

signal dungeon_generation_started
signal dungeon_generation_completed

export var _map_size := Vector2(80, 45)
export (PackedScene) var treasure_scene


enum CellType {  WALL, FLOOR }

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


func _ready() -> void:
	#randomize()
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
	
	_paint_map()
	
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
			_new_map[cell] = CellType.FLOOR if floor_neighbor_count > _floor_conversion else CellType.WALL
	
	return _new_map


func _paint_map() -> void:
	for cell in _map:
		var cell_type = CellType.WALL if _map[cell] == CellType.WALL else CellType.FLOOR
	
		_tilemap.set_cellv(cell, cell_type)
	
	_tilemap.update_bitmask_region()


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
