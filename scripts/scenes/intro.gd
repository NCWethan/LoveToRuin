extends Node2D
## The opening narration, like Undertale's: a sepia picture above, a line of text
## below, one at a time, before Elric arrives at Mt. Carmel.
##
## Each picture is drawn small (PICTURE_SIZE) and scaled up, so it looks like pixel
## art, then a filter turns it sepia with a soft vignette and a bit of film grain.
## Anything strongly red (the fragment, the eyes) keeps a hint of its red.

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

## The picture is drawn this small, then shown twice as big in FRAME.
const PICTURE_SIZE := Vector2i(200, 120)
const FRAME := Rect2(120, 36, 400, 240)
## How long a new picture takes to fade in.
const FADE_TIME := 0.7

const SEPIA_SHADER := """
shader_type canvas_item;
uniform float seed = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233)) + seed) * 43758.5453); }
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 dark = vec3(0.12, 0.07, 0.03);
	vec3 mid = vec3(0.6, 0.44, 0.22);
	vec3 light = vec3(0.98, 0.91, 0.68);
	vec3 s = l < 0.5 ? mix(dark, mid, l * 2.0) : mix(mid, light, (l - 0.5) * 2.0);
	// Strong reds keep a little of their color.
	float red = clamp((c.r - max(c.g, c.b)) * 2.0 - 0.6, 0.0, 1.0);
	s = mix(s, vec3(0.78, 0.18, 0.12), red * 0.7);
	// A soft vignette and a little film grain.
	vec2 d = UV - 0.5;
	s *= 1.0 - dot(d, d) * 1.1;
	s += (hash(floor(UV * vec2(200.0, 120.0))) - 0.5) * 0.05;
	COLOR = vec4(s, c.a);
}
"""

var _font: Font
var _line: int = 0
var _typed: float = 0.0
var _last_beep: int = 0
var _leaving: bool = false
var _time: float = 0.0
var _picture_time: float = 0.0

var _viewport: SubViewport
var _canvas: Node2D
var _picture: TextureRect
var _material: ShaderMaterial

var _back: Texture2D
var _back_walk: Array[Texture2D] = []
var _front: Texture2D


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	_font = ThemeDB.fallback_font
	Game.play_music("title")
	_back = load("res://art/sprites/elric_back.png")
	_back_walk.assign([load("res://art/sprites/elric_back_walk1.png"), _back, load("res://art/sprites/elric_back_walk2.png"), _back])
	_front = load("res://art/sprites/elric.png")

	# The small canvas each picture is drawn on.
	_viewport = SubViewport.new()
	_viewport.size = PICTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_canvas = Node2D.new()
	_viewport.add_child(_canvas)
	_canvas.draw.connect(_draw_picture)

	# ...shown big, in sepia.
	_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = SEPIA_SHADER
	_material.shader = shader
	_picture = TextureRect.new()
	_picture.texture = _viewport.get_texture()
	_picture.position = FRAME.position
	_picture.size = FRAME.size
	_picture.stretch_mode = TextureRect.STRETCH_SCALE
	_picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_picture.material = _material
	add_child(_picture)


func _process(delta: float) -> void:
	_time += delta
	_picture_time += delta
	_canvas.queue_redraw()
	_material.set_shader_parameter("seed", floor(_time * 8.0))
	_picture.modulate.a = clampf(_picture_time / FADE_TIME, 0.0, 1.0)
	if _leaving:
		_picture.modulate.a = 0.0
		return
	var text: String = LINES[_line]
	_typed += delta * TYPE_SPEED * Game.text_speed()

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
			_picture_time = 0.0
		else:
			_leaving = true
			Game.change_scene(NEXT_SCENE)
	queue_redraw()


