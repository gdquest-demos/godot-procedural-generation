extends Control

signal step_time_changed(time)
signal wall_chance_changed(value)
signal wall_conversion_changed(value)
signal floor_conversion_changed(value)
signal step_count_changed(value)
signal maximum_treasure_changed(value)
signal min_cavern_area_changed(value)
signal min_exit_distance_changed(value)

@onready var button_generate := $ButtonGenerate
@onready var step_time_value := $StepSpeed/Value
@onready var wall_chance_value := $WallChance/Value
@onready var wall_conversion_value := $WallConversion/Value
@onready var floor_conversion_value := $FloorConversion/Value
@onready var step_count_value := $StepCount/Value


func _on_SliderStepSpeed_value_changed(value: float) -> void:
	step_time_value.text = "%s" % [value]
	step_time_changed.emit(value)


func _on_SliderWallChance_value_changed(value) -> void:
	wall_chance_value.text = "%s" % [value]
	wall_chance_changed.emit(value)


func _on_SliderWallConversion_value_changed(value: int) -> void:
	wall_conversion_value.text = "< %s" % [value]
	wall_conversion_changed.emit(value)


func _on_SliderFloorConversion_value_changed(value: int) -> void:
	floor_conversion_value.text = "> %s" % [value]
	floor_conversion_changed.emit(value)


func _on_SliderStepCount_value_changed(value) -> void:
	step_count_value.text = "%s" % [value]
	step_count_changed.emit(value)
