class_name MSTDungeonRoom
extends RigidBody2D


const CONSECUTIVE_MAX_EQUALITIES := 10

export var radius := 600
export var room_size := Vector2(2, 9)

var size := Vector2.ZERO

var _level: TileMap = null
var _rng: RandomNumberGenerator = null
var _previous_xform := Transform2D()
var _consecutive_equalities := 0

var _area: float = 0.0
var _iter_index: int = 0

onready var collision_shape: CollisionShape2D = $CollisionShape2D


func setup(rng: RandomNumberGenerator, level: TileMap) -> void:
	_rng = rng
	_level = level


func _ready() -> void:
	position = MSTDungeonUtils.get_rng_point_in_circle(_rng, radius)

	var w: int = _rng.randi_range(room_size.x, room_size.y)
	var h: int = _rng.randi_range(room_size.x, room_size.y)
	_area = 4 * w * h

	collision_shape.shape.extents = _level.map_to_world(Vector2(w, h))
	size = 2 * collision_shape.shape.extents


func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	if mode == RigidBody2D.MODE_STATIC:
		return

	if MSTDungeonUtils.is_approx_equal(_previous_xform.origin, state.transform.origin):
		_consecutive_equalities += 1

	if _consecutive_equalities > CONSECUTIVE_MAX_EQUALITIES:
		set_deferred("mode", RigidBody2D.MODE_STATIC)
		call_deferred("emit_signal", "sleeping_state_changed")
	_previous_xform = state.transform


func _iter_init(_arg) -> bool:
	_iter_index = 0
	return _iter_is_running()


func _iter_next(_arg) -> bool:
	_iter_index += 1
	return _iter_is_running()


func _iter_get(_arg) -> Vector2:
	var width := _level.world_to_map(size).x
	var offset := MSTDungeonUtils.index_to_xy(width, _iter_index)
	return _level.world_to_map(position - size / 2) + offset


func _iter_is_running() -> bool:
	return _iter_index < _area
