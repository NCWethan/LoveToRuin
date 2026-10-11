class_name Scenery
extends RefCounted
## Detailed drawings of big, one-off pieces of scenery (a junk heap, a stack of
## crushed cars, a van...), for areas to draw on a static layer
## (Area.add_static_layer), so the detail costs nothing frame to frame.
## Everything is built from a seed, so it looks the same every time.


static func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


## An oval shadow on the ground.
static func shadow(ci: CanvasItem, center: Vector2, size: Vector2, alpha: float = 0.25) -> void:
	ci.draw_set_transform(center, 0.0, Vector2(1.0, size.y / size.x))
	ci.draw_circle(Vector2.ZERO, size.x, Color(0, 0, 0, alpha))
	ci.draw_set_transform(Vector2.ZERO)


# --- The junkyard ---------------------------------------------------------------------

## A heap of junk filling `r`: a lumpy mound, shaded, piled with tires, hubcaps,
## rusted sheet metal, pipes, planks, a barrel, a fridge, an old TV...
static func junk_heap(ci: CanvasItem, r: Rect2, seed: int) -> void:
	var rng := _rng(seed)
	# The mound: a bumpy outline, darker at the bottom.
	shadow(ci, r.get_center() + Vector2(4, r.size.y * 0.42), Vector2(r.size.x * 0.55, r.size.y * 0.22), 0.3)
	var outline := PackedVector2Array()
	var steps := 14
	for i in steps + 1:
		var t := i / float(steps)
		var bump := pow(sin(t * PI), 0.7) * r.size.y * 0.8 + rng.randf_range(-5, 5)
		outline.append(Vector2(r.position.x + t * r.size.x, r.end.y - 4 - bump))
	outline.append(r.end)
	outline.append(Vector2(r.position.x, r.end.y))
	ci.draw_colored_polygon(outline, Color8(92, 80, 68))
	# Lighter toward the top-left (the light comes from there).
	var lit := PackedVector2Array()
	for i in range(0, steps / 2 + 1):
		lit.append(outline[i] + Vector2(0, 3))
	lit.append(Vector2(r.position.x + r.size.x * 0.5, r.end.y - 6))
	lit.append(Vector2(r.position.x + 4, r.end.y - 4))
	ci.draw_colored_polygon(lit, Color8(112, 98, 84))
	# Grit and rust flecks all over it.
	for i in int(r.size.x * r.size.y / 60.0):
		var at := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y + r.size.y * 0.3, r.end.y - 2))
		ci.draw_rect(Rect2(at, Vector2(1, 1)), [Color8(70, 60, 52), Color8(140, 96, 66), Color8(128, 124, 118)][i % 3])
	# The junk, back to front.
	var items: Array = []
	var count := int(r.size.x / 9.0)
	for i in count:
		var x := rng.randf_range(r.position.x + 6, r.end.x - 6)
		var top := _heap_top(outline, x)
		var y := rng.randf_range(top + 4, r.end.y - 6)
		items.append([y, x, rng.randi() % 9, rng.randi()])
	items.sort_custom(func(a, b) -> bool: return a[0] < b[0])
	for item in items:
		_junk(ci, Vector2(item[1], item[0]), item[2], item[3])


static func _heap_top(outline: PackedVector2Array, x: float) -> float:
	for i in outline.size() - 3:
		if outline[i].x <= x and outline[i + 1].x >= x:
			var t := (x - outline[i].x) / maxf(outline[i + 1].x - outline[i].x, 0.01)
			return lerpf(outline[i].y, outline[i + 1].y, t)
	return outline[0].y


static func _junk(ci: CanvasItem, at: Vector2, kind: int, seed: int) -> void:
	var rng := _rng(seed)
	match kind:
		0, 1:
			# A tire: tread, sidewall, the hole in the middle.
			var r := rng.randf_range(5.0, 7.0)
			ci.draw_circle(at, r, Color8(30, 30, 34))
			for k in 10:
				var a := k * TAU / 10.0
				ci.draw_rect(Rect2(at + Vector2.from_angle(a) * (r - 1.0) - Vector2(1, 1), Vector2(2, 2)), Color8(48, 48, 54))
			ci.draw_circle(at, r * 0.5, Color8(56, 56, 60))
			ci.draw_circle(at, r * 0.32, Color8(18, 18, 20))
			ci.draw_arc(at, r - 0.5, PI * 1.1, PI * 1.6, 6, Color8(80, 80, 86), 1.0)
		2:
			# A hubcap, catching the light.
			ci.draw_circle(at, 4.5, Color8(150, 152, 160))
			ci.draw_circle(at, 3.5, Color8(196, 198, 206))
			for k in 5:
				ci.draw_line(at, at + Vector2.from_angle(k * TAU / 5.0) * 3.5, Color8(130, 132, 140), 1.0)
			ci.draw_rect(Rect2(at + Vector2(-2, -3), Vector2(1, 1)), Color.WHITE)
		3:
			# A sheet of metal, rusting, with rivets.
			var size := Vector2(rng.randf_range(10, 16), rng.randf_range(6, 9))
			var base: Color = [Color8(150, 80, 60), Color8(110, 130, 150), Color8(170, 160, 90)][rng.randi() % 3]
			var rot := rng.randf_range(-0.4, 0.4)
			ci.draw_set_transform(at, rot, Vector2.ONE)
			ci.draw_rect(Rect2(-size / 2, size), base)
			ci.draw_rect(Rect2(-size / 2, Vector2(size.x, 1)), base.lightened(0.2))
			ci.draw_rect(Rect2(-size / 2 + Vector2(0, size.y - 1), Vector2(size.x, 1)), base.darkened(0.3))
			for k in 3:
				ci.draw_rect(Rect2(Vector2(rng.randf_range(-size.x / 2, size.x / 2 - 2), rng.randf_range(-size.y / 2, size.y / 2 - 2)), Vector2(3, 2)), Color8(150, 82, 40))
			ci.draw_rect(Rect2(-size / 2 + Vector2(1, 1), Vector2(1, 1)), base.darkened(0.4))
			ci.draw_rect(Rect2(Vector2(size.x / 2 - 2, -size.y / 2 + 1), Vector2(1, 1)), base.darkened(0.4))
			ci.draw_set_transform(Vector2.ZERO)
		4:
			# A pipe, at an angle.
			var dir := Vector2.from_angle(rng.randf_range(-0.6, 0.6)) * rng.randf_range(8, 14)
			ci.draw_line(at - dir, at + dir, Color8(110, 112, 118), 3.0)
			ci.draw_line(at - dir + Vector2(0, -1), at + dir + Vector2(0, -1), Color8(168, 170, 176), 1.0)
			ci.draw_circle(at + dir, 1.8, Color8(60, 60, 64))
		5:
			# A plank, with a nail sticking out.
			var size := Vector2(rng.randf_range(12, 18), 3)
			ci.draw_set_transform(at, rng.randf_range(-0.5, 0.5), Vector2.ONE)
			ci.draw_rect(Rect2(-size / 2, size), Color8(150, 112, 70))
			ci.draw_rect(Rect2(-size / 2, Vector2(size.x, 1)), Color8(180, 140, 96))
			ci.draw_rect(Rect2(Vector2(size.x / 2 - 3, -3), Vector2(1, 3)), Color8(160, 160, 166))
			ci.draw_set_transform(Vector2.ZERO)
		6:
			# A dented oil drum, lying on its side.
			ci.draw_rect(Rect2(at - Vector2(7, 4), Vector2(14, 8)), Color8(60, 100, 150))
			ci.draw_rect(Rect2(at - Vector2(7, 4), Vector2(14, 2)), Color8(90, 130, 180))
			ci.draw_rect(Rect2(at - Vector2(3, 4), Vector2(1, 8)), Color8(40, 70, 110))
			ci.draw_rect(Rect2(at + Vector2(3, -4), Vector2(1, 8)), Color8(40, 70, 110))
			ci.draw_circle(at + Vector2(7, 0), 4.0, Color8(48, 82, 124))
			ci.draw_rect(Rect2(at + Vector2(-2, 1), Vector2(4, 2)), Color8(150, 82, 40))
		7:
			# An old TV: wooden case, a dead gray screen, a knob.
			ci.draw_rect(Rect2(at - Vector2(7, 6), Vector2(14, 11)), Color8(110, 74, 44))
			ci.draw_rect(Rect2(at - Vector2(6, 5), Vector2(9, 8)), Color8(70, 78, 76))
			ci.draw_rect(Rect2(at - Vector2(5, 4), Vector2(3, 2)), Color8(120, 130, 128))
			ci.draw_circle(at + Vector2(5, -2), 1.2, Color8(200, 190, 160))
			ci.draw_circle(at + Vector2(5, 2), 1.2, Color8(200, 190, 160))
		_:
			# A car door, window rolled down.
			var base: Color = [Color8(180, 60, 50), Color8(60, 120, 90), Color8(200, 190, 170)][rng.randi() % 3]
			ci.draw_rect(Rect2(at - Vector2(8, 6), Vector2(16, 12)), base)
			ci.draw_rect(Rect2(at - Vector2(7, 5), Vector2(14, 5)), Color8(60, 70, 80))
			ci.draw_rect(Rect2(at + Vector2(-8, 1), Vector2(16, 1)), base.darkened(0.3))
			ci.draw_rect(Rect2(at + Vector2(4, 2), Vector2(3, 1)), Color8(210, 210, 216))


## A stack of crushed cars, flattened to slabs, each a different color.
static func crushed_cars(ci: CanvasItem, r: Rect2, seed: int) -> void:
	var rng := _rng(seed)
	var colors := [Color8(170, 60, 50), Color8(60, 90, 160), Color8(200, 190, 80), Color8(90, 140, 90), Color8(200, 200, 206)]
	shadow(ci, Vector2(r.get_center().x + 4, r.end.y), Vector2(r.size.x * 0.6, 7), 0.3)
	var layers := 4
	for k in layers:
		var h := (r.size.y - 4) / layers
		var y := r.end.y - (k + 1) * h
		var shift := rng.randf_range(-4, 4)
		var c: Color = colors[(k + seed) % colors.size()]
		var slab := Rect2(r.position.x + shift, y, r.size.x, h - 1)
		ci.draw_rect(slab, c.darkened(0.25))
		ci.draw_rect(Rect2(slab.position, Vector2(slab.size.x, 2)), c)
		ci.draw_rect(Rect2(slab.position, Vector2(slab.size.x, 1)), c.lightened(0.2))
		# Crumpled window glass, a squashed wheel arch, rust.
		ci.draw_rect(Rect2(slab.position + Vector2(slab.size.x * 0.3, 2), Vector2(slab.size.x * 0.3, 2)), Color8(90, 110, 130))
		ci.draw_arc(Vector2(slab.position.x + 10, slab.end.y), 5.0, PI, TAU, 8, Color8(30, 30, 34), 2.0)
		ci.draw_arc(Vector2(slab.end.x - 10, slab.end.y), 5.0, PI, TAU, 8, Color8(30, 30, 34), 2.0)
		for i in 3:
			ci.draw_rect(Rect2(slab.position + Vector2(rng.randf_range(2, slab.size.x - 6), rng.randf_range(2, slab.size.y - 2)), Vector2(3, 1)), Color8(140, 74, 40))


## Sansworth's van, seen from the side: tan, boxy, a stripe, windows, hubcaps.
## `tarp` draws a blue tarp half pulled off it; `flat` lets the tires sag.
static func van(ci: CanvasItem, r: Rect2, tarp: bool, flat: bool) -> void:
	shadow(ci, Vector2(r.get_center().x, r.end.y + 2), Vector2(r.size.x * 0.55, 7), 0.3)
	var body := Color8(204, 184, 144)
	# The body, with a rounded nose at the front (the right).
	ci.draw_rect(Rect2(r.position + Vector2(0, 4), Vector2(r.size.x - 6, r.size.y - 12)), body)
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 8, 12), Vector2(8, r.size.y - 20)), body)
	ci.draw_rect(Rect2(r.position + Vector2(2, 4), Vector2(r.size.x - 10, 2)), body.lightened(0.15))
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 14), Vector2(r.size.x - 2, 3)), body.darkened(0.25))
	# A stripe down the side.
	ci.draw_rect(Rect2(r.position + Vector2(2, r.size.y * 0.55), Vector2(r.size.x - 6, 3)), Color8(170, 70, 50))
	ci.draw_rect(Rect2(r.position + Vector2(2, r.size.y * 0.55 + 3), Vector2(r.size.x - 6, 1)), Color8(220, 150, 60))
	# Windows: the cab up front, a long one at the back.
	var glass := Color8(110, 150, 180)
	ci.draw_rect(Rect2(r.position + Vector2(6, 9), Vector2(r.size.x * 0.5, 14)), glass)
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.62, 9), Vector2(r.size.x * 0.28, 14)), glass)
	ci.draw_line(r.position + Vector2(10, 21), r.position + Vector2(22, 10), Color(1, 1, 1, 0.3), 2.0)
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.58, 8), Vector2(2, r.size.y - 22)), body.darkened(0.3))
	# Headlight, bumper, door handle.
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 4, r.size.y * 0.5), Vector2(3, 4)), Color8(250, 244, 200))
	ci.draw_rect(Rect2(r.position + Vector2(-2, r.size.y - 13), Vector2(4, 3)), Color8(170, 170, 176))
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 4, r.size.y - 13), Vector2(5, 3)), Color8(170, 170, 176))
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.66, r.size.y * 0.5 - 2), Vector2(4, 1)), Color8(80, 80, 86))
	# Wheels.
	for wx in [r.position.x + 18, r.end.x - 20]:
		var c := Vector2(wx, r.end.y - 6)
		if flat:
			ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.8))
			ci.draw_circle(Vector2(0, 1), 8.0, Color8(28, 28, 32))
			ci.draw_set_transform(Vector2.ZERO)
		else:
			ci.draw_circle(c, 8.0, Color8(28, 28, 32))
		ci.draw_circle(c, 4.0, Color8(176, 178, 186))
		ci.draw_circle(c, 1.5, Color8(110, 112, 118))
	if tarp:
		# A blue tarp thrown over the back half, ropes holding it.
		var tp := PackedVector2Array([r.position + Vector2(r.size.x * 0.42, -2), Vector2(r.end.x + 4, r.position.y + 2),
			Vector2(r.end.x + 6, r.end.y - 12), Vector2(r.end.x - 20, r.end.y - 8), r.position + Vector2(r.size.x * 0.48, r.size.y * 0.7)])
		ci.draw_colored_polygon(tp, Color8(58, 92, 146))
		ci.draw_polyline(PackedVector2Array([tp[0], tp[1], tp[2]]), Color8(90, 126, 180), 1.0)
		for k in 3:
			var a := tp[0].lerp(tp[1], 0.25 + k * 0.25)
			ci.draw_line(a, a + Vector2(-2, 14 + k * 3), Color8(42, 70, 116), 1.0)
		ci.draw_line(tp[3], tp[3] + Vector2(-4, 10), Color8(200, 180, 120), 1.0)


