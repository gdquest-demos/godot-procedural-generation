# Base class for worlds. It exposes functions for use by extensions, though the
# most important and central class is the _generate_at virtual function. This
# is where the information for any given sector should be generated.
# @tags - abstract
class_name WorldGenerator
extends Node2D

enum { AXIS_X, AXIS_Y }


# How many pixels each square sector should cover
export var sector_size := 1000.0

# How many sectors along each axis
export var sector_count := 10

# The seed for the world to use when using a random generator
export var start_seed := "world_generation"

# Random number generator to generate sectors with
var rng := RandomNumberGenerator.new()

# The dictionary containing sector data.
var sectors := {}

# The current sector we are in, in integers
var current_sector := Vector2.ZERO

onready var half_sector_size := sector_size / 2.0
onready var sector_size_square := sector_size * sector_size
onready var half_sector_count := int(sector_count / 2.0)


# Calls _generate_at for each currently exposed sectors around the player.
func generate() -> void:
	for x in range(-half_sector_count, half_sector_count):
		for y in range(-half_sector_count, half_sector_count):
			_generate_at(x, y)


func make_seed_for(_x_id: int, _y_id: int, custom_data := "") -> int:
	var reset_seed := "%s_%s_%s" % [start_seed, _x_id, _y_id]
	if not custom_data.empty():
		reset_seed = "%s_%s" % [reset_seed, custom_data]
	return reset_seed.hash()


# Moves the `current_sector` variable by difference, generates sectors that
# come into bounds and erases sectors that go out of bounds.
func _update_sector(difference: Vector2) -> void:
	_update_along_axis(AXIS_X, difference.x)
	_update_along_axis(AXIS_Y, difference.y)


# Virtual function that governs how any given sector should be generated based
# on its position in the world array.
# @tags - virtual
func _generate_at(_x_id: int, _y_id: int) -> void:
	pass


# Travels along an axis and a direction, erasing sectors that go outside the
# half the sector count width, and adding new sectors that come into this range.
func _update_along_axis(axis: int, difference: float) -> void:
	if difference == 0 or (axis != AXIS_X and axis != AXIS_Y):
		return

	# Find the current sector's row/column
	var axis_current := current_sector.x if axis == AXIS_X else current_sector.y
	
	# Find the edges of the row/column, perpendicular to the axis we're updating
	var other_axis_min := (
		(current_sector.y if axis == AXIS_X else current_sector.x)
		- half_sector_count
	)
	var other_axis_max := (
		(current_sector.y if axis == AXIS_X else current_sector.x)
		+ half_sector_count
	)
	
	# Because 0 is technically negative when comparing signs, we end up with
	# 1 more sector when moving in the negative direction than the positive one.
	# So when difference is positive, we end up in situations where sectors
	# aren't erased or added on time. This modifier is there to catch those
	# cases. It's 1 when positive, 0 otherwise, so we have an even count
	# on both positive and negative.
	var axis_modifier: int = difference > 0

	# For each row/column between where we were and where we are now
	for sector_index in range(1, abs(difference) + 1):
		var axis_key := int(
			(
				axis_current
				+ (half_sector_count - axis_modifier) * sign(difference)
				+ (sector_index * sign(difference))
			)
		)

		# Generate a new entire row/column depending on how we're moving.
		for other in range(other_axis_min, other_axis_max):
			var x_key := axis_key if axis == AXIS_X else other
			var y_key := other if axis == AXIS_X else axis_key
			_generate_at(x_key, y_key)

		# Reduce the key by the sector count so we are referencing the 
		# opposite end of the grid.
		axis_key = int(axis_key + sector_count * -sign(difference))

		# Erase the entire row/column.
		for other in range(other_axis_min, other_axis_max):
			var key := Vector2(
				axis_key if axis == AXIS_X else other, other if axis == AXIS_X else axis_key
			)

			if sectors.has(key):
				var sector_data: Array = sectors[key]
				for d in sector_data:
					d.queue_free()
				var _found := sectors.erase(key)

	# Update the current sector for later reference
	if axis == AXIS_X:
		current_sector.x += difference
	else:
		current_sector.y += difference
