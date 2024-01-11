extends Camera2D

var bounding_rect : Rect2

var initial_position : Vector2

func _ready():
	initial_position = position

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("move_camera"):
			position -= event.relative
	
	if Input.is_action_just_pressed("reset_camera"):
		position = initial_position

func clamp_position():
	position = position.clamp(bounding_rect.position, bounding_rect.position + bounding_rect.size)
