extends Button

@export var camera_one_path : NodePath
@export var camera_two_path : NodePath

@onready var _camera_one: Camera2D = get_node(camera_one_path)
@onready var _camera_two: Camera2D = get_node(camera_two_path)


func _on_pressed():
	if _camera_one.is_current():
		_camera_two.make_current()
	else:
		_camera_one.make_current()
