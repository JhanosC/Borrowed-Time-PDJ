extends CharacterBody3D

@export_subgroup("Properties")
@export var jump_strength := 9.0
@export var slam_strength := 3.5
@export var mouse_sensitivity = 700
const HEADBOB_MOVE_AMOUNT = 0.05
const HEADBOB_FREQUENCY = 2.0
var headbob_time := 0.0
var lerp_speed := 10.0
var sliding_height := 0.75
var gravity := 0.0
var camera_distortion := -1.0
var camera_distortion_strength := 0.6
var camera_default_fov := 0.0
var camera_new_fov := camera_default_fov

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
@export var movement_speed : float
@export var max_speed : float
@export var hitGroundCooldown := 0.2
@export var ground_decel := 10.0
@export var acceleration := 10.0
@export var desiredMoveSpeedCurve : Curve
@export var inAirMoveSpeedCurve : Curve
var desired_velocity := 0.0
var hitGroundCooldownRef : float

var direction := Vector3.ZERO
var wall_jump_counter := 0
var wall_run_cooldown := 0.0
var possible_wall_jumps := 3.0

var rotation_target: Vector3
var input_mouse: Vector2
var input_dir: Vector2

signal velocity_update(velocity: Vector3, desired_velocity: float)
signal fov_update(fov: float)
signal camera_distortion_update(distortion: float)
signal states_update(can_crouch:bool,slaming:bool,sliding:bool,wall_running:bool,on_floor:bool,on_wall:bool,direction:Vector3)
signal position_update(x,y,z: float)

@onready var camera = $CameraController/Camera3D
@onready var head: Node3D = $CameraController
@onready var ceilingCheck = $Raycasts/CeilingCheck
@onready var wall_check_r: RayCast3D = $Raycasts/WallCheckR
@onready var wall_check_l: RayCast3D = $Raycasts/WallCheckL
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var sliding_collision_shape: CollisionShape3D = $SlidingCollisionShape
@onready var mesh: MeshInstance3D = $WorldModel/MeshInstance3D
@onready var hud = $HUD

var debug_mode = true

func update_signals():
	states_update.emit(can_crouch,slaming,sliding,wall_running,is_on_floor(),is_touching_wall(),direction)
	velocity_update.emit(Vector3(velocity.x,0.0,velocity.z).length(), desired_velocity)

func get_move_speed() -> float:
	return movement_speed

func is_touching_wall() -> bool:
	if wall_check_l.is_colliding() or wall_check_r.is_colliding():
		if !(wall_check_l.get_collider() is RigidBody3D or wall_check_r.get_collider() is RigidBody3D):
			if !(wall_check_l.get_collider() is CharacterBody3D or wall_check_r.get_collider() is CharacterBody3D):
				if abs(wall_check_l.get_collision_normal().y) < 0.1 or abs(wall_check_r.get_collision_normal().y) < 0.1:
					return true
	return false

func _ready():
	sliding_collision_shape.disabled = true
	standing_collision_shape.disabled = false
	hitGroundCooldownRef = hitGroundCooldown
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
			
			var push_force = mass_ratio * 5.0
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
	if wall_running and self.velocity.y <= 0.0:
		self.velocity.y *= 0.7
	self.velocity.y -= gravity * delta

func _physics_process(delta):
	if wall_run_cooldown >= 0.0: wall_run_cooldown -= delta
	if wall_run_cooldown <= 0.0:
		can_wall_run = true
	if !is_on_floor():
		if hitGroundCooldown != hitGroundCooldownRef: hitGroundCooldown = hitGroundCooldownRef
	if is_on_floor():
		if hitGroundCooldown >= 0: hitGroundCooldown -= delta
	hud.display_speed_lines(self.velocity.length(), movement_speed)
	# Handle functions
	handle_controls(delta)
	move(delta)
	_process_camera(delta)
	_distort_camera(delta)
	_push_away_rigid_bodies()
	_wall_run(delta)
	move_and_slide()
	update_signals()
	
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
	if desired_velocity < get_move_speed(): desired_velocity = velocity.length()
	if wall_running:
		direction = velocity.normalized()
	else:
		direction = (self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	
	if is_on_floor():
		wall_jump_counter = 0
		if direction:
			self.velocity.x = lerp(velocity.x, direction.x * get_move_speed(), acceleration * delta)
			self.velocity.z = lerp(velocity.z, direction.z * get_move_speed(), acceleration * delta)
			if hitGroundCooldown <= 0: desired_velocity = velocity.length()
		else:
			self.velocity.x = lerp(velocity.x, 0.0, ground_decel * delta)
			self.velocity.z = lerp(velocity.z, 0.0, ground_decel * delta)
			desired_velocity = velocity.length()
		_headbob_effect(delta)

	if !is_on_floor():
		_process_gravity(delta)
		if direction:
			if desired_velocity < max_speed: desired_velocity += 1.0 * delta
			
			# Curves for air acceleration
			var contrdDesMoveSpeed : float = desiredMoveSpeedCurve.sample(desired_velocity/100)
			var contrdInAirMoveSpeed : float = inAirMoveSpeedCurve.sample(desired_velocity)
		
			velocity.x = lerp(velocity.x, direction.x * contrdDesMoveSpeed, contrdInAirMoveSpeed * delta)
			velocity.z = lerp(velocity.z, direction.z * contrdDesMoveSpeed, contrdInAirMoveSpeed * delta)
		else:
			desired_velocity = velocity.length()
	if is_touching_wall():
		if wall_running:
			if direction:
				desired_velocity += 0.5 * delta
				velocity.x = direction.x * desired_velocity
				velocity.z = direction.z * desired_velocity
				
	if desired_velocity >= max_speed: desired_velocity = max_speed

func jump(strength_value : float):
	if wall_running:
		wall_running = false
		can_wall_run = false
		if wall_check_l.is_colliding():
			velocity = wall_check_l.get_collision_normal() * 20.0
		else:
			velocity = wall_check_r.get_collision_normal() * 20.0
		wall_run_cooldown = 0.5
		
	self.velocity.y = jump_strength + strength_value

func _wall_run(_delta):
	if !is_on_floor() and is_touching_wall() and can_wall_run:
		print("R: "+ str(wall_check_r.get_collision_normal()))
		print("L: "+ str(wall_check_l.get_collision_normal()))
		wall_running = true
		if Input.is_action_just_pressed("jump") and wall_jump_counter < possible_wall_jumps:
			wall_jump_counter += 1
			jump(5)
			self.velocity.y = jump_strength
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
