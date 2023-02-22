extends Node2D


enum Type { SIDE, LR, LRB, LRT, LRTB }
enum Cell { GROUND, VEGETATION, SPIKES, MAYBE_GROUND, MAYBE_BUSH, MAYBE_TREE, MAYBE_SPIKES }

const BOTTOM_OPENED := [Type.LRB, Type.LRTB]
const BOTTOM_CLOSED := [Type.LR, Type.LRT]

# this is no longer needed, custom data layers in tilemaps are much better suited
#const CELL_MAP := {
#  Cell.GROUND: {"chance": 1.0, "cell": [[Cell.GROUND]], "size": Vector2.ONE},
#  Cell.VEGETATION: {"chance": 1.0, "cell": [[Cell.VEGETATION]], "size": Vector2.ONE},
#  Cell.SPIKES: {"chance": 1.0, "cell": [[Cell.SPIKES]], "size": Vector2.ONE},
#  Cell.MAYBE_GROUND: {"chance": 0.7, "cell": [[Cell.GROUND]], "size": Vector2.ONE},
#  Cell.MAYBE_BUSH: {"chance": 0.3, "cell": [[Cell.VEGETATION]], "size": Vector2.ONE},
#  Cell.MAYBE_TREE:
#  {
#	"chance": 0.8,
#	"cell": [[Cell.VEGETATION, Cell.VEGETATION], [Cell.VEGETATION, Cell.VEGETATION]],
#	"size": 2 * Vector2.ONE
#  },
#  Cell.MAYBE_SPIKES: {"chance": 0.5, "cell": [[Cell.SPIKES]], "size": Vector2.ONE}
#}


var room_size := Vector2.ZERO
var cell_size := Vector2.ZERO

var _rng := RandomNumberGenerator.new()


func _notification(what: int) -> void:
	if what == Node.NOTIFICATION_SCENE_INSTANTIATED:
		_rng.randomize()

		var room: TileMap = $Side.get_child(0)
#		room.data
		room_size = room.get_used_rect().size
		cell_size = room.tile_set.tile_size


func get_room_data(type: int) -> Dictionary:
	var group: Node2D = get_child(type)
	var index := _rng.randi_range(0, group.get_child_count() - 1)
	var room: TileMap = group.get_child(index)

	var data := {"objects": [], "tilemap": []}
	for object in room.get_children():
		data.objects.push_back(object)
	
	# get_used_cells now needs to know which layer, for conversion from Godot 3 to 4, layer 0 should be safe
	for v in room.get_used_cells(0):
		# just like set_cellv there no longer is a get_cellv in Godot 4
		# while the line below works, it might maybe be better to directly get the TileData
#		var mapping: Dictionary = CELL_MAP[room.get_cell_source_id(0,v)]
		# since the line above had a lot of problems with my converted tileset/tilemap
		# I just added a custom data layer and get the chance value directly
		var cell_data = room.get_cell_tile_data(0,v)
		var chance: float = cell_data.get_custom_data("chance")
		var cell_source_id : int = room.get_cell_source_id(0,v)
		var atlas_coords : Vector2i = room.get_cell_atlas_coords(0,v)
#		if room.get_cell_source_id(0,v) != 0:
#			print("cell id {0}".format("0":str(room.get_cell_source_id(0,v)))
#		if _rng.randf() > mapping.chance:
		if _rng.randf() > chance:
			continue
		
		# even the tree is a single tile now, so no need to do this for loop dance
#		for x in range(mapping.size.x):
#			for y in range(mapping.size.y):
#		data.tilemap.push_back({"offset": v + Vector2i(x, y), "cell": cell_data})
		# but we need to take care of the atlas now
		data.tilemap.push_back({"offset": v, "cell": cell_source_id, "atlas_coords": atlas_coords})
	return data
