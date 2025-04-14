extends CharacterBody3D

# --- Exported Properties (Editable from Inspector) ---

@export_subgroup("Properties")
@export var jump_strength := 9.0 # Force applied when jumping
@export var slam_strength := 3.5 # Additional downward force during slam
@export var mouse_sensitivity = 700 # Camera sensitivity
@export var wall_jump_strength := 1.5 # Force applied during wall jump

# Headbob visual settings
const HEADBOB_MOVE_AMOUNT = 0.05
const HEADBOB_FREQUENCY = 2.5

# Camera and movement tuning
var headbob_time := 0.0
var lerp_speed := 20.0
var sliding_height := 0.75 # Height of camera during slide
var gravity := 0.0
var wall_friction := 0.05
var possible_wall_jumps := 3
var camera_distortion := -1.0
var camera_distortion_strength := 0.6
var camera_default_fov := 0.0
var camera_new_fov := camera_default_fov

@export_subgroup("States")
@export var auto_bhop := true # Enables bunny hop by holding jump
var sliding = false
var wall_running = false
var can_wall_run = true
var can_crouch = true
var slaming = false
var mouse_captured := true # Is mouse currently controlling camera?

@export_subgroup("Movement Settings")
@export var movement_speed := 15.0 # Base movement speed
@export var air_control := 2.0 # Movement responsiveness in air
var wish_dir := Vector3.ZERO # Desired movement direction
var start_slide_speed := 15.0
var wall_jump_counter := 0

# --- Runtime Variables ---
var movement_velocity: Vector3
var rotation_target: Vector3
var input_mouse: Vector2
var input_dir: Vector2
var wall_normal: Vector3

# --- Signals ---
signal velocity_update(velocity: Vector3)
signal fov_update(fov: float)
signal camera_distortion_update(distortion: float)
signal states_update(can_crouch, slaming, sliding, wall_running: bool)
signal position_update(x, y, z: float)

# --- Node References ---
@onready var camera = $CameraController/Camera3D
@onready var head: Node3D = $CameraController
@onready var raycast = $RayCast3D
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var sliding_collision_shape: CollisionShape3D = $SlidingCollisionShape

# Debug toggle
var debug_mode = true

func _ready():
	# Set gravity and initialize camera settings
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	camera_default_fov = camera.fov
	
	# Switch render layers for world models
	for child in $WorldModel.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(2, true)
		
	# Capture mouse for camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _emit_debug_info():
	# Emit gameplay state values to connected UI or debugger
	velocity_update.emit(Vector3(velocity.x, 0.0, velocity.z).length())
	fov_update.emit(camera.fov)
	camera_distortion_update.emit(camera_distortion)
	states_update.emit(can_crouch, slaming, sliding, wall_running)
	position_update.emit(position.x, position.y, position.z)

func _push_away_rigid_bodies():
	# Push rigid bodies on collision (simulate physical interaction)
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var collider := c.get_collider(i)
		if collider is RigidBody3D:
			var push_dir = -c.get_normal()
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - collider.linear_velocity.dot(push_dir)
			velocity_diff_in_push_dir = max(0.0, velocity_diff_in_push_dir)
			
			const MY_APPROX_MASS_KG = 60.0
			var mass_ratio = min(1.0, MY_APPROX_MASS_KG / collider.mass)
			push_dir.y = 0
			
			var push_force = clamp(mass_ratio, 0.0, 10.0)
			collider.apply_impulse(
				push_dir * velocity_diff_in_push_dir * push_force,
				c.get_position() - collider.global_position
			)

func _process_gravity(_delta):
	# Handle gravity and wall running gravity reduction
	if is_on_floor():
		return
	elif wall_running and velocity.y <= 0:
		self.velocity.y -= gravity * _delta * wall_friction
	else:
		self.velocity.y -= gravity * _delta

func _process_camera(_delta):
	# Smooth camera control
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 70 * _delta, _delta * 5)
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, _delta * 50)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, _delta * 25)

	# Landing effect
	camera.position.y = lerp(camera.position.y, 0.0, _delta * 50)
	if is_on_floor():
		camera.position.y = -0.1
		wall_jump_counter = 0

