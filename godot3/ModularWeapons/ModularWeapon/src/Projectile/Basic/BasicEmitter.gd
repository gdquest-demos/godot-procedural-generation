extends ProjectileEmitter


var projectile := preload("BasicProjectile.tscn")

onready var timer := $Timer


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("fire") and timer.is_stopped():
		fire()
		timer.start(1.0 / projectiles_per_second)


# Spawns and configures a basic projectile scene and connects to its signals.
func _do_fire(_direction: Vector2, _motions: Array, _lifetime: float) -> void:
	if not spawned_objects:
		return
	
	var new_projectile := projectile.instance()
	new_projectile.setup(global_position, _direction, _motions, _lifetime)
	spawned_objects.add_child(new_projectile)
	
	var _error := new_projectile.connect("collided", self, "_on_projectile_collided")
	_error = new_projectile.connect("missed", self, "_on_projectile_missed")
