extends CharacterBody2D

@export var drag_linear_coeff := 0.05
@export var drag_angular_coeff : float = 0.1

var acceleration_max := 1200.0
var linear_speed_max := 540.0
var angular_speed_max := 200
var angular_acceleration_max := 1800

var linear_velocity := Vector2.ZERO
var angular_velocity : float = 0.0

@onready var weapons := $ModularWeaponsSystem


func _ready() -> void:
	weapons.connect("damaged", _on_Weapons_damaged)


func _physics_process(delta: float) -> void:
	var movement := _calculate_move_factor()
	var direction := Vector2(sin(-rotation), cos(rotation))

	linear_velocity = (linear_velocity + movement.y * direction * acceleration_max * delta).limit_length(
		linear_speed_max
	)
	if is_equal_approx(movement.y, 0.0):
		linear_velocity = linear_velocity.lerp(Vector2.ZERO, drag_linear_coeff)

	var angular_speed_max_rad := deg_to_rad(angular_speed_max)
	angular_velocity = clamp(
		angular_velocity + movement.x * deg_to_rad(angular_acceleration_max) * delta,
		-angular_speed_max_rad,
		angular_speed_max_rad
	)
	if is_equal_approx(movement.x, 0.0):
		angular_velocity = lerp(angular_velocity, 0.0, drag_angular_coeff)

	set_velocity(linear_velocity)
	move_and_slide()
	linear_velocity = velocity
	rotation += angular_velocity * delta

	#convenience function
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()


func _calculate_move_factor() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("back") - Input.get_action_strength("forwards")
	)


func _on_Weapons_damaged(_target: Node, _damage: int) -> void:
	print("%s took %s damage." % [_target, _damage])
