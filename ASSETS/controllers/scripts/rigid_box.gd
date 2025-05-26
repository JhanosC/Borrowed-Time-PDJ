extends RigidBody3D

var thrown := false
var targeted := false
var held := false
@onready var outline: MeshInstance3D = $MeshInstance3D/Outline
@onready var freeze_outline = $MeshInstance3D/FreezeOutline

# Called when the node enters the scene tree for the first time.
func _ready():
	contact_monitor = true
	max_contacts_reported = 4
	outline.hide()
	freeze_outline.hide()
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if linear_velocity.length() <= 0.0:
		thrown = false
	if targeted and not held:
		enable_outline()
	elif outline.visible == true:
		disable_outline()
	if freeze:
		freeze_outline.show()
	else:
		freeze_outline.hide()

func throw(push_dir, push_force):
	thrown = true
	lock_rotation = false
	apply_impulse(push_dir * push_force)

func enable_outline():
	outline.show()
func disable_outline():
	outline.hide()
func change_to_freeze_state():
	freeze = true

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not thrown:
		return
	var count = state.get_contact_count()
	for i in count:
		var other = state.get_contact_collider_object(i)
		# skip if the thing we hit is a RigidBody3D or CharacterBody3D
		if other is RigidBody3D or other is CharacterBody3D:
			continue
		# otherwise, align to this surface and break out
		var normal = state.get_contact_local_normal(i)
		_align_to_normal(normal)
		thrown = false
		sleeping = true
		call_deferred("change_to_freeze_state")

func _align_to_normal(normal: Vector3) -> void:
	# Pick a world-up that isn’t colinear with the normal
	var world_up = Vector3.UP
	if abs(normal.dot(world_up)) > 0.9:
		world_up = Vector3.FORWARD
	var new_basis = Basis.looking_at(-normal, world_up)
	global_transform.basis = new_basis
