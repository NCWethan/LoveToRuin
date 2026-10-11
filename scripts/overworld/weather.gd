class_name Weather
extends CanvasLayer
## The sky over an outdoor area: clear, cloudy, rain, or a thunderstorm
## (Game.weather picks, and changes it every few minutes).
##   clear    nothing
##   cloudy   just as bright, but greyer
##   rain     darker and a little blue; rain slanting down, splashes, its hiss
##   storm    darker still; heavier rain, lightning, thunder
## It all fades away indoors (the tiles in view decide, like Ambience), and
## changes fade in and out over a few seconds. Areas that shouldn't have weather
## (memories, the bunker, the big story nights) say so (Area.weather_ok).
## (Added to every area by Area.setup_area.)

const LOOKS := {
	# grey: how washed-out the colors are. dark: how much darker. tint: a cast.
	"clear": {"grey": 0.0, "dark": 0.0, "tint": Color(1, 1, 1), "drops": 0},
	"cloudy": {"grey": 0.42, "dark": 0.0, "tint": Color(0.99, 1.0, 1.03), "drops": 0},
	"rain": {"grey": 0.45, "dark": 0.3, "tint": Color(0.92, 0.97, 1.08), "drops": 90},
	"storm": {"grey": 0.55, "dark": 0.48, "tint": Color(0.9, 0.95, 1.12), "drops": 170},
}
const SCREEN := Vector2(640, 480)
## How the rain slants (pixels sideways per pixel down).
const SLANT := 0.28

var area: Node
var room: Room

var _shade: ColorRect
var _rain: Node2D
var _sound: AudioStreamPlayer
var _shown := "clear"
## The current look, fading toward the weather's (grey, dark, tint, drops).
var _grey := 0.0
var _dark := 0.0
var _tint := Color(1, 1, 1)
var _drops := 0.0
## 0 indoors, 1 outdoors (fades).
var _outside := 1.0
var _drop_list: Array = []
var _splashes: Array = []
var _flash := 0.0
var _next_flash := 8.0
var _thunder_in := -1.0
var _check := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	layer = 3
	_rng.randomize()
	_shade = ColorRect.new()
	_shade.size = SCREEN
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = _make_shader()
	_shade.material = material
	add_child(_shade)
	_rain = Node2D.new()
	_rain.draw.connect(_draw_rain)
	add_child(_rain)
	_sound = AudioStreamPlayer.new()
	_sound.bus = "SFX"
	_sound.stream = Game.get_sound("rain")
	_sound.volume_db = -80.0
	add_child(_sound)
	# Start already looking like the weather (no fade on arrival).
	_shown = Game.weather
	var look: Dictionary = LOOKS[_shown]
	_grey = look["grey"]
	_dark = look["dark"]
	_tint = look["tint"]
	_drops = look["drops"]
	_outside = 1.0 if _is_outdoors() else 0.0
	_apply()


