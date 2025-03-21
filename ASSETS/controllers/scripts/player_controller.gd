extends CharacterBody3D

@export_subgroup("Properties")
@export var movement_speed = 10
@export var jump_strength = 10

var mouse_sensitivity = 700

var mouse_captured := true

var movement_velocity: Vector3
var rotation_target: Vector3

var input_mouse: Vector2

var gravity := 0.0

var jump_single := true
var jump_double := true

@onready var camera = $CameraController/Camera3D
@onready var raycast = $CameraController/Camera3D/RayCast3D

func _ready():
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	
	#Handle functions
	handle_controls(delta)
	handle_gravity(delta)
	
	#Apply movement

	var applied_velocity: Vector3
	
	movement_velocity = transform.basis * movement_velocity #Move forward
	
	applied_velocity = velocity.lerp(movement_velocity, delta * 10)
	applied_velocity.y = -gravity
	
	velocity = applied_velocity
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

func _input(event):
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
	
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	movement_velocity = Vector3(input.x, 0, input.y).normalized() * movement_speed
	
	#Jumping
	
	if Input.is_action_just_pressed("jump"):
		
		if jump_double:
			
			gravity = -jump_strength
			jump_double = false
			
		if(jump_single): action_jump()
	#Interact with objects
	action_interact()

func action_interact():
#	if Input.is_action_just_pressed("interact"):
		return
		

#Gravity

func handle_gravity(delta):
	
	gravity += 20 * delta
	
	if gravity > 0 and is_on_floor():
		jump_single = true
		gravity = 0

#Jumping logic

func action_jump():
	if is_on_floor():
		jump_double = true;
	else:
		jump_double = false;
	jump_single = false;
	
	gravity = -jump_strength
	
	