func _draw() -> void:
	# A thin frame around the picture.
	draw_rect(FRAME.grow(3), Color(0.55, 0.45, 0.3, _picture.modulate.a), false, 1.0)
	var text: String = LINES[_line]
	var shown := text.substr(0, mini(int(_typed), text.length()))
	var lines := shown.split("\n")
	for i in lines.size():
		var width := _font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(_font, Vector2(320 - width / 2, 330 + i * 30), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	if _typed >= text.length():
		draw_string(_font, Vector2(296, 450), "(ENTER)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.5, 0.5))


# --- The pictures ---------------------------------------------------------------
# Drawn in plain colors on a 200 x 120 canvas; the sepia filter does the rest.
# `_picture_time` drives the slow movement in each one.

func _draw_picture() -> void:
	match _line:
		0: _picture_road()
		1: _picture_bus_stop()
		2: _picture_cliff()
		3: _picture_city()
		4: _picture_fragment()
		_: _picture_shadow()


## A sky that fades from `top` at the top to `bottom` at `horizon`.
func _sky(top: Color, bottom: Color, horizon: float) -> void:
	var bands := 12
	for i in bands:
		var y := horizon * i / bands
		_canvas.draw_rect(Rect2(0, y, 200, horizon / bands + 1), top.lerp(bottom, float(i) / (bands - 1)))


## Elric walking away from us, seen from behind, bobbing a little with each step.
func _elric_walking_away(feet: Vector2, scale: float, walk_time: float) -> void:
	var phase := int(walk_time / 0.18) % 4
	var frame: Texture2D = _back_walk[phase]
	var size := frame.get_size() * scale
	var bob := 0.0 if phase % 2 == 1 else -0.6
	# A soft shadow stretching back toward us (the sun is ahead of him).
	_canvas.draw_colored_polygon(PackedVector2Array([feet + Vector2(-4, 0), feet + Vector2(4, 0), feet + Vector2(9, 10), feet + Vector2(-7, 10)]), Color(0.1, 0.08, 0.08, 0.5))
	_canvas.draw_texture_rect(frame, Rect2(feet - Vector2(size.x / 2, size.y - bob), size), false)


## 1. An endless road at sunset, telephone poles going by, Elric walking alone.
func _picture_road() -> void:
	var t := _picture_time
	var horizon := 70.0
	_sky(Color(0.25, 0.2, 0.35), Color(0.95, 0.7, 0.4), horizon)
	# The setting sun, with bands across it.
	_canvas.draw_circle(Vector2(140, horizon - 4), 22, Color(1.0, 0.85, 0.55))
	for i in 4:
		_canvas.draw_rect(Rect2(118, horizon - 12 + i * 4, 44, 1), Color(0.95, 0.7, 0.4))
	# Faraway hills.
	_canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, horizon), Vector2(30, 60), Vector2(70, 66), Vector2(110, 56), Vector2(160, 64), Vector2(200, 58), Vector2(200, horizon)]), Color(0.35, 0.27, 0.3))
	# The ground and the road narrowing to the horizon.
	_canvas.draw_rect(Rect2(0, horizon, 200, 50), Color(0.3, 0.24, 0.2))
	var vanish := Vector2(100, horizon)
	_canvas.draw_colored_polygon(PackedVector2Array([vanish + Vector2(-2, 0), vanish + Vector2(2, 0), Vector2(170, 120), Vector2(30, 120)]), Color(0.18, 0.15, 0.14))
	# Dashes down the middle, rolling toward us.
	for i in 6:
		var d := fmod(i / 6.0 + t * 0.08, 1.0)
		var y := horizon + 50.0 * d * d
		var h := 1.0 + d * 4.0
		_canvas.draw_rect(Rect2(100 - d * 1.5, y, d * 3.0 + 0.5, h), Color(0.95, 0.85, 0.6))
	# Telephone poles along the right side, with the wire sagging between them.
	var tops: Array[Vector2] = []
	for i in 6:
		var d := fmod(i / 6.0 + t * 0.06, 1.0)
		var x := 104.0 + 90.0 * d * d
		var base := horizon + 50.0 * d * d
		var height := 4.0 + 60.0 * d * d
		_canvas.draw_line(Vector2(x, base), Vector2(x, base - height), Color(0.12, 0.1, 0.1), 0.5 + d * 2.0)
		_canvas.draw_line(Vector2(x - height * 0.15, base - height * 0.9), Vector2(x + height * 0.15, base - height * 0.9), Color(0.12, 0.1, 0.1), 0.5 + d)
		tops.append(Vector2(x, base - height * 0.9))
	tops.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	for i in tops.size() - 1:
		var a := tops[i]
		var b := tops[i + 1]
		var points := PackedVector2Array()
		for k in 9:
			var f := k / 8.0
			points.append(a.lerp(b, f) + Vector2(0, sin(f * PI) * (b.x - a.x) * 0.08))
		_canvas.draw_polyline(points, Color(0.12, 0.1, 0.1), 0.5)
	# A couple of birds.
	for i in 3:
		var at := Vector2(fmod(30 + i * 22 + t * 6.0, 220.0) - 10, 22 + i * 7 + sin(t * 2 + i) * 2)
		_canvas.draw_polyline(PackedVector2Array([at + Vector2(-3, -1), at, at + Vector2(3, -1)]), Color(0.2, 0.15, 0.15), 1.0)
	# Elric, walking down the middle of the road toward the sunset, his back to us.
	_elric_walking_away(Vector2(94, 110), 0.9, t)


