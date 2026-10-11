class_name Room
extends Node2D
## A map made of 20 x 20 pixel tiles. Each tile type is drawn as simple pixel art,
## and solid tiles (walls, trees, fences...) get collision so the player can't walk through.
##
## Build a map with set_tile() / fill(), then call build().

const TILE := 20

enum { GRASS, SIDEWALK, ASPHALT, PARKING_LINE, WALL, WINDOW, DOOR, TREE, FENCE,
	FIELD, FIELD_LINE, BLEACHERS, BENCH, ROAD, ROAD_LINE, DIRT, ROOF,
	STUCCO, GLASS, PLANTER, PATIO, TABLE, PALM, WOOD_WALL, RED_WALL,
	VOID, INTERIOR_WALL, HALL_FLOOR, LOCKER, CHALKBOARD, DESK, GYM_FLOOR, GYM_LINE, GATE,
	BUNKER_FLOOR, BUNKER_WALL, BUNKER_DOOR, PROP, SCORCHED, STUMP,
	HOUSE_FLOOR, HOUSE_WALL, HOUSE_PROP, SAND, WATER, BOARDWALK, ADOBE, CLAY_ROOF,
	ARCADE_CARPET }

## Tiles the player can't walk through.
const SOLID := [WALL, WINDOW, DOOR, TREE, FENCE, BLEACHERS, BENCH, ROOF,
	STUCCO, GLASS, PLANTER, TABLE, PALM, WOOD_WALL, RED_WALL,
	VOID, INTERIOR_WALL, LOCKER, CHALKBOARD, DESK, GATE,
	BUNKER_WALL, BUNKER_DOOR, PROP, STUMP, HOUSE_WALL, HOUSE_PROP, WATER, ADOBE, CLAY_ROOF]

var width: int = 0
var height: int = 0
var _tiles := PackedInt32Array()
var _walls: StaticBody2D
## The map is baked in CHUNK x CHUNK tile pieces: each piece is drawn just once
## (tiles, then wall shadows, then the ground details) into its own little
## viewport, and shown as a picture after that. Drawing thousands of tiles every
## frame was the slowest thing in the game; a picture costs almost nothing, and
## pieces off screen are skipped. (A margin around each piece keeps tree tops and
## shadows that hang over the edge.) Pieces that are all VOID are just black.
const CHUNK := 16
const BAKE_MARGIN := 24
var _chunks: Array[Node] = []
## The ground details (ground_details.gd), baked in with the tiles.
var details: GroundDetails
## What the tile drawing draws onto (the chunk being drawn).
var _ci: CanvasItem = self
## How each kind of tile looks (tile_art.gd).
var _art: TileArt


func setup(map_width: int, map_height: int, fill_tile: int) -> void:
	width = map_width
	height = map_height
	_tiles.resize(width * height)
	_tiles.fill(fill_tile)


func set_tile(x: int, y: int, tile: int) -> void:
	if x >= 0 and y >= 0 and x < width and y < height:
		_tiles[y * width + x] = tile


## Whether someone could stand with their feet at `at` (pixels) without being
## inside a solid tile.
func is_free(at: Vector2) -> bool:
	for corner in [Vector2(-6, -8), Vector2(6, -8), Vector2(-6, 0), Vector2(6, 0)]:
		var p: Vector2 = at + corner
		if get_tile(floori(p.x / TILE), floori(p.y / TILE)) in SOLID:
			return false
	return true


## The nearest spot to `at` where someone can stand (`at` itself if it's clear).
func free_spot_near(at: Vector2) -> Vector2:
	if is_free(at):
		return at
	for radius in range(1, 8):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var spot := at + Vector2(dx, dy) * (TILE / 2.0)
				if is_free(spot):
					return spot
	return at


func get_tile(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= width or y >= height:
		return WALL
	return _tiles[y * width + x]


## Fills a rectangle of tiles: `w` wide and `h` tall, starting at tile (x, y).
func fill(x: int, y: int, w: int, h: int, tile: int) -> void:
	for ty in range(y, y + h):
		for tx in range(x, x + w):
			set_tile(tx, ty, tile)


## The map's size in pixels.
func pixel_size() -> Vector2:
	return Vector2(width, height) * TILE


## The center of tile (x, y) in pixels.
static func tile_center(x: int, y: int) -> Vector2:
	return Vector2(x * TILE + TILE / 2, y * TILE + TILE / 2)


## Call after setting tiles: draws the map and creates the walls.
func build() -> void:
	_build_chunks()
	_build_collision()


func _build_collision() -> void:
	# Rebuilding (after a gate opens, say) replaces the old walls.
	if _walls:
		_walls.queue_free()
	var body := StaticBody2D.new()
	_walls = body
	add_child(body)

	# One wide box per row of touching solid tiles keeps the number of shapes small.
	for y in height:
		var x := 0
		while x < width:
			if get_tile(x, y) in SOLID:
				var start := x
				while x < width and get_tile(x, y) in SOLID:
					x += 1
				_add_box(body, Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE))
			else:
				x += 1

	# Invisible walls around the edge of the map.
	var size := pixel_size()
	_add_box(body, Rect2(-TILE, -TILE, size.x + TILE * 2, TILE))
	_add_box(body, Rect2(-TILE, size.y, size.x + TILE * 2, TILE))
	_add_box(body, Rect2(-TILE, 0, TILE, size.y))
	_add_box(body, Rect2(size.x, 0, TILE, size.y))


