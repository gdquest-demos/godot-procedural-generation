extends Camera2D


signal zoom_changed(zoom)

const LIMIT_DEFAULT := 10000000
#unused variables
#const MARGIN := 100
#const SPEED := 800
#const SPEED_ZOOM := Vector2(0.2, 0.2)
const TIME_START := 0.8
const TIME_TWEEN := 1.0

var _direction := Vector2.ZERO
var _resolution := Vector2.ZERO

# Tweens are no longer used as class, but constructed and fired on demand
#onready var tween: Tween = $Tween
@onready var scene_tree: SceneTree = get_tree()


func _on_LevelGenerator_level_completed(player_position: Vector2) -> void:
	await scene_tree.create_timer(TIME_START).timeout
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(self,"zoom",Vector2(0.8,0.8),TIME_TWEEN)
	tween.connect("step_finished",self._on_Tween_tween_step.bind(self))
	tween.connect("finished",get_parent()._on_Tween_tween_all_completed)
	tween.parallel().tween_property(self,"position",player_position,TIME_TWEEN)


func _on_Tween_tween_step(i:int, camera: Camera2D) -> void:
	if i == 1:
		emit_signal("zoom_changed", camera.zoom)
#	if key == "zoom":
#		emit_signal("zoom_changed", value)


func setup(resolution: Vector2, world_size: Vector2) -> void:
	
	_resolution = resolution
	limit_left = -LIMIT_DEFAULT
	limit_top = -LIMIT_DEFAULT
	limit_right = LIMIT_DEFAULT
	limit_bottom = LIMIT_DEFAULT
	
	position = world_size / 2
	var ratio := world_size / resolution
	# ceilf and maxf used to denote result is a float,
	# other option is to declar var as float - otherwise this is an error
	var zoom_max := 1 / ceilf(maxf(ratio.x, ratio.y) + 1)
	zoom = Vector2(zoom_max, zoom_max)
	emit_signal("zoom_changed", zoom)
	
