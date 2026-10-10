class_name Ambience
extends Node2D
## Life in the background of every area, drawn over everything else:
##   birds         a little flock crossing the sky now and then (outdoors, by day)
##   butterflies   fluttering over the grass (by day)
##   fireflies     blinking over the grass (at night)
##   leaves        drifting down from the trees
##   sparkles      glints on the water
##   clouds        soft shadows sliding over the ground (outdoors, by day)
##   dust          motes floating in the air (indoors)
## Each one only shows up where it makes sense (the tiles in view decide), and an
## area can turn any of them off (Area.ambience_off) or call it night
## (Area.is_night). On the Genocide path, past halfway, the animals stay away.
## (Added to every area by Area.setup_area.)

const T := Room.TILE
const OUTDOOR := [Room.GRASS, Room.SIDEWALK, Room.ASPHALT, Room.PARKING_LINE, Room.FIELD, Room.FIELD_LINE, Room.ROAD,
	Room.ROAD_LINE, Room.DIRT, Room.PATIO, Room.SAND, Room.WATER, Room.BOARDWALK, Room.SCORCHED, Room.TREE, Room.PALM]
const INDOOR := [Room.HALL_FLOOR, Room.HOUSE_FLOOR, Room.GYM_FLOOR, Room.GYM_LINE, Room.BUNKER_FLOOR]

var area: Node
var room: Room
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()
var _birds: Array = []
var _bird_wait: float = 4.0
var _butterflies: Array = []
var _leaves: Array = []
var _leaf_wait: float = 0.5
var _sparkles: Array = []
var _motes: Array = []
var _night: bool = false
var _off: Array = []


func _ready() -> void:
	_rng.randomize()
	z_index = 2
	if area and area.has_method("is_night"):
		_night = area.is_night()
	if area and "ambience_off" in area:
		_off = area.ambience_off
	if Game.dread() >= 2:
		_off = _off + ["birds", "butterflies"]


func _view() -> Rect2:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	return Rect2(inv * Vector2.ZERO, Vector2(640, 480))


func _tile_at(at: Vector2) -> int:
	return room.get_tile(int(at.x / T), int(at.y / T))


## A random spot in view on one of these tiles (or Vector2.INF if there isn't one).
func _spot_on(view: Rect2, tiles: Array, tries: int = 12) -> Vector2:
	for k in tries:
		var at := view.position + Vector2(_rng.randf() * view.size.x, _rng.randf() * view.size.y)
		if _tile_at(at) in tiles:
			return at
	return Vector2.INF


func _outdoors(view: Rect2) -> bool:
	return _tile_at(view.get_center()) in OUTDOOR


func _process(delta: float) -> void:
	if room == null:
		return
	_time += delta
	var view := _view()
	var outside := _outdoors(view)
	# Birds: a flock now and then, crossing the top of the view.
	if not "birds" in _off and outside and not _night:
		_bird_wait -= delta
		if _bird_wait <= 0.0:
			_bird_wait = _rng.randf_range(9.0, 18.0)
			var left := _rng.randf() < 0.5
			var flock := {"pos": Vector2(view.position.x - 30 if left else view.end.x + 30, view.position.y + _rng.randf_range(30, 160)),
				"vel": Vector2(_rng.randf_range(60, 100) * (1 if left else -1), _rng.randf_range(-8, 8)), "count": _rng.randi_range(3, 6), "phase": _rng.randf() * TAU}
			_birds.append(flock)
	for flock in _birds:
		flock["pos"] += flock["vel"] * delta
	_birds = _birds.filter(func(f: Dictionary) -> bool: return view.grow(80).has_point(f["pos"]))
	# Butterflies over the grass by day.
	if not "butterflies" in _off and not _night:
		if _butterflies.size() < 3 and _rng.randf() < delta * 0.5:
			var home := _spot_on(view, [Room.GRASS])
			if home != Vector2.INF:
				_butterflies.append({"home": home, "phase": _rng.randf() * TAU, "color": [Color8(250, 240, 120), Color8(250, 250, 250), Color8(250, 170, 80), Color8(170, 200, 250)][_rng.randi() % 4]})
		_butterflies = _butterflies.filter(func(b: Dictionary) -> bool: return view.grow(40).has_point(b["home"]))
	# Leaves falling from the trees in view.
	if not "leaves" in _off:
		_leaf_wait -= delta
		if _leaf_wait <= 0.0:
			_leaf_wait = _rng.randf_range(0.35, 0.9)
			var tree := _spot_on(view, [Room.TREE], 6)
			if tree != Vector2.INF:
				_leaves.append({"pos": tree + Vector2(0, -6), "age": 0.0, "color": [Color8(120, 170, 70), Color8(190, 160, 70), Color8(200, 120, 60)][_rng.randi() % 3]})
		for leaf in _leaves:
			leaf["age"] += delta
			leaf["pos"] += Vector2(sin(leaf["age"] * 3.0) * 14.0, 16.0) * delta
		_leaves = _leaves.filter(func(l: Dictionary) -> bool: return l["age"] < 3.0)
	# Glints on the water.
	if not "sparkles" in _off and _rng.randf() < delta * 6.0:
		var spot := _spot_on(view, [Room.WATER], 4)
		if spot != Vector2.INF:
			_sparkles.append({"pos": spot, "age": 0.0})
	for s in _sparkles:
		s["age"] += delta
	_sparkles = _sparkles.filter(func(s: Dictionary) -> bool: return s["age"] < 0.6)
	# Dust in the air, indoors.
	if not "dust" in _off and not outside:
		if _motes.size() < 14:
			var spot := _spot_on(view, INDOOR, 3)
			if spot != Vector2.INF:
				_motes.append({"pos": spot, "age": 0.0, "life": _rng.randf_range(3.0, 6.0)})
		for m in _motes:
			m["age"] += delta
			m["pos"] += Vector2(sin(m["age"] + m["life"]) * 4.0, -3.0) * delta
		_motes = _motes.filter(func(m: Dictionary) -> bool: return m["age"] < m["life"])
	queue_redraw()


