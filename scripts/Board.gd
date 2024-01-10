extends TileMap

const ASTAR_NEIGHBORS = [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]
const BASE_LAYER := 0
const OVERLAY_LAYER := 1
const OVERLAY_TILE_INDEX := 1

const UnitData = [preload("res://UnitArrowBox.tres"), preload("res://UnitGC.tres")]

const UnitScene = preload("res://unit.tscn")

var units = {}
var astar : AStar2D

func _ready():	
	_build_pathfinding_graph()
	
	var x = 0
	for unit in UnitData:
		add_unit(Vector2i(5 + x,5), unit)
		x += 1

func add_unit(pos : Vector2i, data : UnitDefinition, team : int = -1):
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

func move_unit(unit, new_pos : Vector2i):
	units.erase(unit.board_position)
	units[new_pos] = unit
	unit.board_position = new_pos
	unit.position = map_to_local(new_pos)

func find_path(start : Vector2i, end : Vector2i, crunch:bool=false):
	var rect = get_used_rect()
	var a = _astar_from_pos(start - rect.position)
	var b = _astar_from_pos(end - rect.position)
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

#== Overlay Layer ==#
func highlight_clear():
	clear_layer(OVERLAY_LAYER)

func highlight_movement_range(unit):
	for x in range(-unit.speed, unit.speed+1):
		for y in range(-unit.speed, unit.speed+1):
			var pos = unit.board_position + Vector2i(x,y)
			if get_cell_source_id(BASE_LAYER, pos) != -1:
				if manhatten_dist(pos, unit.board_position) <= unit.speed:
					set_cell(OVERLAY_LAYER, pos, OVERLAY_TILE_INDEX, Vector2.ZERO)

func highlight_all_spaces():
	var rect = get_used_rect()
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			var pos = Vector2i(x,y)
			if get_cell_source_id(BASE_LAYER, pos) != -1:
				set_cell(OVERLAY_LAYER, pos, OVERLAY_TILE_INDEX, Vector2.ZERO)

func unhighlight_occupied_cells():
	for cell in units.keys():
		set_cell(OVERLAY_LAYER, cell)

#== ASTAR SETUP & UTILITIES ==#

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
			if get_cell_source_id(BASE_LAYER, tilemap_pos) != -1:
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
