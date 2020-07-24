extends Reference

enum NeighborDirection { UP, DOWN, LEFT, RIGHT }


var neighbors := []


func _init() -> void:
	neighbors.resize(4)


func get_neighbor(direction: int):
	return neighbors[direction]
