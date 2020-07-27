class_name StraightMotion
extends ProjectileMotion

# Total distance the projectile travels over its lifetime.
export var travel_distance_total := 300.0


func _update_movement(_direction: Vector2, _current_time: float, _lifetime: float) -> Vector2:
	return _direction * travel_distance_total * _lifetime * (_current_time / _lifetime)
