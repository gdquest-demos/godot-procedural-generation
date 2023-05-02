# Base class for a projectile. The life cycle of the projectile follows these steps:
# 
# 1. An emitter spawns a projectile
# 2. `setup()` is called by the emitter
# 3. `_post_setup()` is called
# 4. `_update_movement()` moves the projectile according to its emitter's
# projectile motions.
# 5. The projectile eithers runs out of lifetime or hits an object.
# 
# When the projectile runs out of life, it should call `_miss()` and emit the
# `missed` signal. When it hits an object, it should call `_impact()` and emit
# the `collided` signal.
# `_miss()` and `_impact()` are there for the projectile to clean up. The signals
# are a way to communicate back to its emitter/the weapons system.
# @tags - abstract
class_name Projectile
extends CharacterBody2D


#warning-ignore: unused_signal
signal collided(target, hit_location)
#warning-ignore: unused_signal
signal missed(miss_location)


var lifetime := 1.0
var motions := []
var direction := Vector2.UP

var _is_setup := false


# Base setup function to configure spawned projectiles.
func setup(_position: Vector2, _direction: Vector2, _motions: Array, _lifetime: float) -> void:
	position = _position
	direction = _direction
	lifetime = _lifetime
	
	if not _is_setup:
		for motion in _motions:
			var new_motion = motion.duplicate()
			new_motion.projectile = self
			motions.append(new_motion)

		_is_setup = true

	_post_setup()


# Virtual function for any specialized setup required by a derived class.
# @tags - virtual
func _post_setup() -> void:
	pass


# Virtual function called when a projectile hits a target. It's where it can
# clean itself up if needed (I.E. queue_free)
# @tags - virtual
func _impact() -> void:
	pass


# Virtual function called when a projectile hits no target. It's where it can
# clean itself up if needed (I.E. queue_free)
# @tags - virtual
func _miss() -> void:
	pass


# Calculates and returns the projectile's movement this frame.
# Can mutate the projectile's state.
func _update_movement(delta: float) -> Vector2:
	var movement_vector := Vector2.ZERO
	
	if motions.is_empty():
		return movement_vector

	for motion in motions:
		movement_vector += motion._update_movement(direction, delta)

	return movement_vector
