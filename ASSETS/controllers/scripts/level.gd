class_name Level extends Node3D

@export var player:CharacterBody3D
@export var door:Door
@onready var spawn_point: Marker3D = $SpawnPoint

var data:LevelDataHandoff

func enter_level() -> void:
	init_player_location()
	_connect_to_doors()
#
func init_player_location():
	player.position = spawn_point.position

func _on_player_entered_door(door2:Door) -> void:
	_disconnect_from_doors()
	player.queue_free()
	data = LevelDataHandoff.new()
	data.entry_door_name = door2.entry_door_name
	set_process(false)

func _connect_to_doors() -> void:
	if not door.player_entered_door.is_connected(_on_player_entered_door):
		door.player_entered_door.connect(_on_player_entered_door)
			
func _disconnect_from_doors() -> void:
	if door.player_entered_door.is_connected(_on_player_entered_door):
		door.player_entered_door.disconnect(_on_player_entered_door)
