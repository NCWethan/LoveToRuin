class_name RoadAttacks
extends RefCounted
## Attack patterns for the wild creatures of Chapter 2 (the road to each fragment:
## three per area, see WildBattles.CREATURES). Tougher than Chapter 1's: more at
## once, faster, and every one of them has something aimed at the SOUL.


static func spawn(pattern: String, enemy: Enemy, parent: Node, area: Rect2, s: Vector2, step: int) -> float:
	match pattern:
		# --- Mission Beach ---
		"crab_pinch": return _crab_pinch(enemy, parent, area, s, step)
		"crab_scuttle": return _crab_scuttle(enemy, parent, area, s, step)
		"jelly_drift": return _jelly_drift(enemy, parent, area, s, step)
		"jelly_sting": return _jelly_sting(enemy, parent, area, s, step)
		"kite_dive": return _kite_dive(enemy, parent, area, s, step)
		"kite_string": return _kite_string(enemy, parent, area, s, step)
		# --- Balboa Park ---
		"peacock_fan": return _peacock_fan(enemy, parent, area, s, step)
		"peacock_strut": return _peacock_strut(enemy, parent, area, s, step)
		"bust_roll": return _bust_roll(enemy, parent, area, s, step)
		"bust_glare": return _bust_glare(enemy, parent, area, s, step)
		"tour_flags": return _tour_flags(enemy, parent, area, s, step)
		"tour_flash": return _tour_flash(enemy, parent, area, s, step)
		# --- Downtown ---
		"pigeon_swoop": return _pigeon_swoop(enemy, parent, area, s, step)
		"pigeon_crumbs": return _pigeon_crumbs(enemy, parent, area, s, step)
		"meter_coins": return _meter_coins(enemy, parent, area, s, step)
		"meter_expired": return _meter_expired(enemy, parent, area, s, step)
		"neon_flicker": return _neon_flicker(enemy, parent, area, s, step)
		"neon_buzz": return _neon_buzz(enemy, parent, area, s, step)
		# --- Old Town ---
		"weed_roll": return _weed_roll(enemy, parent, area, s, step)
		"weed_gust": return _weed_gust(enemy, parent, area, s, step)
		"pinata_candy": return _pinata_candy(enemy, parent, area, s, step)
		"pinata_swing": return _pinata_swing(enemy, parent, area, s, step)
		"wax_drip": return _wax_drip(enemy, parent, area, s, step)
		"wax_flame": return _wax_flame(enemy, parent, area, s, step)
	return -1.0


static func _glyph(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, glyph: String, size: float = 8.0) -> Bullet:
	return FolkAttacks._glyph(enemy, parent, area, at, glyph, size)


# --- Sand Crab ---------------------------------------------------------------------------

