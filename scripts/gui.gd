extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$VBoxContainer/Score.text = "$" + str(GameManager.score)
	$VBoxContainer/Timer.text = str(GameManager.time_left / 60) + ":" +  ("0" if GameManager.time_left % 60 <= 9 else "") + str(GameManager.time_left % 60)
