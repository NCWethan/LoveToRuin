class_name GroundDetails
extends Node2D
## Little things scattered on the ground, everywhere, baked in just above the
## tiles: flowers and tufts and clover in the grass, cracks and gum and leaves on
## the sidewalk, oil stains on the asphalt, pebbles and twigs in the dirt, shells
## and seaweed and footprints in the sand, scuffs on the floors, knots in the
## boardwalk, sprouts coming up through the burned ground. Fallen leaves gather
## under the trees.
##
## Every detail comes from a hash of its tile, so it's the same every time you
## come back. (Added to every area by Area.setup_area.)

const T := Room.TILE

var room: Room
## The Room bakes these in with its tiles (Room.details): _ci is the piece being
## drawn.
var _ci: CanvasItem = self


func _h(x: int, y: int, salt: int) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791) ^ 0x5bd1e995
	return absi(h)


## A number from 0 to 1 for this tile.
func _f(x: int, y: int, salt: int) -> float:
	return float(_h(x, y, salt) % 1000) / 1000.0


func draw_area(onto: CanvasItem, area: Rect2i) -> void:
	_ci = onto
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var tile := room.get_tile(x, y)
			var p := Vector2(x * T, y * T)
			var roll := _h(x, y, 1) % 100
			# Where along the tile: somewhere in the middle, not on the edge.
			var at := p + Vector2(4 + _f(x, y, 2) * 12.0, 4 + _f(x, y, 3) * 12.0)
			match tile:
				Room.GRASS, Room.FIELD:
					_grass(x, y, at, roll, tile == Room.FIELD)
				Room.SIDEWALK:
					_sidewalk(x, y, p, at, roll)
				Room.ASPHALT, Room.ROAD:
					_asphalt(x, y, at, roll)
				Room.DIRT:
					_dirt(x, y, at, roll)
				Room.SAND:
					_sand(x, y, at, roll)
				Room.PATIO:
					_patio(x, y, p, at, roll)
				Room.HALL_FLOOR, Room.HOUSE_FLOOR, Room.GYM_FLOOR, Room.BUNKER_FLOOR:
					_floor(x, y, at, roll)
				Room.BOARDWALK:
					_boardwalk(x, y, p, at, roll)
				Room.SCORCHED:
					_scorched(x, y, at, roll)


func _near_tree(x: int, y: int) -> bool:
	for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]:
		var t := room.get_tile(x + d.x, y + d.y)
		if t == Room.TREE or t == Room.PALM:
			return true
	return false


func _grass(x: int, y: int, at: Vector2, roll: int, field: bool) -> void:
	# Leaves, fallen under the trees.
	if _near_tree(x, y) and roll < 45:
		for k in 3:
			var leaf := at + Vector2(_f(x, y, 10 + k) * 10.0 - 5.0, _f(x, y, 20 + k) * 8.0 - 4.0)
			var colors := [Color8(170, 140, 60), Color8(120, 150, 60), Color8(190, 110, 50)]
			_ci.draw_rect(Rect2(leaf, Vector2(3, 2)), Color(colors[(x + y + k) % 3], 0.85))
		return
	if field:
		# A field: mostly just clipped grass. A divot here and there.
		if roll < 3:
			_ci.draw_rect(Rect2(at, Vector2(5, 3)), Color8(110, 90, 60, 150))
		return
	if roll < 6:
		# A little cluster of flowers.
		var palette := [Color8(250, 250, 245), Color8(250, 220, 70), Color8(240, 140, 170), Color8(180, 140, 230), Color8(250, 160, 80)]
		var color: Color = palette[_h(x, y, 4) % palette.size()]
		for k in 3:
			var f := at + Vector2(k * 3 - 3, (k % 2) * 3)
			_ci.draw_line(f + Vector2(0, 2), f + Vector2(0, 5), Color8(60, 120, 50), 1.0)
			_ci.draw_rect(Rect2(f - Vector2(1, 1), Vector2(3, 3)), color)
			_ci.draw_rect(Rect2(f, Vector2(1, 1)), Color8(250, 230, 120))
	elif roll < 11:
		# A tuft of taller grass.
		for k in 4:
			var base := at + Vector2(k * 2 - 3, 4)
			_ci.draw_line(base, base + Vector2((k - 1.5) * 1.5, -5 - (k % 2) * 2), Color8(55, 125, 55), 1.0)
	elif roll < 13:
		# A small stone, half in the grass.
		_ci.draw_set_transform(at, 0.0, Vector2(1.0, 0.6))
		_ci.draw_circle(Vector2.ZERO, 3.0, Color8(150, 150, 145))
		_ci.draw_circle(Vector2(-1, -1), 1.2, Color8(185, 185, 180))
		_ci.draw_set_transform(Vector2.ZERO)
	elif roll < 15:
		# Clover.
		for k in 3:
			_ci.draw_circle(at + Vector2.from_angle(k * TAU / 3.0) * 1.8, 1.6, Color8(70, 150, 70))
	elif roll == 15:
		# A dandelion gone to seed.
		_ci.draw_line(at, at + Vector2(0, 6), Color8(70, 120, 60), 1.0)
		_ci.draw_circle(at, 2.5, Color(1, 1, 1, 0.8))
	elif roll == 16 and _h(x, y, 5) % 3 == 0:
		# A tiny mushroom.
		_ci.draw_rect(Rect2(at + Vector2(-0.5, 0), Vector2(1.5, 3)), Color8(235, 225, 205))
		_ci.draw_rect(Rect2(at + Vector2(-2, -2), Vector2(5, 2)), Color8(190, 70, 60))


