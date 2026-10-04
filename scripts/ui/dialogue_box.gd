class_name DialogueBox
extends CanvasLayer
## The text box used for talking and cutscenes, everywhere outside of battle.
##
## Usage (from any script):
##   await Game.dialogue.say(["* (A line of narration.)", {"who": "Hop", "text": "A line Hop says."}])
##   var answer := await Game.dialogue.ask("* (Pick it up?)", ["Yes", "No"])   # 0 = Yes, 1 = No
##
## Each line is either a String (narration) or a Dictionary with "who" (the speaker)
## and "text". Add "face": false to hide the speaker's portrait for that line.
## Press Z to finish a line or go to the next one.

signal _advanced

const BOTTOM_BOX := Rect2(30, 330, 580, 130)
const TOP_BOX := Rect2(30, 40, 580, 130)

const TYPE_SPEED := 40.0
const FONT_SIZE := 16
const LINE_HEIGHT := 22
## Portraits are the speaker's head and shoulders, drawn this many times bigger.
const PORTRAIT_SCALE := 4.0
## How far the text moves right to make room for a portrait.
const PORTRAIT_SPACE := 112.0

## Name tag color and voice pitch for each speaker. Anyone not listed uses white / normal.
const SPEAKERS := {
	"Elric": {"color": Color(0.8, 0.65, 1.0), "pitch": 1.25},
	"Hop": {"color": Color(0.75, 0.75, 0.75), "pitch": 1.0},
	"Eggo": {"color": Color(1.0, 0.85, 0.2), "pitch": 0.8},
	"BigJoe6": {"color": Color(0.9, 0.3, 0.3), "pitch": 0.65},
	"MuffinMage": {"color": Color(0.95, 0.5, 0.2), "pitch": 0.9},
	"Supreme": {"color": Color(0.75, 0.45, 1.0), "pitch": 1.15},
	"Crayola": {"color": Color(0.85, 0.85, 0.9), "pitch": 1.4},
	"NCWethan": {"color": Color(0.4, 0.75, 1.0), "pitch": 0.75},
	"Ronin": {"color": Color(0.95, 0.25, 0.2), "pitch": 0.7},
	"Rooster": {"color": Color(0.95, 0.95, 0.95), "pitch": 1.1},
	"Nat": {"color": Color(0.6, 0.4, 0.8), "pitch": 0.6},
	"Sansworth": {"color": Color(0.7, 0.7, 0.75), "pitch": 1.3},
	"Nassan": {"color": Color(0.55, 0.55, 0.6), "pitch": 0.85},
}

## Where the box is drawn. It moves to the top when Elric is in the
## bottom half of the screen, so it never covers them (like Undertale).
var _box := BOTTOM_BOX

var _panel: Control
var _font: Font
var _active: bool = false
var _who: String = ""
var _show_face: bool = true
var _tag: String = ""
var _text: String = ""
var _typed: float = 0.0
var _last_beep: int = 0
var _choices: Array = []
var _choice: int = 0


func _ready() -> void:
	layer = 50
	_font = ThemeDB.fallback_font
	_panel = Control.new()
	_panel.size = Vector2(640, 480)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)
	_panel.draw.connect(_draw_box)


## Shows each line in turn and returns when the player has read them all.
func say(lines: Array) -> void:
	var was_busy := Game.busy
	Game.busy = true
	_panel.visible = true
	for line in lines:
		_show(line)
		await _advanced
	_panel.visible = false
	# Wait one frame so the Z press that closed the box doesn't also
	# count as "talk to whatever is in front of me" again.
	await get_tree().process_frame
	Game.busy = was_busy


## Shows a question with options side by side. Returns the index of the chosen option.
func ask(question, options: Array) -> int:
	var was_busy := Game.busy
	Game.busy = true
	_panel.visible = true
	_show(question)
	_choices = options
	_choice = 0
	await _advanced
	var picked := _choice
	_choices = []
	_panel.visible = false
	await get_tree().process_frame
	Game.busy = was_busy
	return picked


