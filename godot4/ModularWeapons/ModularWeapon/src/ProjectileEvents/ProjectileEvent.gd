# A base class that defines an event for when a projectile hits and/or misses.
# The `trigger()` function is provided and filters out misses from events that
# do not trigger on miss. It calls `_do_trigger()`, which is the specialized
# implementation of the event. Like spawning an explosion, or a new, temporary
# projectile emitter.
# @tags - abstract
class_name ProjectileEvent
extends Resource


@export var triggers_on_misses := false


# Base function for triggering an impact event. Will check if it should or
# shouldn't trigger on miss and only call the virtual `_do_trigger` on a match.
func trigger(_spawn_location: Vector2, _spawn_parent: Node, _weapons_system, _missed: bool) -> void:
	if _missed and not triggers_on_misses:
		return

	_do_trigger(_spawn_location, _spawn_parent, _weapons_system, _missed)


# Virtual implementation specific call for triggering an impact event.
# @tags - virtual
func _do_trigger(_spawn_location: Vector2, _spawn_parent: Node, _weapons_system, _missed: bool) -> void:
	pass
