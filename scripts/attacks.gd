class_name Attacks
extends RefCounted
## Every enemy attack pattern. Each enemy lists the patterns it knows (in
## tutorial_battle.gd) and uses a different one each turn.
##
## spawn() is called whenever a pattern's timer runs out. It adds bullets to the
## battle and returns how many seconds to wait before it's called again.
## `step` counts how many times it's been called this turn (0, 1, 2, ...).


static func spawn(pattern: String, enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2, step: int) -> float:
	match pattern:
		"rain":
			return _rain(enemy, parent, area)
		"egg_drop":
			return _egg_drop(enemy, parent, area)
		"bunny_hop":
			return _bunny_hop(enemy, parent, area, step)
		"lance":
			return _lance(enemy, parent, area)
		"sweep":
			return _sweep(enemy, parent, area, step)
		"aimed":
			return _aimed(enemy, parent, area, soul_position)
		"pencils":
			return _pencils(enemy, parent, area)
		"bubbles":
			return _bubbles(enemy, parent, area, soul_position)
		"papers":
			return _papers(enemy, parent, area)
		"zoom":
			return _zoom(enemy, parent, area, step)
		"confetti":
			return _confetti(enemy, parent, area)
		"foam_finger":
			return _foam_finger(enemy, parent, area, step)
		"dodgeballs":
			return _dodgeballs(enemy, parent, area, step)
		"claw_swipe":
			return _claw_swipe(enemy, parent, area)
		"claw_drop":
			return _claw_drop(enemy, parent, area)
		"cleave":
			return _cleave(enemy, parent, area)
		"slash_grid":
			return _slash_grid(enemy, parent, area)
		"red_arrows":
			return _red_arrows(enemy, parent, area, soul_position)
		"burst":
			return _burst(enemy, parent, area, soul_position)
		"fire_arrow":
			return _fire_arrow(enemy, parent, area)
	return 1.0


static func _bullet(enemy: Enemy, parent: Node, area: Rect2, at: Vector2) -> Bullet:
	var bullet := Bullet.new()
	bullet.damage = enemy.attack
	bullet.bounds = area
	bullet.position = at
	parent.add_child(bullet)
	return bullet


