extends Node2D

@onready var cursor = $Cursor
@onready var camera = $Camera2D
@onready var board = $Board
@onready var controls = $UI/Controls

var cursor_pos : Vector2i

var selected_unit = null

func _ready():
	deselect_unit()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var mp = get_global_mouse_position()
		cursor_pos = board.local_to_map(mp)
		cursor.position = board.map_to_local(cursor_pos)
	
	elif event is InputEventMouseButton:
		if Input.is_action_just_released("select"):
			# Try and select a unit
			var unit = board.get_unit(cursor_pos)
			if unit:
				deselect_unit()
				select_unit(unit)
				board.select_within_distance(unit.board_position, unit.speed)
				board.select_remove_occupied_cells()
			elif selected_unit:
				# Move em
				unit = selected_unit
				deselect_unit()
				var dist = board.manhatten_dist(unit.board_position, cursor_pos)
				if dist <= unit.speed:
					var path = board.find_path(unit.board_position, cursor_pos, true)
					if path.size() > 0:
						# Valid path
						board.move_unit(unit, cursor_pos)
						await unit.follow_path(path)
					else:
						print("Can't go there!")
				else:
					print("Out of range!")
		
		elif Input.is_action_just_released("deselect"):
			deselect_unit()

func select_unit(unit):
	selected_unit = unit
	unit.select()
	controls.show_unit_info(unit)

func deselect_unit():
	if selected_unit:
		selected_unit.deselect()
	selected_unit = null
	controls.show_unit_info(null)
	board.select_clear()
