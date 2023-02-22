extends CharacterBody2D


const FLOOR_NORMAL: = Vector2.UP

@export var speed: = Vector2(400.0, 1000.0)
@export var gravity: = 3500.0

# in Godot 4 this is an error, velocity redefined
#var velocity: = Vector2.ZERO
func _ready():
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