## 2. A bus stop at night in the rain. The bus is leaving. Elric isn't on it.
func _picture_bus_stop() -> void:
	var t := _picture_time
	_sky(Color(0.05, 0.05, 0.1), Color(0.2, 0.2, 0.28), 80)
	# Faraway city lights.
	for i in 40:
		var at := Vector2(fmod(i * 37.0, 200.0), 60 + fmod(i * 13.0, 18.0))
		_canvas.draw_rect(Rect2(at, Vector2(1, 1)), Color(0.8, 0.75, 0.5, 0.5 + 0.5 * sin(t * 2 + i)))
	# The street and the sidewalk.
	_canvas.draw_rect(Rect2(0, 80, 200, 40), Color(0.15, 0.15, 0.18))
	_canvas.draw_rect(Rect2(0, 98, 200, 4), Color(0.4, 0.4, 0.42))
	# The bus, pulling away to the right, taillights glowing.
	var bus_x := 110.0 + t * 22.0
	_canvas.draw_rect(Rect2(bus_x, 64, 70, 26), Color(0.55, 0.55, 0.6))
	for w in 6:
		_canvas.draw_rect(Rect2(bus_x + 4 + w * 11, 68, 8, 7), Color(0.95, 0.9, 0.6))
	_canvas.draw_circle(Vector2(bus_x + 14, 90), 4, Color(0.1, 0.1, 0.1))
	_canvas.draw_circle(Vector2(bus_x + 56, 90), 4, Color(0.1, 0.1, 0.1))
	_canvas.draw_rect(Rect2(bus_x - 1, 80, 2, 4), Color(1.0, 0.3, 0.2))
	# The streetlight, and the pool of light under it.
	_canvas.draw_colored_polygon(PackedVector2Array([Vector2(48, 30), Vector2(54, 30), Vector2(80, 102), Vector2(22, 102)]), Color(0.9, 0.8, 0.5, 0.25))
	_canvas.draw_line(Vector2(51, 30), Vector2(51, 102), Color(0.1, 0.1, 0.1), 2.0)
	_canvas.draw_rect(Rect2(46, 27, 10, 4), Color(1.0, 0.95, 0.7))
	# The bus stop sign and bench.
	_canvas.draw_line(Vector2(84, 66), Vector2(84, 100), Color(0.1, 0.1, 0.1), 1.0)
	_canvas.draw_rect(Rect2(80, 62, 9, 7), Color(0.85, 0.85, 0.8))
	_canvas.draw_rect(Rect2(62, 90, 18, 3), Color(0.35, 0.25, 0.2))
	# Elric, standing in the light, watching it go.
	var size := _front.get_size() * 0.9
	_canvas.draw_texture_rect(_front, Rect2(Vector2(40 - size.x / 2, 101 - size.y), size), false)
	# Rain.
	for i in 70:
		var fall := fmod(t * (130.0 + i % 7 * 6.0) + i * 17.3 + i * i * 0.61, 130.0) - 10.0
		var x := fmod(i * 29.7 + i * i * 0.37, 210.0) - fall * 0.15
		_canvas.draw_line(Vector2(x, fall), Vector2(x - 1.5, fall + 6), Color(0.7, 0.75, 0.85, 0.5), 1.0)


