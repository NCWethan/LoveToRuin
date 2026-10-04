extends CanvasLayer
## The settings screen: music volume, sound volume, text speed and fullscreen.
## Opened from the title screen or from the bag. Up/Down to pick a setting,
## Left/Right to change it, X (or ENTER on "Back") to close.
## Settings are saved to user://settings.cfg (separate from the save file).

signal _closed

const PANEL := Rect2(90, 70, 460, 330)
const ROWS := ["Music", "Sound", "Text speed", "Fullscreen", "Back"]
const TEXT_SPEEDS := ["Slow", "Normal", "Fast"]
const ROW_HEIGHT := 44

var _panel: Control
var _font: Font
var _open: bool = false
var _opened_frame: int = -1
var _cursor: int = 0
## The frame the menu closed on (so the key that closed it isn't used again by whatever is underneath).
var closed_frame: int = -1


func _ready() -> void:
	layer = 65
	_font = ThemeDB.fallback_font
	_panel = Control.new()
	_panel.size = Vector2(640, 480)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)
	_panel.draw.connect(_draw_panel)


## Opens the settings and waits until they're closed.
func open() -> void:
	var was_busy := Game.busy
	Game.busy = true
	_opened_frame = Engine.get_process_frames()
	_open = true
	_cursor = 0
	_panel.visible = true
	await _closed
	_panel.visible = false
	Game.save_settings()
	await get_tree().process_frame
	Game.busy = was_busy


func is_open() -> bool:
	return _open


func _process(_delta: float) -> void:
	if not _open or Engine.get_process_frames() == _opened_frame:
		return
	var left := Input.is_action_just_pressed("ui_left")
	var right := Input.is_action_just_pressed("ui_right")
	if Input.is_action_just_pressed("ui_up"):
		_cursor = wrapi(_cursor - 1, 0, ROWS.size())
		Game.play_sfx("move")
	elif Input.is_action_just_pressed("ui_down"):
		_cursor = wrapi(_cursor + 1, 0, ROWS.size())
		Game.play_sfx("move")
	elif left or right:
		_change(1 if right else -1)
	elif Input.is_action_just_pressed("confirm"):
		if ROWS[_cursor] == "Back":
			_close()
		elif ROWS[_cursor] == "Fullscreen":
			_change(1)
	elif Input.is_action_just_pressed("cancel"):
		_close()
	_panel.queue_redraw()


## Changes the highlighted setting by one step (left = -1, right = +1).
func _change(step: int) -> void:
	var settings: Dictionary = Game.settings
	match ROWS[_cursor]:
		"Music":
			settings["music"] = clampf(snappedf(settings["music"] + step * 0.1, 0.1), 0.0, 1.0)
		"Sound":
			settings["sound"] = clampf(snappedf(settings["sound"] + step * 0.1, 0.1), 0.0, 1.0)
		"Text speed":
			settings["text_speed"] = clampi(int(settings["text_speed"]) + step, 0, TEXT_SPEEDS.size() - 1)
		"Fullscreen":
			settings["fullscreen"] = not settings["fullscreen"]
		_:
			return
	Game.apply_settings()
	# A blip at the new volume, so you can hear the difference.
	Game.play_sfx("select")


func _close() -> void:
	closed_frame = Engine.get_process_frames()
	Game.play_sfx("select")
	_open = false
	_closed.emit()


func _draw_panel() -> void:
	_panel.draw_rect(Rect2(Vector2.ZERO, Vector2(640, 480)), Color(0, 0, 0, 0.7))
	_panel.draw_rect(PANEL.grow(4), Color.WHITE)
	_panel.draw_rect(PANEL, Color.BLACK)
	_panel.draw_string(_font, PANEL.position + Vector2(24, 36), "SETTINGS", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.YELLOW)

	var settings: Dictionary = Game.settings
	for i in ROWS.size():
		var y := PANEL.position.y + 86 + i * ROW_HEIGHT
		var selected := i == _cursor
		var color := Color.YELLOW if selected else Color.WHITE
		var label_x := PANEL.position.x + 50
		_panel.draw_string(_font, Vector2(label_x, y), ROWS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
		if selected:
			_heart(Vector2(label_x - 20, y - 6))
		var value_x := PANEL.position.x + 220
		match ROWS[i]:
			"Music", "Sound":
				var amount: float = settings["music" if ROWS[i] == "Music" else "sound"]
				_volume_bar(Vector2(value_x, y - 14), amount, color)
			"Text speed":
				_arrows(value_x, y, TEXT_SPEEDS[int(settings["text_speed"])], color, selected)
			"Fullscreen":
				_arrows(value_x, y, "On" if settings["fullscreen"] else "Off", color, selected)
	_panel.draw_string(_font, Vector2(PANEL.position.x + 24, PANEL.end.y - 14), "Up/Down: choose   Left/Right: change   X: back", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.55, 0.55))


## Ten little blocks, filled up to `amount` (0 to 1), and the percent.
func _volume_bar(at: Vector2, amount: float, color: Color) -> void:
	var filled := roundi(amount * 10)
	for b in 10:
		var block := Rect2(at + Vector2(b * 16, 0), Vector2(12, 16))
		_panel.draw_rect(block, color if b < filled else Color(0.25, 0.25, 0.25))
	_panel.draw_string(_font, at + Vector2(170, 14), "%d%%" % roundi(amount * 100), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)


func _arrows(x: float, y: float, text: String, color: Color, selected: bool) -> void:
	var shown := "<  %s  >" % text if selected else text
	_panel.draw_string(_font, Vector2(x, y), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)


func _heart(center: Vector2) -> void:
	var red := Color(1, 0, 0)
	_panel.draw_rect(Rect2(center + Vector2(-6, -5), Vector2(5, 4)), red)
	_panel.draw_rect(Rect2(center + Vector2(1, -5), Vector2(5, 4)), red)
	_panel.draw_rect(Rect2(center + Vector2(-6, -2), Vector2(12, 3)), red)
	_panel.draw_rect(Rect2(center + Vector2(-4, 1), Vector2(8, 2)), red)
	_panel.draw_rect(Rect2(center + Vector2(-2, 3), Vector2(4, 2)), red)
