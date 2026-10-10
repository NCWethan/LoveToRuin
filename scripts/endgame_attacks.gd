class_name EndgameAttacks
extends RefCounted
## The last of the Corps, on the Genocide path: Eggo (on the couch), MuffinMage (in
## the kitchen), and Nassan (at the register, at Vons). Works like Attacks.spawn():
## adds bullets, and returns how many seconds until it's called again (or -1 for a
## pattern it doesn't know).

const YOLK := Color(1.0, 0.8, 0.2)
const SHELL := Color(0.97, 0.95, 0.9)
const FLOUR := Color(0.95, 0.9, 0.8)
const GRILL := Color(1.0, 0.45, 0.2)
const SALMON := Color(1.0, 0.6, 0.5)
const MAP := Color(0.45, 0.6, 0.95)
const STRING := Color(0.9, 0.2, 0.2)


static func spawn(pattern: String, enemy: Enemy, parent: Node, area: Rect2, s: Vector2, step: int) -> float:
	match pattern:
		# --- Eggo ---
		"hard_boiled": return _hard_boiled(enemy, parent, area, s, step)
		"toast": return _toast(enemy, parent, area, s, step)
		"sunny_side": return _sunny_side(enemy, parent, area, s, step)
		"just_talk": return 99.0
		# --- MuffinMage ---
		"muffin_rain": return _muffin_rain(enemy, parent, area, s, step)
		"grill_flames": return _grill_flames(enemy, parent, area, s, step)
		"spatula_flip": return _spatula_flip(enemy, parent, area, s, step)
		"salmon_leap": return _salmon_leap(enemy, parent, area, s, step)
		"sprinkles": return _sprinkles(enemy, parent, area, s, step)
		"oven_timer": return _oven_timer(enemy, parent, area, s, step)
		"magic_missile": return _magic_missile(enemy, parent, area, s, step)
		"the_warning": return _the_warning(enemy, parent, area, s, step)
		# --- Nassan ---
		"step_one": return _step_one(enemy, parent, area, s, step)
		"red_string": return _red_string(enemy, parent, area, s, step)
		"five_pages": return _five_pages(enemy, parent, area, s, step)
		"circle_the_map": return _circle_the_map(enemy, parent, area, s, step)
		"contingency": return _contingency(enemy, parent, area, s, step)
		"push_pins": return _push_pins(enemy, parent, area, s, step)
		"price_check": return _price_check(enemy, parent, area, s, step)
		"the_note": return 99.0
		# --- Hopkuna, at the end ---
		"twelve_tattoos": return _twelve_tattoos(enemy, parent, area, s, step)
		"everything": return _everything(enemy, parent, area, s, step)
		"last_stand": return _last_stand(enemy, parent, area, s, step)
	return -1.0


static func _glyph(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, glyph: String, size: float = 8.0) -> Bullet:
	return FolkAttacks._glyph(enemy, parent, area, at, glyph, size)


static func _dot(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, color: Color, size: float = 6.0) -> Bullet:
	var b := Attacks._bullet(enemy, parent, area, at)
	b.size = size
	b.color = color
	return b


# --- Eggo ---------------------------------------------------------------------------------
# He doesn't want to hurt you. He does anyway, a little, with the same attacks he
# used the day you met. Then he stops (JUST TALK: nothing at all).

