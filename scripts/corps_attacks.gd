class_name CorpsAttacks
extends RefCounted
## The REVOLUTION Corps, fought as bosses: Crayola, N.C. Wethan, Big Joe and Nat.
## Each of them has at least six attacks of their own, and a last one they only
## use when they're nearly beaten (Enemy.finale_patterns). They get faster as the
## fight goes on (`_pace`). Works like Attacks.spawn(): adds bullets, and returns
## how many seconds until it's called again (or -1 for a pattern it doesn't know).

const CARD_RED := Color(0.95, 0.25, 0.3)
const BOLT := Color(0.45, 0.85, 1.0)
const BOLT_WHITE := Color(0.85, 0.97, 1.0)
const GOLD := Color(1.0, 0.82, 0.25)
const STEEL := Color(0.85, 0.87, 0.92)
const INK := Color(0.8, 0.72, 1.0)


static func spawn(pattern: String, enemy: Enemy, parent: Node, area: Rect2, s: Vector2, step: int) -> float:
	match pattern:
		# --- Crayola: the magician (cards, all of them the Seven of Hearts) ---
		"card_fan": return _card_fan(enemy, parent, area, s, step)
		"riffle_shuffle": return _riffle_shuffle(enemy, parent, area, s, step)
		"pick_a_card": return _pick_a_card(enemy, parent, area, s, step)
		"fifty_two_pickup": return _fifty_two_pickup(enemy, parent, area, s, step)
		"vanishing_act": return _vanishing_act(enemy, parent, area, s, step)
		"undertow": return _undertow(enemy, parent, area, s, step)
		"seven_of_hearts": return _seven_of_hearts(enemy, parent, area, s, step)
		# --- N.C. Wethan: lightning, and checkers ---
		"checkerboard": return _checkerboard(enemy, parent, area, s, step)
		"king_me": return _king_me(enemy, parent, area, s, step)
		"chain_lightning": return _chain_lightning(enemy, parent, area, s, step)
		"storm_front": return _storm_front(enemy, parent, area, s, step)
		"live_wire": return _live_wire(enemy, parent, area, s, step)
		"loudest_man": return _loudest_man(enemy, parent, area, s, step)
		"double_jump": return _double_jump(enemy, parent, area, s, step)
		# --- Big Joe: justice, by the rules ---
		"joust": return _joust(enemy, parent, area, s, step)
		"shield_press": return _shield_press(enemy, parent, area, s, step)
		"rulebook": return _rulebook(enemy, parent, area, s, step)
		"salute": return _salute(enemy, parent, area, s, step)
		"justice_for_all": return _justice_for_all(enemy, parent, area, s, step)
		"helmet_bash": return _helmet_bash(enemy, parent, area, s, step)
		# --- Nat: the reader ---
		"footnotes": return _footnotes(enemy, parent, area, s, step)
		"spoiler": return _spoiler(enemy, parent, area, s, step)
		"page_turn": return _page_turn(enemy, parent, area, s, step)
		"cross_reference": return _cross_reference(enemy, parent, area, s, step)
		"history_repeats": return _history_repeats(enemy, parent, area, s, step)
		"the_last_page": return _the_last_page(enemy, parent, area, s, step)
	return -1.0


## How much faster everything comes as the fight goes on (and once they're
## nearly beaten). 1.0 at the start, down to about 0.7.
static func _pace(enemy: Enemy) -> float:
	var p := 1.0 - 0.05 * mini(enemy.fury, 4)
	if enemy.hp * 3 < enemy.max_hp:
		p -= 0.1
	return p


static func _speed(enemy: Enemy) -> float:
	return 1.0 / _pace(enemy)


static func _glyph(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, glyph: String, size: float = 8.0) -> Bullet:
	return FolkAttacks._glyph(enemy, parent, area, at, glyph, size)


static func _inside(area: Rect2, at: Vector2, margin: float = 6.0) -> Vector2:
	return at.clamp(area.position + Vector2(margin, margin), area.end - Vector2(margin, margin))


# --- Crayola ---------------------------------------------------------------------------

