# The base class for a projectile emitter. Its job is to spawn or control a
# projectile in its `_do_fire()` function. To actually fire a projectile, the
# base `fire()` function is provided and called, I.E. from `_unhandled_input()`.
# @tags - abstract
class_name ProjectileEmitter
extends Node2D


@export var damage_per_collision := 5
@export var projectiles_per_second := 1.0
@export var projectile_lifetime := 1.0

var weapons_system: Node

@onready var spawned_objects: Node = get_tree().get_nodes_in_group("spawned_objects").front()


# Base function to shoot a projectile. Calls the virtual `_do_fire` function.
func fire() -> void:
	_do_fire(
		Vector2.UP.rotated(global_rotation), weapons_system.projectile_motions, projectile_lifetime
	)


# Virtual function that is called by `fire()`.
# @tags - virtual
func _do_fire(_direction: Vector2, _motions: Array, _lifetime: float) -> void:
	pass


# Emits the damaged signal and triggers any impact event in the system.
func _on_projectile_collided(target: Node, hit_location: Vector2) -> void:
	weapons_system.damaged.emit(target, damage_per_collision)
	for event in weapons_system.projectile_impact_events:
		event.trigger(hit_location, spawned_objects, weapons_system, false)


# Triggers any missed event in the system.
func _on_projectile_missed(miss_location: Vector2) -> void:
	for event in weapons_system.projectile_impact_events:
		event.trigger(miss_location, spawned_objects, weapons_system, true)