func _draw() -> void:
	if room == null:
		return
	var view := _view()
	var outside := _outdoors(view)
	# Cloud shadows, sliding slowly across.
	if not "clouds" in _off and outside and not _night:
		for c in 2:
			var x := fmod(_time * 9.0 + c * 520.0, view.size.x + 400.0) - 200.0
			var center := view.position + Vector2(x, 120 + c * 190)
			draw_set_transform(center, 0.0, Vector2(1.8, 0.8))
			draw_circle(Vector2.ZERO, 70.0, Color(0, 0, 0, 0.05))
			draw_circle(Vector2(40, 10), 50.0, Color(0, 0, 0, 0.04))
			draw_set_transform(Vector2.ZERO)
	for flock in _birds:
		for k in flock["count"]:
			var offset := Vector2(-absf(k - flock["count"] / 2.0) * 9.0 * signf(flock["vel"].x), (k - flock["count"] / 2.0) * 7.0)
			var at: Vector2 = flock["pos"] + offset
			var flap := sin(_time * 10.0 + k + flock["phase"]) * 3.0
			draw_line(at, at + Vector2(-4, -2 + flap), Color(0.15, 0.15, 0.2, 0.75), 1.5)
			draw_line(at, at + Vector2(4, -2 + flap), Color(0.15, 0.15, 0.2, 0.75), 1.5)
	for b in _butterflies:
		var t: float = _time + b["phase"]
		var at: Vector2 = b["home"] + Vector2(sin(t * 0.7) * 24.0 + sin(t * 2.3) * 6.0, cos(t * 0.9) * 14.0 - absf(sin(t * 3.0)) * 6.0)
		var wing := absf(sin(t * 14.0)) * 3.0 + 1.0
		draw_rect(Rect2(at + Vector2(-wing - 1, -2), Vector2(wing, 3)), b["color"])
		draw_rect(Rect2(at + Vector2(1, -2), Vector2(wing, 3)), b["color"])
		draw_rect(Rect2(at + Vector2(0, -2), Vector2(1, 4)), Color8(60, 50, 40))
	if _night and not "fireflies" in _off and outside:
		for k in 12:
			var seed := k * 97.3
			var at := view.position + Vector2(fmod(seed * 13.0 + sin(_time * 0.3 + k) * 40.0, view.size.x), fmod(seed * 7.0 + cos(_time * 0.25 + k) * 30.0, view.size.y))
			if not _tile_at(at) in [Room.GRASS, Room.FIELD, Room.TREE, Room.DIRT]:
				continue
			var blink := clampf(sin(_time * 1.5 + k * 1.7) * 2.0 - 0.6, 0.0, 1.0)
			if blink > 0.0:
				draw_circle(at, 5.0, Color(0.8, 1.0, 0.4, 0.15 * blink))
				draw_circle(at, 1.5, Color(0.9, 1.0, 0.5, blink))
	for leaf in _leaves:
		var fade: float = clampf(3.0 - float(leaf["age"]), 0.0, 1.0)
		var at: Vector2 = leaf["pos"]
		draw_set_transform(at, sin(leaf["age"] * 4.0) * 0.8, Vector2.ONE)
		draw_rect(Rect2(Vector2(-2, -1), Vector2(4, 2)), Color(leaf["color"], fade))
		draw_set_transform(Vector2.ZERO)
	for s in _sparkles:
		var a: float = 1.0 - float(s["age"]) / 0.6
		var at: Vector2 = s["pos"]
		draw_line(at - Vector2(3 * a, 0), at + Vector2(3 * a, 0), Color(1, 1, 1, 0.8 * a), 1.0)
		draw_line(at - Vector2(0, 3 * a), at + Vector2(0, 3 * a), Color(1, 1, 1, 0.8 * a), 1.0)
	for m in _motes:
		var a: float = clampf(minf(m["age"], m["life"] - m["age"]), 0.0, 1.0)
		draw_rect(Rect2(m["pos"], Vector2(1.5, 1.5)), Color(1, 0.95, 0.85, 0.5 * a))
