extends CharacterBody3D

@export_subgroup("Properties")
@export var jump_strength := 8.0
@export var mouse_sensitivity = 700
@export var air_control := 2.0
const HEADBOB_MOVE_AMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4
var headbob_time := 0.0
var lerp_speed := 20.0
var sliding_height := 0.75
var gravity := 0

@export_subgroup("States")
@export var auto_bhop := true
@export var sliding = false
@export var wall_running = false
@export var can_wall_run = true

@export_subgroup("Movement Settings")
@export var movement_speed := 10.0
var wish_dir := Vector3.ZERO
var start_slide_speed := 10.0

var mouse_captured := true
var movement_velocity: Vector3
var rotation_target: Vector3
var input_mouse: Vector2
var input_dir: Vector2
var wall_normal

signal velocity_update

@onready var camera = $CameraController/Camera3D
@onready var head: Node3D = $CameraController
@onready var raycast = $RayCast3D
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var sliding_collision_shape: CollisionShape3D = $SlidingCollisionShape

func _ready():
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
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
			
			const MY_APPROX_MASS_KG = 60.0
			var mass_ratio = min(1., MY_APPROX_MASS_KG / c.get_collider().mass)
			push_dir.y = 0
			
			var push_force = mass_ratio
			c.get_collider().apply_impulse(
				push_dir * velocity_diff_in_push_dir * push_force,
				c.get_position() - c.get_collider().global_position)

func _physics_process(delta):
	#Handle functions
	handle_controls(delta)
	_wall_run(delta)
	
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
	
	if is_on_floor() and !sliding:
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity.y = jump_strength
		_headbob_effect(_delta)
	elif !wall_running:
		self.velocity.y -= gravity * _delta
	if self.velocity.y <= 0:
		can_wall_run = true
	else:
		can_wall_run = false
	
	if Input.is_action_pressed("crouch"):
		_slide(_delta)
	elif !raycast.is_colliding() and is_on_floor():
		_stop_slide(_delta)
	
	#Get direction
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
	if !sliding and is_on_floor():
		wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	elif !is_on_floor() and !wall_running:
		wish_dir = lerp(wish_dir, self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y), _delta * air_control)
	if wish_dir:
		self.velocity.x = wish_dir.x * movement_speed
		self.velocity.z = wish_dir.z * movement_speed
	else:
		self.velocity.x = move_toward(self.velocity.x, 0, movement_speed)
		self.velocity.z = move_toward(self.velocity.z, 0, movement_speed)
	
	# Emit velocity to UI
	velocity_update.emit(self.velocity.length())

func _slide(delta):
	head.position.y = lerp(head.position.y, sliding_height, delta * lerp_speed)
	sliding = true
	standing_collision_shape.disabled = true
	sliding_collision_shape.disabled = false
func _stop_slide(delta):
	head.position.y = lerp(head.position.y, 1.75, delta * lerp_speed)
	sliding = false
	standing_collision_shape.disabled = false
	sliding_collision_shape.disabled = true

func _headbob_effect(delta):
	headbob_time += delta * self.velocity.length()
	$CameraController/Camera3D.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)
	
func _wall_run(delta):
	if is_on_wall() and !sliding and can_wall_run:
		wall_running = true
		wall_normal = get_wall_normal()
		#wish_dir = -wall_normal
		self.velocity.y -= gravity * delta * 0.1
		if Input.is_action_just_pressed("jump"):
			var wall_jump_direction = (wall_normal + Vector3.UP).normalized()
			self.velocity = wall_jump_direction * jump_strength
	else:
		wall_running = false
