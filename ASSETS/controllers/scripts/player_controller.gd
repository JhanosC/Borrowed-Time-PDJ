class_name Player extends CharacterBody3D

@export_subgroup("Properties")
@export var jump_strength := 7.0
@export var slam_strength := 7.0
@export var mouse_sensitivity = 700
var move_foward_vector : Vector2 = Vector2.ZERO
const HEADBOB_MOVE_AMOUNT = 0.1
const HEADBOB_FREQUENCY = 1.0
var headbob_time := 0.0
var lerp_speed := 10.0
var sliding_height := 0.75
var gravity := 0.0
var camera_distortion := -1.0
var camera_distortion_strength := 0.6
var camera_default_fov := 75.0
var camera_new_fov := camera_default_fov

@export_subgroup("States")
@export var auto_bhop := true
var wall_running := false
var sliding := false
var dashing := false
var can_crouch := true
var slaming := false
var mouse_captured := true
var crawling := false
var can_wall_run := true
var on_floor := true
var pulled = false
var holding = false
var hook_out = false
var reloading_scene = false
var slow_time := false


@export var max_slow_time_amount := 10.0
var slow_time_amount := 10.0
var slow_cooldown := 3.0
var slow_speed_multiplier:= 4.0

@export_subgroup("Movement Settings")
@export var movement_speed : float
@export var max_speed : float
@export var hitGroundCooldown := 0.2
@export var ground_decel := 10.0
@export var acceleration := 5.0
@export var desiredMoveSpeedCurve : Curve
@export var inAirMoveSpeedCurve : Curve
@export var dash_cooldown := 0.0
@export var wall_jump_force := 20.0
@export var dash_duration := 0.05
@export var dash_speed_multiplier := 5.0
@export var crawl_speed_multiplier := 0.7
@export var dash_refresh_rate := 2.5
@export var max_dash_storage := 5.0
var current_dash_storage := 0.0
var dashing_timer := 0.0
var previous_dash_velocity := 0.0
var desired_velocity := 0.0
var hitGroundCooldownRef : float

var direction := Vector3.ZERO
var wall_jump_counter := 0
var wall_run_cooldown := 0.0
var possible_wall_jumps := 3

var picked_object : RigidBody3D = null
var selected_object = null
const pull_power := 20.0

var rotation_target: Vector3
var input_mouse: Vector2
var input_dir: Vector2

signal velocity_update(velocity: Vector3, desired_velocity: float)
signal states_update(can_crouch:bool,slaming:bool,sliding:bool,wall_running:bool,on_floor:bool,on_wall:bool,direction:Vector3)

@onready var camera = $CameraController/Camera3D
@onready var head: Node3D = $CameraController
@onready var face_check: RayCast3D = $Raycasts/FaceCheck
@onready var ceilingCheck = $Raycasts/CeilingCheck
@onready var wall_check_r: RayCast3D = $Raycasts/WallCheckR
@onready var wall_check_l: RayCast3D = $Raycasts/WallCheckL
@onready var aim_raycast: RayCast3D = $CameraController/Camera3D/AimRaycast
@onready var aim_shape_cast: ShapeCast3D = $CameraController/Camera3D/AimShapeCast
@onready var pull_point: Marker3D = $CameraController/Camera3D/PullPoint
@onready var big_pull_point = $CameraController/Camera3D/BigPullPoint
@onready var standing_collision_shape: CollisionShape3D = $StandingCollisionShape
@onready var sliding_collision_shape: CollisionShape3D = $SlidingCollisionShape
@onready var mesh: MeshInstance3D = $WorldModel/MeshInstance3D
@onready var hud = $HUD
@onready var hook_controller: HookController = $HookController

@onready var landind: AudioStreamPlayer3D = $sounds/landing
@onready var slow_motion_sound: AudioStreamPlayer3D = $sounds/slow_motion_sound
@onready var slow_motion_stop_sound: AudioStreamPlayer3D = $sounds/slow_motion_stop_sound
@onready var running_sound: AudioStreamPlayer3D = $sounds/running_sound
@onready var jump_voice_sound: AudioStreamPlayer3D = $sounds/jump_voice 
@onready var dash_sound_effect: AudioStreamPlayer3D = $sounds/dash_sound_effect 
@onready var sliding_sound_effect: AudioStreamPlayer3D = $sounds/sliding_sound_effect 

var debug_mode = true

