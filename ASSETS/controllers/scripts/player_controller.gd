extends CharacterBody3D

@export_subgroup("Properties")
@export var jump_strength := 6.0
@export var mouse_sensitivity = 700
@export var auto_bhop := true
const HEADBOB_MOVE_AMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4
var headbob_time := 0.0

@export_subgroup("Movement Settings")
@export var movement_speed := 10
@export var ground_accel := 14.0
@export var ground_decel := 10.0
@export var ground_friction := 6.0

@export var air_cap := 0.85
@export var air_accel := 800.0
@export var air_move_speed := 500.0

var wish_dir := Vector3.ZERO

var mouse_captured := true

var movement_velocity: Vector3
var rotation_target: Vector3

var input_mouse: Vector2

var gravity := 0.0

@onready var camera = $CameraController/Camera3D
@onready var raycast = $CameraController/Camera3D/RayCast3D

func _ready():
	for child in $WorldModel.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(2, true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _handle_air_physics(delta) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	# Air movement from Source Engine
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir

func _handle_ground_physics(delta) -> void:
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_till_cap = movement_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel  * delta * movement_speed
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
	
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed
	
	_headbob_effect(delta)

func _physics_process(delta):
	#Handle functions
	handle_controls(delta)
	if is_on_floor():
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity. y = jump_strength
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	##Apply movement
	#var applied_velocity: Vector3
	#wish_dir = transform.basis * wish_dir #Move forward
	#applied_velocity = velocity.lerp(wish_dir, delta * 10)
	#applied_velocity.y = -gravity
	#velocity = applied_velocity
	
	move_and_slide()
	
	#Smooth camera movement
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 70 * delta, delta * 5)	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 50)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)

	#Camera bobbing when landing
	camera.position.y = lerp(camera.position.y, 0.0, delta * 5)
	if is_on_floor() and gravity > 1: # Landed
		camera.position.y = -0.1
	#Respawn
	if position.y < -10:
		get_tree().reload_current_scene()

#Mouse movement
func _unhandled_input(event):
	if event is InputEventMouseMotion and mouse_captured:
		input_mouse = event.relative / mouse_sensitivity
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity

func handle_controls(_delta):
	#Mouse capture/Enable cursor
	if Input.is_action_just_pressed("mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	
	if Input.is_action_just_pressed("mouse_capture_exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
		input_mouse = Vector2.ZERO
	rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))
	
	#Get direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
	#movement_velocity = Vector3(input_dir.x, 0, input_dir.y) * movement_speed
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	#Interact with objects
	action_interact()

func action_interact():
#	if Input.is_action_just_pressed("interact"):
		return

func _headbob_effect(delta):
	headbob_time += delta * self.velocity.length()
	$CameraController/Camera3D.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)