func _add_box(body: StaticBody2D, rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = rect.get_center()
	body.add_child(collision)


# --- Drawing --------------------------------------------------------------

func _build_chunks() -> void:
	for chunk in _chunks:
		chunk.queue_free()
	_chunks.clear()
	for cy in ceili(height / float(CHUNK)):
		for cx in ceili(width / float(CHUNK)):
			var area := Rect2i(cx * CHUNK, cy * CHUNK, mini(CHUNK, width - cx * CHUNK), mini(CHUNK, height - cy * CHUNK))
			var origin := Vector2(area.position * TILE)
			if _all_void(area):
				var black := ColorRect.new()
				black.color = Color.BLACK
				black.position = origin
				black.size = Vector2(area.size * TILE)
				black.mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(black)
				_chunks.append(black)
				continue
			var view := SubViewport.new()
			view.size = area.size * TILE + Vector2i.ONE * BAKE_MARGIN * 2
			view.transparent_bg = true
			view.disable_3d = true
			view.render_target_update_mode = SubViewport.UPDATE_ONCE
			var painter := Node2D.new()
			painter.position = -origin + Vector2.ONE * BAKE_MARGIN
			painter.draw.connect(_draw_chunk.bind(painter, area))
			view.add_child(painter)
			var picture := Sprite2D.new()
			picture.centered = false
			picture.position = origin - Vector2.ONE * BAKE_MARGIN
			picture.add_child(view)
			picture.texture = view.get_texture()
			add_child(picture)
			_chunks.append(picture)


func _draw_chunk(painter: Node2D, area: Rect2i) -> void:
	if _art == null:
		_art = TileArt.new(self)
	_art.ci = painter
	_ci = painter
	# The ground, the shadows walls cast on it, and the little things lying on it...
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			_art.ground(x, y, get_tile(x, y))
	_draw_wall_shadows(area)
	_ci = self
	if details:
		details.draw_area(painter, area)
	# ...then everything that stands up out of it, top row first, so trees further
	# down overlap the ones behind them. (One tile past the edge too: a tree just
	# outside this piece can still hang over into it.)
	for y in range(area.position.y - 1, area.end.y + 1):
		for x in range(area.position.x - 1, area.end.x + 1):
			var tile := get_tile(x, y)
			if tile in TileArt.TALL:
				_art.tall(x, y, tile)


func _all_void(area: Rect2i) -> bool:
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if get_tile(x, y) != VOID:
				return false
	return true


## Tiles that cast a shadow onto the ground below them (buildings, walls, lockers...).
const SHADOW_CASTERS := [WALL, WINDOW, DOOR, STUCCO, GLASS, WOOD_WALL, RED_WALL,
	INTERIOR_WALL, LOCKER, CHALKBOARD, BLEACHERS, BUNKER_WALL, BUNKER_DOOR, HOUSE_WALL]


## A soft shadow along the ground at the foot of every wall, and a thinner one
## down the right side of buildings (the light comes from the top-left).
func _draw_wall_shadows(area: Rect2i) -> void:
	for y in range(area.position.y - 1, area.end.y):
		for x in range(area.position.x - 1, area.end.x):
			var tile := get_tile(x, y)
			if not tile in SHADOW_CASTERS:
				continue
			var below := get_tile(x, y + 1)
			if area.has_point(Vector2i(x, y + 1)) and y + 1 < height and not below in SHADOW_CASTERS and below != VOID and below != ROOF:
				var p := Vector2(x * TILE, (y + 1) * TILE)
				_ci.draw_rect(Rect2(p, Vector2(TILE, 7)), Color(0, 0, 0, 0.16))
				_ci.draw_rect(Rect2(p, Vector2(TILE, 3)), Color(0, 0, 0, 0.14))
			var right := get_tile(x + 1, y)
			if area.has_point(Vector2i(x + 1, y)) and x + 1 < width and not right in SHADOW_CASTERS and right != VOID and right != ROOF:
				_ci.draw_rect(Rect2(Vector2((x + 1) * TILE, y * TILE + 4), Vector2(4, TILE)), Color(0, 0, 0, 0.13))


## A soft oval shadow on the ground (under trees).
func _ground_shadow(center: Vector2, radius: float) -> void:
	_ci.draw_set_transform(center, 0.0, Vector2(1.0, 0.35))
	_ci.draw_circle(Vector2.ZERO, radius, Color(0, 0, 0, 0.22))
	_ci.draw_set_transform(Vector2.ZERO)


## A repeatable "random" number for each tile, so details like grass specks
## are scattered but stay in the same place every time.
func _hash(x: int, y: int, salt: int = 0) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
	return absi(h)


## A few darker pixels scattered on a tile.
func _specks(x: int, y: int, r: Rect2, color: Color, count: int) -> void:
	for i in count:
		var h := _hash(x, y, i + 1)
		_ci.draw_rect(Rect2(r.position + Vector2(h % 18, (h / 18) % 18), Vector2(2, 2)), color)
