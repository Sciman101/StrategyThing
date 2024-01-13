extends Camera2D

@export var camera_move_speed : float = 300

var bounding_rect : Rect2

var return_position : Vector2
var tween : Tween

var screenshake_amt : float
var screenshake_duration : float

func _ready():
	return_position = position

func _unhandled_input(event):
	if can_move():
		if event is InputEventMouseMotion:
			if Input.is_action_pressed("drag_camera"):
				position -= event.relative / zoom
				clamp_position()
		
		if Input.is_action_just_pressed("reset_camera"):
			pan_to(return_position)

func _process(delta):
	
	if can_move():
		var move = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
		position += move.normalized() * delta * camera_move_speed / zoom
		clamp_position()
	
	if screenshake_duration > 0:
		screenshake_duration -= delta
		if screenshake_duration <= 0:
			offset = Vector2.ZERO
		else:
			offset = Vector2(randf_range(-screenshake_amt, screenshake_amt),randf_range(-screenshake_amt, screenshake_amt))

# Control methods
func clamp_position():
	position = position.clamp(bounding_rect.position, bounding_rect.position + bounding_rect.size)

func can_move():
	return not (tween and tween.is_running())

func pan_to(pos : Vector2):
	tween = get_tree().create_tween()
	tween.tween_property(self, 'position', pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func screenshake(amt : float = 2, duration : float = 0.2):
	screenshake_amt = amt
	screenshake_duration = duration