## A little wooden shack: plank walls, a tin roof, a door, a window.
static func shack_roof(ci: CanvasItem, r: Rect2) -> void:
	# A corrugated tin roof along the top of the shack.
	ci.draw_rect(Rect2(r.position + Vector2(-4, -8), Vector2(r.size.x + 8, 10)), Color8(150, 156, 160))
	for k in int((r.size.x + 8) / 4):
		ci.draw_rect(Rect2(r.position + Vector2(-4 + k * 4, -8), Vector2(2, 10)), Color8(126, 132, 138))
	ci.draw_rect(Rect2(r.position + Vector2(-4, 1), Vector2(r.size.x + 8, 2)), Color8(96, 100, 106))
	for k in 4:
		ci.draw_rect(Rect2(r.position + Vector2(10 + k * 30, -6), Vector2(5, 3)), Color8(150, 90, 50))


# --- Around town ------------------------------------------------------------------------

## A bus stop: a pole with a blue sign (a little bus on it) and the schedule in
## its case. `at` is where the pole meets the ground.
static func bus_stop(ci: CanvasItem, at: Vector2) -> void:
	shadow(ci, at + Vector2(4, 1), Vector2(10, 3), 0.25)
	ci.draw_rect(Rect2(at + Vector2(-1, -46), Vector2(3, 46)), Color8(150, 150, 158))
	ci.draw_rect(Rect2(at + Vector2(-1, -46), Vector2(1, 46)), Color8(190, 190, 198))
	# The sign: blue, white border, a bus.
	var sign := Rect2(at + Vector2(-10, -58), Vector2(22, 14))
	ci.draw_rect(sign.grow(1), Color8(240, 240, 244))
	ci.draw_rect(sign, Color8(40, 92, 196))
	ci.draw_rect(Rect2(sign.position + Vector2(4, 3), Vector2(14, 7)), Color8(244, 244, 244))
	ci.draw_rect(Rect2(sign.position + Vector2(5, 4), Vector2(4, 3)), Color8(40, 92, 196))
	ci.draw_rect(Rect2(sign.position + Vector2(10, 4), Vector2(4, 3)), Color8(40, 92, 196))
	ci.draw_rect(Rect2(sign.position + Vector2(5, 10), Vector2(2, 2)), Color8(30, 30, 34))
	ci.draw_rect(Rect2(sign.position + Vector2(15, 10), Vector2(2, 2)), Color8(30, 30, 34))
	# The schedule, in its little case.
	ci.draw_rect(Rect2(at + Vector2(2, -30), Vector2(7, 10)), Color8(60, 64, 72))
	ci.draw_rect(Rect2(at + Vector2(3, -29), Vector2(5, 8)), Color8(236, 232, 210))
	for k in 3:
		ci.draw_rect(Rect2(at + Vector2(4, -28 + k * 2), Vector2(3, 1)), Color8(120, 120, 126))


# --- The Harbor -------------------------------------------------------------------------

## The carrier's hull, from the pier: steel plates and rivets, portholes (a few
## lit), rust weeping from them, the flight deck's overhang along the top with its
## edge lights, a red waterline, and the sea lapping at it.
static func carrier_hull(ci: CanvasItem, r: Rect2, lit: bool) -> void:
	var steel := Color8(112, 118, 130)
	ci.draw_rect(r, steel)
	# Plates: staggered rows, each a slightly different gray, with rivet lines.
	var rng := _rng(41)
	var row_h := 22.0
	var rows := int(r.size.y / row_h) + 1
	for row in rows:
		var y := r.position.y + 14 + row * row_h
		var offset := 0.0 if row % 2 == 0 else 30.0
		var x := r.position.x - offset
		while x < r.end.x:
			var left := maxf(x, r.position.x)
			var plate := Rect2(Vector2(left, y), Vector2(minf(x + 60.0, r.end.x) - left, minf(row_h, r.end.y - y)))
			var c := steel.lerp(steel.darkened(0.12), rng.randf())
			if plate.size.x > 0 and plate.size.y > 0:
				ci.draw_rect(plate, c)
				ci.draw_rect(Rect2(plate.position, Vector2(plate.size.x, 1)), c.lightened(0.12))
				ci.draw_rect(Rect2(plate.position, Vector2(1, plate.size.y)), c.darkened(0.25))
				var k := 3.0
				while k < plate.size.x:
					ci.draw_rect(Rect2(plate.position + Vector2(k, 3), Vector2(1, 1)), c.darkened(0.3))
					k += 6.0
			x += 60.0
	# The flight deck overhead: a dark overhang with its row of edge lights.
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 14)), Color8(70, 74, 84))
	ci.draw_rect(Rect2(r.position + Vector2(0, 14), Vector2(r.size.x, 3)), Color(0, 0, 0, 0.3))
	var lx := r.position.x + 8
	while lx < r.end.x:
		ci.draw_rect(Rect2(Vector2(lx, r.position.y + 5), Vector2(2, 2)), Color8(250, 214, 120) if lit else Color8(150, 150, 140))
		lx += 24
	# Portholes: rims, glass, rust weeping down below them.
	var px := r.position.x + 40
	var i := 0
	while px < r.end.x - 20:
		var c := Vector2(px, r.position.y + r.size.y * 0.45)
		ci.draw_rect(Rect2(c + Vector2(-1, 6), Vector2(2, 10 + (i % 3) * 6)), Color8(132, 90, 62, 140))
		ci.draw_circle(c, 6.0, Color8(150, 156, 166))
		ci.draw_circle(c, 4.5, Color8(36, 40, 50))
		if (i * 7) % 5 == 0 or (lit and i % 3 == 0):
			ci.draw_circle(c, 4.5, Color(1.0, 0.82, 0.48, 0.8))
		ci.draw_rect(Rect2(c + Vector2(-3, -3), Vector2(2, 2)), Color(1, 1, 1, 0.35))
		px += 60
		i += 1
	# The anchor's hawse hole, and a mooring line down to the pier.
	var hawse := Vector2(r.end.x - 60, r.position.y + 30)
	ci.draw_circle(hawse, 8.0, Color8(60, 64, 74))
	ci.draw_circle(hawse, 5.0, Color8(30, 32, 38))
	ci.draw_line(hawse + Vector2(0, 6), Vector2(hawse.x - 40, r.end.y + 50), Color8(200, 180, 130), 2.0)
	# The waterline: red anti-fouling paint, and the sea lapping at it.
	ci.draw_rect(Rect2(r.position.x, r.end.y - 8, r.size.x, 8), Color8(150, 46, 42))
	ci.draw_rect(Rect2(r.position.x, r.end.y - 8, r.size.x, 1), Color8(190, 70, 60))
	for k in int(r.size.x / 16):
		ci.draw_rect(Rect2(r.position.x + k * 16 + (k % 3) * 3, r.end.y - 2, 8, 2), Color(1, 1, 1, 0.4))


## A warbird in the hangar museum, seen from above: wings with stars, a tail,
## the fuselage and canopy, a propeller.
static func warplane(ci: CanvasItem, center: Vector2, span: float, body: Color) -> void:
	shadow(ci, center + Vector2(6, 10), Vector2(span * 0.55, span * 0.18), 0.28)
	var dark := body.darkened(0.25)
	var light := body.lightened(0.15)
	var wing := PackedVector2Array([center + Vector2(-span / 2, 2), center + Vector2(span / 2, 2), center + Vector2(span / 2 - 6, 10), center + Vector2(-span / 2 + 6, 10)])
	ci.draw_colored_polygon(wing, body)
	ci.draw_line(wing[0], wing[1], light, 1.0)
	ci.draw_line(wing[3], wing[2], dark, 1.0)
	for side in [-1.0, 1.0]:
		var star := center + Vector2(side * span * 0.32, 6)
		ci.draw_circle(star, 3.0, Color8(40, 60, 120))
		ci.draw_circle(star, 1.5, Color8(240, 240, 240))
	var tail := center + Vector2(0, span * 0.5)
	ci.draw_colored_polygon(PackedVector2Array([tail + Vector2(-span * 0.18, 0), tail + Vector2(span * 0.18, 0), tail + Vector2(span * 0.12, 5), tail + Vector2(-span * 0.12, 5)]), body)
	ci.draw_rect(Rect2(center + Vector2(-4, -span * 0.32), Vector2(8, span * 0.88)), body)
	ci.draw_rect(Rect2(center + Vector2(-4, -span * 0.32), Vector2(2, span * 0.88)), light)
	ci.draw_rect(Rect2(center + Vector2(3, -span * 0.32), Vector2(1, span * 0.88)), dark)
	ci.draw_rect(Rect2(center + Vector2(-3, -span * 0.12), Vector2(6, 8)), Color8(140, 196, 230))
	ci.draw_rect(Rect2(center + Vector2(-2, -span * 0.12 + 1), Vector2(2, 3)), Color(1, 1, 1, 0.6))
	var nose := center + Vector2(0, -span * 0.32 - 2)
	ci.draw_line(nose + Vector2(-9, 0), nose + Vector2(9, 0), Color8(60, 60, 64), 2.0)
	ci.draw_circle(nose, 2.0, Color8(200, 60, 50))


## Brass posts with a red velvet rope between them, around a museum exhibit.
static func velvet_ropes(ci: CanvasItem, r: Rect2) -> void:
	var posts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in 4:
		var a: Vector2 = posts[k]
		var b: Vector2 = posts[(k + 1) % 4]
		var mid := a.lerp(b, 0.5) + Vector2(0, 4)
		ci.draw_polyline(PackedVector2Array([a + Vector2(0, -6), mid + Vector2(0, -6), b + Vector2(0, -6)]), Color8(170, 30, 40), 2.0)
	for p in posts:
		ci.draw_rect(Rect2(p + Vector2(-1, -9), Vector2(3, 10)), Color8(200, 160, 60))
		ci.draw_circle(p + Vector2(0, -9), 2.0, Color8(236, 200, 96))


## A hazard-striped platform (an aircraft elevator).
static func hazard_platform(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, Color8(70, 74, 80))
	ci.draw_rect(r.grow(-6), Color8(84, 88, 96))
	var k := 0.0
	while k < r.size.x:
		var a := r.position + Vector2(k + 6, 0)
		ci.draw_line(a, a + Vector2(-6, 6), Color8(240, 200, 40), 3.0)
		ci.draw_line(Vector2(a.x, r.end.y - 6), Vector2(a.x - 6, r.end.y), Color8(240, 200, 40), 3.0)
		k += 10.0
	var y := r.position.y + 10
	while y < r.end.y - 8:
		ci.draw_line(Vector2(r.position.x + 8, y), Vector2(r.end.x - 8, y), Color8(76, 80, 88), 1.0)
		y += 6


## The island tower on the flight deck: stacked decks, bridge windows, a mast.
static func island_tower(ci: CanvasItem, r: Rect2, lit: bool) -> void:
	shadow(ci, Vector2(r.get_center().x + 10, r.end.y), Vector2(r.size.x * 0.7, 10), 0.35)
	var gray := Color8(112, 118, 130)
	ci.draw_rect(r, gray)
	for level in 3:
		var y := r.position.y + level * r.size.y / 3.0
		ci.draw_rect(Rect2(r.position.x, y, r.size.x, 3), gray.lightened(0.15))
		ci.draw_rect(Rect2(r.position.x, y + r.size.y / 3.0 - 2, r.size.x, 2), gray.darkened(0.25))
		var wx := r.position.x + 6
		while wx < r.end.x - 8:
			var on := lit and int(wx + level * 13) % 3 != 0
			ci.draw_rect(Rect2(wx, y + 8, 8, 6), Color(1.0, 0.84, 0.5) if on else Color8(40, 48, 62))
			ci.draw_rect(Rect2(wx, y + 8, 8, 1), Color(1, 1, 1, 0.3))
			wx += 14
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x / 2, -28), Vector2(3, 28)), Color8(150, 154, 164))
	ci.draw_line(r.position + Vector2(r.size.x / 2 - 12, -20), r.position + Vector2(r.size.x / 2 + 14, -20), Color8(150, 154, 164), 2.0)


## The seal statue on the promenade: a bronze seal on a stone plinth, nose up.
static func seal_statue(ci: CanvasItem, at: Vector2) -> void:
	shadow(ci, at + Vector2(2, 8), Vector2(14, 5), 0.3)
	ci.draw_rect(Rect2(at + Vector2(-12, -2), Vector2(24, 10)), Color8(170, 168, 160))
	ci.draw_rect(Rect2(at + Vector2(-12, -2), Vector2(24, 2)), Color8(200, 198, 190))
	ci.draw_rect(Rect2(at + Vector2(-5, 2), Vector2(10, 3)), Color8(150, 120, 60))
	var bronze := Color8(120, 92, 62)
	ci.draw_set_transform(at + Vector2(-2, -8), -0.3, Vector2(1.0, 0.6))
	ci.draw_circle(Vector2.ZERO, 9.0, bronze)
	ci.draw_set_transform(Vector2.ZERO)
	ci.draw_circle(at + Vector2(5, -16), 5.0, bronze)
	ci.draw_circle(at + Vector2(4, -18), 2.0, bronze.lightened(0.3))
	ci.draw_rect(Rect2(at + Vector2(8, -15), Vector2(1, 1)), Color8(20, 20, 20))
	ci.draw_line(at + Vector2(-10, -6), at + Vector2(-14, -2), bronze.darkened(0.2), 3.0)
	ci.draw_line(at + Vector2(1, -6), at + Vector2(-2, -1), bronze.darkened(0.2), 2.0)


