class_name MSTDungeonUtils


const UNCERTAINTY := 0.01


static func get_rng_point_in_circle(rng: RandomNumberGenerator, radius: float) -> Vector2:
	return get_rng_point_in_ellipse(rng, radius, radius)


static func get_rng_point_in_ellipse(rng: RandomNumberGenerator, width: float, height: float) -> Vector2:
	# Get a random number in [0, 2PI].
	var t := 2 * PI * rng.randf()
	# Adding two random numbers allows us to get a uniform distribution of points in the ellipse.
	var u := rng.randf() + rng.randf()
	# Calculate a random factor in [0, 1].
	var r := 2 - u if u > 1 else u
	# Calculate the coordinates of the point in the ellipse.
	return r * Vector2(width * cos(t), height * sin(t))


# Tests for approximate equality between two `Vector2`, allowing you to specify an absolute
# error margin.
static func is_approx_equal(v1: Vector2, v2: Vector2, error: float = UNCERTAINTY) -> bool:
	return abs(v1.x - v2.x) < error and abs(v1.y - v2.y) < error


# Calculates the Minimum Spanning Tree (MST) for given points and returns an `AStar2D` graph
# using Prim's algorithm.
static func mst(points: Array) -> AStar2D:
	var out := AStar2D.new()
	# Start from an arbitrary point in the list of points
	out.add_point(out.get_available_point_id(), points.pop_back())

	# Loop through all points, erasing them as we connect them.
	while not points.is_empty():
		var current_position := Vector2.ZERO
		var min_position := Vector2.ZERO
		var min_distance := INF

		for point1_id in out.get_point_ids():
			# Compare each point added to the `Astar2D` graph
			# to each remaining point to find the closest one.
			var point1_position = out.get_point_position(point1_id)
			for point2_position in points:
				var distance: float = point1_position.distance_to(point2_position)
				if min_distance > distance:
					# We use the variables to store the coordinates of the closest point.
					# We have to loop over all points to ensure it's the closest.
					current_position = point1_position
					min_position = point2_position
					min_distance = distance

		# Connect the point closest to `current_position` with our new point.
		var point_id := out.get_available_point_id()
		out.add_point(point_id, min_position)
		out.connect_points(out.get_closest_point(current_position), point_id)
		points.erase(min_position)

	return out


static func index_to_xy(width: int, index: int) -> Vector2:
	return Vector2(index % width, index / width)
