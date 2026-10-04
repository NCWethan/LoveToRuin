extends CanvasLayer
## The Rock Paper Scissors minigame at the PQ Mall.
##
## Each round: the opponent shows up (and gives something away, if you look),
## you pick a throw with Left/Right, press ENTER, and both hands bob through
## "ROCK... PAPER... SCISSORS... SHOOT!" (you can still change your mind until SHOOT).
## Ties are replayed.
##
## Opponents and their tells:
##   NCWethan  "sparks"  his lightning crackles in the shape of what he's about to throw
##   Ronin     "shadow"  he hides his hand, but his shadow on the ground doesn't
##   Agent     "math"    he counts your throws so far and plays the counter to the one
##                       you've thrown most. He tells you the odds. He thinks that's fine.
##
## Usage:
##   var game = preload("res://scripts/ui/rps_game.gd").new()
##   add_child(game)
##   var wins: int = await game.play(rounds)

signal _finished

const ROCK := 0
const PAPER := 1
const SCISSORS := 2
const NAMES := ["ROCK", "PAPER", "SCISSORS"]
## How long each "ROCK... PAPER... SCISSORS..." beat lasts, in seconds.
const BEAT := 0.5

const ELRIC_SKIN := Color(0.78, 0.66, 0.92)
const SKINS := {"NCWethan": Color(1.0, 0.86, 0.3), "Ronin": Color(0.89, 0.87, 0.84), "Agent": Color(1.0, 0.86, 0.3)}
const SLEEVES := {"NCWethan": Color(0.95, 0.95, 0.97), "Ronin": Color(0.6, 0.12, 0.12), "Agent": Color(0.16, 0.16, 0.2)}

var _panel: Control
var _font: Font
var _rounds: Array = []
var _round: int = 0
## "ready" (pick a throw, ENTER to go), "count" (the countdown), "result", "done".
var phase: String = "ready"
var _phase_time: float = 0.0
var _choice: int = ROCK
var _their_throw: int = ROCK
var _result: int = 0
var _wins: int = 0
var _losses: int = 0
var _history: Array[int] = []
var _opened_frame: int = -1
var _time: float = 0.0


func _ready() -> void:
	layer = 55
	_font = ThemeDB.fallback_font
	_panel = Control.new()
	_panel.size = Vector2(640, 480)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_panel.draw.connect(_draw_panel)
	_panel.visible = false


## Plays every round, then returns how many were won. Each round is a Dictionary:
## {"opponent": "NCWethan", "throw": 0, "tell": "sparks"}. Agent's "throw" is ignored
## (he works it out from your history).
func play(rounds: Array) -> int:
	var was_busy := Game.busy
	Game.busy = true
	_rounds = rounds
	_round = 0
	_wins = 0
	_losses = 0
	_history.clear()
	_opened_frame = Engine.get_process_frames()
	_start_round()
	_panel.visible = true
	await _finished
	_panel.visible = false
	await get_tree().process_frame
	Game.busy = was_busy
	return _wins


func _current() -> Dictionary:
	return _rounds[mini(_round, _rounds.size() - 1)]


func _start_round() -> void:
	phase = "ready"
	_phase_time = 0.0
	var round_info := _current()
	_their_throw = _agent_throw() if round_info["tell"] == "math" else int(round_info["throw"])


## The throw that beats `throw`.
static func counter(throw: int) -> int:
	return (throw + 1) % 3


## What the player should throw to win this round (used by the test robot, too).
func winning_throw() -> int:
	return counter(_their_throw)


## Agent's plan: find the throw you've made most often (the most recent one wins a
## tie), assume you'll throw it again, and play whatever beats it.
func _agent_throw() -> int:
	return counter(_most_likely())


func _most_likely() -> int:
	var counts := [0, 0, 0]
	for t in _history:
		counts[t] += 1
	var best: int = _history.back() if not _history.is_empty() else ROCK
	for t in 3:
		if counts[t] > counts[best]:
			best = t
	return best


func _process(delta: float) -> void:
	if not _panel.visible:
		return
	_time += delta
	_phase_time += delta
	_panel.queue_redraw()
	if Engine.get_process_frames() == _opened_frame:
		return
	match phase:
		"ready", "count":
			if Input.is_action_just_pressed("ui_left"):
				_choice = wrapi(_choice - 1, 0, 3)
				Game.play_sfx("move")
			elif Input.is_action_just_pressed("ui_right"):
				_choice = wrapi(_choice + 1, 0, 3)
				Game.play_sfx("move")
			if phase == "ready" and Input.is_action_just_pressed("confirm"):
				phase = "count"
				_phase_time = 0.0
				Game.play_sfx("select")
			elif phase == "count":
				_process_count()
		"result":
			if _phase_time > 0.6 and Input.is_action_just_pressed("confirm"):
				_next()
		"done":
			if _phase_time > 0.6 and Input.is_action_just_pressed("confirm"):
				_finished.emit()


