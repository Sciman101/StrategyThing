extends Sprite2D

const BASE_AP := 3

@export var unit_data : UnitDefinition

# Unit stats
var health : int
var power : int
var speed : int
var action_points : int

var team : int = -1 # Unassigned by default

# Board info
var board
var board_position : Vector2i

func _ready():
	health = unit_data.max_health
	power = unit_data.base_power
	speed = unit_data.base_speed
	action_points = BASE_AP
	
	texture = unit_data.board_sprite

func select():
	modulate = Color.GREEN

func deselect():
	modulate = Color.WHITE

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
		var tween = get_tree().create_tween().tween_property(self, 'position', world_pos, Vector2(prev - point).length() * 0.1)
		await tween.finished
		prev = point

func get_info_string():
	return "%s\n%d AP\nHealth: %d/%d\nSpeed: %d\nPower: %d" % [unit_data.name, action_points, health, unit_data.max_health, speed, power]
