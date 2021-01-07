## Abstract base class for worlds.
##
## Splits the world into `_sectors` of a fixed size in pixels. You can think of
## the world as a grid of square _sectors.
## Exposes functions for extended classes to use, though the central part is the
## `_generate_at()` virtual method. This is where you should generate the
## content of individual _sectors.
##
## @tags - abstract
class_name WorldGenerator
extends Node2D

enum { AXIS_X, AXIS_Y }

## Size of a sector in pixels.
export var sector_size := 1000.0
## Number of _sectors to generate around the player on a given axis.
export var sector_axis_count := 10
## Seed to generate the world. We use a hash function to convert it to a number.
## Allows players and developers to save specific worlds and generate them from a name.
export var start_seed := "world_generation"

## The dictionary containing sector data.
var _sectors := {}
## Coordinates of the sector the player currently is in. We use it to generate _sectors around the player.
var _current_sector := Vector2.ZERO
var _rng := RandomNumberGenerator.new()

## Half of `sector_size`.
onready var _half_sector_size := sector_size / 2.0
## Total number of _sectors to generate around the player.
onready var _total_sector_count := sector_size * sector_size
onready var _half_sector_count := int(sector_axis_count / 2.0)


## Calls _generate_at for each currently exposed _sectors around the player.
func generate() -> void:
	for x in range(-_half_sector_count, _half_sector_count):
		for y in range(-_half_sector_count, _half_sector_count):
			_generate_at(x, y)


## Creates an ascii seed with the format "seed_x_y" and returns it as an integer
## hash suitable for `RandomNumberGenerator`'s `seed` property
func make_seed_for(_x_id: int, _y_id: int, custom_data := "") -> int:
	var reset_seed := "%s_%s_%s" % [start_seed, _x_id, _y_id]
	if not custom_data.empty():
		reset_seed = "%s_%s" % [reset_seed, custom_data]
	return reset_seed.hash()


## Moves the `_current_sector` variable by difference, generates _sectors that
## come into bounds and erases _sectors that go out of bounds.
func _update_sectors(difference: Vector2) -> void:
	_update_along_axis(AXIS_X, difference.x)
	_update_along_axis(AXIS_Y, difference.y)


## Virtual function that governs how any given sector should be generated based
## on its position in the world array.
## @tags - virtual
func _generate_at(_x_id: int, _y_id: int) -> void:
	pass


## Travels along an axis and a direction, erasing _sectors that go outside the
## half the sector count width, and adding new _sectors that come into this range.
func _update_along_axis(axis: int, difference: float) -> void:
	if difference == 0 or (axis != AXIS_X and axis != AXIS_Y):
		return

	# Find the current sector's row or column
	var axis_current := _current_sector.x if axis == AXIS_X else _current_sector.y

	# Find the range of coordinates of the row or column perpendicular to the axis we're updating.
	var other_axis_position := _current_sector.y if axis == AXIS_X else _current_sector.x
	var other_axis_min := other_axis_position - _half_sector_count
	var other_axis_max := other_axis_position + _half_sector_count

	# Because 0 is technically negative when comparing signs, we end up with
	# 1 more sector when moving in the negative direction than the positive one.
	# So when difference is positive, we end up in situations where _sectors
	# aren't erased or added on time. This modifier is there to catch those
	# cases. It's 1 when positive, 0 otherwise, so we have an even count
	# on both positive and negative.
	var axis_modifier := int(difference > 0)

	# For each row or column between where we were and where we are now
	for sector_index in range(1, abs(difference) + 1):
		var axis_key := int(
			(
				axis_current
				+ (_half_sector_count - axis_modifier) * sign(difference)
				+ (sector_index * sign(difference))
			)
		)

		# Generate a new entire row or column depending on how we're moving.
		for other_axis_coordinate in range(other_axis_min, other_axis_max):
			var x_key := axis_key if axis == AXIS_X else other_axis_coordinate
			var y_key := other_axis_coordinate if axis == AXIS_X else axis_key
			_generate_at(x_key, y_key)

		# Reduce the key by the sector count so we are referencing the 
		# opposite end of the grid.
		axis_key = int(axis_key + sector_axis_count * -sign(difference))

		# Erase the entire row or column.
		for other_axis_coordinate in range(other_axis_min, other_axis_max):
			var key := Vector2(
				axis_key if axis == AXIS_X else other_axis_coordinate, other_axis_coordinate if axis == AXIS_X else axis_key
			)

			if _sectors.has(key):
				var sector_data: Array = _sectors[key]
				for d in sector_data:
					d.queue_free()
				var _found := _sectors.erase(key)

	# Update the current sector for later reference
	if axis == AXIS_X:
		_current_sector.x += difference
	else:
		_current_sector.y += difference
