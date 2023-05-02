extends Projectile

onready var timer: Timer = $Timer
onready var tween := $Tween


# Called after the base _setup to allow for specialized configuration.
func _post_setup() -> void:
	if not is_inside_tree():
		yield(self, "ready")
	timer.start(lifetime)


func _physics_process(delta: float) -> void:
	var movement := _update_movement(delta)

	var collision := move_and_collide(movement)

	if collision:
		emit_signal("collided", collision.collider, collision.position)
		_impact()


func _on_Timer_timeout() -> void:
	_miss()


# What the projectile does after it has hit a valid target.
# Flares up in size and fades out.
# @tags - virtual
func _impact() -> void:
	set_physics_process(false)
	tween.interpolate_property(self, "modulate", modulate, modulate * 3, 0.1, Tween.TRANS_CUBIC)
	tween.interpolate_property(self, "modulate", modulate * 3, Color.transparent, 0.2, 0, 2, 0.1)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()


# What the projectile does after it has not hit any target.
# Shrinks and fades out
# @tags - virtual
func _miss() -> void:
	emit_signal("missed", global_position)
	collision_layer = 0
	collision_mask = 0
	tween.interpolate_property(self, "scale", scale, Vector2.ZERO, 0.25)
	tween.start()
	yield(tween, "tween_all_completed")
	queue_free()
