class_name TileArt
extends RefCounted
## How every kind of map tile is drawn (Room bakes the results into pictures, so
## none of this runs while you play: it can afford to be detailed).
##
## Two passes:
##   ground()  the floor of every tile: grass, sidewalk, road, water, walls...
##             Tiles look at their neighbors: grass spills over the edges of paths,
##             sidewalks get a curb where they meet the road, water gets shallow and
##             foamy near the shore, walls get a cap on top and a plinth at the
##             bottom, windows and doors sit in whatever wall they're part of.
##   tall()    things that stick up (trees, palms, stumps, fences, benches,
##             planters, umbrella tables), drawn after all the ground around them so
##             a tree's crown can hang over the tile above it.
## Every bit of variety comes from a hash of the tile's position, so a place looks
## the same every time you come back.

const T := 20

## Things drawn in the second pass (over the ground around them).
const TALL := [Room.TREE, Room.PALM, Room.STUMP, Room.FENCE, Room.BENCH, Room.PLANTER, Room.TABLE]
## Ground a tall thing can stand on (it takes its floor from its neighbors).
const FLOORS := [Room.GRASS, Room.SIDEWALK, Room.ASPHALT, Room.ROAD, Room.DIRT, Room.SAND, Room.PATIO,
	Room.BOARDWALK, Room.FIELD, Room.SCORCHED, Room.HALL_FLOOR, Room.HOUSE_FLOOR, Room.GYM_FLOOR, Room.BUNKER_FLOOR, Room.ARCADE_CARPET]
## Walls a window or a door can be set into.
const WALLS := [Room.WALL, Room.STUCCO, Room.ADOBE, Room.RED_WALL, Room.WOOD_WALL, Room.INTERIOR_WALL,
	Room.HOUSE_WALL, Room.BUNKER_WALL]
## Anything that's part of a building's face (for caps and plinths).
const FACADE := [Room.WALL, Room.STUCCO, Room.ADOBE, Room.RED_WALL, Room.WOOD_WALL, Room.WINDOW, Room.DOOR,
	Room.GLASS, Room.INTERIOR_WALL, Room.HOUSE_WALL, Room.LOCKER, Room.CHALKBOARD, Room.BUNKER_WALL, Room.BUNKER_DOOR]
const GRASSY := [Room.GRASS, Room.TREE, Room.FIELD]
const ROADS := [Room.ROAD, Room.ROAD_LINE, Room.ASPHALT, Room.PARKING_LINE]

var room: Room
var ci: CanvasItem


func _init(for_room: Room) -> void:
	room = for_room


# --- Little helpers ----------------------------------------------------------------

func _h(x: int, y: int, salt: int = 0) -> int:
	return absi((x * 73856093) ^ (y * 19349663) ^ (salt * 83492791) ^ 0x2545F491)


## 0..1 for this tile (and salt).
func _f(x: int, y: int, salt: int = 0) -> float:
	return float(_h(x, y, salt) % 1000) / 1000.0


func _t(x: int, y: int) -> int:
	return room.get_tile(x, y)


func _rect(p: Vector2, size: Vector2, c: Color) -> void:
	ci.draw_rect(Rect2(p, size), c)


## Scattered single pixels (or small squares) in one color.
func _dots(x: int, y: int, salt: int, p: Vector2, count: int, c: Color, size: float = 1.0, inset: int = 1) -> void:
	for i in count:
		var h := _h(x, y, salt + i * 13)
		var span := T - inset * 2 - int(size)
		_rect(p + Vector2(inset + h % span, inset + (h / 31) % span), Vector2(size, size), c)


## Gentle variation across a whole area (changes every few tiles, not every tile).
func _patch(x: int, y: int, salt: int, scale: int = 3) -> float:
	var gx := x / float(scale)
	var gy := y / float(scale)
	var x0 := floori(gx)
	var y0 := floori(gy)
	var tx := gx - x0
	var ty := gy - y0
	# Smoothstep, so the blend has no visible seams either.
	tx = tx * tx * (3.0 - 2.0 * tx)
	ty = ty * ty * (3.0 - 2.0 * ty)
	var top := lerpf(_f(x0, y0, salt), _f(x0 + 1, y0, salt), tx)
	var bottom := lerpf(_f(x0, y0 + 1, salt), _f(x0 + 1, y0 + 1, salt), tx)
	return lerpf(top, bottom, ty)


# --- Pass 1: the ground ---------------------------------------------------------------

func ground(x: int, y: int, tile: int) -> void:
	var p := Vector2(x * T, y * T)
	match tile:
		Room.GRASS: _grass(x, y, p)
		Room.FIELD, Room.FIELD_LINE: _field(x, y, p, tile == Room.FIELD_LINE)
		Room.SIDEWALK: _sidewalk(x, y, p)
		Room.ASPHALT, Room.PARKING_LINE: _asphalt(x, y, p, tile == Room.PARKING_LINE)
		Room.ROAD, Room.ROAD_LINE: _road(x, y, p, tile == Room.ROAD_LINE)
		Room.DIRT: _dirt(x, y, p)
		Room.SAND: _sand(x, y, p)
		Room.WATER: _water(x, y, p)
		Room.PATIO: _patio(x, y, p)
		Room.BOARDWALK: _boardwalk(x, y, p)
		Room.SCORCHED: _scorched(x, y, p)
		Room.WALL: _brick(x, y, p)
		Room.STUCCO: _stucco(x, y, p)
		Room.ADOBE: _adobe(x, y, p)
		Room.RED_WALL: _red_wall(x, y, p)
		Room.WOOD_WALL: _wood_wall(x, y, p)
		Room.ROOF: _roof(x, y, p)
		Room.CLAY_ROOF: _clay_roof(x, y, p)
		Room.WINDOW: _window(x, y, p)
		Room.GLASS: _glass(x, y, p)
		Room.DOOR: _door(x, y, p)
		Room.GATE: _gate(x, y, p)
		Room.BLEACHERS: _bleachers(x, y, p)
		Room.VOID: _rect(p, Vector2(T, T), Color.BLACK)
		Room.INTERIOR_WALL: _interior_wall(x, y, p)
		Room.HALL_FLOOR: _hall_floor(x, y, p)
		Room.LOCKER: _locker(x, y, p)
		Room.CHALKBOARD: _chalkboard(x, y, p)
		Room.DESK: _desk(x, y, p)
		Room.GYM_FLOOR, Room.GYM_LINE: _gym_floor(x, y, p, tile == Room.GYM_LINE)
		Room.HOUSE_FLOOR, Room.HOUSE_PROP: _house_floor(x, y, p)
		Room.HOUSE_WALL: _house_wall(x, y, p)
		Room.BUNKER_FLOOR: _bunker_floor(x, y, p)
		Room.ARCADE_CARPET: _arcade_carpet(x, y, p)
		# Solid ground that something is drawn on top of (a junk heap, a well, the
		# armor on its stands): just the floor around it.
		Room.PROP: ground(x, y, _floor_under(x, y))
		Room.BUNKER_WALL: _bunker_wall(x, y, p)
		Room.BUNKER_DOOR: _bunker_door(x, y, p)
		_:
			if tile in TALL:
				# Tall things stand on whatever floor is around them, with a shadow.
				ground(x, y, _floor_under(x, y))
				_ground_shadow(x, y, p, tile)


