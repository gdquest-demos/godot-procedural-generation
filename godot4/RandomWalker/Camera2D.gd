extends Camera2D


signal zoom_changed(zoom: float)

const LIMIT_DEFAULT := 10000000
const TIME_START := 0.8
const TIME_TWEEN := 1.0
const TARGET_ZOOM := Vector2.ONE

var _direction := Vector2.ZERO
var _resolution := Vector2.ZERO


func _on_LevelGenerator_level_completed(player_position: Vector2) -> void:
	await get_tree().create_timer(TIME_START).timeout
	var tween = create_tween()
	tween.tween_property(self, "zoom", TARGET_ZOOM, TIME_TWEEN).set_delay(0.2)
	tween.parallel().tween_method(_on_Tween_tween_step, zoom, TARGET_ZOOM,TIME_TWEEN)
	tween.parallel().tween_property(self, "position", player_position, TIME_TWEEN).set_trans(Tween.TRANS_QUAD)
	tween.connect("finished", get_parent()._on_Tween_tween_all_completed)


func _on_Tween_tween_step(zoom: Vector2) -> void:
	zoom_changed.emit(zoom)


func setup(resolution: Vector2, world_size: Vector2) -> void:
	_resolution = resolution
	limit_left = -LIMIT_DEFAULT
	limit_top = -LIMIT_DEFAULT
	limit_right = LIMIT_DEFAULT
	limit_bottom = LIMIT_DEFAULT

	position = world_size / 2
	var ratio := world_size / resolution
	var zoom_max := 1 / ceilf(maxf(ratio.x, ratio.y) + 1)
	zoom = zoom_max * Vector2.ONE
	zoom_changed.emit(zoom)

