extends RefCounted
## Hopkuna's face, up close: the tent's jumpscare. Drawn entirely in code, about
## 380 pixels wide at scale 1, lit from below by a red glow:
##   - a gaunt head with deep shading, black tattoo zigzags and glowing red cracks
##     (like a FRAGMENT's) running through the skin
##   - his black hat, its brim throwing a shadow over the eyes
##   - sunken, bloodshot eyes with tiny red irises and pinpoint pupils
##   - a grin stretched cheek to cheek, wide open, full of jagged yellow teeth
## `laugh` (0 to 1) opens the jaw, so it can move in time with the laugh sound.
## `tint` multiplies every color (for red / cyan ghost copies), and `invert` draws
## a photo-negative.

const SKIN := Color(0.52, 0.42, 0.42)
const SKIN_DARK := Color(0.07, 0.02, 0.03)
const SKIN_LIT := Color(0.95, 0.3, 0.28)
const INK := Color(0.03, 0.01, 0.02)
const GLOW := Color(1.0, 0.12, 0.15)
const TOOTH := Color(0.86, 0.8, 0.6)
const TOOTH_DARK := Color(0.45, 0.38, 0.22)

static var _canvas: CanvasItem
static var _tint: Color = Color.WHITE
static var _invert: bool = false


static func draw(canvas: CanvasItem, center: Vector2, scale: float, laugh: float, t: float, tint: Color = Color.WHITE, invert: bool = false) -> void:
	_canvas = canvas
	_tint = tint
	_invert = invert
	# He throws his head back a little with each laugh, and twitches.
	var tilt := -0.05 * laugh + sin(t * 37.0) * 0.012
	canvas.draw_set_transform(center, tilt, Vector2(scale, scale))
	var jaw := laugh * 48.0
	_shoulders()
	_head(jaw)
	_tattoos(jaw, t)
	_cracks(t)
	_hat()
	_brows()
	for side in [-1.0, 1.0]:
		_eye(side, t)
	_nose()
	_mouth(jaw, t)
	canvas.draw_set_transform(Vector2.ZERO)


## Every color goes through here, for the tint and the negative.
static func _c(color: Color) -> Color:
	var out := color
	if _invert:
		out = Color(1.0 - out.r, 1.0 - out.g, 1.0 - out.b, out.a)
	return out * _tint


## A shaded shape: a fan of triangles from `middle`, so the color fades smoothly
## from the middle out to each edge point's own color.
static func _fan(middle: Vector2, middle_color: Color, points: PackedVector2Array, edge_color: Callable) -> void:
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		_canvas.draw_polygon(PackedVector2Array([middle, a, b]), PackedColorArray([_c(middle_color), _c(edge_color.call(a)), _c(edge_color.call(b))]))


static func _line(points: PackedVector2Array, color: Color, width: float) -> void:
	_canvas.draw_polyline(points, _c(color), width, true)


static func _shoulders() -> void:
	var coat := PackedVector2Array([Vector2(-120, 150), Vector2(120, 150), Vector2(330, 330), Vector2(330, 520), Vector2(-330, 520), Vector2(-330, 330)])
	_canvas.draw_colored_polygon(coat, _c(Color(0.07, 0.05, 0.06)))
	# The neck, in shadow under the jaw.
	_canvas.draw_colored_polygon(PackedVector2Array([Vector2(-70, 120), Vector2(70, 120), Vector2(90, 260), Vector2(-90, 260)]), _c(SKIN_DARK))


## The head: lit red from below, falling off to near-black at the top and sides.
static func _head(jaw: float) -> void:
	var outline := PackedVector2Array()
	for k in 48:
		var a := k * TAU / 48
		var down := maxf(sin(a), 0.0)
		# Wide at the cheekbones, tapering hard to a long, narrow chin.
		var width := 186.0 * (1.0 - 0.42 * down * down) + 8.0 * cos(a * 2.0)
		var height := (200.0 + jaw) if sin(a) > 0.0 else 222.0
		outline.append(Vector2(cos(a) * width, sin(a) * height + (10.0 * down)))
	_fan(Vector2(0, 70), SKIN, outline, func(p: Vector2) -> Color:
		var lit := clampf((p.y + 60.0) / 260.0, 0.0, 1.0)
		return SKIN_DARK.lerp(SKIN_LIT.darkened(0.35), lit * lit))
	_mottling()

	# Hollow cheeks: dark scoops under the cheekbones.
	for side in [-1.0, 1.0]:
		var hollow := PackedVector2Array()
		for k in 12:
			var a := k * TAU / 12
			hollow.append(Vector2(side * 128, 55) + Vector2(cos(a) * 34, sin(a) * 52))
		_fan(Vector2(side * 132, 60), SKIN_DARK.darkened(0.3), hollow, func(_p: Vector2) -> Color: return Color(SKIN_DARK, 0.0))


