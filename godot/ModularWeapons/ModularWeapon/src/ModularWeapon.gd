# Main class to manage, configure and control projectile emitters from.
class_name ModularWeapon
extends Node2D


#warning-ignore: unused_signal
signal damaged(target, amount)

export var emitter_configuration: PackedScene setget set_emitter_configuration
export var projectile_emitter: PackedScene
export (Array, Resource) var projectile_motions := []
export (Array, Resource) var projectile_impact_events := []


# Setter for emitter configuration. Whenever changed, will remove existing
# emitters and replace them with the new configuration.
func set_emitter_configuration(value: PackedScene) -> void:
	emitter_configuration = value
	if not is_inside_tree():
		yield(self, "ready")

	_clear_emitters()
	_add_new_emitters()


# Removes existing projectile emitters.
func _clear_emitters() -> void:
	for child in get_children():
		if child is ProjectileEmitter:
			remove_child(child)
			child.queue_free()


# Adds new projectile emitters that are positioned and rotated according to the
# provided configuration scene.
func _add_new_emitters() -> void:
	var configuration := emitter_configuration.instance()

	for weapon_position in configuration.get_children():
		var new_emitter := projectile_emitter.instance()
		new_emitter.position = weapon_position.position
		new_emitter.rotation = weapon_position.rotation

		new_emitter.weapons_system = self
		add_child(new_emitter)
