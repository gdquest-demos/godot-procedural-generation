# Abstract base class to represent a projectile's motion.
class_name ProjectileMotion
extends Resource

var projectile: Projectile


# Method to override to define the projectile's motion.
# @tags - virtual
func _update_movement(_direction: Vector2, _delta: float) -> Vector2:
	return Vector2.ZERO
