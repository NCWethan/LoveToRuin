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

const HOPKUNA_RED := Color(1.0, 0.22, 0.28)


## A straight slash: a line of marks that flashes as a warning, then cuts for a moment.
static func _slash_line(enemy: Enemy, parent: Node, area: Rect2, from: Vector2, to: Vector2, delay: float) -> void:
	var length := from.distance_to(to)
	var t := 0.0
	while t <= length:
		var mark := _bullet(enemy, parent, area, from.lerp(to, t / length))
		mark.size = 5.0
		mark.color = HOPKUNA_RED
		mark.delay = delay
		mark.lifetime = 0.25
		t += 7.0


## Hopkuna: two horizontal slashes across the box.
static func _cleave(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var first := randf_range(area.position.y + 8, area.end.y - 8)
	var second := fposmod(first - area.position.y + area.size.y * 0.5, area.size.y - 16) + area.position.y + 8
	for y in [first, second]:
		_slash_line(enemy, parent, area, Vector2(area.position.x + 3, y), Vector2(area.end.x - 3, y), 0.6)
	return 1.0


## Hopkuna: a crisscross of slashes, some across and some up-and-down.
static func _slash_grid(enemy: Enemy, parent: Node, area: Rect2) -> float:
	for i in 3:
		if randf() < 0.5:
			var y := randf_range(area.position.y + 8, area.end.y - 8)
			_slash_line(enemy, parent, area, Vector2(area.position.x + 3, y), Vector2(area.end.x - 3, y), 0.7)
		else:
			var x := randf_range(area.position.x + 8, area.end.x - 8)
			_slash_line(enemy, parent, area, Vector2(x, area.position.y + 3), Vector2(x, area.end.y - 3), 0.7)
	return 1.4


## Hopkuna: arrows appear at the edge, lock onto the SOUL, then fire.
static func _red_arrows(enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2) -> float:
	var start: Vector2
	match randi() % 3:
		0: start = Vector2(randf_range(area.position.x, area.end.x), area.position.y + 4)
		1: start = Vector2(area.position.x + 4, randf_range(area.position.y, area.end.y))
		_: start = Vector2(area.end.x - 4, randf_range(area.position.y, area.end.y))
	var arrow := _bullet(enemy, parent, area, start)
	arrow.shape = "arrow"
	arrow.size = 10.0
	arrow.color = HOPKUNA_RED
	arrow.delay = 0.35
	arrow.velocity = (soul_position - start).normalized() * 170.0
	return 0.5


## Hopkuna: a ring of shards bursts outward from one spot.
static func _burst(enemy: Enemy, parent: Node, area: Rect2, soul_position: Vector2) -> float:
	var center := Vector2(randf_range(area.position.x + 20, area.end.x - 20), randf_range(area.position.y + 20, area.end.y - 20))
	if center.distance_to(soul_position) < 40:
		center = area.get_center() + (area.get_center() - soul_position).normalized() * 40
	for i in 10:
		var shard := _bullet(enemy, parent, area, center)
		shard.size = 6.0
		shard.color = HOPKUNA_RED
		shard.shape = "star"
		shard.delay = 0.5
		shard.velocity = Vector2.from_angle(i * TAU / 10 + randf() * 0.3) * 100.0
	return 1.5