## A fish stand: a striped awning, ice with fish on it.
static func fish_stand(ci: CanvasItem, r: Rect2) -> void:
	shadow(ci, Vector2(r.get_center().x + 4, r.end.y), Vector2(r.size.x * 0.55, 5), 0.3)
	ci.draw_rect(Rect2(r.position + Vector2(0, 12), Vector2(r.size.x, r.size.y - 12)), Color8(140, 104, 66))
	ci.draw_rect(Rect2(r.position + Vector2(0, 12), Vector2(r.size.x, 2)), Color8(170, 132, 90))
	ci.draw_rect(Rect2(r.position + Vector2(3, 15), Vector2(r.size.x - 6, 8)), Color8(220, 236, 244))
	var fish := [Color8(150, 160, 176), Color8(220, 120, 100), Color8(190, 190, 150)]
	for k in int((r.size.x - 10) / 9):
		var f := r.position + Vector2(6 + k * 9, 19)
		ci.draw_set_transform(f, 0.2 * (1 if k % 2 == 0 else -1), Vector2.ONE)
		ci.draw_rect(Rect2(Vector2(-3, -1), Vector2(6, 3)), fish[k % 3])
		ci.draw_rect(Rect2(Vector2(3, -2), Vector2(2, 5)), Color8(120, 130, 146))
		ci.draw_rect(Rect2(Vector2(-2, -1), Vector2(1, 1)), Color8(20, 20, 20))
		ci.draw_set_transform(Vector2.ZERO)
	for k in int(r.size.x / 6) + 1:
		var c := Color8(52, 110, 180) if k % 2 == 0 else Color8(240, 240, 244)
		ci.draw_rect(Rect2(r.position + Vector2(k * 6, 0), Vector2(6, 10)), c)
		ci.draw_circle(r.position + Vector2(k * 6 + 3, 10), 3.0, c)
	ci.draw_string(ThemeDB.fallback_font, r.position + Vector2(r.size.x / 2 - 13, 8), "FISH", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(30, 30, 40))


# --- Parks -------------------------------------------------------------------------------

## A playground: wood chips in a border, a play structure with a roof and a slide,
## monkey bars, and a swing set's frame. (The swings themselves move: swing_seats.)
static func playground(ci: CanvasItem, r: Rect2) -> void:
	var rng := _rng(11)
	# Wood chips, inside a timber border.
	ci.draw_rect(r, Color8(110, 80, 52))
	ci.draw_rect(r.grow(-3), Color8(150, 108, 70))
	for i in int(r.size.x * r.size.y / 40.0):
		var at := Vector2(rng.randf_range(r.position.x + 3, r.end.x - 5), rng.randf_range(r.position.y + 3, r.end.y - 5))
		ci.draw_rect(Rect2(at, Vector2(2, 1)), [Color8(176, 130, 84), Color8(124, 88, 56), Color8(190, 150, 100)][i % 3])
	# The play structure: four posts, a deck, a peaked green roof.
	var tower := Rect2(r.position + Vector2(16, 14), Vector2(44, 40))
	shadow(ci, tower.get_center() + Vector2(8, 22), Vector2(30, 8), 0.3)
	ci.draw_rect(tower, Color8(200, 170, 110))
	ci.draw_rect(tower.grow(-4), Color8(176, 146, 92))
	for k in 4:
		ci.draw_line(tower.position + Vector2(6 + k * 10, 4), tower.position + Vector2(6 + k * 10, tower.size.y - 4), Color8(150, 120, 74), 1.0)
	for corner in [tower.position, Vector2(tower.end.x - 4, tower.position.y), Vector2(tower.position.x, tower.end.y - 4), tower.end - Vector2(4, 4)]:
		ci.draw_rect(Rect2(corner, Vector2(4, 4)), Color8(40, 90, 170))
	var roof := PackedVector2Array([tower.position + Vector2(-4, 6), tower.position + Vector2(tower.size.x / 2, -12), Vector2(tower.end.x + 4, tower.position.y + 6), Vector2(tower.end.x + 4, tower.position.y + 12), tower.position + Vector2(-4, 12)])
	ci.draw_colored_polygon(roof, Color8(60, 140, 70))
	ci.draw_line(roof[0], roof[1], Color8(100, 180, 100), 2.0)
	ci.draw_line(roof[1], roof[2], Color8(40, 110, 54), 2.0)
	# The slide, curving down off the side.
	var top := Vector2(tower.end.x, tower.get_center().y)
	var slide := PackedVector2Array()
	for k in 9:
		var t := k / 8.0
		slide.append(top + Vector2(t * 46, t * t * 36 + sin(t * PI) * -6))
	ci.draw_polyline(slide, Color8(176, 40, 36), 9.0)
	ci.draw_polyline(slide, Color8(226, 70, 60), 5.0)
	ci.draw_polyline(slide, Color8(250, 130, 110), 1.0)
	# Monkey bars.
	var bars := Rect2(r.position + Vector2(18, r.size.y - 26), Vector2(60, 12))
	ci.draw_rect(Rect2(bars.position, Vector2(bars.size.x, 2)), Color8(220, 190, 40))
	ci.draw_rect(Rect2(bars.position + Vector2(0, bars.size.y), Vector2(bars.size.x, 2)), Color8(220, 190, 40))
	var bx := bars.position.x + 4
	while bx < bars.end.x:
		ci.draw_rect(Rect2(Vector2(bx, bars.position.y), Vector2(2, bars.size.y + 2)), Color8(180, 150, 30))
		bx += 7
	# The swing set's frame (A-frames at each end and a top bar).
	var frame := Rect2(r.end - Vector2(64, r.size.y - 12), Vector2(54, 4))
	ci.draw_rect(frame, Color8(60, 100, 160))
	ci.draw_rect(Rect2(frame.position, Vector2(frame.size.x, 1)), Color8(110, 150, 210))
	for x in [frame.position.x, frame.end.x - 4]:
		ci.draw_line(Vector2(x + 2, frame.position.y), Vector2(x - 6, frame.position.y + 50), Color8(50, 86, 140), 3.0)
		ci.draw_line(Vector2(x + 2, frame.position.y), Vector2(x + 10, frame.position.y + 50), Color8(50, 86, 140), 3.0)


## The swings, hanging from the top bar of `playground`'s swing set (they sway).
static func swing_seats(ci: CanvasItem, r: Rect2, time: float) -> void:
	var bar_y := r.position.y + 14
	var x0 := r.end.x - 64
	for k in 3:
		var top := Vector2(x0 + 10 + k * 16, bar_y)
		var sway := sin(time * 1.4 + k * 1.7) * 5.0
		var seat := top + Vector2(sway, 34)
		ci.draw_line(top + Vector2(-3, 0), seat + Vector2(-3, 0), Color8(150, 150, 160), 1.0)
		ci.draw_line(top + Vector2(3, 0), seat + Vector2(3, 0), Color8(150, 150, 160), 1.0)
		ci.draw_rect(Rect2(seat + Vector2(-5, 0), Vector2(10, 3)), Color8(30, 30, 34))
		ci.draw_rect(Rect2(seat + Vector2(-5, 0), Vector2(10, 1)), Color8(70, 70, 76))


## A routed wooden park sign on two posts, over a little stone planter.
static func park_sign(ci: CanvasItem, r: Rect2, text: String) -> void:
	shadow(ci, Vector2(r.get_center().x + 4, r.end.y + 6), Vector2(r.size.x * 0.55, 5), 0.3)
	# The stone base, with flowers.
	var base := Rect2(r.position + Vector2(-6, r.size.y - 2), Vector2(r.size.x + 12, 10))
	ci.draw_rect(base, Color8(150, 146, 138))
	var sx := base.position.x
	var i := 0
	while sx < base.end.x - 4:
		ci.draw_rect(Rect2(sx + 1, base.position.y + 1 + (i % 2) * 4, 8, 4), Color8(176, 172, 164))
		sx += 9
		i += 1
	for k in 6:
		ci.draw_rect(Rect2(base.position + Vector2(4 + k * (base.size.x - 8) / 6.0, -3), Vector2(3, 3)), [Color8(240, 120, 150), Color8(250, 220, 90), Color8(250, 250, 250)][k % 3])
	# Posts and the board.
	for x in [r.position.x + 6, r.end.x - 10]:
		ci.draw_rect(Rect2(x, r.position.y - 4, 4, r.size.y + 4), Color8(96, 66, 40))
		ci.draw_rect(Rect2(x, r.position.y - 4, 1, r.size.y + 4), Color8(130, 92, 58))
	ci.draw_rect(r, Color8(110, 76, 46))
	ci.draw_rect(r.grow(-2), Color8(132, 92, 56))
	for k in 3:
		ci.draw_rect(Rect2(r.position + Vector2(3, 5 + k * 6), Vector2(r.size.x - 6, 1)), Color8(118, 82, 50))
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	ci.draw_string(f, Vector2(r.get_center().x - w / 2, r.get_center().y + 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(70, 46, 26))
	ci.draw_string(f, Vector2(r.get_center().x - w / 2, r.get_center().y + 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(244, 232, 200))


## Torn-up ground: clods of earth turned over, roots, furrows.
static func torn_ground(ci: CanvasItem, r: Rect2) -> void:
	var rng := _rng(12)
	for k in 9:
		var a := Vector2(r.position.x + 8 + k * r.size.x / 9.0, r.position.y + 6)
		var b := a + Vector2(rng.randf_range(4, 14), r.size.y - 12)
		ci.draw_line(a, b, Color8(70, 46, 30), 3.0)
		ci.draw_line(a + Vector2(2, 0), b + Vector2(2, 0), Color8(140, 104, 70), 1.0)
	for k in 26:
		var at := Vector2(rng.randf_range(r.position.x + 4, r.end.x - 8), rng.randf_range(r.position.y + 4, r.end.y - 8))
		var s := rng.randf_range(3, 6)
		ci.draw_rect(Rect2(at, Vector2(s, s * 0.7)), Color8(96, 66, 42))
		ci.draw_rect(Rect2(at, Vector2(s, 1)), Color8(150, 112, 76))
	for k in 5:
		var at := Vector2(rng.randf_range(r.position.x + 10, r.end.x - 20), rng.randf_range(r.position.y + 10, r.end.y - 10))
		ci.draw_polyline(PackedVector2Array([at, at + Vector2(6, 3), at + Vector2(10, 1), at + Vector2(16, 5)]), Color8(170, 136, 96), 1.0)


# --- Balboa Park ------------------------------------------------------------------------

## The museum's bell tower: a cream tower with arched belfry openings, carved
## trim, and a blue-and-gold tiled dome with a lantern and a cross on top.
static func bell_tower(ci: CanvasItem, base: Vector2, width: float, height: float) -> void:
	var cream := Color8(228, 210, 168)
	var shade := Color8(196, 176, 134)
	var body := Rect2(base + Vector2(-width / 2, -height), Vector2(width, height))
	ci.draw_rect(body, cream)
	ci.draw_rect(Rect2(body.position, Vector2(width * 0.2, height)), Color8(238, 222, 184))
	ci.draw_rect(Rect2(body.end.x - width * 0.18, body.position.y, width * 0.18, height), shade)
	# Bands of carved trim.
	for t in [0.18, 0.55, 0.92]:
		var y: float = body.position.y + height * t
		ci.draw_rect(Rect2(body.position.x - 2, y, width + 4, 3), Color8(206, 186, 140))
		var x := body.position.x
		while x < body.end.x:
			ci.draw_rect(Rect2(x, y + 3, 2, 2), Color8(176, 150, 106))
			x += 5
	# Belfry: two arched openings with a bell in each.
	for k in 2:
		var arch := Rect2(body.position + Vector2(width * 0.18 + k * width * 0.38, height * 0.24), Vector2(width * 0.26, height * 0.26))
		ci.draw_rect(Rect2(arch.position + Vector2(0, arch.size.x / 2), arch.size - Vector2(0, arch.size.x / 2)), Color8(40, 36, 44))
		ci.draw_circle(arch.position + Vector2(arch.size.x / 2, arch.size.x / 2), arch.size.x / 2, Color8(40, 36, 44))
		ci.draw_circle(arch.get_center() + Vector2(0, 2), arch.size.x * 0.28, Color8(196, 150, 60))
		ci.draw_rect(Rect2(arch.position + Vector2(0, arch.size.y - 2), Vector2(arch.size.x, 2)), shade)
	# The dome: blue tiles in rows, gold trim, a lantern, a cross.
	var dome_c := Vector2(base.x, body.position.y)
	var r := width * 0.6
	for ring in 6:
		var rr := r - ring * r / 6.0
		var c := Color8(52, 104, 156) if ring % 2 == 0 else Color8(232, 190, 70)
		ci.draw_arc(dome_c, rr, PI, TAU, 24, c, r / 6.0 + 0.5)
	ci.draw_arc(dome_c, r, PI, TAU, 24, Color8(36, 74, 116), 1.0)
	ci.draw_rect(Rect2(dome_c + Vector2(-r - 2, -2), Vector2(r * 2 + 4, 4)), Color8(206, 186, 140))
	ci.draw_rect(Rect2(dome_c + Vector2(-4, -r - 10), Vector2(8, 10)), cream)
	ci.draw_rect(Rect2(dome_c + Vector2(-1, -r - 22), Vector2(2, 12)), Color8(232, 190, 70))
	ci.draw_rect(Rect2(dome_c + Vector2(-4, -r - 18), Vector2(8, 2)), Color8(232, 190, 70))


## A stone fountain: an outer basin of water with a carved rim, an inner bowl.
## (The spray is drawn by the area, so it can move.)
static func fountain(ci: CanvasItem, center: Vector2, radius: float) -> void:
	shadow(ci, center + Vector2(6, radius * 0.5), Vector2(radius * 1.1, radius * 0.35), 0.22)
	ci.draw_circle(center, radius + 6, Color8(196, 190, 176))
	ci.draw_circle(center, radius + 3, Color8(222, 216, 200))
	ci.draw_circle(center, radius, Color8(62, 128, 176))
	ci.draw_circle(center + Vector2(-radius * 0.2, -radius * 0.2), radius * 0.7, Color8(78, 148, 196))
	for k in 12:
		var a := k * TAU / 12.0
		ci.draw_rect(Rect2(center + Vector2.from_angle(a) * (radius + 4) - Vector2(1, 1), Vector2(2, 2)), Color8(176, 170, 156))
	# Coins on the bottom.
	var rng := _rng(5)
	for k in 9:
		var at := center + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(radius * 0.3, radius * 0.85)
		ci.draw_rect(Rect2(at, Vector2(2, 2)), Color8(220, 190, 90) if k % 3 else Color8(190, 140, 90))
	# The inner bowl on its pedestal.
	ci.draw_circle(center, radius * 0.38, Color8(222, 216, 200))
	ci.draw_circle(center, radius * 0.28, Color8(92, 160, 206))


## A lily pad (with a notch, and maybe a flower).
static func lily_pad(ci: CanvasItem, at: Vector2, seed: int) -> void:
	var rng := _rng(seed)
	var r := rng.randf_range(5.0, 8.0)
	var notch := rng.randf() * TAU
	ci.draw_circle(at + Vector2(1, 1), r, Color(0, 0, 0, 0.18))
	var pts := PackedVector2Array([at])
	for k in 17:
		var a := notch + 0.35 + k * (TAU - 0.7) / 16.0
		pts.append(at + Vector2.from_angle(a) * r)
	ci.draw_colored_polygon(pts, Color8(72, 140, 64))
	ci.draw_line(at, at + Vector2.from_angle(notch + PI) * r * 0.8, Color8(100, 168, 86), 1.0)
	if rng.randf() < 0.6:
		var fl := at + Vector2(rng.randf_range(-2, 2), rng.randf_range(-2, 2))
		for k in 5:
			ci.draw_circle(fl + Vector2.from_angle(k * TAU / 5.0) * 2.0, 1.8, Color8(246, 186, 210))
		ci.draw_circle(fl, 1.2, Color8(250, 220, 90))


## A suit of armor on a stand: helmet with a visor slit and a plume, pauldrons,
## breastplate, gauntlets, greaves, and a sword point-down in front.
static func suit_of_armor(ci: CanvasItem, feet: Vector2, plume: Color) -> void:
	shadow(ci, feet + Vector2(2, 1), Vector2(10, 3), 0.3)
	var steel := Color8(176, 180, 194)
	var dark := Color8(116, 120, 136)
	var light := Color8(220, 224, 236)
	ci.draw_rect(Rect2(feet + Vector2(-8, -2), Vector2(16, 3)), Color8(90, 64, 40))
	ci.draw_rect(Rect2(feet + Vector2(-5, -12), Vector2(4, 10)), steel)
	ci.draw_rect(Rect2(feet + Vector2(1, -12), Vector2(4, 10)), steel)
	ci.draw_rect(Rect2(feet + Vector2(-5, -12), Vector2(1, 10)), light)
	ci.draw_rect(Rect2(feet + Vector2(-6, -26), Vector2(12, 14)), steel)
	ci.draw_rect(Rect2(feet + Vector2(-6, -26), Vector2(3, 14)), light)
	ci.draw_rect(Rect2(feet + Vector2(4, -26), Vector2(2, 14)), dark)
	ci.draw_rect(Rect2(feet + Vector2(-6, -15), Vector2(12, 2)), dark)
	ci.draw_circle(feet + Vector2(-7, -24), 3.5, steel)
	ci.draw_circle(feet + Vector2(7, -24), 3.5, dark)
	ci.draw_rect(Rect2(feet + Vector2(-9, -20), Vector2(3, 8)), dark)
	ci.draw_rect(Rect2(feet + Vector2(6, -20), Vector2(3, 8)), dark)
	ci.draw_rect(Rect2(feet + Vector2(-4, -35), Vector2(8, 9)), steel)
	ci.draw_rect(Rect2(feet + Vector2(-4, -35), Vector2(2, 9)), light)
	ci.draw_rect(Rect2(feet + Vector2(-3, -31), Vector2(6, 1)), Color8(30, 30, 38))
	ci.draw_line(feet + Vector2(0, -35), feet + Vector2(-3, -41), plume, 3.0)
	ci.draw_line(feet + Vector2(-3, -41), feet + Vector2(-6, -38), plume.darkened(0.2), 2.0)
	ci.draw_rect(Rect2(feet + Vector2(-1, -14), Vector2(2, 14)), Color8(200, 204, 216))
	ci.draw_rect(Rect2(feet + Vector2(-3, -15), Vector2(6, 2)), Color8(150, 110, 50))


## A framed painting on the wall: a gilt frame and a little landscape or portrait.
static func painting(ci: CanvasItem, r: Rect2, seed: int) -> void:
	var rng := _rng(seed)
	ci.draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.25))
	ci.draw_rect(r, Color8(176, 138, 60))
	ci.draw_rect(r.grow(-1), Color8(214, 178, 90))
	ci.draw_rect(r.grow(-3), Color8(140, 104, 44))
	var canvas := r.grow(-4)
	match seed % 3:
		0:
			# A landscape: sky, hills, a little tree.
			ci.draw_rect(canvas, Color8(150, 186, 210))
			ci.draw_rect(Rect2(canvas.position + Vector2(0, canvas.size.y * 0.55), Vector2(canvas.size.x, canvas.size.y * 0.45)), Color8(96, 140, 76))
			ci.draw_circle(canvas.position + Vector2(canvas.size.x * 0.7, canvas.size.y * 0.55), canvas.size.y * 0.25, Color8(80, 120, 64))
			ci.draw_circle(canvas.position + Vector2(canvas.size.x * 0.25, canvas.size.y * 0.3), 2.5, Color8(250, 230, 150))
		1:
			# A portrait: a dark ground, a face, a collar.
			ci.draw_rect(canvas, Color8(52, 40, 36))
			var face := canvas.get_center() + Vector2(0, -2)
			ci.draw_rect(Rect2(face + Vector2(-6, 4), Vector2(12, canvas.size.y)), Color8(40, 50, 80))
			ci.draw_circle(face, 5.0, Color8(220, 186, 150))
			ci.draw_rect(Rect2(face + Vector2(-5, -6), Vector2(10, 3)), Color8(90, 60, 40))
		_:
			# A still life: a table, a vase, fruit.
			ci.draw_rect(canvas, Color8(120, 90, 70))
			ci.draw_rect(Rect2(canvas.position + Vector2(0, canvas.size.y * 0.65), Vector2(canvas.size.x, canvas.size.y * 0.35)), Color8(90, 60, 40))
			ci.draw_rect(Rect2(canvas.get_center() + Vector2(-3, -6), Vector2(6, 10)), Color8(60, 100, 150))
			ci.draw_circle(canvas.get_center() + Vector2(6, 4), 2.5, Color8(210, 80, 60))
			ci.draw_circle(canvas.get_center() + Vector2(-7, 4), 2.5, Color8(230, 190, 60))
	if rng.randf() < 0.5:
		ci.draw_rect(Rect2(Vector2(r.get_center().x - 4, r.end.y + 3), Vector2(8, 3)), Color8(220, 214, 196))