func _sidewalk(x: int, y: int, p: Vector2, at: Vector2, roll: int) -> void:
	if roll < 4:
		# A crack.
		var a := p + Vector2(_f(x, y, 6) * T, 2)
		_ci.draw_polyline(PackedVector2Array([a, a + Vector2(3, 6), a + Vector2(1, 11), a + Vector2(4, 16)]), Color8(140, 140, 132), 1.0)
	elif roll < 6:
		# Old gum.
		_ci.draw_circle(at, 1.6, Color8(120, 120, 128))
	elif roll < 8 and _near_tree(x, y):
		_ci.draw_rect(Rect2(at, Vector2(3, 2)), Color8(180, 130, 60))
	elif roll == 8:
		# A bottle cap. (Somebody else's.)
		_ci.draw_circle(at, 1.8, Color8(190, 60, 50))
	elif roll == 9 and _h(x, y, 8) % 4 == 0:
		# Chalk: a little star someone drew.
		for k in 5:
			_ci.draw_line(at, at + Vector2.from_angle(k * TAU / 5.0 - PI / 2) * 4.0, Color8(240, 200, 220), 1.0)


func _asphalt(x: int, y: int, at: Vector2, roll: int) -> void:
	if roll < 3:
		# An oil stain.
		_ci.draw_set_transform(at, 0.0, Vector2(1.0, 0.55))
		_ci.draw_circle(Vector2.ZERO, 5.0, Color(0.05, 0.05, 0.08, 0.25))
		_ci.draw_set_transform(Vector2.ZERO)
	elif roll < 5:
		var a := at - Vector2(5, 0)
		_ci.draw_polyline(PackedVector2Array([a, a + Vector2(4, 2), a + Vector2(7, 1), a + Vector2(11, 3)]), Color(0, 0, 0, 0.3), 1.0)
	elif roll == 5 and _h(x, y, 9) % 5 == 0:
		# A manhole cover.
		_ci.draw_circle(at, 6.0, Color8(60, 60, 66))
		_ci.draw_arc(at, 6.0, 0, TAU, 16, Color8(90, 90, 96), 1.0)
		_ci.draw_line(at - Vector2(4, 0), at + Vector2(4, 0), Color8(85, 85, 92), 1.0)


func _dirt(x: int, y: int, at: Vector2, roll: int) -> void:
	if roll < 8:
		for k in 3:
			_ci.draw_circle(at + Vector2(k * 3 - 3, (k % 2) * 2), 1.0, Color8(120, 95, 65))
	elif roll < 10:
		# A twig.
		_ci.draw_line(at, at + Vector2(6, 2), Color8(100, 70, 45), 1.0)
		_ci.draw_line(at + Vector2(3, 1), at + Vector2(5, -2), Color8(100, 70, 45), 1.0)
	elif roll == 10:
		# A footprint.
		_ci.draw_set_transform(at, 0.3, Vector2(0.55, 1.0))
		_ci.draw_circle(Vector2.ZERO, 3.0, Color(0, 0, 0, 0.1))
		_ci.draw_set_transform(Vector2.ZERO)


