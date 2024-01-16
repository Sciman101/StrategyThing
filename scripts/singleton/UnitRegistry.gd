extends Node

const UNIT_PATH := "res://units"

var units = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	_load_units()

## Find a unit by its name
func find_by_name(unit_name : String):
	for unit in units.values():
		if unit.name == unit_name:
			return unit
	return null

## Find a unit by its string id
func find_by_id(id : String):
	return units.get(id)

## ALL units
func all_units():
	return units.values()

func _load_units():
	print("Loading units from %s" % UNIT_PATH)
	
	#Load all character info
	var unit_dir = DirAccess.open(UNIT_PATH)
	if unit_dir:
		#Load each character info file
		unit_dir.list_dir_begin()
		
		var path = unit_dir.get_next()
		while path != "":
			#Cycle over the units directory
			if not unit_dir.current_is_dir():
				var unit = load(UNIT_PATH + "/" + path)
				if units.has(unit.identifier):
					print("Warning! Attempting to override unit %s! If this is intentional, consider changing the id" % unit.identifier)
				else:
					units[unit.identifier] = unit
					print("Loaded %s (id %s)" % [unit.name, unit.identifier])
			path = unit_dir.get_next()
			
	else:
		print("Error loading unit directory! Something is very wrong D:")
	print("Loaded %s units(s) successfully" % units.size())
