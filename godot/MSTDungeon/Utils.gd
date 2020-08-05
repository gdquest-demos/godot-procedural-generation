class_name MSTDungeonUtils


const UNCERTAINTY := 1e-2
const DELAUNAY_STRIDE := 3


static func get_rng_point_in_circle(rng: RandomNumberGenerator, radius: float) -> Vector2:
	return get_rng_point_in_ellipse(rng, radius, radius)


static func get_rng_point_in_ellipse(rng: RandomNumberGenerator, width: float, height: float) -> Vector2:
	var t := 2 * PI * rng.randf()
	var u := rng.randf() + rng.randf()
	var r := 2 - u if u > 1 else u
	return r * Vector2(width * cos(t), height * sin(t))


static func roundm(n: float, m: float) -> int:
	return int(floor((n + m - 1) / m) * m)


# Tests for approximate equality between two `Vector2`, allowing you to specify an absolute 
# error margin.
static func is_approx_equal(v1: Vector2, v2: Vector2, error: float = UNCERTAINTY) -> bool:
	return abs(v1.x - v2.x) < error and abs(v1.y - v2.y) < error


# Converts an `Array` generated with `Geometry.triangulate_delaunay_2d()` to an adjacency list.
static func delaunay_to_connections(delaunay: Array) -> Dictionary:
	var out := {}
	for index in range(0, delaunay.size(), DELAUNAY_STRIDE):
		for i in range(index, index + DELAUNAY_STRIDE):
			if not out.has(delaunay[i]):
				out[delaunay[i]] = {}
			
			for j in range(index, index + DELAUNAY_STRIDE):
				if i != j:
					out[delaunay[i]][delaunay[j]] = null
	return out


# Calculates the Minimum Spanning Tree (MST) for 2D data points.
#
# `points`: Array
#           `Vector2` positions corresponding to `connections`
# `connections`: Dictionary
#                Adjacency list with indices as IDs for positions in `points`. Eg.:
#                ```
#                connections = {0: [1, 2], 1: [0], 2: [0]}
#                # or
#                connections = {0: {1: null, 2: null}, 1: {0: null}, 2: {0: null}}
#                ```
#                is an adjacency list where `points[0]` is connected to `points[1]` and `points[2]`.
#
# Returns an `AStar2D` with points and connections representing the MST.
static func mst(points: Array, connections: Dictionary) -> AStar2D:
	var out := AStar2D.new()
	if connections.size() > 2:
		connections = connections.duplicate()
		var point_id: int = connections.keys()[0]
		out.add_point(point_id, points[point_id])
		
		while out.get_point_count() != points.size():
			var min_distance := INF
			var min_point1_id := -1
			var min_point2_id := -1
			for point1_id in out.get_points():
				for point2_id in connections[point1_id]:
					var distance: float = points[point1_id].distance_to(points[point2_id])
					if min_distance > distance:
						min_distance = distance
						min_point1_id = point1_id
						min_point2_id = point2_id
			
			if min_point1_id == min_point2_id:
				continue
			
			out.add_point(min_point2_id, points[min_point2_id])
			out.connect_points(min_point1_id, min_point2_id)
			
			connections[min_point1_id].erase(min_point2_id)
			connections[min_point2_id].erase(min_point1_id)
	elif connections.size() == 2:
		var point_ids := connections.keys()
		out.add_point(point_ids[0], points[point_ids[0]])
		out.add_point(point_ids[1], points[point_ids[1]])
		out.connect_points(point_ids[0], point_ids[1])
	
	return out


# Removes points and connections from the `connections` dictionary based on `factor`.
static func cull_points_by(rng: RandomNumberGenerator, connections: Dictionary, factor: float) -> void:
	var connections_size := connections.size()
	var cull_threshold = int((1 - factor) * connections_size)

	while connections.size() > cull_threshold:
		var index := rng.randi_range(0, connections.size() - 1)
		var point1: int = connections.keys()[index]
		
		connections.erase(point1)
		for point2 in connections:
			connections[point2].erase(point1)


static func index_to_xy(width: int, index: int) -> Vector2:
	return Vector2(index % width, index / width)