## 3. Elric at the edge of a cliff, looking out over the ocean.
func _picture_cliff() -> void:
	var t := _picture_time
	_sky(Color(0.45, 0.6, 0.8), Color(0.95, 0.9, 0.75), 62)
	# Clouds drifting by.
	for i in 4:
		var x := fmod(i * 61.0 + t * (3.0 + i), 260.0) - 30.0
		var y := 12.0 + i * 9.0
		for puff in 4:
			_canvas.draw_circle(Vector2(x + puff * 7, y + (puff % 2) * 2), 5.0 + (puff % 2) * 2, Color(1, 1, 1, 0.9))
	# The ocean, with glints of light on it.
	_canvas.draw_rect(Rect2(0, 62, 200, 58), Color(0.35, 0.5, 0.65))
	for i in 24:
		var at := Vector2(fmod(i * 47.0 + t * 4.0, 200.0), 66 + fmod(i * 17.0, 50.0))
		var glint := 0.5 + 0.5 * sin(t * 3.0 + i)
		_canvas.draw_rect(Rect2(at, Vector2(3 + i % 3, 1)), Color(0.95, 0.95, 0.9, glint * 0.8))
	# The cliff, dark against the bright sea.
	_canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, 88), Vector2(70, 84), Vector2(112, 90), Vector2(124, 120), Vector2(0, 120)]), Color(0.2, 0.17, 0.12))
	for i in 12:
		var x := i * 9.0 + 4.0
		var sway := sin(t * 2.5 + i) * 1.5
		_canvas.draw_line(Vector2(x, 86 + (i % 3)), Vector2(x + sway, 81 + (i % 3)), Color(0.25, 0.3, 0.15), 1.0)
	# Seagulls.
	for i in 2:
		var at := Vector2(130 + i * 30 + sin(t + i) * 8, 30 + i * 10 + sin(t * 1.5 + i) * 3)
		var flap := 1.0 + sin(t * 8.0 + i) * 1.5
		_canvas.draw_polyline(PackedVector2Array([at + Vector2(-4, -flap), at, at + Vector2(4, -flap)]), Color(0.25, 0.2, 0.2), 1.0)
	# Elric, seen from behind, looking out.
	var size := _back.get_size() * 1.6
	var sway2 := sin(t * 0.8) * 0.5
	_canvas.draw_texture_rect(_back, Rect2(Vector2(70 + sway2 - size.x / 2, 86 - size.y), size), false)


## 4. The city at night. Little whispers floating up from the streets.
func _picture_city() -> void:
	var t := _picture_time
	_sky(Color(0.05, 0.05, 0.12), Color(0.2, 0.18, 0.3), 120)
	_canvas.draw_circle(Vector2(160, 22), 10, Color(0.95, 0.92, 0.8))
	_canvas.draw_circle(Vector2(164, 19), 9, Color(0.07, 0.07, 0.14))
	# The skyline, with windows flicking on and off.
	var heights := [40, 62, 50, 75, 44, 58, 36, 66, 48, 54]
	for i in heights.size():
		var x := i * 20.0
		var top: float = 120.0 - heights[i]
		_canvas.draw_rect(Rect2(x, top, 18, heights[i]), Color(0.12, 0.12, 0.18))
		for wy in range(int(top) + 4, 112, 6):
			for wx in 3:
				var lit := sin(t * 0.7 + i * 3.1 + wy * 0.7 + wx * 2.3) > 0.2
				if lit:
					_canvas.draw_rect(Rect2(x + 3 + wx * 5, wy, 2, 2), Color(0.95, 0.85, 0.5))
	# Palm trees in the front.
	for p in 2:
		var base := Vector2(28 + p * 140, 120)
		var top := base + Vector2(6 - p * 10, -70)
		_canvas.draw_line(base, top, Color(0.05, 0.05, 0.08), 3.0)
		for f in 6:
			var dir := Vector2.from_angle(-PI / 2 + (f - 2.5) * 0.55 + sin(t + f) * 0.05)
			_canvas.draw_line(top, top + dir * 16 + Vector2(0, 6), Color(0.05, 0.05, 0.08), 2.0)
	# Whispers: little "..." bubbles rising and fading.
	for i in 5:
		var life := fmod(t * 0.35 + i * 0.23, 1.0)
		var at := Vector2(40 + i * 30, 100 - life * 50)
		var alpha := sin(life * PI)
		_canvas.draw_rect(Rect2(at - Vector2(8, 4), Vector2(16, 8)), Color(0.95, 0.95, 0.9, alpha * 0.85))
		for d in 3:
			_canvas.draw_rect(Rect2(at + Vector2(-5 + d * 4, -1), Vector2(2, 2)), Color(0.1, 0.1, 0.1, alpha))