func _sand(x: int, y: int, at: Vector2, roll: int) -> void:
	if roll < 3:
		# Seaweed, washed up.
		_ci.draw_polyline(PackedVector2Array([at, at + Vector2(3, -2), at + Vector2(6, 0), at + Vector2(9, -2)]), Color8(70, 110, 60), 2.0)
	elif roll < 7:
		# A pair of footprints, going somewhere.
		for k in 2:
			_ci.draw_set_transform(at + Vector2(k * 5, (k % 2) * 4), 0.2, Vector2(0.55, 1.0))
			_ci.draw_circle(Vector2.ZERO, 2.5, Color(0.5, 0.4, 0.25, 0.25))
			_ci.draw_set_transform(Vector2.ZERO)
	elif roll == 7 and _h(x, y, 11) % 4 == 0:
		# A little crab, very still.
		_ci.draw_rect(Rect2(at, Vector2(5, 3)), Color8(220, 90, 60))
		_ci.draw_line(at + Vector2(0, 1), at + Vector2(-2, -1), Color8(220, 90, 60), 1.0)
		_ci.draw_line(at + Vector2(5, 1), at + Vector2(7, -1), Color8(220, 90, 60), 1.0)


func _patio(x: int, y: int, p: Vector2, at: Vector2, roll: int) -> void:
	if roll < 6:
		# Moss in the cracks between the stones.
		_ci.draw_rect(Rect2(p + Vector2(0, T - 2), Vector2(4 + _f(x, y, 12) * 8.0, 2)), Color8(90, 130, 70, 160))
	elif roll < 8 and _near_tree(x, y):
		_ci.draw_rect(Rect2(at, Vector2(3, 2)), Color8(180, 130, 60))
	elif roll == 8:
		# A penny.
		_ci.draw_circle(at, 1.5, Color8(200, 130, 70))


func _floor(x: int, y: int, at: Vector2, roll: int) -> void:
	if roll < 3:
		# A scuff mark.
		_ci.draw_line(at, at + Vector2(6, 1), Color(0, 0, 0, 0.12), 2.0)
	elif roll == 3:
		# A dust bunny.
		_ci.draw_circle(at, 2.0, Color(0.8, 0.8, 0.8, 0.35))
	elif roll == 4 and _h(x, y, 13) % 3 == 0:
		# A scrap of paper.
		_ci.draw_rect(Rect2(at, Vector2(4, 3)), Color(1, 1, 1, 0.5))


func _boardwalk(x: int, y: int, p: Vector2, at: Vector2, roll: int) -> void:
	if roll < 8:
		# A knot in the wood.
		_ci.draw_set_transform(at, 0.0, Vector2(1.4, 0.8))
		_ci.draw_circle(Vector2.ZERO, 1.8, Color8(110, 75, 45))
		_ci.draw_set_transform(Vector2.ZERO)
	elif roll < 14:
		# Nail heads.
		_ci.draw_rect(Rect2(p + Vector2(3, 3), Vector2(1, 1)), Color8(80, 80, 85))
		_ci.draw_rect(Rect2(p + Vector2(16, 3), Vector2(1, 1)), Color8(80, 80, 85))
	elif roll < 18:
		# Sand blown up onto the boards.
		_ci.draw_rect(Rect2(at, Vector2(6, 2)), Color8(230, 210, 160, 160))


func _scorched(x: int, y: int, at: Vector2, roll: int) -> void:
	if roll < 6:
		# Ash.
		_ci.draw_rect(Rect2(at, Vector2(3, 2)), Color8(150, 145, 140, 140))
	elif roll < 8:
		# Something green, coming back up.
		_ci.draw_line(at + Vector2(0, 3), at + Vector2(-1, -1), Color8(90, 170, 80), 1.0)
		_ci.draw_line(at + Vector2(0, 3), at + Vector2(2, 0), Color8(90, 170, 80), 1.0)
	elif roll == 8:
		# A charred pinecone.
		_ci.draw_circle(at, 2.0, Color8(40, 30, 25))