## Blotches and veins in the skin, so it doesn't look painted on.
static func _mottling() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for d in 160:
		var spot := Vector2(rng.randf_range(-170, 170), rng.randf_range(-180, 180))
		if (spot.x / 175.0) ** 2 + (spot.y / 200.0) ** 2 > 0.85:
			continue
		_canvas.draw_circle(spot, rng.randf_range(1.5, 5.0), _c(Color(0.15, 0.02, 0.05, rng.randf_range(0.1, 0.3))))
	# Dark veins branching up the temples.
	for side in [-1.0, 1.0]:
		var vein := PackedVector2Array([Vector2(side * 168, -10)])
		for k in 6:
			vein.append(vein[-1] + Vector2(side * rng.randf_range(-8, 4), -rng.randf_range(14, 22)))
		_line(vein, Color(0.22, 0.05, 0.2, 0.7), 2.5)
		for b in range(1, 5):
			_line(PackedVector2Array([vein[b], vein[b] + Vector2(-side * rng.randf_range(8, 16), -rng.randf_range(4, 10))]), Color(0.22, 0.05, 0.2, 0.55), 1.5)


## Black tattoo zigzags: across the forehead, down both cheeks, and on the chin.
static func _tattoos(jaw: float, t: float) -> void:
	var forehead := PackedVector2Array()
	for k in 13:
		forehead.append(Vector2(-150 + k * 25, -150 + (12.0 if k % 2 == 0 else -12.0)))
	_line(forehead, INK, 7.0)
	for side in [-1.0, 1.0]:
		var cheek := PackedVector2Array()
		for k in 7:
			cheek.append(Vector2(side * (100 + (14.0 if k % 2 == 0 else -6.0) + k * 6), -15 + k * 26 + (jaw * 0.5 if k > 4 else 0.0)))
		_line(cheek, INK, 6.0)
		# Little marks fanning out by the temples.
		for m in 3:
			var from := Vector2(side * (150 + m * 6), -110 + m * 22)
			_line(PackedVector2Array([from, from + Vector2(side * 22, -8), from + Vector2(side * 30, 6)]), INK, 4.0)
	var chin := PackedVector2Array([Vector2(-30, 170 + jaw), Vector2(-12, 186 + jaw), Vector2(0, 168 + jaw), Vector2(12, 186 + jaw), Vector2(30, 170 + jaw)])
	_line(chin, INK, 5.0)


## Cracks of red light running through the skin, flickering like a FRAGMENT's.
static func _cracks(t: float) -> void:
	var flicker := 0.7 + 0.3 * sin(t * 45.0)
	var cracks := [
		PackedVector2Array([Vector2(-40, -205), Vector2(-52, -170), Vector2(-38, -140), Vector2(-60, -112), Vector2(-50, -90)]),
		PackedVector2Array([Vector2(60, 0), Vector2(78, 28), Vector2(70, 52), Vector2(92, 74)]),
		PackedVector2Array([Vector2(-150, -60), Vector2(-170, -40), Vector2(-160, -8), Vector2(-178, 18)]),
	]
	for crack in cracks:
		_line(crack, Color(GLOW, 0.25 * flicker), 9.0)
		_line(crack, Color(GLOW, flicker), 3.0)
		_line(crack, Color(1, 0.8, 0.7, flicker), 1.0)


static func _hat() -> void:
	# The crown, the band, and a wide brim right across the forehead.
	_canvas.draw_colored_polygon(PackedVector2Array([Vector2(-150, -205), Vector2(-135, -360), Vector2(135, -360), Vector2(150, -205)]), _c(Color(0.05, 0.04, 0.05)))
	_canvas.draw_rect(Rect2(-150, -232, 300, 26), _c(Color(0.16, 0.14, 0.16)))
	var brim := PackedVector2Array()
	for k in 25:
		var x := lerpf(-250, 250, k / 24.0)
		brim.append(Vector2(x, -206 + absf(x) * 0.06))
	for k in 25:
		var x := lerpf(250, -250, k / 24.0)
		brim.append(Vector2(x, -186 + absf(x) * 0.1))
	_canvas.draw_colored_polygon(brim, _c(Color(0.04, 0.03, 0.04)))
	_line(PackedVector2Array([Vector2(-240, -192), Vector2(240, -192)]), Color(0.25, 0.22, 0.25), 1.5)
	# The brim's shadow falling over the forehead.
	for k in 10:
		_canvas.draw_rect(Rect2(-190, -186 + k * 7, 380, 7), _c(Color(0, 0, 0, 0.6 * (1.0 - k / 10.0))))