## 5. A fragment lying in the grass, humming.
func _picture_fragment() -> void:
	var t := _picture_time
	_canvas.draw_rect(Rect2(0, 0, 200, 120), Color(0.1, 0.12, 0.08))
	var center := Vector2(100, 70)
	# The hum: rings rippling out.
	for i in 4:
		var r := fmod(t * 18.0 + i * 16.0, 64.0)
		_canvas.draw_arc(center, r, 0, TAU, 32, Color(0.9, 0.2, 0.2, 0.5 * (1.0 - r / 64.0)), 1.0)
	_canvas.draw_circle(center, 18, Color(0.6, 0.1, 0.1, 0.35 + 0.15 * sin(t * 4.0)))
	# The fragment itself.
	var shard := PackedVector2Array([Vector2(0, -16), Vector2(8, -4), Vector2(5, 12), Vector2(-3, 15), Vector2(-8, 1)])
	for p in shard.size():
		shard[p] = center + shard[p].rotated(0.2)
	_canvas.draw_colored_polygon(shard, Color(0.75, 0.08, 0.15))
	_canvas.draw_polyline(shard + PackedVector2Array([shard[0]]), Color(1.0, 0.5, 0.5), 1.0)
	_canvas.draw_line(center + Vector2(-2, -6), center + Vector2(3, 6), Color(0.3, 0.0, 0.05), 1.0)
	# Grass blades in front, swaying.
	for i in 40:
		var x := i * 5.0 + (i % 3)
		var h := 10.0 + (i * 7 % 9) * 2.0
		var sway := sin(t * 2.0 + i * 0.7) * 2.0
		_canvas.draw_line(Vector2(x, 120), Vector2(x + sway, 120 - h), Color(0.3, 0.4, 0.2), 1.5)
	# Motes of light drifting up.
	for i in 10:
		var life := fmod(t * 0.4 + i * 0.1, 1.0)
		var at := center + Vector2(sin(i * 2.3) * 30, 10 - life * 60)
		_canvas.draw_rect(Rect2(at, Vector2(1, 1)), Color(1.0, 0.6, 0.6, 1.0 - life))


## 6. Something huge rising behind the city. A hat. Two eyes.
func _picture_shadow() -> void:
	var t := _picture_time
	_sky(Color(0.02, 0.02, 0.04), Color(0.15, 0.08, 0.08), 120)
	var rise := minf(t * 6.0, 26.0)
	# The shape: a head and shoulders, with a hat, rising up.
	var c := Vector2(100, 78 - rise)
	var dark := Color(0.0, 0.0, 0.0)
	_canvas.draw_rect(Rect2(c + Vector2(-40, 10), Vector2(80, 80)), dark)
	_canvas.draw_rect(Rect2(c + Vector2(-20, -30), Vector2(40, 42)), dark)
	_canvas.draw_rect(Rect2(c + Vector2(-26, -34), Vector2(52, 5)), dark)
	_canvas.draw_rect(Rect2(c + Vector2(-18, -50), Vector2(36, 17)), dark)
	# Glowing eyes, opening.
	var open := clampf((t - 1.0) / 1.2, 0.0, 1.0)
	for side in [-1, 1]:
		var eye := c + Vector2(side * 9, -12)
		_canvas.draw_rect(Rect2(eye - Vector2(3, 1.5 * open), Vector2(6, 3 * open + 0.1)), Color(1.0, 0.1, 0.1))
		_canvas.draw_circle(eye, 6.0 * open, Color(1.0, 0.1, 0.1, 0.25))
	# The city in front of it, small and dark.
	var heights := [14, 22, 18, 30, 16, 26, 12, 24, 20, 18]
	for i in heights.size():
		_canvas.draw_rect(Rect2(i * 20, 120 - heights[i], 18, heights[i]), Color(0.08, 0.06, 0.06))
		if i % 3 == 0:
			_canvas.draw_rect(Rect2(i * 20 + 6, 120 - heights[i] + 4, 2, 2), Color(0.9, 0.8, 0.5))
