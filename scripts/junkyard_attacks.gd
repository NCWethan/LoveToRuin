class_name JunkyardAttacks
extends RefCounted
## The junkyard by the freeway: the Junk Dealer, Scrap Heap (a crane with a car
## crusher for a body), and Sansworth (on the Genocide path). Works like
## Attacks.spawn(): adds bullets, and returns how many seconds until it's called
## again (or -1 for a pattern it doesn't know).

const RUST := Color(0.75, 0.45, 0.3)
const STEEL := Color(0.75, 0.77, 0.82)
const TIRE := Color(0.15, 0.15, 0.17)
const HEADLIGHT := Color(1.0, 0.95, 0.7)


static func spawn(pattern: String, enemy: Enemy, parent: Node, area: Rect2, s: Vector2, step: int) -> float:
	match pattern:
		# --- The Junk Dealer ---
		"shiny_things": return _shiny_things(enemy, parent, area, s, step)
		"dumpster_dive": return _dumpster_dive(enemy, parent, area, s, step)
		# --- Scrap Heap ---
		"car_fling": return _car_fling(enemy, parent, area, s, step)
		"crusher_press": return _crusher_press(enemy, parent, area, s, step)
		"magnet_pull": return _magnet_pull(enemy, parent, area, s, step)
		"tire_roll": return _tire_roll(enemy, parent, area, s, step)
		"hubcaps": return _hubcaps(enemy, parent, area, s, step)
		"spring_coil": return _spring_coil(enemy, parent, area, s, step)
		"compactor": return _compactor(enemy, parent, area, s, step)
		# --- Sansworth (Genocide) ---
		"honk": return _honk(enemy, parent, area, s, step)
		"key_ring": return _key_ring(enemy, parent, area, s, step)
		"rev_engine": return _rev_engine(enemy, parent, area, s, step)
		"high_beams": return _high_beams(enemy, parent, area, s, step)
		"wrong_turn": return _wrong_turn(enemy, parent, area, s, step)
		"parallel_park": return _parallel_park(enemy, parent, area, s, step)
		"traffic": return _traffic(enemy, parent, area, s, step)
		"vroom": return _vroom(enemy, parent, area, s, step)
	return -1.0


static func _glyph(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, glyph: String, size: float = 8.0) -> Bullet:
	return FolkAttacks._glyph(enemy, parent, area, at, glyph, size)


static func _dot(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, color: Color, size: float = 6.0) -> Bullet:
	var b := Attacks._bullet(enemy, parent, area, at)
	b.size = size
	b.color = color
	return b


# --- The Junk Dealer -------------------------------------------------------------------

