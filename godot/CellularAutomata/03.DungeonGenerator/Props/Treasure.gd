extends Area2D

signal treasure_collected


func _on_body_shape_entered(_body_id, _body, _body_shape, _local_shape):
	emit_signal("treasure_collected")

	queue_free()
