extends CharacterBody3D

@export_subgroup("Properties")
@export var jump_strength := 9.0
@export var slam_strength := 3.5
@export var mouse_sensitivity = 700
@export var wall_jump_strength := 1.5
const HEADBOB_MOVE_AMOUNT = 0.05
const HEADBOB_FREQUENCY = 2.8
var headbob_time := 0.0
var lerp_speed := 20.0
var sliding_height := 0.75
var gravity := 0.0
var wall_friction := 0.05
var possible_wall_jumps := 3
var camera_distortion := 0.0
var camera_distortion_strength := 0.2
var camera_default_fov := 75.0

@export_subgroup("States")
@export var auto_bhop := true
var sliding = false
var wall_running = false
var can_wall_run = true
var can_crouch = true
var mouse_captured := true

@export_subgroup("Movement Settings")
@export var movement_speed := 15.0
@export var air_control := 2.0
var wish_dir := Vector3.ZERO
var start_slide_speed := 10.0
var wall_jump_counter := 0

var movement_velocity: Vector3
var rotation_target: Vector3
var input_mouse: Vector2
var input_dir: Vector2
var wall_normal: Vector3

signal velocity_update
signal fov_update
signal camera_distortion_update

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

func _emit_degub_info():
	# Emit info to UI
	velocity_update.emit(Vector3(velocity.x,0.,velocity.z).length())
	fov_update.emit(camera.fov)
	camera_distortion_update.emit(camera_distortion)

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
	# Handle functions
	handle_controls(delta)
	_wall_run(delta)
	
	# Smooth camera movement
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 70 * delta, delta * 5)	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 50)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)

	#C amera bobbing when landing
	camera.position.y = lerp(camera.position.y, 0.0, delta * 50)
	if is_on_floor(): # Landed
		camera.position.y = -0.1
		wall_jump_counter = 0
	if mouse_captured:
		_distort_camera(delta)
	# Respawn
	if position.y < -10:
		get_tree().call_deferred("reload_current_scene")
	_emit_degub_info()
	_push_away_rigid_bodies()
	move_and_slide()

func _unhandled_input(event):
	# Mouse movement
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
	
	# Jumping control
	if is_on_floor() and !sliding:
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity.y = jump_strength
		_headbob_effect(_delta)
	elif !wall_running:
		self.velocity.y -= gravity * _delta
	
	# Sliding and slam control
	if Input.is_action_pressed("crouch") and can_crouch:
		if is_on_floor():
			_slide(_delta)
		elif !sliding:
			self.velocity.y -= gravity * slam_strength
			can_crouch = false
	elif !raycast.is_colliding() and is_on_floor():
		_stop_slide(_delta)
	if Input.is_action_just_released("crouch"):
		can_crouch = true
	
	# Get direction
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
	if !sliding and is_on_floor():
		wish_dir = lerp(wish_dir, self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y), _delta * lerp_speed)
	elif !is_on_floor():
		wish_dir = lerp(wish_dir, self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y), _delta * air_control)
	if wish_dir:
		self.velocity.x = wish_dir.x * movement_speed
		self.velocity.z = wish_dir.z * movement_speed
	else:
		self.velocity.x = move_toward(self.velocity.x, 0, movement_speed)
		self.velocity.z = move_toward(self.velocity.z, 0, movement_speed)

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

func _wall_run(delta):
	if is_on_wall() and !sliding and !is_on_floor():
		wall_running = true
		wall_normal = get_wall_normal()
		#wish_dir = -wall_normal
		if self.velocity.y <= 0:
			self.velocity.y -= gravity * delta * wall_friction
		else:
			self.velocity.y -= gravity * delta
		if Input.is_action_just_pressed("jump") and wall_jump_counter < possible_wall_jumps:
			wall_jump_counter += 1
			wish_dir = wall_normal * 1.5
			self.velocity.y = jump_strength
			can_wall_run = false
	else:
		wall_running = false

func _headbob_effect(delta):
	headbob_time += delta * self.velocity.length()
	camera.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)

func _distort_camera(delta):
	camera_distortion += camera_distortion_strength * delta
	camera.fov += camera_distortion
	if self.velocity.length() >= 2.0:
		camera_distortion = 0.0
		camera.fov = lerp(camera.fov, camera_default_fov, delta * lerp_speed)
	if camera_distortion >= 0.7:
		get_tree().call_deferred("reload_current_scene")
