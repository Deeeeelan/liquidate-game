extends TextureRect

func _ready():
	$Timer.timeout.connect(func():
		rotation_degrees = randi_range(-6, 6)
		scale = Vector2.ONE * randf_range(0.92, 1.08)
	)
