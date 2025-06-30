extends Control

@onready var main = $".."
var next_level_path : String

func _ready() -> void:
	hide()

func set_next_path(path_to_new_scene) -> void:
	next_level_path = path_to_new_scene

func get_stats():
	var resets = StatsMan.reset_count
	var time = StatsMan.level_time
	var rank = StatsMan.rank_level()
	display_stats(resets,time,rank)
	

func display_stats(reset_count: int,level_time: float,rank: String):
	$PanelContainer/VBoxContainer/ResetsLabel.text = "Resets: %d" % reset_count
	$PanelContainer/VBoxContainer/TimeLabel.text = "Time in Level: %.2f s"% level_time
	$PanelContainer/VBoxContainer/RankLabel.text = "Rank in Level: %s" % rank
	

func _on_next_level_pressed() -> void:
	if next_level_path != "":
		Global.game_controller.load_new_scene(next_level_path)
	else:
		print("Failure: no Door selected")
	StatsMan.reset_stats()
	main.resume_level()

func _on_continue_pressed() -> void:
	main.end_level()

func _on_quit_pressed() -> void:
	get_tree().quit()
