extends WorldGenerator

export var sector_margin_proportion := 0.1
export var sub_sector_margin_proportion := 0.1

var margined_sub_sector_size: Vector2
var hash_gen := XXHash.new()

onready var sector_margin := sector_size * sector_margin_proportion
onready var sub_sector_size := sector_size - sector_margin * 2
onready var sub_sector_margin := sub_sector_size * sub_sector_margin_proportion

onready var grid_drawer := $GridDrawer
onready var player := $Player


func _ready() -> void:
	sub_sector_size -= sub_sector_margin * 2
	margined_sub_sector_size = Vector2(
		sub_sector_margin * 2 + sub_sector_size, sub_sector_margin * 2 + sub_sector_size
	)

	_generate()
	grid_drawer.setup(sector_size, sector_count)
	
	hash_gen.hash_seed = start_seed.hash()


func _physics_process(_delta: float) -> void:
	var sector_offset := Vector2.ZERO

	var sector_location := current_sector * sector_size

	if player.global_position.distance_squared_to(sector_location) > sector_size_square:
		sector_offset = (player.global_position - sector_location) / sector_size
		sector_offset.x = int(sector_offset.x)
		sector_offset.y = int(sector_offset.y)

		_update_sector(sector_offset)
		grid_drawer.move_grid_to(current_sector)


func _generate_at(x_id: int, y_id: int) -> void:
	if sectors.has(Vector2(x_id, y_id)):
		return

	rng.seed = hash_gen.get_hash_array([x_id, y_id])

	var top_left := Vector2(
		x_id * sector_size - half_sector_size + sector_margin,
		y_id * sector_size - half_sector_size + sector_margin
	)

	var sector_data := []
	var rolled_indices := []
