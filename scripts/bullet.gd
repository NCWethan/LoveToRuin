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
## "finger", "ball", "claw", "arrow", "beam", "claw_slash", "ring", "clapper",
## "yolk", "lance", "shield" or "justice_star".
@export var shape: String = "square"

## For shape "glyph": which little picture to draw (see GLYPHS), each of its pixels
## GLYPH_PIXEL screen pixels big. Flips to face the way it's moving sideways.
var glyph: String = ""
## Spins as it flies, in turns of... radians per second.
var spin: float = 0.0
## Points the way it's moving (paper planes, arrows of things).
var face_motion: bool = false
## Stops dead this many seconds after it starts moving, and stays there (gum
## sticking where it lands). -1: never.
var stop_after: float = -1.0
## Bounces off the left and right sides of the box instead of leaving it.
var wall_bounce: bool = false
## Runs laps around the inside edge of the box at this speed (pixels per second),
## clockwise, starting `lap_start` pixels along. 0: doesn't.
var lap_speed: float = 0.0
var lap_start: float = 0.0
## Zigzags up and down this many pixels as it goes (a scampering squirrel).
var zigzag: float = 0.0
## What a bullet that cracks into pieces breaks into, when they're glyphs.
var split_glyph: String = ""

## Bounces up when it reaches the bottom of the box (for hopping things).
var bounce_speed: float = 0.0
## Cracks into this many small pieces when it reaches the bottom of the box.
var splits_into: int = 0
## The color of those pieces.
var split_color: Color = Color(1.0, 0.85, 0.2)
## The shape of those pieces.
var split_shape: String = "square"
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
## Rings only ("ring"): a circle of sound that grows outward from `position`.
## `size` is how thick it is; `radius` grows by `ring_speed` each second. A gap of
## `gap_width` radians, centered on `gap_angle`, is safe to pass through.
var radius: float = 4.0
var ring_speed: float = 60.0
var gap_angle: float = 0.0
var gap_width: float = 0.0
## Clappers only ("clapper"): a bell clapper hanging from `position`, swinging back
## and forth by `swing_amplitude` radians, `swing_length` pixels long.
var swing_amplitude: float = 1.0
var swing_speed: float = 2.5
var swing_length: float = 100.0
var _swing_angle: float = 0.0
## How many past positions to draw as a glowing trail (0 = no trail).
var trail_length: int = 0
## Draws a soft glow around the bullet.
var glow: bool = false
## The enemy that fired it (for status effects a hit can cause).
var source: Object
## Everything about it runs this much slower or faster (Stravant's Lightning slows
## an enemy's attacks down).
var time_scale: float = 1.0

## The area the bullet lives in. Once it flies out, it disappears.
var bounds: Rect2

var _time: float = 0.0
var _trail: PackedVector2Array = PackedVector2Array()
var _armed_before: bool = false


func _ready() -> void:
	# Draw on top of the battle box, like the SOUL.
	z_index = 1


