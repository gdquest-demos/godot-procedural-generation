@tool
extends Marker2D


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_line(Vector2.ZERO, Vector2.UP * 100, Color.STEEL_BLUE, 4)
		draw_line(Vector2(-15, -85), Vector2(15, -115), Color.RED, 4)
		draw_line(Vector2(-15, -115), Vector2(15, -85), Color.GREEN, 4)