## SHINY THINGS: bottle caps and bolts, flicked from his paw, in arcs.
static func _shiny_things(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(area.end.x - 6, area.end.y - 8)
	var target := Attacks._aim_x(area, soul, step, 2)
	var up := randf_range(200, 250)
	var cap := _glyph(enemy, parent, area, from, "coin", 6.0)
	cap.velocity = Vector2((target - from.x) / (up / 320.0), -up)
	cap.acceleration = Vector2(0, 320)
	cap.spin = 10.0
	if step % 3 == 2:
		var drop := _glyph(enemy, parent, area, Vector2(clampf(soul.x, area.position.x + 6, area.end.x - 6), area.position.y + 4), "coin", 6.0)
		drop.delay = 0.3
		drop.velocity = Vector2(0, 120)
	return 0.4


## DUMPSTER DIVE: he goes in from below, and everything comes up.
static func _dumpster_dive(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	for i in 4:
		var junk := _dot(enemy, parent, area, Vector2(x + (i - 1.5) * 10.0, area.end.y - 4), RUST, 7.0)
		junk.delay = 0.35
		junk.velocity = Vector2((i - 1.5) * 25.0, -235)
		junk.acceleration = Vector2(0, 220)
	if step % 3 == 2:
		var lid := _dot(enemy, parent, area, Vector2(clampf(soul.x, area.position.x + 6, area.end.x - 6), area.position.y + 4), RUST, 9.0)
		lid.delay = 0.3
		lid.velocity = Vector2(0, 120)
	return 0.8


# --- Scrap Heap ------------------------------------------------------------------------

## CAR FLING: the magnet swings an old car across the box and lets go.
static func _car_fling(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var from := Vector2(area.position.x + 8 if left else area.end.x - 8, area.position.y + 10)
	var car := _glyph(enemy, parent, area, from, "car", 14.0)
	car.delay = 0.35
	car.velocity = Vector2((soul.x - from.x) * 1.1, -40)
	car.acceleration = Vector2(0, 300)
	car.spin = 4.0
	car.splits_into = 6
	car.split_color = STEEL
	# And every other time, it just drops one. Right on you.
	if step % 2 == 1:
		var drop := _glyph(enemy, parent, area, Vector2(clampf(soul.x, area.position.x + 10, area.end.x - 10), area.position.y + 6), "car", 12.0)
		drop.delay = 0.5
		drop.velocity = Vector2(0, 60)
		drop.acceleration = Vector2(0, 260)
	return 1.0


## CRUSHER: the walls of the crusher close, from the top and the bottom, leaving
## one row. Then from the sides, leaving one column.
static func _crusher_press(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var vertical := step % 2 == 0
	if vertical:
		var keep := clampf(soul.y + randf_range(-20, 20), area.position.y + 14, area.end.y - 14)
		var x := area.position.x + 6
		while x < area.end.x - 2:
			for top in [true, false]:
				var plate := _dot(enemy, parent, area, Vector2(x, area.position.y + 4 if top else area.end.y - 4), STEEL, 10.0)
				plate.delay = 0.35
				var dist: float = (keep - 14.0 - area.position.y) if top else (area.end.y - keep - 14.0)
				plate.velocity = Vector2(0, 90 if top else -90)
				plate.stop_after = maxf(dist, 0.0) / 90.0
				plate.lifetime = 1.6
			x += 11
	else:
		var keep_x := clampf(soul.x + randf_range(-30, 30), area.position.x + 14, area.end.x - 14)
		var y := area.position.y + 6
		while y < area.end.y - 2:
			for left in [true, false]:
				var plate := _dot(enemy, parent, area, Vector2(area.position.x + 4 if left else area.end.x - 4, y), STEEL, 10.0)
				plate.delay = 0.35
				var dist: float = (keep_x - 14.0 - area.position.x) if left else (area.end.x - keep_x - 14.0)
				plate.velocity = Vector2(110 if left else -110, 0)
				plate.stop_after = maxf(dist, 0.0) / 110.0
				plate.lifetime = 1.6
			y += 11
	return 1.8


## MAGNET: bolts and nails get dragged toward the magnet, across the box, then
## it lets go and they fly back.
static func _magnet_pull(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var magnet := Vector2(area.get_center().x + sin(step * 0.7) * 40.0, area.position.y + 6)
	var from := Vector2(randf_range(area.position.x + 6, area.end.x - 6), area.end.y - 6)
	var bolt := _dot(enemy, parent, area, from, STEEL, 5.0)
	bolt.velocity = (magnet - from).normalized() * 40.0
	bolt.acceleration = (magnet - from).normalized() * 160.0
	bolt.trail_length = 3
	if step % 4 == 3:
		for i in 6:
			var fling := _dot(enemy, parent, area, magnet, RUST, 5.0)
			fling.delay = 0.2
			fling.velocity = Vector2.from_angle(PI / 2 + (i - 2.5) * 0.25 + (soul - magnet).angle() - PI / 2) * 130.0
	return 0.18


## TIRES: old tires roll and bounce down the pile.
static func _tire_roll(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := (step / 3) % 2 == 0
	var tire := Attacks._bullet(enemy, parent, area, Vector2(area.position.x + 8 if left else area.end.x - 8, area.position.y + 10))
	tire.shape = "ball"
	tire.size = 14.0
	tire.color = TIRE
	tire.velocity = Vector2(100 if left else -100, 0)
	tire.acceleration = Vector2(0, 340)
	tire.bounce_speed = 190
	tire.bounce_variance = 0.25
	tire.wall_bounce = true
	tire.lifetime = 3.0
	return 0.55


## HUBCAPS: spinning discs, thrown flat across the box.
static func _hubcaps(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(area.end.x - 6 if step % 2 == 0 else area.position.x + 6, Attacks._aim_y(area, soul, step, 2))
	var cap := Attacks._bullet(enemy, parent, area, from)
	cap.shape = "ball"
	cap.size = 10.0
	cap.color = STEEL
	cap.velocity = Vector2(-150 if step % 2 == 0 else 150, randf_range(-30, 30))
	cap.wall_bounce = true
	cap.lifetime = 2.2
	return 0.35


## SPRINGS: coils pop out of an old mattress and boing around the box.
static func _spring_coil(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var spring := _dot(enemy, parent, area, Vector2(x, area.end.y - 6), STEEL.darkened(0.2), 7.0)
	spring.velocity = Vector2(randf_range(-60, 60), -300)
	spring.acceleration = Vector2(0, 380)
	spring.bounce_speed = 300
	spring.wall_bounce = true
	spring.zigzag = 2.0
	spring.lifetime = 2.6
	return 0.4


## (Overheating.) THE COMPACTOR: the whole crusher closes on the box, from all four
## sides at once, with one gap that moves.
static func _compactor(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var gap_side := step % 4
	for side in 4:
		var normal: Vector2 = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT][side]
		for i in 7:
			if side == gap_side and (i == 2 or i == 3):
				continue
			var t := (i + 0.5) / 7.0
			var at: Vector2
			match side:
				0: at = Vector2(lerpf(area.position.x, area.end.x, t), area.position.y + 4)
				1: at = Vector2(lerpf(area.position.x, area.end.x, t), area.end.y - 4)
				2: at = Vector2(area.position.x + 4, lerpf(area.position.y, area.end.y, t))
				_: at = Vector2(area.end.x - 4, lerpf(area.position.y, area.end.y, t))
			var plate := _dot(enemy, parent, area, at, RUST, 9.0)
			plate.delay = 0.4
			plate.velocity = normal * 45.0
			plate.lifetime = 2.0
	return 1.5


# --- Sansworth (Genocide) ---------------------------------------------------------------
# He was going to drive everyone to safety. The van never starts.

## HONK: a horn, from nowhere (he doesn't have a car; he has a horn). Rings of
## noise, one after another.
static func _honk(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var ring := Attacks._bullet(enemy, parent, area, Vector2(area.end.x - 6, area.get_center().y))
	ring.shape = "ring"
	ring.size = 5.0
	ring.color = Color(1.0, 0.9, 0.4)
	ring.delay = 0.2
	ring.ring_speed = 95.0
	ring.gap_angle = (soul - ring.position).angle() + randf_range(0.5, 0.9) * (1.0 if step % 2 == 0 else -1.0)
	ring.gap_width = 0.5
	ring.lifetime = 2.0
	return 0.55


## KEY RING: all 31 of his keys, on one ring, spinning outward from the middle.
## None of them fit anything.
static func _key_ring(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var center := area.get_center()
	# Every other time, the ring comes back IN, around you.
	if step % 2 == 1:
		for i in 10:
			var angle := i * TAU / 10.0 + step * 0.3
			if i == step % 10:
				continue
			var spot := (soul + Vector2.from_angle(angle) * 60.0).clamp(area.position + Vector2(4, 4), area.end - Vector2(4, 4))
			var back := _glyph(enemy, parent, area, spot, "key", 7.0)
			back.delay = 0.4
			back.velocity = (soul - spot).normalized() * 75.0
		return 1.0
	for i in 10:
		var angle := i * TAU / 10.0 + step * 0.3
		var key := _glyph(enemy, parent, area, center + Vector2.from_angle(angle) * 8.0, "key", 7.0)
		key.delay = 0.3
		key.velocity = Vector2.from_angle(angle + 0.5) * 80.0
		key.spin = 6.0
	return 1.0


## REV: he revs an engine he doesn't have, with his mouth. Exhaust puffs, low.
static func _rev_engine(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var y := area.end.y - 8 - (step % 4) * 14.0
	if step % 4 == 3:
		y = clampf(soul.y, area.position.y + 6, area.end.y - 6)
	var puff := _dot(enemy, parent, area, Vector2(area.position.x + 4, y), Color(0.6, 0.6, 0.65), 12.0)
	puff.velocity = Vector2(140, -10)
	puff.sway = 15.0
	return 0.22


## HIGH BEAMS: two headlights from the far corners, swinging across.
static func _high_beams(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for top in [true, false]:
		var from := Vector2(area.end.x, area.position.y if top else area.end.y)
		var aim := (soul - from).angle() + (0.12 if top else -0.12) * (step % 3 - 1)
		Attacks._beam(enemy, parent, area, from + Vector2.from_angle(aim) * 10.0, Vector2.from_angle(aim), 0.55, HEADLIGHT)
	return 1.1


## WRONG TURN: cars head off one way, realize, and U-turn right back.
static func _wrong_turn(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var y := Attacks._aim_y(area, soul, step, 2)
	var left := step % 2 == 0
	var car := _glyph(enemy, parent, area, Vector2(area.position.x + 8 if left else area.end.x - 8, y), "car", 10.0)
	car.velocity = Vector2(230 if left else -230, 0)
	car.acceleration = Vector2(-200 if left else 200, 0)
	car.lifetime = 2.4
	return 0.5


## PARALLEL PARKING: blocks slide in sideways, trying to fit in spaces that aren't
## there, and stop in odd places.
static func _parallel_park(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var y := Attacks._aim_y(area, soul, step, 2, 10.0)
	var left := step % 2 == 0
	var block := _dot(enemy, parent, area, Vector2(area.position.x + 6 if left else area.end.x - 6, y), Color(0.85, 0.8, 0.7), 14.0)
	block.delay = 0.2
	block.velocity = Vector2(160 if left else -160, 0)
	block.stop_after = randf_range(0.35, 0.8)
	block.lifetime = 2.0
	return 0.45


## TRAFFIC: lanes of cars, alternating directions. Cross when you can.
static func _traffic(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var lanes := 5
	var lane := step % lanes
	var y := area.position.y + (lane + 0.5) * area.size.y / lanes
	var left := lane % 2 == 0
	var car := _glyph(enemy, parent, area, Vector2(area.position.x + 6 if left else area.end.x - 6, y), "car", 10.0)
	car.velocity = Vector2(130 if left else -130, 0)
	if step % 7 == 6:
		var extra := _glyph(enemy, parent, area, Vector2(area.position.x + 6, clampf(soul.y, area.position.y + 6, area.end.y - 6)), "car", 10.0)
		extra.delay = 0.3
		extra.velocity = Vector2(150, 0)
	return 0.2


## (The van.) VROOM: the van tries to start. It sputters. Puffs of black smoke,
## slow, everywhere. It never starts.
static func _vroom(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var puff := _dot(enemy, parent, area, Vector2(x, area.end.y - 4), Color(0.2, 0.2, 0.22), 11.0)
	puff.velocity = Vector2(randf_range(-15, 15), -60)
	puff.sway = 20.0
	return 0.3
