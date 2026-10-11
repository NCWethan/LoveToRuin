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
