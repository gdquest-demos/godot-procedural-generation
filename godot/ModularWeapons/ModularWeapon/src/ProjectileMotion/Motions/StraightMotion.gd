class_name StraightMotion
extends ProjectileMotion

# Total distance the projectile travels over its lifetime.
export var travel_speed := 300.0


func _update_movement(direction: Vector2, delta: float) -> Vector2:
	return direction * travel_speed * delta