## The floor around a tall thing: the most common floor among its neighbors.
func _floor_under(x: int, y: int) -> int:
	var counts := {}
	for d in [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		var t := _t(x + d.x, y + d.y)
		if t == Room.ROAD_LINE: t = Room.ROAD
		if t == Room.PARKING_LINE: t = Room.ASPHALT
		if t == Room.FIELD_LINE: t = Room.FIELD
		if t in FLOORS:
			counts[t] = int(counts.get(t, 0)) + 1
	# In the middle of something big (a junk heap), look farther out.
	var reach := 2
	while counts.is_empty() and reach <= 5:
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				if absi(dx) != reach and absi(dy) != reach:
					continue
				var t := _t(x + dx, y + dy)
				if t == Room.ROAD_LINE: t = Room.ROAD
				if t == Room.PARKING_LINE: t = Room.ASPHALT
				if t == Room.FIELD_LINE: t = Room.FIELD
				if t in FLOORS:
					counts[t] = int(counts.get(t, 0)) + 1
		reach += 1
	var best := Room.GRASS
	var most := 0
	for t in counts:
		if counts[t] > most:
			most = counts[t]
			best = t
	# Stumps stand in burned ground.
	if _t(x, y) == Room.STUMP and best == Room.GRASS:
		return Room.SCORCHED
	return best


func _ground_shadow(x: int, y: int, p: Vector2, tile: int) -> void:
	var size := 9.0
	match tile:
		Room.TREE: size = 11.0 + _f(x, y, 40) * 2.0
		Room.PALM: size = 9.0
		Room.STUMP: size = 7.0
		Room.FENCE, Room.BENCH, Room.PLANTER, Room.TABLE: return
	ci.draw_set_transform(p + Vector2(12, 17), 0.0, Vector2(1.0, 0.38))
	ci.draw_circle(Vector2.ZERO, size, Color(0, 0, 0, 0.22))
	ci.draw_circle(Vector2.ZERO, size * 0.6, Color(0, 0, 0, 0.1))
	ci.draw_set_transform(Vector2.ZERO)


# --- Outdoors -------------------------------------------------------------------------

func _grass(x: int, y: int, p: Vector2) -> void:
	# Big soft patches of lighter and darker green, so a lawn isn't one flat color.
	var tone := _patch(x, y, 1, 4) * 0.6 + _patch(x + 1, y + 2, 2, 7) * 0.4
	var base := Color8(72, 140, 61).lerp(Color8(82, 150, 65), tone)
	_rect(p, Vector2(T, T), base)
	# Blades: short dark and light strokes.
	var dark := base.darkened(0.2)
	var light := base.lightened(0.16)
	for i in 7:
		var h := _h(x, y, 50 + i)
		var at := p + Vector2(1 + h % 18, 2 + (h / 19) % 16)
		_rect(at, Vector2(1, 2), dark)
	for i in 4:
		var h := _h(x, y, 70 + i)
		_rect(p + Vector2(1 + h % 18, 1 + (h / 23) % 17), Vector2(1, 1), light)
	# Now and then a clump, or a worn patch.
	if _h(x, y, 90) % 6 == 0:
		var c := p + Vector2(4 + _h(x, y, 91) % 10, 5 + _h(x, y, 92) % 9)
		for k in 3:
			_rect(c + Vector2(k * 2 - 2, -k % 2), Vector2(1, 3), dark)
		_rect(c + Vector2(0, -1), Vector2(1, 1), light)
	if _h(x, y, 93) % 29 == 0:
		_rect(p + Vector2(5, 7), Vector2(8, 5), base.lerp(Color8(150, 130, 80), 0.25))
	_singed(x, y, p)


## Grass next to burned ground: browned and curled along that edge.
func _singed(x: int, y: int, p: Vector2) -> void:
	var burnt := [Room.SCORCHED, Room.STUMP]
	var brown := Color8(120, 104, 60)
	var dark := Color8(70, 56, 40)
	for side in [[Vector2i(0, -1), Vector2(0, 0), Vector2(1, 0)], [Vector2i(0, 1), Vector2(0, T - 1), Vector2(1, 0)],
			[Vector2i(-1, 0), Vector2(0, 0), Vector2(0, 1)], [Vector2i(1, 0), Vector2(T - 1, 0), Vector2(0, 1)]]:
		if not _t(x + side[0].x, y + side[0].y) in burnt:
			continue
		var inward: Vector2 = Vector2(-side[0].x, -side[0].y)
		for i in 10:
			var depth := 1 + _h(x, y, 500 + i + side[0].x * 7 + side[0].y * 13) % 5
			for d in depth:
				_rect(p + side[1] + side[2] * (i * 2) + inward * d, Vector2(2, 2) if side[2].x > 0 else Vector2(2, 2), dark if d == 0 else brown.lerp(dark, 0.3 * float(depth - d) / depth))


func _field(x: int, y: int, p: Vector2, line: bool) -> void:
	# Mown stripes, two greens, with the grain of the mower in them.
	var stripe := Color8(86, 168, 74) if y % 2 == 0 else Color8(78, 156, 66)
	_rect(p, Vector2(T, T), stripe)
	for i in 6:
		var h := _h(x, y, 20 + i)
		_rect(p + Vector2(1 + h % 18, 1 + (h / 17) % 17), Vector2(2, 1), stripe.darkened(0.08) if i % 2 == 0 else stripe.lightened(0.07))
	if line:
		_rect(p + Vector2(9, 0), Vector2(2, T), Color8(236, 238, 232))
		_rect(p + Vector2(9, _h(x, y, 3) % 18), Vector2(2, 2), Color8(200, 214, 196))
	_singed(x, y, p)


## Grass spilling over the edge of a path: tufts along whichever sides touch grass.
func _grass_fringe(x: int, y: int, p: Vector2) -> void:
	var dark := Color8(64, 126, 54)
	var light := Color8(88, 156, 70)
	if _t(x, y - 1) in GRASSY:
		for i in 10:
			var h := _h(x, y, 300 + i)
			_rect(p + Vector2(i * 2, 0), Vector2(2, 1 + h % 3), dark if h % 3 else light)
	if _t(x, y + 1) in GRASSY:
		for i in 10:
			var h := _h(x, y, 320 + i)
			var len := 1 + h % 2
			_rect(p + Vector2(i * 2, T - len), Vector2(2, len), dark)
	if _t(x - 1, y) in GRASSY:
		for i in 10:
			var h := _h(x, y, 340 + i)
			_rect(p + Vector2(0, i * 2), Vector2(1 + h % 3, 2), dark if h % 3 else light)
	if _t(x + 1, y) in GRASSY:
		for i in 10:
			var h := _h(x, y, 360 + i)
			var len := 1 + h % 3
			_rect(p + Vector2(T - len, i * 2), Vector2(len, 2), dark if h % 3 else light)


func _sidewalk(x: int, y: int, p: Vector2) -> void:
	# Concrete slabs: each one a slightly different gray, with a joint around it.
	var base := Color8(180, 180, 172).lerp(Color8(168, 168, 160), _f(x, y, 1))
	_rect(p, Vector2(T, T), base)
	_dots(x, y, 2, p, 6, base.darkened(0.07))
	_dots(x, y, 3, p, 3, base.lightened(0.06))
	var joint := base.darkened(0.2)
	_rect(p, Vector2(T, 1), joint)
	_rect(p, Vector2(1, T), joint)
	_rect(p + Vector2(1, 1), Vector2(T - 1, 1), base.lightened(0.08))
	# A chipped corner, sometimes.
	if _h(x, y, 4) % 9 == 0:
		_rect(p + Vector2(T - 3, T - 2), Vector2(3, 2), base.darkened(0.14))
	# The curb, where the sidewalk meets the road.
	if _t(x, y + 1) in ROADS:
		_rect(p + Vector2(0, T - 4), Vector2(T, 2), Color8(206, 206, 198))
		_rect(p + Vector2(0, T - 2), Vector2(T, 2), Color8(122, 122, 118))
	if _t(x, y - 1) in ROADS:
		_rect(p, Vector2(T, 2), Color8(122, 122, 118))
		_rect(p + Vector2(0, 2), Vector2(T, 1), Color8(206, 206, 198))
	_grass_fringe(x, y, p)


func _asphalt(x: int, y: int, p: Vector2, line: bool) -> void:
	var base := Color8(58, 58, 64).lerp(Color8(64, 63, 68), _patch(x, y, 5))
	_rect(p, Vector2(T, T), base)
	_dots(x, y, 6, p, 9, base.lightened(0.12), 1.0, 0)
	_dots(x, y, 7, p, 6, base.darkened(0.18), 1.0, 0)
	_dots(x, y, 8, p, 2, base.lightened(0.22), 2.0, 1)
	if _h(x, y, 9) % 13 == 0:
		# A patched square where the asphalt was redone.
		_rect(p + Vector2(3, 4), Vector2(11, 9), base.darkened(0.1))
		_rect(p + Vector2(3, 4), Vector2(11, 1), base.lightened(0.05))
	if line:
		# A painted stall line, worn where the tires go.
		_rect(p + Vector2(9, 0), Vector2(2, T), Color8(228, 228, 222))
		for k in 3:
			_rect(p + Vector2(9 + (k % 2), 3 + k * 6 + _h(x, y, 10 + k) % 3), Vector2(1, 1), base)
	_grass_fringe(x, y, p)


func _road(x: int, y: int, p: Vector2, line: bool) -> void:
	var base := Color8(48, 48, 54).lerp(Color8(53, 52, 58), _patch(x, y, 11, 4))
	_rect(p, Vector2(T, T), base)
	_dots(x, y, 12, p, 10, base.lightened(0.14), 1.0, 0)
	_dots(x, y, 13, p, 5, base.darkened(0.25), 1.0, 0)
	# Tire tracks: two faint darker lanes, worn smooth.
	_rect(p + Vector2(0, 4), Vector2(T, 2), base.darkened(0.06))
	_rect(p + Vector2(0, 14), Vector2(T, 2), base.darkened(0.06))
	if _h(x, y, 14) % 11 == 0:
		# A crack, with a tar seal over it.
		var a := p + Vector2(2, 3 + _h(x, y, 15) % 10)
		ci.draw_line(a, a + Vector2(7, 3), Color8(30, 30, 34), 1.0)
		ci.draw_line(a + Vector2(7, 3), a + Vector2(16, 1), Color8(30, 30, 34), 1.0)
	if line and x % 3 != 0:
		_rect(p + Vector2(0, 9), Vector2(T, 2), Color8(232, 198, 60))
		_rect(p + Vector2(0, 9), Vector2(T, 1), Color8(244, 214, 92))
		if _h(x, y, 16) % 3 == 0:
			_rect(p + Vector2(4 + _h(x, y, 17) % 10, 9), Vector2(2, 1), base.lightened(0.1))
	# The gutter, darker along the curb.
	if _t(x, y - 1) == Room.SIDEWALK:
		_rect(p, Vector2(T, 2), base.darkened(0.25))
	if _t(x, y + 1) == Room.SIDEWALK:
		_rect(p + Vector2(0, T - 2), Vector2(T, 2), base.darkened(0.25))


func _dirt(x: int, y: int, p: Vector2) -> void:
	var base := Color8(152, 120, 80).lerp(Color8(140, 110, 72), _patch(x, y, 18))
	_rect(p, Vector2(T, T), base)
	_dots(x, y, 19, p, 8, base.darkened(0.12))
	_dots(x, y, 20, p, 5, base.lightened(0.1))
	# Pebbles: a light top and a dark underside.
	for i in 2:
		var h := _h(x, y, 21 + i)
		var at := p + Vector2(2 + h % 15, 2 + (h / 15) % 15)
		_rect(at, Vector2(3, 2), Color8(176, 164, 146))
		_rect(at + Vector2(0, 2), Vector2(3, 1), Color8(110, 92, 66))
	# Ruts, where feet and wheels have worn it down.
	if _h(x, y, 24) % 4 == 0:
		_rect(p + Vector2(0, 7 + _h(x, y, 25) % 6), Vector2(T, 1), base.darkened(0.1))
	_grass_fringe(x, y, p)


func _sand(x: int, y: int, p: Vector2) -> void:
	var near_water := _t(x, y + 1) == Room.WATER or _t(x, y - 1) == Room.WATER
	var base := Color8(236, 214, 162).lerp(Color8(228, 204, 150), _patch(x, y, 26))
	if near_water:
		base = Color8(206, 182, 132)   # wet sand
	_rect(p, Vector2(T, T), base)
	_dots(x, y, 27, p, 8, base.darkened(0.08))
	_dots(x, y, 28, p, 6, base.lightened(0.07))
	# Ripples the wind leaves behind.
	if not near_water and _h(x, y, 29) % 3 == 0:
		var ry := 4 + _h(x, y, 30) % 12
		for k in 3:
			_rect(p + Vector2(2 + k * 6, ry + (k % 2)), Vector2(5, 1), base.darkened(0.07))
	# A shell, now and then.
	if _h(x, y, 31) % 31 == 0:
		var at := p + Vector2(5 + _h(x, y, 32) % 9, 6 + _h(x, y, 33) % 8)
		_rect(at, Vector2(4, 3), Color8(250, 236, 226))
		_rect(at + Vector2(1, 1), Vector2(2, 1), Color8(232, 190, 176))
	if _t(x, y + 1) == Room.WATER:
		# Where the last wave reached: a thin line of foam on the wet sand.
		for i in 10:
			var h := _h(x, y, 400 + i)
			_rect(p + Vector2(i * 2, T - 2 - h % 2), Vector2(2, 1), Color(1, 1, 1, 0.55))


## How far this bit of water is from land (1 = right at the shore, up to 5).
func _depth(x: int, y: int) -> int:
	if _t(x, y) != Room.WATER:
		return 0
	for r in range(1, 5):
		for d in [Vector2i(0, -r), Vector2i(0, r), Vector2i(-r, 0), Vector2i(r, 0)]:
			var t := _t(x + d.x, y + d.y)
			if t != Room.WATER and t != Room.VOID:
				return r
	return 5


func _water_color(depth: int) -> Color:
	return Color8(80, 162, 206).lerp(Color8(34, 96, 156), clampf((depth - 1) / 4.0, 0.0, 1.0))


func _water(x: int, y: int, p: Vector2) -> void:
	# Deeper (and darker) the farther from land, blended into the water next to it
	# so there are no hard edges between depths.
	var depth := _depth(x, y)
	var base := _water_color(depth)
	_rect(p, Vector2(T, T), base)
	for side in [[Vector2i(0, -1), Vector2(0, 0), Vector2(T, 1)], [Vector2i(0, 1), Vector2(0, T - 1), Vector2(T, 1)],
			[Vector2i(-1, 0), Vector2(0, 0), Vector2(1, T)], [Vector2i(1, 0), Vector2(T - 1, 0), Vector2(1, T)]]:
		var other := _depth(x + side[0].x, y + side[0].y)
		if other == 0 or other == depth:
			continue
		var theirs := _water_color(other)
		var inward: Vector2 = Vector2(-side[0].x, -side[0].y)
		for k in 6:
			_rect(side[1] + p + inward * k, side[2], theirs.lerp(base, (k + 1) / 7.0).lerp(base, 0.5))
	# Swells: long soft bands, a little lighter and darker.
	_rect(p + Vector2(0, (y * 7) % 20 / 2), Vector2(T, 2), base.lightened(0.05))
	_rect(p + Vector2(0, (y * 7 + 10) % 20 / 2 + 8), Vector2(T, 1), base.darkened(0.06))
	# Wave crests: short white dashes.
	for i in 2:
		var h := _h(x, y, 34 + i)
		var at := p + Vector2(h % 14, 3 + (h / 14) % 14)
		_rect(at, Vector2(5 + h % 3, 1), Color(1, 1, 1, 0.32))
		_rect(at + Vector2(1, 1), Vector2(3, 1), base.darkened(0.12))
	# A pond's grassy bank, with reeds (no surf in a pond).
	for side in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		if _t(x + side.x, y + side.y) in GRASSY:
			_bank(x, y, p, side)
	# Foam where it meets the sand (or a pier), ragged.
	var foam := Color(1, 1, 1, 0.7)
	var up := _t(x, y - 1)
	if up != Room.WATER and up != Room.VOID and not up in GRASSY:
		for i in 10:
			var h := _h(x, y, 410 + i)
			_rect(p + Vector2(i * 2, 0), Vector2(2, 2 + h % 3), foam)
		_rect(p + Vector2(0, 5), Vector2(T, 1), Color(1, 1, 1, 0.25))
	var left := _t(x - 1, y)
	if left != Room.WATER and left != Room.VOID and not left in GRASSY:
		for i in 10:
			_rect(p + Vector2(0, i * 2), Vector2(1 + _h(x, y, 430 + i) % 3, 2), foam)
	var right := _t(x + 1, y)
	if right != Room.WATER and right != Room.VOID and not right in GRASSY:
		for i in 10:
			var w := 1 + _h(x, y, 450 + i) % 3
			_rect(p + Vector2(T - w, i * 2), Vector2(w, 2), foam)


## The edge of a pond against the grass: a dark muddy line, grass hanging over
## it, and reeds here and there.
func _bank(x: int, y: int, p: Vector2, side: Vector2i) -> void:
	var mud := Color8(70, 92, 70)
	var grass := Color8(70, 136, 58)
	for i in 10:
		var h := _h(x, y, 600 + i + side.x * 3 + side.y * 7)
		var len := 2 + h % 3
		var along := float(i * 2)
		if side.y != 0:
			var edge := 0.0 if side.y < 0 else float(T - len)
			_rect(p + Vector2(along, edge), Vector2(2, len), mud)
			_rect(p + Vector2(along, 0.0 if side.y < 0 else float(T - 1 - h % 2)), Vector2(2, 1 + h % 2), grass)
		else:
			var edge := 0.0 if side.x < 0 else float(T - len)
			_rect(p + Vector2(edge, along), Vector2(len, 2), mud)
			_rect(p + Vector2(0.0 if side.x < 0 else float(T - 1 - h % 2), along), Vector2(1 + h % 2, 2), grass)
	# Reeds, with their brown heads.
	if _h(x, y, 620 + side.x + side.y * 2) % 3 == 0:
		var at := p + Vector2(4 + _h(x, y, 621) % 12, 3 if side.y < 0 else T - 9) if side.y != 0 else p + Vector2(3 if side.x < 0 else T - 6, 4 + _h(x, y, 622) % 10)
		for k in 3:
			_rect(at + Vector2(k * 2, -k % 2), Vector2(1, 6), Color8(90, 140, 70))
		_rect(at + Vector2(2, -2), Vector2(1, 3), Color8(120, 82, 50))


func _patio(x: int, y: int, p: Vector2) -> void:
	# Terracotta tiles, two to a tile, each fired a slightly different color.
	for k in 2:
		for j in 2:
			var tone := _f(x * 2 + k, y * 2 + j, 36)
			var c := Color8(198, 122, 84).lerp(Color8(180, 104, 70), tone)
			var at := p + Vector2(k * 10, j * 10)
			_rect(at, Vector2(10, 10), c)
			_rect(at + Vector2(1, 1), Vector2(8, 1), c.lightened(0.1))
			_rect(at + Vector2(1, 8), Vector2(8, 1), c.darkened(0.08))
	var grout := Color8(150, 92, 64)
	_rect(p, Vector2(T, 1), grout)
	_rect(p + Vector2(0, 10), Vector2(T, 1), grout)
	_rect(p, Vector2(1, T), grout)
	_rect(p + Vector2(10, 0), Vector2(1, T), grout)
	_grass_fringe(x, y, p)


func _boardwalk(x: int, y: int, p: Vector2) -> void:
	# Sun-bleached planks running the long way, each a little different, with gaps.
	for k in 4:
		var tone := _f(x, y * 4 + k, 37)
		var c := Color8(178, 142, 100).lerp(Color8(160, 124, 86), tone)
		var at := p + Vector2(k * 5, 0)
		_rect(at, Vector2(5, T), c)
		_rect(at + Vector2(1, 0), Vector2(1, T), c.lightened(0.08))
		# Grain.
		_rect(at + Vector2(3, _h(x, y, 38 + k) % 14), Vector2(1, 5), c.darkened(0.1))
		_rect(at + Vector2(4, 0), Vector2(1, T), Color8(116, 88, 60))
	# Nail heads where the planks cross a joist.
	if y % 2 == 0:
		for k in 4:
			_rect(p + Vector2(k * 5 + 2, 2), Vector2(1, 1), Color8(96, 80, 64))
	# Blown sand drifting onto it from the beach.
	if _t(x, y + 1) == Room.SAND:
		for i in 6:
			var h := _h(x, y, 39 + i)
			_rect(p + Vector2(h % 18, T - 1 - (h / 18) % 4), Vector2(2, 1), Color8(232, 210, 156))


func _scorched(x: int, y: int, p: Vector2) -> void:
	var base := Color8(52, 42, 36).lerp(Color8(44, 36, 30), _patch(x, y, 40))
	_rect(p, Vector2(T, T), base)
	# Ragged edges against living grass: ash thinning out into it.
	for side in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		if _t(x + side.x, y + side.y) in [Room.GRASS, Room.FIELD, Room.FIELD_LINE]:
			for i in 5:
				var h := _h(x, y, 520 + i + side.x * 5 + side.y * 11)
				var along := float(i * 4 + h % 3)
				var at := p + (Vector2(along, 0 if side.y < 0 else T - 2) if side.y != 0 else Vector2(0 if side.x < 0 else T - 2, along))
				_rect(at, Vector2(2, 2), Color8(96, 110, 58))
	_dots(x, y, 41, p, 7, Color8(98, 92, 88))
	_dots(x, y, 42, p, 5, Color8(28, 22, 18), 2.0)
	if _h(x, y, 43) % 6 == 0:
		ci.draw_line(p + Vector2(2, 8), p + Vector2(10, 12), Color8(24, 18, 14), 1.0)
		ci.draw_line(p + Vector2(10, 12), p + Vector2(17, 9), Color8(24, 18, 14), 1.0)
	# Embers, still glowing in the cracks.
	if _h(x, y, 44) % 11 == 0:
		var at := p + Vector2(_h(x, y, 45) % 16 + 2, _h(x, y, 46) % 16 + 2)
		_rect(at - Vector2(1, 1), Vector2(4, 4), Color(0.9, 0.35, 0.15, 0.25))
		_rect(at, Vector2(2, 2), Color8(236, 96, 42))
		_rect(at, Vector2(1, 1), Color8(255, 196, 96))
	# White ash, drifted into little heaps.
	if _h(x, y, 47) % 7 == 0:
		_rect(p + Vector2(6, 12), Vector2(6, 2), Color8(150, 146, 142))
		_rect(p + Vector2(7, 11), Vector2(4, 1), Color8(176, 172, 168))


# --- Building faces -------------------------------------------------------------------

## A ledge along the top of a wall (where there's no more wall above it) and a
## darker plinth along the bottom (where it meets the ground).
func _cap_and_plinth(x: int, y: int, p: Vector2, wall: Color) -> void:
	if not _t(x, y - 1) in FACADE and _t(x, y - 1) != Room.ROOF and _t(x, y - 1) != Room.CLAY_ROOF:
		_rect(p, Vector2(T, 3), wall.lightened(0.18))
		_rect(p + Vector2(0, 3), Vector2(T, 1), wall.darkened(0.25))
	if not _t(x, y + 1) in FACADE:
		_rect(p + Vector2(0, T - 4), Vector2(T, 4), wall.darkened(0.3))
		_rect(p + Vector2(0, T - 4), Vector2(T, 1), wall.darkened(0.12))


func _brick(x: int, y: int, p: Vector2) -> void:
	var mortar := Color8(176, 156, 124)
	_rect(p, Vector2(T, T), mortar)
	# Four courses of bricks, staggered, each brick its own shade.
	for row in 4:
		var offset := 0 if (row + y) % 2 == 0 else -5
		for b in 3:
			var bx := offset + b * 10
			var tone := _f(x * 3 + b, y * 4 + row, 48)
			var c := Color8(206, 172, 130).lerp(Color8(186, 148, 108), tone)
			var left := maxf(bx, 0.0)
			var right := minf(bx + 9.0, float(T))
			if right <= left:
				continue
			_rect(p + Vector2(left, row * 5), Vector2(right - left, 4), c)
			_rect(p + Vector2(left, row * 5), Vector2(right - left, 1), c.lightened(0.08))
	_cap_and_plinth(x, y, p, Color8(196, 164, 124))


## The color of whichever wall this window or door is set into.
func _wall_around(x: int, y: int) -> int:
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-2, 0), Vector2i(2, 0)]:
		var t := _t(x + d.x, y + d.y)
		if t in WALLS:
			return t
	return Room.WALL


