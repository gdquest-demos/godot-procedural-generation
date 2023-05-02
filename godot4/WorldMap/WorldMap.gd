extends Control


var _rng := RandomNumberGenerator.new()

@onready var viewer: ColorRect = $Viewer
@onready var post_proces: ColorRect = $PostProcess


func _ready() -> void:
	_rng.randomize()
	generate()


# Generates a new world map and feeds textures into the viewer's shader.
func generate() -> void:
	var color_map: GradientTexture2D = viewer.material.get_shader_parameter("color_map")
	var height_map: Texture2D = viewer.material.get_shader_parameter("height_map")
	var heat_map: NoiseTexture2D = viewer.material.get_shader_parameter("heat_map")
	var moisture_map: NoiseTexture2D = viewer.material.get_shader_parameter("moisture_map")

	height_map.noise.seed = _rng.randi()
	heat_map.noise.seed = _rng.randi()
	moisture_map.noise.seed = _rng.randi()

	height_map = domain_warp(height_map, 10, 0.15)
	var rivers_level := Vector2(color_map.gradient.offsets[1], color_map.gradient.offsets[-2])
	var rivers_map := WorldMapRiverGenerator.generate_rivers(_rng, height_map, 10, rivers_level)
	var heat_map_minmax := WorldMapUtils.get_minmax_noise(heat_map)
	var moisture_map_minmax := WorldMapUtils.get_minmax_noise(moisture_map)
	heat_map_minmax = WorldMapUtils.normalize_noise_vector2(heat_map_minmax)
	moisture_map_minmax = WorldMapUtils.normalize_noise_vector2(moisture_map_minmax)

	viewer.material.set_shader_parameter("color_map", discrete(color_map))
	viewer.material.set_shader_parameter("color_map_offsets", to_sampler2D(color_map.gradient.offsets))
	viewer.material.set_shader_parameter("color_map_offsets_n", color_map.gradient.offsets.size())
	viewer.material.set_shader_parameter("height_map", height_map)
	viewer.material.set_shader_parameter("rivers_map", rivers_map)
	viewer.material.set_shader_parameter("heat_map_minmax", heat_map_minmax)
	viewer.material.set_shader_parameter("moisture_map_minmax", moisture_map_minmax)

	post_proces.material.set_shader_parameter("resolution", get_viewport().size)


# Uses the 2D noise value as z-axis in the 3D noise function to generate a more realistic
# height map.
# size is a built in property of Control and therefore I needed to rename it here
func domain_warp(nt: NoiseTexture2D, strength: float, _size: float) -> ImageTexture:
	var out : ImageTexture
	strength = max(0, strength)
	_size = max(0, _size)
	
	var data := []
	var minmax := Vector2(INF, -INF)
	for x in range(nt.width):
		for y in range(nt.height):
			var value := strength * nt.noise.get_noise_2d(_size * x, _size * y)
			value = nt.noise.get_noise_3d(x, y, value)
			minmax.x = min(minmax.x, value)
			minmax.y = max(minmax.y, value)
			data.push_back(value)
	
	var bytes = StreamPeerBuffer.new()
	for d in data:
		bytes.put_float(remap(d, minmax.x, minmax.y, 0, 1))
	
	var image := Image.create_from_data(nt.width, nt.height, false, Image.FORMAT_RF, bytes.data_array)
	out = ImageTexture.create_from_image(image) #,0
	
	return out


# Converts a smooth gradient to a discrete texture, that is to say,
# a texture with hard color transitions.
func discrete(gt: GradientTexture2D) -> ImageTexture:
	var out : ImageTexture

	var image := Image.create(gt.width, 1, false, Image.FORMAT_RGBA8)
	var point_count := gt.gradient.get_point_count()

	for index in (point_count - 1) if point_count > 1 else point_count:
		var offset1: float = gt.gradient.offsets[index]
		var offset2: float = gt.gradient.offsets[index + 1] if point_count > 1 else 1
		var color: Color = gt.gradient.colors[index]
		for x in range(gt.width * offset1, gt.width * offset2):
			image.set_pixel(x, 0, color)
	out = ImageTexture.create_from_image(image) #,0

	return out


# Converts an array of floating point values to an ImageTexture, to sample with a shader.
func to_sampler2D(array: PackedFloat32Array) -> ImageTexture:
	var bytes := StreamPeerBuffer.new()
	for x in array:
		bytes.put_float(x)
	
	var image := Image.create_from_data(array.size(), 1, false, Image.FORMAT_RF, bytes.data_array)
	
	var out := ImageTexture.create_from_image(image) #,0
	return out