func _physics_process(_delta):
	# Main game loop
	handle_controls(_delta)
	_wall_run(_delta)
	_process_camera(_delta)
	_distort_camera(_delta)
	_push_away_rigid_bodies()
	move_and_slide()
	_emit_debug_info()

func _unhandled_input(event):
	# Handle mouse motion for look control
	if event is InputEventMouseMotion and mouse_captured:
		input_mouse = event.relative / mouse_sensitivity
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity

func handle_controls(_delta):
	# Reload scene
	if Input.is_action_just_pressed("reload"):
		get_tree().call_deferred("reload_current_scene")
		
	# Mouse capture toggle
	if Input.is_action_just_pressed("mouse_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true
	
	if Input.is_action_just_pressed("mouse_capture_exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
		input_mouse = Vector2.ZERO

	# Clamp vertical look angle
	rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))
	
	# Handle jump
	if is_on_floor() and !sliding:
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			self.velocity.y = jump_strength
		_headbob_effect(_delta)
	else:
		_process_gravity(_delta)

	# Handle crouch/sliding and slamming
	if Input.is_action_pressed("crouch") and can_crouch:
		if is_on_floor() and input_dir:
			_slide(_delta)
		elif !is_on_floor() and !sliding:
			self.velocity.y -= gravity * slam_strength
			slaming = true
			can_crouch = false
	elif !raycast.is_colliding() and is_on_floor():
		slaming = false
		_stop_slide(_delta)
	if Input.is_action_just_released("crouch"):
		can_crouch = true

	# Get movement input
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()

	# Apply movement direction
	if !sliding and is_on_floor():
		wish_dir = lerp(wish_dir, global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y), _delta * lerp_speed)
	elif !is_on_floor():
		wish_dir = lerp(wish_dir, global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y), _delta * air_control)

	# Apply movement velocity
	if wish_dir:
		self.velocity.x = wish_dir.x * movement_speed
		self.velocity.z = wish_dir.z * movement_speed
	else:
		self.velocity.x = move_toward(self.velocity.x, 0, movement_speed)
		self.velocity.z = move_toward(self.velocity.z, 0, movement_speed)

func _slide(_delta):
	# Start sliding transition
	head.position.y = lerp(head.position.y, sliding_height, _delta * lerp_speed)
	sliding = true
	standing_collision_shape.disabled = true
	sliding_collision_shape.disabled = false

func _stop_slide(_delta):
	# End sliding transition
	head.position.y = lerp(head.position.y, 1.75, _delta * lerp_speed)
	sliding = false
	standing_collision_shape.disabled = false
	sliding_collision_shape.disabled = true

func _wall_run(_delta):
	# Allow wall running and wall jumps
	if is_on_wall() and !sliding and !is_on_floor():
		wall_running = true
		wall_normal = get_wall_normal()
		if Input.is_action_just_pressed("jump") and wall_jump_counter < possible_wall_jumps:
			wall_jump_counter += 1
			wish_dir = wall_normal
			self.velocity.y = jump_strength
			can_wall_run = false
	else:
		wall_running = false

func _headbob_effect(_delta):
	# Create visual head movement while walking
	headbob_time += _delta * self.velocity.length()
	camera.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)

func _distort_camera(_delta):
	# Handle FOV and visual distortion effects
	if mouse_captured and (velocity.length() <= 0.0 and !debug_mode) or position.y < -350.0:
		camera_distortion += camera_distortion_strength * _delta
		if camera_distortion >= 0.0:
			camera_new_fov += camera_distortion
			if camera_distortion >= 1.0:
				get_tree().call_deferred("reload_current_scene")
	elif !slaming:
		camera_new_fov = min(camera_default_fov + (Vector3(velocity.x, 0.0, velocity.z).length() * 0.7), camera_default_fov * 1.3)
		camera_distortion = -1.0
	
	# Smooth FOV transition
	camera.fov = lerp(camera.fov, camera_new_fov, _delta * lerp_speed)
