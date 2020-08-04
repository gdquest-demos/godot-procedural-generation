extends Node2D


signal rooms_placed
signal finished

const Room := preload("Room.tscn")

const MEAN_ROOM_SIZE_WEIGHT := 1.1
const CULL_FACTOR := 0.55
const MAX_ROOMS := 60

var _rng := RandomNumberGenerator.new()
var _data := {}
var _path := AStar2D.new()
var _sleeping_rooms := 0
var _mean_room_size := Vector2.ZERO

onready var rooms: Node2D = $Rooms
onready var level: TileMap = $Level


func _ready() -> void:
	connect("rooms_placed", self, "_on_rooms_placed")
	_rng.randomize()
	_generate()


func _on_rooms_placed() -> void:
	var main_rooms := []
	var main_rooms_positions := []
	for room in rooms.get_children():
		if _is_main_room(room):
			main_rooms.push_back(room)
			main_rooms_positions.push_back(room.position)
	
	var delaunay := Geometry.triangulate_delaunay_2d(main_rooms_positions)
	var main_rooms_connections := MSTDungeonUtils.delaunay_to_connections(delaunay)
	_path = MSTDungeonUtils.mst(main_rooms_positions, main_rooms_connections)
	MSTDungeonUtils.cull_points_by(_rng, main_rooms_connections, CULL_FACTOR)

	for point1_id in main_rooms_connections:
		for point2_id in main_rooms_connections[point1_id]:
			if not _path.are_points_connected(point1_id, point2_id):
				_path.connect_points(point1_id, point2_id)
	
	for room in main_rooms:
		_add_room(room)
	_add_corridors()


func _on_Room_mode_changed(room: MSTDungeonRoom) -> void:
	_sleeping_rooms += 1
	if _sleeping_rooms == MAX_ROOMS:
		emit_signal("rooms_placed")


func _generate() -> void:
	for _i in MAX_ROOMS:
		var room := Room.instance()
		room.connect("mode_changed", self, "_on_Room_mode_changed", [room])
		room.setup(level)
		rooms.add_child(room)
		
		_mean_room_size += room.size
	_mean_room_size /= rooms.get_child_count()
	
	yield(self, "finished")
	
	rooms.queue_free()
	for point in _data:
		level.set_cellv(point, 0)
	return _data


func _add_room(room: MSTDungeonRoom) -> void:
	var room_extents := level.world_to_map(room.size / 2)
	for x in range(-room_extents.x, room_extents.x):
		for y in range(-room_extents.y, room_extents.y):
			var offset := level.world_to_map(room.position) + Vector2(x, y)
			_data[offset] = null


func _add_corridors():
	var connected := {}
	for point1_id in _path.get_points():
		for point2_id in _path.get_point_connections(point1_id):
			var point1 := _path.get_point_position(point1_id)
			var point2 := _path.get_point_position(point2_id)
			if Vector2(point1_id, point2_id) in connected:
				continue
			
			point1 = level.world_to_map(point1)
			point2 = level.world_to_map(point2)
			_add_corridor(point1.x, point2.x, point1.y, Vector2.AXIS_X)
			_add_corridor(point1.y, point2.y, point2.x, Vector2.AXIS_Y)
			
			connected[Vector2(point1_id, point2_id)] = null
			connected[Vector2(point2_id, point1_id)] = null
	emit_signal("finished")


func _add_corridor(start: int, end: int, constant: int, axis: int) -> void:
	var t := min(start, end)
	while t <= max(start, end):
		var point := Vector2.ZERO
		match axis:
			Vector2.AXIS_X: point = Vector2(t, constant)
			Vector2.AXIS_Y: point = Vector2(constant, t)

		t += 1
		for room in rooms.get_children():
			if _is_main_room(room):
				continue
			
			var top_left: Vector2 = level.world_to_map(room.position - room.size / 2)
			var bottom_right: Vector2 = level.world_to_map(room.position + room.size / 2)
			if (
				top_left.x <= point.x and point.x < bottom_right.x
				and top_left.y <= point.y and point.y < bottom_right.y
			):
				_add_room(room)
				t = bottom_right[axis]
		_data[point] = null


func _is_main_room(room: MSTDungeonRoom) -> bool:
	return (
		room.size.x > MEAN_ROOM_SIZE_WEIGHT * _mean_room_size.x
		and room.size.y > MEAN_ROOM_SIZE_WEIGHT * _mean_room_size.y
	)
