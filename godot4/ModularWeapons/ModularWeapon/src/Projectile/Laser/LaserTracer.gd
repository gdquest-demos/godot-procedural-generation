extends Projectile

const TIME_STEP := 1.0 / 60.0

var collision_normal := Vector2.ZERO

@onready var impact_particles := $ImpactParticles


# Moves the laser tracer along the path it would have taken over time as a
# regular projectile. Returns an array of positions of each point it reached
# along this line.
func trace_path(lifetime_actual: float) -> Array:
	position = Vector2.ZERO

	var positions := [global_position]
	var current_time := 0.0
	var has_collided := false
	while current_time < lifetime:
		current_time += TIME_STEP
		var planned_movement := _update_movement(TIME_STEP)
		if not has_collided and current_time < lifetime_actual:
			var collision := move_and_collide(planned_movement)
			if not collision:
				positions.append(global_position)
			else:
				positions.append(collision.get_position())
				collided.emit(collision.get_collider(), collision.get_position())
				collision_normal = collision.get_normal()
				_impact()
				has_collided = true

	if not has_collided:
		_miss()
		return positions.slice(0, int(lifetime_actual / lifetime * positions.size()))
	else:
		return positions


# Moves the impact particle effect to the laser and shows it.
# @tags - virtual
func _impact() -> void:
	impact_particles.global_position = global_position
	impact_particles.rotation = collision_normal.angle()
	impact_particles.emitting = true


# Turns off any impact particle effect currently running.
# @tags - virtual
func _miss() -> void:
	impact_particles.emitting = false