## Eggo: pellets falling straight down from the top of the box.
static func _rain(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var x := randf_range(area.position.x + 4, area.end.x - 4)
	var bullet := _bullet(enemy, parent, area, Vector2(x, area.position.y + 3))
	bullet.velocity = Vector2(0, enemy.bullet_speed)
	return 0.42


## Eggo: big eggs drop and speed up as they fall, then crack into
## scattering bits of yolk when they hit the bottom.
static func _egg_drop(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var x := randf_range(area.position.x + 10, area.end.x - 10)
	var egg := _bullet(enemy, parent, area, Vector2(x, area.position.y + 6))
	egg.shape = "egg"
	egg.size = 11.0
	egg.color = Color(0.97, 0.95, 0.85)
	egg.velocity = Vector2(0, 20)
	egg.acceleration = Vector2(0, 170)
	egg.splits_into = 4
	return 0.85


## Eggo: Eggo's bunny friend's... friends. They hop across the bottom of the box.
static func _bunny_hop(enemy: Enemy, parent: Node, area: Rect2, step: int) -> float:
	var from_left := step % 2 == 0
	var x := area.position.x + 5 if from_left else area.end.x - 5
	var bunny := _bullet(enemy, parent, area, Vector2(x, area.end.y - 8))
	bunny.shape = "bunny"
	bunny.size = 9.0
	bunny.velocity = Vector2(75 if from_left else -75, -170)
	bunny.acceleration = Vector2(0, 340)
	bunny.bounce_speed = randf_range(150, 200)
	return 0.9


## BigJoe6: fast pellets flying in from the left or right.
static func _lance(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var y := randf_range(area.position.y + 4, area.end.y - 4)
	var from_left := randf() < 0.5
	var x := area.position.x + 3 if from_left else area.end.x - 3
	var bullet := _bullet(enemy, parent, area, Vector2(x, y))
	bullet.velocity = Vector2(enemy.bullet_speed if from_left else -enemy.bullet_speed, 0)
	return 0.5


## BigJoe6: a whole wall of bullets sweeps across the box. Dodge through the gap!
static func _sweep(enemy: Enemy, parent: Node, area: Rect2, step: int) -> float:
	var from_left := step % 2 == 0
	var x := area.position.x + 3 if from_left else area.end.x - 3
	var gap := randf_range(area.position.y + 22, area.end.y - 22)
	var y := area.position.y + 4
	while y < area.end.y - 2:
		if absf(y - gap) > 18:
			var bullet := _bullet(enemy, parent, area, Vector2(x, y))
			bullet.velocity = Vector2(85 if from_left else -85, 0)
			bullet.color = Color(1.0, 0.75, 0.75)
		y += 10
	return 1.7


## BigJoe6: "Justice Strike!" Spinning stars launched right at where the SOUL is.
static func _aimed(enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2) -> float:
	var start: Vector2
	match randi() % 3:
		0: start = Vector2(randf_range(area.position.x, area.end.x), area.position.y + 3)
		1: start = Vector2(area.position.x + 3, randf_range(area.position.y, area.end.y))
		_: start = Vector2(area.end.x - 3, randf_range(area.position.y, area.end.y))
	var star := _bullet(enemy, parent, area, start)
	star.shape = "star"
	star.size = 9.0
	star.color = Color(1.0, 0.45, 0.45)
	star.velocity = (soul_position - start).normalized() * 125.0
	return 0.65


# --- Westview High School ---------------------------------------------------

## Pop Quiz: pencils rain down at an angle.
static func _pencils(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var x := randf_range(area.position.x + 6, area.end.x - 6)
	var pencil := _bullet(enemy, parent, area, Vector2(x, area.position.y + 4))
	pencil.shape = "pencil"
	pencil.size = 8.0
	pencil.velocity = Vector2(randf_range(-45, 45), 125)
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
static func _papers(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var x := randf_range(area.position.x + 10, area.end.x - 10)
	var card := _bullet(enemy, parent, area, Vector2(x, area.position.y + 4))
	card.shape = "card"
	card.size = 10.0
	card.color = Color(0.8, 0.6, 0.35)
	card.velocity = Vector2(0, 70)
	card.sway = 45.0
	return 0.35


## Hall Pass: a warning shows which row it'll dash down, then it ZOOMS across.
static func _zoom(enemy: Enemy, parent: Node, area: Rect2, step: int) -> float:
	var from_left := step % 2 == 0
	var y := randf_range(area.position.y + 8, area.end.y - 8)
	var x := area.position.x + 6 if from_left else area.end.x - 6
	var card := _bullet(enemy, parent, area, Vector2(x, y))
	card.shape = "card"
	card.size = 14.0
	card.color = Color(0.8, 0.6, 0.35)
	card.delay = 0.6
	card.velocity = Vector2(260 if from_left else -260, 0)
	return 0.75


## Wally: a shower of colorful confetti.
static func _confetti(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var colors := [Color(1, 0.3, 0.3), Color(1, 0.85, 0.2), Color(0.3, 0.8, 1), Color(0.5, 1, 0.4), Color(1, 0.5, 1)]
	var x := randf_range(area.position.x + 4, area.end.x - 4)
	var bit := _bullet(enemy, parent, area, Vector2(x, area.position.y + 3))
	bit.size = 4.0
	bit.color = colors.pick_random()
	bit.velocity = Vector2(0, randf_range(80, 120))
	bit.sway = 35.0
	return 0.14


## Wally: a giant foam finger swings across the box (after a warning).
static func _foam_finger(enemy: Enemy, parent: Node, area: Rect2, step: int) -> float:
	var from_left := step % 2 == 0
	var y := randf_range(area.position.y + 12, area.end.y - 12)
	var x := area.position.x + 10 if from_left else area.end.x - 10
	var finger := _bullet(enemy, parent, area, Vector2(x, y))
	finger.shape = "finger"
	finger.size = 18.0
	finger.color = Color(1.0, 0.85, 0.2)
	finger.delay = 0.5
	finger.velocity = Vector2(190 if from_left else -190, 0)
	return 0.9


## Wally: red dodgeballs. Some roll in from the sides, some drop from the top,
## and every ball bounces to its own height (and a little differently each bounce).
static func _dodgeballs(enemy: Enemy, parent: Node, area: Rect2, step: int) -> float:
	var ball: Bullet
	if randf() < 0.5:
		# From the side, thrown in a random arc.
		var from_left := step % 2 == 0
		var x := area.position.x + 8 if from_left else area.end.x - 8
		ball = _bullet(enemy, parent, area, Vector2(x, area.end.y - 12))
		ball.velocity = Vector2(randf_range(50, 110) * (1 if from_left else -1), -randf_range(110, 250))
	else:
		# Dropped from the top, drifting a little sideways.
		var x := randf_range(area.position.x + 15, area.end.x - 15)
		ball = _bullet(enemy, parent, area, Vector2(x, area.position.y + 8))
		ball.velocity = Vector2(randf_range(-45, 45), randf_range(10, 60))
	ball.shape = "ball"
	ball.size = randf_range(12.0, 16.0)
	ball.color = Color(0.85, 0.15, 0.15)
	ball.acceleration = Vector2(0, 330)
	ball.bounce_speed = randf_range(110, 250)
	ball.bounce_variance = 0.15
	return 1.0


## Wally: three claw marks flash as a warning across the box, then slash for a moment.
static func _claw_swipe(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var down_right := randf() < 0.5
	var base := randf_range(-area.size.y * 0.5, area.size.y * 0.5)
	for line in 3:
		var offset := base + (line - 1) * 16.0
		var t := 0.0
		while t <= area.size.x:
			var x := area.position.x + t
			var y := (area.position.y + offset + t * 0.75) if down_right else (area.end.y - offset - t * 0.75)
			if y > area.position.y + 3 and y < area.end.y - 3:
				var mark := _bullet(enemy, parent, area, Vector2(x, y))
				mark.size = 5.0
				mark.color = Color(1.0, 0.95, 0.85)
				mark.delay = 0.6
				mark.lifetime = 0.3
			t += 7.0
	return 1.2


## Wally: sets of three claws plunge down from the top (they flash first).
static func _claw_drop(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var x := randf_range(area.position.x + 14, area.end.x - 34)
	for i in 3:
		var claw := _bullet(enemy, parent, area, Vector2(x + i * 10, area.position.y + 8))
		claw.shape = "claw"
		claw.size = 9.0
		claw.color = Color(1.0, 0.95, 0.85)
		claw.delay = 0.45
		claw.velocity = Vector2(0, 230)
	return 0.75


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
static func _beam(enemy: Enemy, parent: Node, area: Rect2, through: Vector2, direction: Vector2, delay: float) -> void:
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
	beam.color = HOPKUNA_RED
	beam.beam_vector = (to - from) / 2
	beam.delay = delay
	beam.lifetime = 0.22
	# Beams are as long as the box is wide; keep them from being removed for "leaving" it.
	beam.bounds = Rect2()


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
