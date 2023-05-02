class_name ExplosionEvent
extends ProjectileEvent

@export var explosion_radius := 130.0
@export var explosion_damage := 30.0
@export var damage_scales_with_distances := true
@export_flags_2d_physics var collision_mask: int

var explosion_effect := preload("Explosion.tscn")


# Spawns a new explosion, positions it and triggers its animation.
# Causes damage based on proximity to the explosion.
# @tags - virtual
func _do_trigger(_spawn_location: Vector2, _spawn_parent: Node, _weapons_system, _missed: bool) -> void:
	var explosion := explosion_effect.instantiate()

	explosion.position = _spawn_location

	_spawn_parent.add_child(explosion)
	explosion.shape.radius = explosion_radius
	explosion.area.collision_mask = collision_mask

	explosion.trigger()

	await explosion.get_tree().physics_frame

	var bodies: Array = explosion.area.get_overlapping_bodies()
	for body in bodies:
		var distance: float = body.global_position.distance_to(explosion.global_position)

		var damage := explosion_damage
		if damage_scales_with_distances:
			damage *= clamp(1.0 - distance / explosion_radius, 0, 1)

		_weapons_system.damaged.emit(body, damage)
