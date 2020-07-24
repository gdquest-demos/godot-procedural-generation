class_name Projectile
extends KinematicBody2D

var lifetime := 1.0
var motions := []
var direction := Vector2.UP
var multiple_projectiles_active := true

var _last_offset := Vector2.ZERO


func setup(_position: Vector2, _direction: Vector2, _motions: Array, _lifetime: float) -> void:
	position = _position
	direction = _direction
	motions = _motions
	for motion in motions:
		motions.back().projectile = self

	lifetime = _lifetime
	_post_setup()


func _post_setup() -> void:
	pass


# Calculates and returns the projectile's movement this frame.
# Mutates the projectile's state, so be sure to only call it when the time changes.
func _update_movement(current_time: float) -> Vector2:
	if motions.empty():
		return Vector2.ZERO

	var offset := Vector2.ZERO
	for motion in motions:
		offset += motion._update_movement(direction, current_time, lifetime)

	var movement_vector := offset - _last_offset
	_last_offset = offset
	return movement_vector
