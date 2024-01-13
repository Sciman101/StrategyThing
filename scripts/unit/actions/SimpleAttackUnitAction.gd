extends UnitAction

@export var damage : int = 1
@export var pushback_amt : int = 0

func execute(game, board, unit, control_signal, set_busy):
	# Highlight all enemy units
	board.highlight_units(1 - unit.team)
	var target_valid = false
	var target_pos
	while not target_valid:
		var result = await control_signal
		if result.get('cancel'):
			return
		
		target_pos = result.get('selected_cell')
		if target_pos:
			if board.space_is_highlighted(target_pos):
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