func update_signals():
	states_update.emit(can_crouch,slaming,sliding,wall_running,on_floor,is_touching_wall(),direction)
	velocity_update.emit(Vector3(velocity.x,0.0,velocity.z).length(), desired_velocity, current_dash_storage)

func get_move_speed() -> float:
	if crawling:
		return movement_speed * crawl_speed_multiplier
	elif dashing:
		return movement_speed * dash_speed_multiplier
	return movement_speed

func is_touching_wall() -> bool:
	var checks = [wall_check_l, wall_check_r, face_check]
	for check in checks:
		if check.is_colliding():
			var collider : Node3D = check.get_collider()
			match collider:
				null:
					pass
				_:
					if collider.is_in_group("walls"):
						return true
	return false

func _ready():
	current_dash_storage = max_dash_storage
	sliding_collision_shape.disabled = true
	standing_collision_shape.disabled = false
	hitGroundCooldownRef = hitGroundCooldown
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	camera.fov = camera_default_fov
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _push_away_rigid_bodies():
	# Handle colision with RigidBodies
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			var push_dir = -c.get_normal()
			push_dir.y = 0 # Do not push down or up
			var velocity_diff_in_push_dir = self.velocity.dot(push_dir) - c.get_collider().linear_velocity.dot(push_dir)
			velocity_diff_in_push_dir = max(0., velocity_diff_in_push_dir)
			const MY_APPROX_MASS_KG = 60.0
			var mass_ratio = min(1., MY_APPROX_MASS_KG / c.get_collider().mass)
			var push_force = mass_ratio * 2.0
			push_force = clamp(push_force, 0.0, 10.0)
			
			c.get_collider().apply_impulse(
				push_dir * velocity_diff_in_push_dir * push_force,
				c.get_position() - c.get_collider().global_position)

func _process_camera(delta):
	var axis_vector = Vector2.ZERO
	axis_vector.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	axis_vector.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	if wall_running:
		var aim = get_global_transform().basis
		var foward = -aim.z
		if wall_check_l.is_colliding():
			var rotation_degree = PI/2.0 - foward.angle_to(wall_check_l.get_collision_normal())
			rotation_degree = deg_to_rad(clamp(rotation_degree*20 + 20, -20.0, 30.0))
			head.rotation.z = lerp(head.rotation.z, rotation_degree * -(wall_check_l.get_collision_normal().length()), lerp_speed * delta)
		else:
			var rotation_degree = PI/2.0 - foward.angle_to(wall_check_r.get_collision_normal())
			rotation_degree = deg_to_rad(clamp(rotation_degree*20 + 10, -20.0, 30.0))
			head.rotation.z = lerp(head.rotation.z, rotation_degree * wall_check_r.get_collision_normal().length(), lerp_speed * delta)
	else:
		head.rotation.z = lerp(head.rotation.z, deg_to_rad(0.0), lerp_speed * delta)
		
	var speed_factor = slow_speed_multiplier if slow_time else 1.0
	rotation_target.y -= axis_vector.x * 5.0 * delta * speed_factor
	rotation_target.x -= axis_vector.y * 5.0 * delta * speed_factor

	# Smooth camera movement
	camera.rotation.z = lerp_angle(camera.rotation.z, -input_mouse.x * 70 * delta, delta * 5 * speed_factor)	
	camera.rotation.x = lerp_angle(camera.rotation.x, rotation_target.x, delta * 50 * speed_factor)
	rotation.y = lerp_angle(rotation.y, rotation_target.y, delta * 25 * speed_factor)

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
	if wall_run_cooldown <= 0.0 and (Vector3(velocity.x, 0.0, velocity.z).length() >= get_move_speed() * 0.7 or face_check.is_colliding()) and !on_floor and is_touching_wall():
		can_wall_run = true
	else:
		can_wall_run = false
	# If on air, momentum reset cooldown is up
	if !on_floor:
		if hitGroundCooldown != hitGroundCooldownRef: 
			hitGroundCooldown = hitGroundCooldownRef
	# If is on floor, decrease momentum reset cooldown
	if on_floor:
		slaming = false
		wall_jump_counter = 0 # Reset wall jump counter when hit the ground
		if hitGroundCooldown >= 0: hitGroundCooldown -= delta

	# Call function to display speed lines when going fast
	hud.display_speed_lines(Vector3(velocity.x, 0.0, velocity.z).length(), movement_speed)
	hud.update_dash_storage(current_dash_storage, max_dash_storage)
	hud.update_slow_down_storage(slow_time_amount,10.0)
	hud.display_debug_info(can_crouch,slaming,sliding,wall_running,on_floor,is_touching_wall(),hook_out,direction,Vector3(velocity.x, 0.0, velocity.z).length(),desired_velocity)
	
	# Handle functions
	handle_controls(delta)
	move(delta)
	_process_camera(delta)
	_distort_camera(delta)
	_push_away_rigid_bodies()
	_wall_run(delta)
	if !hook_out:
		sel_object()
	if !hook_out or (picked_object and picked_object.is_in_group("big_object")):
		pull_object()
	move_and_slide()
	update_signals()
	
