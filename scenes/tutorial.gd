extends Area2D

@export var texture: Texture2D
var activated = false

func _ready() -> void:
	self.body_entered.connect(func(body: Node2D):
		if body == %Character and not activated:
			activated = true
			%ControlTex.texture = texture
			%ControlTex.modulate = Color(1.0, 1.0, 1.0, 0.0)
			var tween = get_tree().create_tween()
			tween.tween_property(%ControlTex, "modulate", Color(1.0, 1.0, 1.0, 1.0), 2.0)
			tween.tween_interval(6.0)
			tween.tween_property(%ControlTex, "modulate", Color(1.0, 1.0, 1.0, 0.0), 2.0)
			tween.play()
	)
