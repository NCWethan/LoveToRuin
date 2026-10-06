class_name Attacks
extends RefCounted
## Every enemy attack pattern. Each enemy lists the patterns it knows (in
## tutorial_battle.gd and friends) and uses a different one each turn.
##
## spawn() is called whenever a pattern's timer runs out. It adds bullets to the
## battle and returns how many seconds to wait before it's called again.
## `step` counts how many times it's been called this turn (0, 1, 2, ...).
##
## No attack has a safe spot: even the "random" ones aim some of their shots at
## where the SOUL is (see _aim_x / _aim_y), so standing still always gets you hit.


static func spawn(pattern: String, enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2, step: int) -> float:
	var s := soul_position
	match pattern:
		"rain": return _rain(enemy, parent, area, s, step)
		"straw": return _straw(enemy, parent, area, s, step)
		"egg_drop": return _egg_drop(enemy, parent, area, s, step)
		"bunny_hop": return _bunny_hop(enemy, parent, area, s, step)
		"lance": return _lance(enemy, parent, area, s, step)
		"sweep": return _sweep(enemy, parent, area, s, step)
		"aimed": return _aimed(enemy, parent, area, s)
		"pencils": return _pencils(enemy, parent, area, s, step)
		"bubbles": return _bubbles(enemy, parent, area, s)
		"papers": return _papers(enemy, parent, area, s, step)
		"zoom": return _zoom(enemy, parent, area, s, step)
		"confetti": return _confetti(enemy, parent, area, s, step)
		"foam_finger": return _foam_finger(enemy, parent, area, s, step)
		"dodgeballs": return _dodgeballs(enemy, parent, area, s, step)
		"claw_swipe": return _claw_swipe(enemy, parent, area, s)
		"claw_drop": return _claw_drop(enemy, parent, area, s, step)
		"cleave": return _cleave(enemy, parent, area)
		"slash_grid": return _slash_grid(enemy, parent, area)
		"red_arrows": return _red_arrows(enemy, parent, area, s)
		"burst": return _burst(enemy, parent, area, s)
		"fire_arrow": return _fire_arrow(enemy, parent, area)
		"scantron": return _scantron(enemy, parent, area, s, step)
		"tardy_slips": return _tardy_slips(enemy, parent, area, s, step)
		"gravy": return _gravy(enemy, parent, area, s, step)
		"tray_toss": return _tray_toss(enemy, parent, area, s, step)
		"peas": return _peas(enemy, parent, area, s)
		"ring": return _ring(enemy, parent, area, s, step)
		"sound_waves": return _sound_waves(enemy, parent, area, s)
		"alarm": return _alarm(enemy, parent, area, s, step)
		"sonar": return _sonar(enemy, parent, area, s)
		"clapper": return _clapper(enemy, parent, area, s, step)
		"pages": return _pages(enemy, parent, area, s, step)
		"bookmark": return _bookmark(enemy, parent, area, s)
		"shelf": return _shelf(enemy, parent, area, s, step)
		"bleacher_wave": return _bleacher_wave(enemy, parent, area, s)
		"mascot_spin": return _mascot_spin(enemy, parent, area, s, step)
		"frenzy": return _frenzy(enemy, parent, area, s, step)
	return 1.0


static func _bullet(enemy: Enemy, parent: Node, area: Rect2, at: Vector2) -> Bullet:
	var bullet := Bullet.new()
	bullet.damage = enemy.attack
	bullet.source = enemy
	bullet.bounds = area
	bullet.position = at
	parent.add_child(bullet)
	return bullet


## An x position: every `every`-th shot lines up with the SOUL (give or take a few
## pixels), the rest are random. Keeps "random" attacks from having a safe spot.
static func _aim_x(area: Rect2, soul: Vector2, step: int, every: int, margin: float = 6.0) -> float:
	if step % every == 0:
		return clampf(soul.x + randf_range(-6.0, 6.0), area.position.x + margin, area.end.x - margin)
	return randf_range(area.position.x + margin, area.end.x - margin)


static func _aim_y(area: Rect2, soul: Vector2, step: int, every: int, margin: float = 6.0) -> float:
	if step % every == 0:
		return clampf(soul.y + randf_range(-6.0, 6.0), area.position.y + margin, area.end.y - margin)
	return randf_range(area.position.y + margin, area.end.y - margin)