## Heavy brows pulled down hard toward the middle, with deep creases between them.
static func _brows() -> void:
	for side in [-1.0, 1.0]:
		var brow := PackedVector2Array([Vector2(side * 150, -122), Vector2(side * 100, -112), Vector2(side * 30, -82), Vector2(side * 26, -94), Vector2(side * 96, -130), Vector2(side * 152, -138)])
		_canvas.draw_colored_polygon(brow, _c(INK))
	for k in 3:
		var x := -8.0 + k * 8.0
		_line(PackedVector2Array([Vector2(x, -110), Vector2(x * 1.4, -78)]), SKIN_DARK.darkened(0.5), 2.0)


## A sunken, bloodshot eye with a tiny glowing red iris and a pinpoint pupil.
static func _eye(side: float, t: float) -> void:
	var middle := Vector2(side * 76, -52)
	# The socket: a dark hollow.
	var socket := PackedVector2Array()
	for k in 20:
		var a := k * TAU / 20
		socket.append(middle + Vector2(cos(a) * 74, sin(a) * 56))
	_fan(middle, INK, socket, func(_p: Vector2) -> Color: return Color(SKIN_DARK, 0.0))
	_fan(middle, INK, socket, func(_p: Vector2) -> Color: return Color(SKIN_DARK, 0.0))
	# Bags and wrinkles under the eye.
	for k in 3:
		var y := 20.0 + k * 9.0
		_line(PackedVector2Array([middle + Vector2(-38, y - 6), middle + Vector2(0, y), middle + Vector2(38, y - 6)]), SKIN_DARK.darkened(0.4), 2.0)
	# The eye, opened far too wide.
	var white := PackedVector2Array()
	for k in 24:
		var a := k * TAU / 24
		white.append(middle + Vector2(cos(a) * 36, sin(a) * (19 if sin(a) < 0 else 22)))
	_fan(middle, Color(0.85, 0.72, 0.62), white, func(_p: Vector2) -> Color: return Color(0.45, 0.12, 0.12))
	# Veins creeping in from the edges.
	var rng := RandomNumberGenerator.new()
	rng.seed = 41 + int(side)
	for v in 9:
		var a := rng.randf() * TAU
		var from := middle + Vector2(cos(a) * 35, sin(a) * 19)
		var mid := from.lerp(middle, 0.35) + Vector2(rng.randf_range(-5, 5), rng.randf_range(-3, 3))
		var end := from.lerp(middle, 0.6) + Vector2(rng.randf_range(-6, 6), rng.randf_range(-3, 3))
		_line(PackedVector2Array([from, mid, end]), Color(0.75, 0.08, 0.1, 0.85), 1.5)
	# The iris twitches around, never quite still.
	var look := Vector2(sin(t * 23.0 + side) * 3.0, cos(t * 31.0) * 2.0)
	var iris := middle + look
	_canvas.draw_circle(iris, 30, _c(Color(GLOW, 0.22)))
	_canvas.draw_circle(iris, 12, _c(Color(0.3, 0.0, 0.02)))
	_canvas.draw_circle(iris, 10, _c(GLOW))
	_canvas.draw_circle(iris, 5, _c(Color(1.0, 0.6, 0.35)))
	_canvas.draw_circle(iris, 1.8, _c(INK))
	_canvas.draw_circle(iris + Vector2(-4, -4), 2.0, _c(Color(1, 1, 1, 0.9)))
	# Lids: the upper one a hard dark line.
	var lid := PackedVector2Array()
	for k in 13:
		var a := PI + k * PI / 12
		lid.append(middle + Vector2(cos(a) * 38, sin(a) * 21))
	_line(lid, INK, 6.0)
	# Black tears running down the cheek.
	for d in 2:
		var from := middle + Vector2(side * (-10.0 + d * 18.0), 20)
		var run := 70.0 + d * 45.0 + sin(t * 3.0 + d) * 6.0
		var drip := PackedVector2Array([from, from + Vector2(side * 3, run * 0.4), from + Vector2(-side * 2, run * 0.75), from + Vector2(side * 2, run)])
		_line(drip, INK, 5.0 - d)
		_line(drip, Color(0.5, 0.05, 0.08, 0.6), 1.0)
		_canvas.draw_circle(drip[-1] + Vector2(0, 3), 4.5 - d, _c(INK))


