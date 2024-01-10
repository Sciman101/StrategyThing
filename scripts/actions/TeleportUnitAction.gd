extends UnitAction

func execute(game, board, unit, control_signal):
	# Start by highlighting the available spaces
	board.highlight_all_spaces()
	board.unhighlight_occupied_cells()
	var move_valid = false
	var target_pos
	while not move_valid:
		var result = await control_signal
		if result.get('cancel'):
			return
		
		target_pos = result.selected_cell
		if target_pos != unit.board_position and not board.get_unit(target_pos):
			# Ok! We can move now
			game.deselect_unit()
			move_valid = true
			await game.get_tree().create_tween().tween_property(unit, 'scale', Vector2(0, 5), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).finished
			board.move_unit(unit, target_pos)
			await game.get_tree().create_tween().tween_property(unit, 'scale', Vector2.ONE, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC).finished
