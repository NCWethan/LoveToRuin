extends CanvasLayer
## The stamina bar in the bottom-right corner of the screen. It slides in when
## Elric starts sprinting, drains as he runs, and fades away once it's full again.
## It turns from green to yellow to red as it runs low, and flashes red with
## "WINDED" when it's been run all the way down.

## The Player whose stamina this shows (set by the Player).
var player: Node

const BOX := Rect2(506, 446, 122, 24)
## How long the bar stays on screen after it fills back up, in seconds.
const LINGER := 1.0

var _canvas: Node2D
var _font: Font
var _shown: float = 0.0
## (Starts as if it has been full a while, so it isn't shown when an area loads.)
var _full_for: float = LINGER
var _time: float = 0.0


func _ready() -> void:
	layer = 5
	_font = ThemeDB.fallback_font
	_canvas = Node2D.new()
	add_child(_canvas)
	_canvas.draw.connect(_draw_bar)


func _process(delta: float) -> void:
	_time += delta
	if player == null:
		return
	var stamina: float = player.stamina
	_full_for = _full_for + delta if stamina >= 1.0 and not player.sprinting else 0.0
	# Hidden during conversations and cutscenes.
	var wanted := 1.0 if _full_for < LINGER and not Game.busy else 0.0
	_shown = move_toward(_shown, wanted, delta * 5.0)
	_canvas.visible = _shown > 0.0
	_canvas.queue_redraw()


func _draw_bar() -> void:
	var stamina: float = player.stamina
	var winded: bool = player.is_winded()
	var alpha := _shown
	# Slides up from just below the screen as it appears.
	var box := BOX
	box.position.y += (1.0 - _shown) * 12.0
	_canvas.draw_rect(box, Color(0, 0, 0, 0.8 * alpha))
	_canvas.draw_rect(box, Color(1, 1, 1, alpha), false, 2.0)
	# A little lightning bolt icon.
	var icon := box.position + Vector2(8, 4)
	var bolt := PackedVector2Array([icon + Vector2(6, 0), icon + Vector2(1, 9), icon + Vector2(5, 9), icon + Vector2(3, 16), icon + Vector2(9, 6), icon + Vector2(5, 6), icon + Vector2(8, 0)])
	_canvas.draw_colored_polygon(bolt, Color(1, 0.85, 0.25, alpha))
	# The bar itself.
	var track := Rect2(box.position + Vector2(22, 7), Vector2(box.size.x - 30, 10))
	_canvas.draw_rect(track, Color(0.25, 0.05, 0.05, alpha))
	var fill_color := Color(0.3, 0.9, 0.35)
	if stamina < 0.5:
		fill_color = Color(1.0, 0.8, 0.2).lerp(Color(0.3, 0.9, 0.35), (stamina - 0.25) / 0.25) if stamina > 0.25 else Color(1.0, 0.3, 0.2).lerp(Color(1.0, 0.8, 0.2), stamina / 0.25)
	if winded and int(_time * 6.0) % 2 == 0:
		fill_color = Color(1.0, 0.2, 0.2)
	_canvas.draw_rect(Rect2(track.position, Vector2(track.size.x * stamina, track.size.y)), Color(fill_color, alpha))
	_canvas.draw_rect(Rect2(track.position, Vector2(track.size.x * stamina, 3)), Color(1, 1, 1, 0.3 * alpha))
	_canvas.draw_rect(track, Color(1, 1, 1, 0.6 * alpha), false, 1.0)
	# A tick where sprinting comes back after being winded.
	if winded:
		var x: float = track.position.x + track.size.x * player.WINDED_UNTIL
		_canvas.draw_line(Vector2(x, track.position.y - 2), Vector2(x, track.end.y + 2), Color(1, 1, 1, alpha), 1.0)
		_canvas.draw_string(_font, box.position + Vector2(box.size.x - 52, -4), "WINDED", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.4, 0.4, alpha))
