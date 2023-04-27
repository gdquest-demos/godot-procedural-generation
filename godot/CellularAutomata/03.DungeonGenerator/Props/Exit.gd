extends Area2D

signal miner_entered


func _on_body_shape_entered(_body_id, _body, _body_shape, _local_shape):
	miner_entered.emit()
