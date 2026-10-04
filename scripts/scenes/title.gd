extends Node2D
## The title screen. "REVOLUTION" appears, then its letters rearrange themselves
## into "LOVE TO RUIN" (the same ten letters!). Then the player picks Begin or Continue.

const INTRO_SCENE := "res://scenes/intro.tscn"

const SOURCE := "REVOLUTION"
const TARGET := "LOVE TO RUIN"
## For each letter of TARGET (spaces skipped), which letter of SOURCE moves there.
## L=4  O=3  V=2  E=1  T=6  O=8  R=0  U=5  I=7  N=9
const MAPPING := [4, 3, 2, 1, -1, 6, 8, -1, 0, 5, 7, 9]

const LETTER_SIZE := 52
const LETTER_SPACING := 40.0
const TITLE_Y := 190.0

const HOLD_TIME := 1.6      # how long REVOLUTION stays before moving
const MOVE_TIME := 1.6      # how long the letters take to rearrange

var _font: Font
var _time: float = 0.0
var _starts: Array[Vector2] = []    # where each SOURCE letter begins
var _ends: Array[Vector2] = []      # where each SOURCE letter ends up
var _options: Array[String] = []
var _choice: int = 0
var _ready_for_input: bool = false
var _done: bool = false
var _played_chime: bool = false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	_font = ThemeDB.fallback_font
	Game.play_music("title")

	# Centers of the first letters, so each word is centered on the screen.
	var source_left := 320.0 - LETTER_SPACING * (SOURCE.length() - 1) / 2.0
	var target_left := 320.0 - LETTER_SPACING * (TARGET.length() - 1) / 2.0
	_starts.resize(SOURCE.length())
	_ends.resize(SOURCE.length())
	for i in SOURCE.length():
		_starts[i] = Vector2(source_left + i * LETTER_SPACING, TITLE_Y)
	for i in MAPPING.size():
		if MAPPING[i] >= 0:
			_ends[MAPPING[i]] = Vector2(target_left + i * LETTER_SPACING, TITLE_Y)

	_options = ["Begin"]
	if Game.has_save():
		_options.append("Continue")
		_choice = 1
	_options.append("Settings")


func _process(delta: float) -> void:
	_time += delta
	if not _ready_for_input and _time >= HOLD_TIME + MOVE_TIME + 0.4:
		_ready_for_input = true
	if not _played_chime and _time >= HOLD_TIME + MOVE_TIME:
		_played_chime = true
		Game.play_sfx("save")

	# Pressing Z early skips the animation.
	if not _ready_for_input and Input.is_action_just_pressed("confirm") and _time > 0.3:
		_time = HOLD_TIME + MOVE_TIME + 0.4
		_played_chime = true
		_ready_for_input = true
	elif _ready_for_input and not _done and not Game.settings_menu.is_open() and Engine.get_process_frames() != Game.settings_menu.closed_frame:
		if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
			_choice = wrapi(_choice + (1 if Input.is_action_just_pressed("ui_right") else -1), 0, _options.size())
			Game.play_sfx("move")
		elif Input.is_action_just_pressed("confirm") and _options[_choice] == "Settings":
			Game.play_sfx("select")
			Game.settings_menu.open()
		elif Input.is_action_just_pressed("confirm"):
			_done = true
			Game.play_sfx("select")
			if _options[_choice] == "Continue":
				Game.load_game()
			else:
				Game.new_game()
				Game.change_scene(INTRO_SCENE)

	queue_redraw()


const RED := Color(0.9, 0.12, 0.2)
## Twelve fragments, like the twelve in the story.
const FRAGMENTS := 12


