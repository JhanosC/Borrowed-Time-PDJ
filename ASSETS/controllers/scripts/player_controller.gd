extends CharacterBody3D

@export_subgroup("Properties")
@export var jump_strength := 9.0
@export var slam_strength := 3.5
@export var mouse_sensitivity = 700
<<<<<<< HEAD
var slide_vector : Vector2 = Vector2.ZERO
const HEADBOB_MOVE_AMOUNT = 0.05
const HEADBOB_FREQUENCY = 2.0
var headbob_time := 0.0
var lerp_speed := 10.0
var sliding_height := 0.75
var gravity := 0.0
=======
@export var wall_jump_strength := 1.5
const HEADBOB_MOVE_AMOUNT = 0.05
const HEADBOB_FREQUENCY = 2.0
var headbob_time := 0.0
var lerp_speed := 20.0
var sliding_height := 0.75
var gravity := 0.0
var wall_friction := 0.05
var possible_wall_jumps := 3
>>>>>>> main
var camera_distortion := -1.0
var camera_distortion_strength := 0.6
var camera_default_fov := 0.0
var camera_new_fov := camera_default_fov

@export_subgroup("States")
@export var auto_bhop := true
<<<<<<< HEAD
var wall_running := false
var sliding := false
var dashing := false
var can_crouch := true
var slaming := false
var mouse_captured := true
var crawling := false
var can_wall_run := true
var on_floor := true

@export_subgroup("Movement Settings")
@export var movement_speed : float
@export var max_speed : float
@export var hitGroundCooldown := 0.2
@export var ground_decel := 10.0
@export var acceleration := 10.0
@export var desiredMoveSpeedCurve : Curve
@export var inAirMoveSpeedCurve : Curve
@export var dash_cooldown := 0.0
@export var wall_jump_force := 20.0
@export var dash_duration := 0.2
@export var dash_speed_multiplier := 3.0
@export var crawl_speed_multiplier := 0.7
var dashing_timer := 0.0
var desired_velocity := 0.0
var hitGroundCooldownRef : float

var direction := Vector3.ZERO
var wall_jump_counter := 0
var wall_run_cooldown := 0.0
var possible_wall_jumps := 3
var dash_counter := 0
var possible_dashs := 3
=======
var sliding = false
var wall_running = false
var can_wall_run = true
var can_crouch = true
var slaming = false
var mouse_captured := true
var crawling := false

@export_subgroup("Movement Settings")
@export var movement_speed := 15.0
@export var air_cap := 0.85
@export var air_accel := 800.0
@export var air_move_speed := 500.0
@export var desired_velocity := Vector3.ZERO
@export var air_control := 0.5
@export var ground_accel := 11.0
@export var ground_decel := 7.0
@export var ground_friction := 3.5
var direction := Vector3.ZERO
var start_slide_speed := 15.0
var wall_jump_counter := 0
>>>>>>> main

var rotation_target: Vector3
var input_mouse: Vector2
var input_dir: Vector2
<<<<<<< HEAD

signal velocity_update(velocity: Vector3, desired_velocity: float)
signal fov_update(fov: float)
signal camera_distortion_update(distortion: float)
signal states_update(can_crouch:bool,slaming:bool,sliding:bool,wall_running:bool,on_floor:bool,on_wall:bool,direction:Vector3)
=======
var wall_normal: Vector3

signal velocity_update(velocity: Vector3)
signal fov_update(fov: float)
signal camera_distortion_update(distortion: float)
signal states_update(can_crouch,slaming,sliding,wall_running,on_floor: bool)
>>>>>>> main
signal position_update(x,y,z: float)

@onready var camera = $CameraController/Camera3D
@onready var head: Node3D = $CameraController
@onready var ceilingCheck = $Raycasts/CeilingCheck
<<<<<<< HEAD
@onready var wall_check_r: RayCast3D = $Raycasts/WallCheckR
@onready var wall_check_l: RayCast3D = $Raycasts/WallCheckL
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var sliding_collision_shape: CollisionShape3D = $SlidingCollisionShape
@onready var mesh: MeshInstance3D = $WorldModel/MeshInstance3D
@onready var hud = $HUD

var debug_mode = true

func update_signals():
	states_update.emit(can_crouch,slaming,sliding,wall_running,on_floor,is_touching_wall(),direction)
	velocity_update.emit(Vector3(velocity.x,0.0,velocity.z).length(), desired_velocity)

