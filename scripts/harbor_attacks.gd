class_name HarborAttacks
extends RefCounted
## The Harbor (fragment 8): the people on the pier, Flight Deck (an old jet on the
## carrier), and Agent (on the Genocide path). Works like Attacks.spawn(): adds
## bullets, and returns how many seconds until it's called again (or -1 for a
## pattern it doesn't know).

const JET := Color(0.85, 0.88, 0.95)
const FLAME := Color(1.0, 0.55, 0.2)
const RUNWAY := Color(1.0, 0.95, 0.5)
const AGENT := Color(0.35, 0.95, 0.85)

## What each of Flight Deck's attacks is called, and what Agent says about it
## (he calls the dodges; see BattleData.announcer).
const LABELS := {
	"jet_wash": "JET WASH", "afterburner": "AFTERBURNER", "catapult": "CATAPULT LAUNCH",
	"barrel_roll": "BARREL ROLL", "flare_drop": "FLARES", "landing_lights": "LANDING APPROACH",
	"prediction": "PREDICTION", "counter_move": "COUNTER", "rock_paper_scissors": "ROCK PAPER SCISSORS",
	"dart_volley": "DART VOLLEY", "bullseye_rings": "BULLSEYE", "checkmate": "CHECKMATE",
	"zugzwang": "ZUGZWANG", "the_variable": "THE VARIABLE",
}
const HINTS := {
	"jet_wash": "Wind from the side. Hold your row, slip the gaps.",
	"afterburner": "Fire down one row. Then the next. Move vertically.",
	"catapult": "Catapult, down your row. You get one beat. Move.",
	"barrel_roll": "It rolls. A spiral. Circle WITH it, not against it.",
	"flare_drop": "Flares, dropping. They drift. Stay between them.",
	"landing_lights": "It's landing. Stay mid-runway. THEN guide it in.",
}


static func spawn(pattern: String, enemy: Enemy, parent: Node, area: Rect2, s: Vector2, step: int) -> float:
	match pattern:
		# --- On the pier ---
		"anchor_drop": return _anchor_drop(enemy, parent, area, s, step)
		"rope_knots": return _rope_knots(enemy, parent, area, s, step)
		"flash_photo": return _flash_photo(enemy, parent, area, s, step)
		"souvenir_spoons": return _souvenir_spoons(enemy, parent, area, s, step)
		"fish_toss": return _fish_toss(enemy, parent, area, s, step)
		"beak_scoop": return _beak_scoop(enemy, parent, area, s, step)
		# --- Flight Deck ---
		"jet_wash": return _jet_wash(enemy, parent, area, s, step)
		"afterburner": return _afterburner(enemy, parent, area, s, step)
		"catapult": return _catapult(enemy, parent, area, s, step)
		"barrel_roll": return _barrel_roll(enemy, parent, area, s, step)
		"flare_drop": return _flare_drop(enemy, parent, area, s, step)
		"landing_lights": return _landing_lights(enemy, parent, area, s, step)
		# --- Agent (Genocide) ---
		"prediction": return _prediction(enemy, parent, area, s, step)
		"counter_move": return _counter_move(enemy, parent, area, s, step)
		"rock_paper_scissors": return _rock_paper_scissors(enemy, parent, area, s, step)
		"dart_volley": return _dart_volley(enemy, parent, area, s, step)
		"bullseye_rings": return _bullseye_rings(enemy, parent, area, s, step)
		"checkmate": return _checkmate(enemy, parent, area, s, step)
		"zugzwang": return _zugzwang(enemy, parent, area, s, step)
		"the_variable": return _the_variable(enemy, parent, area, s, step)
	return -1.0


static func _glyph(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, glyph: String, size: float = 8.0) -> Bullet:
	return FolkAttacks._glyph(enemy, parent, area, at, glyph, size)


static func _dot(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, color: Color, size: float = 6.0) -> Bullet:
	var b := Attacks._bullet(enemy, parent, area, at)
	b.size = size
	b.color = color
	return b


