extends "Actor.gd"


@onready var visibility_enabler : VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D
@onready var inital_speed : float = 300.0
@onready var _direction : float = 1.0

func _ready() -> void:
	# the visible on_screen enabler does not activate physics again,
	# this does not work without adding a new func and signal
	set_physics_process(false)
	velocity.x = inital_speed
	velocity.y = 0.0


func _physics_process(_delta: float) -> void:
	if is_on_wall():
		_direction *= -1
	velocity.x = inital_speed * _direction #if is_on_wall() else 1
	if not is_on_floor():
		velocity.y += 3500 * _delta
	
	move_and_slide()


func _on_visible_on_screen_enabler_2d_screen_entered():
	set_physics_process(true)

func _on_visible_on_screen_enabler_2d_screen_exited():
	set_physics_process(false)
