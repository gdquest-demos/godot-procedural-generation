extends Node2D


@export var level_size := Vector2(100, 80)
@export var rooms_size := Vector2(10, 14)
@export var rooms_max := 15

@onready var level: TileMap = $Level
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	_setup_camera()
	_generate()


func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_select"):
		_generate()


func _setup_camera() -> void:
	camera.position = level.map_to_local(level_size / 2)
	var z := 8 / maxf(level_size.x, level_size.y)
	camera.zoom = Vector2(z, z)


func _generate() -> void:
	level.clear()
	for vector in BasicDungeonGenerator.generate(level_size, rooms_size, rooms_max):
		level.set_cell(0,vector, 0, Vector2i(0,0), 0)
