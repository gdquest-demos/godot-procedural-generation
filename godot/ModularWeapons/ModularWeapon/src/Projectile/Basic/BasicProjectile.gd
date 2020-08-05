extends Projectile

onready var timer: Timer = $Timer


func _post_setup() -> void:
	if not is_inside_tree():
		yield(self, "ready")
	timer.start(lifetime)


func _physics_process(delta: float) -> void:
	var movement := _update_movement(delta)

	var collision := move_and_collide(movement)

	if collision:
		queue_free()


func _on_Timer_timeout() -> void:
	queue_free()