## HARD BOILED: eggs that don't crack. They bounce, and bounce, and bounce.
static func _hard_boiled(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var egg := Attacks._bullet(enemy, parent, area, Vector2(x, area.position.y + 6))
	egg.shape = "egg"
	egg.size = 10.0
	egg.color = SHELL
	egg.velocity = Vector2(randf_range(-50, 50), 40)
	egg.acceleration = Vector2(0, 340)
	egg.bounce_speed = 230
	egg.wall_bounce = true
	egg.lifetime = 3.0
	return 0.55


## TOAST: his bunny, Toast, hopping across the box. Again. And again.
static func _toast(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var bunny := Attacks._bullet(enemy, parent, area, Vector2(area.position.x + 8 if left else area.end.x - 8, area.end.y - 8))
	bunny.shape = "bunny"
	bunny.size = 10.0
	bunny.color = Color(0.85, 0.7, 0.55)
	var up := sqrt(640.0 * maxf((area.end.y - 8) - soul.y, 16.0))
	# (Every other hop peaks right over you.)
	var vx := (soul.x - bunny.position.x) / (up / 320.0) if step % 2 == 1 else (95.0 if left else -95.0)
	bunny.velocity = Vector2(vx, -up)
	bunny.acceleration = Vector2(0, 320)
	bunny.bounce_speed = up
	return 0.9


## SUNNY SIDE UP: yolks in a ring, bursting outward from where he cracked them.
static func _sunny_side(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var at := (soul + Vector2.from_angle(randf() * TAU) * 34.0).clamp(area.position + Vector2(8, 8), area.end - Vector2(8, 8))
	var white := _dot(enemy, parent, area, at, SHELL, 14.0)
	white.delay = 0.5
	white.lifetime = 0.2
	for i in 8:
		var yolk := Attacks._bullet(enemy, parent, area, at)
		yolk.shape = "yolk"
		yolk.size = 6.0
		yolk.color = YOLK
		yolk.delay = 0.6
		yolk.velocity = Vector2.from_angle(i * TAU / 8.0 + step) * 90.0
	return 0.9


# --- MuffinMage ----------------------------------------------------------------------------
# Calm. Almost bored. A salmon burger in one hand the whole fight.

## MUFFIN RAIN: muffins fall, and crumble into crumbs when they land.
static func _muffin_rain(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var muffin := Attacks._bullet(enemy, parent, area, Vector2(x, area.position.y + 4))
	muffin.shape = "ball"
	muffin.size = 10.0
	muffin.color = Color(0.75, 0.5, 0.3)
	muffin.velocity = Vector2(0, 70)
	muffin.acceleration = Vector2(0, 200)
	muffin.splits_into = 5
	muffin.split_color = FLOUR
	return 0.4


## THE GRILL: bars of flame rise up from the bottom, one column at a time.
static func _grill_flames(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var cols := 8
	var c := step % cols if (step / cols) % 2 == 0 else cols - 1 - step % cols
	var x := area.position.x + (c + 0.5) * area.size.x / cols
	if step % 5 == 4:
		x = clampf(soul.x, area.position.x + 6, area.end.x - 6)
	Attacks._beam(enemy, parent, area, Vector2(x, area.get_center().y), Vector2.DOWN, 0.4, GRILL)
	return 0.28


## SPATULA FLIP: patties flipped high, and coming down where you'll be.
static func _spatula_flip(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(randf_range(area.position.x + 10, area.end.x - 10), area.end.y - 6)
	var target := Attacks._aim_x(area, soul, step, 2)
	var up := sqrt(640.0 * maxf((area.end.y - 6) - soul.y, 14.0)) if step % 2 == 0 else randf_range(230, 270)
	var patty := _dot(enemy, parent, area, from, Color(0.5, 0.3, 0.2), 9.0)
	patty.velocity = Vector2((target - from.x) / (up / 320.0), -up)
	patty.acceleration = Vector2(0, 320)
	return 0.4


## SALMON LEAP: salmon, leaping upstream, across the box in arcs.
static func _salmon_leap(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var fish := _glyph(enemy, parent, area, Vector2(area.position.x + 6 if left else area.end.x - 6, area.end.y - 8), "fish", 8.0)
	var up := sqrt(640.0 * maxf((area.end.y - 8) - soul.y, 16.0))
	var vx := (soul.x - fish.position.x) / (up / 320.0) if step % 2 == 1 else (140.0 if left else -140.0)
	fish.velocity = Vector2(vx, -up)
	fish.acceleration = Vector2(0, 320)
	fish.face_motion = true
	return 0.45


## SPRINKLES: a shower of sprinkles, every color, from the top.
static func _sprinkles(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var colors := [Color(1.0, 0.4, 0.5), Color(0.4, 0.8, 1.0), Color(1.0, 0.9, 0.3), Color(0.5, 1.0, 0.5), Color(0.9, 0.5, 1.0)]
	for i in 2:
		var bit := _dot(enemy, parent, area, Vector2(Attacks._aim_x(area, soul, step * 2 + i, 5), area.position.y + 4), colors[(step + i) % colors.size()], 4.0)
		bit.velocity = Vector2(randf_range(-20, 20), 110)
	return 0.1


## OVEN TIMER: it ticks, and the heat closes in around you when it dings.
static func _oven_timer(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var ring := Attacks._bullet(enemy, parent, area, soul)
	ring.shape = "ring"
	ring.size = 5.0
	ring.color = GRILL
	ring.delay = 0.5
	ring.radius = 64.0
	ring.ring_speed = -70.0
	ring.gap_angle = randf() * TAU
	ring.gap_width = 0.55
	ring.lifetime = 1.1
	return 1.1


## MAGIC MISSILE: he is, technically, a mage. Sparkles that follow you, a little.
static func _magic_missile(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(area.end.x - 6, randf_range(area.position.y + 8, area.end.y - 8))
	var spark := Attacks._bullet(enemy, parent, area, from)
	spark.shape = "star"
	spark.size = 8.0
	spark.color = Color(0.7, 0.5, 1.0)
	spark.velocity = (soul - from).normalized() * 120.0
	spark.homing = Attacks._soul(parent)
	spark.homing_time = 0.7
	spark.turn_rate = 2.2
	spark.trail_length = 5
	spark.glow = true
	return 0.6


## (The end.) THE WARNING: the same words, over and over, falling. He warned you.
static func _the_warning(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var word := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "text", 8.0)
	word.velocity = Vector2(0, 75)
	word.sway = 12.0
	return 0.24


# --- Nassan ---------------------------------------------------------------------------------
# He always had a plan. Step one: find them. Step two: we'll figure out step two.

## STEP ONE: markers appear on a grid, one by one, numbered. Then they all go off.
static func _step_one(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for i in 6:
		var spot := Vector2(randf_range(area.position.x + 10, area.end.x - 10), randf_range(area.position.y + 10, area.end.y - 10))
		if i == 0:
			spot = soul.clamp(area.position + Vector2(10, 10), area.end - Vector2(10, 10))
		var marker := _dot(enemy, parent, area, spot, MAP, 12.0)
		marker.delay = 0.5 + i * 0.12
		marker.lifetime = 0.3
	return 1.4


## RED STRING: pins on the corkboard, and red string pulled tight between them,
## right through where you are.
static func _red_string(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var pin_a := Vector2(area.position.x + 4, randf_range(area.position.y + 6, area.end.y - 6))
	var dir := (soul - pin_a).normalized()
	Attacks._beam(enemy, parent, area, soul, dir, 0.6, STRING)
	if step % 2 == 1:
		Attacks._beam(enemy, parent, area, soul, dir.orthogonal(), 0.9, STRING)
	return 1.0


## FIVE PAGES: his note, five pages long, coming down one page at a time.
static func _five_pages(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var page := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "paper", 10.0)
	page.velocity = Vector2(0, 70)
	page.sway = 30.0
	return 0.3


## CIRCLE THE MAP: rings drawn on the map, around the places he's sure of. You're
## one of them.
static func _circle_the_map(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var at := soul if step % 2 == 0 else (soul + Vector2.from_angle(randf() * TAU) * 40.0).clamp(area.position + Vector2(8, 8), area.end - Vector2(8, 8))
	var ring := Attacks._bullet(enemy, parent, area, at)
	ring.shape = "ring"
	ring.size = 4.0
	ring.color = Color(0.9, 0.25, 0.25)
	ring.delay = 0.4
	ring.radius = 48.0 if step % 2 == 0 else 4.0
	ring.ring_speed = -55.0 if step % 2 == 0 else 70.0
	ring.gap_angle = randf() * TAU
	ring.gap_width = 0.6
	ring.lifetime = 1.0
	return 0.75


## CONTINGENCY: he planned for you dodging. Shots go where you'd dodge TO: left and
## right of you, then above and below.
static func _contingency(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var offsets := [Vector2(-28, 0), Vector2(28, 0)] if step % 2 == 0 else [Vector2(0, -24), Vector2(0, 24)]
	offsets.append(Vector2.ZERO)
	for offset in offsets:
		var spot: Vector2 = (soul + offset).clamp(area.position + Vector2(6, 6), area.end - Vector2(6, 6))
		var plan := _dot(enemy, parent, area, spot, MAP, 10.0)
		plan.delay = 0.55
		plan.lifetime = 0.3
	return 0.85


## PUSH PINS: pins, dropped from the corkboard, point first.
static func _push_pins(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3)
	var pin := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "needle", 7.0)
	pin.velocity = Vector2(0, 160)
	pin.trail_length = 3
	return 0.18


## PRICE CHECK: the register beeps, and price tags fly off the scanner in a line.
static func _price_check(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var y := Attacks._aim_y(area, soul, step, 2)
	for i in 4:
		var tag := _glyph(enemy, parent, area, Vector2(area.end.x - 4, y), "coupon", 7.0)
		tag.delay = 0.2 + i * 0.09
		tag.velocity = Vector2(-150, 0)
	return 0.75


# --- Hopkuna, at the end ----------------------------------------------------------------

## TWELVE TATTOOS: his twelve marks glow, one after another, and each one cuts.
static func _twelve_tattoos(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var angle := (step % 12) * TAU / 12.0
	var color := Attacks.HOPKUNA_RED if (step / 12) % 2 == 0 else Color(0.45, 0.95, 0.55)
	Attacks._beam(enemy, parent, area, area.get_center() + Vector2.from_angle(angle + PI / 2) * (soul - area.get_center()).length() * 0.0, Vector2.from_angle(angle), 0.45, color)
	if step % 3 == 2:
		Attacks._beam(enemy, parent, area, soul, Vector2.from_angle(angle + PI / 2), 0.6, color)
	return 0.35


## EVERYTHING: everything from the whole game, a little of each. Cleave, the
## closing ring, red arrows, the fire.
static func _everything(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	match step % 4:
		0: return Attacks._cleave(enemy, parent, area) * 0.8
		1: return Attacks._burst(enemy, parent, area, soul) * 0.8
		2: return Attacks._red_arrows(enemy, parent, area, soul) * 0.8
		_: return Attacks._ember_rain(enemy, parent, area, soul, step) * 0.8


## (With Hop, at the end.) LAST STAND: Hopkuna, fighting for his life. Desperate,
## fast, and scared: everything at once, aimed badly.
static func _last_stand(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(randf_range(area.position.x, area.end.x), area.position.y + 4)
	var shard := Attacks._bullet(enemy, parent, area, from)
	shard.shape = "star"
	shard.size = 7.0
	shard.color = Attacks.HOPKUNA_RED
	shard.velocity = (soul - from).normalized().rotated(randf_range(-0.4, 0.4)) * randf_range(120, 200)
	shard.trail_length = 4
	shard.glow = true
	return 0.1
