extends ProjectileEmitter


var projectile := preload("BasicProjectile.tscn")

var registry: ObjectRegistry
onready var timer := $Timer


func _ready() -> void:
	var registry_array := get_tree().get_nodes_in_group("object_registry")
	if registry_array.size() > 0:
		registry = registry_array[0]


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("fire") and timer.is_stopped():
		fire()
		timer.start(1.0 / projectiles_per_second)


func _do_fire(_direction: Vector2, _motions: Array, _lifetime: float) -> void:
	if not registry:
		return
	
	var new_projectile := projectile.instance()
	new_projectile.setup(global_position, _direction, _motions, _lifetime)
	registry.add_projectile(new_projectile)
	
	var _error := new_projectile.connect("collided", self, "_on_projectile_collided")
