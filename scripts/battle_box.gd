class_name BattleBox
extends Node2D
## The white-bordered box the SOUL has to stay inside during battles.

## Where the middle of the box is on the screen (the screen is 640 x 480).
@export var center: Vector2 = Vector2(320, 320)
## How big the black area inside the border is, in pixels.
@export var size: Vector2 = Vector2(160, 140)
## How thick the white border is, in pixels.
@export var border: float = 5.0


## Returns the black area inside the border, in screen coordinates.
## The SOUL uses this to know where it's allowed to go.
func get_inner_rect() -> Rect2:
	return Rect2(global_position + center - size / 2, size)


func _draw() -> void:
	var inner := Rect2(center - size / 2, size)
	# Draw a white rectangle, then a slightly smaller black one on top.
	# The bit of white still showing around the edge is the border.
	draw_rect(inner.grow(border), Color.WHITE)
	draw_rect(inner, Color.BLACK)
