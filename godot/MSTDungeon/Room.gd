class_name MSTDungeonRoom
extends RigidBody2D


signal mode_changed

const UNCERTAINTY := 1e-2
const CONSECUTIVE_MAX_EQUALITIES := 10

const RADIUS := 600
const ROOM_SIZE := Vector2(2, 9)

var size := Vector2.ZERO

var _level: TileMap = null
var _rng := RandomNumberGenerator.new()
var _previous_xform := Transform2D()
var _consecutive_equalities := 0

onready var collision_shape: CollisionShape2D = $CollisionShape2D


func setup(level: TileMap) -> void:
	_level = level


func _ready() -> void:
	_rng.randomize()
	
	position = MSTDungeonUtils.get_rng_point_in_circle(_rng, RADIUS)
	position.x = MSTDungeonUtils.roundm(position.x, _level.cell_size.x)
	position.y = MSTDungeonUtils.roundm(position.y, _level.cell_size.y)
	
	var w: int = _rng.randi_range(ROOM_SIZE.x, ROOM_SIZE.y)
	var h: int = _rng.randi_range(ROOM_SIZE.x, ROOM_SIZE.y)
	
	var shape := RectangleShape2D.new()
	shape.extents = _level.map_to_world(Vector2(w, h))
	collision_shape.shape = shape
	size = 2 * shape.extents


func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	if mode == RigidBody2D.MODE_STATIC: return

	if MSTDungeonUtils.is_approx_equal(_previous_xform.origin, state.transform.origin, UNCERTAINTY):
		_consecutive_equalities += 1

	if _consecutive_equalities > CONSECUTIVE_MAX_EQUALITIES:
		set_deferred("mode", RigidBody2D.MODE_STATIC)
		call_deferred("emit_signal", "mode_changed")
	_previous_xform = state.transform



