extends Area2D

signal treasure_collected


func _on_body_shape_entered(_body_id, _body, _body_shape, _local_shape):
	treasure_collected.emit()
	queue_free()


# If treasure ever overlap, destroy them
func _on_area_entered(area):
	queue_free()