func _wall_face(x: int, y: int, p: Vector2, wall: int) -> void:
	match wall:
		Room.STUCCO: _stucco(x, y, p)
		Room.ADOBE: _adobe(x, y, p)
		Room.RED_WALL: _red_wall(x, y, p)
		Room.WOOD_WALL: _wood_wall(x, y, p)
		Room.INTERIOR_WALL: _interior_wall(x, y, p)
		Room.HOUSE_WALL: _house_wall(x, y, p)
		Room.BUNKER_WALL: _bunker_wall(x, y, p)
		_: _brick(x, y, p)


func _stucco(x: int, y: int, p: Vector2) -> void:
	var base := Color8(224, 210, 180).lerp(Color8(216, 200, 170), _patch(x, y, 49))
	_rect(p, Vector2(T, T), base)
	_dots(x, y, 50, p, 7, base.darkened(0.05))
	_dots(x, y, 51, p, 4, base.lightened(0.05))
	if _h(x, y, 52) % 17 == 0:
		ci.draw_line(p + Vector2(4, 3), p + Vector2(7, 9), base.darkened(0.15), 1.0)
		ci.draw_line(p + Vector2(7, 9), p + Vector2(6, 14), base.darkened(0.15), 1.0)
	_cap_and_plinth(x, y, p, base)


