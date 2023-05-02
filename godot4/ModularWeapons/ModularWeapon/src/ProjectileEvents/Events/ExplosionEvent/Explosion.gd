extends Node2D

@onready var player := $AnimationPlayer
@onready var area := $Area2D
@onready var shape: CircleShape2D = $Area2D/CollisionShape2D.shape


# Plays the explosion animation and cleans up
func trigger() -> void:
	player.play("Explode")
	await player.animation_finished
	queue_free()
