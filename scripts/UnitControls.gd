extends Control

@onready var infobox = $HBoxContainer/UnitInfo
@onready var actions = $HBoxContainer/Actions
@onready var action_buttons = actions.get_children()

func _ready():
	show_unit_info(null)

func show_unit_info(unit):
	if unit:
		infobox.text = unit.get_info_string()
		actions.show()
		var unit_actions = unit.unit_data.actions
		for i in range(action_buttons.size()):
			if i >= unit_actions.size():
				action_buttons[i].hide()
			else:
				action_buttons[i].show()
				action_buttons[i].text = unit_actions[i]
	else:
		infobox.text = "No unit selected"
		actions.hide()
