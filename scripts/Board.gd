extends TileMap

const ASTAR_NEIGHBORS = [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]
const BASE_LAYER := 0
const OVERLAY_LAYER := 1
const OVERLAY_TILE_INDEX := 1

const UnitScene = preload("res://unit.tscn")

var units = {}
var astar : AStar2D

func _ready():	
	_build_pathfinding_graph()

#== Unit management ==#

func add_unit(data : UnitDefinition, pos : Vector2i, team : int = -1):
	if units.get(pos):
		print('Attempting to spawn unit in occupied space! ', pos)
		return null
	var unit = UnitScene.instantiate()
	add_child(unit)
	# Populate unit info
	unit.board = self
	unit.set_unit_data(data)
	unit.team = team
	move_unit(unit, pos)
	return unit

func get_unit(pos : Vector2i):
	return units.get(pos)

func get_team_units(team : int):
	return units.values().filter(func(unit): return unit.team == team)

func does_team_have_actions(team : int):
	for unit in get_team_units(team):
		var ap = unit.action_points
		for action in unit.unit_data.actions:
			if action.ap_cost <= ap:
				return true
	return false

func move_unit(unit, new_pos : Vector2i, move_visual : bool = true):
	
	# Does something already exist there?
	var old_unit = units.get(new_pos)
	
	# First remove the existing unit
	units.erase(unit.board_position)
	_astar_set_cell_enabled(unit.board_position, true)
	# Move to new position
	units[new_pos] = unit
	unit.board_position = new_pos
	if old_unit:
		old_unit.callbacks.on_overlap(self, old_unit, unit)
	# Should we label this space as unmovable?
	if not unit.can_be_moved_into():
		_astar_set_cell_enabled(unit.board_position, false)
	# If true, move the sprite to the correct location
	if move_visual:
		unit.position = map_to_local(new_pos)

func remove_unit(unit):
	units.erase(unit.board_position)

#== Space management ==#

func space_exists(pos : Vector2i):
	return get_cell_source_id(BASE_LAYER, pos) != -1

func space_traversable(pos : Vector2i):
	return space_exists(pos)

func find_path(start : Vector2i, end : Vector2i, crunch:bool=false):
	var rect = get_used_rect()
	var a = _astar_from_pos(start - rect.position)
	var b = _astar_from_pos(end - rect.position)
	# Abort if cells don't exist
	if not astar.has_point(a) or not astar.has_point(b):
		return []
	var path = Array(astar.get_id_path(a, b)).map(func(id): return _pos_from_astar(id) + rect.position)
	if crunch: path = crunch_path(path)
	return path

# Strictly unecessary, but it makes the tweened movement look smoother
func crunch_path(board_path : Array):
	if board_path.size() < 2: return board_path
	var curr = board_path[0]
	var next = board_path[1]
	var dir = next - curr
	
	var new_path = [curr]
	
	var idx = 1
	while idx < board_path.size() - 1:
		curr = next
		next = board_path[idx + 1]
		var prev_dir = dir
		dir = next - curr
		
		if dir != prev_dir:
			new_path.append(curr)
		idx += 1
	if new_path[-1] != board_path[-1]:
		new_path.append(board_path[-1])
	return new_path

# Moves a fake object from 'from' by 'dir', 'dist' times, returning anything we hit or the final position
func test_linear_move(from : Vector2i, dir : Vector2i, dist : int):
	var pos = from
	var target = from + dir * dist
	while pos != target:
		pos += dir
		if not space_traversable(pos) or get_unit(pos):
			return pos - dir
	return pos

#== Overlay Layer ==#
func create_selection():
	return Selection.new(self)

func highlight_clear():
	clear_layer(OVERLAY_LAYER)

func highlight_selection(selection):
	for cell in selection.cells.keys():
		if selection.cells[cell]:
			set_cell(OVERLAY_LAYER, cell, OVERLAY_TILE_INDEX, Vector2.ZERO)

#== ASTAR SETUP & UTILITIES ==#

func _astar_set_cell_enabled(cell : Vector2i, enabled : bool):
	var index = _astar_from_board(cell)
	if astar.has_point(index):
		astar.set_point_disabled(index, not enabled)

func _astar_from_board(pos : Vector2i):
	var rect = get_used_rect()
	pos -= rect.position
	return pos.x + pos.y * rect.size.x

func _astar_from_pos(pos : Vector2i):
	var rect = get_used_rect()
	return pos.x + pos.y * rect.size.x

