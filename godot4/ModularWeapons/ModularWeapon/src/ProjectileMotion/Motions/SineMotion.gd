class_name SineMotion
extends ProjectileMotion

# Amplitude of the sine wave in pixels relative to the emission point.
@export var amplitude := 100.0
# Number of waves the sine draws per second.
@export var frequency := 2

var elapsed_time := 0.0


# Moves the projectile perpendicular to its travel direction in a sine wave
# pattern.
# @tags - virtual
func _update_movement(direction: Vector2, delta: float) -> Vector2:
	elapsed_time += delta
	
	var wobble_amount := amplitude * sin(elapsed_time * frequency * PI) * frequency

	var travel_direction := Vector2(-direction.y, direction.x)
	return travel_direction * wobble_amount * delta
