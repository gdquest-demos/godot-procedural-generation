# Base class to represent a projectile's motion. The projectile's position
# and/or orientation can be updated inside of `_update_movement`, or it can
# be used just to provide a movement vector.
# @tags - abstract
class_name ProjectileMotion
extends Resource

var projectile: Projectile


# Method to override to define the projectile's motion.
# @tags - virtual
func _update_movement(_direction: Vector2, _delta: float) -> Vector2:
	return Vector2.ZERO
