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