## A tall archive shelf: wooden uprights, three shelves of old books and boxes.
static func archive_shelf(ci: CanvasItem, r: Rect2, seed: int) -> void:
	var rng := _rng(seed)
	ci.draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(0, 0, 0, 0.25))
	ci.draw_rect(r, Color8(96, 66, 40))
	ci.draw_rect(r.grow(-2), Color8(64, 44, 28))
	var shelves := 3
	for s in shelves:
		var y := r.position.y + 2 + s * (r.size.y - 4) / shelves
		var h: float = (r.size.y - 4) / shelves
		var x := r.position.x + 3
		while x < r.end.x - 5:
			var w := rng.randf_range(3, 6)
			var bh := rng.randf_range(h * 0.55, h - 2)
			var c := Color8(rng.randi_range(90, 200), rng.randi_range(50, 130), rng.randi_range(40, 110))
			if rng.randf() < 0.12:
				# A document box instead of a book.
				ci.draw_rect(Rect2(x, y + h - 8, 9, 7), Color8(196, 180, 140))
				ci.draw_rect(Rect2(x + 3, y + h - 6, 3, 1), Color8(120, 100, 70))
				x += 10
				continue
			ci.draw_rect(Rect2(x, y + h - bh - 1, w, bh), c)
			ci.draw_rect(Rect2(x, y + h - bh - 1, 1, bh), c.lightened(0.2))
			ci.draw_rect(Rect2(x, y + h - bh * 0.7, w, 1), Color8(220, 190, 110))
			x += w + (1 if rng.randf() < 0.3 else 0)
		ci.draw_rect(Rect2(r.position.x + 1, y + h - 1, r.size.x - 2, 2), Color8(120, 84, 52))


## An empty display pedestal: marble, with a plaque. (Something was here.)
static func pedestal(ci: CanvasItem, r: Rect2, label: String) -> void:
	shadow(ci, Vector2(r.get_center().x + 4, r.end.y), Vector2(r.size.x * 0.55, 5), 0.3)
	ci.draw_rect(r, Color8(200, 196, 188))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), Color8(230, 226, 218))
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 3), Vector2(r.size.x, 3)), Color8(150, 146, 140))
	var rng := _rng(3)
	for k in 6:
		var a := r.position + Vector2(rng.randf_range(2, r.size.x - 10), rng.randf_range(4, r.size.y - 6))
		ci.draw_line(a, a + Vector2(rng.randf_range(4, 9), rng.randf_range(-2, 2)), Color8(176, 172, 166), 1.0)
	# A clean square where something stood, the dust all around it.
	ci.draw_rect(Rect2(r.get_center() + Vector2(-10, -7), Vector2(20, 6)), Color8(214, 210, 202))
	var plate := Rect2(r.get_center() + Vector2(-26, 2), Vector2(52, 9))
	ci.draw_rect(plate, Color8(176, 140, 60))
	ci.draw_rect(plate.grow(-1), Color8(214, 180, 96))
	ci.draw_string(ThemeDB.fallback_font, plate.position + Vector2(3, 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color8(60, 40, 20))


# --- Downtown ---------------------------------------------------------------------------

## A 1950s all-night diner front: rounded steel corners, a chrome band, big
## lit windows with booths and a counter inside, a striped awning, a door.
static func diner_front(ci: CanvasItem, r: Rect2, door_x: float) -> void:
	var steel := Color8(176, 182, 192)
	ci.draw_rect(r, Color8(48, 50, 62))
	# The body, with rounded ends.
	ci.draw_rect(Rect2(r.position + Vector2(6, 0), Vector2(r.size.x - 12, r.size.y)), Color8(196, 200, 210))
	ci.draw_circle(r.position + Vector2(10, r.size.y - 10), 10.0, Color8(196, 200, 210))
	ci.draw_circle(Vector2(r.end.x - 10, r.end.y - 10), 10.0, Color8(196, 200, 210))
	# Ribbed stainless lower panel, and a red stripe.
	var lower := Rect2(r.position.x + 4, r.end.y - 22, r.size.x - 8, 22)
	ci.draw_rect(lower, steel)
	var x := lower.position.x
	while x < lower.end.x:
		ci.draw_rect(Rect2(x, lower.position.y, 1, lower.size.y), Color8(140, 146, 158))
		ci.draw_rect(Rect2(x + 1, lower.position.y, 1, lower.size.y), Color8(214, 220, 228))
		x += 4
	ci.draw_rect(Rect2(r.position.x + 4, r.end.y - 26, r.size.x - 8, 4), Color8(200, 40, 52))
	# Windows: warm light, booths' red backs, a counter and stools, a waitress.
	var wy := r.position.y + r.size.y * 0.42
	var wx := r.position.x + 12
	var i := 0
	while wx < r.end.x - 30:
		if absf(wx + 14 - door_x) > 22:
			var win := Rect2(wx, wy, 28, 20)
			ci.draw_rect(win.grow(1), steel)
			ci.draw_rect(win, Color(1.0, 0.86, 0.58))
			ci.draw_rect(Rect2(win.position + Vector2(0, 12), Vector2(win.size.x, 8)), Color8(196, 60, 60))
			ci.draw_rect(Rect2(win.position + Vector2(0, 12), Vector2(win.size.x, 1)), Color8(230, 110, 100))
			ci.draw_rect(Rect2(win.position + Vector2(8, 9), Vector2(12, 2)), Color8(230, 230, 236))
			if i % 3 == 1:
				ci.draw_circle(win.position + Vector2(18, 6), 3.0, Color8(80, 56, 44))
				ci.draw_rect(Rect2(win.position + Vector2(15, 9), Vector2(6, 4)), Color8(230, 140, 170))
			ci.draw_line(win.position + Vector2(2, 2), win.position + Vector2(10, 2), Color(1, 1, 1, 0.5), 1.0)
		wx += 34
		i += 1
	# The striped awning along the top.
	for k in int(r.size.x / 8):
		var c := Color8(200, 40, 52) if k % 2 == 0 else Color8(240, 236, 226)
		ci.draw_rect(Rect2(r.position.x + k * 8, r.position.y + 24, 8, 8), c)
		ci.draw_rect(Rect2(r.position.x + k * 8, r.position.y + 32, 8, 2), c.darkened(0.2))
	# The door: chrome-framed glass.
	var door := Rect2(door_x - 10, r.end.y - 30, 20, 30)
	ci.draw_rect(door, steel)
	ci.draw_rect(door.grow(-2), Color(1.0, 0.86, 0.58, 0.9))
	ci.draw_rect(Rect2(door.position + Vector2(14, 14), Vector2(2, 4)), Color8(80, 80, 86))


## The ballpark's front: red brick in courses, cream trim, a big arched gate with
## an iron grille, ticket windows, pennants on the roofline.
static func ballpark_front(ci: CanvasItem, r: Rect2, gate: Rect2) -> void:
	var rng := _rng(17)
	ci.draw_rect(r, Color8(110, 44, 36))
	var row := 0
	var y := r.position.y
	while y < r.end.y:
		var x := r.position.x - (10 if row % 2 == 0 else 0)
		while x < r.end.x:
			var c := Color8(160, 66, 50).lerp(Color8(136, 52, 40), rng.randf())
			var left := maxf(x, r.position.x)
			var w := minf(x + 19, r.end.x) - left
			if w > 0:
				ci.draw_rect(Rect2(left, y, w, 9), c)
				ci.draw_rect(Rect2(left, y, w, 1), c.lightened(0.1))
			x += 20
		y += 10
		row += 1
	# Cream cornice along the top, pennants above it.
	ci.draw_rect(Rect2(r.position + Vector2(0, 0), Vector2(r.size.x, 6)), Color8(232, 220, 196))
	ci.draw_rect(Rect2(r.position + Vector2(0, 6), Vector2(r.size.x, 2)), Color8(150, 130, 110))
	var px := r.position.x + 12
	var k := 0
	while px < r.end.x - 6:
		ci.draw_line(Vector2(px, r.position.y), Vector2(px, r.position.y - 14), Color8(200, 200, 206), 1.0)
		var flag := PackedVector2Array([Vector2(px, r.position.y - 14), Vector2(px + 10, r.position.y - 11), Vector2(px, r.position.y - 8)])
		ci.draw_colored_polygon(flag, [Color8(220, 50, 50), Color8(240, 240, 240), Color8(40, 80, 170)][k % 3])
		px += 34
		k += 1
	# Ticket windows on either side of the gate.
	for side in [-1.0, 1.0]:
		var tw := Rect2(gate.get_center().x + side * (gate.size.x / 2 + 30) - 10, gate.position.y + 10, 20, 16)
		ci.draw_rect(tw.grow(2), Color8(232, 220, 196))
		ci.draw_rect(tw, Color8(40, 40, 50))
		ci.draw_rect(Rect2(tw.position + Vector2(2, 2), Vector2(16, 6)), Color(1.0, 0.86, 0.55, 0.8))
		ci.draw_string(ThemeDB.fallback_font, tw.position + Vector2(-2, -4), "TICKETS", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color8(240, 230, 210))
	# The arched gate: cream stone, dark inside, an iron grille.
	var arch_c := Vector2(gate.get_center().x, gate.position.y + gate.size.x / 2)
	ci.draw_circle(arch_c, gate.size.x / 2 + 6, Color8(232, 220, 196))
	ci.draw_rect(Rect2(gate.position + Vector2(-6, gate.size.x / 2), Vector2(gate.size.x + 12, gate.size.y - gate.size.x / 2)), Color8(232, 220, 196))
	ci.draw_circle(arch_c, gate.size.x / 2, Color8(30, 30, 38))
	ci.draw_rect(Rect2(gate.position + Vector2(0, gate.size.x / 2), Vector2(gate.size.x, gate.size.y - gate.size.x / 2)), Color8(30, 30, 38))
	var gx := gate.position.x + 3
	while gx < gate.end.x:
		ci.draw_line(Vector2(gx, gate.position.y + 8), Vector2(gx, gate.end.y), Color8(70, 70, 80), 1.0)
		gx += 5
	ci.draw_line(Vector2(gate.position.x, gate.end.y - 14), Vector2(gate.end.x, gate.end.y - 14), Color8(70, 70, 80), 1.0)
	ci.draw_rect(Rect2(arch_c + Vector2(-4, -gate.size.x / 2 - 6), Vector2(8, 6)), Color8(206, 190, 160))


## An old-fashioned street lamp: a fluted post on a heavy base, a crossbar, and a
## glass lantern (lit or not). `glow` is 0..1.
static func gaslamp(ci: CanvasItem, at: Vector2, glow: float) -> void:
	shadow(ci, at + Vector2(3, 1), Vector2(6, 2), 0.3)
	var iron := Color8(36, 38, 46)
	ci.draw_rect(Rect2(at + Vector2(-4, -6), Vector2(8, 6)), iron)
	ci.draw_rect(Rect2(at + Vector2(-3, -8), Vector2(6, 2)), iron.lightened(0.15))
	ci.draw_rect(Rect2(at + Vector2(-1.5, -32), Vector2(3, 26)), iron)
	ci.draw_rect(Rect2(at + Vector2(-1.5, -32), Vector2(1, 26)), iron.lightened(0.25))
	ci.draw_rect(Rect2(at + Vector2(-5, -33), Vector2(10, 2)), iron)
	# The lantern: a cap, four panes, a finial.
	var lantern := Rect2(at + Vector2(-4, -44), Vector2(8, 10))
	if glow > 0.0:
		ci.draw_circle(lantern.get_center(), 14.0, Color(1.0, 0.8, 0.45, 0.12 * glow))
	ci.draw_rect(lantern, iron)
	ci.draw_rect(lantern.grow(-1), Color(1.0, 0.86, 0.5, 0.35 + 0.6 * glow))
	ci.draw_rect(Rect2(lantern.position + Vector2(3, 1), Vector2(1, 8)), iron)
	ci.draw_colored_polygon(PackedVector2Array([lantern.position + Vector2(-2, 0), lantern.position + Vector2(4, -5), lantern.position + Vector2(10, 0)]), iron)
	ci.draw_rect(Rect2(lantern.position + Vector2(3, -8), Vector2(2, 3)), iron)


## The trolley: red, a cream band, a row of lit windows with riders in them, the
## pole up to the wire, wheels on the rails, a destination sign.
static func trolley(ci: CanvasItem, r: Rect2, destination: String) -> void:
	shadow(ci, Vector2(r.get_center().x, r.end.y + 2), Vector2(r.size.x * 0.52, 5), 0.35)
	var red := Color8(200, 40, 45)
	ci.draw_rect(Rect2(r.position + Vector2(2, 0), Vector2(r.size.x - 4, r.size.y)), red)
	ci.draw_rect(Rect2(r.position + Vector2(0, 2), Vector2(r.size.x, r.size.y - 4)), red)
	ci.draw_rect(Rect2(r.position + Vector2(2, 0), Vector2(r.size.x - 4, 3)), red.lightened(0.2))
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.62), Vector2(r.size.x, 4)), Color8(236, 220, 180))
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 3), Vector2(r.size.x, 3)), red.darkened(0.35))
	# Windows, with riders.
	var wx := r.position.x + 6
	var i := 0
	while wx < r.end.x - 12:
		var win := Rect2(wx, r.position.y + 5, 10, 9)
		ci.draw_rect(win, Color(1.0, 0.9, 0.6, 0.9))
		if i % 2 == 0:
			ci.draw_circle(win.position + Vector2(5, 5), 2.5, Color8(60, 50, 50))
			ci.draw_rect(Rect2(win.position + Vector2(2, 7), Vector2(6, 2)), Color8(60, 70, 110))
		ci.draw_rect(Rect2(win.position, Vector2(10, 1)), Color(1, 1, 1, 0.5))
		wx += 13
		i += 1
	# Destination sign, headlight, wheels.
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x / 2 - 18, -7), Vector2(36, 7)), Color8(30, 30, 36))
	ci.draw_string(ThemeDB.fallback_font, r.position + Vector2(r.size.x / 2 - 16, -1), destination, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color8(250, 200, 80))
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 3, r.size.y * 0.4), Vector2(3, 4)), Color8(255, 246, 200))
	for wheel_x in [r.position.x + 14, r.position.x + 26, r.end.x - 26, r.end.x - 14]:
		ci.draw_circle(Vector2(wheel_x, r.end.y), 3.0, Color8(30, 30, 34))


