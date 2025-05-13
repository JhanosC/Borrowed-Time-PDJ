class_name Door extends Area3D

signal player_entered_door(door:Door)

@export var path_to_new_scene:String
@export var entry_door_name:String


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_body_entered(body):
	if not body is Player:
		return
	player_entered_door.emit(self)	
	print("ENTREI NA ÁREA")
	Global.game_controller.load_new_scene(path_to_new_scene)
	queue_free()
