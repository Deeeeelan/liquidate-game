extends Area2D


var activated = false

func _ready() -> void:
	self.body_entered.connect(func(body: Node2D):
		if body == %Character and not activated:
			activated = true
			%TruckShow.visible = true
			GameManager.game_started = true
	)
