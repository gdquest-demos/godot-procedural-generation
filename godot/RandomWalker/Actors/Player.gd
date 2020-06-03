extends Actor


const TIME_DEATH := 0.2

onready var danger_detector: Area2D = $DangerDetector
onready var tween: Tween = $Tween


func _on_DangerDetector_body_entered(_body: Node):
	set_physics_process(false)
	
	tween.interpolate_property(self, "scale", null, Vector2.ZERO, TIME_DEATH, Tween.TRANS_LINEAR)
	tween.start()
	
	yield(tween, "tween_all_completed")
	queue_free()


func _physics_process(_delta: float) -> void:
	var direction := _get_direction()
	var is_jump_interrupted := Input.is_action_just_released("jump") and velocity.y < 0.0
	velocity = calculate_velocity(velocity, direction, speed, is_jump_interrupted)
	velocity = move_and_slide(velocity, FLOOR_NORMAL)


func _get_direction() -> Vector2:
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y := (
		-Input.get_action_strength("jump")
		if is_on_floor() and Input.is_action_just_pressed("jump")
		else 0.0
	)
	return Vector2(x, y)


func calculate_velocity(
	velocity: Vector2, direction: Vector2, speed: Vector2, is_jump_interrupted: bool
) -> Vector2:
	velocity.x = speed.x * direction.x
	if direction.y != 0.0:
		velocity.y = speed.y * direction.y
	if is_jump_interrupted:
		velocity.y = 0.0
	return velocity
