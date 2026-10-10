class_name TorreyAttacks
extends RefCounted
## Torrey Pines (fragment 9): the people on the cliffs, the Glider (which won't
## come down), and Rooster (on the Genocide path). Works like Attacks.spawn():
## adds bullets, and returns how many seconds until it's called again (or -1 for a
## pattern it doesn't know).

const WIND := Color(0.8, 0.92, 1.0)
const WING := Color(1.0, 0.4, 0.3)
const SUIT_WHITE := Color(0.95, 0.95, 0.97)
const SUIT_BLACK := Color(0.12, 0.12, 0.15)
const ROAST := Color(1.0, 0.55, 0.2)


static func spawn(pattern: String, enemy: Enemy, parent: Node, area: Rect2, s: Vector2, step: int) -> float:
	match pattern:
		# --- On the cliffs ---
		"rule_signs": return _rule_signs(enemy, parent, area, s, step)
		"slow_and_steady": return _slow_and_steady(enemy, parent, area, s, step)
		"rockslide": return _rockslide(enemy, parent, area, s, step)
		"trail_mix_toss": return _trail_mix_toss(enemy, parent, area, s, step)
		"binocular_scan": return _binocular_scan(enemy, parent, area, s, step)
		"field_guide": return _field_guide(enemy, parent, area, s, step)
		# --- The Glider ---
		"updraft": return _updraft(enemy, parent, area, s, step)
		"thermal": return _thermal(enemy, parent, area, s, step)
		"crosswind": return _crosswind(enemy, parent, area, s, step)
		"gull_escort": return _gull_escort(enemy, parent, area, s, step)
		"dive": return _dive(enemy, parent, area, s, step)
		"pinecones": return _pinecones(enemy, parent, area, s, step)
		"the_ground": return _the_ground(enemy, parent, area, s, step)
		# --- Rooster (Genocide) ---
		"roast": return _roast(enemy, parent, area, s, step)
		"top_hat_trick": return _top_hat_trick(enemy, parent, area, s, step)
		"mic_drop": return _mic_drop(enemy, parent, area, s, step)
		"split_suit": return _split_suit(enemy, parent, area, s, step)
		"heckle": return _heckle(enemy, parent, area, s, step)
		"callback": return _callback(enemy, parent, area, s, step)
		"tongue_out": return _tongue_out(enemy, parent, area, s, step)
		"not_a_joke": return _not_a_joke(enemy, parent, area, s, step)
	return -1.0


static func _glyph(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, glyph: String, size: float = 8.0) -> Bullet:
	return FolkAttacks._glyph(enemy, parent, area, at, glyph, size)


static func _dot(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, color: Color, size: float = 6.0) -> Bullet:
	var b := Attacks._bullet(enemy, parent, area, at)
	b.size = size
	b.color = color
	return b


# --- On the cliffs ----------------------------------------------------------------------

