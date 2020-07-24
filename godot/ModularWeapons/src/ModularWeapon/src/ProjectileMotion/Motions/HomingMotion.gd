class_name HomingMotion
extends ProjectileMotion

export var homing_radius := 60.0
export (float, 0.0, 0.5, 0.025) var homing_strength := 0.067
export (int, LAYERS_2D_PHYSICS) var collision_mask: int

var _area: Area2D = null


func _setup_area() -> void:
	_area = Area2D.new()
	_area.collision_mask = collision_mask

	var homing_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = homing_radius
	homing_shape.shape = circle

	_area.add_child(homing_shape)
	projectile.add_child(_area)


func _find_target() -> Node2D:
	var bodies := _area.get_overlapping_bodies()

	var distance_min := INF
	var closest_body: Node2D = null
	for body in bodies:
		var distance_to := (body as PhysicsBody2D).global_position.distance_squared_to(
			projectile.global_position
		)
		distance_min = min(distance_min, distance_to)
		closest_body = body
	return closest_body


func _update_movement(_direction: Vector2, _current_time: float, _lifetime: float) -> Vector2:
	if not _area:
		_setup_area()

	var target := _find_target()
	if target:
		var intended_direction := (target.global_position - projectile.global_position).normalized()
		projectile.direction = (_direction + intended_direction * homing_strength).normalized()

	return Vector2.ZERO
