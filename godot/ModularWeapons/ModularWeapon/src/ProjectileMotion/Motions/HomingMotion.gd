class_name HomingMotion
extends ProjectileMotion

export var homing_radius := 60.0
export (float, 0.0, 0.5, 0.025) var homing_strength := 0.067
export (int, LAYERS_2D_PHYSICS) var collision_mask: int

var _circle: CircleShape2D
var _space: Physics2DDirectSpaceState
var _query: Physics2DShapeQueryParameters


func _setup_shape() -> void:
	_circle = CircleShape2D.new()
	_circle.radius = homing_radius

	_space = projectile.get_world_2d().direct_space_state
	_query = Physics2DShapeQueryParameters.new()
	_query.set_shape(_circle)
	_query.collision_layer = collision_mask


func _find_target() -> Node2D:
	_query.transform = projectile.global_transform
	var intersections := _space.intersect_shape(_query, 1)
	if intersections.size() > 0:
		return intersections[0].collider
	
	return null


func _update_movement(_direction: Vector2, _delta: float) -> Vector2:
	if not _query:
		_setup_shape()

	var target := _find_target()
	if target:
		var intended_direction := (target.global_position - projectile.global_position).normalized()
		projectile.direction = (_direction + intended_direction * homing_strength).normalized()

	return Vector2.ZERO
