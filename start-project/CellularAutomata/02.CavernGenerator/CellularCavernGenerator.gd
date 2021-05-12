## Generates a cavern using an algorithm based on celular automata.
extends Node2D

var _wall_conversion := 4 setget set_wall_conversion
var _floor_conversion := 4 setget set_floor_conversion

var _step_count := 10 setget set_step_count
var _step_time := 0.1 setget set_step_time
var _wall_chance := 0.5 setget set_wall_chance


func generate_new_dungeon() -> void:
	pass


func set_wall_chance(value: float) -> void:
	_wall_chance = value


func set_step_time(value: float) -> void:
	_step_time = value


func set_wall_conversion(value: int) -> void:
	_wall_conversion = value


func set_floor_conversion(value: int) -> void:
	_floor_conversion = value


func set_step_count(value: int) -> void:
	_step_count = value
