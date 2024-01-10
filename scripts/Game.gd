extends Node2D

@onready var cursor = $Cursor
@onready var camera = $Camera2D
@onready var board = $Board
@onready var controls = $UI/Controls

var cursor_pos : Vector2i

var selected_unit = null
var current_action = null

signal process_action

func _ready():
	deselect_unit()
	controls.action_selected.connect(_action_selected)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var mp = get_global_mouse_position()
		cursor_pos = board.local_to_map(mp)
		cursor.position = board.map_to_local(cursor_pos)
	
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
			if Input.is_action_just_released("select"):
				# Send signal into the action
				process_action.emit({selected_cell=cursor_pos})
				
			# Feed selection back into the current action
			elif Input.is_action_just_released("deselect"):
				# Stop it
				process_action.emit({abort=true}) # Send a signal to abort the current action
				current_action = null
				controls.show()
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
	board.select_clear()

func _action_selected(action : UnitAction):
	controls.hide()
	current_action = action
	# Begin action execution
	var unit = selected_unit
	await action.execute(self, board, unit, process_action)
	# Once the action is complete
	# Take AP from unit
	unit.action_points -= action.ap_cost
	current_action = null
	controls.show()
