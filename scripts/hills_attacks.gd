class_name HillsAttacks
extends RefCounted
## The burned hills (fragment 10): the Firefighter, Ember (the fire's leftover
## heart), and Ronin (on the Genocide path). Works like Attacks.spawn(): adds
## bullets, and returns how many seconds until it's called again (or -1 for a
## pattern it doesn't know).

const FIRE := Color(1.0, 0.45, 0.15)
const FIRE_HOT := Color(1.0, 0.85, 0.35)
const ASH := Color(0.55, 0.52, 0.5)
const SMOKE := Color(0.4, 0.38, 0.4)
const AMP := Color(0.95, 0.25, 0.25)


static func spawn(pattern: String, enemy: Enemy, parent: Node, area: Rect2, s: Vector2, step: int) -> float:
	match pattern:
		# --- The Firefighter ---
		"hose_spray": return _hose_spray(enemy, parent, area, s, step)
		"axe_chop": return _axe_chop(enemy, parent, area, s, step)
		# --- Ember ---
		"wildfire": return _wildfire(enemy, parent, area, s, step)
		"spark_burst": return _spark_burst(enemy, parent, area, s, step)
		"smoke_screen": return _smoke_screen(enemy, parent, area, s, step)
		"firestorm": return _firestorm(enemy, parent, area, s, step)
		"heat_shimmer": return _heat_shimmer(enemy, parent, area, s, step)
		"the_tent": return _the_tent(enemy, parent, area, s, step)
		"ash_fall": return _ash_fall(enemy, parent, area, s, step)
		"burning_out": return _burning_out(enemy, parent, area, s, step)
		# --- Ronin (Genocide) ---
		"power_chord": return _power_chord(enemy, parent, area, s, step)
		"flame_solo": return _flame_solo(enemy, parent, area, s, step)
		"feedback": return _feedback(enemy, parent, area, s, step)
		"pick_slide": return _pick_slide(enemy, parent, area, s, step)
		"stage_dive": return _stage_dive(enemy, parent, area, s, step)
		"encore": return _encore(enemy, parent, area, s, step)
		"riff_loop": return _riff_loop(enemy, parent, area, s, step)
		"held_note": return _held_note(enemy, parent, area, s, step)
	return -1.0


static func _glyph(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, glyph: String, size: float = 8.0) -> Bullet:
	return FolkAttacks._glyph(enemy, parent, area, at, glyph, size)


static func _dot(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, color: Color, size: float = 6.0) -> Bullet:
	var b := Attacks._bullet(enemy, parent, area, at)
	b.size = size
	b.color = color
	return b


# --- The Firefighter -------------------------------------------------------------------

