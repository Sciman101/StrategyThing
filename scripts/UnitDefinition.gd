class_name UnitDefinition
extends Resource

@export var name : String

@export var board_sprite : Texture2D

@export_range(0,100) var max_health : int
@export_range(0,100) var base_power : int
@export_range(0,100) var base_speed : int

@export var actions : Array[UnitAction]
