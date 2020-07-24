extends Projectile

const TIME_STEP := 1.0 / 60.0


func trace_path(lifetime_actual: float) -> Array:
	position = Vector2.ZERO

	var current_transform := get_global_transform()
	var positions := [current_transform.origin]

	var current_time := 0.00001
	_last_offset = Vector2.ZERO

	var collided := false
	while not collided and current_time < lifetime:
		current_time += TIME_STEP

		var planned_movement := _update_movement(current_time)
		collided = test_move(current_transform, planned_movement)
		
		if not collided:
			current_transform.origin += planned_movement
			positions.append(current_transform.origin)
		else:
			global_position = current_transform.origin
			var collision := move_and_collide(planned_movement)
			positions.append(collision.position)

	return positions.slice(0, lifetime_actual / current_time * positions.size())