## A ball field, from above: dirt base paths, mowed infield grass, the mound with
## its rubber, batter's boxes, on-deck circles, the bases and the foul lines.
static func ball_field(ci: CanvasItem, home: Vector2, mound: Vector2) -> void:
	var dirt := Color8(178, 128, 82)
	var dirt_dark := Color8(156, 108, 68)
	var diamond := PackedVector2Array([home + Vector2(0, 14), home + Vector2(136, -110), home + Vector2(0, -236), home + Vector2(-136, -110)])
	ci.draw_colored_polygon(diamond, dirt)
	var rng := _rng(9)
	for k in 260:
		var at := home + Vector2(rng.randf_range(-130, 130), rng.randf_range(-230, 10))
		ci.draw_rect(Rect2(at, Vector2(1, 1)), dirt_dark if k % 2 == 0 else dirt.lightened(0.08))
	# The infield grass, mowed in a checker.
	var grass := PackedVector2Array([home + Vector2(0, -26), home + Vector2(98, -110), home + Vector2(0, -196), home + Vector2(-98, -110)])
	ci.draw_colored_polygon(grass, Color8(72, 142, 70))
	for k in 6:
		var a := home + Vector2(0, -26).lerp(Vector2(98, -110), k / 6.0)
		var b := home + Vector2(-98, -110).lerp(Vector2(0, -196), k / 6.0)
		if k % 2 == 0:
			var c := home + Vector2(0, -26).lerp(Vector2(98, -110), (k + 1) / 6.0)
			var d := home + Vector2(-98, -110).lerp(Vector2(0, -196), (k + 1) / 6.0)
			ci.draw_colored_polygon(PackedVector2Array([a, c, d, b]), Color8(80, 152, 76))
	# The mound and its rubber.
	ci.draw_circle(mound + Vector2(0, 6), 18.0, dirt_dark)
	ci.draw_circle(mound + Vector2(0, 6), 16.0, dirt)
	ci.draw_rect(Rect2(mound + Vector2(-6, 4), Vector2(12, 3)), Color.WHITE)
	# Bases.
	for base in [home + Vector2(120, -110), home + Vector2(0, -222), home + Vector2(-120, -110)]:
		ci.draw_rect(Rect2(base - Vector2(6, 6) + Vector2(1, 1), Vector2(12, 12)), Color(0, 0, 0, 0.25))
		ci.draw_rect(Rect2(base - Vector2(6, 6), Vector2(12, 12)), Color.WHITE)
		ci.draw_rect(Rect2(base - Vector2(6, 6), Vector2(12, 2)), Color8(220, 220, 220))
	# Home plate and the batter's boxes, chalked.
	ci.draw_circle(home, 20.0, dirt_dark)
	ci.draw_colored_polygon(PackedVector2Array([home + Vector2(-7, -6), home + Vector2(7, -6), home + Vector2(7, 0), home + Vector2(0, 6), home + Vector2(-7, 0)]), Color.WHITE)
	for side in [-1.0, 1.0]:
		ci.draw_rect(Rect2(home + Vector2(side * 14 - 6, -12), Vector2(12, 22)), Color(1, 1, 1, 0.7), false, 1.0)
		# On-deck circles, out by the dugouts.
		ci.draw_arc(home + Vector2(side * 120, 10), 9.0, 0, TAU, 16, Color(1, 1, 1, 0.6), 1.0)
	# Foul lines.
	ci.draw_line(home, home + Vector2(400, -344), Color(1, 1, 1, 0.85), 2.0)
	ci.draw_line(home, home + Vector2(-400, -344), Color(1, 1, 1, 0.85), 2.0)


## The frame of a big video screen: dark steel, rows of lamps along the top,
## and two legs.
static func big_screen_frame(ci: CanvasItem, screen: Rect2) -> void:
	for x in [screen.position.x + 40, screen.end.x - 48]:
		ci.draw_rect(Rect2(Vector2(x, screen.end.y), Vector2(8, 14)), Color8(70, 72, 82))
		ci.draw_rect(Rect2(Vector2(x, screen.end.y), Vector2(2, 14)), Color8(110, 112, 122))
	ci.draw_rect(screen.grow(6), Color8(26, 26, 32))
	ci.draw_rect(screen.grow(4), Color8(46, 48, 58))
	ci.draw_rect(screen, Color8(12, 12, 18))
	var x := screen.position.x
	while x < screen.end.x:
		ci.draw_rect(Rect2(x, screen.position.y - 12, 6, 4), Color8(220, 220, 200))
		x += 14
	# A faint pixel grid on the dark screen.
	var gx := screen.position.x + 2
	while gx < screen.end.x:
		ci.draw_rect(Rect2(gx, screen.position.y, 1, screen.size.y), Color(1, 1, 1, 0.03))
		gx += 4


# --- Mission Beach ----------------------------------------------------------------------

## A wooden roller coaster's trestle (white-painted lumber: rows of upright bents,
## crossed bracing, a back row in shadow) with the red track riding over it on
## a curve, ties and two rails, and a little train of cars parked at the top.
static func wooden_coaster(ci: CanvasItem, r: Rect2, track: Callable) -> void:
	ci.draw_rect(r, Color8(54, 48, 46))
	var white := Color8(236, 230, 218)
	var back := Color8(150, 144, 136)
	# Back row of bents, in shadow.
	var x := r.position.x + 12
	while x < r.end.x:
		var top: float = track.call(x) + 8
		ci.draw_line(Vector2(x, top), Vector2(x, r.end.y), back, 2.0)
		x += 26
	# Front row: uprights, X bracing, horizontal ledgers.
	x = r.position.x + 4
	while x < r.end.x - 4:
		var top_a: float = track.call(x) + 4
		var top_b: float = track.call(x + 26) + 4
		ci.draw_line(Vector2(x, top_a), Vector2(x, r.end.y), white, 2.0)
		ci.draw_line(Vector2(x, top_a + 4), Vector2(x + 26, r.end.y - 6), white.darkened(0.08), 1.0)
		ci.draw_line(Vector2(x + 26, top_b + 4), Vector2(x, r.end.y - 6), white.darkened(0.08), 1.0)
		var ly := maxf(top_a, top_b) + 14
		while ly < r.end.y - 4:
			ci.draw_line(Vector2(x, ly), Vector2(x + 26, ly), white.darkened(0.04), 1.0)
			ly += 18
		x += 26
	# The track: ties under two red rails.
	var pts := PackedVector2Array()
	var rails := PackedVector2Array()
	var tx := r.position.x
	while tx <= r.end.x:
		var y: float = track.call(tx)
		pts.append(Vector2(tx, y))
		rails.append(Vector2(tx, y + 4))
		ci.draw_rect(Rect2(tx - 1, y - 2, 3, 8), Color8(110, 80, 56))
		tx += 5
	ci.draw_polyline(rails, Color8(150, 34, 32), 2.0)
	ci.draw_polyline(pts, Color8(206, 52, 46), 3.0)
	ci.draw_polyline(pts, Color8(240, 120, 100), 1.0)
	# The train, parked at the top of the lift hill: three cars, lap bars up.
	var best_x := r.position.x
	var best_y := INF
	var sx := r.position.x + 20
	while sx < r.end.x - 60:
		var y: float = track.call(sx)
		if y < best_y:
			best_y = y
			best_x = sx
		sx += 5
	for k in 3:
		var cx := best_x - 20 + k * 16
		var cy: float = track.call(cx) - 9
		ci.draw_rect(Rect2(cx - 7, cy, 14, 8), Color8(40, 90, 170) if k != 0 else Color8(220, 60, 50))
		ci.draw_rect(Rect2(cx - 7, cy, 14, 2), Color8(250, 210, 80))
		ci.draw_rect(Rect2(cx - 5, cy + 3, 10, 2), Color8(30, 30, 40))
		ci.draw_circle(Vector2(cx - 4, cy + 9), 1.5, Color8(30, 30, 34))
		ci.draw_circle(Vector2(cx + 4, cy + 9), 1.5, Color8(30, 30, 34))


## A shop's painted sign board over its windows, with a little picture.
static func shop_sign(ci: CanvasItem, r: Rect2, text: String, board: Color, ink: Color, icon: String) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.25))
	ci.draw_rect(r, board.darkened(0.3))
	ci.draw_rect(r.grow(-1), board)
	ci.draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 2, 1)), board.lightened(0.25))
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var tx := r.get_center().x - w / 2 + 6
	ci.draw_string(f, Vector2(tx, r.get_center().y + 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ink)
	var ic := Vector2(tx - 10, r.get_center().y)
	match icon:
		"surf":
			ci.draw_set_transform(ic, 0.5, Vector2.ONE)
			ci.draw_rect(Rect2(-2, -6, 4, 12), Color8(250, 250, 250))
			ci.draw_rect(Rect2(-1, -6, 1, 12), Color8(240, 100, 80))
			ci.draw_set_transform(Vector2.ZERO)
		"taco":
			ci.draw_arc(ic + Vector2(0, 2), 5.0, PI, TAU, 10, Color8(240, 200, 90), 3.0)
			ci.draw_rect(Rect2(ic + Vector2(-3, -1), Vector2(6, 2)), Color8(90, 170, 70))
		"arcade":
			ci.draw_rect(Rect2(ic + Vector2(-4, -5), Vector2(8, 10)), Color8(40, 40, 60))
			ci.draw_rect(Rect2(ic + Vector2(-3, -4), Vector2(6, 4)), Color8(80, 220, 240))
			ci.draw_circle(ic + Vector2(0, 3), 1.2, Color8(240, 60, 60))
		"cone":
			ci.draw_colored_polygon(PackedVector2Array([ic + Vector2(-3, 0), ic + Vector2(3, 0), ic + Vector2(0, 7)]), Color8(220, 170, 100))
			ci.draw_circle(ic + Vector2(0, -2), 3.5, Color8(250, 170, 200))


## A striped awning over a shop front, scalloped along the bottom.
static func awning(ci: CanvasItem, r: Rect2, a: Color, b: Color) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y), Vector2(r.size.x, 4)), Color(0, 0, 0, 0.22))
	var k := 0
	var x := r.position.x
	while x < r.end.x:
		var w := minf(8.0, r.end.x - x)
		var c := a if k % 2 == 0 else b
		ci.draw_rect(Rect2(x, r.position.y, w, r.size.y), c)
		ci.draw_rect(Rect2(x, r.position.y, w, 1), c.lightened(0.2))
		ci.draw_circle(Vector2(x + w / 2, r.end.y), w / 2, c)
		x += 8
		k += 1


