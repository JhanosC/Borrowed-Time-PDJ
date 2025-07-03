extends Control

@onready var text = $VBoxContainer/Text
var time_on_screen : float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready():
	hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if time_on_screen > 0:
		time_on_screen -= delta
	else:
		hide()

func display_text(text_displayed : String, time: float):
	show()
	text.text = text_displayed
	time_on_screen = time
