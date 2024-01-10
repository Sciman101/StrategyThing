extends UnitAction

func execute(game, board, unit, control_signal):
	# Start by highlighting the available spaces
	board.select_within_distance(unit.board_position, unit.speed)
	board.select_remove_occupied_cells()
	var move_valid = false
	var target_pos
	while not move_valid:
		var result = await control_signal
		if result.get('cancel'): return
		
		target_pos = result.selected_cell
		# Determine if cell is valid
		if board.manhatten_dist(target_pos, unit.board_position) <= unit.speed:
			# Ok! We can move now
			game.deselect_unit()
			var path = board.find_path(unit.board_position, target_pos, true)
			if path.size() > 0:
				# Valid path
				move_valid = true
				board.move_unit(unit, target_pos)
				unit.play(&'move')
				await unit.follow_path(path)
				unit.play(&'default')
