class_name Props
extends RefCounted
## Set dressing: the little things that make a place feel lived in. Parked cars,
## trash cans, hydrants, bikes, vending machines, carts, cones, crates, flower beds,
## umbrellas, coolers, buoys... Each kind is drawn here, around a point (its middle),
## and some are solid (FOOTPRINTS: what you bump into, relative to that point).
##
## Areas place them with Area.add_dressing([[kind, position, {options}], ...]):
##   options: "color", "text" (signs, machines), "lit" (lamps), "size" (beds,
##   towels, puddles), "look" (lines to say when Elric examines it).

## The part of each solid prop you can't walk through (centered on its point).
const FOOTPRINTS := {
	"car": Vector2(44, 22), "car_v": Vector2(22, 40), "van": Vector2(56, 26), "trash_can": Vector2(12, 10),
	"recycling": Vector2(12, 10), "hydrant": Vector2(8, 6), "mailbox": Vector2(10, 8), "news_box": Vector2(12, 8),
	"vending": Vector2(20, 12), "cart": Vector2(16, 10), "picnic_table": Vector2(36, 18), "potted_plant": Vector2(12, 8),
	"bush": Vector2(22, 12), "dumpster": Vector2(40, 18), "phone_booth": Vector2(18, 12), "crate": Vector2(16, 12),
	"crates": Vector2(32, 18), "barrel": Vector2(14, 10), "bike_rack": Vector2(36, 6), "umbrella_table": Vector2(18, 10),
	"cooler": Vector2(16, 8), "lifeguard": Vector2(30, 18), "rowboat": Vector2(48, 18), "lobster_trap": Vector2(18, 10),
	"food_cart": Vector2(40, 18), "statue": Vector2(18, 14), "planter_box": Vector2(36, 12), "lamp": Vector2(6, 6),
	"sign": Vector2(6, 6), "bollard": Vector2(6, 6), "tree_small": Vector2(10, 8), "wagon": Vector2(36, 16),
	"bin_row": Vector2(40, 10), "rock": Vector2(16, 10), "log": Vector2(36, 10), "tent": Vector2(40, 22),
	"well": Vector2(20, 14), "anchor": Vector2(18, 14), "piano": Vector2(30, 14), "bookshelf": Vector2(36, 10),
	"couch": Vector2(40, 16), "fridge": Vector2(18, 12), "arcade": Vector2(18, 12), "pallet": Vector2(28, 14),
}

const PAINT := [Color8(200, 60, 55), Color8(60, 100, 180), Color8(230, 230, 235), Color8(60, 60, 66),
	Color8(90, 150, 90), Color8(230, 190, 70), Color8(140, 90, 160), Color8(160, 160, 165)]


static func paint(seed: int) -> Color:
	return PAINT[absi(seed) % PAINT.size()]


