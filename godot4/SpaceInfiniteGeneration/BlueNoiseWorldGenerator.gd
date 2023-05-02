class_name BlueNoiseWorldGenerator
extends WorldGenerator

@export var Asteroid: PackedScene
@export var asteroid_density := 3
@export var sector_margin_proportion := 0.1
@export var subsector_margin_proportion := 0.1

@onready var _subsector_grid_width: int = ceil(sqrt(asteroid_density))
@onready var _subsector_count := _subsector_grid_width * _subsector_grid_width

@onready var _sector_margin := sector_size * sector_margin_proportion
@onready var _subsector_base_size := (sector_size - _sector_margin * 2) / _subsector_grid_width
@onready var _subsector_margin := _subsector_base_size * subsector_margin_proportion
@onready var _subsector_size := _subsector_base_size - _subsector_margin * 2

@onready var _grid_drawer := $GridDrawer
@onready var _player := $Player


func _ready() -> void:
	generate()
	_grid_drawer.setup(sector_size, sector_axis_count)


func _physics_process(_delta: float) -> void:
	var sector_offset := Vector2.ZERO
	var sector_location := _current_sector * sector_size
	if _player.global_position.distance_squared_to(sector_location) > _sector_size_squared:
		sector_offset = (_player.global_position - sector_location) / sector_size
		sector_offset.x = int(sector_offset.x)
		sector_offset.y = int(sector_offset.y)

		_update_sectors(sector_offset)
		_grid_drawer.move_grid_to(_current_sector)


func _generate_sector(x_id: int, y_id: int) -> void:
	_rng.seed = make_seed_for(x_id, y_id)
	seed(_rng.seed)

	var sector_top_left := Vector2(
		x_id * sector_size - _half_sector_size + _sector_margin,
		y_id * sector_size - _half_sector_size + _sector_margin
	)

	var sector_data := []
	var sector_indices = range(_subsector_count)
	sector_indices.shuffle()

	for i in range(asteroid_density):
		var x := int(sector_indices[i] / _subsector_grid_width)
		var y: int = sector_indices[i] - x * _subsector_grid_width

		var asteroid := Asteroid.instantiate()
		add_child(asteroid)
		asteroid.position = _generate_random_position(Vector2(x, y), sector_top_left)
		asteroid.rotation = _rng.randf_range(-PI, PI)
		asteroid.scale *= _rng.randf_range(0.2, 1.0)
		sector_data.append(asteroid)

	_sectors[Vector2(x_id, y_id)] = sector_data


func _generate_random_position(subsector_coordinates: Vector2, sector_top_left: Vector2) -> Vector2:
	var subsector_top_left := (
		sector_top_left
		+ Vector2(_subsector_base_size, _subsector_base_size) * subsector_coordinates
		+ Vector2(_subsector_margin, _subsector_margin)
	)
	var subsector_bottom_right := subsector_top_left + Vector2(_subsector_size, _subsector_size)
	return Vector2(
		_rng.randf_range(subsector_top_left.x, subsector_bottom_right.x),
		_rng.randf_range(subsector_top_left.y, subsector_bottom_right.y)
	)