func get_move_speed() -> float:
	if crawling:
		return movement_speed * crawl_speed_multiplier
	elif dashing:
		return movement_speed * dash_speed_multiplier
	return movement_speed

func is_touching_wall() -> bool:
	# More consistent way yo check if is touching a wall
	if wall_check_l.is_colliding() or wall_check_r.is_colliding():
		# Ignore RigidBodies and CharacterBodies
		if !(wall_check_l.get_collider() is RigidBody3D or wall_check_r.get_collider() is RigidBody3D):
			if !(wall_check_l.get_collider() is CharacterBody3D or wall_check_r.get_collider() is CharacterBody3D):
				if abs(wall_check_l.get_collision_normal().y) < 0.1 or abs(wall_check_r.get_collision_normal().y) < 0.1:
					return true
	return false

func _ready():
	sliding_collision_shape.disabled = true
	standing_collision_shape.disabled = false
	hitGroundCooldownRef = hitGroundCooldown
=======
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
>>>>>>> main
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	camera_default_fov = camera.fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

<<<<<<< HEAD
func _push_away_rigid_bodies():
	# Handle colision with RigidBodies
=======
func _emit_debug_info():
	# Emit info to UI
	velocity_update.emit(Vector3(velocity.x,0.,velocity.z).length())
	fov_update.emit(camera.fov)
	camera_distortion_update.emit(camera_distortion)
	position_update.emit(position.x,position.y,position.z)
	states_update.emit(
		can_crouch,slaming,sliding,wall_running,is_on_floor(),is_on_wall(),direction
		)

func _push_away_rigid_bodies():
>>>>>>> main
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir = -c.get_normal()
<<<<<<< HEAD
			push_dir.y = 0 # Do not push down or up
=======
>>>>>>> main
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			velocity_diff_in_push_dir = max(0., velocity_diff_in_push_dir)
			
			const MY_APPROX_MASS_KG = 60.0
			var mass_ratio = min(1., MY_APPROX_MASS_KG / c.get_collider().mass)
			
<<<<<<< HEAD
			
			var push_force = mass_ratio * 5.0
			push_force = clamp(push_force, 0.0, 10.0)
			c.get_collider().apply_impulse(
				push_dir * velocity_diff_in_push_dir * push_force,
				c.get_position() - c.get_collider().global_position)

func _process_camera(delta):
	if wall_running:
		if wall_check_l.is_colliding():
			head.rotation.z = lerp(head.rotation.z, deg_to_rad(20.0) * -(wall_check_l.get_collision_normal().length()), lerp_speed * delta)
		else:
			head.rotation.z = lerp(head.rotation.z, deg_to_rad(20.0) * wall_check_r.get_collision_normal().length(), lerp_speed * delta)
	else:
		head.rotation.z = lerp(head.rotation.z, deg_to_rad(0.0), lerp_speed * delta)
	# Smooth camera movement
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 70 * delta, delta * 5)	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 50)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25)

func _process_gravity(delta):
	# Slower fall while on wall
	if wall_running and self.velocity.y <= 0.0:
		self.velocity.y *= 0.7
	# Apply gravity
	self.velocity.y -= gravity * delta

func _physics_process(delta):
	on_floor = is_on_floor()
	# Decrease wall run cooldown
	if wall_run_cooldown >= 0.0: wall_run_cooldown -= delta
	# If the cooldown is down, can wall run again
	if wall_run_cooldown <= 0.0:
		can_wall_run = true
	# If on air, momentum reset cooldown is up
	if !on_floor:
		if hitGroundCooldown != hitGroundCooldownRef: hitGroundCooldown = hitGroundCooldownRef
	# If is on floor, decrease momentum reset cooldown
	if on_floor:
		if hitGroundCooldown >= 0: hitGroundCooldown -= delta

	# Call function to display speed lines when going fast
	hud.display_speed_lines(Vector3(velocity.x, 0.0, velocity.z).length(), movement_speed)
	
	# Handle functions
	handle_controls(delta)
	move(delta)
	_process_camera(delta)
	_distort_camera(delta)
	_push_away_rigid_bodies()
	_wall_run(delta)
	move_and_slide()
	update_signals()