static func draw(ci: CanvasItem, kind: String, at: Vector2, opt: Dictionary, time: float) -> void:
	var color: Color = opt.get("color", Color8(200, 60, 55))
	match kind:
		"car", "car_v":
			var v := kind == "car_v"
			var s := Vector2(22, 40) if v else Vector2(44, 22)
			var r := Rect2(at - s / 2, s)
			ci.draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.25))
			# Wheels, peeking out at the corners.
			var wheel := Color8(30, 30, 34)
			if v:
				for wy in [6.0, 30.0]:
					ci.draw_rect(Rect2(r.position + Vector2(-2, wy), Vector2(3, 7)), wheel)
					ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 1, wy), Vector2(3, 7)), wheel)
			else:
				for wx in [6.0, 32.0]:
					ci.draw_rect(Rect2(r.position + Vector2(wx, -2), Vector2(7, 3)), wheel)
					ci.draw_rect(Rect2(r.position + Vector2(wx, r.size.y - 1), Vector2(7, 3)), wheel)
			# A body with rounded-off corners.
			ci.draw_rect(r.grow_individual(-2, 0, -2, 0), color)
			ci.draw_rect(r.grow_individual(0, -2, 0, -2), color)
			ci.draw_rect(r.grow_individual(-1, -1, -1, -1), color)
			var glass := Color(0.55, 0.7, 0.85)
			# Headlights at the front, tail lights at the back.
			if v:
				ci.draw_rect(Rect2(r.position + Vector2(2, 0), Vector2(4, 2)), Color8(250, 245, 200))
				ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 6, 0), Vector2(4, 2)), Color8(250, 245, 200))
				ci.draw_rect(Rect2(r.position + Vector2(2, r.size.y - 2), Vector2(4, 2)), Color8(200, 40, 40))
				ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 6, r.size.y - 2), Vector2(4, 2)), Color8(200, 40, 40))
			else:
				ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 2, 2), Vector2(2, 4)), Color8(250, 245, 200))
				ci.draw_rect(Rect2(r.position + Vector2(r.size.x - 2, r.size.y - 6), Vector2(2, 4)), Color8(250, 245, 200))
				ci.draw_rect(Rect2(r.position + Vector2(0, 2), Vector2(2, 4)), Color8(200, 40, 40))
				ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 6), Vector2(2, 4)), Color8(200, 40, 40))
			if v:
				ci.draw_rect(Rect2(r.position + Vector2(3, 6), Vector2(16, 8)), glass)
				ci.draw_rect(Rect2(r.position + Vector2(3, 26), Vector2(16, 6)), glass.darkened(0.15))
				ci.draw_rect(Rect2(r.position + Vector2(3, 16), Vector2(16, 8)), color.lightened(0.15))
			else:
				ci.draw_rect(Rect2(r.position + Vector2(8, 3), Vector2(10, 16)), glass)
				ci.draw_rect(Rect2(r.position + Vector2(28, 3), Vector2(8, 16)), glass.darkened(0.15))
				ci.draw_rect(Rect2(r.position + Vector2(18, 3), Vector2(10, 16)), color.lightened(0.15))
		"van":
			var r := Rect2(at - Vector2(28, 13), Vector2(56, 26))
			ci.draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.25))
			ci.draw_rect(r, color)
			ci.draw_rect(Rect2(r.position + Vector2(42, 3), Vector2(10, 20)), Color(0.55, 0.7, 0.85))
			ci.draw_rect(r, color.darkened(0.35), false, 1.0)
		"trash_can", "recycling":
			var c := Color8(70, 75, 80) if kind == "trash_can" else Color8(50, 100, 170)
			ci.draw_rect(Rect2(at + Vector2(-6, -14), Vector2(12, 18)), c)
			ci.draw_rect(Rect2(at + Vector2(-7, -16), Vector2(14, 3)), c.lightened(0.2))
			if kind == "recycling":
				ci.draw_arc(at + Vector2(0, -6), 3.0, 0, TAU * 0.8, 8, Color.WHITE, 1.0)
		"hydrant":
			ci.draw_rect(Rect2(at + Vector2(-4, -12), Vector2(8, 14)), Color8(210, 50, 45))
			ci.draw_rect(Rect2(at + Vector2(-6, -8), Vector2(12, 3)), Color8(180, 40, 40))
			ci.draw_circle(at + Vector2(0, -13), 3.0, Color8(210, 50, 45))
		"mailbox":
			ci.draw_rect(Rect2(at + Vector2(-1, -6), Vector2(2, 8)), Color8(90, 90, 95))
			ci.draw_rect(Rect2(at + Vector2(-5, -16), Vector2(10, 10)), Color8(50, 80, 160))
			ci.draw_rect(Rect2(at + Vector2(-5, -16), Vector2(10, 3)), Color8(70, 100, 180))
		"news_box":
			ci.draw_rect(Rect2(at + Vector2(-6, -16), Vector2(12, 18)), color)
			ci.draw_rect(Rect2(at + Vector2(-4, -14), Vector2(8, 6)), Color(0.9, 0.9, 0.85))
		"vending":
			var r := Rect2(at + Vector2(-10, -30), Vector2(20, 32))
			ci.draw_rect(r, color)
			ci.draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(10, 20)), Color(0.75, 0.9, 1.0, 0.8))
			for k in 4:
				ci.draw_rect(Rect2(r.position + Vector2(4, 5 + k * 5), Vector2(8, 3)), PAINT[k])
			ci.draw_rect(Rect2(r.position + Vector2(15, 8), Vector2(3, 8)), Color(0.2, 0.2, 0.2))
			var glow := 0.15 + 0.05 * sin(time * 3.0)
			ci.draw_circle(at + Vector2(0, -14), 22.0, Color(color.lightened(0.4), glow))
		"cart":
			ci.draw_rect(Rect2(at + Vector2(-8, -12), Vector2(16, 10)), Color8(170, 175, 185), false, 1.0)
			for k in 4:
				ci.draw_line(at + Vector2(-8 + k * 5, -12), at + Vector2(-8 + k * 5, -2), Color8(170, 175, 185), 1.0)
			ci.draw_circle(at + Vector2(-6, 1), 2.0, Color8(40, 40, 40))
			ci.draw_circle(at + Vector2(6, 1), 2.0, Color8(40, 40, 40))
		"cone":
			ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-5, 2), at + Vector2(5, 2), at + Vector2(0, -12)]), Color8(240, 120, 40))
			ci.draw_line(at + Vector2(-3, -4), at + Vector2(3, -4), Color.WHITE, 2.0)
		"picnic_table":
			ci.draw_rect(Rect2(at + Vector2(-18, -6), Vector2(36, 10)), Color8(150, 105, 60))
			ci.draw_rect(Rect2(at + Vector2(-18, -11), Vector2(36, 3)), Color8(125, 85, 50))
			ci.draw_rect(Rect2(at + Vector2(-18, 6), Vector2(36, 3)), Color8(125, 85, 50))
		"potted_plant":
			ci.draw_rect(Rect2(at + Vector2(-5, -6), Vector2(10, 8)), Color8(180, 100, 60))
			ci.draw_circle(at + Vector2(0, -10), 7.0, Color8(60, 140, 70))
			ci.draw_circle(at + Vector2(-3, -12), 4.0, Color8(80, 165, 85))
		"bush":
			ci.draw_circle(at + Vector2(-6, -4), 8.0, Color8(55, 125, 60))
			ci.draw_circle(at + Vector2(6, -4), 8.0, Color8(55, 125, 60))
			ci.draw_circle(at + Vector2(0, -9), 8.0, Color8(70, 145, 70))
			if opt.get("berries", false):
				for k in 5:
					ci.draw_circle(at + Vector2(-8 + k * 4, -6 - (k % 2) * 5), 1.2, Color8(220, 60, 70))
		"flower_bed":
			var size: Vector2 = opt.get("size", Vector2(60, 16))
			var r := Rect2(at - size / 2, size)
			ci.draw_rect(r, Color8(100, 70, 45))
			ci.draw_rect(r, Color8(150, 150, 145), false, 2.0)
			var palette := [Color8(240, 80, 100), Color8(250, 220, 70), Color8(250, 250, 245), Color8(180, 120, 230)]
			var n := int(size.x / 6)
			for k in n:
				var f := r.position + Vector2(3 + k * 6, 4 + (k % 2) * 6)
				ci.draw_circle(f, 2.5, palette[k % palette.size()])
		"dumpster":
			var r := Rect2(at + Vector2(-20, -18), Vector2(40, 20))
			ci.draw_rect(r, Color8(50, 110, 70))
			ci.draw_rect(Rect2(r.position + Vector2(-1, -3), Vector2(42, 4)), Color8(40, 90, 55))
			ci.draw_rect(r, Color8(30, 70, 40), false, 1.0)
		"phone_booth":
			ci.draw_rect(Rect2(at + Vector2(-9, -36), Vector2(18, 38)), Color8(190, 40, 40))
			ci.draw_rect(Rect2(at + Vector2(-6, -30), Vector2(12, 24)), Color(0.7, 0.85, 1.0, 0.6))
		"crate", "crates":
			var offsets := [Vector2.ZERO] if kind == "crate" else [Vector2(-8, 0), Vector2(8, 0), Vector2(0, -12)]
			for o in offsets:
				var r := Rect2(at + o + Vector2(-8, -12), Vector2(16, 14))
				ci.draw_rect(r, Color8(170, 125, 75))
				ci.draw_rect(r, Color8(120, 85, 50), false, 1.0)
				ci.draw_line(r.position, r.end, Color8(120, 85, 50), 1.0)
		"barrel":
			ci.draw_rect(Rect2(at + Vector2(-7, -16), Vector2(14, 18)), color if opt.has("color") else Color8(120, 80, 50))
			for k in 2:
				ci.draw_line(at + Vector2(-7, -12 + k * 9), at + Vector2(7, -12 + k * 9), Color8(70, 70, 75), 1.0)
		"bike_rack":
			for k in 4:
				ci.draw_arc(at + Vector2(-14 + k * 9, -2), 4.0, PI, TAU, 8, Color8(150, 150, 160), 2.0)
			if opt.get("bike", true):
				var bc := opt.get("color", Color8(60, 120, 200)) as Color
				ci.draw_arc(at + Vector2(-10, 0), 4.0, 0, TAU, 10, Color8(40, 40, 40), 1.0)
				ci.draw_arc(at + Vector2(0, 0), 4.0, 0, TAU, 10, Color8(40, 40, 40), 1.0)
				ci.draw_line(at + Vector2(-10, 0), at + Vector2(-5, -5), bc, 1.5)
				ci.draw_line(at + Vector2(-5, -5), at + Vector2(0, 0), bc, 1.5)
		"bike":
			ci.draw_arc(at + Vector2(-6, 0), 5.0, 0, TAU, 10, Color8(40, 40, 40), 1.5)
			ci.draw_arc(at + Vector2(6, 0), 5.0, 0, TAU, 10, Color8(40, 40, 40), 1.5)
			ci.draw_polyline(PackedVector2Array([at + Vector2(-6, 0), at + Vector2(-1, -6), at + Vector2(6, 0), at + Vector2(-2, 0), at + Vector2(-1, -6)]), color, 1.5)
			ci.draw_line(at + Vector2(-1, -6), at + Vector2(-2, -9), color, 1.5)
			ci.draw_line(at + Vector2(4, -7), at + Vector2(6, 0), color, 1.5)
		"umbrella_table":
			ci.draw_rect(Rect2(at + Vector2(-8, -4), Vector2(16, 6)), Color8(230, 230, 230))
			ci.draw_line(at + Vector2(0, -4), at + Vector2(0, -22), Color8(120, 120, 120), 1.0)
			ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-16, -20), at + Vector2(16, -20), at + Vector2(0, -30)]), color)
			ci.draw_line(at + Vector2(-16, -20), at + Vector2(16, -20), color.darkened(0.3), 1.0)
		"cooler":
			ci.draw_rect(Rect2(at + Vector2(-8, -8), Vector2(16, 10)), color if opt.has("color") else Color8(50, 120, 200))
			ci.draw_rect(Rect2(at + Vector2(-8, -10), Vector2(16, 3)), Color.WHITE)
		"towel":
			var size: Vector2 = opt.get("size", Vector2(20, 34))
			ci.draw_rect(Rect2(at - size / 2, size), color)
			for k in 3:
				ci.draw_rect(Rect2(at - size / 2 + Vector2(0, 6 + k * 10), Vector2(size.x, 3)), Color(1, 1, 1, 0.6))
		"sandcastle":
			ci.draw_rect(Rect2(at + Vector2(-10, -6), Vector2(20, 8)), Color8(210, 185, 130))
			for k in 3:
				ci.draw_rect(Rect2(at + Vector2(-9 + k * 7, -12), Vector2(5, 7)), Color8(220, 195, 140))
			ci.draw_line(at + Vector2(0, -12), at + Vector2(0, -20), Color8(90, 70, 50), 1.0)
			ci.draw_rect(Rect2(at + Vector2(0, -20), Vector2(5, 3)), Color8(220, 60, 60))
		"lifeguard":
			ci.draw_line(at + Vector2(-12, 4), at + Vector2(-8, -16), Color8(240, 240, 240), 2.0)
			ci.draw_line(at + Vector2(12, 4), at + Vector2(8, -16), Color8(240, 240, 240), 2.0)
			ci.draw_rect(Rect2(at + Vector2(-14, -34), Vector2(28, 18)), Color8(240, 200, 60))
			ci.draw_rect(Rect2(at + Vector2(-16, -38), Vector2(32, 5)), Color8(210, 60, 50))
			ci.draw_string(ThemeDB.fallback_font, at + Vector2(-12, -22), "GUARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color8(200, 50, 40))
		"buoy":
			var bob := sin(time * 2.0 + at.x) * 2.0
			ci.draw_circle(at + Vector2(0, bob), 5.0, Color8(230, 80, 50))
			ci.draw_rect(Rect2(at + Vector2(-5, -1 + bob), Vector2(10, 2)), Color.WHITE)
		"rowboat":
			ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-24, -6), at + Vector2(24, -6), at + Vector2(18, 8), at + Vector2(-18, 8)]), color if opt.has("color") else Color8(170, 120, 70))
			ci.draw_rect(Rect2(at + Vector2(-16, -2), Vector2(32, 3)), Color8(120, 80, 50))
		"lobster_trap":
			var r := Rect2(at + Vector2(-9, -10), Vector2(18, 12))
			ci.draw_rect(r, Color8(160, 120, 70), false, 1.0)
			for k in 4:
				ci.draw_line(r.position + Vector2(k * 6, 0), r.position + Vector2(k * 6, 12), Color8(160, 120, 70), 1.0)
		"rope":
			for k in 3:
				ci.draw_arc(at, 3.0 + k * 2.5, 0, TAU, 14, Color8(200, 170, 110), 1.5)
		"food_cart":
			var r := Rect2(at + Vector2(-20, -20), Vector2(40, 22))
			ci.draw_rect(r, color)
			ci.draw_rect(Rect2(r.position + Vector2(-2, -12), Vector2(44, 6)), Color8(240, 240, 240))
			for k in 6:
				ci.draw_rect(Rect2(r.position + Vector2(-2 + k * 8, -12), Vector2(4, 6)), color)
			ci.draw_circle(at + Vector2(-14, 4), 4.0, Color8(40, 40, 40))
			ci.draw_circle(at + Vector2(14, 4), 4.0, Color8(40, 40, 40))
			if opt.has("text"):
				ci.draw_string(ThemeDB.fallback_font, r.position + Vector2(3, 14), opt["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
		"statue":
			ci.draw_rect(Rect2(at + Vector2(-9, -6), Vector2(18, 8)), Color8(170, 170, 165))
			ci.draw_rect(Rect2(at + Vector2(-5, -30), Vector2(10, 24)), Color8(120, 140, 130))
			ci.draw_circle(at + Vector2(0, -33), 5.0, Color8(120, 140, 130))
		"planter_box":
			ci.draw_rect(Rect2(at + Vector2(-18, -8), Vector2(36, 10)), Color8(140, 100, 70))
			for k in 6:
				ci.draw_circle(at + Vector2(-15 + k * 6, -10), 4.0, Color8(70, 150, 70))
		"lamp":
			ci.draw_rect(Rect2(at + Vector2(-1.5, -34), Vector2(3, 36)), Color8(60, 60, 66))
			ci.draw_rect(Rect2(at + Vector2(-5, -40), Vector2(10, 7)), Color8(60, 60, 66))
			var lit: bool = opt.get("lit", false)
			ci.draw_rect(Rect2(at + Vector2(-3, -38), Vector2(6, 4)), Color(1.0, 0.9, 0.6, 1.0 if lit else 0.4))
			if lit:
				ci.draw_circle(at + Vector2(0, -36), 26.0, Color(1.0, 0.85, 0.5, 0.08))
		"sign":
			ci.draw_rect(Rect2(at + Vector2(-1.5, -20), Vector2(3, 22)), Color8(120, 120, 125))
			var text: String = opt.get("text", "")
			var w := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 8
			ci.draw_rect(Rect2(at + Vector2(-w / 2, -32), Vector2(w, 12)), color if opt.has("color") else Color8(40, 110, 60))
			ci.draw_string(ThemeDB.fallback_font, at + Vector2(-w / 2 + 4, -23), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		"bollard":
			ci.draw_rect(Rect2(at + Vector2(-3, -10), Vector2(6, 12)), Color8(240, 200, 40))
			ci.draw_rect(Rect2(at + Vector2(-3, -6), Vector2(6, 2)), Color8(40, 40, 40))
		"puddle":
			var size: Vector2 = opt.get("size", Vector2(24, 10))
			ci.draw_set_transform(at, 0.0, Vector2(1.0, size.y / size.x))
			ci.draw_circle(Vector2.ZERO, size.x / 2, Color(0.4, 0.55, 0.75, 0.45))
			ci.draw_circle(Vector2(-size.x / 6, -2), size.x / 6, Color(1, 1, 1, 0.15 + 0.1 * sin(time * 2.0)))
			ci.draw_set_transform(Vector2.ZERO)
		"trash_bag":
			ci.draw_circle(at + Vector2(0, -5), 6.0, Color8(40, 40, 45))
			ci.draw_line(at + Vector2(0, -11), at + Vector2(2, -14), Color8(40, 40, 45), 2.0)
		"tree_small":
			ci.draw_rect(Rect2(at + Vector2(-1.5, -8), Vector2(3, 10)), Color8(100, 70, 45))
			ci.draw_circle(at + Vector2(0, -14), 8.0, Color8(60, 140, 70))
		"wagon":
			ci.draw_rect(Rect2(at + Vector2(-18, -10), Vector2(36, 12)), Color8(140, 95, 55))
			ci.draw_circle(at + Vector2(-12, 3), 5.0, Color8(80, 55, 35))
			ci.draw_circle(at + Vector2(12, 3), 5.0, Color8(80, 55, 35))
		"bin_row":
			for k in 3:
				ci.draw_rect(Rect2(at + Vector2(-20 + k * 14, -14), Vector2(12, 16)), [Color8(70, 75, 80), Color8(50, 100, 170), Color8(60, 140, 70)][k])
		"rock":
			ci.draw_set_transform(at, 0.0, Vector2(1.0, 0.65))
			ci.draw_circle(Vector2.ZERO, 9.0, Color8(140, 135, 130))
			ci.draw_circle(Vector2(-3, -3), 4.0, Color8(170, 165, 160))
			ci.draw_set_transform(Vector2.ZERO)
		"log":
			ci.draw_rect(Rect2(at + Vector2(-18, -5), Vector2(36, 10)), Color8(110, 75, 45))
			ci.draw_circle(at + Vector2(18, 0), 5.0, Color8(170, 130, 80))
		"tent":
			ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-20, 8), at + Vector2(0, -16), at + Vector2(20, 8)]), color if opt.has("color") else Color8(90, 130, 80))
			ci.draw_line(at + Vector2(0, -16), at + Vector2(0, 8), Color(0, 0, 0, 0.3), 1.0)
		"campfire":
			for k in 5:
				ci.draw_circle(at + Vector2.from_angle(k * TAU / 5) * 6.0, 2.5, Color8(130, 120, 110))
			var f := 0.7 + 0.3 * sin(time * 9.0)
			ci.draw_circle(at, 4.0 * f, Color(1.0, 0.6, 0.2, 0.9))
			ci.draw_circle(at, 14.0, Color(1.0, 0.6, 0.2, 0.12))
		"well":
			ci.draw_circle(at, 10.0, Color8(150, 140, 130))
			ci.draw_circle(at, 6.0, Color8(30, 40, 60))
		"anchor":
			ci.draw_line(at + Vector2(0, -14), at + Vector2(0, 4), Color8(80, 80, 90), 3.0)
			ci.draw_arc(at + Vector2(0, -2), 8.0, 0, PI, 10, Color8(80, 80, 90), 3.0)
			ci.draw_line(at + Vector2(-5, -10), at + Vector2(5, -10), Color8(80, 80, 90), 2.0)
		"string_lights":
			var w: float = opt.get("size", Vector2(120, 0)).x
			for k in int(w / 12):
				var p := at + Vector2(k * 12, sin(k * 0.5) * 3.0 + 4.0)
				var on := 0.6 + 0.4 * sin(time * 3.0 + k)
				ci.draw_circle(p, 2.0, Color(PAINT[k % 6], on))
			ci.draw_line(at, at + Vector2(w, 0), Color8(50, 50, 50), 1.0)
		"piano":
			ci.draw_rect(Rect2(at + Vector2(-15, -18), Vector2(30, 20)), Color8(40, 30, 30))
			for k in 7:
				ci.draw_rect(Rect2(at + Vector2(-13 + k * 4, -4), Vector2(3, 5)), Color.WHITE)
		"bookshelf":
			ci.draw_rect(Rect2(at + Vector2(-18, -30), Vector2(36, 32)), Color8(110, 75, 45))
			for row in 3:
				for k in 8:
					ci.draw_rect(Rect2(at + Vector2(-16 + k * 4, -28 + row * 10), Vector2(3, 8)), PAINT[(k + row) % PAINT.size()])
		"couch":
			ci.draw_rect(Rect2(at + Vector2(-20, -14), Vector2(40, 16)), color if opt.has("color") else Color8(120, 70, 60))
			ci.draw_rect(Rect2(at + Vector2(-20, -18), Vector2(40, 6)), (color if opt.has("color") else Color8(120, 70, 60)).darkened(0.2))
		"fridge":
			ci.draw_rect(Rect2(at + Vector2(-9, -34), Vector2(18, 36)), Color8(230, 230, 235))
			ci.draw_line(at + Vector2(-9, -20), at + Vector2(9, -20), Color8(180, 180, 185), 1.0)
		"arcade":
			ci.draw_rect(Rect2(at + Vector2(-9, -34), Vector2(18, 36)), color)
			ci.draw_rect(Rect2(at + Vector2(-6, -30), Vector2(12, 10)), Color(0.3, 0.9, 0.6, 0.5 + 0.3 * sin(time * 5.0)))
		"pallet":
			for k in 4:
				ci.draw_rect(Rect2(at + Vector2(-14, -7 + k * 4), Vector2(28, 3)), Color8(180, 140, 90))
		_:
			ci.draw_circle(at, 4.0, Color.MAGENTA)
