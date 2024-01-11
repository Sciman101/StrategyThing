extends UnitAction

func execute(game, board, unit, control_signal, set_busy):
	# Start by highlighting the available spaces
	board.highlight_cell(unit.board_position + Vector2i.LEFT)
	board.highlight_cell(unit.board_position + Vector2i.RIGHT)
	board.highlight_cell(unit.board_position + Vector2i.UP)
	board.highlight_cell(unit.board_position + Vector2i.DOWN)
	board.highlight_cell(unit.board_position + Vector2i(1,1))
	board.highlight_cell(unit.board_position + Vector2i(-1,1))
	board.highlight_cell(unit.board_position + Vector2i(1,-1))
	board.highlight_cell(unit.board_position + Vector2i(-1,-1))
	board.unhighlight_occupied_cells()
	var move_valid = false
	var target_pos
	while not move_valid:
		var result = await control_signal
		if result.get('cancel'):
			return
		
		target_pos = result.get('selected_cell')
		if target_pos:
			if board.space_is_highlighted(target_pos):
				# Ok! We can move now
				game.deselect_unit()
				move_valid = true
				
				var new_unit = board.add_unit(target_pos, unit.unit_data, unit.team)
				var o = new_unit.offset
				new_unit.offset = Vector2.UP * 200
				set_busy.call(true)
				await game.get_tree().create_tween().tween_property(new_unit, 'offset', o, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE).finished
				set_busy.call(false)
