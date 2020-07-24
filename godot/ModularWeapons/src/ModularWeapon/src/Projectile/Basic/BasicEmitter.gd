extends ProjectileEmitter

var projectile := preload("BasicProjectile.tscn")

onready var timer := $Timer


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("fire") and timer.is_stopped():
		fire()
		timer.start(1.0 / projectiles_per_second)


func _do_fire(_direction: Vector2, _motions: Array, _lifetime: float) -> void:
	var new_projectile := projectile.instance()
	new_projectile.setup(global_position, _direction, _motions, _lifetime)
	ObjectRegistry.add_projectile(new_projectile)
