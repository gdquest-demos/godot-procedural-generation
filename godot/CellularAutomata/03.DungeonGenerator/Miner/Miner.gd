extends CharacterBody2D

signal drill_used(dig_positions)

@export var speed := 500

const DRILL_RANGE := 100

@onready var _pivot := $Pivot


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var dig_positions := []
		var angles_of_attack := [0, PI/6, -PI/6]
		for angle in angles_of_attack:
			dig_positions.append(global_position + Vector2.RIGHT.rotated(_pivot.rotation + angle) * DRILL_RANGE)
		drill_used.emit(dig_positions)


func _physics_process(_delta: float) -> void:
	var direction := Vector2(Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"), Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")).normalized()

	_pivot.look_at(global_position + direction)

	velocity = direction * speed
	move_and_slide()