## HOSE: a stream of water, swinging side to side across the box.
static func _hose_spray(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(area.get_center().x, area.position.y + 4)
	var angle := PI / 2 + sin(step * 0.35) * 0.9
	if step % 6 == 0:
		angle = (soul - from).angle()
	var drop := _dot(enemy, parent, area, from, Color(0.5, 0.8, 1.0), 6.0)
	drop.velocity = Vector2.from_angle(angle) * 150.0
	return 0.08


## AXE: a chop straight down where you are, then one to each side.
static func _axe_chop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for i in 3:
		var x := clampf(soul.x + (i - 1) * 34.0, area.position.x + 6, area.end.x - 6)
		Attacks._beam(enemy, parent, area, Vector2(x, area.get_center().y), Vector2.DOWN, 0.5 + absi(i - 1) * 0.25, Color(0.85, 0.85, 0.9))
	return 1.2


# --- Ember ------------------------------------------------------------------------------
# The same fire. It feeds on hits (Enemy.feeds_on_hits): every blow makes it
# bigger. Spare it by letting it burn out: survive, and don't feed it.

## WILDFIRE: fire runs along the ground, one row at a time, catching upward.
static func _wildfire(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var row := step % 6
	var y := area.end.y - 6 - row * (area.size.y - 12) / 5.0
	# (Every third row catches right where you're standing.)
	if step % 3 == 2:
		y = clampf(soul.y, area.position.y + 6, area.end.y - 6)
	var left := (step / 6) % 2 == 0
	for k in 3:
		var flame := Attacks._bullet(enemy, parent, area, Vector2(area.position.x + 4 if left else area.end.x - 4, y))
		flame.shape = "star"
		flame.size = 8.0
		flame.color = FIRE if k != 1 else FIRE_HOT
		flame.delay = 0.15 + k * 0.08
		flame.velocity = Vector2(130 if left else -130, 0)
		flame.glow = true
	return 0.3


## SPARK BURST: an ember pops, and sparks go everywhere, with one gap.
static func _spark_burst(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var at := Vector2(randf_range(area.position.x + 20, area.end.x - 20), randf_range(area.position.y + 14, area.end.y - 14))
	if step % 2 == 0:
		at = (soul + Vector2.from_angle(randf() * TAU) * 40.0).clamp(area.position + Vector2(8, 8), area.end - Vector2(8, 8))
	var gap := (soul - at).angle() + PI * (0.3 if step % 3 == 0 else 1.0)
	for i in 14:
		var angle := i * TAU / 14.0
		if absf(angle_difference(angle, gap)) < 0.3:
			continue
		var spark := _dot(enemy, parent, area, at, FIRE_HOT, 4.0)
		spark.delay = 0.4
		spark.velocity = Vector2.from_angle(angle) * 110.0
		spark.trail_length = 3
	return 0.75


## SMOKE: thick, slow clouds roll across. Something hot is hiding in each one.
static func _smoke_screen(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var y := Attacks._aim_y(area, soul, step, 2)
	var cloud := _dot(enemy, parent, area, Vector2(area.position.x + 6 if left else area.end.x - 6, y), SMOKE, 18.0)
	cloud.velocity = Vector2(55 if left else -55, 0)
	cloud.sway = 10.0
	var coal := _dot(enemy, parent, area, cloud.position, FIRE, 5.0)
	coal.velocity = cloud.velocity
	coal.delay = 0.9
	coal.homing = Attacks._soul(parent)
	coal.homing_time = 0.5
	coal.turn_rate = 2.5
	return 0.65


## FIRESTORM: a ring of fire closes in on you. One way out.
static func _firestorm(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var ring := Attacks._bullet(enemy, parent, area, soul)
	ring.shape = "ring"
	ring.size = 6.0
	ring.color = FIRE
	ring.delay = 0.35
	ring.radius = 70.0
	ring.ring_speed = -60.0
	ring.gap_angle = randf() * TAU
	ring.gap_width = 0.6
	ring.lifetime = 1.3
	return 1.15


## HEAT SHIMMER: the air wavers. Hot spots drift, wobbling, hard to read.
static func _heat_shimmer(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3)
	var shimmer := _dot(enemy, parent, area, Vector2(x, area.end.y - 4), Color(1.0, 0.7, 0.4, 0.75), 6.0)
	shimmer.velocity = Vector2(0, -75)
	shimmer.sway = 40.0
	shimmer.zigzag = 2.0
	return 0.18


## THE TENT: a tent made of fire, room for three, closes around you, peak first.
static func _the_tent(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var peak := Vector2(clampf(soul.x, area.position.x + 30, area.end.x - 30), area.position.y + 6)
	var base_l := Vector2(peak.x - 60, area.end.y - 4)
	var base_r := Vector2(peak.x + 60, area.end.y - 4)
	var gap_side := step % 2
	for side in 2:
		var to: Vector2 = base_l if side == 0 else base_r
		for k in 8:
			if side == gap_side and k == 3 + step % 3:
				continue
			var at := peak.lerp(to, (k + 0.5) / 8.0).clamp(area.position + Vector2(4, 4), area.end - Vector2(4, 4))
			var flame := _dot(enemy, parent, area, at, FIRE, 7.0)
			flame.delay = 0.3 + k * 0.05
			flame.velocity = Vector2(55 if side == 0 else -55, 0)
			flame.lifetime = 1.4
			flame.glow = true
	return 1.6


## ASH: grey flakes, everywhere, falling the way snow would if snow were sad.
static func _ash_fall(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var flake := _dot(enemy, parent, area, Vector2(Attacks._aim_x(area, soul, step, 4), area.position.y + 4), ASH, 5.0)
	flake.velocity = Vector2(randf_range(-10, 10), 50)
	flake.sway = 30.0
	return 0.1


## (Burning out.) Fewer embers, slower, dimmer. It's almost over. Don't feed it.
static func _burning_out(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 2)
	var ember := _dot(enemy, parent, area, Vector2(x, area.position.y + 4), Color(1.0, 0.5, 0.3, 0.7), 6.0)
	ember.velocity = Vector2(0, 55)
	ember.sway = 15.0
	return 0.4


# --- Ronin (Genocide) -------------------------------------------------------------------
# He plays his POWER RIFF, the last time. He doesn't finish it.

## POWER CHORD: a wall of sound, every string at once, with one string missing.
static func _power_chord(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var gap := Attacks._away_from(randf_range(area.position.y + 14, area.end.y - 14), soul.y, area.position.y + 14, area.end.y - 14)
	var y := area.position.y + 6
	while y < area.end.y - 2:
		if absf(y - gap) > 12:
			var note := Attacks._bullet(enemy, parent, area, Vector2(area.position.x + 4 if left else area.end.x - 4, y))
			note.shape = "star"
			note.size = 7.0
			note.color = AMP
			note.delay = 0.3
			note.velocity = Vector2(140 if left else -140, 0)
		y += 10
	return 1.0


## FLAME SOLO: fire pours off the fretboard in a fast, bending line.
static func _flame_solo(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(area.end.x - 4, area.position.y + area.size.y * (0.5 + 0.45 * sin(step * 0.4)))
	var flame := Attacks._bullet(enemy, parent, area, from)
	flame.shape = "star"
	flame.size = 7.0
	flame.color = FIRE
	flame.velocity = (soul - from).normalized().rotated(sin(step * 0.7) * 0.3) * 170.0
	flame.trail_length = 4
	flame.glow = true
	return 0.1


## FEEDBACK: the amps howl. Rings of noise from the corners.
static func _feedback(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var corners := [area.position, Vector2(area.end.x, area.position.y), Vector2(area.position.x, area.end.y), area.end]
	var from: Vector2 = corners[step % 4]
	var ring := Attacks._bullet(enemy, parent, area, from.clamp(area.position + Vector2(2, 2), area.end - Vector2(2, 2)))
	ring.shape = "ring"
	ring.size = 4.0
	ring.color = AMP
	ring.delay = 0.25
	ring.ring_speed = 85.0
	ring.gap_angle = (soul - from).angle() + randf_range(0.4, 0.8) * (1.0 if step % 2 == 0 else -1.0)
	ring.gap_width = 0.5
	ring.lifetime = 2.2
	return 0.6


## PICK SLIDE: guitar picks, sliding down the strings on a diagonal.
static func _pick_slide(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(randf_range(area.position.x, area.end.x), area.position.y + 4)
	if step % 3 == 0:
		from.x = soul.x - (soul.y - area.position.y) * 0.6
		# (Too far left to start at the top? Start on the left edge instead.)
		if from.x < area.position.x + 4:
			from = Vector2(area.position.x + 4, soul.y - (soul.x - area.position.x - 4) / 0.6)
	var pick := _glyph(enemy, parent, area, from, "pick", 7.0)
	pick.velocity = Vector2(0.6, 1.0).normalized() * 150.0
	pick.spin = 6.0
	return 0.2


## STAGE DIVE: he jumps. Where he lands, the stage cracks.
static func _stage_dive(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := clampf(soul.x, area.position.x + 12, area.end.x - 12)
	var body := Attacks._bullet(enemy, parent, area, Vector2(x, area.position.y + 8))
	body.shape = "ball"
	body.size = 20.0
	body.color = Color(0.6, 0.15, 0.15)
	body.delay = 0.45
	body.velocity = Vector2(0, 60)
	body.acceleration = Vector2(0, 420)
	body.splits_into = 8
	body.split_color = FIRE
	return 1.0


## ENCORE: the crowd (there isn't one) wants more. Notes come back along the path
## you took last turn.
static func _encore(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var path: Array = parent.get("_last_soul_path") if parent.get("_last_soul_path") != null else []
	var at := soul
	if not path.is_empty():
		at = path[mini(step * 2, path.size() - 1)]
	var note := _dot(enemy, parent, area, at.clamp(area.position + Vector2(5, 5), area.end - Vector2(5, 5)), AMP, 9.0)
	note.delay = 0.3
	note.lifetime = 0.55
	note.glow = true
	return 0.22


## RIFF LOOP: the riff goes round and round: notes circling the middle of the box,
## spiraling out.
static func _riff_loop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var center := area.get_center()
	var angle := step * 0.5
	var note := Attacks._bullet(enemy, parent, area, center + Vector2.from_angle(angle) * 10.0)
	note.shape = "star"
	note.size = 7.0
	note.color = Color(1.0, 0.6, 0.6)
	note.velocity = Vector2.from_angle(angle + 0.6) * 90.0
	# And now and then, one note straight from the amp, at you.
	if step % 7 == 6:
		var from := Vector2(area.end.x - 4, randf_range(area.position.y + 8, area.end.y - 8))
		var hit := Attacks._bullet(enemy, parent, area, from)
		hit.shape = "star"
		hit.size = 8.0
		hit.color = AMP
		hit.velocity = (soul - from).normalized() * 120.0
	return 0.09


## (The end of the riff.) THE HELD NOTE: one long note, held, sweeping slowly across
## the box. He never finishes it.
static func _held_note(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var t := step * 0.25
	var through := Vector2(area.get_center().x + sin(t) * area.size.x * 0.4, area.get_center().y)
	var beam := Attacks._beam(enemy, parent, area, through, Vector2.DOWN.rotated(sin(t * 0.7) * 0.4), 0.3, FIRE_HOT)
	beam.lifetime = 0.3
	if step % 4 == 0:
		var spark := _dot(enemy, parent, area, Vector2(clampf(soul.x, area.position.x + 6, area.end.x - 6), area.position.y + 4), FIRE, 5.0)
		spark.velocity = Vector2(0, 100)
	return 0.25
