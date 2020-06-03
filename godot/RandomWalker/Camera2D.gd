extends Camera2D


signal zoom_changed(zoom)

const LIMIT_DEFAULT := 10000000
const MARGIN := 100
const SPEED := 800
const SPEED_ZOOM := Vector2(0.2, 0.2)
const TIME_START := 0.8
const TIME_TWEEN := 1.0

var _direction := Vector2.ZERO
var _resolution := Vector2.ZERO

onready var tween: Tween = $Tween
onready var scene_tree: SceneTree = get_tree()


func _on_LevelGenerator_level_completed(player_position: Vector2) -> void:
	tween.interpolate_property(self, ":zoom", null, Vector2.ONE, TIME_TWEEN, Tween.TRANS_LINEAR)
	tween.interpolate_property(self, ":position", null, player_position, TIME_TWEEN, Tween.TRANS_LINEAR)
	yield(scene_tree.create_timer(TIME_START), "timeout")
	tween.start()


func _on_Tween_tween_step(_object: Object, key: NodePath, _elapsed: float, value: Vector2) -> void:
	if key == ":zoom":
		emit_signal("zoom_changed", value)


func setup(resolution: Vector2, world_size: Vector2) -> void:
	_resolution = resolution
	limit_left = -LIMIT_DEFAULT
	limit_top = -LIMIT_DEFAULT
	limit_right = LIMIT_DEFAULT
	limit_bottom = LIMIT_DEFAULT
	
	tween.remove_all()
	
	position = world_size / 2
	var ratio := world_size / resolution
	var zoom_max := ceil(max(ratio.x, ratio.y) + 1)
	zoom = Vector2(zoom_max, zoom_max)
	emit_signal("zoom_changed", zoom)