func _draw() -> void:
	var move := clampf((_time - HOLD_TIME) / MOVE_TIME, 0.0, 1.0)
	move = move * move * (3.0 - 2.0 * move)  # ease in and out
	var appear := clampf(_time / 0.8, 0.0, 1.0)
	# How much the red "after the anagram" look has faded in.
	var red_in := clampf((_time - HOLD_TIME - MOVE_TIME + 0.4) / 1.2, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(_time * 1.8)

	_draw_glow(red_in, pulse)
	_draw_embers(appear)
	_draw_fragments(red_in)

	for i in SOURCE.length():
		var start := _starts[i]
		var end := _ends[i]
		# Letters arc up or down while they travel, so they don't crash into each other.
		var arc := sin(move * PI) * (40.0 if i % 2 == 0 else -40.0)
		var pos := start.lerp(end, move) + Vector2(0, arc)
		var color := Color(1, 1, 1, appear)
		if move >= 1.0:
			color = Color(1, 1, 1)
		# A red shadow behind each letter that grows in once it becomes LOVE TO RUIN.
		_draw_letter(SOURCE[i], pos + Vector2(3, 3), Color(RED, 0.25 * appear + 0.55 * red_in))
		_draw_letter(SOURCE[i], pos, color)

	_draw_crack(red_in, pulse)

	if _ready_for_input:
		var fade := clampf((_time - HOLD_TIME - MOVE_TIME - 0.4) / 0.5, 0.0, 1.0)
		for i in _options.size():
			var x := 320.0 + (i - (_options.size() - 1) / 2.0) * 180.0
			var color := Color(1, 1, 0, fade) if i == _choice else Color(1, 1, 1, fade)
			_draw_centered(_options[i], Vector2(x, 330), 22, color)
		var summary := Game.save_summary()
		if summary != "" and _options[_choice] == "Continue":
			_draw_centered(summary, Vector2(320, 380), 14, Color(0.7, 0.7, 0.7, fade))
		_draw_centered("Arrow keys to choose  -  ENTER to confirm", Vector2(320, 450), 12, Color(0.5, 0.5, 0.5, fade))


## A dim red glow behind the title that slowly breathes.
func _draw_glow(amount: float, pulse: float) -> void:
	if amount <= 0.0:
		return
	var center := Vector2(320, TITLE_Y - 16)
	for i in 8:
		var radius := 60.0 + i * 26.0
		draw_set_transform(center, 0.0, Vector2(2.2, 0.75))
		draw_circle(Vector2.ZERO, radius, Color(RED, amount * (0.035 + 0.015 * pulse)))
	draw_set_transform(Vector2.ZERO)


## Tiny red embers drifting up from the bottom of the screen.
func _draw_embers(amount: float) -> void:
	for i in 26:
		var speed := 14.0 + (i * 37 % 23)
		var y := 490.0 - fmod(_time * speed + i * 61.0, 520.0)
		var x := fmod(i * 97.0, 640.0) + sin(_time * 0.7 + i) * 12.0
		var fade := clampf((490.0 - y) / 120.0, 0.0, 1.0) * clampf(y / 160.0, 0.0, 1.0)
		var size := 2.0 if i % 3 != 0 else 3.0
		draw_rect(Rect2(x, y, size, size), Color(RED.lightened(0.2), 0.55 * fade * amount))


## Twelve jagged red fragments slowly circling the title, each glowing in turn.
func _draw_fragments(amount: float) -> void:
	if amount <= 0.0:
		return
	var center := Vector2(320, TITLE_Y - 16)
	for i in FRAGMENTS:
		var angle := _time * 0.18 + i * TAU / FRAGMENTS
		# An ellipse: wide around the words, flatter top to bottom.
		var at := center + Vector2(cos(angle) * 270.0, sin(angle) * 95.0)
		# The ones "behind" the title (top of the ellipse) are dimmer and smaller.
		var depth := 0.55 + 0.45 * (sin(angle) + 1.0) / 2.0
		var glow := 0.5 + 0.5 * sin(_time * 2.5 - i * 0.9)
		var spin := _time * (0.6 if i % 2 == 0 else -0.8) + i
		var size := 7.0 * depth
		var shard := PackedVector2Array([
			Vector2(0, -1.4), Vector2(0.7, -0.3), Vector2(0.45, 0.9), Vector2(-0.2, 1.3), Vector2(-0.75, 0.1)])
		for p in shard.size():
			shard[p] = at + shard[p].rotated(spin) * size
		draw_circle(at, size * 1.8, Color(RED, 0.12 * glow * depth * amount))
		draw_colored_polygon(shard, Color(0.55, 0.05, 0.12, amount * depth))
		draw_polyline(shard + PackedVector2Array([shard[0]]), Color(1.0, 0.35 + 0.3 * glow, 0.4, amount * depth), 1.0)


## A thin red crack running under the title, glowing.
func _draw_crack(amount: float, pulse: float) -> void:
	if amount <= 0.0:
		return
	var points := PackedVector2Array()
	var x := 120.0
	var i := 0
	while x <= 520.0:
		var jag := ((i * 7) % 5 - 2) * 2.0
		points.append(Vector2(x, TITLE_Y + 22 + jag))
		x += 16.0
		i += 1
	# It opens up from the middle outward.
	var shown := int(points.size() * amount)
	var from := (points.size() - shown) / 2
	var line := points.slice(from, from + shown)
	if line.size() > 1:
		draw_polyline(line, Color(RED, 0.35 * amount), 4.0)
		draw_polyline(line, Color(1.0, 0.45 + 0.3 * pulse, 0.5, amount), 1.5)


func _draw_letter(letter: String, center: Vector2, color: Color) -> void:
	_draw_centered(letter, center, LETTER_SIZE, color)


func _draw_centered(text: String, center: Vector2, size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(_font, Vector2(center.x - width / 2, center.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
