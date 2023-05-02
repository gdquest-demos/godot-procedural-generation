extends ProjectileEmitter


@export var collisions_per_second := 4

var is_firing := false
var current_lifetime := 0.0

@onready var tracer := $LaserTracer
@onready var laser_line := $Line2D
@onready var timer := $Timer
@onready var casting_particles := $CastingParticles


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("fire"):
		is_firing = false
		var points: Array = laser_line.points
		for i in range(1, 10):
			current_lifetime = float(projectile_lifetime / i)
			await get_tree().physics_frame

		laser_line.points = []
		tracer.hide()
		tracer.position = Vector2.ZERO
		tracer._miss()
		casting_particles.emitting = false


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("fire"):
		fire()

		current_lifetime = min(
			current_lifetime + _delta * projectile_lifetime * 8, projectile_lifetime
		)

	laser_line.width = current_lifetime / projectile_lifetime * 10

	if is_firing:
		var points: Array = tracer.trace_path(current_lifetime)
		laser_line.points = points


# Resets the persistent tracer's properties and position. Also keeps the direction
# vector up to date with the emitter's rotation.
func _do_fire(_direction: Vector2, _motions: Array, _lifetime: float) -> void:
	if not is_firing:
		is_firing = true
		current_lifetime = 0.0
		tracer.show()
		casting_particles.emitting = true
	tracer.setup(global_position, Vector2.UP.rotated(global_rotation), _motions, _lifetime)


# Triggers the damage signal only when the DPS timer is not running.
func _on_projectile_collided(target: Node, _hit_location: Vector2) -> void:
	if timer.is_stopped():
		super(target, _hit_location)
		timer.start(1.0 / float(collisions_per_second))
