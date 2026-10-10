class_name DowntownAttacks
extends RefCounted
## Downtown (fragment 7): the people on the street, the Big Screen in the
## ballpark, and Supreme (on the Genocide path). Works like Attacks.spawn():
## adds bullets, and returns how many seconds until it's called again (or -1 for
## a pattern it doesn't know).

const LED := Color(1.0, 0.85, 0.3)
const LED_RED := Color(1.0, 0.3, 0.3)
const LED_GREEN := Color(0.4, 1.0, 0.5)
const CHALK := Color(0.85, 0.9, 1.0)
const SUPREME := Color(0.72, 0.5, 1.0)

## What each attack is called, out loud (Supreme reads them, and labels his own).
const LABELS := {
	"instant_replay": "INSTANT REPLAY", "kiss_cam": "KISS CAM", "the_wave": "THE WAVE",
	"foul_ball": "FOUL BALL", "fireworks": "HOME RUN FIREWORKS", "scoreboard": "THE SCORE",
	"bell_curve": "BELL CURVE", "standard_deviation": "STANDARD DEVIATION", "pie_chart": "PIE CHART",
	"bar_graph": "BAR GRAPH", "scatter_plot": "SCATTER PLOT", "regression_line": "REGRESSION LINE",
	"margin_of_error": "MARGIN OF ERROR", "zero_point_four": "0.4%",
}
## The odds Supreme gives each of his own attacks of hitting you (he's usually right).
const ODDS := {
	"bell_curve": 68, "standard_deviation": 95, "pie_chart": 75, "bar_graph": 50,
	"scatter_plot": 33, "regression_line": 81, "margin_of_error": 97, "zero_point_four": 0,
}
## What Supreme says about what's coming (when he reads the Big Screen for you).
const HINTS := {
	"instant_replay": "It replays where you went last turn. Don't go there again.",
	"kiss_cam": "A heart closes around you. 1 gap. Find it.",
	"the_wave": "The crowd wave. It rolls through every row. Jump it.",
	"foul_ball": "Foul balls, arcing in. Watch the top.",
	"fireworks": "Fireworks. They go up, then they go EVERYWHERE.",
	"scoreboard": "Numbers falling. It's the score. We're losing.",
}


static func spawn(pattern: String, enemy: Enemy, parent: Node, area: Rect2, s: Vector2, step: int) -> float:
	match pattern:
		# --- Downtown townsfolk ---
		"hot_dog_toss": return _hot_dog_toss(enemy, parent, area, s, step)
		"mustard_squirt": return _mustard_squirt(enemy, parent, area, s, step)
		"frozen_pose": return _frozen_pose(enemy, parent, area, s, step)
		"tip_jar": return _tip_jar(enemy, parent, area, s, step)
		"rally_towel": return _rally_towel(enemy, parent, area, s, step)
		"peanut_shells": return _peanut_shells(enemy, parent, area, s, step)
		# --- The Big Screen ---
		"instant_replay": return _instant_replay(enemy, parent, area, s, step)
		"kiss_cam": return _kiss_cam(enemy, parent, area, s, step)
		"the_wave": return _the_wave(enemy, parent, area, s, step)
		"foul_ball": return _foul_ball(enemy, parent, area, s, step)
		"fireworks": return _fireworks(enemy, parent, area, s, step)
		"scoreboard": return _scoreboard(enemy, parent, area, s, step)
		# --- Supreme (Genocide) ---
		"bell_curve": return _bell_curve(enemy, parent, area, s, step)
		"standard_deviation": return _standard_deviation(enemy, parent, area, s, step)
		"pie_chart": return _pie_chart(enemy, parent, area, s, step)
		"bar_graph": return _bar_graph(enemy, parent, area, s, step)
		"scatter_plot": return _scatter_plot(enemy, parent, area, s, step)
		"regression_line": return _regression_line(enemy, parent, area, s, step)
		"margin_of_error": return _margin_of_error(enemy, parent, area, s, step)
		"zero_point_four": return _zero_point_four(enemy, parent, area, s, step)
	return -1.0