## The countdown: three bobs, then SHOOT.
func _process_count() -> void:
	var beat := int(_phase_time / BEAT)
	if beat != int((_phase_time - get_process_delta_time()) / BEAT) and beat < 3:
		Game.play_sfx("text", 0.8 + beat * 0.15)
	if _phase_time >= BEAT * 3:
		_history.append(_choice)
		_result = 0 if _choice == _their_throw else (1 if _choice == counter(_their_throw) else -1)
		match _result:
			1:
				_wins += 1
				Game.play_sfx("spare")
			-1:
				_losses += 1
				Game.play_sfx("hurt")
			_:
				Game.play_sfx("miss")
		phase = "result"
		_phase_time = 0.0


func _next() -> void:
	if _result == 0:
		# A tie: same opponent, go again.
		_start_round()
		return
	_round += 1
	if _round >= _rounds.size():
		phase = "done"
		_phase_time = 0.0
	else:
		_start_round()


# --- Drawing ------------------------------------------------------------------

const LEFT_HAND := Vector2(200, 250)
const RIGHT_HAND := Vector2(440, 250)


func _draw_panel() -> void:
	# A dark stage with a spotlight on each player.
	_panel.draw_rect(Rect2(0, 0, 640, 480), Color(0.04, 0.03, 0.08))
	for spot in [LEFT_HAND, RIGHT_HAND]:
		for i in 5:
			_panel.draw_circle(spot + Vector2(0, 20), 120.0 - i * 18.0, Color(1, 1, 0.8, 0.025))
	_panel.draw_rect(Rect2(0, 318, 640, 2), Color(1, 1, 1, 0.15))

	if phase == "done":
		_draw_summary()
		return

	var round_info := _current()
	var opponent: String = round_info["opponent"]
	_centered("ROCK  PAPER  SCISSORS", Vector2(320, 34), 22, Color(1, 0.85, 0.3))
	_centered("ROUND %d / %d   -   vs. %s" % [_round + 1, _rounds.size(), opponent.to_upper()], Vector2(320, 58), 14, Color(0.8, 0.8, 0.85))
	_centered("YOU %d  -  %d %s" % [_wins, _losses, opponent.to_upper()], Vector2(320, 80), 14, Color.WHITE)
	_centered("ELRIC", LEFT_HAND + Vector2(0, -62), 14, Color(0.8, 0.65, 1.0))
	_centered(opponent.to_upper(), RIGHT_HAND + Vector2(0, -62), 14, DialogueBox.SPEAKERS.get(opponent, {}).get("color", Color.WHITE))

	# The hands bob on each beat of the countdown, as fists, then show their throws.
	var bob := 0.0
	var mine := ROCK
	var theirs := ROCK
	if phase == "count":
		bob = -absf(sin(_phase_time / BEAT * PI)) * 34.0
	elif phase == "result":
		mine = _choice
		theirs = _their_throw
	_draw_tell(round_info, theirs, bob)
	if round_info["tell"] != "shadow" or phase == "result":
		_draw_hand(RIGHT_HAND + Vector2(0, bob), theirs, SKINS.get(opponent, Color.WHITE), SLEEVES.get(opponent, Color.GRAY), true, 1.6)
	else:
		# Ronin keeps his hand behind his back: only his sleeve shows.
		_panel.draw_rect(Rect2(RIGHT_HAND + Vector2(20, -12 + bob), Vector2(40, 26)), SLEEVES["Ronin"])
		_panel.draw_rect(Rect2(RIGHT_HAND + Vector2(20, -12 + bob), Vector2(40, 26)), Color.BLACK, false, 2.0)
	_draw_hand(LEFT_HAND + Vector2(0, bob), mine, ELRIC_SKIN, Color(0.49, 0.37, 0.24), false, 1.6)

	match phase:
		"ready":
			_centered("Pick a throw, then press ENTER.", Vector2(320, 352), 16, Color.WHITE)
		"count":
			var word: String = ["ROCK...", "PAPER...", "SCISSORS..."][mini(int(_phase_time / BEAT), 2)]
			_centered(word, Vector2(320, 160), 30, Color(1, 1, 1, 0.9))
		"result":
			var text: String = ["YOU LOSE.", "TIE! AGAIN!", "YOU WIN!"][_result + 1]
			var color: Color = [Color(1, 0.35, 0.35), Color(0.9, 0.9, 0.9), Color(1, 0.9, 0.3)][_result + 1]
			_centered("SHOOT!", Vector2(320, 140), 22, Color(1, 1, 1, 0.6))
			_centered(text, Vector2(320, 172), 30, color)
			_centered("(ENTER)", Vector2(320, 352), 12, Color(0.5, 0.5, 0.5))
	_draw_choices()


