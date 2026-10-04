class_name Bullet
extends Node2D
## Anything in an enemy's attack that hurts the SOUL on touch.
## Most bullets fly in a straight line, but they can also fall (gravity),
## bounce off the bottom of the box, or crack into smaller pieces.

## Which way and how fast the bullet moves, in pixels per second.
@export var velocity: Vector2 = Vector2.ZERO
## Added to the velocity every second (e.g. gravity pulling things down).
@export var acceleration: Vector2 = Vector2.ZERO
## How big the bullet is, in pixels.
@export var size: float = 6.0
## How much HP the SOUL loses when this bullet hits it.
@export var damage: int = 3
@export var color: Color = Color.WHITE
## How it's drawn: "square", "egg", "bunny", "star", "pencil", "bubble", "card",
## "finger" or "ball".
@export var shape: String = "square"

## Bounces up when it reaches the bottom of the box (for hopping things).
var bounce_speed: float = 0.0
## Cracks into this many small pieces when it reaches the bottom of the box.
var splits_into: int = 0
## Seconds it waits as a faint, harmless warning before it starts moving.
var delay: float = 0.0
## How far it drifts side to side while moving (for falling paper and confetti).
var sway: float = 0.0

## The area the bullet lives in. Once it flies out, it disappears.
var bounds: Rect2

var _time: float = 0.0


func _ready() -> void:
	# Draw on top of the battle box, like the SOUL.
	z_index = 1


func _process(delta: float) -> void:
	_time += delta
	if not is_armed():
		# Still a warning: see-through and not moving yet.
		modulate.a = 0.35
		queue_redraw()
		return
	modulate.a = 1.0
	velocity += acceleration * delta
	position += velocity * delta
	if sway != 0.0:
		position.x += cos(_time * 6.0) * sway * delta

	if bounds.has_area():
		var floor_y := bounds.end.y - size / 2
		if global_position.y >= floor_y and velocity.y > 0:
			if splits_into > 0:
				_split()
				return
			if bounce_speed > 0:
				global_position.y = floor_y
				velocity.y = -bounce_speed
		# Remove the bullet once it has left the box, so they don't pile up forever.
		if not bounds.grow(size).has_point(global_position):
			queue_free()

	queue_redraw()


## Cracks into small pieces that scatter up and sideways.
func _split() -> void:
	for i in splits_into:
		var piece := Bullet.new()
		piece.bounds = bounds
		piece.damage = maxi(1, damage - 1)
		piece.size = 4.0
		piece.color = Color(1.0, 0.85, 0.2)
		var angle := lerpf(-PI + 0.4, -0.4, float(i) / maxi(1, splits_into - 1))
		piece.velocity = Vector2(cos(angle), sin(angle)) * 110.0
		piece.acceleration = Vector2(0, 220)
		piece.position = position + Vector2(0, -4)
		get_parent().add_child(piece)
	queue_free()


## Returns the square the SOUL has to touch to get hit, in screen coordinates.
func get_hitbox() -> Rect2:
	if not is_armed():
		return Rect2()
	return Rect2(global_position - Vector2(size, size) / 2, Vector2(size, size))


func _draw() -> void:
	var half := size / 2
	match shape:
		"egg":
			draw_circle(Vector2(0, 1), half, color)
			draw_circle(Vector2(0, -1), half * 0.8, color)
		"bunny":
			# A tiny white bunny: body, head and two ears.
			draw_rect(Rect2(-half, -half * 0.4, size, size * 0.7), color)
			draw_rect(Rect2(half * 0.2, -half, half * 0.8, half * 0.8), color)
			draw_rect(Rect2(half * 0.3, -half * 2.0, 1.5, half), color)
			draw_rect(Rect2(half * 0.8, -half * 2.0, 1.5, half), color)
		"star":
			var spin := _time * 8.0
			for i in 4:
				var dir := Vector2.from_angle(spin + i * PI / 2) * half
				draw_line(-dir, dir, color, 2.0)
		"pencil":
			# A yellow pencil pointing the way it flies, pink eraser at the back.
			var dir := velocity.normalized() if velocity.length() > 0.1 else Vector2.DOWN
			draw_line(-dir * size, dir * size * 0.6, Color(0.95, 0.8, 0.2), 3.0)
			draw_line(dir * size * 0.6, dir * size, Color(0.3, 0.25, 0.2), 2.0)
			draw_line(-dir * size, -dir * size * 0.7, Color(1.0, 0.6, 0.7), 3.0)
		"bubble":
			# An answer bubble from a test sheet.
			draw_arc(Vector2.ZERO, half, 0, TAU, 16, color, 2.0)
			draw_circle(Vector2.ZERO, half * 0.45, color)
		"card":
			# A small wooden hall pass.
			draw_rect(Rect2(-half, -half * 0.6, size, size * 0.6), color)
			draw_rect(Rect2(-half * 0.5, -half * 0.3, size * 0.5, 2), Color(0.2, 0.15, 0.1))
		"finger":
			# A big foam finger.
			var point := 1.0 if velocity.x >= 0 else -1.0
			draw_rect(Rect2(-half, -half * 0.5, size * 0.7, size * 0.6), color)
			draw_rect(Rect2(Vector2(half * 0.2 if point > 0 else -half * 0.9, -half), Vector2(half * 0.7, half * 0.6)), color)
		"ball":
			draw_circle(Vector2.ZERO, half, color)
			draw_arc(Vector2.ZERO, half * 0.6, _time * 6.0, _time * 6.0 + PI, 8, Color(1, 1, 1, 0.6), 2.0)
		_:
			draw_rect(Rect2(-half, -half, size, size), color)


## False while the bullet is still just a warning.
func is_armed() -> bool:
	return _time >= delay
