extends UnitAction

func execute(game, board, unit, control_signal, set_busy):
	# Start by highlighting the available spaces
	var selection = board.create_selection() \
		.select_within_range(unit.board_position, 1) \
		.select_units(-1, false) \
		.highlight_board()
	var move_valid = false
	var target_pos
	while not move_valid:
		var result = await control_signal
		if result.get('cancel'):
			return false
		
		target_pos = result.get('selected_cell')
		if target_pos:
			if selection.has(target_pos):
				# Ok! We can move now
				game.deselect_unit()
				move_valid = true
				
				var new_unit = board.add_unit(unit.unit_data, target_pos, unit.team)
				var o = new_unit.offset
				new_unit.offset = Vector2.UP * 200
				set_busy.call(true)
				await game.get_tree().create_tween().tween_property(new_unit, 'offset', o, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE).finished
				set_busy.call(false)
				return true
