extends Node2D

const NUM_TEAMS := 2

@onready var cursor = $Cursor
@onready var camera = $Camera2D
@onready var board = $Board

@onready var controls = $UI/Controls
@onready var turn_counter = $UI/TurnCounter
@onready var fight_splash = $UI/FightSplash

# Turn management
var turn = 0
var team_idx = 0

var cursor_pos : Vector2i

var selected_unit = null
var current_action = null
var is_busy = false

signal process_action

func _ready():
	controls.action_selected.connect(_action_selected)
	controls.mouse_entered.connect(cursor.hide)
	
	turn_counter.end_turn.connect(advance_turn)
	turn_counter.display_turn_info(turn, team_idx)
	
	deselect_unit()
	cursor.hide()
	
	# Assign bounding rect to the camera
	var rect = board.get_used_rect()
	camera.bounding_rect = Rect2(board.map_to_local(rect.position),Vector2.ZERO)
	camera.bounding_rect = camera.bounding_rect.expand(board.map_to_local(rect.position + rect.size))
	
	# Create units (TEMP CODE)
	var UnitGC = UnitRegistry.find_by_id("GC")
	var UnitArrowBox = UnitRegistry.find_by_id("ArrowBox")
	var UnitIekika = UnitRegistry.find_by_id("Iekika")
	board.add_unit(UnitIekika, Vector2i(3,1) , 0)
	board.add_unit(UnitIekika, Vector2i(3,4), 0)
	board.add_unit(UnitGC, Vector2i(3,7), 0)
	board.add_unit(UnitArrowBox, Vector2i(19,1), 1)
	board.add_unit(UnitGC, Vector2i(19,4), 1)
	board.add_unit(UnitArrowBox, Vector2i(19,7), 1)
	
	start_game()

func _unhandled_input(event):
	if is_busy: return
	
	if event is InputEventMouseMotion:
		# Move the cursor
		var mp = get_global_mouse_position()
		var prev_cursor_pos = cursor_pos
		cursor_pos = board.local_to_map(mp)
		if prev_cursor_pos != cursor_pos:
			cursor.show()
			cursor.position = board.map_to_local(cursor_pos)
			if current_action:
				process_action.emit({highlighted_cell=cursor_pos})
			if not selected_unit:
				var hovered_unit = board.get_unit(cursor_pos)
				controls.show_unit_info(hovered_unit, false, true)
	
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
				# Stop it
				process_action.emit({cancel=true}) # Send a signal to abort the current action
				current_action = null
				controls.show()
				board.highlight_clear()
				select_unit(selected_unit)

# Turn management
func start_game():
	team_idx = -1
	advance_turn()

func advance_turn():
	# Increment the current team
	team_idx += 1
	if team_idx >= NUM_TEAMS: # Teams are either 0 or 1
		team_idx = 0
		turn += 1
	turn_counter.display_turn_info(turn, team_idx)
	# Reset next team and move camera
	deselect_unit()
	var units = board.get_team_units(team_idx)
	if not units.is_empty():
		var camera_pos = Vector2.ZERO
		for unit in units:
			camera_pos += board.map_to_local(unit.board_position)
			unit.pulse_highlight()
			unit.replenish_ap()
		
		camera_pos /= units.size()
		camera.return_position = camera_pos
		camera.pan_to(camera_pos)

# Unit selection
func select_unit(unit):
	selected_unit = unit
	unit.select(team_idx)
	var can_control = unit.team == team_idx
	controls.show_unit_info(unit, can_control)

func deselect_unit():
	if selected_unit:
		selected_unit.deselect()
	selected_unit = null
	controls.show_unit_info(null)
	board.highlight_clear()

# Set whether the user is allowed to do inputs
func set_busy(busy : bool):
	is_busy = busy
	cursor.visible = not busy

func _action_selected(action : UnitAction):
	controls.hide()
	turn_counter.set_interaction_enabled(false)
	current_action = action
	# Begin action execution
	var unit = selected_unit
	var success = await action.execute(self, board, unit, process_action, set_busy)
	# Once the action is complete
	if success:
		unit.action_points -= action.ap_cost
	current_action = null
	turn_counter.set_interaction_enabled(true)
	controls.show()
	controls.show_unit_info(unit)
	# Check if action is available
	var should_end_turn = not board.does_team_have_actions(team_idx)
	turn_counter.set_out_of_actions(should_end_turn)
