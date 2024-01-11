extends VBoxContainer

@onready var label = $Label

signal end_turn

func _ready():
	$AdvanceTurnBtn.pressed.connect(func(): end_turn.emit())
	display_turn_info(0, 0)

func display_turn_info(turn : int, team_idx : int):
	label.text = "Turn: " + str(turn) + "\nTeam " + str(team_idx + 1)
