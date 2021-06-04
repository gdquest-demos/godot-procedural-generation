extends KinematicBody2D

export var speed := 500

onready var _pivot := $Pivot


func _physics_process(_delta: float) -> void:
	var direction := Vector2(Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")).normalized()

	_pivot.look_at(global_position + direction)

	var velocity := direction * speed
	move_and_slide(velocity)
