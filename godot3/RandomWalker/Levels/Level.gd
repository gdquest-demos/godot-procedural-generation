extends Node2D


var _player: KinematicBody2D = null

onready var extra: Node2D = $Extra


func _ready() -> void:
	for n in extra.get_children():
		if n.is_in_group("player"):
			_player = n
		elif n.is_in_group("enemy"):
			n.visibility_enabler.connect("screen_entered", self, "_on_Enemy_screen_enetered", [n])


func _on_Enemy_screen_enetered(enemy: Node2D) -> void:
	enemy.velocity.x = sign((_player.position - enemy.position).x) * enemy.speed.x
