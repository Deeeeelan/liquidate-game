extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GameTimer.timeout.connect(func():
		GameManager.time_left -= 1
	)
