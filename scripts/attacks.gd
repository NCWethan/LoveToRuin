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
		"tumble":
			return _tumble(enemy, parent, area, step)
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


## The Mascot: a shower of colorful confetti.
static func _confetti(enemy: Enemy, parent: Node, area: Rect2) -> float:
	var colors := [Color(1, 0.3, 0.3), Color(1, 0.85, 0.2), Color(0.3, 0.8, 1), Color(0.5, 1, 0.4), Color(1, 0.5, 1)]
	var x := randf_range(area.position.x + 4, area.end.x - 4)
	var bit := _bullet(enemy, parent, area, Vector2(x, area.position.y + 3))
	bit.size = 4.0
	bit.color = colors.pick_random()
	bit.velocity = Vector2(0, randf_range(80, 120))
	bit.sway = 35.0
	return 0.14


## The Mascot: a giant foam finger swings across the box (after a warning).
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


## The Mascot: its big round head comes bouncing across the box.
static func _tumble(enemy: Enemy, parent: Node, area: Rect2, step: int) -> float:
	var from_left := step % 2 == 0
	var x := area.position.x + 8 if from_left else area.end.x - 8
	var ball := _bullet(enemy, parent, area, Vector2(x, area.end.y - 12))
	ball.shape = "ball"
	ball.size = 15.0
	ball.color = Color(0.6, 0.12, 0.12)
	ball.velocity = Vector2(70 if from_left else -70, -180)
	ball.acceleration = Vector2(0, 330)
	ball.bounce_speed = randf_range(170, 210)
	return 1.4
