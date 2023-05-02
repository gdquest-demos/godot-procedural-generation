extends Node2D


var _player: CharacterBody2D = null

@onready var extra: Node2D = $Extra


func _ready() -> void:
	for n in extra.get_children():
		if n.is_in_group("player"):
			_player = n
		elif n.is_in_group("enemy"):
			n.visibility_enabler.connect("screen_entered",Callable(self,"_on_Enemy_screen_enetered").bind(n))

# this func is currently not used an may be removed
func _on_Enemy_screen_enetered(enemy: Node2D) -> void:
	pass
#	enemy.direction .velocity.x = sign((_player.position - enemy.position).x) * enemy.speed.x
