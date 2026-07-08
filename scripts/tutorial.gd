extends Area2D

@export var texture: Texture2D
@export var tw_time1: float = 2.0
@export var tw_time2: float = 4.0
@export var tw_time3: float = 2.0

var activated = false

func _ready() -> void:
	self.body_entered.connect(func(body: Node2D):
		if body == %Character and not activated:
			activated = true
			%ControlTex.texture = texture
			%ControlTex.modulate = Color(1.0, 1.0, 1.0, 0.0)
			var tween = get_tree().create_tween()
			tween.tween_property(%ControlTex, "modulate", Color(1.0, 1.0, 1.0, 1.0), tw_time1)
			tween.tween_interval(tw_time2)
			tween.tween_property(%ControlTex, "modulate", Color(1.0, 1.0, 1.0, 0.0), tw_time3)
			tween.play()
	)
