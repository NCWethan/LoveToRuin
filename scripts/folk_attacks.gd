class_name FolkAttacks
extends RefCounted
## The attacks of the people around town (townsfolk.gd) and the wild creatures
## you can run into anywhere (wild_battles.gd). Every one is their own: Coach
## Ramirez throws his keys, the Waiting Ghost's ride never comes, a goose just
## comes at you. Works like Attacks.spawn(): adds bullets, and returns how many
## seconds until it's called again (or -1 for a pattern it doesn't know).


static func spawn(pattern: String, enemy: Enemy, parent: Node, area: Rect2, s: Vector2, step: int) -> float:
	match pattern:
		# --- People around town ---
		"coach_keys": return _coach_keys(enemy, parent, area, s, step)
		"coach_laps": return _coach_laps(enemy, parent, area, s, step)
		"wet_floor": return _wet_floor(enemy, parent, area, s, step)
		"trash_toss": return _trash_toss(enemy, parent, area, s, step)
		"kickflip": return _kickflip(enemy, parent, area, s, step)
		"grind_rail": return _grind_rail(enemy, parent, area, s, step)
		"five_minutes": return _five_minutes(enemy, parent, area, s, step)
		"headlights": return _headlights(enemy, parent, area, s, step)
		"gum_stick": return _gum_stick(enemy, parent, area, s, step)
		"segway": return _segway(enemy, parent, area, s, step)
		"coupons": return _coupons(enemy, parent, area, s, step)
		"grocery_hop": return _grocery_hop(enemy, parent, area, s, step)
		"pigeon_flock": return _pigeon_flock(enemy, parent, area, s, step)
		"breadcrumbs": return _breadcrumbs(enemy, parent, area, s, step)
		"notifications": return _notifications(enemy, parent, area, s, step)
		"doomscroll": return _doomscroll(enemy, parent, area, s, step)
		"laps": return _laps(enemy, parent, area, s, step)
		"sweat_spray": return _sweat_spray(enemy, parent, area, s, step)
		"moths": return _moths(enemy, parent, area, s, step)
		"wing_dust": return _wing_dust(enemy, parent, area, s, step)
		"flashlight": return _flashlight(enemy, parent, area, s, step)
		"zzz": return _zzz(enemy, parent, area, s, step)
		"fetch": return _fetch(enemy, parent, area, s, step)
		"zoomies": return _zoomies(enemy, parent, area, s, step)
		"paper_planes": return _paper_planes(enemy, parent, area, s, step)
		"backpack": return _backpack(enemy, parent, area, s, step)
		# --- Wild creatures ---
		"cart_ram": return _cart_ram(enemy, parent, area, s, step)
		"coin_roll": return _coin_roll(enemy, parent, area, s, step)
		"receipt_ribbon": return _receipt_ribbon(enemy, parent, area, s, step)
		"ink_blots": return _ink_blots(enemy, parent, area, s, step)
		"balloon_rise": return _balloon_rise(enemy, parent, area, s, step)
		"balloon_pop": return _balloon_pop(enemy, parent, area, s, step)
		"goose_chase": return _goose_chase(enemy, parent, area, s, step)
		"feathers": return _feathers(enemy, parent, area, s, step)
		"spray_arc": return _spray_arc(enemy, parent, area, s, step)
		"puddle_splash": return _puddle_splash(enemy, parent, area, s, step)
		"gnome_hats": return _gnome_hats(enemy, parent, area, s, step)
		"tiny_shovels": return _tiny_shovels(enemy, parent, area, s, step)
		"flamingo_stomp": return _flamingo_stomp(enemy, parent, area, s, step)
		"pink_feathers": return _pink_feathers(enemy, parent, area, s, step)
		"seagull_dive": return _seagull_dive(enemy, parent, area, s, step)
		"fry_steal": return _fry_steal(enemy, parent, area, s, step)
		"acorn_drop": return _acorn_drop(enemy, parent, area, s, step)
		"squirrel_dash": return _squirrel_dash(enemy, parent, area, s, step)
		"bag_drift": return _bag_drift(enemy, parent, area, s, step)
		"gust": return _gust(enemy, parent, area, s, step)
		# --- Mission Beach ---
		"coaster_cars": return _coaster_cars(enemy, parent, area, s, step)
		"the_drop": return _the_drop(enemy, parent, area, s, step)
		"loop_track": return _loop_track(enemy, parent, area, s, step)
		"come_back": return _come_back(enemy, parent, area, s, step)
		"near_miss": return _near_miss(enemy, parent, area, s, step)
		# --- Balboa Park ---
		"sword_sweep": return _sword_sweep(enemy, parent, area, s, step)
		"armor_rain": return _armor_rain(enemy, parent, area, s, step)
		"shield_charge": return _shield_charge(enemy, parent, area, s, step)
	return -1.0


