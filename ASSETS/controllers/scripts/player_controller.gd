extends CharacterBody3D

@export_subgroup("Properties")
@export var jump_strength := 9.0
@export var slam_strength := 3.5
@export var mouse_sensitivity = 700
const HEADBOB_MOVE_AMOUNT = 0.05
const HEADBOB_FREQUENCY = 2.0
var headbob_time := 0.0
var lerp_speed := 20.0
var sliding_height := 0.75
var gravity := 0.0
var camera_distortion := -1.0
var camera_distortion_strength := 0.6
var camera_default_fov := 0.0
var camera_new_fov := camera_default_fov
var last_wall_normal := Vector3.ZERO

@export_subgroup("States")
@export var auto_bhop := true
var wall_running := false
var sliding := false
var can_crouch := true
var slaming := false
var mouse_captured := true
var crawling := false
var can_wall_run := true

@export_subgroup("Movement Settings")
@export var movement_speed := 15.0
@export var desired_velocity := 0.0
@export var air_control := 2.0
@export var max_speed := 80.0
@export var hitGroundCooldown := 0.2
var hitGroundCooldownRef := hitGroundCooldown
var ground_decel := 10.0
var direction := Vector3.ZERO
var wall_jump_counter := 0
var possible_wall_jumps := 3.0

var rotation_target: Vector3
var input_mouse: Vector2
var input_dir: Vector2

signal velocity_update(velocity: Vector3)
signal fov_update(fov: float)
signal camera_distortion_update(distortion: float)
signal states_update(can_crouch,slaming,sliding: bool)
signal position_update(x,y,z: float)

@onready var camera = $CameraController/Camera3D
@onready var head: Node3D = $CameraController
@onready var ceilingCheck = $Raycasts/CeilingCheck
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var sliding_collision_shape: CollisionShape3D = $SlidingCollisionShape
@onready var mesh: MeshInstance3D = $WorldModel/MeshInstance3D

var debug_mode = true

func get_move_speed() -> float:
	return movement_speed

func _ready():
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	camera_default_fov = camera.fov
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
			push_force = clamp(push_force, 0.0, 10.0)
			c.get_collider().apply_impulse(
				push_dir * velocity_diff_in_push_dir * push_force,
				c.get_position() - c.get_collider().global_position)

func _process_camera(delta):
	# Smooth camera movement
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 70 * delta, delta * 5)	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 50)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)

func _process_gravity(delta):
	if is_on_floor():
		return
	if wall_running and self.velocity.y <= 0.0:
		self.velocity.y -= gravity * delta * 0.1
	else:
		self.velocity.y -= gravity * delta

func _physics_process(delta):
	if is_on_floor():
		if hitGroundCooldown != hitGroundCooldownRef: hitGroundCooldown = hitGroundCooldownRef
	if !is_on_floor():
		if hitGroundCooldown >= 0: hitGroundCooldown -= delta
	else:
		if is_on_wall():
			last_wall_normal = get_wall_normal()
			can_wall_run = true
		else:
			can_wall_run = false
	# Handle functions
	handle_controls(delta)
	move(delta)
	move_and_slide()
	_wall_run(delta)
	_process_camera(delta)
	_distort_camera(delta)
	_push_away_rigid_bodies()
	
	
func _unhandled_input(event):
	# Mouse movement
	if event is InputEventMouseMotion and mouse_captured:
		input_mouse = event.relative / mouse_sensitivity
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity

func handle_controls(delta):
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
			jump(0.0)
	
	# Sliding and slam control
	if Input.is_action_pressed("crouch") and can_crouch:
		if !is_on_floor():
			self.velocity.y -= gravity * slam_strength
			slaming = true
			can_crouch = false
	elif !ceilingCheck.is_colliding() and is_on_floor():
		slaming = false
	elif ceilingCheck.is_colliding() and velocity.length() <= 2.0:
		crawling = true
	if Input.is_action_just_released("crouch"):
		can_crouch = true

func move(delta):
	# Get direction
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if wall_running:
		if input_dir.length() > 0.1:
			direction = (self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
		else:
			direction = velocity.normalized()
	else:
		direction = (self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	
	if is_on_floor():
		wall_jump_counter = 0
		if direction:
			self.velocity.x = lerp(velocity.x, direction.x * get_move_speed(), lerp_speed * delta)
			self.velocity.z = lerp(velocity.z, direction.z * get_move_speed(), lerp_speed * delta)
			if hitGroundCooldown <= 0: desired_velocity = velocity.length()
		else:
			self.velocity.x = lerp(velocity.x, 0.0, ground_decel * delta)
			self.velocity.z = lerp(velocity.z, 0.0, ground_decel * delta)
			desired_velocity = velocity.length()
		_headbob_effect(delta)

	if !is_on_floor():
		_process_gravity(delta)
		if direction:
			if desired_velocity < max_speed: desired_velocity += 1.5 * delta
			
			velocity.x = lerp(velocity.x, direction.x * get_move_speed(), air_control * delta)
			velocity.z = lerp(velocity.z, direction.z * get_move_speed(), air_control * delta)
				
		else:
			desired_velocity = velocity.length()
	if is_on_wall():
		if wall_running:
			if direction:
				desired_velocity += 1.0 * delta
				velocity.x = direction.x * desired_velocity
				velocity.z = direction.z * desired_velocity
				
	if desired_velocity >= max_speed: desired_velocity = max_speed #set to ensure the character don't exceed the max speed authorized

func jump(strength_value : float):
	self.velocity.y = jump_strength + strength_value
	if is_on_wall() and can_wall_run:
		wall_running = false
		velocity += last_wall_normal * 20.0

func _wall_run(_delta):
	if !is_on_floor() and is_on_wall() and can_wall_run:
		wall_running = true
		if Input.is_action_just_pressed("jump") and wall_jump_counter < possible_wall_jumps:
			wall_jump_counter += 1
			jump(5)
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

# FOV when running or standing still for too long
func _distort_camera(delta):
	if mouse_captured and (velocity.length() <= 0.0 and !debug_mode) or position.y < -350.0:
		camera_distortion += camera_distortion_strength * delta
		if camera_distortion >= 0.0:
			camera_new_fov += camera_distortion
			if camera_distortion >= 1.0:
				get_tree().call_deferred("reload_current_scene")
	elif !slaming:
		camera_new_fov = min(camera_default_fov + (Vector3(velocity.x,0.,velocity.z).length()*0.7),camera_default_fov * 1.3)
		camera_distortion = -1.0
	camera.fov = lerp(camera.fov, camera_new_fov, delta * lerp_speed)