=======
			if mass_ratio < 0.25:
				continue
			push_dir.y = 0
			var push_force = mass_ratio
			push_force = clamp(push_force, 0.0, 10.0)
			c.get_collider().apply_impulse(
				push_dir * velocity_diff_in_push_dir * push_force,
				c.get_position() - c.get_collider().global_position
				)

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
	if input_dir:
		self.velocity.x = direction.x * get_move_speed()
		self.velocity.z = direction.z * get_move_speed()
	else:
		self.velocity.x = move_toward(self.velocity.x, 0., movement_speed)
		self.velocity.z = move_toward(self.velocity.z, 0., movement_speed)
	if !dashing:
		_headbob_effect(_delta)

func _handle_air_physics(_delta):
	_process_gravity(_delta)
	if input_dir:
		desired_velocity.x = direction.x * get_move_speed()
		desired_velocity.z = direction.z * get_move_speed()
		self.velocity.x = move_toward(self.velocity.x, desired_velocity.x, air_control)
		self.velocity.z = move_toward(self.velocity.z, desired_velocity.z, air_control)
	if is_on_wall():
		_wall_run(_delta)
	else:
		_stop_wall_run()

func _physics_process(_delta):
	# Handle functions
	handle_controls(_delta)
	if is_on_floor():
		wall_jump_counter = 0
		if !sliding or crawling:
			_handle_ground_physics(_delta)
	else:
		_handle_air_physics(_delta)
	
	_process_camera(_delta)
	_distort_camera(_delta)
	_push_away_rigid_bodies()
	move_and_slide()
	_emit_debug_info()
>>>>>>> main
	
func _unhandled_input(event):
	# Mouse movement
	if event is InputEventMouseMotion and mouse_captured:
		input_mouse = event.relative / mouse_sensitivity
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity

<<<<<<< HEAD
func handle_controls(delta):
=======
func handle_controls(_delta):
	# Get direction
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").normalized()
	direction = lerp(direction, self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y), _delta * lerp_speed)
		
>>>>>>> main
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
<<<<<<< HEAD
	if on_floor and !sliding:
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			jump(0.0)
	
	# Sliding and slam control
	if Input.is_action_pressed("crouch") and can_crouch:
		if !on_floor and !sliding:
			self.velocity.y -= gravity * slam_strength
			slaming = true
			can_crouch = false
		else:
			_slide(delta)
	elif !ceilingCheck.is_colliding() and on_floor:
		slaming = false
		_stop_slide(delta)
=======
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
>>>>>>> main
	elif ceilingCheck.is_colliding() and velocity.length() <= 2.0:
		crawling = true
	if Input.is_action_just_released("crouch"):
		can_crouch = true
<<<<<<< HEAD
	
	# Dash control
	if (
		Input.is_action_just_pressed("dash")
		and !sliding
		and dash_cooldown <= 0.0
		and dash_counter < possible_dashs
		):
		dash_counter += 1
		dashing = true
		dashing_timer = dash_duration
		dash_cooldown = 0.5
	if dashing_timer > 0.0:
		self.velocity.y = 0.0
		dashing_timer -= delta
	else:
		if dash_cooldown >= 0.0:
			dash_cooldown -= delta
		dashing = false
	
