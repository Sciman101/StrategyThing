extends Node2D

@onready var cursor = $Cursor
@onready var camera = $Camera2D
@onready var board = $Board
@onready var controls = $UI/Controls

var cursor_pos : Vector2i

var selected_unit = null
var current_action = null
var is_busy = false

signal process_action

func _ready():
	deselect_unit()
	controls.action_selected.connect(_action_selected)
	
	# Assign bounding rect to the camera
	var rect = board.get_used_rect()
	camera.bounding_rect = Rect2(board.map_to_local(rect.position),Vector2.ZERO)
	camera.bounding_rect = camera.bounding_rect.expand(board.map_to_local(rect.position + rect.size))

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Move the cursor
		var mp = get_global_mouse_position()
		var prev_cursor_pos = cursor_pos
		cursor_pos = board.local_to_map(mp)
		if prev_cursor_pos != cursor_pos:
			cursor.position = board.map_to_local(cursor_pos)
			if current_action:
				process_action.emit({highlighted_cell=cursor_pos})
			if not selected_unit:
				var hovered_unit = board.get_unit(cursor_pos)
				controls.show_unit_info(hovered_unit)
	
	elif event is InputEventMouseButton:
		if current_action == null:
			# Unit selection
			if Input.is_action_just_released("select"):
				# Try and select a unit
				var unit = board.get_unit(cursor_pos)
				if unit:
					deselect_unit()
					select_unit(unit)
				else:
					deselect_unit()
			
			elif Input.is_action_just_released("deselect"):
				deselect_unit()
		else:
			# Handle current action
			if Input.is_action_just_released("select"):
				# Send signal into the action
				process_action.emit({selected_cell=cursor_pos})
				
			# Feed selection back into the current action
			elif Input.is_action_just_released("deselect"):
				if not is_busy:
					# Stop it
					process_action.emit({cancel=true}) # Send a signal to abort the current action
					current_action = null
					controls.show()
					board.highlight_clear()
					select_unit(selected_unit)

func select_unit(unit):
	selected_unit = unit
	unit.select()
	controls.show_unit_info(unit)

func deselect_unit():
	if selected_unit:
		selected_unit.deselect()
	selected_unit = null
	controls.show_unit_info(null)
	board.highlight_clear()

func set_busy(busy : bool):
	is_busy = busy

func _action_selected(action : UnitAction):
	controls.hide()
	current_action = action
	# Begin action execution
	var unit = selected_unit
	await action.execute(self, board, unit, process_action, set_busy)
	# Once the action is complete
	# Take AP from unit
	unit.action_points -= action.ap_cost
	current_action = null
	controls.show()
