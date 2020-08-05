class_name SineSideMotion
extends ProjectileMotion

# Amplitude of the sine wave in pixels relative to the emission point.
export var amplitude := 100.0 setget _set_amplitude
# Number of waves the sine draws per second.
export var frequency := 2

var passed_threshold := false

var elapsed_time := 0.0
var square_amplitude: float


func _update_movement(direction: Vector2, delta: float) -> Vector2:
	elapsed_time += delta
	
	var wobble_amount := sin(elapsed_time * PI * frequency) * square_amplitude * (0.5 if not passed_threshold else 1.0)
	if not passed_threshold and wobble_amount < 0.0:
		passed_threshold = true

	var travel_direction := Vector2(-direction.y, direction.x)
	return travel_direction * wobble_amount


func _set_amplitude(value: float) -> void:
	amplitude = value
	square_amplitude = sqrt(value)
