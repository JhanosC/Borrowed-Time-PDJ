extends Node

var reset_count: int = 0
var level_time: float = 0.0

func reset_stats():
	reset_count = 0
	level_time = 0

func _process(delta: float) -> void:
	level_time += delta * 1/Engine.time_scale

func rank_level()-> String:
	if reset_count <= 5 and level_time <= 60:
		return "S"
	elif reset_count > 10 or level_time > 60:
		return "A"
	elif reset_count > 15 or level_time >= 90:
		return "B"
	elif reset_count > 20 or level_time > 120:
		return "C"
	elif reset_count > 25 or level_time > 180:
		return "D"
	elif reset_count > 30 or level_time > 200:
		return "E"
	else:
		return "F"
