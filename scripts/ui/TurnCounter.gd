extends VBoxContainer

@onready var label = $Label
@onready var button = $AdvanceTurnBtn

signal end_turn

func _ready():
	$AdvanceTurnBtn.pressed.connect(func(): end_turn.emit())
	display_turn_info(0, 0)

func display_turn_info(turn : int, team_idx : int):
	label.text = "Turn: " + str(turn) + "\nTeam " + str(team_idx + 1)

func set_interaction_enabled(enabled : bool):
	button.disabled = not enabled
