extends CenterContainer

@export var DOT_RADIUS : float = 1.0
@export var DOT_COLOR :  Color = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	queue_redraw()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func _draw() -> void:
	draw_circle(Vector2(0,0),DOT_RADIUS,DOT_COLOR)