## Something that gives the opponent's throw away, if you're paying attention.
func _draw_tell(round_info: Dictionary, shown: int, bob: float) -> void:
	if phase == "result":
		return
	match round_info["tell"]:
		"sparks":
			# His lightning crackles in the shape of his throw, just above his fist.
			var flicker := 0.35 + 0.65 * absf(sin(_time * 19.0))
			_draw_hand(RIGHT_HAND + Vector2(6, -94 + bob * 0.4), _their_throw, Color(0.5, 0.9, 1.0, 0.0), Color(0, 0, 0, 0), true, 1.3, Color(0.55, 0.92, 1.0, flicker))
			for i in 6:
				var start := RIGHT_HAND + Vector2(randf_range(-30, 30), randf_range(-30, 20) + bob)
				_panel.draw_line(start, start + Vector2(randf_range(-9, 9), randf_range(-9, 9)), Color(0.6, 0.95, 1.0, 0.8), 1.5)
			_centered("(His fist is sparking. The sparks have a shape.)", Vector2(320, 112), 13, Color(0.6, 0.9, 1.0))
		"shadow":
			# A lit patch of floor behind him... with his shadow on it, showing exactly
			# what he's holding behind his back.
			var floor_spot := RIGHT_HAND + Vector2(70, 64)
			_panel.draw_set_transform(floor_spot, 0.0, Vector2(1.0, 0.45))
			_panel.draw_circle(Vector2.ZERO, 70, Color(0.42, 0.36, 0.32))
			_panel.draw_circle(Vector2.ZERO, 54, Color(0.5, 0.44, 0.38))
			_panel.draw_set_transform(floor_spot, 0.0, Vector2(1.0, 0.7))
			_draw_hand(Vector2(-10, 0), _their_throw, Color(0.05, 0.03, 0.05, 0.85), Color(0.05, 0.03, 0.05, 0.85), true, 1.3, Color(0, 0, 0, 0))
			_panel.draw_set_transform(Vector2.ZERO)
			_centered("(Ronin is hiding his hand. Very carefully. From you, at least.)", Vector2(320, 112), 13, Color(0.85, 0.6, 0.6))
		"math":
			_draw_agent_math()


## Agent explains his reasoning, out loud, because he thinks it doesn't matter.
func _draw_agent_math() -> void:
	var counts := [0, 0, 0]
	for t in _history:
		counts[t] += 1
	var total := maxi(1, _history.size())
	var lines: Array[String] = ["\"You've thrown %d times. I counted.\"" % _history.size()]
	lines.append("\"ROCK %d%%.  PAPER %d%%.  SCISSORS %d%%.\"" % [roundi(100.0 * counts[0] / total), roundi(100.0 * counts[1] / total), roundi(100.0 * counts[2] / total)])
	if _history.size() > 0 and counts.count(counts.max()) > 1:
		lines.append("\"Tied? Then your last throw breaks it: %s.\"" % NAMES[_history.back()])
	lines.append("\"I play whatever beats your most likely throw.\"")
	lines.append("\"Telling you doesn't help you. Probably.\"")
	var box := Rect2(140, 96, 360, 18 + lines.size() * 18)
	_panel.draw_rect(box, Color.WHITE)
	_panel.draw_colored_polygon(PackedVector2Array([Vector2(430, box.end.y), Vector2(446, box.end.y), Vector2(440, box.end.y + 12)]), Color.WHITE)
	for i in lines.size():
		_panel.draw_string(_font, box.position + Vector2(10, 22 + i * 18), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.BLACK)


## The three throws to pick from, along the bottom.
func _draw_choices() -> void:
	for i in 3:
		var rect := Rect2(100 + i * 160, 372, 120, 88)
		var selected := i == _choice and phase != "result"
		var color := Color(1, 1, 0) if selected else Color(1, 0.5, 0)
		_panel.draw_rect(rect, Color(0, 0, 0, 0.6))
		_panel.draw_rect(rect, color, false, 2.0)
		_draw_hand(rect.get_center() + Vector2(-4, -10), i, ELRIC_SKIN, Color(0.49, 0.37, 0.24), false, 0.6)
		_centered(NAMES[i], rect.position + Vector2(60, 80), 13, color)
	if phase != "result":
		_centered("Left / Right to choose", Vector2(320, 474), 11, Color(0.5, 0.5, 0.5))


