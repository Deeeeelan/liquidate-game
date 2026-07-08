extends Label
var state = false

func _ready() -> void:
	$Timer.timeout.connect(func():
		if GameManager.time_left <= 60:
			if state:
				label_settings.font_color = Color(0.0, 0.0, 0.0, 1.0)
			else:
				label_settings.font_color = Color(1.0, 0.0, 0.0, 1.0)
			state = not state
	)