func _show(line) -> void:
	if line is Dictionary:
		_who = line.get("who", "")
		_text = line.get("text", "")
		# "face": false hides the portrait (e.g. someone shouting from off-screen).
		_show_face = line.get("face", true)
		# "tag" changes the name shown, e.g. "???" for someone not met yet.
		_tag = line.get("tag", _who)
	else:
		_who = ""
		_text = str(line)
		_show_face = true
		_tag = ""
	_typed = 0.0
	_last_beep = 0
	_active = true

	_box = BOTTOM_BOX
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.get_global_transform_with_canvas().origin.y > 260:
		_box = TOP_BOX


func _finished() -> bool:
	return _typed >= _text.length()


func _process(delta: float) -> void:
	if not _active:
		return

	_typed += delta * TYPE_SPEED
	var shown := mini(int(_typed), _text.length())
	# A beep every other letter, in the speaker's voice.
	if shown > _last_beep and shown % 2 == 0 and _text[shown - 1] != " ":
		var pitch: float = SPEAKERS.get(_who, {}).get("pitch", 1.0)
		Game.play_sfx("voice" if _who != "" else "text", pitch)
	_last_beep = shown

	if _finished() and not _choices.is_empty():
		if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
			_choice = wrapi(_choice + (1 if Input.is_action_just_pressed("ui_right") else -1), 0, _choices.size())
			Game.play_sfx("move")

	if Input.is_action_just_pressed("confirm"):
		if _finished():
			_active = false
			if not _choices.is_empty():
				Game.play_sfx("select")
			_advanced.emit()
		else:
			_typed = _text.length()
	elif Input.is_action_just_pressed("cancel"):
		_typed = _text.length()

	_panel.queue_redraw()


func _draw_box() -> void:
	_panel.draw_rect(_box.grow(4), Color.WHITE)
	_panel.draw_rect(_box, Color.BLACK)

	if _who != "":
		var color: Color = SPEAKERS.get(_who, {}).get("color", Color.WHITE)
		var tag_width := _font.get_string_size(_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + 16
		var tag := Rect2(_box.position + Vector2(10, -30), Vector2(tag_width, 24))
		_panel.draw_rect(tag.grow(2), Color.WHITE)
		_panel.draw_rect(tag, Color.BLACK)
		_panel.draw_string(_font, tag.position + Vector2(8, 17), _tag, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)

	# The speaker's face on the left, like Deltarune.
	var text_left := 16.0
	var face := Cast.portrait(_who) if _show_face else null
	if face:
		var size := Cast.PORTRAIT_REGION.size * PORTRAIT_SCALE
		var at := _box.position + Vector2(12, (_box.size.y - size.y) / 2)
		_panel.draw_texture_rect_region(face, Rect2(at, size), Cast.PORTRAIT_REGION)
		text_left = PORTRAIT_SPACE

	var visible_text := _text.substr(0, mini(int(_typed), _text.length()))
	var lines := visible_text.split("\n")
	for i in lines.size():
		_panel.draw_string(_font, _box.position + Vector2(text_left, 28 + i * LINE_HEIGHT), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)

	if _finished() and not _choices.is_empty():
		var y := _box.end.y - 20
		for i in _choices.size():
			var x := _box.position.x + 120 + i * 200
			var color := Color.YELLOW if i == _choice else Color.WHITE
			_panel.draw_string(_font, Vector2(x, y), str(_choices[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
			if i == _choice:
				_draw_heart(Vector2(x - 18, y - 6))


## A tiny red heart used as the choice cursor.
func _draw_heart(center: Vector2) -> void:
	var red := Color(1, 0, 0)
	_panel.draw_rect(Rect2(center + Vector2(-6, -5), Vector2(5, 4)), red)
	_panel.draw_rect(Rect2(center + Vector2(1, -5), Vector2(5, 4)), red)
	_panel.draw_rect(Rect2(center + Vector2(-6, -2), Vector2(12, 3)), red)
	_panel.draw_rect(Rect2(center + Vector2(-4, 1), Vector2(8, 2)), red)
	_panel.draw_rect(Rect2(center + Vector2(-2, 3), Vector2(4, 2)), red)