## How the SOUL has been moving (pixels per second), from the last few spots the
## battle recorded. Agent reads it.
static func _soul_velocity(parent: Node) -> Vector2:
	var path: Array = parent.get("_soul_path") if parent.get("_soul_path") != null else []
	if path.size() < 3:
		return Vector2.ZERO
	return ((path[path.size() - 1] as Vector2) - (path[path.size() - 3] as Vector2)) / 0.2


## Where the SOUL will be in `ahead` seconds, if it keeps going (inside the box).
static func _predict(parent: Node, area: Rect2, soul: Vector2, ahead: float) -> Vector2:
	return (soul + _soul_velocity(parent) * ahead).clamp(area.position + Vector2(6, 6), area.end - Vector2(6, 6))


# --- On the pier --------------------------------------------------------------------------

## The Old Sailor: ANCHOR. Drops straight down where you are, hits the bottom, and
## the chain whips side to side.
static func _anchor_drop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var anchor := _glyph(enemy, parent, area, Vector2(x, area.position.y + 6), "anchor", 12.0)
	anchor.delay = 0.35
	anchor.velocity = Vector2(0, 60)
	anchor.acceleration = Vector2(0, 360)
	anchor.splits_into = 5
	anchor.split_color = Color(0.6, 0.6, 0.65)
	return 0.9