func _pos_from_astar(idx : int):
	var width = get_used_rect().size.x
	return Vector2i(idx % width, floor(idx / width))

func _build_pathfinding_graph():
	# https://escada-games.itch.io/randungeon/devlog/261991/how-to-use-godots-astar2d-for-path-finding
	astar = AStar2D.new()
	var rect = get_used_rect()
	var size = rect.size
	astar.reserve_space(size.x * size.y)
	for x in size.x:
		for y in size.y:
			var pos = Vector2i(x,y)
			var idx = _astar_from_pos(pos)
			var tilemap_pos = pos + rect.position
			if space_exists(tilemap_pos):
				astar.add_point(idx, pos)
	for x in size.x:
		for y in size.y:
			var pos = Vector2i(x,y)
			# Connect to right and down
			var idx = _astar_from_pos(pos)
			if not astar.has_point(idx): continue
			var idx_right = _astar_from_pos(pos + Vector2i.RIGHT)
			var idx_down = _astar_from_pos(pos + Vector2i.DOWN)
			
			if idx == 36:
				pass
			
			if astar.has_point(idx_right) and x != rect.size.x - 1:
				astar.connect_points(idx, idx_right)
			if astar.has_point(idx_down):
				astar.connect_points(idx, idx_down)
	queue_redraw()

#== Helpers ==#
func manhatten_dist(a:Vector2i, b:Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

class Selection:
	var cells = {}
	var board
	
	func _init(board):
		self.board = board
	
	func has(position : Vector2i):
		return cells.get(position, false)
	
	func list_cells():
		return cells.keys().filter(func(cell): cells[cell])
	
	func clone():
		var new = Selection.new(self.board)
		new.cells = cells.duplicate()
		return new
	
	func cleanup():
		var list = cells.keys()
		for pos in list:
			if not list[pos]:
				cells.erase(pos)
	
	## Boolean operators ##
	func union(selection):
		for cell in selection.list_cells():
			select_cell(cell)
		return self
	
	func intersection(selection):
		for cell in cells.keys():
			if not selection.has(cell):
				select_cell(cell, false)
		for cell in selection.list_cells():
			if not cells[cell]:
				select_cell(cell, false)
		return self
	
	func difference(selection):
		for cell in selection.list_cells():
			if cells[cell]:
				select_cell(cell, false)
		return self
	
	## Basic selectors ##
	func select_cell(pos : Vector2i, selected : bool = true):
		cells[pos] = selected
		return self
	
	func clear():
		cells = {}
		return self
	
	func invert():
		for cell in cells:
			cells[cell] = not cells[cell]
		return self
	
	func select_all(include_empty : bool = false):
		var rect = board.get_used_rect()
		var size = rect.size
		for x in size.x:
			for y in size.y:
				var pos = rect.position + Vector2i(x,y)
				if board.space_exists(pos) or include_empty:
					cells[pos] = true
		return self
	
	func select_within_range(center : Vector2i, distance : int, selected : bool = true):
		for x in range(-distance, distance + 1):
			for y in range(-distance, distance + 1):
				var pos = center + Vector2i(x,y)
				if board.space_exists(pos):
					if board.manhatten_dist(pos, center) <= distance:
						select_cell(pos, selected)
		return self
	
	func select_units(team : int = -1, selected : bool = true):
		for cell in board.units.keys():
			if team == -1 or board.units[cell].team == team:
				select_cell(cell, selected)
		return self
	
	## Select multiple
	func select_array(cells_list : Array, selected : bool = true):
		for cell in cells_list:
			cells[cell] = selected
		return self
	
	## Select multiple relative to an origin
	func select_array_relative(center : Vector2i, cells_list : Array, selected : bool = true):
		for cell in cells_list:
			cells[cell + center] = selected
		return self
	
	## Given a path, select each cell and the space between them
	func select_path(path : Array, selected : bool = true):
		if path.size() == 0: return
		if path.size() == 1:
			select_cell(path[0], selected)
			return self
		var curr = path[0]
		var next = path[1]
		var end = path[-1]
		var dir = (next - curr).clamp(-Vector2i.ONE, Vector2i.ONE)
		var idx = 0
		while curr != end:
			select_cell(curr, selected)
			curr += dir
			if curr == next:
				idx += 1
				curr = next
				if idx < path.size() - 1:
					next = path[idx + 1]
				dir = (next - curr).clamp(-Vector2i.ONE, Vector2i.ONE)
		select_cell(path[-1], selected)
		return self
	
	func highlight_board():
		board.highlight_selection(self)
		return self
