extends Camera2D

@export var camera_move_speed : float = 300

var bounding_rect : Rect2

var initial_position : Vector2
var tween : Tween

var screenshake_amt : float
var screenshake_duration : float

func _ready():
	initial_position = position

func _unhandled_input(event):
	if not is_tweening():
		if event is InputEventMouseMotion:
			if Input.is_action_pressed("drag_camera"):
				position -= event.relative
				clamp_position()
		
		if Input.is_action_just_pressed("reset_camera"):
			pan_to(initial_position)

func _process(delta):
	
	if not is_tweening():
		var move = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
		position += move.normalized() * get_process_delta_time() * camera_move_speed
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

func is_tweening():
	return tween and tween.is_running()

func pan_to(pos : Vector2):
	tween = get_tree().create_tween()
	tween.tween_property(self, 'position', pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

func screenshake(amt : float = 2, duration : float = 0.2):
	screenshake_amt = amt
	screenshake_duration = duration
