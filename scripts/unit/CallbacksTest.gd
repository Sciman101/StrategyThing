extends Node

func on_overlap(board, unit, other_unit):
	# Called when one unit tries to occupy the same space as this one
	# MUST result in this unit moving, being destroyed, etc
	pass
 
func on_space_passed(board, unit, other_unit):
	# Called when one unit moves through this units space,
	# but does not stop.
	pass

func on_hurt(board, unit, damage, pushback, source):
	# Called when hurt
	pass

func on_defeat(board, unit, source):
	pass