func move(delta):
	# Get direction
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if desired_velocity < get_move_speed(): desired_velocity = velocity.length()
	if wall_running:
		direction = velocity.normalized()
	
	elif sliding and !crawling:
		if direction == Vector3.ZERO:
			direction = (self.global_transform.basis * Vector3(slide_vector.x, 0.0, slide_vector.y)).normalized()
	
	elif dashing:
		if direction == Vector3.ZERO:
			direction = (self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	else:
		direction = (self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	
	if on_floor:
		wall_jump_counter = 0
		dash_counter = 0
		if direction:
			if sliding:
				if velocity.length() < get_move_speed():
					velocity.x = direction.x * get_move_speed()
					velocity.z = direction.z * get_move_speed()
				else:
					velocity.x = direction.x * desired_velocity
					velocity.z = direction.z * desired_velocity
			elif dashing:
				velocity.x = direction.x * get_move_speed()
				velocity.z = direction.z * get_move_speed()
			else:
				self.velocity.x = lerp(velocity.x, direction.x * get_move_speed(), acceleration * delta)
				self.velocity.z = lerp(velocity.z, direction.z * get_move_speed(), acceleration * delta)
				if hitGroundCooldown <= 0 and desired_velocity >= velocity.length():
					desired_velocity -= ground_decel * delta
		else:
			self.velocity.x = lerp(velocity.x, 0.0, ground_decel * delta)
			self.velocity.z = lerp(velocity.z, 0.0, ground_decel * delta)
			desired_velocity = velocity.length()
		if !sliding and !dashing:
			_headbob_effect(delta)

	if !on_floor:
		_process_gravity(delta)
		if direction:
			if dashing:
				velocity.x = direction.x * get_move_speed()
				velocity.z = direction.z * get_move_speed()
			else:
				if desired_velocity < max_speed: desired_velocity += 0.2 * delta
				
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
				desired_velocity += 1.5 * delta
				velocity.x = direction.x * desired_velocity
				velocity.z = direction.z * desired_velocity
				
	if desired_velocity >= max_speed: desired_velocity = max_speed

func jump(strength_value : float):
	if wall_running:
		wall_running = false
		can_wall_run = false
		if wall_check_l.is_colliding():
			velocity = wall_check_l.get_collision_normal() * wall_jump_force
		else:
			velocity = wall_check_r.get_collision_normal() * wall_jump_force
		wall_run_cooldown = 0.5
		
	self.velocity.y = jump_strength + strength_value

func _wall_run(_delta):
	if !on_floor and is_touching_wall() and can_wall_run:
		wall_running = true
		if Input.is_action_just_pressed("jump") and wall_jump_counter < possible_wall_jumps:
			wall_jump_counter += 1
			jump(5)
			self.velocity.y = jump_strength
	else:
		wall_running = false

func _slide(delta):
	head.position.y = lerp(head.position.y, sliding_height, delta * lerp_speed)
	sliding = true
	if input_dir != Vector2.ZERO: slide_vector = input_dir 
	else: slide_vector = Vector2(0, -1)
	standing_collision_shape.disabled = true
	sliding_collision_shape.disabled = false
func _stop_slide(delta):
	head.position.y = lerp(head.position.y, 1.75, delta * lerp_speed)
=======

func _slide(_delta):
	head.position.y = lerp(head.position.y, sliding_height, _delta * lerp_speed)
	sliding = true
	standing_collision_shape.disabled = true
	sliding_collision_shape.disabled = false
func _stop_slide(_delta):
	head.position.y = lerp(head.position.y, 1.75, _delta * lerp_speed)
>>>>>>> main
	sliding = false
	crawling = false
	standing_collision_shape.disabled = false
	sliding_collision_shape.disabled = true

<<<<<<< HEAD
func _headbob_effect(delta):
	headbob_time += delta * self.velocity.length()
=======
func _wall_run(_delta):
	if !sliding:
		wall_running = true
		if Input.is_action_just_pressed("jump") and wall_jump_counter < possible_wall_jumps:
			wall_normal = get_wall_normal()
			wall_jump_counter += 1
			direction = wall_normal
			self.velocity.y = jump_strength
			can_wall_run = false
func _stop_wall_run():
	wall_running = false

func _headbob_effect(_delta):
	headbob_time += _delta * self.velocity.length()
>>>>>>> main
	camera.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)

# FOV when running or standing still for too long
<<<<<<< HEAD
func _distort_camera(delta):
	if mouse_captured and (velocity.length() <= 0.0 and !debug_mode) or position.y < -350.0:
		camera_distortion += camera_distortion_strength * delta
=======
func _distort_camera(_delta):
	if mouse_captured and (velocity.length() <= 0.0 and !debug_mode) or position.y < -350.0:
		camera_distortion += camera_distortion_strength * _delta
>>>>>>> main
		if camera_distortion >= 0.0:
			camera_new_fov += camera_distortion
			if camera_distortion >= 1.0:
				get_tree().call_deferred("reload_current_scene")
	elif !slaming:
		camera_new_fov = min(camera_default_fov + (Vector3(velocity.x,0.,velocity.z).length()*0.7),camera_default_fov * 1.3)
		camera_distortion = -1.0
<<<<<<< HEAD
	camera.fov = lerp(camera.fov, camera_new_fov, delta * lerp_speed)
=======
	camera.fov = lerp(camera.fov, camera_new_fov, _delta * lerp_speed)
>>>>>>> main
