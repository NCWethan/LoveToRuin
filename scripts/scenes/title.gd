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

	var source_left := 320.0 - LETTER_SPACING * SOURCE.length() / 2.0
	var target_left := 320.0 - LETTER_SPACING * TARGET.length() / 2.0
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
	elif _ready_for_input and not _done:
		if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
			_choice = wrapi(_choice + 1, 0, _options.size())
			Game.play_sfx("move")
		elif Input.is_action_just_pressed("confirm"):
			_done = true
			Game.play_sfx("select")
			if _options[_choice] == "Continue":
				Game.load_game()
			else:
				Game.new_game()
				Game.change_scene(INTRO_SCENE)

	queue_redraw()


func _draw() -> void:
	var move := clampf((_time - HOLD_TIME) / MOVE_TIME, 0.0, 1.0)
	move = move * move * (3.0 - 2.0 * move)  # ease in and out
	var appear := clampf(_time / 0.8, 0.0, 1.0)

	for i in SOURCE.length():
		var start := _starts[i]
		var end := _ends[i]
		# Letters arc up or down while they travel, so they don't crash into each other.
		var arc := sin(move * PI) * (40.0 if i % 2 == 0 else -40.0)
		var pos := start.lerp(end, move) + Vector2(0, arc)
		var color := Color(1, 1, 1, appear)
		if move >= 1.0:
			color = Color(1, 1, 1)
		_draw_letter(SOURCE[i], pos, color)

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


func _draw_letter(letter: String, center: Vector2, color: Color) -> void:
	_draw_centered(letter, center, LETTER_SIZE, color)


func _draw_centered(text: String, center: Vector2, size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(_font, Vector2(center.x - width / 2, center.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
