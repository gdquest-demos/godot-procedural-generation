extends Button


export (NodePath) var camera_one_path
export (NodePath) var camera_two_path

onready var _camera_one: Camera2D = get_node(camera_one_path)
onready var _camera_two: Camera2D = get_node(camera_two_path)


func _on_pressed():
	if _camera_one.current:
		_camera_two.current = true
	else:
		_camera_one.current = true
