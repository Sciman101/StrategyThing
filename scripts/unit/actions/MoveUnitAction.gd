extends UnitAction

func execute(game, board, unit, control_signal, set_busy):
	# Start by highlighting the available spaces
	board.highlight_movement_range(unit)
	board.unhighlight_occupied_cells()
	var move_valid = false
	var target_pos
	while not move_valid:
		var result = await control_signal
		if result.get('cancel'):
			return
		
		if result.has('highlighted_cell'):
			board.highlight_clear()
			board.highlight_movement_range(unit)
			board.unhighlight_occupied_cells()
			var pos = result.highlighted_cell
			if board.manhatten_dist(pos, unit.board_position) <= unit.speed:
				var path = board.find_path(unit.board_position, pos, true)
				board.highlight_path(path)
		
		target_pos = result.get('selected_cell')
		if target_pos and board.manhatten_dist(target_pos, unit.board_position) <= unit.speed:
			if board.space_is_highlighted(target_pos):
				var path = board.find_path(unit.board_position, target_pos, true)
				if path.size() > 0:
					# Ok! We can move now
					game.deselect_unit()
					board.highlight_path(path)
					move_valid = true
					board.move_unit(unit, target_pos)
					unit.play(&'move')
					set_busy.call(true)
					await unit.follow_path(path)
					set_busy.call(false)
					unit.play(&'default')