func _is_cliff(x: int, y: int) -> bool:
	for dx in range(-3, 4):
		var t := _t(x + dx, y)
		if t == Room.SAND or t == Room.WATER:
			return true
	return false


func _cliff(x: int, y: int, p: Vector2) -> void:
	# Sandstone, in bands the color of the sunset, crumbling at the edges.
	var bands := [Color8(212, 160, 108), Color8(196, 140, 92), Color8(222, 178, 124), Color8(184, 128, 84), Color8(206, 150, 100)]
	_rect(p, Vector2(T, T), bands[0])
	for k in 5:
		var c: Color = bands[(k + y * 2 + int(x / 2.0)) % bands.size()]
		_rect(p + Vector2(0, k * 4), Vector2(T, 4), c)
		# The bands' edges wander a little, like real rock layers.
		for i in 5:
			var bump := int(_h(x, y, 540 + k * 5 + i) % 3) - 1
			if bump != 0:
				_rect(p + Vector2(i * 4, k * 4 + (0 if bump < 0 else 3)), Vector2(4, 1), c.darkened(0.08) if bump > 0 else c.lightened(0.06))
	_dots(x, y, 530, p, 8, Color8(160, 108, 70))
	_dots(x, y, 531, p, 5, Color8(236, 196, 146))
	if _h(x, y, 532) % 5 == 0:
		ci.draw_line(p + Vector2(3 + _h(x, y, 533) % 12, 0), p + Vector2(5 + _h(x, y, 534) % 10, T), Color8(150, 98, 62), 1.0)
	# The grassy lip at the top of the cliff, and the shadow at its foot.
	if _t(x + 1, y) == Room.GRASS or _t(x + 1, y) == Room.FENCE:
		for i in 10:
			_rect(p + Vector2(T - 1 - _h(x, y, 535 + i) % 3, i * 2), Vector2(3, 2), Color8(78, 140, 60))
	if _t(x - 1, y) == Room.SAND:
		_rect(p, Vector2(2, T), Color8(150, 104, 66))


func _adobe(x: int, y: int, p: Vector2) -> void:
	if _is_cliff(x, y):
		_cliff(x, y, p)
		return
	var base := Color8(214, 168, 120).lerp(Color8(202, 154, 108), _patch(x, y, 53))
	_rect(p, Vector2(T, T), base)
	_dots(x, y, 54, p, 6, base.darkened(0.08), 2.0)
	_dots(x, y, 55, p, 4, base.lightened(0.07))
	# Where the plaster's fallen off: the mud bricks underneath.
	if _h(x, y, 56) % 6 == 0:
		var at := p + Vector2(2 + _h(x, y, 57) % 8, 3 + _h(x, y, 58) % 8)
		_rect(at - Vector2(1, 1), Vector2(11, 8), base.darkened(0.12))
		for row in 2:
			for b in 2:
				_rect(at + Vector2(b * 5 + (row % 2) * 2, row * 3), Vector2(4, 2), Color8(168, 112, 74))
	if _h(x, y, 59) % 7 == 0:
		ci.draw_line(p + Vector2(4, 6), p + Vector2(9, 12), base.darkened(0.2), 1.0)
	# Vigas: round wooden beam ends poking out under the roof.
	if _t(x, y - 1) == Room.CLAY_ROOF and x % 2 == 0:
		_rect(p + Vector2(6, 1), Vector2(7, 5), Color8(96, 66, 42))
		_rect(p + Vector2(7, 2), Vector2(5, 3), Color8(132, 94, 60))
		_rect(p + Vector2(6, 6), Vector2(7, 1), Color(0, 0, 0, 0.2))
	_cap_and_plinth(x, y, p, base)


func _red_wall(x: int, y: int, p: Vector2) -> void:
	# White panels with a red band (Jack in the Box, the ballpark).
	var base := Color8(236, 236, 232)
	_rect(p, Vector2(T, T), base)
	_rect(p + Vector2(0, 6), Vector2(T, 5), Color8(206, 40, 46))
	_rect(p + Vector2(0, 6), Vector2(T, 1), Color8(232, 80, 82))
	_rect(p + Vector2(0, 10), Vector2(T, 1), Color8(160, 28, 34))
	# Panel seams, and a little grime.
	if x % 2 == 0:
		_rect(p, Vector2(1, T), base.darkened(0.12))
	_dots(x, y, 60, p, 3, base.darkened(0.07))
	_cap_and_plinth(x, y, p, base.darkened(0.05))


func _wood_wall(x: int, y: int, p: Vector2) -> void:
	# Horizontal boards, each its own brown, with grain and the odd knot.
	for row in 4:
		var tone := _f(x, y * 4 + row, 61)
		var c := Color8(114, 74, 46).lerp(Color8(98, 62, 38), tone)
		var at := p + Vector2(0, row * 5)
		_rect(at, Vector2(T, 5), c)
		_rect(at, Vector2(T, 1), c.lightened(0.12))
		_rect(at + Vector2(0, 4), Vector2(T, 1), Color8(66, 42, 26))
		_rect(at + Vector2(_h(x, y, 62 + row) % 12, 2), Vector2(6, 1), c.darkened(0.1))
	if _h(x, y, 66) % 5 == 0:
		var at := p + Vector2(4 + _h(x, y, 67) % 10, 6 + 5 * (_h(x, y, 68) % 2))
		_rect(at, Vector2(3, 2), Color8(62, 38, 22))
		_rect(at + Vector2(1, 0), Vector2(1, 1), Color8(130, 92, 60))
	_cap_and_plinth(x, y, p, Color8(108, 70, 44))


func _roof(x: int, y: int, p: Vector2) -> void:
	# Asphalt shingles in staggered rows; lighter up top, an eave at the bottom.
	var base := Color8(122, 72, 62)
	_rect(p, Vector2(T, T), base.darkened(0.15))
	for row in 4:
		var offset := 0 if (row + y) % 2 == 0 else 3
		for k in 4:
			var tone := _f(x * 4 + k, y * 4 + row, 69)
			var c := base.lerp(base.darkened(0.18), tone)
			var at := p + Vector2(offset + k * 6 - 3, row * 5)
			_rect(at, Vector2(5, 4), c)
			_rect(at, Vector2(5, 1), c.lightened(0.1))
	if not _t(x, y + 1) in [Room.ROOF]:
		_rect(p + Vector2(0, T - 3), Vector2(T, 2), Color8(88, 52, 44))
		_rect(p + Vector2(0, T - 1), Vector2(T, 1), Color8(60, 36, 30))
	if not _t(x, y - 1) in [Room.ROOF]:
		_rect(p, Vector2(T, 2), base.lightened(0.15))


func _clay_roof(x: int, y: int, p: Vector2) -> void:
	# Barrel tiles: rounded columns, overlapping rows, each a slightly different red.
	var base := Color8(182, 84, 56)
	_rect(p, Vector2(T, T), base.darkened(0.3))
	for col in 4:
		for row in 4:
			var tone := _f(x * 4 + col, y * 4 + row, 70)
			var c := base.lerp(Color8(160, 70, 46), tone)
			var at := p + Vector2(col * 5, row * 5)
			_rect(at + Vector2(0, 0), Vector2(4, 5), c)
			_rect(at + Vector2(1, 0), Vector2(1, 4), c.lightened(0.2))
			_rect(at + Vector2(3, 0), Vector2(1, 5), c.darkened(0.15))
			_rect(at + Vector2(0, 4), Vector2(4, 1), c.darkened(0.25))
	if _t(x, y + 1) != Room.CLAY_ROOF:
		# The eave: round tile ends, and the shadow under them.
		for col in 4:
			_rect(p + Vector2(col * 5, T - 3), Vector2(4, 3), Color8(196, 98, 66))
			_rect(p + Vector2(col * 5 + 1, T - 2), Vector2(2, 1), Color8(120, 52, 36))


func _window(x: int, y: int, p: Vector2) -> void:
	var wall := _wall_around(x, y)
	_wall_face(x, y, p, wall)
	var frame := Color8(236, 232, 222) if wall in [Room.WALL, Room.ADOBE, Room.WOOD_WALL] else Color8(92, 92, 102)
	# Frame, glass with a soft reflection, the cross bars, and a sill.
	_rect(p + Vector2(3, 2), Vector2(14, 14), frame)
	var glass_top := Color8(150, 196, 232)
	var glass_bottom := Color8(96, 140, 186)
	for k in 12:
		_rect(p + Vector2(4, 3 + k), Vector2(12, 1), glass_top.lerp(glass_bottom, k / 11.0))
	ci.draw_line(p + Vector2(5, 12), p + Vector2(11, 4), Color(1, 1, 1, 0.35), 2.0)
	_rect(p + Vector2(9, 3), Vector2(2, 12), frame)
	_rect(p + Vector2(4, 8), Vector2(12, 1), frame)
	# Curtains in some windows.
	if _h(x, y, 71) % 3 == 0:
		var curtain: Color = [Color8(200, 80, 80), Color8(220, 200, 120), Color8(120, 150, 200)][_h(x, y, 72) % 3]
		_rect(p + Vector2(4, 3), Vector2(3, 12), curtain)
		_rect(p + Vector2(13, 3), Vector2(3, 12), curtain.darkened(0.1))
	_rect(p + Vector2(2, 16), Vector2(16, 2), frame.lightened(0.1))
	_rect(p + Vector2(2, 18), Vector2(16, 1), Color(0, 0, 0, 0.25))