func _draw_summary() -> void:
	_centered("FINAL SCORE", Vector2(320, 150), 26, Color(1, 0.85, 0.3))
	_centered("%d / %d" % [_wins, _rounds.size()], Vector2(320, 210), 40, Color.WHITE)
	var verdict := "CHAMPION!" if _wins == _rounds.size() else ("Not bad." if _wins >= 3 else "Rematch...?")
	_centered(verdict, Vector2(320, 260), 22, Color(1, 0.9, 0.3) if _wins == _rounds.size() else Color(0.8, 0.8, 0.8))
	_centered("(ENTER)", Vector2(320, 340), 12, Color(0.5, 0.5, 0.5))


## A hand throwing rock, paper or scissors, drawn from simple shapes. It points
## right (toward the other player); `flip` points it left. If `outline_only` is set,
## only a glowing outline in that color is drawn (NCWethan's sparks).
func _draw_hand(at: Vector2, throw: int, skin: Color, sleeve: Color, flip: bool, size: float, outline_only: Color = Color(0, 0, 0, 0)) -> void:
	var dir := -1.0 if flip else 1.0
	var parts: Array = []   # [from, to, width] capsules
	# The palm / fist.
	parts.append([Vector2(-10, -4), Vector2(6, -4), 26.0])
	parts.append([Vector2(-10, 6), Vector2(6, 6), 24.0])
	match throw:
		ROCK:
			for i in 4:
				parts.append([Vector2(4, -12 + i * 8), Vector2(18, -12 + i * 8), 9.0])
			parts.append([Vector2(-4, -16), Vector2(12, -18), 8.0])
		PAPER:
			for i in 4:
				parts.append([Vector2(6, -12 + i * 8), Vector2(36, -13 + i * 8), 8.0])
			parts.append([Vector2(-2, -14), Vector2(10, -28), 8.0])
		SCISSORS:
			parts.append([Vector2(6, -8), Vector2(36, -24), 8.0])
			parts.append([Vector2(6, -1), Vector2(37, 8), 8.0])
			parts.append([Vector2(2, 8), Vector2(16, 8), 9.0])
			parts.append([Vector2(2, 15), Vector2(14, 15), 9.0])
			parts.append([Vector2(-4, -16), Vector2(10, -18), 8.0])
	var place := func(p: Vector2) -> Vector2:
		return at + Vector2(p.x * dir, p.y) * size
	if outline_only.a > 0.0:
		for part in parts:
			_capsule(place.call(part[0]), place.call(part[1]), part[2] * size + 2, outline_only, true)
		return
	# Sleeve, then a dark outline for every piece, then the skin on top.
	_panel.draw_rect(Rect2(place.call(Vector2(-34 if not flip else -14, -15)), Vector2(20, 30) * size), sleeve)
	for part in parts:
		_capsule(place.call(part[0]), place.call(part[1]), part[2] * size + 4, Color(0.1, 0.08, 0.1, skin.a), false)
	for part in parts:
		_capsule(place.call(part[0]), place.call(part[1]), part[2] * size, skin, false)
	# Lines between the fingers of an open hand.
	if throw == PAPER and skin.a > 0.9:
		for i in 3:
			var y := -8.0 + i * 8.0
			_panel.draw_line(place.call(Vector2(12, y)), place.call(Vector2(38, y - 1)), skin.darkened(0.35), 1.5)
	# Knuckle lines on a fist.
	if throw == ROCK and skin.a > 0.9:
		for i in 3:
			var y := -8 + i * 8
			_panel.draw_line(place.call(Vector2(10, y)), place.call(Vector2(18, y)), skin.darkened(0.35), 1.5)


## A thick line with rounded ends (or just its outline).
func _capsule(from: Vector2, to: Vector2, width: float, color: Color, outline: bool) -> void:
	if outline:
		var side := (to - from).orthogonal().normalized() * width / 2
		_panel.draw_line(from + side, to + side, color, 1.5)
		_panel.draw_line(from - side, to - side, color, 1.5)
		_panel.draw_arc(to, width / 2, (to - from).angle() - PI / 2, (to - from).angle() + PI / 2, 8, color, 1.5)
		_panel.draw_arc(from, width / 2, (to - from).angle() + PI / 2, (to - from).angle() + PI * 1.5, 8, color, 1.5)
		return
	_panel.draw_line(from, to, color, width)
	_panel.draw_circle(from, width / 2, color)
	_panel.draw_circle(to, width / 2, color)


func _centered(text: String, center: Vector2, size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_panel.draw_string(_font, Vector2(center.x - width / 2, center.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