## A turnstile gate: a steel post with three arms, and a little ticket box.
static func turnstile(ci: CanvasItem, at: Vector2) -> void:
	shadow(ci, at + Vector2(2, 2), Vector2(14, 4), 0.3)
	ci.draw_rect(Rect2(at + Vector2(-16, -14), Vector2(32, 14)), Color8(128, 92, 60))
	ci.draw_rect(Rect2(at + Vector2(-16, -14), Vector2(32, 2)), Color8(160, 120, 80))
	ci.draw_rect(Rect2(at + Vector2(-3, -24), Vector2(6, 14)), Color8(170, 174, 182))
	ci.draw_rect(Rect2(at + Vector2(-3, -24), Vector2(2, 14)), Color8(210, 214, 222))
	for k in 3:
		var a := -PI / 2 + k * TAU / 3.0 + 0.4
		ci.draw_line(at + Vector2(0, -18), at + Vector2(0, -18) + Vector2.from_angle(a) * 10.0, Color8(196, 200, 208), 2.0)
	ci.draw_rect(Rect2(at + Vector2(8, -22), Vector2(6, 8)), Color8(200, 50, 45))
	ci.draw_rect(Rect2(at + Vector2(9, -21), Vector2(4, 2)), Color8(250, 230, 160))


## A beach umbrella from above: eight panels in two colors, a scalloped edge,
## its pole's shadow on the sand.
static func beach_umbrella(ci: CanvasItem, at: Vector2, a: Color, b: Color) -> void:
	shadow(ci, at + Vector2(10, 14), Vector2(16, 6), 0.22)
	for k in 8:
		var a0 := k * TAU / 8.0
		var pts := PackedVector2Array([at, at + Vector2.from_angle(a0) * 16.0, at + Vector2.from_angle(a0 + TAU / 16.0) * 17.0, at + Vector2.from_angle(a0 + TAU / 8.0) * 16.0])
		ci.draw_colored_polygon(pts, a if k % 2 == 0 else b)
	for k in 8:
		var a0 := k * TAU / 8.0
		ci.draw_line(at, at + Vector2.from_angle(a0) * 16.0, Color(0, 0, 0, 0.15), 1.0)
	ci.draw_circle(at, 2.0, Color8(240, 240, 240))
	ci.draw_circle(at + Vector2(-5, -5), 5.0, Color(1, 1, 1, 0.12))


## An inflatable duck pool float (Crayola's).
static func duck_float(ci: CanvasItem, at: Vector2) -> void:
	shadow(ci, at + Vector2(2, 6), Vector2(12, 4), 0.2)
	ci.draw_circle(at, 9.0, Color8(250, 210, 60))
	ci.draw_circle(at, 4.5, Color8(236, 214, 162))
	ci.draw_arc(at, 9.0, PI * 1.1, PI * 1.6, 8, Color8(255, 240, 150), 2.0)
	ci.draw_circle(at + Vector2(-6, -8), 4.5, Color8(250, 210, 60))
	ci.draw_rect(Rect2(at + Vector2(-13, -9), Vector2(4, 2)), Color8(240, 140, 40))
	ci.draw_rect(Rect2(at + Vector2(-7, -10), Vector2(1, 1)), Color8(20, 20, 20))


# --- Old Town ---------------------------------------------------------------------------

## A string of papel picado: cut-paper flags hanging from a sagging cord, each
## with a scalloped hem and a pattern cut out of it.
static func papel_picado(ci: CanvasItem, from: Vector2, to: Vector2, colors: Array, seed: int) -> void:
	var count := int(from.distance_to(to) / 20.0)
	var sag := 10.0
	var cord := PackedVector2Array()
	for k in count + 1:
		var t := k / float(count)
		cord.append(from.lerp(to, t) + Vector2(0, sin(t * PI) * sag))
	ci.draw_polyline(cord, Color8(90, 80, 70), 1.0)
	for k in count:
		var t := (k + 0.5) / float(count)
		var top := from.lerp(to, t) + Vector2(0, sin(t * PI) * sag)
		var c: Color = colors[(k + seed) % colors.size()]
		var flag := Rect2(top + Vector2(-6, 0), Vector2(12, 11))
		ci.draw_rect(flag, Color(c, 0.92))
		ci.draw_rect(Rect2(flag.position, Vector2(12, 1)), c.lightened(0.25))
		# The cut-outs: a little flower, and diamonds around it.
		var cc := flag.get_center() + Vector2(0, -1)
		ci.draw_rect(Rect2(cc - Vector2(1, 1), Vector2(2, 2)), Color(0, 0, 0, 0.35))
		for d in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
			ci.draw_rect(Rect2(cc + d - Vector2(0.5, 0.5), Vector2(1, 1)), Color(0, 0, 0, 0.3))
		# Scalloped hem.
		for s in 3:
			ci.draw_circle(flag.position + Vector2(2 + s * 4, 11), 2.0, Color(c, 0.92))


## A hand-painted wooden shop sign hanging from an iron bracket.
static func hanging_sign(ci: CanvasItem, at: Vector2, text: String, color: Color) -> void:
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 12
	var board := Rect2(at, Vector2(w, 14))
	# The bracket, and the chains.
	ci.draw_line(at + Vector2(-4, -6), at + Vector2(w + 4, -6), Color8(40, 36, 36), 2.0)
	ci.draw_arc(at + Vector2(-4, -2), 4.0, PI * 0.5, PI * 1.5, 6, Color8(40, 36, 36), 1.0)
	ci.draw_line(at + Vector2(4, -6), at + Vector2(4, 0), Color8(60, 56, 56), 1.0)
	ci.draw_line(at + Vector2(w - 4, -6), at + Vector2(w - 4, 0), Color8(60, 56, 56), 1.0)
	ci.draw_rect(Rect2(board.position + Vector2(2, 2), board.size), Color(0, 0, 0, 0.25))
	ci.draw_rect(board, Color8(122, 84, 52))
	ci.draw_rect(board.grow(-1), Color8(238, 222, 186))
	ci.draw_rect(Rect2(board.position + Vector2(1, 1), Vector2(w - 2, 1)), Color8(250, 240, 214))
	ci.draw_rect(board.grow(-3), color, false, 1.0)
	ci.draw_string(f, at + Vector2(6, 11), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)


## Doña Rosa's outdoor kitchen: an adobe counter with a tiled top, the comal (a
## round black griddle) with tortillas on it, a stack of them in a basket.
static func comal_counter(ci: CanvasItem, r: Rect2) -> void:
	shadow(ci, Vector2(r.get_center().x + 4, r.end.y + 2), Vector2(r.size.x * 0.55, 5), 0.3)
	ci.draw_rect(r, Color8(200, 150, 104))
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 4), Vector2(r.size.x, 4)), Color8(160, 112, 76))
	# Talavera tiles along the top.
	var x := r.position.x
	var k := 0
	while x < r.end.x:
		var tile := Rect2(x, r.position.y, minf(6.0, r.end.x - x), 5)
		ci.draw_rect(tile, Color8(240, 236, 222))
		ci.draw_rect(Rect2(tile.position + Vector2(2, 1), Vector2(2, 3)), Color8(40, 80, 170) if k % 2 == 0 else Color8(220, 160, 40))
		x += 6
		k += 1
	# The comal, hot.
	var c := Vector2(r.position.x + r.size.x * 0.45, r.position.y + 2)
	ci.draw_circle(c, 10.0, Color8(36, 32, 32))
	ci.draw_circle(c, 8.0, Color8(52, 46, 44))
	ci.draw_circle(c + Vector2(-3, -1), 4.0, Color8(236, 216, 160))
	ci.draw_circle(c + Vector2(4, 2), 3.5, Color8(226, 200, 140))
	ci.draw_rect(Rect2(c + Vector2(-4, -2), Vector2(2, 1)), Color8(150, 110, 60))
	# A basket of tortillas under a cloth.
	var b := Vector2(r.end.x - 12, r.position.y + 1)
	ci.draw_circle(b, 6.0, Color8(160, 120, 70))
	ci.draw_circle(b, 4.5, Color8(240, 230, 200))
	ci.draw_line(b + Vector2(-5, -1), b + Vector2(5, 1), Color8(220, 60, 60), 2.0)


## A window with wooden shutters thrown open and iron bars across it.
static func shuttered_window(ci: CanvasItem, r: Rect2, inside: Color) -> void:
	ci.draw_rect(r.grow(2), Color8(176, 130, 92))
	ci.draw_rect(r, inside)
	for k in 3:
		var bx := r.position.x + (k + 1) * r.size.x / 4.0
		ci.draw_line(Vector2(bx, r.position.y), Vector2(bx, r.end.y), Color8(40, 36, 36), 1.0)
	ci.draw_line(Vector2(r.position.x, r.get_center().y), Vector2(r.end.x, r.get_center().y), Color8(40, 36, 36), 1.0)
	for side in [-1.0, 1.0]:
		var sx := r.position.x - 7 if side < 0 else r.end.x + 1
		ci.draw_rect(Rect2(sx, r.position.y - 1, 6, r.size.y + 2), Color8(60, 100, 90))
		for k in 4:
			ci.draw_rect(Rect2(sx + 1, r.position.y + 1 + k * (r.size.y / 4.0), 4, 1), Color8(40, 70, 64))
	ci.draw_rect(Rect2(r.position.x - 3, r.end.y + 2, r.size.x + 6, 3), Color8(150, 110, 76))


## A flagpole with a finial and a flag in three stripes, rippling.
static func flagpole(ci: CanvasItem, base: Vector2, height: float, stripes: Array) -> void:
	shadow(ci, base + Vector2(10, 1), Vector2(16, 3), 0.25)
	ci.draw_rect(Rect2(base + Vector2(-5, -3), Vector2(10, 4)), Color8(150, 146, 140))
	ci.draw_rect(Rect2(base + Vector2(-1.5, -height), Vector2(3, height)), Color8(196, 196, 204))
	ci.draw_rect(Rect2(base + Vector2(-1.5, -height), Vector2(1, height)), Color8(236, 236, 240))
	ci.draw_circle(base + Vector2(0, -height - 2), 2.5, Color8(220, 190, 80))
	var top := base + Vector2(1.5, -height + 2)
	var w := 30.0
	var h := 18.0
	for k in stripes.size():
		var x0 := k * w / stripes.size()
		var x1 := (k + 1) * w / stripes.size()
		var pts := PackedVector2Array()
		for i in 5:
			var x := lerpf(x0, x1, i / 4.0)
			pts.append(top + Vector2(x, sin(x * 0.25) * 2.0))
		for i in 5:
			var x := lerpf(x1, x0, i / 4.0)
			pts.append(top + Vector2(x, h + sin(x * 0.25) * 2.0))
		ci.draw_colored_polygon(pts, stripes[k])
	ci.draw_circle(top + Vector2(w / 2, h / 2 + 1), 2.5, Color8(150, 110, 60))


## An old wooden wagon: a planked bed, big spoked wheels with iron rims and
## hubs, the tongue resting on the ground, some hay in the back.
static func old_wagon(ci: CanvasItem, r: Rect2) -> void:
	shadow(ci, Vector2(r.get_center().x + 6, r.end.y + 6), Vector2(r.size.x * 0.6, 7), 0.3)
	var wood := Color8(136, 94, 58)
	ci.draw_line(Vector2(r.end.x, r.get_center().y), Vector2(r.end.x + 22, r.end.y + 6), Color8(110, 76, 46), 3.0)
	ci.draw_rect(r, wood.darkened(0.3))
	for k in 4:
		var plank := Rect2(r.position.x + 1, r.position.y + 1 + k * (r.size.y - 2) / 4.0, r.size.x - 2, (r.size.y - 2) / 4.0 - 1)
		ci.draw_rect(plank, wood.lerp(wood.darkened(0.1), (k % 2) * 1.0))
		ci.draw_rect(Rect2(plank.position, Vector2(plank.size.x, 1)), wood.lightened(0.15))
	# Hay.
	var rng := _rng(4)
	for k in 26:
		var at := Vector2(rng.randf_range(r.position.x + 3, r.end.x - 8), rng.randf_range(r.position.y + 2, r.get_center().y))
		ci.draw_line(at, at + Vector2(rng.randf_range(3, 7), rng.randf_range(-2, 2)), Color8(220, 190, 100) if k % 2 else Color8(196, 160, 80), 1.0)
	for wx in [r.position.x + 8, r.end.x - 8]:
		var c := Vector2(wx, r.end.y + 2)
		ci.draw_arc(c, 11.0, 0, TAU, 18, Color8(56, 56, 60), 2.0)
		ci.draw_arc(c, 9.5, 0, TAU, 18, Color8(90, 64, 40), 2.0)
		for s in 6:
			var dir := Vector2.from_angle(s * PI / 6.0)
			ci.draw_line(c - dir * 9.0, c + dir * 9.0, Color8(104, 74, 46), 1.0)
		ci.draw_circle(c, 2.5, Color8(60, 60, 66))


