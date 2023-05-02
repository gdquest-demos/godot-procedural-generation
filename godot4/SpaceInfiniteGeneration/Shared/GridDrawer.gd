extends Node2D

var cell_size: float
var grid_origin: Vector2
var cell_count: int


func _draw() -> void:
	if cell_size == 0:
		return

	var position_origin := grid_origin * cell_size

	var half_cell_count := int(cell_count / 2.0)
	var half_cell_size := cell_size/2.0
	
	for x in range(-half_cell_count, half_cell_count):
		for y in range(-half_cell_count, half_cell_count):
			var cell_rect := Rect2(
				Vector2(
					position_origin.x + x * cell_size - half_cell_size,
					position_origin.y + y * cell_size - half_cell_size
				),
				Vector2(cell_size, cell_size)
			)

			draw_rect(cell_rect, Color.SKY_BLUE, false)


func setup(size: float, count: int) -> void:
	cell_size = size
	cell_count = count
	
	queue_redraw()


func move_grid_to(origin: Vector2) -> void:
	grid_origin = origin
	queue_redraw()
