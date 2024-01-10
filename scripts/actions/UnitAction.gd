class_name UnitAction
extends Resource

@export var name : String
@export_multiline var description : String
@export_range(0,4) var ap_cost : int

func execute(game, board, unit, control_signal): # This method is awaited
	pass
