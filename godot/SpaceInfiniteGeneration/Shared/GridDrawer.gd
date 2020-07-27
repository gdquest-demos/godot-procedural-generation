extends Node2D

var cell_size: float
var grid_origin: Vector2
var cell_count: int


func _draw() -> void:
	if cell_size == 0:
		return

	var position_origin := grid_origin * cell_size

	for x in range(-cell_count / 2, cell_count / 2):
		for y in range(-cell_count / 2, cell_count / 2):
			var cell_rect := Rect2(
				Vector2(
					position_origin.x + x * cell_size - cell_size / 2,
					position_origin.y + y * cell_size - cell_size / 2
				),
				Vector2(cell_size, cell_size)
			)

			draw_rect(cell_rect, Color.skyblue, false)


func setup(size: float, count: int) -> void:
	cell_size = size
	cell_count = count
	update()


func move_grid_to(origin: Vector2) -> void:
	grid_origin = origin
	update()
