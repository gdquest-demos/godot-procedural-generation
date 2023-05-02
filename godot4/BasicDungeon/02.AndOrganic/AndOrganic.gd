extends Node2D


const FACTOR := 1.0 / 8.0

@export var level_size := Vector2(100, 80)
@export var rooms_size := Vector2(10, 14)
@export var rooms_max := 15

@onready var level: TileMap = $Level
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_setup_camera()
	_generate()


func _setup_camera() -> void:
	camera.position = level.map_to_local(level_size / 2)
	var z := 8 / maxf(level_size.x, level_size.y)
	camera.zoom = Vector2(z, z)


func _generate() -> void:
	level.clear()
	for vector in _generate_data():
		level.set_cell(0, vector, 0, Vector2i.ZERO, 0)


func _generate_data() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var data := {}
	var rooms := []
	for r in range(rooms_max):
		var room := _get_random_room(rng)
		if _intersects(rooms, room):
			continue

		_add_room(rng, data, rooms, room)
		if rooms.size() > 1:
			var room_previous: Rect2 = rooms[-2]
			_add_connection(rng, data, room_previous, room)
	return data.keys()


func _get_random_room(rng: RandomNumberGenerator) -> Rect2:
	var width := rng.randi_range(rooms_size.x, rooms_size.y)
	var height := rng.randi_range(rooms_size.x, rooms_size.y)
	var x := rng.randi_range(0, level_size.x - width - 1)
	var y := rng.randi_range(0, level_size.y - height - 1)
	return Rect2(x, y, width, height)


func _add_room(rng: RandomNumberGenerator, data: Dictionary, rooms: Array, room: Rect2) -> void:
	rooms.push_back(room)
	if rng.randi_range(0, 1) == 0:
		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				data[Vector2(x, y)] = null
	else:
		var unit := FACTOR * room.size
		var order := [
			room.grow_individual(-unit.x, 0, -unit.x, unit.y - room.size.y),
			room.grow_individual(unit.x - room.size.x, -unit.y, 0, -unit.y),
			room.grow_individual(-unit.x, unit.y - room.size.y, -unit.x, 0),
			room.grow_individual(0, -unit.y, unit.x - room.size.x, -unit.y)
		]
		var poly := []
		for index in range(order.size()):
			var rect: Rect2 = order[index]
			var is_even := index % 2 == 0
			var poly_partial := []
			for r in range(rng.randi_range(1, 2)):
				poly_partial.push_back(Vector2(
					rng.randf_range(rect.position.x, rect.end.x),
					rng.randf_range(rect.position.y, rect.end.y)
				))
			poly_partial.sort_custom(_lessv_x if is_even else _lessv_y)
			if index > 1:
				poly_partial.reverse()
			poly += poly_partial

		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				var point := Vector2(x, y)
				if Geometry2D.is_point_in_polygon(point, poly):
					data[point] = null


func _add_connection(
	rng: RandomNumberGenerator, data: Dictionary, room1: Rect2, room2: Rect2
) -> void:
	var room_center1 := (room1.position + room1.end) / 2
	var room_center2 := (room2.position + room2.end) / 2
	if rng.randi_range(0, 1) == 0:
		_add_corridor(data, room_center1.x, room_center2.x, room_center1.y, Vector2.AXIS_X)
		_add_corridor(data, room_center1.y, room_center2.y, room_center2.x, Vector2.AXIS_Y)
	else:
		_add_corridor(data, room_center1.y, room_center2.y, room_center1.x, Vector2.AXIS_Y)
		_add_corridor(data, room_center1.x, room_center2.x, room_center2.y, Vector2.AXIS_X)


func _add_corridor(data: Dictionary, start: int, end: int, constant: int, axis: int) -> void:
	for t in range(min(start, end), max(start, end) + 1):
		var point := Vector2.ZERO
		match axis:
			Vector2.AXIS_X: point = Vector2(t, constant)
			Vector2.AXIS_Y: point = Vector2(constant, t)
		data[point] = null


func _intersects(rooms: Array, room: Rect2) -> bool:
	var out := false
	for room_other in rooms:
		if room.intersects(room_other):
			out = true
			break
	return out


func _lessv_x(v1: Vector2, v2: Vector2) -> bool:
	return v1.x < v2.x


func _lessv_y(v1: Vector2, v2: Vector2) -> bool:
	return v1.y < v2.y
