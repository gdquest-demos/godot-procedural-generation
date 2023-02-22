extends "Actor.gd"


@onready var visibility_enabler : VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D


func _ready() -> void:
	set_physics_process(false)
	velocity.x = speed.x


func _physics_process(_delta: float) -> void:
	velocity.x *= -1 if is_on_wall() else 1
	set_velocity(velocity)
	set_up_direction(FLOOR_NORMAL)
	move_and_slide()
	velocity.y = velocity.y
	