static func _glyph(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, glyph: String, size: float = 8.0) -> Bullet:
	return FolkAttacks._glyph(enemy, parent, area, at, glyph, size)


static func _dot(enemy: Enemy, parent: Node, area: Rect2, at: Vector2, color: Color, size: float = 6.0) -> Bullet:
	var b := Attacks._bullet(enemy, parent, area, at)
	b.size = size
	b.color = color
	return b


# --- Downtown townsfolk -----------------------------------------------------------------

## The Hot Dog Vendor: HOT DOGS, lobbed over the counter in high arcs. Every other
## one is aimed.
static func _hot_dog_toss(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var from := Vector2(area.position.x + 6 if left else area.end.x - 6, area.end.y - 10)
	var target := Attacks._aim_x(area, soul, step, 2)
	var dog := _glyph(enemy, parent, area, from, "hotdog", 10.0)
	var up := sqrt(640.0 * maxf((area.end.y - 10) - soul.y, 16.0)) if step % 2 == 0 else randf_range(220, 260)
	dog.velocity = Vector2((target - from.x) / (up / 320.0), -up)
	dog.acceleration = Vector2(0, 320)
	dog.spin = 6.0
	return 0.55


## The Hot Dog Vendor: MUSTARD. A squiggly yellow stream, side to side across the box.
static func _mustard_squirt(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var y := Attacks._aim_y(area, soul, step, 2)
	for i in 5:
		var blob := _dot(enemy, parent, area, Vector2(area.position.x + 4, y), Color(1.0, 0.85, 0.15), 6.0)
		blob.delay = 0.15 + i * 0.07
		blob.velocity = Vector2(120, 0)
		blob.zigzag = 2.5
	return 0.8


## The Living Statue: FROZEN POSE. Coins fly in, stop dead in mid-air (he's very
## good at not moving), then all start again at once.
static func _frozen_pose(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for i in 4:
		var at := Vector2(randf_range(area.position.x + 8, area.end.x - 8), area.position.y + 4)
		if i == 0:
			at.x = clampf(soul.x, area.position.x + 8, area.end.x - 8)
		var coin := _glyph(enemy, parent, area, at, "coin", 7.0)
		coin.velocity = Vector2(0, 90)
		coin.stop_after = 0.35
		var again := _glyph(enemy, parent, area, at + Vector2(0, 31), "coin", 7.0)
		again.delay = 1.0
		again.velocity = Vector2(0, 120)
	return 1.1


## The Living Statue: TIP JAR. He tips it over: coins spray out of a corner.
static func _tip_jar(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var left := step % 2 == 0
	var from := Vector2(area.position.x + 6 if left else area.end.x - 6, area.end.y - 6)
	var aim := (soul - from).angle()
	for i in 5:
		var coin := _glyph(enemy, parent, area, from, "coin", 6.0)
		coin.delay = 0.2
		coin.velocity = Vector2.from_angle(aim + (i - 2) * 0.18) * 115.0
		coin.acceleration = Vector2(0, 60)
	return 0.9


## The Superfan: RALLY TOWELS, whirling over his head and flung across.
static func _rally_towel(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(area.end.x - 6 if step % 2 == 0 else area.position.x + 6, Attacks._aim_y(area, soul, step, 2))
	var towel := _glyph(enemy, parent, area, from, "towel", 10.0)
	towel.delay = 0.2
	towel.velocity = Vector2(-110 if step % 2 == 0 else 110, 0)
	towel.spin = 10.0
	towel.sway = 30.0
	return 0.6


## The Superfan: PEANUT SHELLS, everywhere. He's been here since the first pitch.
static func _peanut_shells(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var x := Attacks._aim_x(area, soul, step, 3)
	var shell := _glyph(enemy, parent, area, Vector2(x, area.position.y + 4), "peanut", 7.0)
	shell.velocity = Vector2(randf_range(-20, 20), 60)
	shell.bounce_speed = 90
	shell.acceleration = Vector2(0, 150)
	shell.lifetime = 2.5
	return 0.28


# --- The Big Screen ----------------------------------------------------------------------

## INSTANT REPLAY: last turn, again. Lights come on along the path your SOUL took
## last turn, at the same moment you were there. (On the first turn, where you are.)
static func _instant_replay(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var path: Array = parent.get("_last_soul_path") if parent.get("_last_soul_path") != null else []
	var at := soul
	if not path.is_empty():
		at = path[mini(step * 2, path.size() - 1)]
	var pixel := _dot(enemy, parent, area, at.clamp(area.position + Vector2(5, 5), area.end - Vector2(5, 5)), LED, 11.0)
	pixel.delay = 0.3
	pixel.lifetime = 0.55
	pixel.glow = true
	# And a trail of replay pixels sliding along the old path.
	if step % 3 == 0:
		var chaser := _dot(enemy, parent, area, at.clamp(area.position + Vector2(5, 5), area.end - Vector2(5, 5)), LED_RED, 7.0)
		chaser.delay = 0.3
		chaser.velocity = (soul - at).normalized() * 70.0
	return 0.2


## KISS CAM: a heart frame closes in around you, with one gap.
static func _kiss_cam(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	const COUNT := 20
	var gap := randi() % COUNT
	for i in COUNT:
		if absi(i - gap) <= 1 or absi(i - gap) >= COUNT - 1:
			continue
		var t := i * TAU / COUNT
		# A heart curve.
		var heart := Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) * 3.6
		var spot := (soul + heart).clamp(area.position + Vector2(4, 4), area.end - Vector2(4, 4))
		var light := _dot(enemy, parent, area, spot, Color(1.0, 0.4, 0.6), 6.0)
		light.delay = 0.55
		light.velocity = (soul - spot).normalized() * 85.0
		light.glow = true
	return 1.4


## THE WAVE: the crowd (that isn't there) does the wave. Seats rise and fall
## across the box, row after row, one column at a time.
static func _the_wave(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var columns := 12
	var width := area.size.x / columns
	var c := step % columns if (step / columns) % 2 == 0 else columns - 1 - step % columns
	var x := area.position.x + width * (c + 0.5)
	# Every seat stands all the way up (and sits back down): time it.
	var height := area.size.y - 10.0
	var rise := 0.38
	var seat := _dot(enemy, parent, area, Vector2(x, area.end.y - 4), CHALK, width - 3)
	seat.velocity = Vector2(0, -2.0 * height / rise)
	seat.acceleration = Vector2(0, 2.0 * height / (rise * rise))
	seat.lifetime = rise * 2.0
	return 0.11


## FOUL BALL: baseballs, popped up off the screen, arcing into the box.
static func _foul_ball(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from := Vector2(randf_range(area.position.x + 10, area.end.x - 10), area.position.y + 4)
	var ball := Attacks._bullet(enemy, parent, area, from)
	ball.shape = "ball"
	ball.size = 9.0
	ball.color = Color(0.97, 0.95, 0.9)
	ball.delay = 0.25
	ball.velocity = Vector2((Attacks._aim_x(area, soul, step, 2) - from.x) * 1.4, 10)
	ball.acceleration = Vector2(0, 230)
	ball.bounce_speed = 120
	ball.wall_bounce = true
	ball.lifetime = 2.2
	return 0.45


## HOME RUN FIREWORKS: a rocket goes up from the bottom, and bursts where you are.
static func _fireworks(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var at := Vector2(clampf(soul.x + randf_range(-20, 20), area.position.x + 10, area.end.x - 10), clampf(soul.y + randf_range(-10, 10), area.position.y + 10, area.end.y - 10))
	var rocket := _dot(enemy, parent, area, Vector2(at.x, area.end.y - 4), LED, 5.0)
	rocket.velocity = Vector2(0, -(area.end.y - 4 - at.y) / 0.5)
	rocket.lifetime = 0.5
	rocket.trail_length = 6
	var colors := [LED, LED_RED, LED_GREEN, Color(0.5, 0.7, 1.0)]
	for i in 10:
		var spark := _dot(enemy, parent, area, at, colors[step % colors.size()], 5.0)
		spark.delay = 0.55
		spark.velocity = Vector2.from_angle(i * TAU / 10 + step) * 95.0
		spark.acceleration = Vector2(0, 50)
		spark.trail_length = 3
	return 0.9


## THE SCORE: the numbers fall off the scoreboard. (It's 0 to 7. We're the 0.)
static func _scoreboard(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var digit: String = ["0", "7"][step % 2]
	var x := Attacks._aim_x(area, soul, step, 2, 14.0) - 7
	for y in 5:
		for c in 3:
			if str(DIGITS[digit][y])[c] == "#":
				var bulb := _dot(enemy, parent, area, Vector2(x + c * 7, area.position.y + 4 + y * 7), LED if step % 2 == 0 else LED_RED, 6.0)
				bulb.delay = 0.3
				bulb.velocity = Vector2(0, 85)
	return 0.7


# --- Supreme (Genocide) -------------------------------------------------------------------
# A bullet-hell made of statistics. Every attack is labeled with its odds of hitting
# you (see ODDS: the label shows up over his head).

const DIGITS := {
	"0": ["###", "#.#", "#.#", "#.#", "###"], "4": ["#.#", "#.#", "###", "..#", "..#"],
	"7": ["###", "..#", ".#.", ".#.", ".#."], ".": ["...", "...", "...", "...", ".#."],
	"%": ["#.#", "..#", ".#.", "#..", "#.#"],
}


## BELL CURVE: a hill of points sweeps across the box. Highest in the middle,
## right where most people stand. (68% of you are within one standard deviation.)
static func _bell_curve(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var from_left := step % 2 == 0
	var mean := soul.y
	for i in 9:
		var z := (i - 4) / 2.0
		var height := exp(-z * z / 2.0)
		var y := clampf(mean + (i - 4) * 12.0, area.position.y + 4, area.end.y - 4)
		var point := _dot(enemy, parent, area, Vector2(area.position.x + 4 if from_left else area.end.x - 4, y), SUPREME, 5.0 + height * 4.0)
		point.delay = 0.3 + (1.0 - height) * 0.35
		point.velocity = Vector2(130.0 if from_left else -130.0, 0)
	return 0.75


## STANDARD DEVIATION: points scatter around you, close in a normal spread, and
## come in all at once.
static func _standard_deviation(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for i in 12:
		var offset := Vector2(randfn(0.0, 30.0), randfn(0.0, 22.0))
		if offset.length() < 22.0:
			offset = offset.normalized() * 22.0 if offset.length() > 0.1 else Vector2(22, 0)
		var spot := (soul + offset).clamp(area.position + Vector2(4, 4), area.end - Vector2(4, 4))
		var point := _dot(enemy, parent, area, spot, SUPREME, 5.0)
		point.delay = 0.6
		point.velocity = (soul - spot).normalized() * 70.0
	return 1.1


## PIE CHART: the box is a pie, and slices of it cut, one after another, around
## the middle. One slice is left.
static func _pie_chart(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var center := area.get_center()
	var skip := randi() % 6
	for i in 6:
		if i == skip:
			continue
		var angle := i * PI / 6.0 + step * 0.2
		Attacks._beam(enemy, parent, area, center, Vector2.from_angle(angle), 0.45 + i * 0.12, SUPREME)
	return 1.5


## BAR GRAPH: bars shoot up from the bottom of the box, all different heights. Then
## from the top. (Read the chart.)
static func _bar_graph(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var bars := 7
	var width := area.size.x / bars
	var from_top := step % 2 == 1
	for b in bars:
		var x := area.position.x + width * (b + 0.5)
		var height := area.size.y * randf_range(0.25, 0.8)
		if absf(x - soul.x) < width:
			height = maxf(height, absf((area.position.y if from_top else area.end.y) - soul.y) + 6)
		var y := area.position.y + 4.0
		var count := int(height / 9.0)
		for k in count:
			var at := Vector2(x, (area.position.y + 4 + k * 9) if from_top else (area.end.y - 4 - k * 9))
			var block := _dot(enemy, parent, area, at, Color(0.5, 0.85, 1.0) if b % 2 == 0 else SUPREME, width - 5)
			block.delay = 0.5 + k * 0.02
			block.lifetime = 0.5
		y += 0
	return 1.3


## SCATTER PLOT: dots everywhere, faint, and then they all move at once, to the
## right. (No correlation. That's the scary part.)
static func _scatter_plot(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	for i in 14:
		var spot := Vector2(randf_range(area.position.x + 4, area.end.x - 4), randf_range(area.position.y + 4, area.end.y - 4))
		if i == 0:
			spot = Vector2(area.position.x + 4, soul.y)
		var dot := _dot(enemy, parent, area, spot, SUPREME, 5.0)
		dot.delay = 0.7
		dot.velocity = Vector2.from_angle(randf_range(-0.4, 0.4) + (0.0 if step % 2 == 0 else PI)) * 80.0
	return 1.3


## REGRESSION LINE: he draws the line of best fit through where you've been. It
## goes right through where you are.
static func _regression_line(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var path: Array = parent.get("_last_soul_path") if parent.get("_last_soul_path") != null else []
	var slope := randf_range(-0.6, 0.6)
	if path.size() > 4:
		var a: Vector2 = path[0]
		var b: Vector2 = path[path.size() - 1]
		if absf(b.x - a.x) > 4.0:
			slope = clampf((b.y - a.y) / (b.x - a.x), -1.5, 1.5)
	Attacks._beam(enemy, parent, area, soul, Vector2(1, slope).normalized(), 0.55, SUPREME)
	if step % 2 == 1:
		Attacks._beam(enemy, parent, area, soul + Vector2(0, 26), Vector2(1, slope).normalized(), 0.85, Color(0.5, 0.85, 1.0))
	return 1.0


## MARGIN OF ERROR: a ring of points around you, plus or minus. It closes. The
## margin (the gap) is small.
static func _margin_of_error(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var ring := Attacks._bullet(enemy, parent, area, soul)
	ring.shape = "ring"
	ring.size = 4.0
	ring.color = SUPREME
	ring.delay = 0.3
	ring.radius = 70.0
	ring.ring_speed = -60.0
	ring.gap_angle = randf() * TAU
	ring.gap_width = 0.55
	ring.lifetime = 1.3
	ring.bounds = Rect2()
	return 1.2


## (Nearly beaten.) 0.4%: the number comes down, made of light, over and over. His
## odds against Hopkuna. He stayed anyway.
static func _zero_point_four(enemy: Enemy, parent: Node, area: Rect2, soul: Vector2, step: int) -> float:
	var text := "0.4%"
	var ch: String = text[step % text.length()]
	var x := area.position.x + 8 + (step % text.length()) * (area.size.x - 24) / 3.0
	for y in 5:
		for c in 3:
			if str(DIGITS[ch][y])[c] == "#":
				var bulb := _dot(enemy, parent, area, Vector2(x + c * 7, area.position.y + 4 + y * 7), SUPREME, 6.0)
				bulb.delay = 0.3
				bulb.velocity = Vector2(0, 75)
				bulb.glow = true
	var aimed := _dot(enemy, parent, area, Vector2(clampf(soul.x, area.position.x + 4, area.end.x - 4), area.position.y + 4), Color(1, 1, 1), 6.0)
	aimed.delay = 0.4
	aimed.velocity = Vector2(0, 110)
	return 0.55
