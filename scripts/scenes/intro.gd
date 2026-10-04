extends Node2D
## The opening narration: white text on black, one line at a time,
## before Elric arrives at Mt. Carmel.

const NEXT_SCENE := "res://scenes/mt_carmel.tscn"

const LINES := [
	"There's a kind of person who never stays anywhere for long.",
	"No home. Not because of money.\nJust... never the right place.",
	"Elric was that kind of person.",
	"Lately, people around San Diego\nhad started whispering.",
	"About strange fragments\nthat hum like they're alive.",
	"And about a name\nnobody liked to say out loud.",
]
const TYPE_SPEED := 30.0

var _font: Font
var _line: int = 0
var _typed: float = 0.0
var _last_beep: int = 0
var _leaving: bool = false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	if _leaving:
		return
	var text: String = LINES[_line]
	_typed += delta * TYPE_SPEED

	var shown := mini(int(_typed), text.length())
	if shown > _last_beep and shown % 2 == 0 and text[shown - 1] != " ":
		Game.play_sfx("text", 0.8)
	_last_beep = shown

	if Input.is_action_just_pressed("confirm") and not Game.transitioning:
		if _typed < text.length():
			_typed = text.length()
		elif _line + 1 < LINES.size():
			_line += 1
			_typed = 0.0
			_last_beep = 0
		else:
			_leaving = true
			Game.change_scene(NEXT_SCENE)
	queue_redraw()


func _draw() -> void:
	var text: String = LINES[_line]
	var shown := text.substr(0, mini(int(_typed), text.length()))
	var lines := shown.split("\n")
	for i in lines.size():
		var width := _font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(_font, Vector2(320 - width / 2, 220 + i * 30), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	if _typed >= text.length():
		draw_string(_font, Vector2(296, 440), "(Z)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.5))
