class_name BasicDungeonGenerator


static func generate(level_size: Vector2, rooms_size: Vector2, rooms_max: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	
	var data := {}
	var rooms := []
	for r in range(rooms_max):
		var room := _get_random_room(level_size, rooms_size, rng)
		if _intersects(rooms, room):
			continue
	
		_add_room(data, rooms, room)
		if rooms.size() > 1:
			var room_previous: BasicDungeonRoom = rooms[-2]
			_add_connection(rng, data, room_previous, room)
	return data.keys()


static func _get_random_room(
	level_size: Vector2, rooms_size: Vector2, rng: RandomNumberGenerator
) -> BasicDungeonRoom:
	var width := rng.randi_range(rooms_size.x, rooms_size.y)
	var height := rng.randi_range(rooms_size.x, rooms_size.y)
	var x := rng.randi_range(0, level_size.x - width - 1)
	var y := rng.randi_range(0, level_size.y - height - 1)
	var rect := Rect2(x, y, width, height)
	return BasicDungeonRoom.new(rect) if rng.randi_range(0, 1) == 0 else BasicDungeonRoomOrganic.new(rect)


static func _add_room(data: Dictionary, rooms: Array, room: BasicDungeonRoom) -> void:
	rooms.push_back(room)
	for point in room:
		data[point] = null


static func _add_connection(
		rng: RandomNumberGenerator, data: Dictionary, room1: BasicDungeonRoom, room2: BasicDungeonRoom
) -> void:
	if rng.randi_range(0, 1) == 0:
		_add_corridor(data, room1.center.x, room2.center.x, room1.center.y, Vector2.AXIS_X)
		_add_corridor(data, room1.center.y, room2.center.y, room2.center.x, Vector2.AXIS_Y)
	else:
		_add_corridor(data, room1.center.y, room2.center.y, room1.center.x, Vector2.AXIS_Y)
		_add_corridor(data, room1.center.x, room2.center.x, room2.center.y, Vector2.AXIS_X)


static func _add_corridor(data: Dictionary, start: int, end: int, constant: int, axis: int) -> void:
	for t in range(min(start, end), max(start, end) + 1):
		var point := Vector2.ZERO
		match axis:
			Vector2.AXIS_X: point = Vector2(t, constant)
			Vector2.AXIS_Y: point = Vector2(constant, t)
		data[point] = null


static func _intersects(rooms: Array, room: BasicDungeonRoom) -> bool:
	var out := false
	for room_other in rooms:
		if room.intersects(room_other):
			out = true
			break
	return out
