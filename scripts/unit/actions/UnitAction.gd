class_name UnitAction
extends Resource

@export var name : String
@export_multiline var description : String
@export_range(0,4) var ap_cost : int

# game is the current game manager
# board is the current gameboard
# unit is the unit this is targeting
# control_signal is passed by the game to allow messages to pass through
# set_busy can be called by the action to tell the game "don't let the user interrupt this!"
func execute(game, board, unit, control_signal, set_busy): # This method is awaited
	pass
