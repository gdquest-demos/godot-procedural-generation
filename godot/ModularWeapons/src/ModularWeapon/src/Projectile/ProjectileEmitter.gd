class_name ProjectileEmitter
extends Node2D

export var projectiles_per_second := 1.0
export var projectile_lifetime := 1.0

var weapons_system: Node


func fire() -> void:
	_do_fire(
		Vector2.UP.rotated(global_rotation), weapons_system.projectile_motions, projectile_lifetime
	)


func _do_fire(_direction: Vector2, _motions: Array, _lifetime: float) -> void:
	pass