## Moves a gap's position at least 40 pixels away from `avoid` (staying between
## `low` and `high`), so the way through is never where the SOUL is standing.
static func _away_from(gap: float, avoid: float, low: float, high: float) -> float:
	if absf(gap - avoid) >= 40.0:
		return gap
	var up := avoid - 40.0 - randf() * 20.0
	var down := avoid + 40.0 + randf() * 20.0
	if up < low:
		return minf(down, high)
	if down > high:
		return maxf(up, low)
	return up if randf() < 0.5 else down


# --- Eggo -------------------------------------------------------------------------

## Eggo: drops of runny yolk, falling with little trails. Every third one falls
## right over the SOUL.
static func _rain(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := _aim_x(area, soul, step, 3, 4.0)
	var drop := _bullet(enemy, parent, area, Vector2(x, area.position.y + 3))
	drop.shape = "yolk"
	drop.size = 7.0
	drop.color = Color(1.0, 0.78, 0.15)
	drop.velocity = Vector2(0, enemy.bullet_speed)
	drop.trail_length = 5
	return 0.3


## The training dummy: tufts of straw shaken loose from its stuffing drift down,
## swaying a little as they fall. Every few fall over the SOUL.
static func _straw(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := _aim_x(area, soul, step, 3, 4.0)
	var tuft := _bullet(enemy, parent, area, Vector2(x, area.position.y + 3))
	tuft.shape = "straw"
	tuft.size = 6.0
	tuft.color = Color(0.92, 0.8, 0.42)
	tuft.velocity = Vector2(randf_range(-18.0, 18.0), enemy.bullet_speed * 0.9)
	return 0.3


## Eggo: big shaded eggs drop and speed up as they fall, then crack into a splash
## of yolk drops when they hit the bottom. Every other egg drops over the SOUL.
static func _egg_drop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := _aim_x(area, soul, step, 2, 10.0)
	var egg := _bullet(enemy, parent, area, Vector2(x, area.position.y + 6))
	egg.shape = "egg"
	egg.size = 12.0
	egg.color = Color(0.97, 0.95, 0.85)
	egg.velocity = Vector2(0, 20)
	egg.acceleration = Vector2(0, 170)
	egg.splits_into = 5
	egg.split_color = Color(1.0, 0.78, 0.15)
	egg.split_shape = "yolk"
	return 0.62


## Eggo: Eggo's bunny friend's... friends. They hop across the box, and each one
## jumps high enough to reach wherever the SOUL is.
static func _bunny_hop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from_left := step % 2 == 0
	var x := area.position.x + 5 if from_left else area.end.x - 5
	var bunny := _bullet(enemy, parent, area, Vector2(x, area.end.y - 8))
	bunny.shape = "bunny"
	bunny.size = 9.0
	bunny.color = Color(0.97, 0.97, 1.0)
	var gravity := 340.0
	# How fast it has to bounce to reach just above the SOUL: v = sqrt(2 g h).
	var height := clampf(area.end.y - soul.y + randf_range(-3.0, 5.0), 20.0, area.size.y - 6.0)
	var jump := sqrt(2.0 * gravity * height)
	# Time the first hop so its peak is right where the SOUL is.
	var to_peak := jump / gravity
	var run := (soul.x - x) / to_peak
	if absf(run) < 40.0:
		run = 40.0 if from_left else -40.0
	bunny.velocity = Vector2(run, -jump)
	bunny.acceleration = Vector2(0, gravity)
	bunny.bounce_speed = jump * randf_range(0.9, 1.05)
	bunny.trail_length = 3
	return 0.68


# --- Big Joe ------------------------------------------------------------------------

## Big Joe: lances thrust across the box from the sides, pennants flapping. Every
## other one comes in right at the SOUL's height (after a flash of warning).
static func _lance(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var y := _aim_y(area, soul, step, 2, 5.0)
	var from_left := randf() < 0.5
	var x := area.position.x + 6 if from_left else area.end.x - 6
	var lance := _bullet(enemy, parent, area, Vector2(x, y))
	lance.shape = "lance"
	lance.size = 9.0
	lance.color = Color(0.85, 0.87, 0.92)
	lance.delay = 0.18
	lance.velocity = Vector2(enemy.bullet_speed if from_left else -enemy.bullet_speed, 0)
	lance.trail_length = 4
	return 0.36


## Big Joe: a wall of shields sweeps across the box. Dodge through the gap!
static func _sweep(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from_left := step % 2 == 0
	var x := area.position.x + 4 if from_left else area.end.x - 4
	var gap := randf_range(area.position.y + 22, area.end.y - 22)
	gap = _away_from(gap, soul.y, area.position.y + 22, area.end.y - 22)
	var y := area.position.y + 6
	while y < area.end.y - 2:
		if absf(y - gap) > 15:
			var shield := _bullet(enemy, parent, area, Vector2(x, y))
			shield.shape = "shield"
			shield.size = 10.0
			shield.color = Color(0.82, 0.84, 0.9)
			shield.velocity = Vector2(105 if from_left else -105, 0)
		y += 11
	return 1.35


## Big Joe: "JUSTICE STRIKE!" Glowing gold stars, spinning, launched right at
## where the SOUL is, trailing light.
static func _aimed(enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2) -> float:
	var start: Vector2
	match randi() % 3:
		0: start = Vector2(randf_range(area.position.x, area.end.x), area.position.y + 3)
		1: start = Vector2(area.position.x + 3, randf_range(area.position.y, area.end.y))
		_: start = Vector2(area.end.x - 3, randf_range(area.position.y, area.end.y))
	var star := _bullet(enemy, parent, area, start)
	star.shape = "justice_star"
	star.size = 10.0
	star.color = Color(1.0, 0.82, 0.25)
	star.glow = true
	star.trail_length = 6
	star.velocity = (soul_position - start).normalized() * 150.0
	return 0.48


# --- Westview High School ---------------------------------------------------

## Pop Quiz: pencils rain down at an angle.
static func _pencils(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := _aim_x(area, soul, step, 3)
	var pencil := _bullet(enemy, parent, area, Vector2(x, area.position.y + 4))
	pencil.shape = "pencil"
	pencil.size = 8.0
	pencil.velocity = Vector2(randf_range(-45, 45), 125)
	if step % 3 == 0:
		pencil.velocity = (soul - pencil.position).normalized() * 135.0
	return 0.45


## Pop Quiz: answer bubbles appear as faint warnings, then fly at where the SOUL was.
static func _bubbles(enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2) -> float:
	for i in 3:
		var at := Vector2(randf_range(area.position.x + 10, area.end.x - 10), randf_range(area.position.y + 10, area.end.y - 10))
		# Don't appear right on top of the SOUL.
		if at.distance_to(soul_position) < 30:
			at.y = area.position.y + 10
		var bubble := _bullet(enemy, parent, area, at)
		bubble.shape = "bubble"
		bubble.size = 9.0
		bubble.delay = 0.7
		bubble.velocity = (soul_position - at).normalized() * 95.0
	return 1.3


## Hall Pass: little hall passes flutter down, drifting side to side.
static func _papers(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := _aim_x(area, soul, step, 3, 10.0)
	var card := _bullet(enemy, parent, area, Vector2(x, area.position.y + 4))
	card.shape = "card"
	card.size = 10.0
	card.color = Color(0.8, 0.6, 0.35)
	card.velocity = Vector2(0, 70)
	card.sway = 45.0
	return 0.35


## Hall Pass: a warning shows which row it'll dash down, then it ZOOMS across.
static func _zoom(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from_left := step % 2 == 0
	var y := _aim_y(area, soul, step, 2, 8.0)
	var x := area.position.x + 6 if from_left else area.end.x - 6
	var card := _bullet(enemy, parent, area, Vector2(x, y))
	card.shape = "card"
	card.size = 14.0
	card.color = Color(0.8, 0.6, 0.35)
	card.delay = 0.6
	card.velocity = Vector2(260 if from_left else -260, 0)
	return 0.75


## Pop Quiz: a column of answer bubbles fills in across the box (they flash first).
## One bubble in the column is left blank: that's the way through.
static func _scantron(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := _aim_x(area, soul, step, 2, 10.0)
	var gap := randi_range(1, int(area.size.y / 14) - 2)
	var row := 0
	var y := area.position.y + 8
	while y < area.end.y - 4:
		if absi(row - gap) > 0:
			var bubble := _bullet(enemy, parent, area, Vector2(x, y))
			bubble.shape = "bubble"
			bubble.size = 10.0
			bubble.delay = 0.6
			bubble.lifetime = 0.45
		row += 1
		y += 14
	return 0.7


## Hall Pass: tardy slips slide in diagonally from the top corners.
static func _tardy_slips(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from_left := step % 2 == 0
	var x := area.position.x + 6 if from_left else area.end.x - 6
	var slip := _bullet(enemy, parent, area, Vector2(x, area.position.y + 6))
	slip.shape = "card"
	slip.size = 10.0
	slip.color = Color(1.0, 0.75, 0.8)
	slip.velocity = Vector2(95 if from_left else -95, 85)
	if step % 3 == 2:
		# Every third slip is thrown right at the SOUL.
		slip.velocity = (soul - slip.position).normalized() * 130.0
	return 0.38


# --- Westview: the cafeteria, the bell, the library -------------------------

## Mystery Meat: blobs of gravy drop, speed up, and splatter into brown drops.
static func _gravy(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := _aim_x(area, soul, step, 2, 10.0)
	var blob := _bullet(enemy, parent, area, Vector2(x, area.position.y + 6))
	blob.shape = "egg"
	blob.size = 10.0
	blob.color = Color(0.55, 0.35, 0.2)
	blob.velocity = Vector2(0, 30)
	blob.acceleration = Vector2(0, 160)
	blob.splits_into = 3
	blob.split_color = Color(0.7, 0.45, 0.25)
	return 0.75


## Mystery Meat: lunch trays spin across the box.
static func _tray_toss(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from_left := step % 2 == 0
	var y := _aim_y(area, soul, step, 2, 10.0)
	var x := area.position.x + 8 if from_left else area.end.x - 8
	var tray := _bullet(enemy, parent, area, Vector2(x, y))
	tray.shape = "card"
	tray.size = 16.0
	tray.color = Color(0.7, 0.72, 0.78)
	tray.delay = 0.35
	tray.velocity = Vector2(150 if from_left else -150, randf_range(-30, 30))
	if step % 2 == 0:
		tray.velocity = (soul - tray.position).normalized() * 150.0
	return 0.7


## Mystery Meat: a spoonful of peas flicked at the SOUL, spreading out.
static func _peas(enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2) -> float:
	var start := Vector2(randf_range(area.position.x + 10, area.end.x - 10), area.position.y + 4)
	var aim := (soul_position - start).normalized()
	for spread in [-0.4, -0.2, 0.0, 0.2, 0.4]:
		var pea := _bullet(enemy, parent, area, start)
		pea.shape = "ball"
		pea.size = 5.0
		pea.color = Color(0.45, 0.8, 0.3)
		pea.velocity = aim.rotated(spread) * 110.0
	return 1.0


## Tardy Bell: a ring of notes bursts out from a spot on the edge of the box.
static func _ring(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var center := Vector2(_aim_x(area, soul, step, 2, 20.0), area.position.y + 6)
	var offset := (soul - center).angle()
	for i in 10:
		var note := _bullet(enemy, parent, area, center)
		note.shape = "star"
		note.size = 7.0
		note.color = Color(1.0, 0.9, 0.4)
		note.velocity = Vector2.from_angle(offset + i * TAU / 10) * 80.0
	return 1.0


## Tardy Bell: rings of sound roll down the box, each with a quiet gap in it.
static func _sound_waves(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2) -> float:
	var gap := randf_range(area.position.x + 20, area.end.x - 20)
	gap = _away_from(gap, soul.x, area.position.x + 20, area.end.x - 20)
	var x := area.position.x + 4
	while x < area.end.x - 2:
		if absf(x - gap) > 16:
			var wave := _bullet(enemy, parent, area, Vector2(x, area.position.y + 4))
			wave.size = 5.0
			wave.color = Color(1.0, 0.95, 0.6)
			wave.velocity = Vector2(0, 70)
		x += 9
	return 1.25


## Tardy Bell: the alarm goes off. A line flickers across the box, then blasts.
static func _alarm(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var horizontal := step % 2 == 0
	# Every alarm goes off right through the SOUL.
	var at := soul.clamp(area.position + Vector2(10, 10), area.end - Vector2(10, 10))
	_beam(enemy, parent, area, at, Vector2.RIGHT if horizontal else Vector2.DOWN, 0.7, Color(1.0, 0.85, 0.2))
	return 0.85


## Tardy Bell: SONAR. Rings of sound pulse out from a corner of the box, one after
## another. Each ring has a quiet gap in it, aimed somewhere different: slip through it.
static func _sonar(enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2) -> float:
	var corners := [area.position, Vector2(area.end.x, area.position.y), Vector2(area.get_center().x, area.position.y)]
	var from: Vector2 = corners[randi() % corners.size()]
	var ring := _bullet(enemy, parent, area, from)
	ring.shape = "ring"
	ring.size = 4.0
	ring.color = Color(1.0, 0.9, 0.45)
	ring.delay = 0.25
	ring.ring_speed = 75.0
	# The gap points near the SOUL, but not right at it, so you still have to move.
	ring.gap_angle = (soul_position - from).angle() + randf_range(0.45, 0.85) * (1.0 if randf() < 0.5 else -1.0)
	ring.gap_width = 0.55
	Game.play_sfx("ping")
	return 0.95


## Tardy Bell: the CLAPPER swings across the box like a pendulum, ringing out
## little notes at the top of each swing.
static func _clapper(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	if step == 0:
		var clapper := _bullet(enemy, parent, area, Vector2(area.get_center().x, area.position.y + 2))
		clapper.shape = "clapper"
		clapper.size = 9.0
		clapper.color = Color(0.95, 0.8, 0.3)
		clapper.delay = 0.6
		clapper.lifetime = 3.6
		clapper.swing_length = area.size.y * 0.82
		clapper.swing_amplitude = 0.95
		clapper.swing_speed = 2.6
		clapper.bounds = Rect2()
		return 0.9
	# Notes ding out from the sides as it swings.
	var from_left := step % 2 == 0
	var note := _bullet(enemy, parent, area, Vector2(area.position.x + 6 if from_left else area.end.x - 6, area.position.y + 30))
	note.shape = "star"
	note.size = 7.0
	note.color = Color(1.0, 0.9, 0.4)
	note.velocity = (soul - note.position).normalized() * 85.0
	return 0.6


## Overdue Book: loose pages flutter down, drifting side to side.
static func _pages(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := _aim_x(area, soul, step, 3, 8.0)
	var page := _bullet(enemy, parent, area, Vector2(x, area.position.y + 4))
	page.shape = "card"
	page.size = 11.0
	page.color = Color(0.95, 0.92, 0.82)
	page.velocity = Vector2(0, 60)
	page.sway = 60.0
	return 0.3


## Overdue Book: bookmarks shoot straight at the SOUL (after a quick flash).
static func _bookmark(enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2) -> float:
	var from_left := randf() < 0.5
	var start := Vector2(area.position.x + 4 if from_left else area.end.x - 4, randf_range(area.position.y + 6, area.end.y - 6))
	var mark := _bullet(enemy, parent, area, start)
	mark.shape = "arrow"
	mark.size = 9.0
	mark.color = Color(0.85, 0.25, 0.3)
	mark.delay = 0.4
	mark.velocity = (soul_position - start).normalized() * 170.0
	return 0.6


## Overdue Book: a whole shelf of books slides across. Squeeze through the gap.
static func _shelf(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from_left := step % 2 == 0
	var x := area.position.x + 4 if from_left else area.end.x - 4
	var gap := randf_range(area.position.y + 20, area.end.y - 20)
	gap = _away_from(gap, soul.y, area.position.y + 20, area.end.y - 20)
	var colors := [Color(0.7, 0.25, 0.25), Color(0.25, 0.45, 0.7), Color(0.3, 0.6, 0.35), Color(0.75, 0.6, 0.25)]
	var y := area.position.y + 6
	var i := 0
	while y < area.end.y - 2:
		if absf(y - gap) > 17:
			var book := _bullet(enemy, parent, area, Vector2(x, y))
			book.size = 9.0
			book.color = colors[i % colors.size()]
			book.velocity = Vector2(90 if from_left else -90, 0)
		y += 11
		i += 1
	return 1.6


## Wally gets more fired up once he's below half health: his attacks come 15% faster.
static func _pep(enemy: Enemy) -> float:
	return 0.85 if enemy.hp < enemy.max_hp / 2 else 1.0


## Wally (miniboss): the bleachers rise. A row comes up from the floor with a gap in it.
static func _bleacher_wave(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2) -> float:
	var gap := randf_range(area.position.x + 18, area.end.x - 18)
	# The gap never opens where the SOUL already is: you always have to move to it.
	gap = _away_from(gap, soul.x, area.position.x + 18, area.end.x - 18)
	var x := area.position.x + 5
	while x < area.end.x - 2:
		if absf(x - gap) > 15:
			var seat := _bullet(enemy, parent, area, Vector2(x, area.end.y - 5))
			seat.size = 8.0
			seat.color = Color(0.65, 0.66, 0.72)
			seat.delay = 0.35
			seat.velocity = Vector2(0, -95)
		x += 10
	return 1.0 * _pep(enemy)


## Wally (miniboss): a spinning mascot twirl that flings claws out in a spiral.
static func _mascot_spin(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var center := Vector2(area.get_center().x, area.position.y + 8)
	for arm in 2:
		# Two arms sweeping back and forth, always flinging downward into the box.
		var angle := PI / 2 + sin(step * 0.35 + arm * PI) * 1.2
		var claw := _bullet(enemy, parent, area, center)
		claw.shape = "claw"
		claw.size = 8.0
		claw.color = Color(1.0, 0.95, 0.85)
		claw.velocity = Vector2.from_angle(angle) * 135.0
	# Every so often, one claw is flung straight at the SOUL.
	if step % 5 == 4:
		var aimed := _bullet(enemy, parent, area, center)
		aimed.shape = "claw"
		aimed.size = 8.0
		aimed.color = Color(1.0, 0.6, 0.5)
		aimed.velocity = (soul - center).normalized() * 150.0
	return 0.15 * _pep(enemy)


## Wally (miniboss): FRENZY. Claws and dodgeballs at the same time, faster than usual.
static func _frenzy(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	if step % 2 == 0:
		_claw_drop(enemy, parent, area, soul, step / 2)
	else:
		_dodgeballs(enemy, parent, area, soul, step)
	return 0.45 * _pep(enemy)


## Wally: a shower of colorful confetti.
static func _confetti(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var colors := [Color(1, 0.3, 0.3), Color(1, 0.85, 0.2), Color(0.3, 0.8, 1), Color(0.5, 1, 0.4), Color(1, 0.5, 1)]
	var x := _aim_x(area, soul, step, 4, 4.0)
	var bit := _bullet(enemy, parent, area, Vector2(x, area.position.y + 3))
	bit.size = 4.0
	bit.color = colors.pick_random()
	bit.velocity = Vector2(0, randf_range(95, 135))
	bit.sway = 35.0
	return 0.11 * _pep(enemy)


## Wally: a giant foam finger swings across the box (after a warning).
static func _foam_finger(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from_left := step % 2 == 0
	# Every finger swings through the SOUL's row.
	var y := clampf(soul.y + randf_range(-5, 5), area.position.y + 12, area.end.y - 12)
	var x := area.position.x + 10 if from_left else area.end.x - 10
	var finger := _bullet(enemy, parent, area, Vector2(x, y))
	finger.shape = "finger"
	finger.size = 18.0
	finger.color = Color(1.0, 0.85, 0.2)
	finger.delay = 0.5
	finger.velocity = Vector2(220 if from_left else -220, 0)
	return 0.75 * _pep(enemy)


## Wally: red dodgeballs. Some roll in from the sides, some drop from the top,
## and every ball bounces to its own height (and a little differently each bounce).
static func _dodgeballs(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var ball: Bullet
	if randf() < 0.5:
		# From the side, thrown in a random arc.
		var from_left := step % 2 == 0
		var x := area.position.x + 8 if from_left else area.end.x - 8
		ball = _bullet(enemy, parent, area, Vector2(x, area.end.y - 12))
		ball.velocity = Vector2(randf_range(50, 110) * (1 if from_left else -1), -randf_range(110, 250))
	else:
		# Dropped from the top, drifting a little sideways.
		var x := _aim_x(area, soul, step, 2, 15.0)
		ball = _bullet(enemy, parent, area, Vector2(x, area.position.y + 8))
		ball.velocity = Vector2(randf_range(-45, 45), randf_range(10, 60))
	if step % 3 == 2:
		var from_left := randf() < 0.5
		var start := Vector2(area.position.x + 8 if from_left else area.end.x - 8, area.end.y - 12)
		ball.position = start
		var rise := maxf(start.y - soul.y, 10.0)
		var up := sqrt(2.0 * 330.0 * rise)
		ball.velocity = Vector2((soul.x - start.x) / (up / 330.0), -up)
		if start.y - soul.y < 10.0:
			# The SOUL is down low: skim it along the floor instead.
			ball.position.y = soul.y
			ball.velocity = Vector2(190.0 if from_left else -190.0, -40.0)
	ball.shape = "ball"
	ball.size = randf_range(12.0, 16.0)
	ball.color = Color(0.85, 0.15, 0.15)
	ball.acceleration = Vector2(0, 330)
	ball.bounce_speed = randf_range(110, 250)
	ball.bounce_variance = 0.15
	return 0.8 * _pep(enemy)


## Wally: CLAW SWIPE. Three claw marks rake through right where the SOUL is (they
## flash as scratches first), and a moment later a second set rakes back the other
## way, crossing the first. Dodge one, then dodge again.
static func _claw_swipe(enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2) -> float:
	var tilt := randf_range(0.45, 0.8) * (1.0 if randf() < 0.5 else -1.0)
	var warn := 0.42 * _pep(enemy)
	for pass_index in 2:
		var direction := Vector2.RIGHT.rotated(tilt if pass_index == 0 else -tilt)
		var aim := soul_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		var across := direction.orthogonal()
		for line in 3:
			var through := aim + across * (line - 1) * 14.0
			var slash := _beam(enemy, parent, area, through, direction, warn + pass_index * 0.4 + line * 0.04, Color(1.0, 0.92, 0.75))
			slash.shape = "claw_slash"
			slash.size = 7.0
			slash.lifetime = 0.2
	return 1.05 * _pep(enemy)


## Wally: sets of three claws plunge down from the top (they flash first).
static func _claw_drop(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	# Every other set lands with its middle claw on the SOUL.
	var x := randf_range(area.position.x + 14, area.end.x - 34)
	if step % 2 == 0:
		x = clampf(soul.x - 10, area.position.x + 14, area.end.x - 34)
	for i in 3:
		var claw := _bullet(enemy, parent, area, Vector2(x + i * 10, area.position.y + 8))
		claw.shape = "claw"
		claw.size = 9.0
		claw.color = Color(1.0, 0.95, 0.85)
		claw.delay = 0.45
		claw.velocity = Vector2(0, 260)
	return 0.6 * _pep(enemy)


# --- Hopkuna ------------------------------------------------------------------
# Every Hopkuna attack is aimed at where the SOUL is, shows a warning first,
# and gets faster each turn (enemy.fury counts his turns).

const HOPKUNA_RED := Color(1.0, 0.18, 0.25)
const EMBER := Color(1.0, 0.45, 0.15)


## How much faster Hopkuna is this turn: 1.0 at first, down to 0.65 (35% faster).
static func _haste(enemy: Enemy) -> float:
	return 1.0 - 0.07 * mini(enemy.fury, 5)


static func _soul(parent: Node) -> Node2D:
	return parent.get_node_or_null("Soul") as Node2D


## A glowing slash across the whole box, along `direction`, through `through`.
## A thin flickering line shows where it will land, then it cuts for a moment.
static func _beam(enemy: Enemy, parent: Node, area: Rect2, through: Vector2, direction: Vector2, delay: float, color: Color = HOPKUNA_RED) -> Bullet:
	# Find where the line through `through` enters and leaves the box, so the
	# slash reaches exactly from one wall to the other.
	var dir := direction.normalized()
	var inner := area.grow(-2)
	var t_min := -INF
	var t_max := INF
	for axis in 2:
		if absf(dir[axis]) < 0.0001:
			continue
		var t1 := (inner.position[axis] - through[axis]) / dir[axis]
		var t2 := (inner.end[axis] - through[axis]) / dir[axis]
		t_min = maxf(t_min, minf(t1, t2))
		t_max = minf(t_max, maxf(t1, t2))
	var from := through + dir * t_min
	var to := through + dir * t_max

	var beam := _bullet(enemy, parent, area, (from + to) / 2)
	beam.shape = "beam"
	beam.size = 9.0
	beam.color = color
	beam.beam_vector = (to - from) / 2
	beam.delay = delay
	beam.lifetime = 0.22
	# Beams are as long as the box is wide; keep them from being removed for "leaving" it.
	beam.bounds = Rect2()
	return beam


## Hopkuna: CLEAVE. One slash right through the SOUL, and a second one close by.
static func _cleave(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var soul := _soul(parent)
	var y := soul.global_position.y if soul else area.get_center().y
	var horizontal := randf() < 0.65
	var warn := 0.55 * _haste(enemy)
	if horizontal:
		_beam(enemy, parent, area, Vector2(area.get_center().x, y), Vector2.RIGHT, warn)
		var other_y := clampf(y + (36.0 if randf() < 0.5 else -36.0), area.position.y + 6, area.end.y - 6)
		_beam(enemy, parent, area, Vector2(area.get_center().x, other_y), Vector2.RIGHT, warn + 0.2)
	else:
		var x := soul.global_position.x if soul else area.get_center().x
		_beam(enemy, parent, area, Vector2(x, area.get_center().y), Vector2.DOWN, warn)
		var other_x := clampf(x + (36.0 if randf() < 0.5 else -36.0), area.position.x + 6, area.end.x - 6)
		_beam(enemy, parent, area, Vector2(other_x, area.get_center().y), Vector2.DOWN, warn + 0.2)
	return 0.9 * _haste(enemy)


## Hopkuna: SLASH GRID. Three slashes cross right where the SOUL is (across, down,
## and diagonal), each a beat after the last, so you have to keep moving.
static func _slash_grid(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var soul := _soul(parent)
	var at := soul.global_position if soul else area.get_center()
	var directions := [Vector2.RIGHT, Vector2.DOWN, Vector2(1, 1 if randf() < 0.5 else -1)]
	directions.shuffle()
	var warn := 0.6 * _haste(enemy)
	for i in directions.size():
		_beam(enemy, parent, area, at, directions[i], warn + i * 0.28)
	return 1.6 * _haste(enemy)


## Hopkuna: RED ARROWS. A volley of three arrows from one spot on the edge.
## They lock on, fire, and curve toward the SOUL for a moment.
static func _red_arrows(enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2) -> float:
	var start: Vector2
	match randi() % 3:
		0: start = Vector2(randf_range(area.position.x, area.end.x), area.position.y + 4)
		1: start = Vector2(area.position.x + 4, randf_range(area.position.y, area.end.y))
		_: start = Vector2(area.end.x - 4, randf_range(area.position.y, area.end.y))
	var aim := (soul_position - start).normalized()
	for spread in [-0.28, 0.0, 0.28]:
		var arrow := _bullet(enemy, parent, area, start)
		arrow.shape = "arrow"
		arrow.size = 10.0
		arrow.color = HOPKUNA_RED
		arrow.delay = 0.35 * _haste(enemy)
		arrow.velocity = aim.rotated(spread) * 200.0
		arrow.homing = _soul(parent)
		arrow.homing_time = 0.35
		arrow.turn_rate = 2.5
		arrow.trail_length = 6
		arrow.glow = true
	return 0.8 * _haste(enemy)


## Hopkuna: CLOSING RING. Shards appear in a circle around the SOUL and collapse
## inward. Two neighboring shards are missing: that gap is your way out.
static func _burst(enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2) -> float:
	const COUNT := 14
	var gap := randi() % COUNT
	for i in COUNT:
		if i == gap or i == (gap + 1) % COUNT:
			continue
		var angle := i * TAU / COUNT
		var spot := soul_position + Vector2.from_angle(angle) * 62.0
		# Keep the shards inside the box.
		spot = spot.clamp(area.position + Vector2(4, 4), area.end - Vector2(4, 4))
		var shard := _bullet(enemy, parent, area, spot)
		shard.shape = "star"
		shard.size = 7.0
		shard.color = HOPKUNA_RED
		shard.delay = 0.65 * _haste(enemy)
		shard.velocity = (soul_position - spot).normalized() * 115.0
		shard.trail_length = 5
		shard.glow = true
	return 1.6 * _haste(enemy)


## Hopkuna: FLAMING ARROW. One big burning arrow that chases the SOUL before it commits.
static func _fire_arrow(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var x := randf_range(area.position.x + 10, area.end.x - 10)
	var arrow := _bullet(enemy, parent, area, Vector2(x, area.position.y + 6))
	arrow.shape = "arrow"
	arrow.size = 15.0
	arrow.damage = enemy.attack + 1
	arrow.color = EMBER
	arrow.delay = 0.4 * _haste(enemy)
	arrow.velocity = Vector2(0, 150)
	arrow.homing = _soul(parent)
	arrow.homing_time = 1.1
	arrow.turn_rate = 2.2
	arrow.trail_length = 12
	arrow.glow = true
	return 1.1 * _haste(enemy)
