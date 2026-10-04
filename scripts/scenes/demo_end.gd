extends Node2D
## Shown when Elric leaves Mt. Carmel: the end of what's built so far.

var _font: Font
var _time: float = 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_time += delta
	if _time > 1.5 and Input.is_action_just_pressed("confirm") and not Game.transitioning:
		Game.change_scene(Game.TITLE_SCENE)
	queue_redraw()


func _draw() -> void:
	var alpha := clampf(_time / 1.0, 0.0, 1.0)
	_centered("LOVE TO RUIN", 140, 44, Color(1, 1, 1, alpha))
	_centered("Chapter 1  -  to be continued", 190, 18, Color(0.8, 0.8, 0.8, alpha))
	var next := "Next stop: Westview High School... after dark." if Game.flags.get("mall_done", false) else "Next stop: the PQ Mall."
	_centered(next, 250, 18, Color(1, 1, 0.6, alpha))

	var path: String = Game.flags.get("tutorial_path", "")
	var note := ""
	match path:
		"spared": note = "You talked your way out. Revolution trusts you... for now."
		"fought": note = "You fought your way out. Revolution will remember that."
		"mixed": note = "Revolution isn't sure what to make of you."
	_centered(note, 300, 14, Color(0.7, 0.7, 0.7, alpha))
	_centered("LV %d     BOND %d     EXP %d     $%d" % [Game.lv(), Game.bond, Game.exp_points, Game.money], 340, 16, Color(1, 1, 1, alpha))
	if _time > 1.5:
		_centered("(press Z to return to the title)", 440, 12, Color(0.5, 0.5, 0.5))


func _centered(text: String, y: float, size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(_font, Vector2(320 - width / 2, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