## CARD FAN: a fan of seven cards flicked from one top corner, spread around you.
static func _card_fan(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var from := Vector2(area.position.x + 6 if left else area.end.x - 6, area.position.y + 6)
	var aim := (soul - from).angle()
	for i in 7:
		var card := _glyph(enemy, parent, area, from, "heart_card", 7.0)
		card.delay = 0.25
		card.velocity = Vector2.from_angle(aim + (i - 3) * 0.13) * 125.0 * _speed(enemy)
		card.spin = 9.0
	return 0.85 * _pace(enemy)


## RIFFLE SHUFFLE: rows of cards riffle in from both sides at once, interleaving.
## One row is missing on each side; they're never the same row.
static func _riffle_shuffle(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var rows := int(area.size.y / 14.0)
	var gap_left := randi() % rows
	var gap_right := (gap_left + 1 + randi() % maxi(rows - 1, 1)) % rows
	for r in rows:
		var y := area.position.y + 7 + r * 14.0
		var from_left := r % 2 == 0
		if r == (gap_left if from_left else gap_right):
			continue
		var card := _glyph(enemy, parent, area, Vector2(area.position.x + 4 if from_left else area.end.x - 4, y), "heart_card", 7.0)
		card.delay = 0.35
		card.velocity = Vector2(95.0 if from_left else -95.0, 0) * _speed(enemy)
	return 1.25 * _pace(enemy)


## PICK A CARD: three cards hover over the box. One of them is your card. It
## comes for you.
static func _pick_a_card(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for i in 3:
		var at := Vector2(area.position.x + area.size.x * (0.25 + i * 0.25), area.position.y + 10)
		var card := _glyph(enemy, parent, area, at, "heart_card", 9.0)
		card.delay = 0.45 + i * 0.12
		card.velocity = (soul - at).normalized() * 105.0 * _speed(enemy)
		card.homing = Attacks._soul(parent)
		card.homing_time = 0.55 if i == step % 3 else 0.0
		card.turn_rate = 2.4
		card.trail_length = 4
		card.glow = i == step % 3
	return 1.0 * _pace(enemy)


## 52 PICKUP: the whole deck goes up at once, out of the middle of the box, in
## every direction. There's a gap in the spray, somewhere.
static func _fifty_two_pickup(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var center := area.get_center() + Vector2(randf_range(-20, 20), randf_range(-12, 12))
	var gap := (soul - center).angle() + randf_range(0.6, 1.2) * (1.0 if step % 2 == 0 else -1.0)
	for i in 26:
		var angle := i * TAU / 26.0 + step * 0.11
		if absf(angle_difference(angle, gap)) < 0.35:
			continue
		var card := _glyph(enemy, parent, area, center, "heart_card", 6.0)
		card.delay = 0.5
		card.velocity = Vector2.from_angle(angle) * 85.0 * _speed(enemy)
		card.spin = 6.0
	return 1.3 * _pace(enemy)


## VANISHING ACT: cards appear in a ring all around you, then close in. Two are
## missing: that's the way out.
static func _vanishing_act(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	const COUNT := 14
	var gap := randi() % COUNT
	for i in COUNT:
		if i == gap or i == (gap + 1) % COUNT:
			continue
		var spot := _inside(area, soul + Vector2.from_angle(i * TAU / COUNT) * 58.0, 4.0)
		var card := _glyph(enemy, parent, area, spot, "heart_card", 7.0)
		card.delay = 0.65
		card.velocity = (soul - spot).normalized() * 110.0 * _speed(enemy)
	return 1.35 * _pace(enemy)


## UNDERTOW: Crayola swims. A wave of water rolls across the box along the bottom,
## and pulls back the other way, higher.
static func _undertow(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from_left := step % 2 == 0
	var height := area.size.y * (0.4 + 0.15 * (step % 2))
	# (Every third one is the riptide: it comes along the top.)
	var top := step % 3 == 2
	var low := area.position.y + 6 if top else area.end.y - height
	var high := area.position.y + height if top else area.end.y - 6
	var gap := Attacks._away_from(randf_range(low + 6, high - 6), soul.y, low + 6, high - 6)
	var y := high
	while y > low:
		if absf(y - gap) > 13:
			var drop := FolkAttacks._glyph(enemy, parent, area, Vector2(area.position.x + 4 if from_left else area.end.x - 4, y), "drop", 6.0)
			drop.delay = 0.3
			drop.velocity = Vector2(110.0 if from_left else -110.0, 0) * _speed(enemy)
			drop.zigzag = 3.0
		y -= 9
	return 1.0 * _pace(enemy)


## (Nearly beaten.) SEVEN OF HEARTS: columns of hearts fall, seven at a time, and
## the gap between them slides toward wherever you aren't.
static func _seven_of_hearts(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var columns := 9
	var width := area.size.x / columns
	var gap := clampi(int((soul.x - area.position.x) / width) + (2 if step % 2 == 0 else -2), 0, columns - 1)
	for c in columns:
		if c == gap:
			continue
		var heart := _glyph(enemy, parent, area, Vector2(area.position.x + width * (c + 0.5), area.position.y + 4), "heart_card", 8.0)
		heart.delay = 0.4
		heart.velocity = Vector2(0, 80) * _speed(enemy)
		heart.glow = true
	return 0.9 * _pace(enemy)


# --- N.C. Wethan -----------------------------------------------------------------------
# His lightning hits everything around you. Every attack leaves a way out: he's
# not aiming at you, and he never was. But you have to find it.

## CHECKERBOARD: the box is a board. Lightning strikes every black square, then
## every red one. Stand on the other color.
static func _checkerboard(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var cell := 24.0
	var cols := int(ceil(area.size.x / cell))
	var rows := int(ceil(area.size.y / cell))
	var parity := step % 2
	for r in rows:
		for c in cols:
			if (r + c) % 2 != parity:
				continue
			var at := area.position + Vector2(c + 0.5, r + 0.5) * cell
			var zap := Attacks._bullet(enemy, parent, area, _inside(area, at, 2.0))
			zap.size = cell - 4.0
			zap.color = BOLT if parity == 0 else Color(1.0, 0.45, 0.45)
			zap.delay = 0.7 * _pace(enemy)
			zap.lifetime = 0.25
	return 1.0 * _pace(enemy)


## KING ME: a checker piece hops across the box, square by square, crowned in
## lightning. Then another, the other way.
static func _king_me(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from_left := step % 2 == 0
	var checker := Attacks._bullet(enemy, parent, area, Vector2(area.position.x + 8 if from_left else area.end.x - 8, area.position.y + 10 + randf() * 20))
	checker.shape = "ball"
	checker.size = 14.0
	checker.color = Color(0.85, 0.15, 0.2) if step % 2 == 0 else Color(0.15, 0.15, 0.18)
	checker.velocity = Vector2((70.0 if from_left else -70.0) * _speed(enemy), 0)
	checker.acceleration = Vector2(0, 340)
	checker.bounce_speed = 200
	checker.bounce_variance = 0.25
	checker.wall_bounce = true
	checker.lifetime = 4.0
	checker.trail_length = 4
	checker.glow = true
	return 1.1 * _pace(enemy)


## CHAIN LIGHTNING: one bolt across the box, and from where it lands, more bolts
## branch off, one after another, closer and closer. The last one misses you.
static func _chain_lightning(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var horizontal := step % 2 == 0
	var low := (area.position.y if horizontal else area.position.x) + 10
	var high := (area.end.y if horizontal else area.end.x) - 10
	var start := randf_range(low, high)
	var here := soul.y if horizontal else soul.x
	for i in 4:
		var at := lerpf(start, here, i / 4.0) + (16.0 if start > here else -16.0) * (1.0 if i == 3 else 0.0)
		at = clampf(at, low, high)
		var through := Vector2(area.get_center().x, at) if horizontal else Vector2(at, area.get_center().y)
		Attacks._beam(enemy, parent, area, through, Vector2.RIGHT if horizontal else Vector2.DOWN, (0.45 + i * 0.22) * _pace(enemy), BOLT)
	return 1.3 * _pace(enemy)


## STORM FRONT: a sheet of rain blows across the box at a slant, and it's charged.
static func _storm_front(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for i in 3:
		var x := Attacks._aim_x(area, soul, step * 3 + i, 4)
		var drop := Attacks._bullet(enemy, parent, area, Vector2(x - 30, area.position.y + 4))
		drop.shape = "arrow"
		drop.size = 7.0
		drop.color = BOLT_WHITE
		drop.velocity = Vector2(40, 170) * _speed(enemy)
		drop.trail_length = 3
	return 0.22 * _pace(enemy)


## LIVE WIRE: current runs around the edges of the box, faster and faster. Stay
## off the walls. (Then he electrifies the middle row, too.)
static func _live_wire(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	if step < 4:
		var spark := Attacks._bullet(enemy, parent, area, area.position)
		spark.size = 8.0
		spark.color = BOLT
		spark.glow = true
		spark.trail_length = 6
		spark.lap_speed = (150.0 + step * 25.0) * _speed(enemy)
		spark.lap_start = step * (area.size.x + area.size.y) / 2.0
		spark.lifetime = 5.0
		return 0.4
	var horizontal := step % 2 == 0
	var through := area.get_center() + (Vector2(0, randf_range(-20, 20)) if horizontal else Vector2(randf_range(-30, 30), 0))
	Attacks._beam(enemy, parent, area, through, Vector2.RIGHT if horizontal else Vector2.DOWN, 0.6 * _pace(enemy), BOLT)
	return 0.95 * _pace(enemy)


## DOUBLE JUMP: two checkers leap at you at once, from the two top corners, and
## each one jumps again where it lands.
static func _double_jump(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for left in [true, false]:
		var from := Vector2(area.position.x + 8 if left else area.end.x - 8, area.position.y + 8)
		var checker := Attacks._bullet(enemy, parent, area, from)
		checker.shape = "ball"
		checker.size = 11.0
		checker.color = Color(0.85, 0.15, 0.2) if left else Color(0.15, 0.15, 0.18)
		checker.delay = 0.3
		checker.velocity = Vector2((soul.x - from.x) * 0.9, -60) * _speed(enemy)
		checker.acceleration = Vector2(0, 300)
		checker.bounce_speed = 180
		checker.wall_bounce = true
		checker.lifetime = 3.0
		checker.trail_length = 3
	var king := Attacks._bullet(enemy, parent, area, Vector2(clampf(soul.x, area.position.x + 8, area.end.x - 8), area.position.y + 6))
	king.shape = "ball"
	king.size = 11.0
	king.color = Color(1.0, 0.85, 0.25)
	king.delay = 0.55
	king.velocity = Vector2(0, 40)
	king.acceleration = Vector2(0, 300)
	king.glow = true
	return 1.15 * _pace(enemy)


## (Nearly beaten.) THE LOUDEST MAN YOU EVER MET: he yells. Rings of thunder roll
## out of the middle of the box, each with one quiet gap.
static func _loudest_man(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var ring := Attacks._bullet(enemy, parent, area, area.get_center())
	ring.shape = "ring"
	ring.size = 5.0
	ring.color = BOLT_WHITE
	ring.delay = 0.3
	ring.ring_speed = 70.0 * _speed(enemy)
	ring.gap_angle = (soul - area.get_center()).angle() + randf_range(0.6, 1.4) * (1.0 if step % 2 == 0 else -1.0)
	ring.gap_width = 0.6
	ring.lifetime = 2.6
	ring.bounds = Rect2()
	return 0.75 * _pace(enemy)


# --- Big Joe ---------------------------------------------------------------------------
# By the rules: every attack is announced (a warning first), and he never hits
# anyone who's down. That doesn't make it easy.

## JOUST: a long lance, couched, charges down your row after a fanfare of a
## warning. Then down the row above or below.
static func _joust(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from_left := step % 2 == 0
	var y := clampf(soul.y + (0.0 if step % 3 == 0 else (22.0 if step % 3 == 1 else -22.0)), area.position.y + 8, area.end.y - 8)
	var lance := Attacks._bullet(enemy, parent, area, Vector2(area.position.x + 6 if from_left else area.end.x - 6, y))
	lance.shape = "lance"
	lance.size = 14.0
	lance.color = STEEL
	lance.delay = 0.5 * _pace(enemy)
	lance.velocity = Vector2((260.0 if from_left else -260.0) * _speed(enemy), 0)
	lance.trail_length = 6
	return 0.6 * _pace(enemy)


## SHIELD PRESS: two walls of shields close in from the top and the bottom,
## leaving one gap in each. Line them up.
static func _shield_press(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var gap := Attacks._away_from(randf_range(area.position.x + 20, area.end.x - 20), soul.x, area.position.x + 20, area.end.x - 20)
	for top in [true, false]:
		var x := area.position.x + 6
		while x < area.end.x - 2:
			if absf(x - gap) > 14:
				var shield := Attacks._bullet(enemy, parent, area, Vector2(x, area.position.y + 4 if top else area.end.y - 4))
				shield.shape = "shield"
				shield.size = 10.0
				shield.color = STEEL
				shield.delay = 0.3
				shield.velocity = Vector2(0, (55.0 if top else -55.0) * _speed(enemy))
			x += 12
	return 1.6 * _pace(enemy)


## THE RULEBOOK: rule after rule comes down, left to right, like dominoes. Rule
## one: no hitting anyone who's down. Rule two: no running.
static func _rulebook(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var count := 8
	var width := area.size.x / count
	var reverse := step % 2 == 1
	for i in count:
		var c := count - 1 - i if reverse else i
		var x := area.position.x + width * (c + 0.5) + (width * 0.5 if step % 4 >= 2 else 0.0)
		if x > area.end.x - 4:
			continue
		var lance := Attacks._bullet(enemy, parent, area, Vector2(x, area.position.y + 4))
		lance.shape = "lance"
		lance.size = 9.0
		lance.color = GOLD
		lance.delay = (0.3 + i * 0.12) * _pace(enemy)
		lance.velocity = Vector2(0, 190) * _speed(enemy)
		lance.trail_length = 3
	return 1.7 * _pace(enemy)


## SALUTE: his sword comes up... and swings, like a pendulum, from the top of the
## box. While it swings, justice stars come in from the sides.
static func _salute(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	if step == 0:
		var sword := Attacks._bullet(enemy, parent, area, Vector2(area.get_center().x, area.position.y + 2))
		sword.shape = "clapper"
		sword.size = 9.0
		sword.color = STEEL
		sword.delay = 0.7
		sword.lifetime = 3.8
		sword.swing_length = area.size.y * 0.85
		sword.swing_amplitude = 1.05
		sword.swing_speed = 2.8 * _speed(enemy)
		sword.bounds = Rect2()
		return 1.0
	var from_left := step % 2 == 0
	var star := Attacks._bullet(enemy, parent, area, Vector2(area.position.x + 6 if from_left else area.end.x - 6, randf_range(area.position.y + 10, area.end.y - 10)))
	star.shape = "justice_star"
	star.size = 9.0
	star.color = GOLD
	star.glow = true
	star.trail_length = 4
	star.velocity = (soul - star.position).normalized() * 120.0 * _speed(enemy)
	return 0.55 * _pace(enemy)


## HELMET BASH: he lowers his head and charges: a big spiked helmet bounces around
## the box, off every wall.
static func _helmet_bash(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(area.end.x - 10 if step % 2 == 0 else area.position.x + 10, area.position.y + 12)
	var helmet := _glyph(enemy, parent, area, from, "helmet", 14.0)
	helmet.delay = 0.4
	helmet.velocity = (soul - from).normalized() * 150.0 * _speed(enemy)
	helmet.acceleration = Vector2(0, 220)
	helmet.bounce_speed = 210
	helmet.wall_bounce = true
	helmet.lifetime = 3.2
	helmet.spin = 5.0
	return 1.3 * _pace(enemy)


## (Nearly beaten.) JUSTICE FOR ALL: stars from all four sides of the box at once,
## steering toward you for a moment before they commit.
static func _justice_for_all(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var spots := [
		Vector2(randf_range(area.position.x, area.end.x), area.position.y + 4),
		Vector2(randf_range(area.position.x, area.end.x), area.end.y - 4),
		Vector2(area.position.x + 4, randf_range(area.position.y, area.end.y)),
		Vector2(area.end.x - 4, randf_range(area.position.y, area.end.y)),
	]
	for spot in spots:
		var star := Attacks._bullet(enemy, parent, area, spot)
		star.shape = "justice_star"
		star.size = 9.0
		star.color = GOLD
		star.glow = true
		star.trail_length = 5
		star.delay = 0.3
		star.velocity = (soul - spot).normalized() * 115.0 * _speed(enemy)
		star.homing = Attacks._soul(parent)
		star.homing_time = 0.35
		star.turn_rate = 2.0
	return 1.0 * _pace(enemy)


# --- Nat --------------------------------------------------------------------------------
# He reads ahead. A lot of his attacks land where you're GOING to be.

## FOOTNOTES: tiny print, everywhere, drifting down. Too small to read. Too many
## to dodge without trying.
static func _footnotes(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for i in 2:
		var note := _glyph(enemy, parent, area, Vector2(Attacks._aim_x(area, soul, step * 2 + i, 5), area.position.y + 4), "text", 6.0)
		note.velocity = Vector2(randf_range(-12, 12), 55) * _speed(enemy)
		note.sway = 18.0
	return 0.2 * _pace(enemy)


## SPOILER: a bookmark ribbon cuts down where you are, and then where he knows
## you're about to go: to the left, then the right.
static func _spoiler(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var vertical := step % 2 == 0
	var here := soul.x if vertical else soul.y
	var low := (area.position.x if vertical else area.position.y) + 8
	var high := (area.end.x if vertical else area.end.y) - 8
	for i in 3:
		var at := clampf(here + [0.0, -28.0, 28.0][i], low, high)
		var through := Vector2(at, area.get_center().y) if vertical else Vector2(area.get_center().x, at)
		Attacks._beam(enemy, parent, area, through, Vector2.DOWN if vertical else Vector2.RIGHT, (0.5 + i * 0.28) * _pace(enemy), INK)
	return 1.35 * _pace(enemy)


## PAGE TURN: a whole page sweeps across the box, edge first, in a column of
## words. There's one line of white space on it.
static func _page_turn(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from_left := step % 2 == 0
	var gap := Attacks._away_from(randf_range(area.position.y + 14, area.end.y - 14), soul.y, area.position.y + 14, area.end.y - 14)
	var y := area.position.y + 6
	while y < area.end.y - 2:
		if absf(y - gap) > 13:
			for k in 2:
				var word := _glyph(enemy, parent, area, Vector2((area.position.x + 6 if from_left else area.end.x - 6) - (k * 16.0 if from_left else -k * 16.0), y), "text", 7.0)
				word.delay = 0.3
				word.velocity = Vector2((115.0 if from_left else -115.0) * _speed(enemy), 0)
		y += 10
	return 1.2 * _pace(enemy)


## CROSS-REFERENCE: lines of text from both sides, and from the top and bottom,
## all at once. See page 211. See page 212.
static func _cross_reference(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var horizontal := step % 2 == 0
	var count := 6
	for i in count:
		if horizontal:
			var y := area.position.y + 8 + i * (area.size.y - 16) / (count - 1)
			if absf(y - soul.y) < 9 and i % 2 == 0:
				continue
			var from_left := i % 2 == 0
			var word := _glyph(enemy, parent, area, Vector2(area.position.x + 4 if from_left else area.end.x - 4, y), "text", 7.0)
			word.delay = 0.25
			word.velocity = Vector2((90.0 if from_left else -90.0) * _speed(enemy), 0)
		else:
			var x := area.position.x + 10 + i * (area.size.x - 20) / (count - 1)
			var from_top := i % 2 == 0
			var word := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4 if from_top else area.end.y - 4), "text", 7.0)
			word.delay = 0.25
			word.velocity = Vector2(0, (80.0 if from_top else -80.0) * _speed(enemy))
	var cite := _glyph(enemy, parent, area, Vector2(area.position.x + 4, clampf(soul.y, area.position.y + 6, area.end.y - 6)) if horizontal else Vector2(clampf(soul.x, area.position.x + 6, area.end.x - 6), area.position.y + 4), "text", 7.0)
	cite.delay = 0.45
	cite.velocity = (Vector2(100, 0) if horizontal else Vector2(0, 90)) * _speed(enemy)
	return 0.8 * _pace(enemy)


## HISTORY REPEATS: a book flies through the box, and then the same book flies the
## same way again, and again. Everything happens twice. Three times.
static func _history_repeats(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var corners := [area.position, Vector2(area.end.x, area.position.y), Vector2(area.position.x, area.end.y), area.end]
	var from: Vector2 = _inside(area, corners[step % 4], 6.0)
	var dir := (soul - from).normalized()
	for i in 3:
		var book := _glyph(enemy, parent, area, from, "book", 10.0)
		book.delay = (0.35 + i * 0.32) * _pace(enemy)
		book.velocity = dir * 150.0 * _speed(enemy)
		book.spin = 4.0
		book.trail_length = 3
	return 1.0 * _pace(enemy)


## (Nearly beaten.) THE LAST PAGE: pages come down from everywhere at once, and
## the corners fold in. He knows how this ends.
static func _the_last_page(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var page := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "paper", 9.0)
	page.velocity = Vector2(0, 80) * _speed(enemy)
	page.sway = 22.0
	if step % 3 == 0:
		FolkAttacks._dog_ear(enemy, parent, area, soul, step / 3)
	return 0.32 * _pace(enemy)