func _process(delta: float) -> void:
	delta *= time_scale
	_time += delta
	if not is_armed():
		# Still a warning: see-through and not moving yet. Beams flicker.
		modulate.a = 0.35 + (0.35 * absf(sin(_time * 22.0)) if shape in ["beam", "claw_slash"] else 0.0)
		queue_redraw()
		return
	if not _armed_before:
		_armed_before = true
		if shape in ["beam", "claw_slash"]:
			Game.play_sfx("slash")
	modulate.a = 1.0
	if lifetime > 0.0:
		var left := delay + lifetime - _time
		if left <= 0.0:
			queue_free()
			return
		# Slashes fade out as they finish.
		if shape in ["beam", "claw_slash"]:
			modulate.a = clampf(left / (lifetime * 0.5), 0.0, 1.0)

	# Chasing the SOUL: turn a little toward it each frame.
	if homing and is_instance_valid(homing) and _time - delay < homing_time and velocity.length() > 0.1:
		var wanted := (homing.global_position - global_position).angle()
		var turn := clampf(angle_difference(velocity.angle(), wanted), -turn_rate * delta, turn_rate * delta)
		velocity = velocity.rotated(turn)

	if shape == "ring":
		radius += ring_speed * delta
		if radius > 260.0:
			queue_free()
		queue_redraw()
		return
	if shape == "clapper":
		_swing_angle = sin((_time - delay) * swing_speed) * swing_amplitude
		queue_redraw()
		return

	if lap_speed > 0.0:
		global_position = _lap_point(lap_start + (_time - delay) * lap_speed)
		queue_redraw()
		return
	if stop_after >= 0.0 and _time - delay >= stop_after:
		velocity = Vector2.ZERO
		acceleration = Vector2.ZERO
		sway = 0.0
	velocity += acceleration * delta
	position += velocity * delta
	if sway != 0.0:
		position.x += cos(_time * 6.0) * sway * delta
	if zigzag != 0.0:
		position.y += cos(_time * 12.0) * zigzag * 12.0 * delta
	if wall_bounce and bounds.has_area():
		var half := size / 2
		if (global_position.x < bounds.position.x + half and velocity.x < 0) or (global_position.x > bounds.end.x - half and velocity.x > 0):
			velocity.x = -velocity.x

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


## A point `distance` pixels clockwise around the inside edge of the box (from the
## top-left corner), for things running laps.
func _lap_point(distance: float) -> Vector2:
	var r := bounds.grow(-size / 2 - 1)
	var perimeter := 2.0 * (r.size.x + r.size.y)
	var d := fposmod(distance, perimeter)
	if d < r.size.x:
		return r.position + Vector2(d, 0)
	d -= r.size.x
	if d < r.size.y:
		return Vector2(r.end.x, r.position.y + d)
	d -= r.size.y
	if d < r.size.x:
		return Vector2(r.end.x - d, r.end.y)
	d -= r.size.x
	return Vector2(r.position.x, r.end.y - d)


