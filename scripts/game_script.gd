extends Node

var minute_left = false
var game_ending = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GameTimer.timeout.connect(func():
		if GameManager.game_started:
			if GameManager.time_left <= 0 and not game_ending:
				game_ending = true
				var tween = get_tree().create_tween()
				tween.tween_property($CanvasLayer/Control/ColorRect, "color", Color("000000ff"), 3.0)
				tween.play()
				await tween.finished
				Engine.time_scale = 0.0
				%Stats.visible = true
				var score_text = "Money Liquidated:\n" + str(GameManager.score) + "/10000000\n"
				score_text += "Congratulations!" if GameManager.score > 10000000 else "yeah... you might get fired\n\n(hint: take more valuable things!)"
				%ScoreText.text = score_text
			elif not game_ending:
				GameManager.time_left -= 1
			if GameManager.time_left <= 60 * 5:
				%Sell.visible = false
				%Grab.visible = false
			if GameManager.time_left <= 60 and not minute_left:
				minute_left = true
				var tween = get_tree().create_tween()
				tween.tween_property($CanvasLayer/Control/ColorRect, "color", Color("e9000017"), 3.0)
				tween.play()

				
	)
