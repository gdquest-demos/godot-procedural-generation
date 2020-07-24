class_name WorldGenerator
extends Node2D

enum { AXIS_X, AXIS_Y }

export var sector_size := 1000.0
export var sector_count := 10
export var start_seed := "world_generation"

var rng := RandomNumberGenerator.new()
var sectors := {}
var current_sector := Vector2.ZERO

onready var half_sector_size := sector_size / 2.0
onready var sector_size_square := sector_size * sector_size
onready var half_sector_count := sector_count / 2


func _generate() -> void:
	for x in range(-half_sector_count, half_sector_count):
		for y in range(-half_sector_count, half_sector_count):
			_generate_at(x, y)


func _generate_at(_x_id: int, _y_id: int) -> void:
	pass


func _update_sector(difference: Vector2) -> void:
	_update_along_axis(AXIS_X, difference.x)
	_update_along_axis(AXIS_Y, difference.y)


func _update_along_axis(axis: int, difference: float) -> void:
	if axis != AXIS_X and axis != AXIS_Y:
		return

	var axis_current := current_sector.x if axis == AXIS_X else current_sector.y
	var other_axis_min := (
		(current_sector.y if axis == AXIS_X else current_sector.x)
		- half_sector_count
	)
	var other_axis_max := (
		(current_sector.y if axis == AXIS_X else current_sector.x)
		+ half_sector_count
	)
	var axis_mod: int = max(difference, 0) != 0

	for s in range(1, abs(difference) + 1):
		var axis_key := int(
			(
				axis_current
				+ (half_sector_count - axis_mod) * sign(difference)
				+ (s * sign(difference))
			)
		)

		for other in range(other_axis_min, other_axis_max):
			var x_key := axis_key if axis == AXIS_X else other
			var y_key := other if axis == AXIS_X else axis_key
			_generate_at(x_key, y_key)

		axis_key = int(axis_key + sector_count * -sign(difference))

		for other in range(other_axis_min, other_axis_max):
			var key := Vector2(
				axis_key if axis == AXIS_X else other, other if axis == AXIS_X else axis_key
			)

			if sectors.has(key):
				var sector_data: Array = sectors[key]
				for d in sector_data:
					d.queue_free()
				sectors.erase(key)

	if axis == AXIS_X:
		current_sector.x += difference
	else:
		current_sector.y += difference
