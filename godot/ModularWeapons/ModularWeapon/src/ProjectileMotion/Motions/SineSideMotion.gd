class_name SineSideMotion
extends ProjectileMotion

# Amplitude of the sine wave in pixels relative to the emission point.
export var amplitude := 100.0
# Number of waves the sine draws per second.
export var frequency := 2


func _update_movement(_direction: Vector2, _current_time: float, _lifetime: float) -> Vector2:
	var wobble_amount := (
		amplitude
		* sin((PI * (_current_time / _lifetime)) * frequency)
	)

	var travel_direction := Vector2(_direction.y, -_direction.x)
	return travel_direction * wobble_amount
