class_name UnitDefinition
extends Resource

@export_category("Unit Info")
@export var identifier : String
@export var name : String

@export var portrait : Texture
@export var logo : Texture

@export var board_animations : SpriteFrames
@export var attack_sprite : Texture
@export var defend_sprite : Texture

@export_category("Stats")
@export_range(0,100) var max_health : int
@export_range(0,100) var base_speed : int

@export var actions : Array[UnitAction]

@export var callbacks : Script
