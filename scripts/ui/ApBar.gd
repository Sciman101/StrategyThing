@tool
extends Control

@export var filled : Texture2D
@export var empty : Texture2D

@export var value : int = 0 : set = set_value
@export var max_value : int = 3
@export var gap : int = 2
var drain_preview : int = 0 : set = set_drain_preview

var pulse = 0.0

func _process(delta):
	pulse += delta * 3
	if pulse >= PI:
		pulse = 0
	if drain_preview != 0:
		queue_redraw()

func _draw():
	var pos = Vector2.ZERO
	for i in max_value:
		var tex = empty
		var draw_drain := false
		if i < value:
			tex = filled
			if i >= value - drain_preview:
				draw_drain = true
		draw_texture(tex, pos)
		if draw_drain:
			draw_texture(empty, pos, Color(1,1,1,sin(pulse)))
		pos += Vector2.RIGHT * (tex.get_size().x + gap)

func set_unit(unit):
	value = unit.action_points
	queue_redraw()

func set_value(x : int):
	value = clamp(x, 0, max_value)
	queue_redraw()

func set_max_value(x : int):
	max_value = max(0, x)
	queue_redraw()

func set_drain_preview(x : int):
	drain_preview = min(x, max_value)
	queue_redraw()