## An old stone well: a ring of blocks, dark water, a little roof on posts, a
## crank, a rope and a bucket.
static func stone_well(ci: CanvasItem, c: Vector2) -> void:
	shadow(ci, c + Vector2(4, 10), Vector2(16, 6), 0.3)
	for k in 12:
		var a := k * TAU / 12.0
		var at := c + Vector2(cos(a) * 11.0, sin(a) * 9.0)
		ci.draw_circle(at, 3.5, Color8(160, 150, 138) if k % 2 == 0 else Color8(140, 130, 120))
	ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.82))
	ci.draw_circle(Vector2.ZERO, 7.5, Color8(24, 30, 44))
	ci.draw_circle(Vector2(-2, -2), 3.0, Color8(40, 56, 80))
	ci.draw_set_transform(Vector2.ZERO)
	# Posts, the crossbeam, the rope down to the bucket on the rim.
	for side in [-1.0, 1.0]:
		ci.draw_rect(Rect2(c + Vector2(side * 13 - 1, -22), Vector2(3, 20)), Color8(110, 76, 46))
	ci.draw_rect(Rect2(c + Vector2(-15, -24), Vector2(31, 3)), Color8(130, 92, 56))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-18, -24), c + Vector2(0, -34), c + Vector2(18, -24)]), Color8(150, 66, 46))
	ci.draw_line(c + Vector2(-18, -24), c + Vector2(0, -34), Color8(190, 96, 66), 1.0)
	ci.draw_line(c + Vector2(4, -22), c + Vector2(4, -8), Color8(200, 180, 130), 1.0)
	ci.draw_rect(Rect2(c + Vector2(1, -9), Vector2(6, 5)), Color8(120, 120, 128))
	ci.draw_rect(Rect2(c + Vector2(1, -9), Vector2(6, 1)), Color8(170, 170, 178))


## A pigeon, pecking around (`bob` lifts it a little as it hops).
static func pigeon(ci: CanvasItem, at: Vector2, facing: float, bob: float) -> void:
	var p := at + Vector2(0, -bob)
	ci.draw_set_transform(at + Vector2(1, 2), 0.0, Vector2(1.0, 0.4))
	ci.draw_circle(Vector2.ZERO, 4.0, Color(0, 0, 0, 0.18))
	ci.draw_set_transform(Vector2.ZERO)
	ci.draw_circle(p, 4.0, Color8(136, 138, 152))
	ci.draw_circle(p + Vector2(-facing * 1.5, 0.5), 3.0, Color8(112, 114, 130))
	ci.draw_rect(Rect2(p + Vector2(-facing * 5 - 1, -1), Vector2(3, 2)), Color8(70, 72, 86))
	var head := p + Vector2(facing * 4, -3)
	ci.draw_circle(head, 2.5, Color8(100, 110, 134))
	ci.draw_rect(Rect2(head + Vector2(-1, 1), Vector2(2, 2)), Color8(96, 150, 120))
	ci.draw_rect(Rect2(head + Vector2(facing * 2, 0), Vector2(1.5, 1)), Color8(230, 170, 120))
	ci.draw_rect(Rect2(head + Vector2(facing * 0.5, -1), Vector2(1, 1)), Color8(240, 120, 60))


## A grandfather clock: a tall case, a face, a window onto the pendulum.
static func grandfather_clock(ci: CanvasItem, r: Rect2, hour: int) -> void:
	shadow(ci, Vector2(r.get_center().x + 3, r.end.y), Vector2(r.size.x * 0.6, 3), 0.3)
	ci.draw_rect(r, Color8(84, 50, 32))
	ci.draw_rect(Rect2(r.position, Vector2(2, r.size.y)), Color8(116, 74, 48))
	ci.draw_rect(Rect2(r.position + Vector2(-2, 0), Vector2(r.size.x + 4, 4)), Color8(100, 62, 40))
	var face := r.position + Vector2(r.size.x / 2, 10)
	ci.draw_circle(face, 6.0, Color8(200, 170, 90))
	ci.draw_circle(face, 5.0, Color8(240, 230, 204))
	for k in 12:
		ci.draw_rect(Rect2(face + Vector2.from_angle(k * TAU / 12.0) * 4.0, Vector2(1, 1)), Color8(60, 50, 40))
	var hour_angle := -PI / 2 + hour * TAU / 12.0
	ci.draw_line(face, face + Vector2.from_angle(hour_angle) * 3.0, Color8(30, 30, 30), 1.0)
	ci.draw_line(face, face + Vector2(0, -4), Color8(30, 30, 30), 1.0)
	var pend := Rect2(r.position + Vector2(3, 20), Vector2(r.size.x - 6, r.size.y - 26))
	ci.draw_rect(pend, Color8(40, 28, 22))
	ci.draw_line(pend.position + Vector2(pend.size.x / 2, 0), pend.position + Vector2(pend.size.x / 2, pend.size.y - 6), Color8(200, 170, 90), 1.0)
	ci.draw_circle(pend.position + Vector2(pend.size.x / 2, pend.size.y - 5), 2.5, Color8(220, 190, 100))


## A dining chair from above: a seat with a cushion and a carved back.
static func dining_chair(ci: CanvasItem, at: Vector2, back_up: bool, color: Color) -> void:
	ci.draw_rect(Rect2(at + Vector2(-6, -6), Vector2(14, 14)), Color(0, 0, 0, 0.2))
	ci.draw_rect(Rect2(at + Vector2(-7, -7), Vector2(14, 14)), color)
	ci.draw_rect(Rect2(at + Vector2(-5, -5), Vector2(10, 10)), Color8(150, 40, 50))
	ci.draw_rect(Rect2(at + Vector2(-5, -5), Vector2(10, 1)), Color8(190, 70, 80))
	var by := -9.0 if back_up else 6.0
	ci.draw_rect(Rect2(at + Vector2(-7, by), Vector2(14, 3)), color.darkened(0.2))
	ci.draw_rect(Rect2(at + Vector2(-7, by), Vector2(14, 1)), color.lightened(0.2))


## A place setting: plate, fork, knife, a glass, a folded napkin.
static func place_setting(ci: CanvasItem, at: Vector2) -> void:
	ci.draw_circle(at, 6.0, Color8(232, 232, 236))
	ci.draw_circle(at, 4.5, Color8(250, 250, 252))
	ci.draw_arc(at, 6.0, 0, TAU, 12, Color8(170, 170, 190), 1.0)
	ci.draw_arc(at, 4.5, 0, TAU, 12, Color8(210, 180, 100), 1.0)
	ci.draw_line(at + Vector2(-9, -4), at + Vector2(-9, 4), Color8(196, 196, 206), 1.0)
	ci.draw_rect(Rect2(at + Vector2(-10, -4), Vector2(3, 1)), Color8(196, 196, 206))
	ci.draw_line(at + Vector2(9, -4), at + Vector2(9, 4), Color8(196, 196, 206), 1.0)
	ci.draw_circle(at + Vector2(8, -7), 2.0, Color(0.85, 0.92, 1.0, 0.7))
	ci.draw_rect(Rect2(at + Vector2(-3, 4), Vector2(6, 2)), Color8(150, 40, 50))


# --- Torrey Pines and the hills ---------------------------------------------------------

## A Torrey pine: a twisted trunk, and a wind-swept crown in flat layers, leaning
## away from the sea. `size` 1 is a normal pine; Doris is bigger.
static func torrey_pine(ci: CanvasItem, base: Vector2, size: float) -> void:
	shadow(ci, base + Vector2(10 * size, 2), Vector2(22 * size, 7 * size), 0.25)
	var bark := Color8(96, 68, 44)
	var trunk := PackedVector2Array([base + Vector2(-3, 0) * size, base + Vector2(-2, -14) * size, base + Vector2(4, -24) * size, base + Vector2(9, -30) * size,
		base + Vector2(12, -29) * size, base + Vector2(7, -22) * size, base + Vector2(3, -12) * size, base + Vector2(4, 0) * size])
	ci.draw_colored_polygon(trunk, bark)
	ci.draw_line(base + Vector2(-1, -2) * size, base + Vector2(5, -24) * size, Color8(128, 92, 60), 1.0)
	# A side branch, and the crown in layers (darkest first).
	ci.draw_line(base + Vector2(2, -16) * size, base + Vector2(-10, -24) * size, bark, 2.0 * size)
	var layers := [[Vector2(-10, -26), 9.0, Color8(30, 74, 46)], [Vector2(4, -32), 12.0, Color8(30, 74, 46)], [Vector2(16, -30), 9.0, Color8(30, 74, 46)],
		[Vector2(-8, -28), 7.0, Color8(44, 96, 58)], [Vector2(6, -35), 9.0, Color8(44, 96, 58)], [Vector2(15, -32), 6.0, Color8(44, 96, 58)],
		[Vector2(2, -38), 5.0, Color8(70, 126, 76)], [Vector2(-6, -31), 3.0, Color8(70, 126, 76)]]
	for l in layers:
		var c: Vector2 = base + (l[0] as Vector2) * size
		ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.55))
		ci.draw_circle(Vector2.ZERO, float(l[1]) * size, l[2])
		ci.draw_set_transform(Vector2.ZERO)
	# Long needles poking out of the edges.
	var rng := _rng(int(base.x * 7 + base.y))
	for k in 14:
		var c := base + Vector2(rng.randf_range(-16, 22), rng.randf_range(-40, -24)) * size
		ci.draw_line(c, c + Vector2(rng.randf_range(2, 4), rng.randf_range(-1, 1)) * size, Color8(90, 150, 90), 1.0)


## A windsock on a pole: a striped sock (orange and white), tapering, blowing.
static func windsock(ci: CanvasItem, pole: Vector2, time: float) -> void:
	shadow(ci, pole + Vector2(2, 16), Vector2(5, 2), 0.3)
	ci.draw_rect(Rect2(pole + Vector2(-3, 14), Vector2(6, 3)), Color8(120, 120, 126))
	ci.draw_line(pole + Vector2(0, 16), pole + Vector2(0, -26), Color8(190, 190, 196), 2.0)
	ci.draw_circle(pole + Vector2(0, -24), 3.0, Color8(160, 160, 166))
	var flap := sin(time * 4.0) * 3.0
	for k in 5:
		var t0 := k / 5.0
		var t1 := (k + 1) / 5.0
		var w0 := lerpf(5.0, 2.0, t0)
		var w1 := lerpf(5.0, 2.0, t1)
		var x0 := -t0 * 28.0
		var x1 := -t1 * 28.0
		var y0 := -24 + sin(time * 5.0 + t0 * 3.0) * t0 * 3.0 + flap * t0
		var y1 := -24 + sin(time * 5.0 + t1 * 3.0) * t1 * 3.0 + flap * t1
		ci.draw_colored_polygon(PackedVector2Array([pole + Vector2(x0, y0 - w0), pole + Vector2(x1, y1 - w1), pole + Vector2(x1, y1 + w1), pole + Vector2(x0, y0 + w0)]),
			Color8(244, 116, 40) if k % 2 == 0 else Color8(246, 242, 236))


## A bronze plaque on a stone post.
static func plaque(ci: CanvasItem, at: Vector2) -> void:
	shadow(ci, at + Vector2(2, 2), Vector2(8, 3), 0.3)
	ci.draw_rect(Rect2(at + Vector2(-4, -12), Vector2(8, 12)), Color8(150, 146, 138))
	ci.draw_rect(Rect2(at + Vector2(-4, -12), Vector2(2, 12)), Color8(176, 172, 164))
	ci.draw_rect(Rect2(at + Vector2(-7, -18), Vector2(14, 8)), Color8(120, 90, 50))
	ci.draw_rect(Rect2(at + Vector2(-6, -17), Vector2(12, 6)), Color8(170, 130, 70))
	for k in 3:
		ci.draw_rect(Rect2(at + Vector2(-4, -16 + k * 2), Vector2(8, 1)), Color8(110, 80, 40))


## A pitched roof of cedar shakes along the top of a wooden building.
static func shake_roof(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(-6, r.size.y), Vector2(r.size.x + 12, 4)), Color(0, 0, 0, 0.3))
	var rng := _rng(int(r.position.x))
	var rows := int(r.size.y / 5)
	for row in rows:
		var y := r.position.y + row * 5
		var x := r.position.x - 6 - (row % 2) * 3
		while x < r.end.x + 6:
			var c := Color8(122, 84, 56).lerp(Color8(96, 64, 42), rng.randf())
			ci.draw_rect(Rect2(x, y, 5, 6), c)
			ci.draw_rect(Rect2(x, y, 5, 1), c.lightened(0.15))
			x += 6
	ci.draw_rect(Rect2(r.position + Vector2(-6, 0), Vector2(r.size.x + 12, 2)), Color8(150, 110, 76))


## A sapling the Firefighter planted: a stake, a tie, leaves, and a name tag.
static func sapling(ci: CanvasItem, at: Vector2, seed: int) -> void:
	var rng := _rng(seed)
	shadow(ci, at + Vector2(2, 0), Vector2(5, 2), 0.25)
	ci.draw_circle(at, 4.0, Color8(90, 70, 50))
	ci.draw_rect(Rect2(at + Vector2(3, -16), Vector2(2, 16)), Color8(170, 140, 96))
	ci.draw_line(at, at + Vector2(0, -12), Color8(110, 80, 50), 2.0)
	ci.draw_rect(Rect2(at + Vector2(0, -9), Vector2(4, 1)), Color8(80, 160, 90))
	for k in 6:
		var a := -PI / 2 + rng.randf_range(-1.4, 1.4)
		var c := at + Vector2(0, -12) + Vector2.from_angle(a) * rng.randf_range(2, 5)
		ci.draw_circle(c, 2.0, Color8(80, 170, 80) if k % 2 == 0 else Color8(110, 196, 96))
	ci.draw_rect(Rect2(at + Vector2(5, -14), Vector2(4, 3)), Color8(244, 240, 226))


## A lookout: a wooden railing with posts, and a coin-operated viewer.
static func lookout(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(0, 6), Vector2(r.size.x, r.size.y)), Color8(150, 116, 80))
	var x := r.position.x
	while x < r.end.x:
		ci.draw_rect(Rect2(x, r.position.y + 6, 1, r.size.y), Color8(120, 90, 60))
		x += 5
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), Color8(120, 86, 54))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), Color8(170, 130, 90))
	x = r.position.x
	while x <= r.end.x:
		ci.draw_rect(Rect2(x - 1, r.position.y, 3, 10), Color8(100, 72, 44))
		x += 20
	var viewer := r.position + Vector2(r.size.x * 0.65, 14)
	ci.draw_rect(Rect2(viewer + Vector2(-1, -2), Vector2(3, 12)), Color8(70, 74, 84))
	ci.draw_rect(Rect2(viewer + Vector2(-6, -8), Vector2(12, 7)), Color8(60, 110, 70))
	ci.draw_circle(viewer + Vector2(-3, -9), 2.0, Color8(30, 30, 34))
	ci.draw_circle(viewer + Vector2(3, -9), 2.0, Color8(30, 30, 34))


# --- Westview Field -----------------------------------------------------------------------

