extends Button

var game_path = "res://scenes/game.tscn"

func _pressed() -> void:
	get_tree().change_scene_to_file(game_path)