## The Old Sailor: KNOTS. A rope snakes across the box, tying itself in loops.
static func _rope_knots(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var y := Attacks._aim_y(area, soul, step, 2)
	var left := step % 2 == 0
	for i in 6:
		var knot := _dot(enemy, parent, area, Vector2(area.position.x + 4 if left else area.end.x - 4, y), Color(0.8, 0.65, 0.4), 6.0)
		knot.delay = 0.2 + i * 0.08
		knot.velocity = Vector2(110 if left else -110, 0)
		knot.zigzag = 3.0
	return 0.9


## The Tourist: FLASH PHOTO. The flash goes off where you are (after the beep),
## and leaves spots in your eyes that drift.
static func _flash_photo(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var at := soul.clamp(area.position + Vector2(12, 12), area.end - Vector2(12, 12))
	var flash := _dot(enemy, parent, area, at, Color(1, 1, 1), 22.0)
	flash.delay = 0.6
	flash.lifetime = 0.15
	for i in 4:
		var spot := _dot(enemy, parent, area, at, Color(0.6, 0.8, 1.0), 5.0)
		spot.delay = 0.75
		spot.velocity = Vector2.from_angle(i * TAU / 4 + 0.6) * 50.0
	return 1.0


## The Tourist: SOUVENIR SPOONS. Commemorative. Thrown.
static func _souvenir_spoons(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(randf_range(area.position.x + 8, area.end.x - 8), area.position.y + 4)
	var spoon := _glyph(enemy, parent, area, from, "spoon", 8.0)
	spoon.velocity = (soul - from).normalized() * 120.0
	spoon.spin = 9.0
	return 0.4


## The Pelican: FISH, tossed up and caught (mostly not caught).
static func _fish_toss(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := randf_range(area.position.x + 10, area.end.x - 10)
	var fish := _glyph(enemy, parent, area, Vector2(x, area.end.y - 6), "fish", 8.0)
	var target := Attacks._aim_x(area, soul, step, 2)
	var up := sqrt(640.0 * maxf((area.end.y - 6) - soul.y, 14.0)) if step % 2 == 0 else randf_range(220, 260)
	fish.velocity = Vector2((target - x) / (up / 320.0), -up)
	fish.acceleration = Vector2(0, 320)
	fish.spin = 8.0
	# And every third one, he just drops it. Right on you.
	if step % 3 == 2:
		var dropped := _glyph(enemy, parent, area, Vector2(clampf(soul.x, area.position.x + 6, area.end.x - 6), area.position.y + 4), "fish", 8.0)
		dropped.delay = 0.3
		dropped.velocity = Vector2(0, 130)
	return 0.5


## The Pelican: BEAK SCOOP. The beak sweeps along the bottom of the box, then the top.
static func _beak_scoop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var low := step % 2 == 0
	var y := area.end.y - 10 if low else area.position.y + 10
	if absf(soul.y - y) > 30.0 and step % 3 == 0:
		y = soul.y
	var left := step % 4 < 2
	var beak := Attacks._beam(enemy, parent, area, Vector2(area.get_center().x, y), Vector2.RIGHT, 0.55, Color(1.0, 0.65, 0.25))
	beak.size = 14.0
	return 0.9 if left else 0.95


# --- Flight Deck ----------------------------------------------------------------------------

## JET WASH: hot air blasts across the box from one side, in streaks with gaps.
static func _jet_wash(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := (step / 6) % 2 == 0
	var y := randf_range(area.position.y + 6, area.end.y - 6)
	if step % 3 == 0:
		y = clampf(soul.y, area.position.y + 6, area.end.y - 6)
	var streak := Attacks._bullet(enemy, parent, area, Vector2(area.position.x + 4 if left else area.end.x - 4, y))
	streak.shape = "arrow"
	streak.size = 9.0
	streak.color = Color(0.85, 0.9, 1.0, 0.9)
	streak.velocity = Vector2(230 if left else -230, randf_range(-15, 15))
	streak.trail_length = 6
	return 0.12


## AFTERBURNER: a column of flame sweeps down the box, row by row, toward you.
static func _afterburner(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var rows := 5
	var row := step % rows
	var down := (step / rows) % 2 == 0
	var y := area.position.y + (row + 0.5) * area.size.y / rows if down else area.end.y - (row + 0.5) * area.size.y / rows
	Attacks._beam(enemy, parent, area, Vector2(area.get_center().x, y), Vector2.RIGHT, 0.45, FLAME)
	return 0.42


## CATAPULT LAUNCH: the catapult fires a shuttle down your row, very fast, after
## one beat of steam.
static func _catapult(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var y := clampf(soul.y, area.position.y + 8, area.end.y - 8)
	var left := step % 2 == 0
	for k in 2:
		var shuttle := Attacks._bullet(enemy, parent, area, Vector2(area.position.x + 6 if left else area.end.x - 6, y + (k * 12 - 6)))
		shuttle.shape = "lance"
		shuttle.size = 11.0
		shuttle.color = JET
		shuttle.delay = 0.55
		shuttle.velocity = Vector2(330 if left else -330, 0)
		shuttle.trail_length = 8
	var steam := _dot(enemy, parent, area, Vector2(area.position.x + 8 if left else area.end.x - 8, y), Color(1, 1, 1, 0.5), 6.0)
	steam.velocity = Vector2(0, -40)
	steam.lifetime = 0.5
	return 0.75


## BARREL ROLL: shots spiral out of the middle of the box as it rolls.
static func _barrel_roll(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var center := area.get_center()
	for arm in 3:
		var angle := step * 0.38 + arm * TAU / 3.0
		var shot := _dot(enemy, parent, area, center, JET, 6.0)
		shot.velocity = Vector2.from_angle(angle) * 95.0
		shot.trail_length = 3
	return 0.13


## FLARES: glowing flares drop from the top and drift, sputtering sparks.
static func _flare_drop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var flare := _dot(enemy, parent, area, Vector2(x, area.position.y + 4), FLAME, 8.0)
	flare.velocity = Vector2(0, 45)
	flare.sway = 25.0
	flare.glow = true
	flare.trail_length = 5
	if step % 2 == 0:
		for i in 3:
			var spark := _dot(enemy, parent, area, Vector2(x, area.position.y + 4), Color(1.0, 0.85, 0.4), 4.0)
			spark.delay = 0.6
			spark.velocity = Vector2.from_angle(PI / 2 + (i - 1) * 0.6) * 90.0
	return 0.45


## LANDING APPROACH: it tries to land. Two lines of runway lights come in along
## the sides, closing toward the middle, then opening again. Stay on the centerline.
## (This is the turn to guide it in.)
static func _landing_lights(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var narrow := 0.5 + 0.35 * sin(step * 0.5)
	for side in [-1.0, 1.0]:
		var x: float = area.get_center().x + side * area.size.x * 0.5 * narrow
		var light := _dot(enemy, parent, area, Vector2(x, area.position.y + 4), RUNWAY, 6.0)
		light.velocity = Vector2(0, 110)
		light.glow = true
	# Now and then a light down the centerline (stay a little off it).
	if step % 5 == 4:
		var center := _dot(enemy, parent, area, Vector2(area.get_center().x, area.position.y + 4), Color(1.0, 0.4, 0.4), 5.0)
		center.velocity = Vector2(0, 110)
	return 0.16


# --- Agent (Genocide) -------------------------------------------------------------------
# The hardest fight in the game. He predicts where you're going, the way he read your
# throws at Rock Paper Scissors, and he's usually right.

## PREDICTION: darts thrown where you're going to be, not where you are. Keep
## changing direction.
static func _prediction(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var target := _predict(parent, area, soul, 0.55)
	var spots := [Vector2(area.position.x + 4, area.position.y + 4), Vector2(area.end.x - 4, area.position.y + 4), Vector2(area.position.x + 4, area.end.y - 4), Vector2(area.end.x - 4, area.end.y - 4)]
	var from: Vector2 = spots[step % 4]
	var dart := _glyph(enemy, parent, area, from, "dart", 8.0)
	dart.velocity = (target - from).normalized() * 190.0
	dart.face_motion = true
	dart.trail_length = 4
	return 0.3


## COUNTER: a slash lands where you're heading. If you're standing still, it lands
## on you.
static func _counter_move(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var target := _predict(parent, area, soul, 0.6)
	var vel := _soul_velocity(parent)
	var dir := vel.normalized().orthogonal() if vel.length() > 10.0 else (Vector2.RIGHT if step % 2 == 0 else Vector2.DOWN)
	Attacks._beam(enemy, parent, area, target, dir, 0.5, AGENT)
	return 0.75


## ROCK PAPER SCISSORS: he counts your moves and throws the counter. ROCK (a big
## stone falls where you go most), PAPER (a sheet sweeps the side you favor),
## SCISSORS (an X closes on you).
static func _rock_paper_scissors(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	match step % 3:
		0:
			var x := _predict(parent, area, soul, 0.8).x
			var rock := Attacks._bullet(enemy, parent, area, Vector2(x, area.position.y + 6))
			rock.shape = "ball"
			rock.size = 22.0
			rock.color = Color(0.6, 0.58, 0.55)
			rock.delay = 0.45
			rock.velocity = Vector2(0, 80)
			rock.acceleration = Vector2(0, 260)
			rock.splits_into = 6
			rock.split_color = Color(0.6, 0.58, 0.55)
		1:
			var right := soul.x > area.get_center().x
			var y := area.position.y + 6
			while y < area.end.y - 2:
				var sheet := _dot(enemy, parent, area, Vector2(area.end.x - 4 if right else area.position.x + 4, y), Color(0.95, 0.95, 0.9), 8.0)
				sheet.delay = 0.45
				sheet.velocity = Vector2(-95 if right else 95, 0)
				sheet.stop_after = area.size.x * 0.5 / 95.0
				sheet.lifetime = 1.4
				y += 10
		_:
			var at := _predict(parent, area, soul, 0.5)
			Attacks._beam(enemy, parent, area, at, Vector2(1, 1), 0.55, AGENT)
			Attacks._beam(enemy, parent, area, at, Vector2(1, -1), 0.55, AGENT)
	return 1.0


## DART VOLLEY: five darts in a fan, aimed at where you'll be, from the side you're
## farthest from.
static func _dart_volley(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := soul.x > area.get_center().x
	var from := Vector2(area.position.x + 4 if left else area.end.x - 4, randf_range(area.position.y + 10, area.end.y - 10))
	var aim := (_predict(parent, area, soul, 0.4) - from).angle()
	for i in 5:
		var dart := _glyph(enemy, parent, area, from, "dart", 7.0)
		dart.delay = 0.3
		dart.velocity = Vector2.from_angle(aim + (i - 2) * 0.16) * 170.0
		dart.face_motion = true
	return 0.8


## BULLSEYE: target rings pulse out from where you're going. Every ring has one gap.
static func _bullseye_rings(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	# Every other one closes IN on where you're going; the rest pulse out from
	# beside it.
	var at := _predict(parent, area, soul, 0.3)
	var inward := step % 2 == 0
	var ring := Attacks._bullet(enemy, parent, area, at if inward else (at + Vector2.from_angle(randf() * TAU) * 46.0).clamp(area.position + Vector2(4, 4), area.end - Vector2(4, 4)))
	ring.shape = "ring"
	ring.size = 4.0
	ring.color = Color(1.0, 0.35, 0.3) if inward else Color(1, 1, 1)
	ring.delay = 0.3
	ring.radius = 70.0 if inward else 4.0
	ring.ring_speed = -65.0 if inward else 80.0
	ring.gap_angle = randf() * TAU
	ring.gap_width = 0.7
	ring.lifetime = 1.6
	return 0.6


## CHECKMATE: walls of pieces close in from all four sides, and the way out is
## where he expects you to go... so it isn't. (The gap is on the other side.)
static func _checkmate(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var vel := _soul_velocity(parent)
	var away := -vel.normalized() if vel.length() > 10.0 else Vector2.UP
	for side in 4:
		var normal: Vector2 = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT][side]
		if normal.dot(-away) > 0.7:
			continue
		var count := 7
		for i in count:
			var t := (i + 0.5) / count
			var at: Vector2
			match side:
				0: at = Vector2(lerpf(area.position.x, area.end.x, t), area.position.y + 4)
				1: at = Vector2(lerpf(area.position.x, area.end.x, t), area.end.y - 4)
				2: at = Vector2(area.position.x + 4, lerpf(area.position.y, area.end.y, t))
				_: at = Vector2(area.end.x - 4, lerpf(area.position.y, area.end.y, t))
			var piece := _dot(enemy, parent, area, at, Color(0.2, 0.2, 0.24) if i % 2 == 0 else Color(0.9, 0.9, 0.92), 8.0)
			piece.delay = 0.4
			piece.velocity = normal * 45.0
			piece.stop_after = 1.0
			piece.lifetime = 2.0
	return 1.8


## ZUGZWANG: whatever you do makes it worse. Bullets hang still around you, and
## start moving the moment you do, toward wherever you went.
static func _zugzwang(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for i in 6:
		var spot := (soul + Vector2.from_angle(i * TAU / 6 + step) * 40.0).clamp(area.position + Vector2(4, 4), area.end - Vector2(4, 4))
		var piece := _dot(enemy, parent, area, spot, AGENT, 6.0)
		piece.delay = 0.5
		piece.homing = Attacks._soul(parent)
		piece.homing_time = 0.8
		piece.turn_rate = 2.2
		piece.velocity = (soul - spot).normalized() * 60.0
		piece.trail_length = 3
	return 1.2


## (Nearly beaten.) THE VARIABLE: the one thing he didn't count. Nothing he throws
## follows a rule any more: random, fast, everywhere. He's panicking.
static func _the_variable(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var edge := randi() % 4
	var at: Vector2
	match edge:
		0: at = Vector2(randf_range(area.position.x, area.end.x), area.position.y + 4)
		1: at = Vector2(randf_range(area.position.x, area.end.x), area.end.y - 4)
		2: at = Vector2(area.position.x + 4, randf_range(area.position.y, area.end.y))
		_: at = Vector2(area.end.x - 4, randf_range(area.position.y, area.end.y))
	var aim := (soul - at).angle() + randf_range(-0.5, 0.5)
	var shot := _glyph(enemy, parent, area, at, "dart", 7.0)
	shot.velocity = Vector2.from_angle(aim) * randf_range(110, 210)
	shot.face_motion = true
	return 0.14