func _make_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float grey = 0.0;
uniform float dark = 0.0;
uniform vec3 tint = vec3(1.0);
uniform float flash = 0.0;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), grey);
	c = c * (1.0 - dark) * tint;
	c = mix(c, vec3(1.0), flash);
	COLOR = vec4(c, 1.0);
}
"""
	return shader


func _is_outdoors() -> bool:
	if room == null:
		return true
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	var center: Vector2 = inv * (SCREEN / 2.0)
	return room.get_tile(int(center.x / Room.TILE), int(center.y / Room.TILE)) in Ambience.OUTDOOR


func _process(delta: float) -> void:
	# Every so often, the sky might change.
	_check -= delta
	if _check <= 0.0:
		_check = 10.0
		Game.update_weather()
	_shown = Game.weather
	var look: Dictionary = LOOKS[_shown]
	var k := minf(1.0, delta * 0.35)
	_grey = lerpf(_grey, look["grey"], k)
	_dark = lerpf(_dark, look["dark"], k)
	_tint = _tint.lerp(look["tint"], k)
	_drops = lerpf(_drops, float(look["drops"]), k)
	_outside = move_toward(_outside, 1.0 if _is_outdoors() else 0.0, delta * 1.5)
	_update_rain(delta)
	_update_lightning(delta)
	# The rain's hiss: louder in a storm, gone indoors.
	var loud := _drops / 170.0 * _outside
	if loud > 0.02:
		if not _sound.playing:
			_sound.play()
		_sound.volume_db = linear_to_db(loud * (1.3 if _shown == "storm" else 1.0))
	elif _sound.playing:
		_sound.stop()
	_apply()
	_rain.queue_redraw()


func _apply() -> void:
	var m := _shade.material as ShaderMaterial
	m.set_shader_parameter("grey", _grey * _outside)
	m.set_shader_parameter("dark", _dark * _outside)
	var t := Color(1, 1, 1).lerp(_tint, _outside)
	m.set_shader_parameter("tint", Vector3(t.r, t.g, t.b))
	m.set_shader_parameter("flash", _flash * _outside)
	_shade.visible = _grey > 0.005 or _dark > 0.005 or _flash > 0.0


func _update_rain(delta: float) -> void:
	var want := int(_drops * _outside)
	while _drop_list.size() < want:
		_drop_list.append(_new_drop(true))
	while _drop_list.size() > want:
		_drop_list.pop_back()
	var speed := 520.0 if _shown == "storm" else 420.0
	for d in _drop_list:
		d["pos"] += Vector2(SLANT, 1.0) * speed * d["speed"] * delta
		if d["pos"].y > d["land"]:
			# It lands: a little splash, and a new drop up top.
			if _splashes.size() < 40:
				_splashes.append({"pos": d["pos"], "age": 0.0})
			d.merge(_new_drop(false), true)
	for s in _splashes:
		s["age"] += delta
	_splashes = _splashes.filter(func(s: Dictionary) -> bool: return s["age"] < 0.25)


func _new_drop(anywhere: bool) -> Dictionary:
	var y := _rng.randf_range(-40, SCREEN.y) if anywhere else _rng.randf_range(-60, -10)
	return {"pos": Vector2(_rng.randf_range(-120, SCREEN.x), y), "speed": _rng.randf_range(0.8, 1.2),
		"land": _rng.randf_range(SCREEN.y * 0.25, SCREEN.y + 20), "len": _rng.randf_range(7, 13)}


## In a storm, lightning now and then: a flash (or two), and thunder after it.
func _update_lightning(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 3.5)
	if _thunder_in > 0.0:
		_thunder_in -= delta
		if _thunder_in <= 0.0 and _outside > 0.3:
			Game.play_sfx("thunder", _rng.randf_range(0.85, 1.1))
	if _shown != "storm" or _outside < 0.5:
		return
	_next_flash -= delta
	if _next_flash <= 0.0:
		_next_flash = _rng.randf_range(7.0, 16.0)
		var strength := 0.15 if Game.settings.get("reduce_flashing", false) else 0.6
		_flash = strength
		# A second flicker, sometimes.
		if _rng.randf() < 0.5:
			get_tree().create_timer(0.18).timeout.connect(func() -> void: _flash = maxf(_flash, strength * 0.7))
		_thunder_in = _rng.randf_range(0.4, 1.4)


func _draw_rain() -> void:
	if _drop_list.is_empty() and _splashes.is_empty():
		return
	var streak := Color(0.75, 0.82, 0.95, 0.45)
	for d in _drop_list:
		var p: Vector2 = d["pos"]
		_rain.draw_line(p, p - Vector2(SLANT, 1.0) * d["len"], streak, 1.0)
	for s in _splashes:
		var age: float = s["age"] / 0.25
		var c := Color(0.8, 0.86, 0.96, 0.5 * (1.0 - age))
		var r := 2.0 + age * 4.0
		_rain.draw_line(s["pos"] + Vector2(-r, 0), s["pos"] + Vector2(-r * 0.4, -1), c, 1.0)
		_rain.draw_line(s["pos"] + Vector2(r, 0), s["pos"] + Vector2(r * 0.4, -1), c, 1.0)
