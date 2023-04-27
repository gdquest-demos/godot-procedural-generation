extends Node2D


enum Type { SIDE, LR, LRB, LRT, LRTB }
enum Cell { GROUND, VEGETATION, SPIKES, MAYBE_GROUND, MAYBE_BUSH, MAYBE_TREE, MAYBE_SPIKES }

const BOTTOM_OPENED := [Type.LRB, Type.LRTB]
const BOTTOM_CLOSED := [Type.LR, Type.LRT]

var room_size := Vector2.ZERO
var cell_size := Vector2.ZERO

var _rng := RandomNumberGenerator.new()


func _notification(what: int) -> void:
	if what == Node.NOTIFICATION_SCENE_INSTANTIATED:
		_rng.randomize()

		var room: TileMap = $Side.get_child(0)
		room_size = room.get_used_rect().size
		cell_size = room.tile_set.tile_size


func get_room_data(type: int) -> Dictionary:
	var group: Node2D = get_child(type)
	var index := _rng.randi_range(0, group.get_child_count() - 1)
	var room: TileMap = group.get_child(index)

	var data := {"objects": [], "tilemap": []}
	for object in room.get_children():
		data.objects.push_back(object)

	for v in room.get_used_cells(0):
		var cell_data = room.get_cell_tile_data(0,v)
		var chance: float = cell_data.get_custom_data("chance")
		var target_id: int = cell_data.get_custom_data("target_id")
		var cell_source_id : int = room.get_cell_source_id(0,v)
		var atlas_coords : Vector2i = room.get_cell_atlas_coords(0,v)
		if _rng.randf() > chance:
			continue
		data.tilemap.push_back({
			"offset": v,
			"cell": cell_source_id,
			"atlas_coords": atlas_coords,
			"target_id": target_id
		})
	return data