static func _nose() -> void:
	# A thin, lit bridge and a dark hollow where the nose should be.
	_line(PackedVector2Array([Vector2(-2, -60), Vector2(-4, 0), Vector2(0, 14)]), SKIN_LIT.darkened(0.4), 3.0)
	_canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, -6), Vector2(14, 22), Vector2(8, 34), Vector2(-8, 34), Vector2(-14, 22)]), _c(Color(INK, 0.85)))
	for side in [-1.0, 1.0]:
		_canvas.draw_colored_polygon(PackedVector2Array([Vector2(side * 6, 30), Vector2(side * 26, 24), Vector2(side * 22, 34)]), _c(INK))
		# Deep creases from the nose down to the corners of the grin.
		_line(PackedVector2Array([Vector2(side * 34, 22), Vector2(side * 70, 52), Vector2(side * 110, 66), Vector2(side * 150, 62)]), SKIN_DARK.darkened(0.5), 4.0)


## The grin: stretched from cheek to cheek, wide open, jagged teeth in two rows.
static func _mouth(jaw: float, t: float) -> void:
	var corner := 156.0
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for k in 21:
		var f := k / 20.0
		var x := lerpf(-corner, corner, f)
		var bend := 1.0 - pow(2.0 * f - 1.0, 2.0)
		# Corners pulled up high: a grin, not a scream.
		upper.append(Vector2(x, 60 - 10 * (1.0 - bend) + bend * 22))
		lower.append(Vector2(x, 60 - 10 * (1.0 - bend) + bend * (40 + jaw)))
	var opening := upper.duplicate()
	for k in range(lower.size() - 1, -1, -1):
		opening.append(lower[k])
	# Inside: a red throat fading to black.
	_fan(Vector2(0, 92 + jaw * 0.5), Color(0.0, 0.0, 0.0), opening, func(_p: Vector2) -> Color: return Color(0.28, 0.0, 0.03))
	_fan(Vector2(0, 92 + jaw * 0.5), Color(0.0, 0.0, 0.0), opening, func(_p: Vector2) -> Color: return Color(0.0, 0.0, 0.0, 0.0))
	# A dark tongue, low in the mouth.
	_canvas.draw_circle(Vector2(0, 80 + jaw * 0.65), 14 + jaw * 0.12, _c(Color(0.25, 0.02, 0.05)))
	# Gums along the top and bottom.
	_line(upper, Color(0.55, 0.06, 0.12), 9.0)
	_line(lower, Color(0.55, 0.06, 0.12), 9.0)
	# Teeth: long and sharp in the middle, smaller toward the corners, uneven.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for row in 2:
		var edge := upper if row == 0 else lower
		var dir := 1.0 if row == 0 else -1.0
		for k in range(1, edge.size() - 1):
			var base_a := edge[k - 1].lerp(edge[k], 0.5)
			var base_b := edge[k].lerp(edge[k + 1], 0.5)
			var bend := 1.0 - pow(2.0 * k / 20.0 - 1.0, 2.0)
			var length := (10.0 + 22.0 * bend) * rng.randf_range(0.7, 1.25)
			if rng.randf() < 0.08:
				continue
			var tip := edge[k] + Vector2(rng.randf_range(-3, 3), dir * length)
			_canvas.draw_colored_polygon(PackedVector2Array([base_a, base_b, tip]), _c(TOOTH.darkened(rng.randf_range(0.0, 0.3))))
			_line(PackedVector2Array([base_a, tip, base_b]), TOOTH_DARK, 1.2)
	# Blood running down from the gums over the top teeth.
	for b in [-110.0, -48.0, 12.0, 66.0, 120.0]:
		var top := Vector2(b, 62 + 20 * (1.0 - pow(b / corner, 2.0)))
		var length := 10.0 + absf(sin(b)) * 16.0
		_line(PackedVector2Array([top, top + Vector2(1, length)]), Color(0.5, 0.0, 0.04), 3.0)
		_canvas.draw_circle(top + Vector2(1, length), 2.5, _c(Color(0.5, 0.0, 0.04)))
	# Strings of spit stretching between the rows as the jaw opens.
	if jaw > 15.0:
		for s in [-60.0, 25.0, 90.0]:
			var top := Vector2(s, 70 + 20 * (1.0 - pow(s / corner, 2.0)))
			var bottom := Vector2(s + 4, 70 + (36 + jaw) * (1.0 - pow(s / corner, 2.0)))
			_line(PackedVector2Array([top, top.lerp(bottom, 0.5) + Vector2(3, 4), bottom]), Color(0.9, 0.85, 0.85, 0.5), 1.0)
	# Cracked lips around it all.
	_line(upper, Color(0.25, 0.04, 0.06), 3.0)
	_line(lower, Color(0.25, 0.04, 0.06), 3.0)
