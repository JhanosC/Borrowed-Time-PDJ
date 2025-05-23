class_name HookController
extends Node

@export_group("Controls")

@export var launch_action_name: String = "left_mouse"## Input Map action name that triggers hook's launch; default left mouse button

@export var retract_action_name: String = "left_mouse"## Input Map action name that triggers hook's retraction; default left mouse button

@export var shorten_action_name: String = "scroll_down"## Input Map action name that decreases the length of the rope rest_length; default mouse scroll down
@export var extend_action_name: String = "scroll_up"## Input Map action name that increases the length of the rope rest_length; default mouse scroll up



@export_group("References")
@export var hook_scene: PackedScene ## The hook and rope which we will be instantiating
@export var player_body: CharacterBody3D ## The player, who we will apply forces to
@export var hook_raycast: RayCast3D ## The raycast which will look where to shoot the rope
@export var hook_source: Node3D ## A 3D node that serves as the beginning on the rope model


@export_group("Settings")
var rest_length: float = 2.0 ##where the player wont have forces applied to them (this is now done automatically in code depending on rope length)
@export var stiffness: float = 10.0##how stiff the rope is, higher is stiffer
@export var damping: float = 1.0##how much to dampen the bouncing
@export_range ( 1, 10) var rest_length_center_fraction : int = 3## 10 will not pull the player and make them rest where they hooked from, 1 will launch the player towards the hook. 

var is_hook_launched: bool = false
var _hook_model: Node3D = null
var hook_target_normal: Vector3 = Vector3.ZERO
var hook_target_node: Marker3D = null

signal hook_launched()
signal hook_attached(body)
signal hook_detached()
func _physics_process(delta: float) -> void:
	if is_hook_launched:
		_handle_hook(delta)

func _release_hook() -> void:
	hook_launched.emit()
		
	match is_hook_launched:
		false: _launch_hook()
		true: _retract_hook()
## Attaches a Marker3D to the body that is in the way of the raycast.
## Enables the hook, emits proper signals.
func _launch_hook() -> void:
	if not hook_raycast.is_colliding():
		return
	var body: Node3D = hook_raycast.get_collider()
	if !body.is_in_group("grappable"):
		return
	is_hook_launched = true
	player_body.hook_out = true
	hook_attached.emit()
	
	

	hook_target_node = Marker3D.new()
	body.add_child(hook_target_node)
	
	hook_target_node.global_position = hook_raycast.get_collision_point()#for some reason this was originally hook_target_node.position = hook_raycast.get_collision_point() - body.global_position, even though that was a less precise and more convoluted way of doing it
	hook_target_normal = hook_raycast.get_collision_normal()
	var rest_length_center = (hook_target_node.global_position - player_body.global_position).length() / rest_length_center_fraction
	rest_length = (hook_target_node.global_position - player_body.global_position).length() - rest_length_center
	
	_hook_model = hook_scene.instantiate()
	add_child(_hook_model)


## Disables the hook, frees the target node and the hook model, emits required signals.
func _retract_hook() -> void:
	is_hook_launched = false
	player_body.hook_out = false
	
	hook_target_node.queue_free()
	_hook_model.queue_free()
	
	hook_detached.emit()



## the code that manages the hook physics and its movement
func _handle_hook(delta: float) -> void:
	# Hook pull math
	var pull_vector = (hook_target_node.global_position - player_body.global_position).normalized()
	var distance = (hook_target_node.global_position - player_body.global_position).length()
	var spring_force_magnitude = stiffness * (distance - rest_length)
	if spring_force_magnitude > 0:#this makes the force the spring applies stronger when the hook is above you, but apply no force when its under you, so you dont bounce 10m above the hook like a spring
		spring_force_magnitude *= 2
	else:
		spring_force_magnitude = 0
	var relative_velocity = - player_body.velocity
	var damping_force_magnitude = damping * relative_velocity.dot(pull_vector)
	var total_force = (spring_force_magnitude + damping_force_magnitude) * pull_vector
	if Input.is_action_just_pressed(shorten_action_name):#scrolling the mouse wheel changes the position of the rest_length
		rest_length -= 1
	elif Input.is_action_just_pressed(extend_action_name):
		rest_length += 1
	if distance <= 3.0:
		_retract_hook()
	print(distance)
	player_body.velocity += total_force * delta

	
	# Hook model handling
	var source_position: Vector3
	match true if hook_source else false:
		true: source_position = hook_source.global_position
		false: source_position = player_body.global_position
	
	_hook_model.extend_from_to(source_position, hook_target_node.global_position, hook_target_normal, delta)