func _glass(x: int, y: int, p: Vector2) -> void:
	# A storefront: dark glass in a metal frame, a diagonal reflection, and
	# something on display behind it.
	_rect(p, Vector2(T, T), Color8(62, 72, 84))
	for k in 18:
		_rect(p + Vector2(1, 1 + k), Vector2(18, 1), Color8(98, 136, 166).lerp(Color8(64, 92, 120), k / 17.0))
	var shop := _display_at(x, y)
	if shop.size() > 0:
		_display(shop[0], x - shop[1].x, y - shop[1].y, p)
	elif _h(x, y, 73) % 2 == 0:
		var shelf := [Color8(220, 120, 80), Color8(110, 180, 120), Color8(230, 200, 90), Color8(170, 120, 200)]
		for k in 3:
			_rect(p + Vector2(3 + k * 5, 12), Vector2(3, 5), shelf[(_h(x, y, 74) + k) % 4].darkened(0.3))
		_rect(p + Vector2(2, 17), Vector2(16, 1), Color8(70, 70, 80))
	ci.draw_line(p + Vector2(3, 17), p + Vector2(15, 3), Color(1, 1, 1, 0.3), 2.0)
	ci.draw_line(p + Vector2(9, 17), p + Vector2(18, 7), Color(1, 1, 1, 0.15), 1.0)
	_rect(p, Vector2(1, T), Color8(150, 154, 162))
	_rect(p, Vector2(T, 1), Color8(150, 154, 162))


## What a shop has in its window: the Room meta "displays" is a list of
## [Rect2i (tiles), kind]. Returns [kind, the rect's corner], or [] for none.
func _display_at(x: int, y: int) -> Array:
	for d in room.get_meta("displays", []):
		var r: Rect2i = d[0]
		if r.has_point(Vector2i(x, y)):
			return [d[1], r.position]
	return []


## A shop window's stock, one tile of it (`col`, `row`: which tile of the window).
func _display(kind: String, col: int, row: int, p: Vector2) -> void:
	var v := (col * 7 + row * 3) % 4
	match kind:
		"grocery":
			if row == 0:
				# A SALE banner, and hanging bananas.
				_rect(p + Vector2(2, 3), Vector2(16, 6), Color8(240, 240, 230))
				_rect(p + Vector2(3, 5), Vector2(14, 2), Color8(220, 50, 50))
				if v % 2 == 0:
					_rect(p + Vector2(5, 11), Vector2(2, 5), Color8(240, 210, 70))
					_rect(p + Vector2(8, 11), Vector2(2, 6), Color8(240, 210, 70))
					_rect(p + Vector2(11, 11), Vector2(2, 5), Color8(240, 210, 70))
			else:
				# Crates of fruit.
				var fruit := [Color8(220, 50, 45), Color8(245, 150, 40), Color8(120, 190, 70), Color8(240, 210, 70)]
				for k in 2:
					var c: Color = fruit[(v + k) % 4]
					_rect(p + Vector2(2 + k * 8, 12), Vector2(7, 5), Color8(150, 104, 60))
					_rect(p + Vector2(2 + k * 8, 12), Vector2(7, 1), Color8(190, 140, 90))
					for f in 3:
						_rect(p + Vector2(3 + k * 8 + f * 2, 9 + (f % 2)), Vector2(2, 3), c)
		"games":
			if row == 0:
				# A fan of playing cards, or a pair of dice.
				if v % 2 == 0:
					for k in 3:
						_rect(p + Vector2(4 + k * 4, 4 + absi(k - 1)), Vector2(5, 7), Color8(250, 250, 250))
						_rect(p + Vector2(5 + k * 4, 5 + absi(k - 1)), Vector2(2, 2), Color8(220, 40, 40) if k != 1 else Color8(30, 30, 30))
				else:
					for k in 2:
						_rect(p + Vector2(4 + k * 7, 6 + k * 2), Vector2(6, 6), Color8(250, 250, 250) if k == 0 else Color8(220, 40, 40))
						_rect(p + Vector2(6 + k * 7, 8 + k * 2), Vector2(2, 2), Color8(30, 30, 30) if k == 0 else Color8(250, 250, 250))
			else:
				# Stacked game boxes.
				var boxes := [Color8(70, 110, 210), Color8(220, 60, 60), Color8(80, 170, 90), Color8(240, 190, 60)]
				for k in 3:
					var c: Color = boxes[(v + k) % 4]
					_rect(p + Vector2(2 + k, 14 - k * 4), Vector2(15 - k * 2, 4), c)
					_rect(p + Vector2(3 + k, 15 - k * 4), Vector2(5, 1), c.lightened(0.4))
		"bar":
			if row == 0:
				# A glowing OPEN sign in one window, string lights in the others.
				if col == 0:
					_rect(p + Vector2(2, 5), Vector2(16, 7), Color8(40, 20, 30))
					_rect(p + Vector2(3, 6), Vector2(14, 5), Color8(255, 80, 120))
					_rect(p + Vector2(4, 7), Vector2(12, 3), Color8(255, 190, 210))
				else:
					for k in 5:
						_rect(p + Vector2(2 + k * 4 - (k / 4) * 2, 4 + (k % 2) * 2), Vector2(2, 2), Color8(255, 220, 140))
			else:
				# Root beer mugs on the sill, and a little barrel.
				_rect(p + Vector2(2, 9), Vector2(7, 8), Color8(140, 90, 50))
				_rect(p + Vector2(2, 11), Vector2(7, 1), Color8(80, 50, 30))
				_rect(p + Vector2(2, 15), Vector2(7, 1), Color8(80, 50, 30))
				for k in 2:
					_rect(p + Vector2(11 + k * 4, 10), Vector2(3, 7), Color8(150, 80, 30))
					_rect(p + Vector2(11 + k * 4, 10), Vector2(3, 2), Color8(250, 240, 220))
		"empty":
			# Bare, dusty, with a FOR LEASE sheet taped up.
			_rect(p + Vector2(1, 1), Vector2(18, 18), Color(0.85, 0.82, 0.7, 0.18))
			if row == 0 and col % 2 == 0:
				_rect(p + Vector2(4, 4), Vector2(12, 12), Color8(245, 245, 235))
				_rect(p + Vector2(6, 6), Vector2(8, 2), Color8(200, 40, 40))
				for k in 3:
					_rect(p + Vector2(6, 10 + k * 2), Vector2(8 - k * 2, 1), Color8(120, 120, 120))
		"burger":
			if row == 0 or v % 2 == 0:
				# A poster of the burger.
				_rect(p + Vector2(3, 3), Vector2(14, 13), Color8(250, 240, 220))
				_rect(p + Vector2(5, 5), Vector2(10, 3), Color8(220, 160, 80))
				_rect(p + Vector2(5, 8), Vector2(10, 1), Color8(90, 170, 70))
				_rect(p + Vector2(5, 9), Vector2(10, 2), Color8(110, 60, 40))
				_rect(p + Vector2(5, 11), Vector2(10, 2), Color8(220, 160, 80))
			else:
				# Fries and a cup.
				_rect(p + Vector2(4, 9), Vector2(6, 8), Color8(220, 40, 40))
				for k in 4:
					_rect(p + Vector2(4 + k + k / 2, 6 + (k % 2)), Vector2(1, 4), Color8(250, 210, 80))
				_rect(p + Vector2(12, 8), Vector2(5, 9), Color8(250, 250, 250))
				_rect(p + Vector2(12, 11), Vector2(5, 2), Color8(220, 40, 40))
		"surf":
			# Surfboards standing up, and a rack of shirts.
			var boards := [Color8(240, 100, 80), Color8(80, 200, 220), Color8(250, 210, 70), Color8(140, 220, 120)]
			if row == 0:
				for k in 2:
					var c: Color = boards[(v + k) % 4]
					_rect(p + Vector2(4 + k * 7, 3), Vector2(4, 16), c)
					_rect(p + Vector2(5 + k * 7, 3), Vector2(2, 16), c.lightened(0.3))
			else:
				_rect(p + Vector2(2, 3), Vector2(16, 1), Color8(150, 150, 160))
				for k in 3:
					_rect(p + Vector2(3 + k * 5, 4), Vector2(4, 8), boards[(v + k + 1) % 4])
		"taco":
			if row == 0:
				# A string of red chiles, and the menu.
				for k in 4:
					_rect(p + Vector2(3 + k * 4, 3 + k % 2), Vector2(2, 5), Color8(220, 40, 30))
				_rect(p + Vector2(4, 10), Vector2(12, 8), Color8(30, 40, 30))
				for k in 3:
					_rect(p + Vector2(5, 11 + k * 2), Vector2(6 + (k % 2) * 3, 1), Color8(240, 240, 220))
			else:
				# Hot sauce bottles, and tacos on a plate.
				var sauce := [Color8(220, 40, 30), Color8(90, 160, 60), Color8(240, 140, 40)]
				for k in 3:
					_rect(p + Vector2(2 + k * 3, 9), Vector2(2, 8), sauce[k])
				_rect(p + Vector2(11, 14), Vector2(7, 2), Color8(240, 240, 240))
				_rect(p + Vector2(12, 11), Vector2(5, 3), Color8(240, 200, 90))
				_rect(p + Vector2(13, 11), Vector2(3, 1), Color8(90, 170, 70))
		"arcade":
			# Glowing cabinet screens in the dark.
			_rect(p + Vector2(1, 1), Vector2(18, 18), Color8(26, 20, 44))
			var glow := [Color8(80, 220, 240), Color8(250, 90, 200), Color8(250, 220, 80), Color8(120, 240, 120)]
			var sy := 4 if row == 0 else 2
			_rect(p + Vector2(4, sy), Vector2(12, 8), glow[v])
			_rect(p + Vector2(6, sy + 2), Vector2(3, 3), glow[(v + 1) % 4].lightened(0.4))
			if row == 1:
				_rect(p + Vector2(6, 12), Vector2(2, 2), Color8(240, 60, 60))
				_rect(p + Vector2(11, 12), Vector2(2, 2), Color8(80, 120, 240))
		"icecream":
			var scoops := [Color8(250, 160, 200), Color8(250, 240, 220), Color8(140, 90, 60), Color8(150, 220, 150)]
			if row == 0:
				# A giant cone, painted on the glass.
				_rect(p + Vector2(6, 3), Vector2(8, 6), scoops[v])
				for k in 4:
					_rect(p + Vector2(7 + k / 2, 9 + k * 2), Vector2(6 - k, 2), Color8(220, 170, 100))
			else:
				# Tubs in the freezer case.
				_rect(p + Vector2(1, 10), Vector2(18, 8), Color8(200, 220, 230))
				for k in 3:
					_rect(p + Vector2(2 + k * 6, 11), Vector2(5, 3), scoops[(v + k) % 4])
		"diner":
			# Checked curtains, a pie on a stand, a coffee cup.
			for k in 9:
				_rect(p + Vector2(1 + k * 2, 1), Vector2(2, 3), Color8(220, 50, 50) if k % 2 == 0 else Color8(250, 250, 250))
			if col % 4 < 2:
				_rect(p + Vector2(4, 13), Vector2(10, 1), Color8(200, 200, 210))
				_rect(p + Vector2(8, 14), Vector2(2, 3), Color8(200, 200, 210))
				_rect(p + Vector2(5, 10), Vector2(8, 3), Color8(220, 160, 80))
				_rect(p + Vector2(5, 10), Vector2(8, 1), Color8(180, 40, 60))
			else:
				_rect(p + Vector2(7, 11), Vector2(6, 5), Color8(250, 250, 250))
				_rect(p + Vector2(13, 12), Vector2(2, 2), Color8(250, 250, 250))
				_rect(p + Vector2(8, 11), Vector2(4, 1), Color8(110, 70, 40))


