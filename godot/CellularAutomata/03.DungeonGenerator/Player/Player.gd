extends KinematicBody2D

signal pickaxe_used(dig_position)

export var speed := 500

const DRILL_RANGE := 64

onready var _pivot := $Pivot


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		emit_signal("pickaxe_used", global_position + Vector2.RIGHT.rotated(_pivot.rotation) * DRILL_RANGE)


func _physics_process(_delta: float) -> void:
	var direction := Vector2(Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")).normalized()

	_pivot.look_at(global_position + direction)

	var velocity := direction * speed
	move_and_slide(velocity)
