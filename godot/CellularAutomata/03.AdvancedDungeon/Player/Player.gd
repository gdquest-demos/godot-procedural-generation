extends KinematicBody2D

signal pickaxe_used(dig_position)

export var speed := 500

var _velocity := Vector2.ZERO

onready var _pivot := $Pivot
onready var _pickaxe := $Pivot/Pickaxe


func _physics_process(_delta: float) -> void:
	var direction := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if direction.length() > 1.0:
		direction = direction.normalized()
	
	_update_look_direction(direction)
	
	_velocity = direction * speed
	_velocity = move_and_slide(_velocity)


func _update_look_direction(input_direction: Vector2) -> void:
	_pivot.look_at(global_position + input_direction)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		emit_signal("pickaxe_used", _pickaxe.global_position)
