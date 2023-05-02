class_name StraightMotion
extends ProjectileMotion

# Speed at which the projectile travels.
@export var travel_speed := 300.0


# Moves in a straight line by the projectile's speed
# @tags - virtual
func _update_movement(direction: Vector2, delta: float) -> Vector2:
	return direction * travel_speed * delta
