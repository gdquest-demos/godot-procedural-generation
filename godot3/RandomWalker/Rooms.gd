extends Node2D


enum Type { SIDE, LR, LRB, LRT, LRTB }
enum Cell { GROUND, VEGETATION, SPIKES, MAYBE_GROUND, MAYBE_BUSH, MAYBE_TREE, MAYBE_SPIKES }

const BOTTOM_OPENED := [Type.LRB, Type.LRTB]
const BOTTOM_CLOSED := [Type.LR, Type.LRT]

const CELL_MAP := {
  Cell.GROUND: {"chance": 1.0, "cell": [[Cell.GROUND]], "size": Vector2.ONE},
  Cell.VEGETATION: {"chance": 1.0, "cell": [[Cell.VEGETATION]], "size": Vector2.ONE},
  Cell.SPIKES: {"chance": 1.0, "cell": [[Cell.SPIKES]], "size": Vector2.ONE},
  Cell.MAYBE_GROUND: {"chance": 0.7, "cell": [[Cell.GROUND]], "size": Vector2.ONE},
  Cell.MAYBE_BUSH: {"chance": 0.3, "cell": [[Cell.VEGETATION]], "size": Vector2.ONE},
  Cell.MAYBE_TREE:
  {
	"chance": 0.8,
	"cell": [[Cell.VEGETATION, Cell.VEGETATION], [Cell.VEGETATION, Cell.VEGETATION]],
	"size": 2 * Vector2.ONE
  },
  Cell.MAYBE_SPIKES: {"chance": 0.5, "cell": [[Cell.SPIKES]], "size": Vector2.ONE}
}


var room_size := Vector2.ZERO
var cell_size := Vector2.ZERO

var _rng := RandomNumberGenerator.new()


func _notification(what: int) -> void:
	if what == Node.NOTIFICATION_INSTANCED:
		_rng.randomize()

		var room: TileMap = $Side.get_child(0)
		room_size = room.get_used_rect().size
		cell_size = room.cell_size


func get_room_data(type: int) -> Dictionary:
	var group: Node2D = get_child(type)
	var index := _rng.randi_range(0, group.get_child_count() - 1)
	var room: TileMap = group.get_child(index)

	var data := {"objects": [], "tilemap": []}
	for object in room.get_children():
		data.objects.push_back(object)
	
	for v in room.get_used_cells():
		var mapping: Dictionary = CELL_MAP[room.get_cellv(v)]
		if _rng.randf() > mapping.chance:
			continue

		for x in range(mapping.size.x):
			for y in range(mapping.size.y):
				data.tilemap.push_back({"offset": v + Vector2(x, y), "cell": mapping.cell[x][y]})
	return data