## Cracks into small pieces that scatter up and sideways.
func _split() -> void:
	for i in splits_into:
		var piece := Bullet.new()
		piece.bounds = bounds
		piece.damage = maxi(1, damage - 1)
		piece.source = source
		piece.time_scale = time_scale
		piece.size = 5.0 if split_shape == "yolk" else 4.0
		piece.color = split_color
		piece.shape = split_shape
		piece.glyph = split_glyph
		piece.trail_length = 3 if split_shape == "yolk" else 0
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
	if shape == "ring":
		var offset := rect.get_center() - global_position
		if absf(offset.length() - radius) > size * 0.5 + rect.size.x * 0.5:
			return false
		# Inside the gap? Then it's safe.
		return gap_width <= 0.0 or absf(angle_difference(offset.angle(), gap_angle)) > gap_width / 2
	if shape == "clapper":
		var center := rect.get_center()
		var tip := _clapper_tip()
		var closest := Geometry2D.get_closest_point_to_segment(center, global_position, tip)
		return closest.distance_to(center) < 3.0 + rect.size.x * 0.5 or tip.distance_to(center) < size + rect.size.x * 0.5
	if shape in ["beam", "claw_slash"]:
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
		"glyph":
			_draw_glyph()
		"claw_slash":
			var dir := beam_vector.normalized()
			var side := dir.orthogonal()
			if not is_armed():
				# The warning: a faint scratch, broken into dashes.
				var length := beam_vector.length()
				var d := -length
				while d < length:
					draw_line(dir * d, dir * minf(d + 7.0, length), color, 1.0)
					d += 12.0
			else:
				# A claw mark: thin at both ends, fat in the middle, with a hot white core
				# and a little spray of torn bits along it.
				var tip := beam_vector
				var mid_width := size * 0.9
				draw_colored_polygon(PackedVector2Array([-tip, side * mid_width * 1.9, tip, -side * mid_width * 1.9]), Color(color, 0.3))
				draw_colored_polygon(PackedVector2Array([-tip, side * mid_width, tip, -side * mid_width]), color)
				draw_colored_polygon(PackedVector2Array([-tip * 0.9, side * mid_width * 0.35, tip * 0.9, -side * mid_width * 0.35]), Color(1, 1, 1))
				for k in 5:
					var along := (k - 2) / 2.5
					var bit := tip * along + side * (mid_width + 3.0) * (1.0 if k % 2 == 0 else -1.0)
					draw_line(bit, bit + side * (4.0 if k % 2 == 0 else -4.0) + dir * 3.0, Color(color, 0.8), 1.5)
		"ring":
			# A ring of sound, drawn as an arc that skips the gap.
			# Only the parts inside the box are drawn.
			var segments := 64
			for k in segments:
				var a0 := gap_angle + gap_width / 2 + (TAU - gap_width) * k / segments
				var a1 := gap_angle + gap_width / 2 + (TAU - gap_width) * (k + 1) / segments
				var p0 := Vector2.from_angle(a0) * radius
				var p1 := Vector2.from_angle(a1) * radius
				if bounds.has_area() and not bounds.has_point(global_position + (p0 + p1) / 2):
					continue
				draw_line(p0, p1, Color(color, 0.3), size * 2.0)
				draw_line(p0, p1, color, size * 0.7)
		"clapper":
			# The bell's clapper: a rod with a heavy ball on the end.
			var tip := _clapper_tip() - global_position
			if not is_armed():
				draw_line(Vector2.ZERO, tip, Color(color, 0.6), 1.0)
			else:
				draw_line(Vector2.ZERO, tip, Color(0.3, 0.3, 0.32), 4.0)
				draw_circle(tip, size + 3.0, Color(color, 0.25))
				draw_circle(tip, size, color)
				draw_circle(tip + Vector2(-size * 0.3, -size * 0.3), size * 0.35, Color(1, 1, 1, 0.6))
		"beam":
			if not is_armed():
				# The warning: a thin line showing exactly where the slash will land.
				draw_line(-beam_vector, beam_vector, color, 1.5)
			else:
				draw_line(-beam_vector, beam_vector, Color(color, 0.3), size * 2.4)
				draw_line(-beam_vector, beam_vector, color, size * 1.2)
				draw_line(-beam_vector, beam_vector, Color(1, 0.95, 0.95), size * 0.45)
		"egg":
			# A shaded egg, wobbling as it falls, with a crack that grows as it speeds up.
			var wobble := sin(_time * 9.0) * 0.18
			draw_set_transform(Vector2.ZERO, wobble, Vector2.ONE)
			var egg := PackedVector2Array()
			for k in 20:
				var a := k * TAU / 20
				# Narrower at the top, rounder at the bottom.
				var r := half * (0.82 if sin(a) < 0 else 1.0)
				egg.append(Vector2(cos(a) * half * 0.85, sin(a) * r * 1.2))
			draw_colored_polygon(egg, color.darkened(0.25))
			var inner := PackedVector2Array()
			for p in egg:
				inner.append(p * 0.82 + Vector2(-0.8, -0.8))
			draw_colored_polygon(inner, color)
			draw_circle(Vector2(-half * 0.3, -half * 0.45), half * 0.22, Color(1, 1, 1, 0.8))
			var crack := clampf(velocity.length() / 220.0, 0.0, 1.0)
			if crack > 0.25:
				var line := PackedVector2Array([Vector2(-half * 0.8, 0), Vector2(-half * 0.3, -2), Vector2(0, 1.5), Vector2(half * 0.35, -1.5), Vector2(half * 0.8, 0.5)])
				var shown := PackedVector2Array()
				for k in maxi(2, int(line.size() * crack)):
					shown.append(line[k])
				draw_polyline(shown, Color(0.35, 0.3, 0.25), 1.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"yolk":
			# A runny drop of yolk: a round bottom pulled to a point at the top.
			var dir := velocity.normalized() if velocity.length() > 0.1 else Vector2.DOWN
			var side := dir.orthogonal()
			var tail := -dir * half * 1.6
			draw_colored_polygon(PackedVector2Array([tail, side * half * 0.95, dir * half * 0.2, -side * half * 0.95]), color.darkened(0.15))
			draw_circle(Vector2.ZERO, half, color.darkened(0.15))
			draw_circle(-side * 0.6 - dir * 0.6, half * 0.8, color)
			draw_circle(-side * half * 0.35 - dir * half * 0.3, half * 0.28, Color(1, 1, 0.85, 0.9))
		"bunny":
			# A little white bunny mid-hop: round body, head, floppy ears, pink nose,
			# a black eye and a cotton tail. It leans into the jump.
			var facing := 1.0 if velocity.x >= 0 else -1.0
			draw_set_transform(Vector2.ZERO, clampf(velocity.y / 600.0, -0.4, 0.4) * facing, Vector2(facing, 1))
			var ear_flop := clampf(-velocity.y / 300.0, -1.0, 1.0)
			draw_circle(Vector2(-half * 0.2, half * 0.15), half * 0.8, color.darkened(0.12))
			draw_circle(Vector2(-half * 0.3, 0), half * 0.72, color)
			draw_circle(Vector2(-half * 1.05, half * 0.1), half * 0.3, Color(1, 1, 1))
			draw_circle(Vector2(half * 0.55, -half * 0.45), half * 0.52, color)
			for e in 2:
				var base := Vector2(half * (0.35 + e * 0.35), -half * 0.85)
				var tip := base + Vector2(-half * (0.5 + 0.3 * ear_flop) - e * 1.0, -half * (1.1 - 0.2 * ear_flop))
				draw_line(base, tip, color, 2.6)
				draw_line(base.lerp(tip, 0.2), base.lerp(tip, 0.8), Color(1.0, 0.7, 0.78), 1.0)
			draw_circle(Vector2(half * 0.75, -half * 0.55), 1.0, Color(0.1, 0.1, 0.12))
			draw_circle(Vector2(half * 1.05, -half * 0.35), 0.9, Color(1.0, 0.55, 0.65))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"lance":
			# A knight's lance: a long tapered steel point, a striped grip, and a red
			# and gold pennant flapping behind it.
			var dir := velocity.normalized() if velocity.length() > 0.1 else Vector2.RIGHT
			var side := dir.orthogonal()
			if not is_armed():
				# The warning: a faint line across the box at its height.
				draw_line(Vector2.ZERO, dir * (bounds.size.x - 8.0 if bounds.has_area() else 200.0), Color(1, 0.3, 0.3, 0.6), 1.0)
			var back := -dir * size * 2.6
			draw_colored_polygon(PackedVector2Array([dir * size * 1.6, side * size * 0.38, -side * size * 0.38]), color)
			draw_line(dir * size * 1.5, side * size * 0.2, Color(1, 1, 1, 0.9), 1.0)
			draw_colored_polygon(PackedVector2Array([side * size * 0.55, side * size * 0.25 - dir * 3.0, -side * size * 0.25 - dir * 3.0, -side * size * 0.55]), Color(0.75, 0.6, 0.25))
			draw_line(-dir * 3.0, back, Color(0.55, 0.35, 0.2), 2.5)
			for k in 3:
				var at := -dir * (6.0 + k * 5.0)
				draw_line(at - side * 1.3, at + side * 1.3 - dir * 1.5, Color(0.85, 0.2, 0.2), 1.2)
			var flap := sin(_time * 18.0) * 2.5
			draw_colored_polygon(PackedVector2Array([back * 0.55, back * 0.55 + side * size * 0.75, back * 0.95 + side * (size * 0.55 + flap)]), Color(0.85, 0.2, 0.2))
			draw_colored_polygon(PackedVector2Array([back * 0.55, back * 0.55 + side * size * 0.38, back * 0.8 + side * (size * 0.35 + flap * 0.6)]), Color(1.0, 0.82, 0.25))
		"shield":
			# A kite shield: steel rim, blue field, a gold star in the middle.
			var s := half * 1.15
			var outline := PackedVector2Array([Vector2(-s, -s * 0.9), Vector2(s, -s * 0.9), Vector2(s * 0.95, s * 0.1), Vector2(0, s * 1.15), Vector2(-s * 0.95, s * 0.1)])
			draw_colored_polygon(outline, color)
			var field := PackedVector2Array()
			for p in outline:
				field.append(p * 0.72 + Vector2(0, -0.6))
			draw_colored_polygon(field, Color(0.2, 0.32, 0.65))
			draw_line(Vector2(-s * 0.72, -s * 0.66), Vector2(-s * 0.1, -s * 0.66), Color(1, 1, 1, 0.5), 1.0)
			_draw_star(Vector2(0, -s * 0.1), s * 0.38, Color(1.0, 0.82, 0.25), 0.0)
		"justice_star":
			# A spinning five-pointed star of light, with a hot white middle.
			_draw_star(Vector2.ZERO, half * 1.5, Color(color, 0.35), _time * 7.0)
			_draw_star(Vector2.ZERO, half, color, _time * 7.0)
			_draw_star(Vector2.ZERO, half * 0.45, Color(1, 1, 0.9), _time * 7.0)
		"star":
			var spin := _time * 8.0
			for i in 4:
				var dir := Vector2.from_angle(spin + i * PI / 2) * half
				draw_line(-dir, dir, color, 2.0)
		"straw":
			# A little tuft of straw (three stalks), tumbling as it falls.
			var spin := _time * 4.0 + global_position.x * 0.1
			for k in 3:
				var dir := Vector2.from_angle(spin + (k - 1) * 0.35)
				draw_line(-dir * size, dir * size, color.darkened(0.15 * k), 2.0)
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


## Little pixel pictures for attacks (shape "glyph"). Each letter is a color in
## GLYPH_COLORS; "." is see-through.
const GLYPH_PIXEL := 2.0
const GLYPH_COLORS := {
	"K": Color(0.08, 0.08, 0.1), "W": Color(0.96, 0.96, 0.98), "R": Color(0.9, 0.2, 0.22),
	"Y": Color(1.0, 0.85, 0.25), "O": Color(1.0, 0.55, 0.15), "G": Color(0.72, 0.74, 0.8),
	"g": Color(0.42, 0.44, 0.5), "B": Color(0.3, 0.5, 0.95), "b": Color(0.5, 0.32, 0.18),
	"P": Color(1.0, 0.55, 0.75), "N": Color(0.35, 0.8, 0.35), "C": Color(0.45, 0.85, 1.0),
	"L": Color(0.8, 0.72, 1.0), "T": Color(0.85, 0.72, 0.5),
}
const GLYPHS := {
	"key": [".YYY....", "Y...YYYY", ".YYY.Y.Y"],
	"cone": ["..O..", ".OWO.", ".OOO.", "OWWWO", "OOOOO"],
	"can": [".GGG.", "GRRRG", "GWWWG", "GRRRG", ".GGG."],
	"wet_sign": ["..Y..", ".YKY.", ".YKY.", "YYYYY", "Y...Y"],
	"board": [".KKKKKKKK.", "BBBBBBBBBB", ".W......W."],
	"car": ["..RRRR..", ".RCCCCR.", "RRRRRRRR", "YRRRRRRY", ".K....K."],
	"gum": [".PPP.", "PPWPP", "PPPPP", ".PPP."],
	"segway": ["..GG..", "..g...", "..g...", ".gggg.", "KK..KK"],
	"coupon": ["YYYYYY", "YKWWKY", "YWKKWY", "YYYYYY"],
	"grocery": [".b..b.", "TTTTTT", "TNTTRT", "TTTTTT", "TTTTTT"],
	"apple": ["..N.", ".RR.", "RRRR", ".RR."],
	"bird": ["..GG.", ".GGKO", "GGGG.", ".GG.."],
	"notif": ["WWWWW", "WRRWW", "WWWWW", ".W..."],
	"text": ["LLLLLLL", "LKLKLKL", "LLLLLLL", ".L....."],
	"drop": ["..C..", ".CCC.", "CCWCC", ".CCC."],
	"moth": ["T...T", "TTKTT", ".TKT.", "T...T"],
	"z": ["YYYY", "..Y.", ".Y..", "YYYY"],
	"dog": ["O....O.", "OOOOOOK", "OOOOOOO", "WWWWWW.", "O.O..O."],
	"plane": ["W.....", "WWW...", "WWWWWW", "WWW...", "W....."],
	"book": ["BBBB", "BWWB", "BBBB"],
	"backpack": [".bb.", "RRRR", "RbbR", "RRRR"],
	"ostrich": ["..GG", "..KO", ".GG.", "GGGG", ".T.T"],
	"cart": ["G.....", "GGGGGG", "GgGgGG", ".GGGG.", ".K..K."],
	"coin": [".YY.", "YWYY", "YYYY", ".YY."],
	"ink": [".K.", "KKK", ".K."],
	"balloon": [".RR.", "RRRR", "RRWR", ".RR.", "..W.", "..W."],
	"feather": ["...W", "..WW", ".WW.", "WW..", "W..."],
	"pink_feather": ["...P", "..PP", ".PP.", "PP..", "P..."],
	"hat": ["..R..", ".RRR.", "RRRRR"],
	"shovel": ["...b", "..b.", ".GG.", "GG.."],
	"fry": ["Y.Y", "YYY", "YYY", "RRR", "RRR"],
	"acorn": [".bb.", "bbbb", "TTTT", ".TT."],
	"squirrel": ["....bb", "b..bbb", "bbbbb.", ".bbb..", ".b.b.."],
	"leaf": ["..N.", ".NN.", "NN.."],
	"bag": ["W..W", "WWWW", "WKKW", "WWWW"],
	"tick": ["WW", "WW"],
	"tennis": [".NN.", "NYNN", "NNYN", ".NN."],
	"paper": ["WW", "WW"],
	"dust": ["L"],
	"heart_card": ["WWW", "WRW", "WWW"],
}


func _draw_glyph() -> void:
	var rows: Array = GLYPHS.get(glyph, ["W"])
	var w := str(rows[0]).length()
	var h := rows.size()
	var angle := _time * spin
	var flip := 1.0
	if face_motion and velocity.length() > 0.1:
		angle = velocity.angle()
	elif velocity.x < -1.0:
		flip = -1.0
	draw_set_transform(Vector2.ZERO, angle, Vector2(flip, 1.0))
	var origin := -Vector2(w, h) * GLYPH_PIXEL / 2.0
	for y in h:
		var row: String = rows[y]
		for x in w:
			var c: Color = GLYPH_COLORS.get(row[x], Color.TRANSPARENT)
			if c.a > 0.0:
				draw_rect(Rect2(origin + Vector2(x, y) * GLYPH_PIXEL, Vector2(GLYPH_PIXEL, GLYPH_PIXEL)), Color(c, c.a * color.a))
	draw_set_transform(Vector2.ZERO)


## A filled five-pointed star centered on `at`.
func _draw_star(at: Vector2, radius: float, star_color: Color, spin: float) -> void:
	var points := PackedVector2Array()
	for k in 10:
		var r := radius if k % 2 == 0 else radius * 0.45
		points.append(at + Vector2.from_angle(spin - PI / 2 + k * PI / 5) * r)
	draw_colored_polygon(points, star_color)


## Where the end of a clapper is right now, in screen coordinates.
func _clapper_tip() -> Vector2:
	return global_position + Vector2.DOWN.rotated(_swing_angle) * swing_length


## False while the bullet is still just a warning.
func is_armed() -> bool:
	return _time >= delay
