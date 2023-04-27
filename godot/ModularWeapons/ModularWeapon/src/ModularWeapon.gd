# Main class to manage, configure and control projectile emitters from.
class_name ModularWeapon
extends Node2D


#warning-ignore: unused_signal
signal damaged(target, amount)

@export var emitter_configuration: PackedScene : set = _set_emitter_configuration
@export var projectile_emitter: PackedScene : set = _set_emitter
@export var projectile_motions : Array[Resource] = []
@export var projectile_impact_events : Array[Resource] = []


# Appends the specified motion to the projectile motions array. Checks for and prevents
# duplicates by default, unless the second parameter is true.
func add_motion(new_motion: ProjectileMotion, allows_duplicates := false) -> void:
	if not allows_duplicates:
		var has_motion := false
		for motion in projectile_motions:
			has_motion = new_motion.get_script() == motion.get_script()
			if has_motion:
				return
	projectile_motions.append(new_motion)


# Appends the specified event to the projectile events array. Checks for and prevents
# duplicates by default, unless the second parameter is true.
func add_impact_event(new_event: ProjectileEvent, allows_duplicates := false) -> void:
	if not allows_duplicates:
		var has_event := false
		for event in projectile_impact_events:
			has_event = new_event.get_script() == event.get_script()
			if has_event:
				return
	projectile_impact_events.append(new_event)


# Setter for emitter configuration. Whenever changed, will remove existing
# emitters and replace them with the new configuration.
func _set_emitter_configuration(value: PackedScene) -> void:
	emitter_configuration = value
	if not is_inside_tree():
		await ready

	_clear_emitters()
	_add_new_emitters()


# Setter for emitter scene. When changed, will replace existing emitters.
func _set_emitter(value: PackedScene) -> void:
	projectile_emitter = value
	_set_emitter_configuration(emitter_configuration)


# Removes existing projectile emitters.
func _clear_emitters() -> void:
	for child in get_children():
		if child is ProjectileEmitter:
			remove_child(child)
			child.queue_free()


# Adds new projectile emitters that are positioned and rotated according to the
# provided configuration scene.
func _add_new_emitters() -> void:
	var configuration := emitter_configuration.instantiate()

	for weapon_position in configuration.get_children():
		var new_emitter := projectile_emitter.instantiate()
		new_emitter.position = weapon_position.position
		new_emitter.rotation = weapon_position.rotation

		new_emitter.weapons_system = self
		add_child(new_emitter)

	configuration.free()
