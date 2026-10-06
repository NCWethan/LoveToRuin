extends Node2D
## Shown when Elric leaves Mt. Carmel: the end of what's built so far.

var _font: Font
var _time: float = 0.0
## Genocide only: after CONTINUE, a page saying the Corps' base is closed to you.
var _sealed: bool = false

const CORPS_BASE_SCENE := "res://scenes/corps_base.tscn"


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	# Going with Hop: straight to the bolted hatch (no chapter screen).
	if Game.flags.get("chapter1_done", false) and Game.flags.get("route", "") == "genocide":
		_sealed = true
	_font = ThemeDB.fallback_font
	Game.play_music("title")


func _process(delta: float) -> void:
	_time += delta
	var wait := 2.5 if Game.flags.get("chapter1_done", false) else 1.5
	if _time > wait and Input.is_action_just_pressed("confirm") and not Game.transitioning:
		_continue()
	queue_redraw()


## After Chapter 1: CONTINUE goes down into the Corps' base (Chapter 2), unless
## Elric went with Hop. Then the way is closed.
func _continue() -> void:
	if not Game.flags.get("chapter1_done", false) or _sealed:
		Game.change_scene(Game.TITLE_SCENE)
	elif Game.flags.get("route", "") == "genocide":
		_sealed = true
		_time = 0.0
		Game.play_sfx("door")
	else:
		Game.play_music("", 1.0)
		Game.change_scene(CORPS_BASE_SCENE)


## The route endings for Chapter 1: the name shown, its color, and a closing line.
const ROUTE_ENDINGS := {
	"pacifist": ["PACIFIST", Color(1.0, 0.95, 0.4), "Elric found something worth staying for."],
	"neutral": ["NEUTRAL", Color(0.8, 0.8, 0.8), "Elric keeps wandering... for now.\nThe Corps' offer still stands."],
	"genocide": ["GENOCIDE", Color(1.0, 0.25, 0.3), "...You can't go back now."],
}


func _draw() -> void:
	var alpha := clampf(_time / 1.0, 0.0, 1.0)
	if _sealed:
		_draw_sealed(alpha)
		return
	if Game.flags.get("chapter1_done", false):
		_draw_chapter_complete(alpha)
		return
	_centered("LOVE TO RUIN", 140, 44, Color(1, 1, 1, alpha))
	_centered("To be continued", 190, 18, Color(0.8, 0.8, 0.8, alpha))
	var next := "Next stop: the PQ Mall."
	if Game.flags.get("westview_done", false):
		next = "2 of 12 fragments found.   Next stop: Westview Field."
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
	_draw_fragment_ring(alpha)
	_centered("LOVE TO RUIN", 110, 44, Color(1, 1, 1, alpha))
	_centered("CHAPTER 1 COMPLETE", 160, 20, Color(0.85, 0.85, 0.85, alpha))
	# (The route's name stays hidden; only its closing line shows.)
	var lines: PackedStringArray = (ending[2] as String).split("\n")
	for i in lines.size():
		_centered(lines[i], 230 + i * 24, 18, route_color)
	_centered("3 of 12 fragments found.", 330, 14, Color(1, 0.6, 0.6, alpha))
	_centered("LV %d     BOND %d     EXP %d     $%d" % [Game.lv(), Game.bond, Game.exp_points, Game.money], 362, 16, Color(1, 1, 1, alpha))
	if _time > 2.5:
		_centered("Thank you for playing!", 410, 16, Color(1, 1, 0.6))
		_centered("CONTINUE  (press ENTER)", 440, 14, Color(1, 1, 1, 0.55 + 0.45 * sin(_time * 3.0)))


## Genocide: leaving Hop's house the morning after. (What comes next isn't built yet.)
func _draw_sealed(alpha: float) -> void:
	_centered("Hop locks the door behind you.", 190, 18, Color(0.8, 0.8, 0.8, alpha))
	_centered("The city is waiting.", 230, 18, Color(0.8, 0.8, 0.8, alpha))
	_centered("So is someone else.", 270, 18, Color(1.0, 0.25, 0.3, alpha))
	# Relic (green), saying "we" for the first time.
	_centered("...And so are we.", 310, 18, Color(0.45, 0.95, 0.55, clampf((_time - 1.5) / 1.0, 0.0, 1.0)))
	if _time > 2.5:
		_centered("What comes next is still being written.", 370, 14, Color(0.6, 0.6, 0.6))
		_centered("(press ENTER to return to the title)", 440, 12, Color(0.5, 0.5, 0.5))


## Behind the text: a great ring split into twelve pieces, one for each FRAGMENT,
## turning slowly. The three found so far fill in deep red one by one (with a
## flash), and glow. The other nine are just faint outlines... for now.
const RING_CENTER := Vector2(320, 230)
const RING_OUTER := 190.0
const RING_INNER := 150.0
const FRAGMENTS_FOUND := 3


func _draw_fragment_ring(alpha: float) -> void:
	var spin := _time * 0.05
	var piece := TAU / 12
	var gap := 0.04
	var red := Color(0.8, 0.05, 0.12)
	for k in 12:
		var start := spin + k * piece + gap - PI / 2
		var end := spin + (k + 1) * piece - gap - PI / 2
		var shape := PackedVector2Array()
		for s in 9:
			shape.append(RING_CENTER + Vector2.from_angle(lerpf(start, end, s / 8.0)) * RING_OUTER)
		for s in 9:
			shape.append(RING_CENTER + Vector2.from_angle(lerpf(end, start, s / 8.0)) * RING_INNER)
		var outline := shape.duplicate()
		outline.append(shape[0])
		var fill_at := 1.0 + k * 0.6
		if k < FRAGMENTS_FOUND and _time >= fill_at:
			var since := _time - fill_at
			var flash := clampf(1.0 - since / 0.4, 0.0, 1.0)
			var glow := 0.5 + 0.15 * sin(_time * 2.0 + k)
			# A soft glow, the red piece, and a white flash as it fills in.
			var halo := PackedVector2Array()
			for p in shape:
				halo.append(RING_CENTER + (p - RING_CENTER) * (1.0 + 0.03 * glow))
			draw_colored_polygon(halo, Color(red, 0.25 * alpha * glow))
			draw_colored_polygon(shape, Color(red.lerp(Color.WHITE, flash), alpha * (0.55 + 0.25 * glow)))
			draw_polyline(outline, Color(1, 0.35, 0.4, alpha), 1.5)
		else:
			draw_polyline(outline, Color(0.6, 0.35, 0.38, 0.6 * alpha), 1.0)
	# Thin circles holding it all together.
	draw_arc(RING_CENTER, RING_OUTER + 8.0, 0, TAU, 96, Color(0.6, 0.2, 0.25, 0.25 * alpha), 1.0)
	draw_arc(RING_CENTER, RING_INNER - 8.0, 0, TAU, 96, Color(0.6, 0.2, 0.25, 0.25 * alpha), 1.0)


func _centered(text: String, y: float, size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(_font, Vector2(320 - width / 2, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
