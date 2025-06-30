extends Control

@onready var main = $".."


func _get_door_path() -> String:
	var level = Global.game_controller.current_3d_scene
	if not level:
		return ""
	for child in level.get_children():
		if child is Door:
			return child.path_to_new_scene
	return ""

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
	var next_path = _get_door_path()
	if next_path != "":
		Global.game_controller.load_new_scene(next_path)
	else:
		print("Failure: no Door selected")
	StatsMan.reset_stats()
	main.end_level()

func _on_continue_pressed() -> void:
	main.end_level()

func _on_quit_pressed() -> void:
	get_tree().quit()
