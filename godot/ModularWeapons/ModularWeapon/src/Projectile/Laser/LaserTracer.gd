extends Projectile

const TIME_STEP := 1.0 / 60.0


func trace_path(lifetime_actual: float) -> Array:
	position = Vector2.ZERO

	var current_transform := get_global_transform()
	var positions := [current_transform.origin]

	var current_time := 0.0
	_last_offset = Vector2.ZERO

	while current_time < lifetime:
		current_time += TIME_STEP

		var planned_movement := _update_movement(TIME_STEP)
		var collision := move_and_collide(planned_movement)
		
		if not collision:
			current_transform.origin = get_global_transform().origin
			positions.append(current_transform.origin)
		else:
			positions.append(collision.position)
			emit_signal("collided", collision.collider)
			break
	
	return positions.slice(0, int(lifetime_actual / current_time * positions.size()))
