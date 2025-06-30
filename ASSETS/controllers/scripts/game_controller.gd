class_name GameController extends Node

signal content_finished_loading(content)
signal content_invalid(content_path:String)
signal content_failed_to_load(content_path:String)

@onready var world_3d: Node3D = $World3D

var current_3d_scene

var _content_path:String
var _load_progress_timer:Timer

func _ready() -> void:
	current_3d_scene = $World3D/Level1
	Global.game_controller = self
	content_invalid.connect(on_content_invalid)
	content_failed_to_load.connect(on_content_failed_to_load)
	content_finished_loading.connect(on_content_finished_loading)

func load_new_scene(content_path:String) -> void:
	_load_content(content_path)
	

func _load_content(content_path:String) -> void:
	_content_path = content_path
	var loader = ResourceLoader.load_threaded_request(content_path)
	if not ResourceLoader.exists(content_path) or loader == null:
		content_invalid.emit(content_path)
		return
		
	_load_progress_timer = Timer.new()
	_load_progress_timer.wait_time = 0.1
	_load_progress_timer.timeout.connect(monitor_load_status)
	get_tree().root.add_child(_load_progress_timer)
	_load_progress_timer.start()

func monitor_load_status() -> void:
	var load_progress = []
	var load_status = ResourceLoader.load_threaded_get_status(_content_path, load_progress)

	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			content_invalid.emit(_content_path)
			_load_progress_timer.stop()
			return
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass
		ResourceLoader.THREAD_LOAD_FAILED:
			content_failed_to_load.emit(_content_path)
			_load_progress_timer.stop()
			return
		ResourceLoader.THREAD_LOAD_LOADED:
			if !is_instance_valid(_load_progress_timer): return
			_load_progress_timer.stop()
			_load_progress_timer.queue_free()
			content_finished_loading.emit(ResourceLoader.load_threaded_get(_content_path).instantiate())
			return # this last return isn't necessary but I like how the 3 dead ends stand out as similar

func on_content_failed_to_load(path:String) -> void:
	printerr("error: Failed to load resource: '%s'" % [path])	

func on_content_invalid(path:String) -> void:
	printerr("error: Cannot load resource: '%s'" % [path])

func on_content_finished_loading(content) -> void:
	#var outgoing_scene = get_tree().current_scene
	world_3d.call_deferred("remove_child", current_3d_scene)

	# Remove the old scene
	#outgoing_scene.queue_free()
	
	# Add and set the new scene to current
	#get_tree().root.call_deferred("add_child",content)
	world_3d.call_deferred("add_child",content)
	#get_tree().set_deferred("current_scene",content)
	current_3d_scene = content
	if content is Level:
		content.call_deferred("enter_level")
		
func reload_scene():
	Engine.time_scale = 1.0
	load_new_scene(current_3d_scene.scene_file_path)
	