## A wooden picnic shelter seen from above: a pitched shingle roof on four posts,
## its shadow, a picnic table peeking out from under the eave, and a hand-painted
## banner hung along the front.
static func picnic_shelter(ci: CanvasItem, r: Rect2, banner: String) -> void:
	shadow(ci, r.get_center() + Vector2(10, r.size.y * 0.55), Vector2(r.size.x * 0.6, r.size.y * 0.3), 0.3)
	# The table, under the front eave.
	var table := Rect2(r.get_center().x - 22, r.end.y - 6, 44, 10)
	ci.draw_rect(table, Color8(150, 106, 64))
	ci.draw_rect(Rect2(table.position, Vector2(table.size.x, 2)), Color8(180, 134, 86))
	ci.draw_rect(Rect2(table.position + Vector2(-2, table.size.y + 1), Vector2(table.size.x + 4, 3)), Color8(130, 90, 54))
	# Posts at the corners.
	for x in [r.position.x + 3, r.end.x - 7]:
		ci.draw_rect(Rect2(x, r.end.y - 10, 4, 14), Color8(110, 76, 44))
		ci.draw_rect(Rect2(x, r.end.y - 10, 1, 14), Color8(140, 102, 64))
	# The roof: two slopes of shingles meeting at a ridge.
	var ridge := r.position.y + r.size.y * 0.45
	var rng := _rng(int(r.position.x) + 3)
	var y := r.position.y
	var row := 0
	while y < r.end.y - 8:
		var x := r.position.x - 4 - (row % 2) * 3
		var upper := y < ridge
		while x < r.end.x + 4:
			var base := Color8(110, 70, 48) if upper else Color8(92, 56, 40)
			var c := base.lerp(base.darkened(0.15), rng.randf())
			ci.draw_rect(Rect2(x, y, 6, 5), c)
			ci.draw_rect(Rect2(x, y, 6, 1), c.lightened(0.15))
			x += 6
		y += 4
		row += 1
	ci.draw_rect(Rect2(r.position.x - 4, ridge - 2, r.size.x + 8, 3), Color8(70, 44, 30))
	ci.draw_rect(Rect2(r.position.x - 4, r.end.y - 9, r.size.x + 8, 2), Color8(60, 38, 26))
	# The banner, tied to the front posts.
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12
	var b := Rect2(r.get_center().x - w / 2, r.end.y - 22, w, 16)
	ci.draw_line(Vector2(r.position.x + 5, r.end.y - 20), b.position, Color8(200, 190, 160), 1.0)
	ci.draw_line(Vector2(r.end.x - 5, r.end.y - 20), Vector2(b.end.x, b.position.y), Color8(200, 190, 160), 1.0)
	var cloth := PackedVector2Array([b.position, Vector2(b.end.x, b.position.y), Vector2(b.end.x - 1, b.end.y), b.position + Vector2(w / 2, b.size.y + 2), Vector2(b.position.x + 1, b.end.y)])
	ci.draw_colored_polygon(cloth, Color8(236, 226, 200))
	ci.draw_string(f, b.position + Vector2(6, 13), banner, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(170, 30, 30))
	for k in 4:
		ci.draw_rect(Rect2(b.position + Vector2(4 + k * (w - 8) / 3.0, 1), Vector2(1, 1)), Color8(150, 30, 30))


## A steel hatch in the ground: a riveted lid, hinges, a wheel handle.
static func hatch(ci: CanvasItem, at: Vector2) -> void:
	shadow(ci, at + Vector2(2, 4), Vector2(16, 5), 0.25)
	var lid := Rect2(at + Vector2(-14, -10), Vector2(28, 18))
	ci.draw_rect(lid.grow(1), Color8(44, 48, 54))
	ci.draw_rect(lid, Color8(92, 98, 106))
	ci.draw_rect(Rect2(lid.position, Vector2(lid.size.x, 2)), Color8(130, 136, 146))
	for k in 4:
		ci.draw_rect(Rect2(lid.position + Vector2(2 + k * 8, lid.size.y - 3), Vector2(1, 1)), Color8(150, 156, 166))
		ci.draw_rect(Rect2(lid.position + Vector2(2 + k * 8, 3), Vector2(1, 1)), Color8(150, 156, 166))
	ci.draw_rect(Rect2(lid.position + Vector2(-3, 3), Vector2(3, 4)), Color8(60, 64, 70))
	ci.draw_rect(Rect2(lid.position + Vector2(-3, 11), Vector2(3, 4)), Color8(60, 64, 70))
	ci.draw_arc(at + Vector2(0, -1), 5.0, 0.0, TAU, 12, Color8(160, 165, 175), 2.0)
	ci.draw_line(at + Vector2(-5, -1), at + Vector2(5, -1), Color8(160, 165, 175), 1.0)
	ci.draw_line(at + Vector2(0, -6), at + Vector2(0, 4), Color8(160, 165, 175), 1.0)
	ci.draw_rect(Rect2(lid.position + Vector2(4, 8), Vector2(6, 2)), Color8(140, 90, 60))


# --- Furniture (indoors, seen from above) -------------------------------------------------

## A couch: a back, two armrests, seat cushions with a crease between them.
static func couch(ci: CanvasItem, r: Rect2, color: Color) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.22))
	var dark := color.darkened(0.25)
	ci.draw_rect(r, dark)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.35)), color.darkened(0.1))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), color.lightened(0.1))
	for side in [r.position.x, r.end.x - 10]:
		ci.draw_rect(Rect2(side, r.position.y + 2, 10, r.size.y - 2), color.darkened(0.15))
		ci.draw_rect(Rect2(side, r.position.y + 2, 10, 2), color.lightened(0.15))
	var seat := Rect2(r.position.x + 10, r.position.y + r.size.y * 0.35, r.size.x - 20, r.size.y * 0.65 - 2)
	var cushions := maxi(2, int(seat.size.x / 32))
	for k in cushions:
		var cu := Rect2(seat.position.x + k * seat.size.x / cushions + 1, seat.position.y, seat.size.x / cushions - 2, seat.size.y)
		ci.draw_rect(cu, color)
		ci.draw_rect(Rect2(cu.position, Vector2(cu.size.x, 2)), color.lightened(0.18))
		ci.draw_rect(Rect2(cu.position + Vector2(0, cu.size.y - 2), Vector2(cu.size.x, 2)), color.darkened(0.12))


## A low coffee table with a checkerboard on it, mid-game (red winning).
static func coffee_table_checkers(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(0, 0, 0, 0.22))
	ci.draw_rect(r, Color8(110, 78, 50))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color8(140, 102, 68))
	var board := Rect2(r.get_center() - Vector2(12, 7), Vector2(24, 14))
	for i in 6:
		for j in 4:
			ci.draw_rect(Rect2(board.position + Vector2(i * 4, j * 3.5), Vector2(4, 3.5)), Color8(230, 220, 196) if (i + j) % 2 == 0 else Color8(60, 40, 30))
	for k in 5:
		ci.draw_circle(board.position + Vector2(2 + (k * 7) % 24, 2 + (k * 5) % 12), 1.5, Color8(200, 40, 40) if k < 4 else Color8(20, 20, 24))


## A TV on a low stand, with a game console and one controller in front.
static func tv_stand(ci: CanvasItem, r: Rect2, on: bool) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(0, 0, 0, 0.22))
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.55), Vector2(r.size.x, r.size.y * 0.45)), Color8(70, 52, 38))
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.55), Vector2(r.size.x, 2)), Color8(96, 72, 52))
	var tv := Rect2(r.position + Vector2(6, 0), Vector2(r.size.x - 12, r.size.y * 0.55))
	ci.draw_rect(tv, Color8(26, 26, 30))
	ci.draw_rect(tv.grow(-2), Color8(60, 80, 110) if on else Color8(40, 46, 56))
	ci.draw_line(tv.position + Vector2(4, tv.size.y - 4), tv.position + Vector2(tv.size.x * 0.4, 3), Color(1, 1, 1, 0.15), 1.0)
	ci.draw_rect(Rect2(r.get_center() + Vector2(-12, r.size.y * 0.2), Vector2(14, 4)), Color8(30, 30, 34))
	ci.draw_rect(Rect2(r.get_center() + Vector2(-11, r.size.y * 0.2 + 1), Vector2(2, 1)), Color8(60, 220, 120))
	ci.draw_rect(Rect2(r.get_center() + Vector2(8, r.size.y * 0.28), Vector2(8, 4)), Color8(40, 40, 46))


## A wall shelf with a few things on it (and a photo frame lying face-down).
static func shelf(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.2))
	ci.draw_rect(r, Color8(110, 78, 50))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color8(140, 102, 68))
	ci.draw_rect(Rect2(r.position + Vector2(10, 4), Vector2(16, 6)), Color8(60, 45, 35))
	ci.draw_rect(Rect2(r.position + Vector2(11, 5), Vector2(14, 1)), Color8(90, 70, 50))
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 12, 2), Vector2(4, 8)), Color8(80, 140, 90))
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 7, 3), Vector2(4, 7)), Color8(200, 80, 70))


## A kitchen counter with a sink and tap, a plate and a cup in the drying rack.
static func kitchen_counter(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(0, 3), r.size), Color(0, 0, 0, 0.2))
	ci.draw_rect(r, Color8(150, 112, 76))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.7)), Color8(206, 206, 200))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color8(232, 232, 228))
	var sink := Rect2(r.position + Vector2(r.size.x * 0.3, 3), Vector2(20, 9))
	ci.draw_rect(sink, Color8(150, 160, 170))
	ci.draw_rect(sink.grow(-2), Color8(120, 130, 140))
	ci.draw_rect(Rect2(sink.position + Vector2(9, -3), Vector2(2, 5)), Color8(200, 204, 214))
	ci.draw_circle(r.position + Vector2(r.size.x * 0.68, 7), 4.0, Color8(240, 240, 235))
	ci.draw_arc(r.position + Vector2(r.size.x * 0.68, 7), 4.0, 0, TAU, 10, Color8(190, 190, 200), 1.0)
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.82, 3), Vector2(5, 6)), Color8(90, 140, 200))
	for k in int(r.size.x / 20):
		ci.draw_rect(Rect2(r.position + Vector2(k * 20 + 9, r.size.y * 0.8), Vector2(3, 1)), Color8(210, 200, 170))


## A tall fridge with a freezer door, a handle, and magnets (and a sign).
static func fridge(ci: CanvasItem, r: Rect2, note: String) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(0, 0, 0, 0.22))
	ci.draw_rect(r, Color8(214, 216, 220))
	ci.draw_rect(Rect2(r.position, Vector2(2, r.size.y)), Color8(240, 242, 246))
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.32), Vector2(r.size.x, 1)), Color8(160, 162, 170))
	ci.draw_rect(Rect2(r.end - Vector2(5, r.size.y * 0.6), Vector2(2, r.size.y * 0.3)), Color8(150, 152, 160))
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 5, 4), Vector2(2, r.size.y * 0.2)), Color8(150, 152, 160))
	for k in 4:
		ci.draw_rect(Rect2(r.position + Vector2(4 + (k * 7) % 14, r.size.y * 0.4 + (k * 5) % 12), Vector2(3, 3)), [Color8(220, 60, 60), Color8(60, 140, 220), Color8(240, 200, 60), Color8(90, 190, 110)][k])
	if note != "":
		ci.draw_rect(Rect2(r.position + Vector2(4, 6), Vector2(r.size.x - 10, 8)), Color8(240, 200, 90))


## A bed: frame, a pillow, a blanket folded down (made perfectly, or not).
static func bed(ci: CanvasItem, r: Rect2, blanket: Color) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.22))
	ci.draw_rect(r, Color8(110, 80, 55))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 6)), Color8(130, 96, 66))
	var mattress := r.grow(-3)
	ci.draw_rect(mattress, Color8(236, 236, 232))
	ci.draw_rect(Rect2(mattress.position + Vector2(4, 3), Vector2(mattress.size.x - 8, 10)), Color8(250, 250, 248))
	ci.draw_rect(Rect2(mattress.position + Vector2(4, 12), Vector2(mattress.size.x - 8, 1)), Color8(210, 210, 206))
	var cover := Rect2(mattress.position + Vector2(0, 16), Vector2(mattress.size.x, mattress.size.y - 16))
	ci.draw_rect(cover, blanket)
	ci.draw_rect(Rect2(cover.position, Vector2(cover.size.x, 4)), blanket.lightened(0.2))
	ci.draw_rect(Rect2(cover.position + Vector2(0, 4), Vector2(cover.size.x, 1)), blanket.darkened(0.25))
	ci.draw_rect(Rect2(cover.position + Vector2(cover.size.x / 2, 6), Vector2(1, cover.size.y - 8)), blanket.darkened(0.12))


## A nightstand with a lamp, and a folded note on it.
static func nightstand(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.2))
	ci.draw_rect(r, Color8(110, 78, 50))
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color8(140, 102, 68))
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x / 2 - 1, r.size.y - 5), Vector2(2, 1)), Color8(200, 180, 120))
	ci.draw_circle(r.position + Vector2(5, 5), 3.5, Color8(240, 220, 160))
	ci.draw_rect(Rect2(r.position + Vector2(9, 4), Vector2(8, 6)), Color8(245, 245, 235))
	ci.draw_line(r.position + Vector2(9, 7), r.position + Vector2(17, 7), Color8(200, 200, 190), 1.0)


## A closet: two sliding doors, one open a crack.
static func closet(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, Color8(90, 64, 44))
	ci.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x / 2 - 2, r.size.y - 4)), Color8(150, 112, 76))
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x / 2 + 3, 2), Vector2(r.size.x / 2 - 5, r.size.y - 4)), Color8(140, 104, 70))
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x / 2, 2), Vector2(3, r.size.y - 4)), Color8(30, 26, 26))
	ci.draw_rect(Rect2(r.position + Vector2(r.size.x / 2 - 5, r.size.y / 2), Vector2(2, 6)), Color8(200, 180, 120))


## A rug on the floor: a border and a simple woven pattern.
static func rug(ci: CanvasItem, r: Rect2, a: Color, b: Color) -> void:
	ci.draw_rect(r, a)
	ci.draw_rect(r.grow(-3), b)
	ci.draw_rect(r.grow(-6), a)
	var k := 0
	var x := r.position.x + 8
	while x < r.end.x - 8:
		ci.draw_rect(Rect2(x, r.get_center().y - 2, 4, 4), b if k % 2 == 0 else b.lightened(0.2))
		x += 8
		k += 1
	for fx in range(int(r.position.x), int(r.end.x), 3):
		ci.draw_rect(Rect2(fx, r.position.y - 2, 1, 2), a.lightened(0.3))
		ci.draw_rect(Rect2(fx, r.end.y, 1, 2), a.lightened(0.3))