## PINCH: two claws open on either side of your row, then snap shut on it.
static func _crab_pinch(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var y := clampf(soul.y, area.position.y + 8, area.end.y - 8)
	for side in [-1.0, 1.0]:
		var at := Vector2(area.position.x + 6 if side < 0 else area.end.x - 6, y)
		var claw := _glyph(enemy, parent, area, at, "claw", 10.0)
		claw.delay = 0.55
		claw.velocity = Vector2(-side * 220, 0)
		claw.lifetime = 1.2
	# A smaller claw a row above or below, so jumping just one way isn't free.
	var y2 := clampf(y + (24.0 if step % 2 == 0 else -24.0), area.position.y + 8, area.end.y - 8)
	var extra := _glyph(enemy, parent, area, Vector2(area.position.x + 6 if step % 2 == 0 else area.end.x - 6, y2), "claw", 8.0)
	extra.delay = 0.8
	extra.velocity = Vector2(180 if step % 2 == 0 else -180, 0)
	return 1.0


## SCUTTLE: little crabs run sideways across the box, bouncing off the walls.
static func _crab_scuttle(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var crab := _glyph(enemy, parent, area, Vector2(x, area.position.y + 6), "crab", 9.0)
	crab.velocity = Vector2(140 if step % 2 == 0 else -140, 70)
	crab.wall_bounce = true
	crab.lifetime = 3.5
	return 0.45


# --- Jellyfish ---------------------------------------------------------------------------

## DRIFT: jellyfish float up from the bottom, swaying side to side.
static func _jelly_drift(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var jelly := _glyph(enemy, parent, area, Vector2(x, area.end.y - 6), "jelly", 9.0)
	jelly.velocity = Vector2(0, -55)
	jelly.sway = 40.0
	return 0.5


## STING: a long tentacle flashes where it'll fall, then drops through.
static func _jelly_sting(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := clampf(soul.x + (0.0 if step % 3 == 0 else randf_range(-40, 40)), area.position.x + 6, area.end.x - 6)
	Attacks._beam(enemy, parent, area, Vector2(x, area.get_center().y), Vector2.DOWN, 0.55, Color(1.0, 0.55, 0.8))
	return 0.75


# --- Runaway Kite ------------------------------------------------------------------------

## DIVE: kites swoop in from the top and dive at you, nose first.
static func _kite_dive(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var start := Vector2(randf_range(area.position.x + 10, area.end.x - 10), area.position.y + 4)
	var kite := _glyph(enemy, parent, area, start, "kite", 10.0)
	kite.delay = 0.35
	kite.velocity = (soul - start).normalized() * 170.0
	kite.face_motion = true
	return 0.6


## STRING: the kite's string snaps taut across the box, at an angle.
static func _kite_string(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var angle := (0.35 if step % 2 == 0 else -0.35)
	Attacks._beam(enemy, parent, area, soul, Vector2.from_angle(angle), 0.6, Color(0.95, 0.95, 1.0))
	return 0.85


# --- Peacock -----------------------------------------------------------------------------

## FAN: the tail spreads, and its eyes fly out in a fan, aimed at you.
static func _peacock_fan(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var origin := Vector2(area.get_center().x + (step % 3 - 1) * 40.0, area.position.y + 4)
	var aim := (soul - origin).angle()
	for k in 5:
		var eye := _glyph(enemy, parent, area, origin, "eye", 8.0)
		eye.delay = 0.3
		eye.velocity = Vector2.from_angle(aim + (k - 2) * 0.28) * 120.0
	return 1.0


## STRUT: the peacock struts back and forth across the bottom, then the top,
## feathers trailing.
static func _peacock_strut(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var top := step % 2 == 0
	var y := clampf(soul.y + (-14.0 if top else 14.0), area.position.y + 8, area.end.y - 8)
	for k in 3:
		var feather := _glyph(enemy, parent, area, Vector2(area.position.x + 6 if top else area.end.x - 6, y + (k - 1) * 12.0), "plume", 8.0)
		feather.delay = 0.2 + k * 0.12
		feather.velocity = Vector2(150 if top else -150, 0)
		feather.zigzag = 30.0
	return 0.9


# --- Marble Bust -------------------------------------------------------------------------

## ROLL: heavy busts roll in from the sides, along the floor and back up the walls.
static func _bust_roll(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var bust := _glyph(enemy, parent, area, Vector2(area.position.x + 8 if left else area.end.x - 8, clampf(soul.y, area.position.y + 10, area.end.y - 10)), "bust", 12.0)
	bust.delay = 0.45
	bust.velocity = Vector2(170 if left else -170, 0)
	bust.spin = 5.0 if left else -5.0
	bust.wall_bounce = true
	bust.lifetime = 2.6
	return 1.1


## GLARE: its blank eyes glare at a row and a column, and the glare burns.
static func _bust_glare(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var warn := 0.6
	if step % 2 == 0:
		Attacks._beam(enemy, parent, area, soul, Vector2.RIGHT, warn, Color(0.95, 0.95, 0.9))
	else:
		Attacks._beam(enemy, parent, area, soul, Vector2.DOWN, warn, Color(0.95, 0.95, 0.9))
	return 0.8


# --- Tour Group --------------------------------------------------------------------------

## FLAGS: the group shuffles through in a tight line behind the guide's flag,
## with a gap to slip through.
static func _tour_flags(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var down := step % 2 == 0
	var gap := int(clampf((soul.x - area.position.x) / area.size.x * 8.0 + randf_range(-1.5, 1.5), 0.0, 7.0))
	for k in 8:
		if k == gap:
			continue
		var x := area.position.x + 10 + k * (area.size.x - 20) / 7.0
		var tourist := _glyph(enemy, parent, area, Vector2(x, area.position.y + 6 if down else area.end.y - 6), "flag" if k == 0 else "tourist", 8.0)
		tourist.velocity = Vector2(0, 70 if down else -70)
	return 1.25


## FLASH: cameras go off all at once: bursts of light from where they're pointing.
static func _tour_flash(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var at := Vector2(randf_range(area.position.x + 10, area.end.x - 10), randf_range(area.position.y + 10, area.end.y - 10))
	if step % 2 == 0:
		at = soul + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	for k in 8:
		var spark := _glyph(enemy, parent, area, at, "spark", 6.0)
		spark.delay = 0.45
		spark.velocity = Vector2.from_angle(k * TAU / 8.0) * 110.0
	return 0.55


# --- Tumbleweed --------------------------------------------------------------------------

## ROLL: tumbleweeds bounce in from the side along your row, spinning.
static func _weed_roll(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var y := clampf(soul.y + randf_range(-10, 10), area.position.y + 10, area.end.y - 10)
	var weed := _glyph(enemy, parent, area, Vector2(area.position.x + 8 if left else area.end.x - 8, y), "weed", 10.0)
	weed.delay = 0.3
	weed.velocity = Vector2(160 if left else -160, 0)
	weed.zigzag = 45.0
	weed.spin = 6.0 if left else -6.0
	return 0.55


## GUST: a gust of grit sweeps across the whole box, with one gap to hide in.
static func _weed_gust(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var rows := int(area.size.y / 12.0)
	var gap := clampi(int((soul.y - area.position.y) / 12.0) + randi_range(-1, 1), 0, rows - 2)
	for k in rows:
		if k == gap or k == gap + 1:
			continue
		var grit := _glyph(enemy, parent, area, Vector2(area.position.x + 4 if left else area.end.x - 4, area.position.y + 6 + k * 12), "dust", 6.0)
		grit.delay = 0.35
		grit.velocity = Vector2(190 if left else -190, 0)
	return 1.2


# --- Piñata ------------------------------------------------------------------------------

## CANDY: the piñata splits, and candy sprays down in a fan around you.
static func _pinata_candy(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var origin := Vector2(clampf(soul.x + randf_range(-30, 30), area.position.x + 10, area.end.x - 10), area.position.y + 4)
	for k in 7:
		var candy := _glyph(enemy, parent, area, origin, "candy", 7.0)
		candy.delay = 0.35
		candy.velocity = Vector2.from_angle(PI / 2 + (k - 3) * 0.32) * randf_range(110, 140)
		candy.spin = 4.0
	return 0.9


## SWING: the stick swings through: a slash across the box, through where you are.
static func _pinata_swing(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var angle := 0.55 if step % 2 == 0 else -0.55
	Attacks._beam(enemy, parent, area, soul, Vector2.from_angle(angle), 0.55, Color(0.95, 0.75, 0.4))
	return 0.8


# --- Wax Ghost ---------------------------------------------------------------------------

## DRIP: hot wax drips from above: where you are, and either side.
static func _wax_drip(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for k in 3:
		var x := clampf(soul.x + (k - 1) * 26.0, area.position.x + 6, area.end.x - 6)
		var drip := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "wax", 8.0)
		drip.delay = 0.3 + k * 0.15
		drip.velocity = Vector2(0, 150)
	return 0.75


## FLAME: little flames drift in from the sides and lean toward you.
static func _wax_flame(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var start := Vector2(area.position.x + 6 if left else area.end.x - 6, randf_range(area.position.y + 10, area.end.y - 10))
	var flame := _glyph(enemy, parent, area, start, "flame", 8.0)
	flame.delay = 0.25
	flame.velocity = (soul - start).normalized() * 95.0
	flame.sway = 30.0
	return 0.5


# --- Pigeon Gang -------------------------------------------------------------------------

## SWOOP: the gang dives in a V from one side, straight at you.
static func _pigeon_swoop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var lead := Vector2(area.position.x + 6 if left else area.end.x - 6, area.position.y + 8)
	var dir := (soul - lead).normalized()
	var side := Vector2(-dir.y, dir.x)
	for k in 5:
		var rank := (k + 1) / 2
		var offset := -dir * rank * 12.0 + side * rank * 10.0 * (1 if k % 2 == 0 else -1)
		var start := (lead + offset).clamp(area.position + Vector2(6, 6), area.end - Vector2(6, 6))
		var bird := _glyph(enemy, parent, area, start, "bird", 8.0)
		bird.delay = 0.3
		bird.velocity = dir * 170.0
		bird.face_motion = true
	return 1.0


## CRUMBS: someone dropped fries. Crumbs rain down, and the gang follows them.
static func _pigeon_crumbs(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3)
	var crumb := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "fry", 6.0)
	crumb.velocity = Vector2(0, 120)
	if step % 3 == 0:
		var bird := _glyph(enemy, parent, area, Vector2(x + (30 if step % 2 == 0 else -30), area.position.y + 4), "bird", 8.0)
		bird.delay = 0.2
		bird.velocity = Vector2(0, 150)
		bird.sway = 30.0
	return 0.3


# --- Parking Meter -----------------------------------------------------------------------

## COINS: quarters pop out of the slot and arc over, bouncing off the walls.
static func _meter_coins(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for k in 3:
		var coin := _glyph(enemy, parent, area, Vector2(area.get_center().x, area.position.y + 6), "coin", 7.0)
		coin.delay = 0.25 + k * 0.1
		coin.velocity = Vector2((k - 1) * 90.0 + randf_range(-20, 20), 130)
		coin.wall_bounce = true
		coin.lifetime = 2.4
	return 0.9


## EXPIRED: the red flag drops. Warning stripes light up a row, then a column.
static func _meter_expired(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var dir := Vector2.RIGHT if step % 2 == 0 else Vector2.DOWN
	Attacks._beam(enemy, parent, area, soul, dir, 0.55, Color(1.0, 0.3, 0.3))
	return 0.75


# --- Neon Sign ---------------------------------------------------------------------------

## FLICKER: tubes of light flash on across the box: two at a time, never where
## the gap is.
static func _neon_flicker(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var colors := [Color(1.0, 0.35, 0.7), Color(0.4, 0.9, 1.0), Color(1.0, 0.85, 0.3)]
	var c: Color = colors[step % 3]
	var at := Vector2(soul.x + (18.0 if step % 2 == 0 else -18.0), soul.y)
	Attacks._beam(enemy, parent, area, at, Vector2.DOWN, 0.5, c)
	Attacks._beam(enemy, parent, area, Vector2(soul.x, clampf(soul.y + (24.0 if step % 2 == 0 else -24.0), area.position.y + 6, area.end.y - 6)), Vector2.RIGHT, 0.65, c)
	return 0.9


## BUZZ: sparks crackle out of a loose wire in rings.
static func _neon_buzz(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var at := Vector2(randf_range(area.position.x + 14, area.end.x - 14), randf_range(area.position.y + 14, area.end.y - 14))
	if at.distance_to(soul) < 30.0:
		at = soul + (at - soul).normalized() * 30.0
	for k in 6:
		var spark := _glyph(enemy, parent, area, at, "spark", 6.0)
		spark.delay = 0.4
		spark.velocity = Vector2.from_angle(k * TAU / 6.0 + step * 0.3) * 120.0
	return 0.6
