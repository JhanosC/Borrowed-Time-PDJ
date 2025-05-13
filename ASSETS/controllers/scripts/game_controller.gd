class_name GameController extends Node

@export var world_3d: Node3D
@export var world_2d: Node2D
@export var gui: Control

var current_3d_scene
var current_2d_scene
var current_gui_scene
var current_3d_scene_path : String

func _ready() -> void:
	Global.game_controller = self
	current_gui_scene = $GUI/SplashScreenManager
	current_3d_scene = $World3D/Main

func change_gui_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
	if current_gui_scene != null:
		if delete:
			current_gui_scene.queue_free()
		elif keep_running:
			current_gui_scene.visible = false
		else:
			gui.remove_child(current_gui_scene)
	var new = load(new_scene).instantiate()
	gui.add_child(new)
	current_gui_scene = new

func change_3d_scene(new_scene: String, delete: bool = true, keep_running: bool = false) -> void:
	if current_3d_scene != null:
		if delete:
			current_3d_scene.queue_free()
		elif keep_running:
			current_3d_scene.visible = false
		else:
			world_3d.call_deferred("remove_child", current_3d_scene)
	var new = load(new_scene).instantiate()
	world_3d.add_child(new)
	current_3d_scene = new

func new_change_3d_scene(new_scene: String):
	if(current_3d_scene_path == new_scene):
		get_tree().call_deferred("reload_current_scene")
	current_3d_scene_path = new_scene
	get_tree().call_deferred("change_scene_to_file", new_scene)
