extends "Actor.gd"


onready var visibility_enabler : VisibilityEnabler2D = $VisibilityEnabler2D


func _ready() -> void:
	set_physics_process(false)
	velocity.x = speed.x


func _physics_process(_delta: float) -> void:
	velocity.x *= -1 if is_on_wall() else 1
	velocity.y = move_and_slide(velocity, FLOOR_NORMAL).y
	
