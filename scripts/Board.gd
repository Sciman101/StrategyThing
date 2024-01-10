extends TileMap

const ASTAR_NEIGHBORS = [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]

const UnitData = [preload("res://UnitArrowBox.tres"), preload("res://UnitGC.tres")]

const UnitScene = preload("res://unit.tscn")

var units = {}
var astar : AStar2D

# List of selected cells
var selection = []

func _ready():
	_build_pathfinding_graph()
	
	var x = 0
	for unit in UnitData:
		add_unit(Vector2i(5 + x,5), unit)
		x += 1

func _draw():
	var rect = get_used_rect()
#	for i in range(rect.size.x * rect.size.y):
#		if astar.has_point(i):
#			var pos = (astar.get_point_position(i) + Vector2(rect.position)) * 32 + Vector2(16,16)
#			draw_circle(pos, 2, Color.RED)
#			for conn in astar.get_point_connections(i):
#				var pos2 = (astar.get_point_position(conn) + Vector2(rect.position)) * 32 + Vector2(16,16)
#				draw_line(pos, pos2, Color.RED)
	for cell in selection:
		draw_circle(map_to_local(cell), 14, Color.AQUA)

func add_unit(pos : Vector2i, data : UnitDefinition):
	if units.get(pos):
		print('Attempting to spawn unit in occupied space! ', pos)
		return null
	var unit = UnitScene.instantiate()
	unit.unit_data = data
	add_child(unit)
	unit.board = self
	unit.position = map_to_local(pos)
	unit.board_position = pos
	units[pos] = unit
	return unit

func get_unit(pos : Vector2i):
	return units.get(pos)

func move_unit(unit, new_pos : Vector2i):
	units.erase(unit.board_position)
	units[new_pos] = unit
	unit.board_position = new_pos

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
		var prev = curr
		curr = next
		next = board_path[idx + 1]
		var prev_dir = dir
		dir = next - curr
		
		if dir != prev_dir:
			new_path.append(curr)
			print(new_path)
		idx += 1
	if new_path[-1] != board_path[-1]:
		new_path.append(board_path[-1])
	return new_path

#== Selection manipulation ==#
func select_clear():
	selection.clear()
	queue_redraw()

func select_all():
	select_clear()
	var rect = get_used_rect()
	for x in rect.size.x:
		for y in rect.size.y:
			var pos = Vector2i(x,y) + rect.position
			if get_cell_source_id(0, pos) != -1:
				selection.append(pos)
	queue_redraw()

func select_within_distance(center: Vector2i, distance: int):
	select_clear()
	var rect = get_used_rect()
	for x in rect.size.x:
		for y in rect.size.y:
			var pos = Vector2i(x,y) + rect.position
			if get_cell_source_id(0, pos) != -1 and manhatten_dist(center, pos) <= distance:
				selection.append(pos)
	queue_redraw()

func select_remove_occupied_cells():
	for pos in units.keys():
		select_remove_cell(pos)

func select_remove_cell(pos:Vector2i):
	selection.erase(pos)
	queue_redraw()

func pos_in_selection(pos:Vector2i):
	return selection.has(pos)

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
			if get_cell_source_id(0, tilemap_pos) != -1:
				astar.add_point(idx, pos)
				var label = Label.new()
				label.text = str(idx)
				add_child(label)
				label.position = tilemap_pos * 32
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
