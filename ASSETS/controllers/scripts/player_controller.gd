extends CharacterBody3D

@export_subgroup("Properties")
@export var jump_strength := 10.0
@export var mouse_sensitivity = 700
@export var slide_timer := 10.0
var slide_timer_max := slide_timer
const HEADBOB_MOVE_AMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4
var headbob_time := 0.0
var lerp_speed := 20.0
var sliding_height := 0.75

@export_subgroup("States")
@export var auto_bhop := true
@export var sliding = false

@export_subgroup("Movement Settings")
@export var movement_speed := 10.0
var wish_dir := Vector3.ZERO
var slide_dir := Vector2.ZERO

var mouse_captured := true
var movement_velocity: Vector3
var rotation_target: Vector3
var input_mouse: Vector2
var input_dir: Vector2

signal velocity_update

@onready var camera = $CameraController/Camera3D
@onready var head: Node3D = $CameraController
@onready var raycast = $RayCast3D
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var sliding_collision_shape: CollisionShape3D = $SlidingCollisionShape


func _ready():
	for child in $WorldModel.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(2, true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _push_away_rigid_bodies():
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir = -c.get_normal()
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			velocity_diff_in_push_dir = max(0., velocity_diff_in_push_dir)
			
			const MY_APPROX_MASS_KG = 80.0
			var mass_ratio = min(1., MY_APPROX_MASS_KG / c.get_collider().mass)
			push_dir.y = 0
			
			var push_force = mass_ratio * 2.0
			c.get_collider().apply_impulse(
				push_dir * velocity_diff_in_push_dir * push_force,
				c.get_position() - c.get_collider().global_position)

func _physics_process(delta):
	#Handle functions
	handle_controls(delta)
	if is_on_floor():
		lerp_speed = 15.0
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity. y = jump_strength
		_headbob_effect(delta)
	else:
		lerp_speed = 2.0
		self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	#Smooth camera movement
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 70 * delta, delta * 5)	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 50)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)

	#Camera bobbing when landing
	camera.position.y = lerp(camera.position.y, 0.0, delta * 50)
	if is_on_floor(): # Landed
		camera.position.y = -0.1
	#Respawn
	if position.y < -10:
		get_tree().reload_current_scene()
	_push_away_rigid_bodies()
	move_and_slide()

func _unhandled_input(event):
	#Mouse movement
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
	
	if Input.is_action_pressed("crouch"):
		standing_collision_shape.disabled = true
		sliding_collision_shape.disabled = false
		head.position.y = lerp(head.position.y, sliding_height, _delta*lerp_speed)
		if input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_dir = input_dir
	elif !raycast.is_colliding():
		standing_collision_shape.disabled = false
		sliding_collision_shape.disabled = true
		sliding = false
		head.position.y = lerp(head.position.y, 1.75, _delta * lerp_speed)
	
	#Get direction
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
	
	if sliding:
		wish_dir = (transform.basis * Vector3(slide_dir.x, 0., slide_dir.y)).normalized()
		slide_timer -= _delta * 10
		if slide_timer <= 0:
				sliding = false
	else:
		wish_dir = lerp(wish_dir, self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y),_delta * lerp_speed)
	
	if wish_dir:
		velocity.x = wish_dir.x * movement_speed
		velocity.z = wish_dir.z * movement_speed
		
		if sliding:
			velocity.x = wish_dir.x * slide_timer
			velocity.z = wish_dir.z * slide_timer
	else:
		velocity.x = move_toward(velocity.x, 0, movement_speed)
		velocity.z = move_toward(velocity.z, 0, movement_speed)
	
	velocity_update.emit(velocity.length())

func _headbob_effect(delta):
	headbob_time += delta * self.velocity.length()
	$CameraController/Camera3D.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)
