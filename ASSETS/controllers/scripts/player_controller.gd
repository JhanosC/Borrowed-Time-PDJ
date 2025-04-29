extends CharacterBody3D

@export_subgroup("Properties")
@export var jump_strength := 9.0
@export var slam_strength := 3.5
@export var mouse_sensitivity = 700
@export var wall_jump_strength := 1.5
const HEADBOB_MOVE_AMOUNT = 0.05
const HEADBOB_FREQUENCY = 2.0
var headbob_time := 0.0
var lerp_speed := 20.0
var sliding_height := 0.75
var gravity := 0.0
var wall_friction := 0.05
var possible_wall_jumps := 3
var camera_distortion := -1.0
var camera_distortion_strength := 0.6
var camera_default_fov := 0.0
var camera_new_fov := camera_default_fov

@export_subgroup("States")
@export var auto_bhop := true
var sliding = false
var wall_running = false
var can_wall_run = true
var can_crouch = true
var slaming = false
var mouse_captured := true
var crawling := false

@export_subgroup("Movement Settings")
@export var movement_speed := 15.0
@export var desired_velocity := Vector3.ZERO
@export var air_control := 2.0
var direction := Vector3.ZERO
var start_slide_speed := 15.0
var wall_jump_counter := 0

var rotation_target: Vector3
var input_mouse: Vector2
var input_dir: Vector2
var wall_normal: Vector3

signal velocity_update(velocity: Vector3)
signal fov_update(fov: float)
signal camera_distortion_update(distortion: float)
signal states_update(can_crouch,slaming,sliding,wall_running: bool)
signal position_update(x,y,z: float)

@onready var camera = $CameraController/Camera3D
@onready var head: Node3D = $CameraController
@onready var ceilingCheck = $Raycasts/CeilingCheck
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var sliding_collision_shape: CollisionShape3D = $SlidingCollisionShape

var debug_mode = true

var dashing_timer = 0.0
var dashing = false
var dash_cooldown = 0.0
func get_move_speed() -> float:
	if dashing:
		return movement_speed * 2.0
	if crawling:
		return movement_speed * 0.6
	return movement_speed

func _ready():
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	camera_default_fov = camera.fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _emit_debug_info():
	# Emit info to UI
	velocity_update.emit(Vector3(velocity.x,0.,velocity.z).length())
	fov_update.emit(camera.fov)
	camera_distortion_update.emit(camera_distortion)
	states_update.emit(can_crouch,slaming,sliding,wall_running,is_on_floor(),is_on_wall(),direction)
	position_update.emit(position.x,position.y,position.z)

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
			push_force = clamp(push_force, 0.0, 10.0)
			c.get_collider().apply_impulse(
				push_dir * velocity_diff_in_push_dir * push_force,
				c.get_position() - c.get_collider().global_position)

func _process_camera(_delta):
	# Smooth camera movement
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 70 * _delta, _delta * 5)	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, _delta * 50)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, _delta * 25)

func _process_gravity(_delta):
	if is_on_floor():
		return
	elif wall_running and velocity.y <= 0:
		self.velocity.y -= gravity * _delta * wall_friction
	else:
		self.velocity.y -= gravity * _delta

func _handle_ground_physics(_delta):
	direction = lerp(direction, self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y), _delta * lerp_speed)
	self.velocity.x = direction.x * get_move_speed()
	self.velocity.z = direction.z * get_move_speed()
	if !sliding:
		_headbob_effect(_delta)

func _handle_air_physics(_delta):
	_process_gravity(_delta)
	direction = lerp(direction, self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y), _delta * air_control)
	self.velocity.x = direction.x * get_move_speed()
	self.velocity.z = direction.z * get_move_speed()

func _physics_process(_delta):
	# Handle functions
	handle_controls(_delta)
	if is_on_floor():
		wall_jump_counter = 0
		_handle_ground_physics(_delta)
	else:
		_handle_air_physics(_delta)
	
	_wall_run(_delta)
	_process_camera(_delta)
	_distort_camera(_delta)
	_push_away_rigid_bodies()
	move_and_slide()
	_emit_debug_info()
	
func _unhandled_input(event):
	# Mouse movement
	if event is InputEventMouseMotion and mouse_captured:
		input_mouse = event.relative / mouse_sensitivity
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity

func handle_controls(_delta):
	# Get direction
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
	
	# Reload scene
	if Input.is_action_just_pressed("reload"):
		get_tree().call_deferred("reload_current_scene")
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
	
	if Input.is_action_just_pressed("dash") and !dashing and !sliding and dash_cooldown <= 0.0:
		dashing = true
		dashing_timer = 0.2
		dash_cooldown = 0.5
	if dashing_timer > 0.0:
		self.velocity.y = 0.0
		dashing_timer -= _delta
	else:
		if dash_cooldown >= 0.0:
			dash_cooldown -= _delta
		dashing = false
	
	# Sliding and slam control
	if Input.is_action_pressed("crouch") and can_crouch:
		if is_on_floor() and input_dir:
			_slide(_delta)
		elif !is_on_floor() and !sliding:
			self.velocity.y -= gravity * slam_strength
			slaming = true
			can_crouch = false
	elif !ceilingCheck.is_colliding() and is_on_floor():
		slaming = false
		_stop_slide(_delta)
	elif ceilingCheck.is_colliding() and velocity.length() <= 2.0:
		crawling = true
	if Input.is_action_just_released("crouch"):
		can_crouch = true

func _slide(_delta):
	head.position.y = lerp(head.position.y, sliding_height, _delta * lerp_speed)
	sliding = true
	standing_collision_shape.disabled = true
	sliding_collision_shape.disabled = false
func _stop_slide(_delta):
	head.position.y = lerp(head.position.y, 1.75, _delta * lerp_speed)
	sliding = false
	crawling = false
	standing_collision_shape.disabled = false
	sliding_collision_shape.disabled = true

func _wall_run(_delta):
	if is_on_wall() and !sliding and !is_on_floor():
		wall_running = true
		wall_normal = get_wall_normal()
		if Input.is_action_just_pressed("jump") and wall_jump_counter < possible_wall_jumps:
			wall_jump_counter += 1
			direction = wall_normal
			self.velocity.y = jump_strength
			can_wall_run = false
	else:
		wall_running = false

func _headbob_effect(_delta):
	headbob_time += _delta * self.velocity.length()
	camera.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)

# FOV when running or standing still for too long
func _distort_camera(_delta):
	if mouse_captured and (velocity.length() <= 0.0 and !debug_mode) or position.y < -350.0:
		camera_distortion += camera_distortion_strength * _delta
		if camera_distortion >= 0.0:
			camera_new_fov += camera_distortion
			if camera_distortion >= 1.0:
				get_tree().call_deferred("reload_current_scene")
	elif !slaming:
		camera_new_fov = min(camera_default_fov + (Vector3(velocity.x,0.,velocity.z).length()*0.7),camera_default_fov * 1.3)
		camera_distortion = -1.0
	camera.fov = lerp(camera.fov, camera_new_fov, _delta * lerp_speed)
