extends KinematicBody2D


const FLOOR_NORMAL: = Vector2.UP

export var speed: = Vector2(400.0, 1000.0)
export var gravity: = 3500.0

var velocity: = Vector2.ZERO


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
