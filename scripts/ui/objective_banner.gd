class_name ObjectiveBanner
extends CanvasLayer
## The "NEW OBJECTIVE" banner that slides in at the top of the screen.
## Use Game.set_objective("...") rather than calling this directly.

const HEIGHT := 54.0
const SHOW_TIME := 3.5

var _panel: Control
var _font: Font
var _text: String = ""
var _tween: Tween


func _ready() -> void:
	layer = 70
	_font = ThemeDB.fallback_font
	_panel = Control.new()
	_panel.size = Vector2(640, HEIGHT)
	_panel.position.y = -HEIGHT - 4
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_panel.draw.connect(_draw_panel)


func show_objective(text: String) -> void:
	_text = text
	_panel.queue_redraw()
	Game.play_sfx("save")
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "position:y", 8.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(SHOW_TIME)
	_tween.tween_property(_panel, "position:y", -HEIGHT - 4, 0.3).set_ease(Tween.EASE_IN)


func _draw_panel() -> void:
	var width := maxf(300.0, _font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 40)
	var rect := Rect2(320 - width / 2, 0, width, HEIGHT)
	_panel.draw_rect(rect.grow(3), Color.YELLOW)
	_panel.draw_rect(rect, Color.BLACK)
	var title := "NEW OBJECTIVE"
	var title_width := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	_panel.draw_string(_font, Vector2(320 - title_width / 2, 18), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)
	var text_width := _font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_panel.draw_string(_font, Vector2(320 - text_width / 2, 42), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
