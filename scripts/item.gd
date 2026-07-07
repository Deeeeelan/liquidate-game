extends Area2D

@export var value: int = 100
@export var sprite: AtlasTexture
@export var rare: bool = false

func _ready() -> void:
	$Sprite2D.texture = sprite


func _process(delta: float) -> void:
	pass
