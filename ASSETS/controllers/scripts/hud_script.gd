extends Control

@onready var speed_lines = $SpeedLines
@onready var time: Label = $Time
@onready var dash_storage: ProgressBar = $DashStorage
var time_passed = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	speed_lines.visible = false

func display_speed_lines(current_velocity, base_velocity):
	if current_velocity > base_velocity * 1.3:
		speed_lines.visible = true
	else:
		speed_lines.visible = false

func display_fall_lines(current_velocity, base_velocity):
	if current_velocity > base_velocity * 1.3:
		speed_lines.visible = true
	else:
		speed_lines.visible = false

func display_time(delta):
	time_passed += delta
	time.text = str(time_passed).pad_decimals(2)
	
func get_time():
	return time_passed

func update_dash_storage(dash_amount, max_dash_amount):
	dash_storage.max_value = max_dash_amount
	dash_storage.value = dash_amount

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	display_time(delta)
