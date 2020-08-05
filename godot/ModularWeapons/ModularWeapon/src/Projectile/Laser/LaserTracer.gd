extends Projectile

const TIME_STEP := 1.0 / 60.0

var one_time_setup := false


func setup(_position: Vector2, _direction: Vector2, _motions: Array, _lifetime: float) -> void:
	position = _position
	direction = _direction
	if not one_time_setup:
		for motion in _motions:
			var new_motion = motion.duplicate()
			new_motion.projectile = self
			motions.append(new_motion)
		one_time_setup = true

	lifetime = _lifetime
	_post_setup()


func trace_path(lifetime_actual: float) -> Array:
	position = Vector2.ZERO

	var current_transform := get_global_transform()
	var positions := [current_transform.origin]

	var current_time := 0.0
	_last_offset = Vector2.ZERO

	var collided := false
	while not collided and current_time < lifetime:
		current_time += TIME_STEP

		var planned_movement := _update_movement(TIME_STEP)
		var collision := move_and_collide(planned_movement)
		
		if not collision:
			current_transform.origin += planned_movement
			positions.append(current_transform.origin)
		else:
			positions.append(collision.position)

	return positions.slice(0, lifetime_actual / current_time * positions.size())