func _door(x: int, y: int, p: Vector2) -> void:
	# A door can be several tiles: wide (double doors) and tall. Each tile draws its
	# part: the frame and a window up top, a kick plate and a step at the bottom,
	# the handle at hand height, and the seam between two leaves.
	var wall := _wall_around(x, y)
	var top := _t(x, y - 1) != Room.DOOR
	var bottom := _t(x, y + 1) != Room.DOOR
	var left_edge := _t(x - 1, y) != Room.DOOR
	var right_edge := _t(x + 1, y) != Room.DOOR
	var metal := wall in [Room.BUNKER_WALL, Room.STUCCO, Room.RED_WALL]
	var leaf := Color8(128, 86, 52) if not metal else Color8(96, 106, 118)
	if wall == Room.WOOD_WALL:
		leaf = Color8(150, 104, 62)
	var frame := leaf.darkened(0.45)
	_rect(p, Vector2(T, T), leaf)
	# Frame around the outside of the whole doorway.
	if top:
		_rect(p, Vector2(T, 2), frame)
	if left_edge:
		_rect(p, Vector2(2, T), frame)
	if right_edge:
		_rect(p + Vector2(T - 2, 0), Vector2(2, T), frame)
	# Wood grain or brushed metal down the leaf.
	for k in 3:
		_rect(p + Vector2(4 + k * 5, 2 if top else 0), Vector2(1, T - (2 if top else 0)), leaf.darkened(0.08) if not metal else leaf.lightened(0.06))
	# The upper part: a window (glass, with a highlight).
	if top:
		var glass := Rect2(p + Vector2(4 if left_edge else 2, 4), Vector2(T - (4 if left_edge else 2) - (4 if right_edge else 2), 8 if bottom else 12))
		_rect(glass.position - Vector2(1, 1), glass.size + Vector2(2, 2), frame)
		for k in int(glass.size.y):
			_rect(glass.position + Vector2(0, k), Vector2(glass.size.x, 1), Color8(150, 192, 226).lerp(Color8(94, 132, 176), k / maxf(glass.size.y - 1, 1)))
		ci.draw_line(glass.position + Vector2(1, glass.size.y - 2), glass.position + Vector2(glass.size.x * 0.6, 1), Color(1, 1, 1, 0.35), 1.0)
	# The lower part: a kick plate and the step.
	if bottom:
		_rect(p + Vector2(0, T - 6), Vector2(T, 3), leaf.darkened(0.2) if not metal else Color8(170, 174, 182))
		_rect(p + Vector2(0, T - 3), Vector2(T, 3), Color8(156, 152, 146))
		_rect(p + Vector2(0, T - 3), Vector2(T, 1), Color8(186, 182, 176))
	# The seam between double doors, and the handles beside it.
	# (The handle is on the bottom tile: near its top if the door is taller than
	# one tile, so it ends up at hand height.)
	var handle_y := 11 if top else 2
	var has_handle := bottom
	var handle := Color8(232, 200, 92) if not metal else Color8(210, 214, 222)
	if not right_edge:
		_rect(p + Vector2(T - 1, 0), Vector2(1, T), frame)
		if has_handle:
			_rect(p + Vector2(T - 4, handle_y), Vector2(2, 4), handle)
	elif not left_edge:
		_rect(p, Vector2(1, T), frame)
		if has_handle:
			_rect(p + Vector2(2, handle_y), Vector2(2, 4), handle)
	elif has_handle:
		_rect(p + Vector2(T - 5, handle_y + 1), Vector2(2, 2), handle)


func _gate(x: int, y: int, p: Vector2) -> void:
	# A chain-link gate, chained shut with a padlock.
	_sidewalk(x, y, p)
	_rect(p + Vector2(1, 0), Vector2(2, T), Color8(130, 130, 138))
	_rect(p + Vector2(17, 0), Vector2(2, T), Color8(130, 130, 138))
	for i in 5:
		ci.draw_line(p + Vector2(3 + i * 4, 0), p + Vector2(i * 4 - 1, T), Color8(150, 150, 160), 1.0)
		ci.draw_line(p + Vector2(i * 4 - 1, 0), p + Vector2(3 + i * 4, T), Color8(120, 120, 130), 1.0)
	ci.draw_line(p + Vector2(0, 8), p + Vector2(T, 12), Color8(80, 80, 86), 2.0)
	if y % 2 == 1:
		_rect(p + Vector2(7, 7), Vector2(6, 6), Color8(215, 180, 60))
		_rect(p + Vector2(7, 7), Vector2(6, 1), Color8(240, 210, 100))
		_rect(p + Vector2(9, 9), Vector2(2, 2), Color8(80, 60, 20))


func _bleachers(x: int, y: int, p: Vector2) -> void:
	# Aluminum benches, row on row, with the gap between them in shadow.
	_rect(p, Vector2(T, T), Color8(84, 86, 96))
	for row in 2:
		var at := p + Vector2(0, row * 10)
		_rect(at, Vector2(T, 6), Color8(162, 164, 174))
		_rect(at, Vector2(T, 1), Color8(200, 202, 210))
		_rect(at + Vector2(0, 5), Vector2(T, 1), Color8(118, 120, 130))
		if x % 3 == 0:
			_rect(at + Vector2(2, 2), Vector2(1, 1), Color8(110, 112, 120))
	# Something left behind on a seat now and then.
	if _h(x, y, 75) % 23 == 0:
		_rect(p + Vector2(8, 2), Vector2(4, 3), [Color8(220, 60, 60), Color8(240, 220, 120), Color8(70, 130, 210)][_h(x, y, 76) % 3])


# --- Indoors ---------------------------------------------------------------------------

func _interior_wall(x: int, y: int, p: Vector2) -> void:
	# Painted cinderblock: blocks, a chair rail, and a darker wainscot below it.
	var paint := Color8(198, 192, 172)
	_rect(p, Vector2(T, T), paint)
	_rect(p + Vector2(0, 9), Vector2(T, 1), paint.darkened(0.08))
	_rect(p + Vector2(10 if y % 2 == 0 else 0, 0), Vector2(1, 9), paint.darkened(0.08))
	_dots(x, y, 77, p, 3, paint.darkened(0.05))
	if not _t(x, y + 1) in FACADE:
		_rect(p + Vector2(0, 11), Vector2(T, 2), Color8(150, 140, 120))
		_rect(p + Vector2(0, 13), Vector2(T, 7), Color8(120, 110, 94))
		_rect(p + Vector2(0, 13), Vector2(T, 1), Color8(138, 128, 110))
		_rect(p + Vector2(0, T - 1), Vector2(T, 1), Color8(80, 72, 60))
	if not _t(x, y - 1) in FACADE:
		_rect(p, Vector2(T, 2), paint.lightened(0.1))


func _hall_floor(x: int, y: int, p: Vector2) -> void:
	# Speckled vinyl tiles, checkered, with a shine from the ceiling lights.
	var light := (x + y) % 2 == 0
	var base := Color8(208, 208, 198) if light else Color8(186, 186, 178)
	_rect(p, Vector2(T, T), base)
	_dots(x, y, 78, p, 6, base.darkened(0.14))
	_dots(x, y, 79, p, 3, Color8(120, 140, 160).lerp(base, 0.6))
	_rect(p, Vector2(T, 1), base.darkened(0.08))
	_rect(p, Vector2(1, T), base.darkened(0.08))
	if (x + y * 3) % 7 == 0:
		_rect(p + Vector2(4, 3), Vector2(6, 1), Color(1, 1, 1, 0.35))
		_rect(p + Vector2(3, 4), Vector2(3, 1), Color(1, 1, 1, 0.2))
	if _h(x, y, 80) % 15 == 0:
		ci.draw_line(p + Vector2(4, 12), p + Vector2(12, 14), Color8(140, 140, 136), 1.0)


func _locker(x: int, y: int, p: Vector2) -> void:
	var tone := Color8(70, 96, 132).lerp(Color8(64, 88, 124), _f(x, y, 81))
	_rect(p, Vector2(T, T), tone)
	_rect(p, Vector2(1, T), Color8(40, 56, 82))
	_rect(p + Vector2(1, 0), Vector2(1, T), tone.lightened(0.15))
	# Vents, a number plate, a handle and a little lock.
	for k in 3:
		_rect(p + Vector2(5, 3 + k * 2), Vector2(10, 1), Color8(38, 52, 78))
	_rect(p + Vector2(7, 10), Vector2(6, 3), Color8(200, 200, 196))
	_rect(p + Vector2(8, 11), Vector2(1, 1), Color8(60, 60, 64))
	_rect(p + Vector2(10, 11), Vector2(2, 1), Color8(60, 60, 64))
	_rect(p + Vector2(15, 11), Vector2(2, 4), Color8(196, 198, 204))
	_rect(p + Vector2(15, 15), Vector2(2, 1), Color8(120, 122, 128))
	if _h(x, y, 82) % 4 == 0:
		_rect(p + Vector2(14, 15), Vector2(3, 3), Color8(60, 60, 66))
		_rect(p + Vector2(15, 14), Vector2(1, 1), Color8(150, 150, 156))
	# A sticker or a dent on a few.
	if _h(x, y, 83) % 9 == 0:
		_rect(p + Vector2(4, 15), Vector2(4, 3), [Color8(230, 80, 80), Color8(240, 210, 80), Color8(120, 210, 120)][_h(x, y, 84) % 3])
	_rect(p + Vector2(0, T - 1), Vector2(T, 1), Color8(36, 48, 70))


