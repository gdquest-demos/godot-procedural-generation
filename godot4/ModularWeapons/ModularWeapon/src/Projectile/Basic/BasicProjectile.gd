extends Projectile

@onready var timer: Timer = $Timer


# Called after the base _setup to allow for specialized configuration.
func _post_setup() -> void:
	if not is_inside_tree():
		await ready
	timer.start(lifetime)


func _physics_process(delta: float) -> void:
	var movement := _update_movement(delta)

	var collision : KinematicCollision2D= move_and_collide(movement)

	if collision:
		collided.emit(collision.get_collider(), collision.get_position())
		_impact()


func _on_Timer_timeout() -> void:
	_miss()


# What the projectile does after it has hit a valid target.
# Flares up in size and fades out.
func _impact() -> void:
	set_physics_process(false)
	var tween = create_tween()
	tween.tween_property(self, "modulate", modulate * 3, 0.1).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.1).set_delay(0.1)
	tween.tween_callback(queue_free)


# What the projectile does after it has not hit any target.
# Shrinks and fades out
func _miss() -> void:
	missed.emit(global_position)
	collision_layer = 0
	collision_mask = 0
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25)
	tween.tween_callback(queue_free)
