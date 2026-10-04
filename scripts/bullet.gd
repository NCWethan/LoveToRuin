class_name Bullet
extends Node2D
## Anything in an enemy's attack that hurts the SOUL on touch.
## Most bullets fly in a straight line, but they can also fall (gravity),
## bounce off the bottom of the box, crack into smaller pieces, chase the SOUL,
## leave glowing trails, or be a whole slash ("beam") across the box.

## Which way and how fast the bullet moves, in pixels per second.
@export var velocity: Vector2 = Vector2.ZERO
## Added to the velocity every second (e.g. gravity pulling things down).
@export var acceleration: Vector2 = Vector2.ZERO
## How big the bullet is, in pixels. For beams, how thick the slash is.
@export var size: float = 6.0
## How much HP the SOUL loses when this bullet hits it.
@export var damage: int = 3
@export var color: Color = Color.WHITE
## How it's drawn: "square", "egg", "bunny", "star", "pencil", "bubble", "card",
## "finger", "ball", "claw", "arrow" or "beam".
@export var shape: String = "square"

## Bounces up when it reaches the bottom of the box (for hopping things).
var bounce_speed: float = 0.0
## Cracks into this many small pieces when it reaches the bottom of the box.
var splits_into: int = 0
## The color of those pieces.
var split_color: Color = Color(1.0, 0.85, 0.2)
## Seconds it waits as a faint, harmless warning before it starts moving.
var delay: float = 0.0
## How far it drifts side to side while moving (for falling paper and confetti).
var sway: float = 0.0
## If above 0: how many seconds it stays dangerous once armed, then it vanishes
## (for quick slashes that flash and disappear).
var lifetime: float = 0.0
## Each bounce is randomly this much higher or lower (0.15 = up to 15%).
var bounce_variance: float = 0.0

## Beams only: the slash runs from (position - beam_vector) to (position + beam_vector).
var beam_vector: Vector2 = Vector2.ZERO
## If set, the bullet steers toward this (the SOUL) for `homing_time` seconds after it starts moving.
var homing: Node2D
var homing_time: float = 0.0
## How fast it can turn while homing, in radians per second.
var turn_rate: float = 3.0
## How many past positions to draw as a glowing trail (0 = no trail).
var trail_length: int = 0
## Draws a soft glow around the bullet.
var glow: bool = false

## The area the bullet lives in. Once it flies out, it disappears.
var bounds: Rect2

var _time: float = 0.0
var _trail: PackedVector2Array = PackedVector2Array()
var _armed_before: bool = false


func _ready() -> void:
	# Draw on top of the battle box, like the SOUL.
	z_index = 1


func _process(delta: float) -> void:
	_time += delta
	if not is_armed():
		# Still a warning: see-through and not moving yet. Beams flicker.
		modulate.a = 0.35 + (0.35 * absf(sin(_time * 22.0)) if shape == "beam" else 0.0)
		queue_redraw()
		return
	if not _armed_before:
		_armed_before = true
		if shape == "beam":
			Game.play_sfx("slash")
	modulate.a = 1.0
	if lifetime > 0.0:
		var left := delay + lifetime - _time
		if left <= 0.0:
			queue_free()
			return
		# Slashes fade out as they finish.
		if shape == "beam":
			modulate.a = clampf(left / (lifetime * 0.5), 0.0, 1.0)

	# Chasing the SOUL: turn a little toward it each frame.
	if homing and is_instance_valid(homing) and _time - delay < homing_time and velocity.length() > 0.1:
		var wanted := (homing.global_position - global_position).angle()
		var turn := clampf(angle_difference(velocity.angle(), wanted), -turn_rate * delta, turn_rate * delta)
		velocity = velocity.rotated(turn)

	velocity += acceleration * delta
	position += velocity * delta
	if sway != 0.0:
		position.x += cos(_time * 6.0) * sway * delta

	if trail_length > 0:
		_trail.append(global_position)
		if _trail.size() > trail_length:
			_trail.remove_at(0)

	if bounds.has_area():
		var floor_y := bounds.end.y - size / 2
		if global_position.y >= floor_y and velocity.y > 0:
			if splits_into > 0:
				_split()
				return
			if bounce_speed > 0:
				global_position.y = floor_y
				velocity.y = -bounce_speed * randf_range(1.0 - bounce_variance, 1.0 + bounce_variance)
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
		piece.color = split_color
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


## True if this bullet is touching `rect` (the SOUL's hitbox) right now.
func hits(rect: Rect2) -> bool:
	if not is_armed():
		return false
	if shape == "beam":
		var center := rect.get_center()
		var closest := Geometry2D.get_closest_point_to_segment(center, global_position - beam_vector, global_position + beam_vector)
		return closest.distance_to(center) < size * 0.5 + rect.size.x * 0.5
	return get_hitbox().intersects(rect)


func _draw() -> void:
	var half := size / 2

	if not _trail.is_empty():
		# A glowing tail that fades out behind the bullet.
		for i in range(1, _trail.size()):
			var fade := float(i) / _trail.size()
			var tail_color := Color(color, 0.5 * fade)
			draw_line(_trail[i - 1] - global_position, _trail[i] - global_position, tail_color, maxf(1.0, size * 0.5 * fade))
	if glow:
		draw_circle(Vector2.ZERO, size * 1.1, Color(color, 0.18))
		draw_circle(Vector2.ZERO, size * 0.7, Color(color, 0.25))

	match shape:
		"beam":
			if not is_armed():
				# The warning: a thin line showing exactly where the slash will land.
				draw_line(-beam_vector, beam_vector, color, 1.5)
			else:
				draw_line(-beam_vector, beam_vector, Color(color, 0.3), size * 2.4)
				draw_line(-beam_vector, beam_vector, color, size * 1.2)
				draw_line(-beam_vector, beam_vector, Color(1, 0.95, 0.95), size * 0.45)
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
		"claw":
			# A claw streak: a thick line ending in a sharp point, along the way it moves.
			var dir := velocity.normalized() if velocity.length() > 0.1 else Vector2.DOWN
			draw_line(-dir * size, dir * size * 0.5, color, 3.0)
			draw_line(dir * size * 0.5, dir * size, color, 1.5)
		"arrow":
			# An arrow pointing the way it flies, with a white-hot tip.
			var dir := velocity.normalized() if velocity.length() > 0.1 else Vector2.DOWN
			var side := dir.orthogonal() * size * 0.45
			draw_line(-dir * size, dir * size * 0.6, color, 2.5)
			draw_colored_polygon(PackedVector2Array([dir * size, dir * size * 0.25 + side, dir * size * 0.25 - side]), color)
			draw_circle(dir * size * 0.75, size * 0.15, Color(1, 0.9, 0.85))
		"ball":
			draw_circle(Vector2.ZERO, half, color)
			draw_arc(Vector2.ZERO, half * 0.6, _time * 6.0, _time * 6.0 + PI, 8, Color(1, 1, 1, 0.6), 2.0)
		_:
			draw_rect(Rect2(-half, -half, size, size), color)


## False while the bullet is still just a warning.
func is_armed() -> bool:
	return _time >= delay