func _chalkboard(x: int, y: int, p: Vector2) -> void:
	_rect(p, Vector2(T, T), Color8(126, 92, 60))
	_rect(p + Vector2(0, 2), Vector2(T, 14), Color8(40, 74, 56))
	_rect(p + Vector2(0, 2), Vector2(T, 1), Color8(30, 58, 42))
	# Old erasing, smeared across it.
	_rect(p + Vector2(_h(x, y, 85) % 8, 5), Vector2(10, 4), Color8(58, 92, 72))
	# Writing: short scribbles.
	if (x + y) % 2 == 0:
		ci.draw_line(p + Vector2(3, 7), p + Vector2(9, 6), Color8(222, 226, 216), 1.0)
		ci.draw_line(p + Vector2(10, 7), p + Vector2(16, 7), Color8(222, 226, 216), 1.0)
		ci.draw_line(p + Vector2(4, 11), p + Vector2(12, 10), Color8(200, 206, 196), 1.0)
	# The chalk tray, with a stub of chalk.
	_rect(p + Vector2(0, 16), Vector2(T, 2), Color8(150, 112, 74))
	if _h(x, y, 86) % 3 == 0:
		_rect(p + Vector2(4 + _h(x, y, 87) % 10, 15), Vector2(3, 1), Color8(244, 244, 236))


func _desk(x: int, y: int, p: Vector2) -> void:
	_hall_floor(x, y, p)
	# A desk with a chair tucked under it, and something on top.
	_rect(p + Vector2(2, 15), Vector2(16, 3), Color(0, 0, 0, 0.18))
	_rect(p + Vector2(2, 3), Vector2(16, 9), Color8(172, 128, 82))
	_rect(p + Vector2(2, 3), Vector2(16, 1), Color8(198, 154, 106))
	_rect(p + Vector2(2, 11), Vector2(16, 1), Color8(132, 94, 58))
	_rect(p + Vector2(3, 12), Vector2(1, 4), Color8(90, 90, 98))
	_rect(p + Vector2(16, 12), Vector2(1, 4), Color8(90, 90, 98))
	_rect(p + Vector2(6, 13), Vector2(8, 4), Color8(60, 90, 140))
	_rect(p + Vector2(6, 13), Vector2(8, 1), Color8(80, 114, 166))
	match _h(x, y, 88) % 4:
		0: _rect(p + Vector2(5, 5), Vector2(6, 4), Color8(240, 238, 228))
		1:
			_rect(p + Vector2(10, 5), Vector2(5, 4), Color8(200, 60, 60))
			_rect(p + Vector2(10, 5), Vector2(1, 4), Color8(150, 40, 40))
		2: _rect(p + Vector2(4, 6), Vector2(7, 1), Color8(240, 200, 60))


func _gym_floor(x: int, y: int, p: Vector2, line: bool) -> void:
	# Varnished maple: long boards, staggered, with a shine.
	for row in 4:
		var tone := _f(x + (row * 7), y * 4 + row, 89)
		var c := Color8(216, 170, 110).lerp(Color8(200, 154, 96), tone)
		_rect(p + Vector2(0, row * 5), Vector2(T, 5), c)
		_rect(p + Vector2(0, row * 5 + 4), Vector2(T, 1), Color8(176, 132, 82))
		_rect(p + Vector2((x * 7 + row * 9) % T, row * 5), Vector2(1, 4), Color8(176, 132, 82))
	if (x * 3 + y) % 5 == 0:
		_rect(p + Vector2(3, 6), Vector2(9, 1), Color(1, 1, 1, 0.25))
	if line:
		_rect(p + Vector2(9, 0), Vector2(2, T), Color8(248, 248, 244))


func _house_floor(x: int, y: int, p: Vector2) -> void:
	for row in 4:
		var tone := _f(x, y * 4 + row, 90)
		var c := Color8(152, 108, 72).lerp(Color8(138, 96, 62), tone)
		_rect(p + Vector2(0, row * 5), Vector2(T, 5), c)
		_rect(p + Vector2(0, row * 5), Vector2(T, 1), c.lightened(0.08))
		_rect(p + Vector2(0, row * 5 + 4), Vector2(T, 1), Color8(112, 76, 48))
		_rect(p + Vector2((_h(x, y, 91 + row) % 3) * 6 + 2, row * 5), Vector2(1, 4), Color8(112, 76, 48))
		_rect(p + Vector2(_h(x, y, 95 + row) % 14, row * 5 + 2), Vector2(5, 1), c.darkened(0.08))


func _house_wall(x: int, y: int, p: Vector2) -> void:
	# Faded wallpaper: stripes, with a tiny pattern between them.
	var paper := Color8(134, 152, 140)
	_rect(p, Vector2(T, T), paper)
	for stripe in 3:
		_rect(p + Vector2(stripe * 7 + 2, 0), Vector2(1, T), paper.darkened(0.1))
		_rect(p + Vector2(stripe * 7 + 5, (stripe * 6 + y * 3) % 16 + 2), Vector2(1, 1), Color8(196, 170, 120))
	if not _t(x, y - 1) in FACADE:
		_rect(p, Vector2(T, 2), Color8(176, 156, 120))
	if not _t(x, y + 1) in FACADE:
		_rect(p + Vector2(0, 14), Vector2(T, 6), Color8(100, 72, 52))
		_rect(p + Vector2(0, 14), Vector2(T, 1), Color8(130, 98, 72))


func _bunker_floor(x: int, y: int, p: Vector2) -> void:
	var base := Color8(96, 97, 100).lerp(Color8(90, 91, 95), _patch(x, y, 100))
	_rect(p, Vector2(T, T), base)
	if x % 3 == 0:
		_rect(p, Vector2(1, T), Color8(78, 79, 83))
	if y % 3 == 0:
		_rect(p, Vector2(T, 1), Color8(78, 79, 83))
	_dots(x, y, 101, p, 6, base.darkened(0.1))
	_dots(x, y, 102, p, 3, base.lightened(0.08))
	if _h(x, y, 103) % 19 == 0:
		ci.draw_line(p + Vector2(3, 5), p + Vector2(9, 11), Color8(68, 68, 72), 1.0)
		ci.draw_line(p + Vector2(9, 11), p + Vector2(15, 12), Color8(68, 68, 72), 1.0)
	# An old oil stain.
	if _h(x, y, 104) % 37 == 0:
		ci.draw_set_transform(p + Vector2(10, 10), 0.0, Vector2(1.0, 0.6))
		ci.draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.12))
		ci.draw_set_transform(Vector2.ZERO)


func _bunker_wall(x: int, y: int, p: Vector2) -> void:
	var base := Color8(74, 76, 82)
	_rect(p, Vector2(T, T), base)
	for row in 2:
		var offset := 10 if (y + row) % 2 == 0 else 0
		var tone := _f(x, y * 2 + row, 105)
		_rect(p + Vector2(0, row * 10), Vector2(T, 9), base.lerp(base.lightened(0.07), tone))
		_rect(p + Vector2(0, row * 10 + 9), Vector2(T, 1), Color8(56, 58, 63))
		_rect(p + Vector2(offset, row * 10), Vector2(1, 9), Color8(56, 58, 63))
	# Damp streaks running down from the ceiling.
	if _h(x, y, 106) % 7 == 0:
		_rect(p + Vector2(4 + _h(x, y, 107) % 12, 0), Vector2(1, 6 + _h(x, y, 108) % 10), Color(0, 0, 0, 0.18))
	_rect(p, Vector2(T, 1), Color8(92, 94, 100))
	if _t(x, y + 1) != Room.BUNKER_WALL and _t(x, y + 1) != Room.BUNKER_DOOR:
		_rect(p + Vector2(0, 15), Vector2(T, 5), Color8(52, 54, 58))
		_rect(p + Vector2(0, 15), Vector2(T, 1), Color8(66, 68, 74))


func _bunker_door(x: int, y: int, p: Vector2) -> void:
	_rect(p, Vector2(T, T), Color8(112, 118, 126))
	_rect(p + Vector2(2, 2), Vector2(T - 4, T - 4), Color8(98, 104, 112))
	_rect(p + Vector2(2, 2), Vector2(T - 4, 1), Color8(130, 136, 144))
	for rivet in [Vector2(3, 3), Vector2(16, 3), Vector2(3, 16), Vector2(16, 16)]:
		_rect(p + rivet, Vector2(1, 1), Color8(156, 162, 170))
	# Rust around the edges.
	_dots(x, y, 109, p, 3, Color8(132, 82, 54))
	if _t(x + 1, y) == Room.BUNKER_DOOR:
		ci.draw_arc(p + Vector2(15, 10), 4.0, 0.0, TAU, 12, Color8(60, 64, 70), 1.5)
		ci.draw_line(p + Vector2(11, 10), p + Vector2(19, 10), Color8(60, 64, 70), 1.0)
		ci.draw_line(p + Vector2(15, 6), p + Vector2(15, 14), Color8(60, 64, 70), 1.0)
	_rect(p, Vector2(1, T), Color8(60, 64, 70))
	# A yellow-and-black hazard stripe along the bottom.
	for k in 5:
		_rect(p + Vector2(k * 4, T - 2), Vector2(2, 2), Color8(214, 180, 50))
		_rect(p + Vector2(k * 4 + 2, T - 2), Vector2(2, 2), Color8(40, 40, 40))


## Arcade carpet: dark blue, with the neon confetti pattern that glows under
## black lights.
func _arcade_carpet(x: int, y: int, p: Vector2) -> void:
	_rect(p, Vector2(T, T), Color8(26, 22, 52))
	var neon := [Color8(80, 230, 250), Color8(250, 90, 200), Color8(250, 230, 80), Color8(120, 250, 120)]
	for i in 6:
		var h := _h(x, y, 700 + i)
		var at := p + Vector2(h % 17, (h / 17) % 17)
		var c: Color = neon[(h / 7) % 4]
		match i % 3:
			0: _rect(at, Vector2(3, 1), c)
			1: _rect(at, Vector2(1, 3), c)
			_: _rect(at, Vector2(2, 2), c)


# --- Pass 2: tall things ---------------------------------------------------------------

func tall(x: int, y: int, tile: int) -> void:
	var p := Vector2(x * T, y * T)
	match tile:
		Room.TREE: _tree(x, y, p)
		Room.PALM: _palm(x, y, p)
		Room.STUMP: _stump(x, y, p)
		Room.FENCE: _fence(x, y, p)
		Room.BENCH: _bench(x, y, p)
		Room.PLANTER: _planter(x, y, p)
		Room.TABLE: _umbrella_table(x, y, p)


