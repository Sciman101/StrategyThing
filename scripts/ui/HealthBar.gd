extends TextureProgressBar

@onready var label = $Label

func set_unit(unit):
	value = unit.health
	max_value = unit.unit_data.max_health
	label.text = "%s/%s" % [value, max_value]
