extends AnimatedSprite2D

const BASE_AP := 3
const PULSE_DURATION := 0.4

@onready var highlight = $Highlight
@onready var callbacks = $Callbacks

@export var unit_data : UnitDefinition

# Unit stats
var health : int
var power : int
var speed : int
var action_points : int

var team : int = -1 # Unassigned by default

# Board info
var board : TileMap
var board_position : Vector2i

func _ready():
	highlight.position = offset
	highlight.modulate = Color.TRANSPARENT
	animation_finished.connect(_animation_finished)
	
	if unit_data.callbacks:
		callbacks.set_script(unit_data.callbacks)

func select():
	modulate = Color.GREEN

func deselect():
	modulate = Color.WHITE

func pulse_highlight():
	highlight.modulate = Color.WHITE
	highlight.scale = Vector2.ONE * 1.5
	var tween = get_tree().create_tween()
	tween.tween_property(highlight, 'scale', Vector2.ONE, PULSE_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(highlight, 'modulate', Color.TRANSPARENT, PULSE_DURATION).set_ease(Tween.EASE_OUT)

func can_be_moved_into(): # Can another unit move into our space?
	return callbacks.has_method('on_overlap')

func replenish_ap():
	action_points = BASE_AP

func hurt(damage : int, pushback : Vector2i, source):
	health -= damage
	play(&'hurt')
	
	if callbacks.has_method('on_hurt'):
		callbacks.on_hurt(board, self, damage, pushback, source)
	
	if health <= 0:
		# Ganon voice: DIE!!!
		if callbacks.has_method('on_defeat'):
			callbacks.on_defeat(board, self, source)
		
		board.remove_unit(self)
		visible = false
		return
	
	if pushback != Vector2i.ZERO:
		var dir = pushback.clamp(-Vector2i.ONE, Vector2i.ONE)
		var final_pos = board.test_linear_move(board_position, dir, pushback.length())
		var old_pos = board_position
		var world_pos = board.map_to_local(final_pos)
		var tween = get_tree().create_tween().tween_property(self, 'position', world_pos, (old_pos - final_pos).length() * 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
		await tween.finished
		board.move_unit(self, final_pos)

func follow_path(board_path : Array): # Path is expected in tilemap/board coordinates
	if not board:
		push_error("Cannot move unit when no board is assigned!")
		return
	var prev = board_path[0]
	for point in board_path:
		var world_pos = board.map_to_local(point)
		# Flip
		var look_dir = sign(world_pos.x - position.x)
		if look_dir != 0: flip_h = look_dir == -1
		var tween = get_tree().create_tween().tween_property(self, 'position', world_pos, Vector2(prev - point).length() * 0.2)
		await tween.finished
		prev = point

func get_info_string():
	return "%s\n%d AP\nHealth: %d/%d\nSpeed: %d\nPower: %d" % [unit_data.name, action_points, health, unit_data.max_health, speed, power]

func set_unit_data(data : UnitDefinition, reset : bool = true):
	unit_data = data
	
	# Set properties
	if reset:
		health = unit_data.max_health
		power = unit_data.base_power
		speed = unit_data.base_speed
		action_points = BASE_AP
	
	sprite_frames = unit_data.board_animations
	
	play(&'default') # Default 

func _animation_finished():
	play(&'default') # Default
