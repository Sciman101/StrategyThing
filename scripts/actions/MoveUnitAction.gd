extends UnitAction

func execute(game, board, unit, control_signal):
	# Start by highlighting the available spaces
	board.highlight_movement_range(unit)
	board.unhighlight_occupied_cells()
	var move_valid = false
	var target_pos
	while not move_valid:
		var result = await control_signal
		if result.get('cancel'):
			return
		
		target_pos = result.selected_cell
		if target_pos != unit.board_position and not board.get_unit(target_pos):
			# Determine if cell is valid
			if board.manhatten_dist(target_pos, unit.board_position) <= unit.speed:
				var path = board.find_path(unit.board_position, target_pos, true)
				if path.size() > 0:
					# Ok! We can move now
					game.deselect_unit()
					move_valid = true
					board.move_unit(unit, target_pos)
					unit.play(&'move')
					await unit.follow_path(path)
					unit.play(&'default')
