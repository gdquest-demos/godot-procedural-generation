extends Camera2D


signal zoom_changed(zoom:float)

const LIMIT_DEFAULT := 10000000
#unused variables
#const MARGIN := 100
#const SPEED := 800
#const SPEED_ZOOM := Vector2(0.2, 0.2)
const TIME_START := 0.8
const TIME_TWEEN := 1.0
const TARGET_ZOOM := Vector2.ONE

var _direction := Vector2.ZERO
var _resolution := Vector2.ZERO

# Tweens are no longer used as class, but constructed and fired on demand
#onready var tween: Tween = $Tween
@onready var scene_tree: SceneTree = get_tree()


func _on_LevelGenerator_level_completed(player_position: Vector2) -> void:
	await scene_tree.create_timer(TIME_START).timeout
	var tween = get_tree().create_tween()
	tween.tween_property(self,"zoom",TARGET_ZOOM,TIME_TWEEN).set_delay(0.2)
	tween.parallel().tween_method(_on_Tween_tween_step,self.zoom,TARGET_ZOOM,TIME_TWEEN)
	tween.parallel().tween_property(self,"position",player_position,TIME_TWEEN).set_trans(Tween.TRANS_QUAD)
	tween.connect("finished",get_parent()._on_Tween_tween_all_completed)


func _on_Tween_tween_step(zoom: Vector2) -> void:
	emit_signal("zoom_changed", zoom)


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
	