## A little picture that hurts (see Bullet.GLYPHS).
static func _glyph(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, glyph: String, size: float = 8.0) -> Bullet:
	var b := Attacks._bullet(enemy, parent, area, at)
	b.shape = "glyph"
	b.glyph = glyph
	b.size = size
	return b


## A side of the box: true is the left.
static func _side_x(area: Rect2, left: bool, margin: float = 6.0) -> float:
	return area.position.x + margin if left else area.end.x - margin


# --- Coach Ramirez -----------------------------------------------------------------

## His keys (he has eleven sets), lobbed from the top corners in arcs. They land
## with a jingle and bounce once. Every third set comes down on the SOUL.
static func _coach_keys(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var start := Vector2(_side_x(area, left), area.position.y + 6)
	var target := Attacks._aim_x(area, soul, step, 3)
	var keys := _glyph(enemy, parent, area, start, "key", 9.0)
	keys.velocity = Vector2((target - start.x) / 0.8, -30)
	keys.acceleration = Vector2(0, 280)
	keys.bounce_speed = 80
	keys.spin = 9.0
	return 0.42


## LAPS: a line of cones sweeps across the box, one side to the other, with one
## gap to run through (never where the SOUL already is).
static func _coach_laps(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var low := area.position.y + 10
	var high := area.end.y - 10
	var gap := Attacks._away_from(randf_range(low, high), soul.y, low, high)
	var y := low
	while y <= high:
		if absf(y - gap) > 14.0:
			var cone := _glyph(enemy, parent, area, Vector2(_side_x(area, left), y), "cone", 9.0)
			cone.velocity = Vector2(105 if left else -105, 0)
		y += 14.0
	return 1.15


# --- The Janitor ---------------------------------------------------------------------

## WET FLOOR signs slide in along the floor at the SOUL's row, skid to a stop,
## and slide back out the way they came.
static func _wet_floor(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var y := Attacks._aim_y(area, soul, step, 1, 8.0)
	var sign_ := _glyph(enemy, parent, area, Vector2(_side_x(area, left), y), "wet_sign", 9.0)
	sign_.delay = 0.3
	sign_.velocity = Vector2(300 if left else -300, 0)
	sign_.acceleration = Vector2(-330 if left else 330, 0)
	return 0.7


## Trash, tipped out of a can: cans flung up from the bottom, falling back down.
static func _trash_toss(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := randf_range(area.position.x + 10, area.end.x - 10)
	var can := _glyph(enemy, parent, area, Vector2(x, area.end.y - 6), "can", 9.0)
	var target := Attacks._aim_x(area, soul, step, 2)
	can.velocity = Vector2((target - x) * 0.9, -randf_range(240, 300))
	can.acceleration = Vector2(0, 330)
	can.spin = 6.0
	return 0.45


# --- The Skater -----------------------------------------------------------------------

## KICKFLIP: skateboards launch off the floor from the corners, flipping end over
## end, in arcs that pass right through the SOUL.
static func _kickflip(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var start := Vector2(_side_x(area, left, 10.0), area.end.y - 6)
	var board := _glyph(enemy, parent, area, start, "board", 10.0)
	var gravity := 300.0
	var rise := maxf(start.y - soul.y, 12.0)
	var up := sqrt(2.0 * gravity * rise)
	board.velocity = Vector2((soul.x - start.x) / (up / gravity), -up)
	board.acceleration = Vector2(0, gravity)
	board.spin = 12.0
	return 0.6


## GRIND RAIL: three boards in a row grind down a slanted rail straight through
## the SOUL. The first one shows where the rail is.
static func _grind_rail(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var direction := Vector2(1, 0.5 if step % 2 == 0 else -0.5).normalized()
	if randf() < 0.5:
		direction = -direction
	# Start where the rail through the SOUL enters the box.
	var start := soul
	while area.grow(-4).has_point(start - direction * 4.0):
		start -= direction * 4.0
	for i in 3:
		var board := _glyph(enemy, parent, area, start, "board", 10.0)
		board.delay = 0.55 + i * 0.16
		board.velocity = direction * 240.0
		board.face_motion = true
	return 1.3


# --- The Waiting Ghost --------------------------------------------------------------

## FIVE MINUTES: the ticks of a clock appear in a circle around the middle of the
## box, one after another, and each one flies at the SOUL. It's always five more
## minutes.
static func _five_minutes(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var angle := -PI / 2 + step * TAU / 12.0
	var at := area.get_center() + Vector2.from_angle(angle) * 52.0
	at = at.clamp(area.position + Vector2(5, 5), area.end - Vector2(5, 5))
	var tick := _glyph(enemy, parent, area, at, "tick", 5.0)
	tick.delay = 0.35
	tick.velocity = (soul - at).normalized() * 125.0
	return 0.25


## HEADLIGHTS: their ride, finally! Headlights glow at the side of the box, then a
## car comes roaring across. ...Sometimes it doesn't come at all, and one comes
## from the other side instead.
static func _headlights(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var y := Attacks._aim_y(area, soul, step, 1, 10.0)
	var car := _glyph(enemy, parent, area, Vector2(_side_x(area, left, 10.0), y), "car", 12.0)
	car.delay = 0.7
	car.velocity = Vector2(300 if left else -300, 0)
	if step % 3 == 1:
		# Never mind. It isn't coming. (But one from the other side is.)
		car.lifetime = 0.01
		var real := _glyph(enemy, parent, area, Vector2(_side_x(area, not left, 10.0), y), "car", 12.0)
		real.delay = 1.0
		real.velocity = Vector2(-340 if left else 340, 0)
	return 0.95


# --- The Mall Cop -----------------------------------------------------------------

## GUM: wads of gum drop in and stick where they land, so the box fills up with
## places you can't stand.
static func _gum_stick(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3)
	var gum := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "gum", 8.0)
	gum.velocity = Vector2(0, 170)
	gum.stop_after = randf_range(0.15, (area.size.y - 10.0) / 170.0)
	gum.lifetime = 2.8
	return 0.38


## PATROL: he rolls back and forth along the SOUL's row on his segway, bouncing
## off the walls, while a second one patrols another row.
static func _segway(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var rows := [soul.y, randf_range(area.position.y + 10, area.end.y - 10)]
	for i in rows.size():
		var left := (step + i) % 2 == 0
		var cop := _glyph(enemy, parent, area, Vector2(_side_x(area, left, 10.0), clampf(rows[i], area.position.y + 8, area.end.y - 8)), "segway", 11.0)
		cop.delay = 0.45
		cop.velocity = Vector2(130 if left else -130, 0)
		cop.wall_bounce = true
		cop.lifetime = 2.4
	return 1.3


# --- The Busy Mom --------------------------------------------------------------------

## COUPONS: a coupon for everything, fluttering down, zigzagging and spinning.
static func _coupons(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3, 12.0)
	var coupon := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "coupon", 10.0)
	coupon.velocity = Vector2(0, 78)
	coupon.sway = 70.0
	coupon.spin = 3.0
	return 0.3


## GROCERY HOP: grocery bags bound across the floor in big kangaroo hops. Every
## third one splits open when it lands, and apples go everywhere.
static func _grocery_hop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var bag := _glyph(enemy, parent, area, Vector2(_side_x(area, left, 8.0), area.end.y - 8), "grocery", 11.0)
	bag.velocity = Vector2(95 if left else -95, -randf_range(240, 300))
	bag.acceleration = Vector2(0, 420)
	if step % 2 == 1:
		# This one's first hop lands right on the SOUL.
		var gravity := 420.0
		var rise := maxf(bag.position.y - soul.y, 12.0)
		var up := sqrt(2.0 * gravity * rise)
		bag.velocity = Vector2((soul.x - bag.position.x) / (up / gravity), -up)
	if step % 3 == 2:
		bag.splits_into = 4
		bag.split_shape = "glyph"
		bag.split_glyph = "apple"
	else:
		bag.bounce_speed = 290
		bag.bounce_variance = 0.15
	return 0.75


# --- Pigeon Man --------------------------------------------------------------------

## THE FLOCK: a V of pigeons (every one of them is Gerald) sweeps across the box.
static func _pigeon_flock(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var y := Attacks._aim_y(area, soul, step, 2, 20.0)
	for i in 5:
		var rank := (i + 1) / 2
		var side := 1.0 if i % 2 == 0 else -1.0
		var at := Vector2(_side_x(area, left, 6.0) - (rank * 14.0 if left else -rank * 14.0), clampf(y + side * rank * 12.0, area.position.y + 6, area.end.y - 6))
		var bird := _glyph(enemy, parent, area, at, "bird", 9.0)
		bird.velocity = Vector2(150 if left else -150, 0)
	return 1.0


## BREADCRUMBS: a handful of crumbs tossed from a corner, and every so often a
## Gerald dives straight for where you are.
static func _breadcrumbs(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var corner := Vector2(_side_x(area, left), area.position.y + 6)
	for i in 5:
		var crumb := Attacks._bullet(enemy, parent, area, corner)
		crumb.size = 4.0
		crumb.color = Color(0.85, 0.72, 0.5)
		var angle := (PI / 2) + (-0.9 if left else 0.9) * (0.2 + i * 0.18)
		crumb.velocity = Vector2.from_angle(angle) * randf_range(90, 130)
		crumb.acceleration = Vector2(0, 120)
	if step % 3 == 2:
		var gerald := _glyph(enemy, parent, area, Vector2(randf_range(area.position.x + 10, area.end.x - 10), area.position.y + 6), "bird", 9.0)
		gerald.delay = 0.3
		gerald.velocity = (soul - gerald.position).normalized() * 180.0
		gerald.homing = Attacks._soul(parent)
		gerald.homing_time = 0.4
	return 0.6


# --- The Teen on the Phone ---------------------------------------------------------

## NOTIFICATIONS: pings pop up all over the box, then burst into little red dots.
static func _notifications(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var at := Vector2(randf_range(area.position.x + 12, area.end.x - 12), randf_range(area.position.y + 12, area.end.y - 12))
	if step % 3 == 0:
		at = soul + Vector2(randf_range(-24, 24), randf_range(-24, 24))
	at = at.clamp(area.position + Vector2(8, 8), area.end - Vector2(8, 8))
	var ping := _glyph(enemy, parent, area, at, "notif", 9.0)
	ping.delay = 0.6
	ping.lifetime = 0.05
	for k in 4:
		var dot := Attacks._bullet(enemy, parent, area, at)
		dot.size = 4.0
		dot.color = Color(0.95, 0.25, 0.3)
		dot.delay = 0.62
		dot.velocity = Vector2.from_angle(PI / 4 + k * PI / 2) * 115.0
	return 0.55


## DOOMSCROLL: the feed, scrolling up the box forever, one message after another.
static func _doomscroll(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3, 10.0)
	var text := _glyph(enemy, parent, area, Vector2(x, area.end.y - 4), "text", 12.0)
	text.velocity = Vector2(0, -95)
	return 0.28


# --- The Jogger --------------------------------------------------------------------

## LAPS: she runs laps around the edge of the box (more of her each time around),
## flinging sweat into the middle as she goes.
static func _laps(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	if step % 4 == 0:
		var runner := _glyph(enemy, parent, area, area.position, "ostrich", 10.0)
		runner.lap_speed = 190.0
		runner.lap_start = step * 60.0
		runner.lifetime = 3.6
	else:
		var from := Vector2(randf_range(area.position.x + 6, area.end.x - 6), area.position.y + 6)
		var drop := _glyph(enemy, parent, area, from, "drop", 8.0)
		drop.velocity = (soul - from).normalized() * 105.0
	return 0.35


## SWEAT: as she runs past, drops spray out and rain down behind her.
static func _sweat_spray(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := area.position.x + fmod(step * 23.0, area.size.x - 8.0) + 4.0
	if step % 3 == 0:
		x = soul.x
	var drop := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "drop", 8.0)
	drop.velocity = Vector2(randf_range(-40, 40), 40)
	drop.acceleration = Vector2(0, 260)
	return 0.2


# --- The Night Janitor (a moth) ---------------------------------------------------

## DRAWN TO THE LIGHT: moths flutter in from the edges and drift toward the SOUL.
## It's the brightest thing in here. They can't help it.
static func _moths(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var edge := randi() % 4
	var at: Vector2
	match edge:
		0: at = Vector2(randf_range(area.position.x, area.end.x), area.position.y + 6)
		1: at = Vector2(area.end.x - 6, randf_range(area.position.y, area.end.y))
		2: at = Vector2(randf_range(area.position.x, area.end.x), area.end.y - 6)
		_: at = Vector2(area.position.x + 6, randf_range(area.position.y, area.end.y))
	var moth := _glyph(enemy, parent, area, at, "moth", 9.0)
	moth.velocity = (soul - at).normalized() * 60.0
	moth.homing = Attacks._soul(parent)
	moth.homing_time = 3.2
	moth.turn_rate = 2.6
	moth.sway = 30.0
	moth.lifetime = 3.4
	return 0.7


## WING DUST: dust shaken off his wings, spiraling out from the middle in two arms.
static func _wing_dust(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var angle := step * 0.42
	for arm in 3:
		var dust := Attacks._bullet(enemy, parent, area, area.get_center())
		dust.size = 6.0
		dust.color = Color(0.85, 0.78, 1.0)
		dust.delay = 0.15
		dust.velocity = Vector2.from_angle(angle + arm * TAU / 3.0) * 95.0
	# Now and then a puff blows straight at the SOUL.
	if step % 8 == 7:
		var puff := Attacks._bullet(enemy, parent, area, area.get_center())
		puff.size = 7.0
		puff.color = Color(0.85, 0.78, 1.0)
		puff.delay = 0.2
		puff.velocity = (soul - area.get_center()).normalized() * 110.0
	return 0.12


# --- The Security Guard (an owl) -------------------------------------------------

## FLASHLIGHT: his flashlight sweeps back and forth from the top of the box. Don't
## get caught in the beam.
static func _flashlight(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var top := Vector2(area.get_center().x, area.position.y + 2)
	var angle := PI / 2 + sin(step * 0.3) * 1.45
	for i in 12:
		var at := top + Vector2.from_angle(angle) * (10.0 + i * 10.0)
		if not area.grow(-3).has_point(at):
			break
		var light := Attacks._bullet(enemy, parent, area, at)
		light.size = 8.0
		light.color = Color(1.0, 0.95, 0.65)
		light.delay = 0.25
		light.lifetime = 0.3
		light.glow = true
	return 0.12


## ZZZ: he's mostly asleep. Z's float up from the bottom of the box, swaying.
static func _zzz(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3, 10.0)
	var z := _glyph(enemy, parent, area, Vector2(x, area.end.y - 4), "z", 8.0)
	z.velocity = Vector2(0, -62)
	z.sway = 40.0
	return 0.32


# --- The Dog Walker (and Biscuit) --------------------------------------------------

## FETCH: a tennis ball, thrown in a bouncing arc, and Biscuit tearing along the
## floor after it.
static func _fetch(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 4 < 2
	if step % 2 == 0:
		var ball := _glyph(enemy, parent, area, Vector2(_side_x(area, left), area.position.y + 10), "tennis", 8.0)
		ball.velocity = Vector2(120 if left else -120, -40)
		ball.acceleration = Vector2(0, 300)
		ball.bounce_speed = 200
	else:
		var biscuit := _glyph(enemy, parent, area, Vector2(_side_x(area, left, 8.0), clampf(soul.y, area.position.y + 8, area.end.y - 8)), "dog", 12.0)
		biscuit.delay = 0.25
		biscuit.velocity = Vector2(220 if left else -220, 0)
	return 0.55


## ZOOMIES: Biscuit gets the zoomies. Too fast to turn properly, she overshoots
## and loops around for another pass.
static func _zoomies(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var corners := [area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)]
	var at: Vector2 = corners[step % 4]
	at = at.clamp(area.position + Vector2(8, 8), area.end - Vector2(8, 8))
	var biscuit := _glyph(enemy, parent, area, at, "dog", 12.0)
	biscuit.delay = 0.35
	biscuit.velocity = (soul - at).normalized() * 210.0
	biscuit.homing = Attacks._soul(parent)
	biscuit.homing_time = 3.0
	biscuit.turn_rate = 1.9
	biscuit.lifetime = 3.0
	biscuit.wall_bounce = true
	return 1.0


# --- Students ------------------------------------------------------------------------

## PAPER PLANES: notes folded into planes, sailing in from the sides and turning
## toward the SOUL for a moment.
static func _paper_planes(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var at := Vector2(_side_x(area, left), randf_range(area.position.y + 10, area.end.y - 10))
	var plane := _glyph(enemy, parent, area, at, "plane", 10.0)
	plane.velocity = Vector2(150 if left else -150, 0)
	plane.homing = Attacks._soul(parent)
	plane.homing_time = 0.6
	plane.turn_rate = 2.6
	plane.face_motion = true
	return 0.55


## BACKPACK: a heavy backpack drops in and bursts open, books flying.
static func _backpack(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var bag := _glyph(enemy, parent, area, Vector2(x, area.position.y + 6), "backpack", 10.0)
	bag.velocity = Vector2(0, 40)
	bag.acceleration = Vector2(0, 340)
	bag.splits_into = 4
	bag.split_shape = "glyph"
	bag.split_glyph = "book"
	return 0.8


# --- Runaway Cart (the PQ Mall) ---------------------------------------------------

## RAM: carts come barreling down two lanes, one of them yours. Their rattle (the
## faint cart) shows the lane first.
static func _cart_ram(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	for y in [soul.y, randf_range(area.position.y + 10, area.end.y - 10)]:
		var cart := _glyph(enemy, parent, area, Vector2(_side_x(area, left, 10.0), clampf(y, area.position.y + 8, area.end.y - 8)), "cart", 12.0)
		cart.delay = 0.6
		cart.velocity = Vector2(280 if left else -280, 0)
	return 0.95


## LOOSE CHANGE: quarters spill out, hit the floor, and roll.
static func _coin_roll(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3)
	var coin := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "coin", 8.0)
	coin.velocity = Vector2(randf_range(-15, 15) if step % 3 == 0 else randf_range(-80, 80), 30)
	coin.acceleration = Vector2(0, 320)
	coin.bounce_speed = 70
	coin.spin = 8.0
	return 0.4


# --- Receipt ---------------------------------------------------------------------------

## UNROLL: the receipt unrolls toward the SOUL in a long, wavy ribbon of paper.
static func _receipt_ribbon(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var start := Vector2(_side_x(area, left), area.position.y + 6)
	var aim := (soul - start).normalized() * 120.0
	for i in 10:
		var paper := _glyph(enemy, parent, area, start, "paper", 5.0)
		paper.delay = i * 0.07
		paper.velocity = aim
		paper.sway = 50.0
	return 1.0


## INK: blots of printer ink drip down and splatter when they land.
static func _ink_blots(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var ink := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "ink", 7.0)
	ink.velocity = Vector2(0, 90)
	ink.acceleration = Vector2(0, 160)
	ink.splits_into = 3
	ink.split_shape = "glyph"
	ink.split_glyph = "ink"
	return 0.45


# --- Lost Balloon --------------------------------------------------------------------

## FLOAT: balloons rise from the bottom of the box, bobbing on their strings.
static func _balloon_rise(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3, 10.0)
	var balloon := _glyph(enemy, parent, area, Vector2(x, area.end.y - 6), "balloon", 9.0)
	balloon.velocity = Vector2(0, -70)
	balloon.sway = 30.0
	return 0.38


## POP: a balloon drifts up close to the SOUL and pops, bits of rubber flying out.
static func _balloon_pop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var at := (soul + Vector2.from_angle(randf() * TAU) * 42.0).clamp(area.position + Vector2(8, 8), area.end - Vector2(8, 8))
	var balloon := _glyph(enemy, parent, area, at, "balloon", 9.0)
	balloon.delay = 0.7
	balloon.lifetime = 0.05
	for k in 6:
		var bit := Attacks._bullet(enemy, parent, area, at)
		bit.size = 4.0
		bit.color = Color(0.9, 0.2, 0.22)
		bit.delay = 0.72
		bit.velocity = Vector2.from_angle(k * TAU / 6 + step) * 120.0
		# (One piece always flies your way.)
		if k == 0:
			bit.velocity = (soul - at).normalized() * 120.0
	return 0.9


# --- Goose ---------------------------------------------------------------------------

## HONK: the goose just comes at you. Neck out. No hesitation.
static func _goose_chase(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var at := Vector2(_side_x(area, left, 8.0), randf_range(area.position.y + 10, area.end.y - 10))
	var goose := _glyph(enemy, parent, area, at, "bird", 11.0)
	goose.color = Color(1, 1, 1)
	goose.delay = 0.3
	goose.velocity = (soul - at).normalized() * 175.0
	goose.homing = Attacks._soul(parent)
	goose.homing_time = 0.8
	goose.turn_rate = 3.0
	return 0.8


## FEATHERS: a fistful of feathers, see-sawing down.
static func _feathers(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3, 10.0)
	var feather := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "feather", 8.0)
	feather.velocity = Vector2(0, 60)
	feather.sway = 55.0
	return 0.25


# --- Sprinkler -----------------------------------------------------------------------

## SPRAY: water arcs out of the sprinkler head at the bottom of the box, sweeping
## back and forth.
static func _spray_arc(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var head := Vector2(area.get_center().x, area.end.y - 4)
	var angle := -PI / 2 + sin(step * 0.38) * 1.25
	var drop := _glyph(enemy, parent, area, head, "drop", 7.0)
	drop.velocity = Vector2.from_angle(angle) * 265.0
	drop.acceleration = Vector2(0, 300)
	# Every so often a stray jet shoots straight at the SOUL.
	if step % 6 == 5:
		var jet := _glyph(enemy, parent, area, head, "drop", 7.0)
		jet.velocity = (soul - head).normalized() * 200.0
	return 0.09


## SPLASH: big drops fall and splash apart when they hit the ground.
static func _puddle_splash(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var drop := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "drop", 9.0)
	drop.velocity = Vector2(0, 80)
	drop.acceleration = Vector2(0, 200)
	drop.splits_into = 5
	drop.split_shape = "glyph"
	drop.split_glyph = "drop"
	return 0.5


# --- Garden Gnome ----------------------------------------------------------------------

## HATS: little pointy red hats, dropping and bouncing.
static func _gnome_hats(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var hat := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "hat", 8.0)
	hat.velocity = Vector2(randf_range(-30, 30), 20)
	hat.acceleration = Vector2(0, 300)
	hat.bounce_speed = 150
	hat.bounce_variance = 0.2
	return 0.45


## TINY SHOVELS: thrown, spinning, from the bottom corners.
static func _tiny_shovels(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var at := Vector2(_side_x(area, left), area.end.y - 6)
	var shovel := _glyph(enemy, parent, area, at, "shovel", 8.0)
	shovel.velocity = (soul - at).normalized() * 170.0
	shovel.spin = 10.0
	return 0.5


# --- Lawn Flamingo --------------------------------------------------------------------

## STOMP: a long pink leg stomps down through the box, right where you are.
static func _flamingo_stomp(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 1, 8.0)
	Attacks._beam(enemy, parent, area, Vector2(x, area.get_center().y), Vector2.DOWN, 0.55, Color(1.0, 0.55, 0.75))
	return 0.85


## PINK FEATHERS: blowing in sideways on the breeze.
static func _pink_feathers(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var y := Attacks._aim_y(area, soul, step, 2, 8.0)
	var feather := _glyph(enemy, parent, area, Vector2(area.position.x + 4, y), "pink_feather", 8.0)
	feather.velocity = Vector2(120, 0)
	feather.zigzag = 1.0
	return 0.25


# --- Hungry Seagull -----------------------------------------------------------------

## DIVE: it dives out of the sky at the SOUL. (It thinks you have fries.)
static func _seagull_dive(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var at := Vector2(randf_range(area.position.x + 10, area.end.x - 10), area.position.y + 6)
	var gull := _glyph(enemy, parent, area, at, "bird", 10.0)
	gull.color = Color(1, 1, 1)
	gull.delay = 0.3
	gull.velocity = (soul - at).normalized() * 190.0
	gull.homing = Attacks._soul(parent)
	gull.homing_time = 0.5
	return 0.7


## STOLEN FRIES: fries raining down, and every so often the gull swoops across
## low to grab them.
static func _fry_steal(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3)
	var fry := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "fry", 7.0)
	fry.velocity = Vector2(randf_range(-20, 20), 140)
	fry.spin = 4.0
	if step % 4 == 3:
		var left := randf() < 0.5
		var gull := _glyph(enemy, parent, area, Vector2(_side_x(area, left), soul.y), "bird", 10.0)
		gull.color = Color(1, 1, 1)
		gull.delay = 0.5
		gull.velocity = Vector2(240 if left else -240, 0)
	return 0.22


# --- Squirrel --------------------------------------------------------------------------

## ACORNS: dropped from above. They bounce once.
static func _acorn_drop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var acorn := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "acorn", 8.0)
	acorn.velocity = Vector2(0, 40)
	acorn.acceleration = Vector2(0, 340)
	acorn.bounce_speed = 120
	return 0.3


## SCAMPER: it zigzags across the box faster than you'd think.
static func _squirrel_dash(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var squirrel := _glyph(enemy, parent, area, Vector2(_side_x(area, left, 8.0), clampf(soul.y, area.position.y + 14, area.end.y - 14)), "squirrel", 11.0)
	squirrel.delay = 0.35
	squirrel.velocity = Vector2(190 if left else -190, 0)
	squirrel.zigzag = 6.0
	return 0.7


# --- Plastic Bag -----------------------------------------------------------------------

## DRIFT: bags drifting on the wind, rising and falling.
static func _bag_drift(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var y := Attacks._aim_y(area, soul, step, 2, 10.0)
	var bag := _glyph(enemy, parent, area, Vector2(area.position.x + 4, y), "bag", 9.0)
	bag.velocity = Vector2(90, 0.0 if step % 2 == 0 else randf_range(-25, 25))
	bag.zigzag = 2.5
	return 0.4


## GUST: a whole wall of leaves and litter blows across, with one gap.
static func _gust(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var low := area.position.y + 8
	var high := area.end.y - 8
	var gap := Attacks._away_from(randf_range(low, high), soul.y, low, high)
	var y := low
	while y <= high:
		if absf(y - gap) > 13.0:
			var leaf := _glyph(enemy, parent, area, Vector2(area.position.x + 4, y), "leaf", 7.0)
			leaf.velocity = Vector2(165, 0)
			leaf.spin = 5.0
		y += 12.0
	return 1.0


# --- The Dipper (Mission Beach) ------------------------------------------------------

## COASTER CARS: a train of cars rattles across the box along a wavy track (they
## rise and dip as they go). The track runs through the SOUL's row.
static func _coaster_cars(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var y := Attacks._aim_y(area, soul, step, 1, 14.0)
	for i in 4:
		var car := _glyph(enemy, parent, area, Vector2(_side_x(area, left, 8.0) - (i * 16.0 if left else -i * 16.0), y), "cart", 11.0)
		car.velocity = Vector2(170 if left else -170, 0)
		car.zigzag = 3.0
	return 1.0


## THE DROP: CLACK... CLACK... CLACK... (the cars climb in at the top, faint),
## then they all come down at once, fast, with one gap.
static func _the_drop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var low := area.position.x + 8
	var high := area.end.x - 8
	var gap := Attacks._away_from(randf_range(low, high), soul.x, low, high)
	var x := low
	while x <= high:
		if absf(x - gap) > 13.0:
			var car := _glyph(enemy, parent, area, Vector2(x, area.position.y + 6), "cart", 10.0)
			car.delay = 0.9
			car.velocity = Vector2(0, 60)
			car.acceleration = Vector2(0, 420)
		x += 14.0
	return 1.5


## LOOP: the track loops around the SOUL; a ring of cars with one opening, closing in.
static func _loop_track(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var ring := Attacks._bullet(enemy, parent, area, soul)
	ring.shape = "ring"
	ring.size = 5.0
	ring.color = Color(0.85, 0.3, 0.25)
	ring.delay = 0.3
	ring.radius = 90.0
	ring.ring_speed = -55.0
	ring.gap_angle = randf() * TAU
	ring.gap_width = 0.75
	ring.lifetime = 1.6
	return 1.2


# --- Crayola (Genocide) -------------------------------------------------------------

## A tiny 3x5 font, for spelling with cards.
const LETTERS := {
	"C": ["###", "#..", "#..", "#..", "###"], "O": ["###", "#.#", "#.#", "#.#", "###"],
	"M": ["#.#", "###", "#.#", "#.#", "#.#"], "E": ["###", "#..", "##.", "#..", "###"],
	"B": ["##.", "#.#", "##.", "#.#", "##."], "A": [".#.", "#.#", "###", "#.#", "#.#"],
	"K": ["#.#", "##.", "#..", "##.", "#.#"],
}

## COME BACK: Crayola's cards (every one the Seven of Hearts) gather into letters,
## one at a time, across the top of the box, and then drift down. They spell
## COME BACK.
static func _come_back(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var word := "COMEBACK"
	var letter: String = word[step % word.length()]
	var col := step % 4
	var row := (step % 8) / 4
	var origin := area.position + Vector2(18 + col * 36, 10 + row * 0)
	var rows: Array = LETTERS[letter]
	for y in rows.size():
		for x in 3:
			if str(rows[y])[x] == "#":
				var card := _glyph(enemy, parent, area, origin + Vector2(x * 7, y * 7), "heart_card", 6.0)
				card.delay = 0.5
				card.velocity = Vector2(0, 38 + (step % 8) * 4)
	return 0.75


# --- N.C. Wethan (Genocide) ---------------------------------------------------------

## NEAR MISS: lightning cracks down all over the box, everywhere except where you
## are. He isn't aiming at you. He never was.
static func _near_miss(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := randf_range(area.position.x + 8, area.end.x - 8)
	if absf(x - soul.x) < 30.0:
		x = soul.x + (34.0 if x >= soul.x else -34.0)
		if x < area.position.x + 6 or x > area.end.x - 6:
			x = soul.x - (x - soul.x)
	Attacks._beam(enemy, parent, area, Vector2(x, area.get_center().y), Vector2.DOWN, 0.4, Color(0.45, 0.85, 1.0))
	return 0.35


# --- The Empty Knight (Balboa Park) -------------------------------------------------

## SWORD SWEEP: the Knight's sword cuts across the box in a wide arc from one top
## corner: three slashes fanning out, one after another, the last through the SOUL.
static func _sword_sweep(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var pivot := Vector2(area.position.x if left else area.end.x, area.position.y)
	var aim := (soul - pivot).angle()
	for i in 3:
		var angle := aim + (-0.5 + i * 0.25) * (1.0 if left else -1.0)
		Attacks._beam(enemy, parent, area, pivot + Vector2.from_angle(angle) * 10.0, Vector2.from_angle(angle), 0.45 + i * 0.22, Color(0.85, 0.88, 0.95))
	return 1.4


## ARMOR RAIN: pieces of armor fall from the rack: helmets and gauntlets, tumbling.
static func _armor_rain(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3)
	var piece := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "helmet" if step % 2 == 0 else "gauntlet", 10.0)
	piece.velocity = Vector2(randf_range(-30, 30), 40)
	piece.acceleration = Vector2(0, 260)
	piece.spin = 6.0
	return 0.33


## SHIELD CHARGE: the Knight charges behind its kite shield along your row, plants
## it, and charges back the other way.
static func _shield_charge(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var y := clampf(soul.y, area.position.y + 10, area.end.y - 10)
	var shield := _glyph(enemy, parent, area, Vector2(_side_x(area, left, 8.0), y), "kite_shield", 14.0)
	shield.delay = 0.5
	shield.velocity = Vector2(320 if left else -320, 0)
	shield.acceleration = Vector2(-340 if left else 340, 0)
	return 1.0
