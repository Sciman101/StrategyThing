extends Node2D

@onready var attacker_sprite := $Attacker
@onready var defender_sprite := $Defender

@onready var animation := $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()

func show_fight(attacker : UnitDefinition, defender : UnitDefinition):
	attacker_sprite.texture = attacker.attack_sprite
	defender_sprite.texture = defender.defend_sprite
	show()
	animation.play("splash")
	await animation.animation_finished
	hide()
