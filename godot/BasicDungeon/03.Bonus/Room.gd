class_name BasicDungeonRoom


var position := Vector2.ZERO setget _no_op, get_position
var end := Vector2.ZERO setget _no_op, get_end
var center := Vector2.ZERO setget _no_op, get_center
var rect: Rect2

var _rect_area: float
var _iter_index: int


func _init(rect: Rect2) -> void:
	update(rect)


func _iter_init(_arg) -> bool:
	_iter_index = 0
	return _iter_is_running()


func _iter_next(_arg) -> bool:
	_iter_index += 1
	return _iter_is_running()


func _iter_get(_arg) -> Vector2:
	var offset := BasicDungeonUtils.index_to_xy(rect.size.x, _iter_index)
	return rect.position + offset


func update(rect: Rect2) -> void:
	self.rect = rect.abs()
	_rect_area = rect.get_area()


func intersects(room: BasicDungeonRoom) -> bool:
	return rect.intersects(room.rect)


func get_position() -> Vector2:
	return rect.position


func get_end() -> Vector2:
	return rect.end


func get_center() -> Vector2:
	return 0.5 * (rect.position + rect.end)


func _iter_is_running() -> bool:
	return _iter_index < _rect_area


func _no_op(val) -> void:
	pass