func _tree(x: int, y: int, p: Vector2) -> void:
	# Some areas have their own kind of tree (Room meta "tree_style").
	if room.get_meta("tree_style", "") == "torrey":
		Scenery.torrey_pine(ci, p + Vector2(8, 19), 0.62 + _f(x, y, 114) * 0.15)
		return
	# Three kinds of green, picked per tree, so a row of trees isn't a row of copies.
	var palettes := [
		[Color8(30, 80, 40), Color8(40, 100, 48), Color8(58, 126, 60), Color8(92, 160, 82)],
		[Color8(28, 72, 44), Color8(36, 92, 54), Color8(50, 116, 66), Color8(84, 150, 92)],
		[Color8(44, 86, 36), Color8(58, 108, 44), Color8(80, 132, 54), Color8(128, 170, 76)],
	]
	var pal: Array = palettes[_h(x, y, 110) % 3]
	var c := p + Vector2(10 + (_h(x, y, 111) % 3) - 1, 5)
	var big := 1.0 + _f(x, y, 112) * 0.15
	# The trunk, with bark and roots.
	_rect(p + Vector2(8, 10), Vector2(4, 9), Color8(104, 72, 42))
	_rect(p + Vector2(8, 10), Vector2(1, 9), Color8(78, 52, 30))
	_rect(p + Vector2(11, 12), Vector2(1, 6), Color8(128, 92, 56))
	_rect(p + Vector2(6, 17), Vector2(8, 2), Color8(92, 62, 36))
	# The crown: a dark mass, then lit clusters toward the top-left.
	ci.draw_circle(c + Vector2(1, 2), 10.0 * big, pal[0])
	for k in 5:
		var a := k * TAU / 5.0 + _f(x, y, 113) * 2.0
		ci.draw_circle(c + Vector2(cos(a) * 5.0, sin(a) * 4.0) * big, 5.5 * big, pal[1])
	ci.draw_circle(c + Vector2(-2, -2), 6.0 * big, pal[2])
	ci.draw_circle(c + Vector2(3, -3), 4.0 * big, pal[2])
	ci.draw_circle(c + Vector2(-4, -4), 3.0 * big, pal[3])
	ci.draw_circle(c + Vector2(1, -6), 2.5 * big, pal[3])
	# Leaves: scattered light and dark pixels across the crown.
	for i in 10:
		var h := _h(x, y, 120 + i)
		var at := c + Vector2(float(h % 17) - 8.0, float((h / 17) % 15) - 8.0) * big
		_rect(at, Vector2(1, 1), pal[3] if i % 2 == 0 else pal[0])
	# A bird's nest or some blossoms, once in a while.
	if _h(x, y, 131) % 17 == 0:
		for k in 4:
			var at := c + Vector2(float(_h(x, y, 132 + k) % 12) - 6.0, float(_h(x, y, 136 + k) % 10) - 6.0)
			_rect(at, Vector2(2, 2), Color8(240, 190, 210))


func _palm(x: int, y: int, p: Vector2) -> void:
	# A curved trunk in rings, a crown of fronds, and coconuts.
	var lean := 1.0 if _h(x, y, 140) % 2 == 0 else -1.0
	var base := p + Vector2(10, 18)
	var top := base + Vector2(3.0 * lean, -16)
	for k in 8:
		var t := k / 7.0
		var at := base.lerp(top, t) + Vector2(sin(t * PI) * 2.0 * lean, 0)
		_rect(at - Vector2(2, 1), Vector2(4, 3), Color8(150, 112, 66) if k % 2 == 0 else Color8(126, 92, 52))
		_rect(at - Vector2(2, 1), Vector2(1, 3), Color8(104, 74, 42))
	var crown := top + Vector2(0, -1)
	var dark := Color8(36, 110, 52)
	var light := Color8(76, 156, 70)
	for i in 7:
		var a := -PI / 2 + (i - 3) * 0.55 + (PI if i == 3 and false else 0.0)
		var dir := Vector2.from_angle(a)
		var droop := Vector2(0, absf(i - 3) * 1.6)
		var tip := crown + dir * 11.0 + droop
		ci.draw_line(crown, tip, dark, 2.0)
		# Leaflets along the frond.
		for k in 4:
			var at := crown.lerp(tip, 0.3 + k * 0.18)
			var side := dir.orthogonal() * 2.5
			ci.draw_line(at, at + side + Vector2(0, 1.5), light, 1.0)
			ci.draw_line(at, at - side + Vector2(0, 1.5), dark, 1.0)
	for k in 3:
		ci.draw_circle(crown + Vector2(-2 + k * 2, 2), 1.5, Color8(110, 74, 40))


func _stump(x: int, y: int, p: Vector2) -> void:
	# What's left of a tree: charred, split at the top, still smoldering inside.
	_rect(p + Vector2(6, 8), Vector2(8, 10), Color8(40, 28, 20))
	_rect(p + Vector2(6, 8), Vector2(2, 10), Color8(62, 46, 34))
	_rect(p + Vector2(12, 9), Vector2(1, 8), Color8(26, 18, 12))
	ci.draw_colored_polygon(PackedVector2Array([p + Vector2(6, 8), p + Vector2(8, 3), p + Vector2(10, 7), p + Vector2(12, 4), p + Vector2(14, 8)]), Color8(30, 20, 15))
	_rect(p + Vector2(8, 9), Vector2(4, 2), Color8(130, 62, 30))
	_rect(p + Vector2(9, 9), Vector2(2, 1), Color8(220, 110, 50))
	# Roots, and charcoal flakes around it.
	_rect(p + Vector2(4, 17), Vector2(3, 1), Color8(36, 26, 18))
	_rect(p + Vector2(13, 17), Vector2(4, 1), Color8(36, 26, 18))


func _fence(x: int, y: int, p: Vector2) -> void:
	# Metal rail fence: posts with caps, two rails, a shadow under the rails.
	var post := Color8(126, 128, 138)
	var rail := Color8(164, 166, 176)
	var linked_left := _t(x - 1, y) == Room.FENCE
	var linked_right := _t(x + 1, y) == Room.FENCE
	var vertical := not linked_left and not linked_right and (_t(x, y - 1) == Room.FENCE or _t(x, y + 1) == Room.FENCE)
	if vertical:
		_rect(p + Vector2(8, 0), Vector2(2, T), rail)
		_rect(p + Vector2(12, 0), Vector2(2, T), rail.darkened(0.1))
		_rect(p + Vector2(7, 2), Vector2(8, 3), post)
		_rect(p + Vector2(7, 2), Vector2(8, 1), post.lightened(0.2))
		return
	for ry in [5, 12]:
		_rect(p + Vector2(0, ry + 2), Vector2(T, 1), Color(0, 0, 0, 0.15))
		_rect(p + Vector2(0, ry), Vector2(T, 2), rail)
		_rect(p + Vector2(0, ry), Vector2(T, 1), rail.lightened(0.2))
	for px in [2, 12]:
		_rect(p + Vector2(px, 2), Vector2(3, 16), post)
		_rect(p + Vector2(px, 2), Vector2(1, 16), post.lightened(0.15))
		_rect(p + Vector2(px - 1, 1), Vector2(5, 2), post.lightened(0.25))
		_rect(p + Vector2(px - 1, 18), Vector2(5, 1), Color(0, 0, 0, 0.2))


func _bench(x: int, y: int, p: Vector2) -> void:
	# A park bench: slats, a backrest, iron legs and armrests.
	var wood := Color8(146, 98, 58)
	var iron := Color8(58, 58, 64)
	var left_end := _t(x - 1, y) != Room.BENCH
	var right_end := _t(x + 1, y) != Room.BENCH
	_rect(p + Vector2(0, 16), Vector2(T, 2), Color(0, 0, 0, 0.18))
	for k in 2:
		_rect(p + Vector2(0, 3 + k * 3), Vector2(T, 2), wood.darkened(0.08))
		_rect(p + Vector2(0, 3 + k * 3), Vector2(T, 1), wood.lightened(0.12))
	for k in 3:
		_rect(p + Vector2(0, 10 + k * 2), Vector2(T, 2), wood if k % 2 == 0 else wood.darkened(0.06))
	_rect(p + Vector2(0, 10), Vector2(T, 1), wood.lightened(0.15))
	if left_end:
		_rect(p + Vector2(1, 2), Vector2(2, 16), iron)
		_rect(p + Vector2(1, 9), Vector2(4, 2), iron.lightened(0.2))
	if right_end:
		_rect(p + Vector2(17, 2), Vector2(2, 16), iron)
		_rect(p + Vector2(15, 9), Vector2(4, 2), iron.lightened(0.2))


func _planter(x: int, y: int, p: Vector2) -> void:
	# A wooden planter box, soil, and a shrub with a few flowers.
	_rect(p + Vector2(1, 10), Vector2(18, 9), Color8(122, 88, 58))
	_rect(p + Vector2(1, 10), Vector2(18, 1), Color8(150, 112, 76))
	_rect(p + Vector2(1, 14), Vector2(18, 1), Color8(100, 70, 46))
	_rect(p + Vector2(1, 18), Vector2(18, 1), Color8(80, 56, 36))
	_rect(p + Vector2(3, 9), Vector2(14, 2), Color8(70, 50, 34))
	ci.draw_circle(p + Vector2(10, 7), 7.0, Color8(40, 100, 48))
	ci.draw_circle(p + Vector2(6, 6), 4.0, Color8(52, 120, 56))
	ci.draw_circle(p + Vector2(13, 5), 4.0, Color8(56, 126, 60))
	ci.draw_circle(p + Vector2(8, 3), 2.5, Color8(86, 156, 78))
	var flower: Color = [Color8(240, 120, 150), Color8(250, 220, 90), Color8(250, 250, 250), Color8(200, 120, 230)][_h(x, y, 150) % 4]
	for k in 4:
		var h := _h(x, y, 151 + k)
		_rect(p + Vector2(4 + h % 12, 2 + (h / 12) % 7), Vector2(2, 2), flower)


func _umbrella_table(x: int, y: int, p: Vector2) -> void:
	# A round table under a striped umbrella (seen from above).
	var colors := [[Color8(40, 120, 76), Color8(236, 236, 226)], [Color8(200, 60, 56), Color8(240, 230, 200)], [Color8(40, 90, 170), Color8(240, 240, 240)]]
	var pair: Array = colors[_h(x, y, 160) % 3]
	ci.draw_set_transform(p + Vector2(11, 13), 0.0, Vector2(1.0, 0.5))
	ci.draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.2))
	ci.draw_set_transform(Vector2.ZERO)
	for k in 8:
		var a := k * TAU / 8.0
		var pts := PackedVector2Array([p + Vector2(10, 9), p + Vector2(10, 9) + Vector2.from_angle(a) * 10.0, p + Vector2(10, 9) + Vector2.from_angle(a + TAU / 8.0) * 10.0])
		ci.draw_colored_polygon(pts, pair[k % 2])
	ci.draw_arc(p + Vector2(10, 9), 10.0, 0, TAU, 24, Color(0, 0, 0, 0.25), 1.0)
	ci.draw_circle(p + Vector2(10, 9), 1.5, Color8(80, 80, 86))
