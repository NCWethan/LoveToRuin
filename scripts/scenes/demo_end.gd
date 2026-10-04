extends Node2D
## Shown when Elric leaves Mt. Carmel: the end of what's built so far.

var _font: Font
var _time: float = 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	_font = ThemeDB.fallback_font
	Game.play_music("title")


func _process(delta: float) -> void:
	_time += delta
	var wait := 2.5 if Game.flags.get("chapter1_done", false) else 1.5
	if _time > wait and Input.is_action_just_pressed("confirm") and not Game.transitioning:
		Game.change_scene(Game.TITLE_SCENE)
	queue_redraw()


## The route endings for Chapter 1: the name shown, its color, and a closing line.
const ROUTE_ENDINGS := {
	"pacifist": ["PACIFIST", Color(1.0, 0.95, 0.4), "Elric found something worth staying for."],
	"neutral": ["NEUTRAL", Color(0.8, 0.8, 0.8), "Elric keeps wandering... for now.\nThe Corps' offer still stands."],
	"genocide": ["GENOCIDE", Color(1.0, 0.25, 0.3), "...You can't go back now."],
}


func _draw() -> void:
	var alpha := clampf(_time / 1.0, 0.0, 1.0)
	if Game.flags.get("chapter1_done", false):
		_draw_chapter_complete(alpha)
		return
	_centered("LOVE TO RUIN", 140, 44, Color(1, 1, 1, alpha))
	_centered("Chapter 1  -  to be continued", 190, 18, Color(0.8, 0.8, 0.8, alpha))
	var next := "Next stop: the PQ Mall."
	if Game.flags.get("westview_done", false):
		next = "2 of 12 fragments found.   Next stop: Hilltop Park."
	elif Game.flags.get("mall_done", false):
		next = "Next stop: Westview High School... after dark."
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
		_centered("(press ENTER to return to the title)", 440, 12, Color(0.5, 0.5, 0.5))


func _draw_chapter_complete(alpha: float) -> void:
	var ending: Array = ROUTE_ENDINGS.get(Game.flags.get("route", "neutral"), ROUTE_ENDINGS["neutral"])
	var route_color: Color = ending[1]
	route_color.a = alpha
	_centered("LOVE TO RUIN", 110, 44, Color(1, 1, 1, alpha))
	_centered("CHAPTER 1 COMPLETE", 160, 20, Color(0.85, 0.85, 0.85, alpha))
	_centered("ROUTE:  " + ending[0], 220, 26, route_color)
	var lines: PackedStringArray = (ending[2] as String).split("\n")
	for i in lines.size():
		_centered(lines[i], 262 + i * 22, 16, Color(0.8, 0.8, 0.8, alpha))
	_centered("3 of 12 fragments found.", 330, 14, Color(1, 0.6, 0.6, alpha))
	_centered("LV %d     BOND %d     EXP %d     $%d" % [Game.lv(), Game.bond, Game.exp_points, Game.money], 362, 16, Color(1, 1, 1, alpha))
	if _time > 2.5:
		_centered("Thank you for playing!", 410, 16, Color(1, 1, 0.6))
		_centered("(press ENTER to return to the title)", 440, 12, Color(0.5, 0.5, 0.5))


func _centered(text: String, y: float, size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(_font, Vector2(320 - width / 2, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