## The Park Ranger: RULE SIGNS. NO RUNNING. NO JUMPING. NO GLIDING. They come in
## from the sides, and stop where they're planted.
static func _rule_signs(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var y := Attacks._aim_y(area, soul, step, 2)
	var sign := _glyph(enemy, parent, area, Vector2(area.position.x + 4 if left else area.end.x - 4, y), "wet_sign", 10.0)
	sign.delay = 0.25
	sign.velocity = Vector2(140 if left else -140, 0)
	sign.stop_after = randf_range(0.35, 0.9)
	sign.lifetime = 2.2
	return 0.55


## The Park Ranger: SLOW AND STEADY. A wall of shells crawls up from the bottom,
## very slowly, with one gap. It gets there.
static func _slow_and_steady(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var gap := Attacks._away_from(randf_range(area.position.x + 16, area.end.x - 16), soul.x, area.position.x + 16, area.end.x - 16)
	var x := area.position.x + 6
	while x < area.end.x - 2:
		if absf(x - gap) > 14:
			var shell := _dot(enemy, parent, area, Vector2(x, area.end.y - 4), Color(0.45, 0.6, 0.35), 9.0)
			shell.velocity = Vector2(0, -38)
		x += 12
	return 1.6


## The Hiker: ROCKSLIDE. Rocks bounce down the slope, from the top corner.
static func _rockslide(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := (step / 4) % 2 == 0
	var rock := Attacks._bullet(enemy, parent, area, Vector2(area.position.x + 6 if left else area.end.x - 6, area.position.y + 6))
	rock.shape = "ball"
	rock.size = randf_range(8, 13)
	rock.color = Color(0.6, 0.5, 0.4)
	rock.velocity = Vector2((90 if left else -90) * randf_range(0.6, 1.4), 20)
	rock.acceleration = Vector2(0, 300)
	rock.bounce_speed = 150
	rock.bounce_variance = 0.3
	rock.wall_bounce = true
	rock.lifetime = 3.0
	return 0.4


## The Hiker: TRAIL MIX. A handful of it, thrown up and raining down. (Somebody
## gave you trail mix once. It's the same brand.)
static func _trail_mix_toss(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	for i in 5:
		var nut := _glyph(enemy, parent, area, Vector2(x + (i - 2) * 9, area.position.y + 4), "peanut" if i % 2 == 0 else "acorn", 6.0)
		nut.delay = 0.2 + i * 0.05
		nut.velocity = Vector2((i - 2) * 12, 50)
		nut.acceleration = Vector2(0, 140)
	return 0.75


## The Birdwatcher: BINOCULARS. Two lenses sweep the box; where they focus, it
## gets hot.
static func _binocular_scan(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for side in [-1.0, 1.0]:
		var ring := Attacks._bullet(enemy, parent, area, (soul + Vector2(side * 14.0, 0)).clamp(area.position + Vector2(8, 8), area.end - Vector2(8, 8)))
		ring.shape = "ring"
		ring.size = 3.0
		ring.color = Color(0.7, 0.85, 1.0)
		ring.delay = 0.35
		ring.radius = 40.0
		ring.ring_speed = -55.0
		ring.lifetime = 0.75
	return 1.0


## The Birdwatcher: THE FIELD GUIDE. Every bird in it, flying out of the pages.
static func _field_guide(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(area.end.x - 6 if step % 2 == 0 else area.position.x + 6, Attacks._aim_y(area, soul, step, 3))
	var bird := _glyph(enemy, parent, area, from, "bird", 8.0)
	bird.velocity = Vector2(-120 if step % 2 == 0 else 120, 0)
	bird.zigzag = 2.0
	return 0.35


# --- The Glider ------------------------------------------------------------------------
# Out in the open sky. The box drifts on the wind (BattleData.box_drift) while it
# attacks.

## UPDRAFT: wind pushes up from the cliff below, carrying grit with it.
static func _updraft(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3)
	var gust := _dot(enemy, parent, area, Vector2(x, area.end.y - 4), WIND, 5.0)
	gust.velocity = Vector2(0, -130)
	gust.sway = 30.0
	gust.trail_length = 4
	return 0.15


## THERMAL: a spiral of warm air, turning, rising out of the middle of the box.
static func _thermal(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var center := Vector2(area.get_center().x + sin(step * 0.3) * 30.0, area.end.y - 6)
	for arm in 2:
		var angle := -PI / 2 + sin(step * 0.45 + arm * PI) * 0.9
		var puff := _dot(enemy, parent, area, center, Color(1.0, 0.85, 0.6), 6.0)
		puff.velocity = Vector2.from_angle(angle) * 100.0
	# Now and then a gust breaks off the column, right at you.
	if step % 5 == 4:
		var gust := _dot(enemy, parent, area, center, Color(1.0, 0.85, 0.6), 7.0)
		gust.velocity = (soul - center).normalized() * 120.0
	return 0.12


## CROSSWIND: streaks of wind straight across the box, in rows, with a gap. It
## changes sides.
static func _crosswind(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var gap := Attacks._away_from(randf_range(area.position.y + 14, area.end.y - 14), soul.y, area.position.y + 14, area.end.y - 14)
	var y := area.position.y + 6
	while y < area.end.y - 2:
		if absf(y - gap) > 13:
			var streak := Attacks._bullet(enemy, parent, area, Vector2(area.position.x + 4 if left else area.end.x - 4, y))
			streak.shape = "arrow"
			streak.size = 8.0
			streak.color = WIND
			streak.delay = 0.3
			streak.velocity = Vector2(150 if left else -150, 0)
			streak.trail_length = 5
		y += 11
	return 1.1


## GULL ESCORT: seagulls fly in a V, right through where you are.
static func _gull_escort(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var lead_y := clampf(soul.y, area.position.y + 6, area.end.y - 6)
	for i in 5:
		var offset := Vector2(-absi(i - 2) * 14.0, (i - 2) * 11.0)
		var at := Vector2(area.position.x + 4 if left else area.end.x - 4, lead_y) + (offset if left else Vector2(-offset.x, offset.y))
		at.y = clampf(at.y, area.position.y + 4, area.end.y - 4)
		var gull := _glyph(enemy, parent, area, at, "bird", 8.0)
		gull.delay = 0.3
		gull.velocity = Vector2(115 if left else -115, 0)
	return 1.0


## DIVE: the Glider's shadow sweeps the box on a diagonal, then the Glider itself.
static func _dive(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var dir := Vector2(1, 0.6 if step % 2 == 0 else -0.6).normalized()
	Attacks._beam(enemy, parent, area, soul, dir, 0.6, Color(0.25, 0.25, 0.35))
	Attacks._beam(enemy, parent, area, soul + Vector2(0, 22), dir, 0.95, WING)
	return 1.25


## PINECONES: torrey pine cones, knocked loose by the wind, tumbling down.
static func _pinecones(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3)
	var cone := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "pinecone", 8.0)
	cone.velocity = Vector2(randf_range(-30, 30), 40)
	cone.acceleration = Vector2(0, 240)
	cone.bounce_speed = 110
	cone.spin = 5.0
	cone.lifetime = 2.5
	return 0.3


## (Low on wind.) THE GROUND: it's coming down, and it's terrified. The ground
## rises from the bottom of the box in a jagged line, with one landing strip.
static func _the_ground(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var strip := Attacks._away_from(randf_range(area.position.x + 20, area.end.x - 20), soul.x, area.position.x + 20, area.end.x - 20)
	if step % 3 == 2:
		strip = clampf(soul.x, area.position.x + 20, area.end.x - 20)
	var x := area.position.x + 5
	while x < area.end.x - 2:
		if absf(x - strip) > 16:
			var rock := _dot(enemy, parent, area, Vector2(x, area.end.y - 4), Color(0.55, 0.45, 0.35), 9.0)
			rock.delay = 0.3
			rock.velocity = Vector2(0, -70 - absf(sin(x * 0.2)) * 30.0)
			rock.stop_after = 1.2
			rock.lifetime = 1.8
		x += 10
	return 1.4


# --- Rooster (Genocide) -----------------------------------------------------------------
# He roasts you through the whole fight. The jokes fall apart as he gets scared.

## THE ROAST: a burn. Literally. Fire letters, "OHHHH", rolling across.
static func _roast(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var y := Attacks._aim_y(area, soul, step, 2)
	for i in 4:
		var flame := Attacks._bullet(enemy, parent, area, Vector2(area.position.x + 4 if left else area.end.x - 4, y + sin(i * 1.3) * 10.0))
		flame.shape = "star"
		flame.size = 8.0
		flame.color = ROAST
		flame.delay = 0.2 + i * 0.1
		flame.velocity = Vector2(140 if left else -140, 0)
		flame.glow = true
		flame.trail_length = 4
	return 0.85


## TOP HAT TRICK: he throws his hat. It comes back. It brings friends.
static func _top_hat_trick(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(area.end.x - 6, area.position.y + 10)
	for i in 3:
		var hat := _glyph(enemy, parent, area, from + Vector2(0, i * 20), "tophat", 10.0)
		hat.delay = 0.25 + i * 0.15
		# It flies out to exactly where you are, turns around, and comes back.
		var reach := maxf(from.distance_to(soul) + 12.0, 30.0)
		hat.velocity = (soul - from).normalized() * 170.0
		hat.acceleration = -(soul - from).normalized() * (170.0 * 170.0 / (2.0 * reach))
		hat.spin = 8.0
		hat.lifetime = 2.2
	return 1.2


## MIC DROP: a microphone falls where you are. When it hits the floor, the sound
## goes everywhere.
static func _mic_drop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := clampf(soul.x, area.position.x + 8, area.end.x - 8)
	var mic := _glyph(enemy, parent, area, Vector2(x, area.position.y + 6), "mic", 10.0)
	mic.delay = 0.35
	mic.velocity = Vector2(0, 40)
	mic.acceleration = Vector2(0, 420)
	mic.splits_into = 8
	mic.split_color = Color(1.0, 0.9, 0.5)
	return 0.95


## SPLIT DOWN THE MIDDLE: like his suit. The left half of the box, then the right,
## flashes and fills. Stay on the side that isn't.
static func _split_suit(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := (step % 2 == 0) == (soul.x < area.get_center().x)
	var half := Rect2(area.position if left else Vector2(area.get_center().x, area.position.y), Vector2(area.size.x / 2, area.size.y))
	var cols := 4
	var rows := 5
	for c in cols:
		for r in rows:
			var at := half.position + Vector2((c + 0.5) * half.size.x / cols, (r + 0.5) * half.size.y / rows)
			var block := _dot(enemy, parent, area, at, SUIT_WHITE if left else SUIT_BLACK.lightened(0.25), half.size.x / cols - 4)
			block.delay = 0.6
			block.lifetime = 0.35
	return 1.1


## HECKLE: "BOO." Rows of it, rolling in from both sides.
static func _heckle(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for i in 2:
		var left := i == 0
		var y := Attacks._aim_y(area, soul, step * 2 + i, 3)
		var boo := _glyph(enemy, parent, area, Vector2(area.position.x + 4 if left else area.end.x - 4, y), "text", 8.0)
		boo.velocity = Vector2(110 if left else -110, 0)
		boo.zigzag = 1.5
	return 0.42


## CALLBACK: a joke from earlier, again. Flames come back along the path you took
## last turn. (Comedy is about timing.)
static func _callback(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var path: Array = parent.get("_last_soul_path") if parent.get("_last_soul_path") != null else []
	var at := soul
	if not path.is_empty():
		at = path[mini(step * 3, path.size() - 1)]
	var flame := _dot(enemy, parent, area, at.clamp(area.position + Vector2(5, 5), area.end - Vector2(5, 5)), ROAST, 10.0)
	flame.delay = 0.35
	flame.lifetime = 0.6
	flame.glow = true
	return 0.3


## TONGUE OUT: his goofy face, huge, and a wavy pink line across the box.
static func _tongue_out(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var y := clampf(soul.y, area.position.y + 8, area.end.y - 8)
	for i in 9:
		var bit := _dot(enemy, parent, area, Vector2(area.end.x - 4, y), Color(1.0, 0.55, 0.65), 9.0)
		bit.delay = 0.35 + i * 0.04
		bit.velocity = Vector2(-150, 0)
		bit.zigzag = 4.0
	return 1.0


## (Scared now. The jokes are gone.) NOT A JOKE: just his top hat, falling, over and
## over, and the sound of him breathing. Slow, and everywhere.
static func _not_a_joke(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var hat := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "tophat", 9.0)
	hat.velocity = Vector2(0, 60)
	hat.sway = 20.0
	if step % 4 == 3:
		var ring := Attacks._bullet(enemy, parent, area, soul)
		ring.shape = "ring"
		ring.size = 3.0
		ring.color = Color(0.9, 0.9, 0.95)
		ring.delay = 0.3
		ring.radius = 60.0
		ring.ring_speed = -55.0
		ring.gap_angle = randf() * TAU
		ring.gap_width = 0.6
		ring.lifetime = 1.1
	return 0.3
