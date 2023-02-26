class_name HomingMotion
extends ProjectileMotion

@export var homing_radius := 60.0
@export_range(0.0, 0.5, 0.025) var homing_strength : float = 0.067
@export_flags_2d_physics var collision_mask: int

var _circle: CircleShape2D
var _space: PhysicsDirectSpaceState2D
var _query: PhysicsShapeQueryParameters2D


# Sets up a circle with the specified radius, and gets the world 2D space state.
# As we may be dealing with a projectile that checks for collisions multiple
# times per frame, we can't rely on Area2D.
func _setup_shape() -> void:
	_circle = CircleShape2D.new()
	_circle.radius = homing_radius

	_space = projectile.get_world_2d().direct_space_state
	_query = PhysicsShapeQueryParameters2D.new()
	_query.shape = _circle
	_query.collision_mask = collision_mask


# Locates the nearest target using an intersect shape call to the 2D space state.
func _find_target() -> Node2D:
	_query.transform = projectile.global_transform
	var intersections := _space.intersect_shape(_query, 2)
	
	if intersections.size() > 0:
		var min_distance: float = INF
		var min_target: PhysicsBody2D
		
		for intersection in intersections:
			var distance: float = intersection.collider.global_position.distance_to(projectile.global_position)
			if distance < min_distance:
				min_distance = distance
				min_target = intersection.collider
			
		return min_target
	
	return null


# Does not update the projectile, but updates its directions to face towards the
# target.
# @tags - virtual
func _update_movement(_direction: Vector2, _delta: float) -> Vector2:
	if not _query:
		_setup_shape()

	var target := _find_target()
	if target:
		var intended_direction := (target.global_position - projectile.global_position).normalized()
		projectile.direction = (_direction + intended_direction * homing_strength).normalized()

	return Vector2.ZERO