func _unhandled_input(event):
	# Mouse movement
	if event is InputEventMouseMotion and mouse_captured:
		input_mouse = event.relative / mouse_sensitivity
		rotation_target.y -= event.relative.x / mouse_sensitivity
		rotation_target.x -= event.relative.y / mouse_sensitivity

func reload_scene():
	Global.game_controller.reload_scene()

func handle_controls(delta):
	# Reload sc43ene
	if Input.is_action_just_pressed("reload"):
		reloading_scene = true
		Global.game_controller.reload_scene()
	
	if Input.is_action_just_pressed("1"):
		Global.game_controller.load_new_scene("res://ASSETS/scenes/levels/test_level_1.tscn")
	if Input.is_action_just_pressed("2"):
		Global.game_controller.load_new_scene("res://ASSETS/scenes/levels/test_level_2.tscn")
	if Input.is_action_just_pressed("3"):
		Global.game_controller.load_new_scene("res://ASSETS/scenes/levels/test_level_3.tscn")
	if Input.is_action_just_pressed("4"):
		print('pressed')
		Global.game_controller.load_new_scene("res://ASSETS/scenes/levels/level_2.tscn")
	
	if Input.is_action_just_pressed("right_mouse"):
		if slow_time:
			Engine.time_scale = 1.0
			slow_time = false
			slow_motion_sound.playing = false
			slow_motion_stop_sound.play()

		else:
			Engine.time_scale /= slow_speed_multiplier
			slow_time = true
			slow_motion_sound.playing = true
			
	if slow_time:
		_slow_bar(delta)
	else:
		_slow_bar_refill(delta)
	
	#Mouse capture/Enable cursor
	if !mouse_captured:
		if Input.is_action_just_pressed("left_mouse"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			mouse_captured = true
			Engine.time_scale = 1.0
	else:
		if Input.is_action_just_pressed("left_mouse"):
			if holding:
				throw_object()
			else:
				pick_object()
				retract_release_hook()
		if Input.is_action_just_released("left_mouse"):
			if hook_out:
				retract_release_hook()
			if holding:
				if picked_object.is_in_group("big_object"):
					picked_object.change_to_freeze_state()
					release_object()
			
	if Input.is_action_just_pressed("interact"):
		if holding:
			release_object()
	
	if Input.is_action_just_pressed("mouse_capture_exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
		input_mouse = Vector2.ZERO
	rotation_target.x = clamp(rotation_target.x, deg_to_rad(-90), deg_to_rad(90))
	# Jumping control
	if on_floor and !sliding:
		if Input.is_action_just_pressed("jump") or (auto_bhop and Input.is_action_pressed("jump")):
			jump(0.0)
	if hook_out:
		if Input.is_action_just_pressed("jump") and !holding:
			jump(2.0)
			retract_release_hook()
		
	# Sliding and slam control
	if Input.is_action_pressed("crouch") and can_crouch:
		if !on_floor and !sliding:
			if hook_out:
				retract_release_hook()
			self.velocity.y = -(gravity * slam_strength)
			slaming = true
			can_crouch = false
		else:
			_slide(delta)
	elif !ceilingCheck.is_colliding():
		_stop_slide(delta)
	elif ceilingCheck.is_colliding() and velocity.length() <= 2.0:
		crawling = true
	if Input.is_action_just_released("crouch"):
		can_crouch = true
	
	# Dash control
	if (
		Input.is_action_just_pressed("dash")
		and !sliding
		and dash_cooldown <= 0.0
		and current_dash_storage >= 5.0
		and direction
		):
		dash_sound_effect.play()
		if hook_out:
			retract_release_hook()
		previous_dash_velocity = desired_velocity
		_dash() # Update variables to allow to dash

	# Handle dash uses and recharge
	if dashing_timer > 0.0:
		self.velocity.y = 0.0
		dashing_timer -= delta
	else:
		if current_dash_storage < max_dash_storage:
			current_dash_storage += dash_refresh_rate * delta
		if dash_cooldown >= 0.0:
			dash_cooldown -= delta
		_stop_dash()
	
func move(delta):
	# Get direction
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	# Desired velocity can't be lower than the actual velocity
	if desired_velocity < get_move_speed(): desired_velocity = velocity.length()
	# Keep on same direction when wall running
	if wall_running:
		direction = velocity.normalized()
		#direction = (self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	# If sliding or dashing, can't change direction. But if is crawling, can change
	elif (sliding and !crawling) or dashing:
		if direction == Vector3.ZERO:
			direction = (self.global_transform.basis * Vector3(move_foward_vector.x, 0.0, move_foward_vector.y)).normalized()
	# If not doing anything above, walks normally
	else:
		direction = (self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	
	# Apply direction based on state
	if on_floor:
		if direction:
			var speed = self.direction.x + self.direction.z
			if speed != 0 and on_floor and !sliding:
				if not running_sound.playing:
					running_sound.play()
					running_sound.pitch_scale = get_move_speed() * 0.03
			else:
				running_sound.stop()
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
				# Lose momentum when on ground
				if hitGroundCooldown <= 0 and desired_velocity >= velocity.length():
					desired_velocity -= ground_decel * delta * 5
		# Smooth slow down when not giving an input
		else:
			self.velocity.x = lerp(velocity.x, 0.0, ground_decel * delta)
			self.velocity.z = lerp(velocity.z, 0.0, ground_decel * delta)
			desired_velocity = velocity.length()
		if !sliding and !dashing:
			_headbob_effect(delta)

	if !on_floor:
		running_sound.stop()
		_process_gravity(delta)
		if direction:
			if dashing:
				velocity.x = direction.x * get_move_speed()
				velocity.z = direction.z * get_move_speed()
			else:
				# Apply momentum when on air
				#if desired_velocity < max_speed: desired_velocity += 0.2 * delta
				
				## Curves for air acceleration
				#var contrdDesMoveSpeed : float = desiredMoveSpeedCurve.sample(desired_velocity/100)
				#var contrdInAirMoveSpeed : float = inAirMoveSpeedCurve.sample(desired_velocity)
			#
				#velocity.x = lerp(velocity.x, direction.x * contrdDesMoveSpeed, contrdInAirMoveSpeed * delta)
				#velocity.z = lerp(velocity.z, direction.z * contrdDesMoveSpeed, contrdInAirMoveSpeed * delta)
				self.velocity.x = lerp(velocity.x, direction.x * get_move_speed(), acceleration * delta)
				self.velocity.z = lerp(velocity.z, direction.z * get_move_speed(), acceleration * delta)
				
		else:
			desired_velocity = velocity.length()
	if is_touching_wall():
		if wall_running:
			if direction:
				desired_velocity += 1.0 * delta
				velocity.x = direction.x * desired_velocity
				velocity.z = direction.z * desired_velocity
				
	if sliding and !sliding_sound_effect.playing:
		sliding_sound_effect.play()
	elif !sliding and sliding_sound_effect.playing:
		sliding_sound_effect.stop()
	if desired_velocity >= max_speed: desired_velocity = max_speed

# Handles jump
func jump(strength_value : float):
	jump_voice_sound.play()
	if wall_running: # Jump away from wall
		if wall_check_l.is_colliding():
			velocity = wall_check_l.get_collision_normal() * wall_jump_force
		else:
			velocity = wall_check_r.get_collision_normal() * wall_jump_force
			
	self.velocity.y += jump_strength + strength_value

func _wall_run(_delta):
	if can_wall_run and !hook_out:
		wall_running = true
		if Input.is_action_just_pressed("jump"):
			if wall_jump_counter < possible_wall_jumps:
				wall_jump_counter += 1
				jump(2.0)
				self.velocity.y = jump_strength
			wall_running = false
			wall_run_cooldown = 0.2
	else:
		wall_running = false

func _slide(delta):
	head.position.y = lerp(head.position.y, sliding_height, delta * lerp_speed)
	sliding = true
	# If start sliding, keep on same direction the player started
	if input_dir != Vector2.ZERO: move_foward_vector = input_dir 
	# If try to slide while idle, slide foward
	else: move_foward_vector = Vector2(0, -1)
	standing_collision_shape.disabled = true
	sliding_collision_shape.disabled = false
func _stop_slide(delta):
	head.position.y = lerp(head.position.y, 1.75, delta * lerp_speed)
	sliding = false
	crawling = false
	standing_collision_shape.disabled = false
	sliding_collision_shape.disabled = true

func _dash():
	## If start dashing, keep on same direction the player started
	#if input_dir != Vector2.ZERO: move_foward_vector = input_dir
	## If try to dash while idle, slide foward
	#else: move_foward_vector = Vector2(0, -1)
	current_dash_storage -= 5.0
	dashing = true
	slaming = false
	dashing_timer = dash_duration
	dash_cooldown = 0.5

func _stop_dash():
	#if dashing:
	desired_velocity = previous_dash_velocity
	dashing = false

func _slow_bar(delta):
	if slow_time_amount > 0:
		slow_time_amount -= 10.0 * delta
	else:
		Engine.time_scale = 1.0
		slow_time = false

func _slow_bar_refill(delta):
	if slow_time_amount < 10.0:
		slow_time_amount += delta * slow_cooldown

func sel_object():
	if not holding and aim_shape_cast.is_colliding():
		var collider = aim_shape_cast.get_collider(0)
		if selected_object != collider:
			if collider != null and "targeted" in collider:
				collider.targeted = true
			if selected_object != null and "targeted" in selected_object:
				selected_object.targeted = false
		if collider is RigidBody3D:
			selected_object = collider
	elif selected_object:
		selected_object.targeted = false
		selected_object = null

func pick_object():
	if selected_object:
		if selected_object is RigidBody3D and not (selected_object.is_in_group("grappable") and selected_object.freeze):
			if selected_object.is_in_group("big_object"):
				big_pull_point.global_position = selected_object.global_transform.origin
			holding = true
			selected_object.held = true
			selected_object.lock_rotation = true
			selected_object.freeze = false
			selected_object.add_collision_exception_with(self)
			picked_object = selected_object

func pull_object():
	if picked_object != null and holding: 
		var object_pos = picked_object.global_transform.origin
		var hand_pos : Vector3
		if picked_object.is_in_group("big_object"):
			hand_pos = big_pull_point.global_position
		else:
			hand_pos = pull_point.global_position
		var pull_direction = hand_pos - object_pos
		if pull_direction.length() > 0.0:
			picked_object.linear_velocity = pull_direction * pull_power
			picked_object.global_transform.basis = global_transform.basis
		
		var hand_position_from_player = (big_pull_point.global_position - self.global_position).normalized()
		if Input.is_action_just_pressed("scroll_up"):
			big_pull_point.global_position += hand_position_from_player
		if Input.is_action_just_pressed("scroll_down"):
			big_pull_point.global_position -= hand_position_from_player

func throw_object():
	var push_dir = (aim_raycast.to_global(aim_raycast.target_position) - aim_raycast.to_global(Vector3.ZERO)).normalized()
	var push_force = 100.0
	picked_object.throw(push_dir, push_force)
	release_object()

func release_object():
	picked_object.held = false
	picked_object.lock_rotation = false
	picked_object.remove_collision_exception_with(self)
	holding = false

func retract_release_hook():
	if !slaming:
		hook_controller._release_hook()

func _headbob_effect(delta):
	headbob_time += delta * self.velocity.length()
	camera.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)

# FOV when running, standing still for too long or falling from map
func _distort_camera(delta):
	if mouse_captured and (Vector3(velocity.x,0.0,velocity.z).length() <= 13.0 and !debug_mode) or position.y < -150.0:
		camera_distortion += camera_distortion_strength * delta
		if camera_distortion >= 0.0:
			camera_new_fov += camera_distortion
			if camera_distortion >= 1.0 and not reloading_scene:
				reloading_scene = true
				Global.game_controller.reload_scene()
	elif !slaming:
		camera_new_fov = min(camera_default_fov + (Vector3(velocity.x,0.,velocity.z).length()*0.7),camera_default_fov * 1.3)
		camera_distortion = -1.0
	camera.fov = lerp(camera.fov, camera_new_fov, delta * lerp_speed)
