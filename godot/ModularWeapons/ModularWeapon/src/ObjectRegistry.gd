class_name ObjectRegistry
extends Node

onready var projectiles := $Projectiles


func add_projectile(projectile: Node) -> void:
	projectiles.add_child(projectile)
