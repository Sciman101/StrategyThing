extends UnitAction

@export var damage : int = 1
@export var pushback_amt : int = 0
@export var max_distance : int = 1

func execute(game, board, unit, control_signal, set_busy):
	# Highlight all enemy units
	var range_selection = board.create_selection().select_within_range(unit.board_position, max_distance).highlight_board(true)
	var selection = board.create_selection() \
		.select_units(1 - unit.team) \
		.intersection(range_selection) \
		.highlight_board()
	var target_valid = false
	var target_pos
	while not target_valid:
		var result = await control_signal
		if result.get('cancel'):
			return false
		
		target_pos = result.get('selected_cell')
		if target_pos:
			if selection.has(target_pos):
				var enemy_unit = board.get_unit(target_pos)
				if enemy_unit.team != unit.team:
					# Kill them!!!!!!!!!
					target_valid = true
					game.deselect_unit()
					set_busy.call(true)
					
					game.camera.screenshake()
					await game.fight_splash.show_fight(unit.unit_data, enemy_unit.unit_data)
					
					var dir = (enemy_unit.board_position - unit.board_position).clamp(-Vector2i.ONE, Vector2i.ONE)
					await enemy_unit.hurt(damage, dir * pushback_amt, self)
					set_busy.call(false)
					return true
