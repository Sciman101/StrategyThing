extends Control

@onready var portrait_rect = $Background/Portrait
@onready var logo_rect = $Background/Logo

@onready var health_bar = $HealthBar
@onready var ap_bar = $ApBar

@onready var actioninfobox = $ActionInfo
@onready var actions = $Actions
@onready var action_buttons = actions.get_children()

signal action_selected(action : UnitAction)

var last_unit = null

func _ready():
	show_unit_info(null, true)
	for btn in action_buttons:
		btn.pressed.connect(_action_button_chosen.bind(btn.get_index()))
		btn.mouse_entered.connect(_action_button_hovered.bind(btn.get_index()))
		btn.mouse_exited.connect(_action_button_unhovered)
	actioninfobox.hide()

func show_unit_info(unit, enable_actions = true):
	if unit:
		show()
		portrait_rect.texture = unit.unit_data.portrait
		logo_rect.texture = unit.unit_data.logo
		health_bar.set_unit(unit)
		ap_bar.set_unit(unit)
		actions.show()
		var unit_actions = unit.unit_data.actions
		for i in range(action_buttons.size()):
			if i >= unit_actions.size():
				action_buttons[i].hide()
			else:
				action_buttons[i].show()
				action_buttons[i].text = unit_actions[i].name
				action_buttons[i].disabled = not enable_actions or unit.action_points < unit_actions[i].ap_cost
	else:
		ap_bar.drain_preview = 0
		hide()
		actions.hide()
		actioninfobox.hide()
	last_unit = unit

func _action_button_hovered(index : int):
	if last_unit:
		actioninfobox.show()
		var action = last_unit.unit_data.actions[index]
		actioninfobox.text = action.description + "\nAP Cost: " + str(action.ap_cost)
		ap_bar.drain_preview = action.ap_cost

func _action_button_unhovered():
	actioninfobox.hide()
	ap_bar.drain_preview = 0

func _action_button_chosen(index : int):
	var action = last_unit.unit_data.actions[index]
	action_selected.emit(action)
