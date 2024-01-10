extends Control

@onready var infobox = $HBoxContainer/UnitInfo
@onready var actioninfobox = $HBoxContainer/ActionInfo
@onready var actions = $HBoxContainer/Actions
@onready var action_buttons = actions.get_children()

signal action_selected(action : UnitAction)

var last_unit = null

func _ready():
	show_unit_info(null)
	for btn in action_buttons:
		btn.pressed.connect(_action_button_chosen.bind(btn.get_index()))
		btn.mouse_entered.connect(_action_button_hovered.bind(btn.get_index()))
		btn.mouse_exited.connect(_action_button_unhovered)
	actioninfobox.hide()

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
				action_buttons[i].text = unit_actions[i].name
	else:
		infobox.text = "No unit selected"
		actions.hide()
		actioninfobox.hide()
	last_unit = unit

func _action_button_hovered(index : int):
	if last_unit:
		actioninfobox.show()
		actioninfobox.text = last_unit.unit_data.actions[index].description

func _action_button_unhovered():
	actioninfobox.hide()

func _action_button_chosen(index : int):
	var action = last_unit.unit_data.actions[index]
	action_selected.emit(action)
