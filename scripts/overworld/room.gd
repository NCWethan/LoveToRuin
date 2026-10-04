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
	VOID, INTERIOR_WALL, HALL_FLOOR, LOCKER, CHALKBOARD, DESK, GYM_FLOOR, GYM_LINE, GATE }

## Tiles the player can't walk through.
const SOLID := [WALL, WINDOW, DOOR, TREE, FENCE, BLEACHERS, BENCH, ROOF,
	STUCCO, GLASS, PLANTER, TABLE, PALM, WOOD_WALL, RED_WALL,
	VOID, INTERIOR_WALL, LOCKER, CHALKBOARD, DESK, GATE]

var width: int = 0
var height: int = 0
var _tiles := PackedInt32Array()
var _walls: StaticBody2D


func setup(map_width: int, map_height: int, fill_tile: int) -> void:
	width = map_width
	height = map_height
	_tiles.resize(width * height)
	_tiles.fill(fill_tile)


func set_tile(x: int, y: int, tile: int) -> void:
	if x >= 0 and y >= 0 and x < width and y < height:
		_tiles[y * width + x] = tile


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
	queue_redraw()
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

func _draw() -> void:
	for y in height:
		for x in width:
			_draw_tile(x, y, get_tile(x, y))


## A repeatable "random" number for each tile, so details like grass specks
## are scattered but stay in the same place every time.
func _hash(x: int, y: int, salt: int = 0) -> int:
	var h := (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
	return absi(h)


func _draw_tile(x: int, y: int, tile: int) -> void:
	var r := Rect2(x * TILE, y * TILE, TILE, TILE)
	var p := r.position
	match tile:
		GRASS:
			_grass(x, y, r)
		SIDEWALK:
			draw_rect(r, Color8(178, 178, 170))
			draw_rect(Rect2(p, Vector2(TILE, 1)), Color8(150, 150, 142))
			draw_rect(Rect2(p, Vector2(1, TILE)), Color8(150, 150, 142))
		ASPHALT, PARKING_LINE:
			draw_rect(r, Color8(58, 58, 64))
			_specks(x, y, r, Color8(72, 72, 78), 3)
			if tile == PARKING_LINE:
				draw_rect(Rect2(p + Vector2(9, 0), Vector2(2, TILE)), Color8(230, 230, 230))
		WALL:
			draw_rect(r, Color8(200, 172, 132))
			# Bricks: a line every 5 pixels, staggered.
			for row in 4:
				draw_rect(Rect2(p + Vector2(0, row * 5), Vector2(TILE, 1)), Color8(172, 146, 110))
				var offset := 5 if (row + y) % 2 == 0 else 15
				draw_rect(Rect2(p + Vector2(offset, row * 5), Vector2(1, 5)), Color8(172, 146, 110))
		ROOF:
			draw_rect(r, Color8(120, 70, 60))
			draw_rect(Rect2(p + Vector2(0, 14), Vector2(TILE, 2)), Color8(95, 55, 48))
		WINDOW:
			draw_rect(r, Color8(200, 172, 132))
			draw_rect(Rect2(p + Vector2(3, 3), Vector2(14, 14)), Color8(90, 90, 100))
			draw_rect(Rect2(p + Vector2(4, 4), Vector2(12, 12)), Color8(120, 170, 215))
			draw_rect(Rect2(p + Vector2(9, 4), Vector2(2, 12)), Color8(90, 90, 100))
			draw_rect(Rect2(p + Vector2(5, 5), Vector2(3, 3)), Color8(200, 230, 250))
		DOOR:
			draw_rect(r, Color8(120, 82, 52))
			draw_rect(Rect2(p + Vector2(9, 0), Vector2(2, TILE)), Color8(90, 60, 38))
			draw_rect(Rect2(p + Vector2(13, 10), Vector2(2, 2)), Color8(230, 200, 90))
		TREE:
			_grass(x, y, r)
			draw_rect(Rect2(p + Vector2(8, 12), Vector2(4, 8)), Color8(100, 70, 40))
			draw_circle(p + Vector2(10, 9), 9.0, Color8(36, 92, 44))
			draw_circle(p + Vector2(7, 6), 3.0, Color8(60, 125, 62))
		FENCE:
			_grass(x, y, r)
			draw_rect(Rect2(p + Vector2(0, 4), Vector2(TILE, 2)), Color8(160, 160, 168))
			draw_rect(Rect2(p + Vector2(0, 12), Vector2(TILE, 2)), Color8(160, 160, 168))
			draw_rect(Rect2(p + Vector2(2, 2), Vector2(2, 16)), Color8(130, 130, 138))
			draw_rect(Rect2(p + Vector2(12, 2), Vector2(2, 16)), Color8(130, 130, 138))
		GATE:
			# A chain-link gate, wrapped in a chain with a padlock.
			draw_rect(r, Color8(178, 178, 170))
			draw_rect(Rect2(p + Vector2(2, 0), Vector2(16, TILE)), Color8(150, 150, 158))
			for i in 4:
				draw_line(p + Vector2(2 + i * 4, 0), p + Vector2(6 + i * 4, TILE), Color8(110, 110, 118), 1.0)
			draw_line(p + Vector2(0, 8), p + Vector2(TILE, 12), Color8(90, 90, 96), 2.0)
			if y % 2 == 1:
				draw_rect(Rect2(p + Vector2(7, 6), Vector2(6, 6)), Color8(215, 180, 60))
				draw_rect(Rect2(p + Vector2(9, 8), Vector2(2, 2)), Color8(80, 60, 20))
		FIELD, FIELD_LINE:
			var stripe := Color8(84, 166, 74) if y % 2 == 0 else Color8(78, 156, 68)
			draw_rect(r, stripe)
			if tile == FIELD_LINE:
				draw_rect(Rect2(p + Vector2(9, 0), Vector2(2, TILE)), Color8(235, 235, 235))
		BLEACHERS:
			draw_rect(r, Color8(150, 152, 162))
			draw_rect(Rect2(p + Vector2(0, 6), Vector2(TILE, 2)), Color8(115, 117, 128))
			draw_rect(Rect2(p + Vector2(0, 14), Vector2(TILE, 2)), Color8(115, 117, 128))
		BENCH:
			_grass(x, y, r)
			draw_rect(Rect2(p + Vector2(0, 6), Vector2(TILE, 6)), Color8(140, 95, 55))
			draw_rect(Rect2(p + Vector2(2, 12), Vector2(2, 5)), Color8(80, 80, 85))
			draw_rect(Rect2(p + Vector2(16, 12), Vector2(2, 5)), Color8(80, 80, 85))
		ROAD, ROAD_LINE:
			draw_rect(r, Color8(48, 48, 54))
			_specks(x, y, r, Color8(62, 62, 68), 2)
			if tile == ROAD_LINE and x % 3 != 0:
				draw_rect(Rect2(p + Vector2(0, 9), Vector2(TILE, 2)), Color8(230, 200, 60))
		DIRT:
			draw_rect(r, Color8(150, 120, 80))
			_specks(x, y, r, Color8(130, 100, 65), 3)
		STUCCO:
			# Cream shopping-center wall.
			draw_rect(r, Color8(222, 208, 178))
			_specks(x, y, r, Color8(206, 192, 162), 2)
		WOOD_WALL:
			# Dark wooden planks (Knotty Barrel).
			draw_rect(r, Color8(110, 72, 44))
			for row in 4:
				draw_rect(Rect2(p + Vector2(0, row * 5), Vector2(TILE, 1)), Color8(80, 52, 32))
			draw_rect(Rect2(p + Vector2((x * 7) % 16, 2), Vector2(2, 2)), Color8(70, 45, 28))
		RED_WALL:
			# White wall with a red stripe.
			draw_rect(r, Color8(235, 235, 232))
			draw_rect(Rect2(p + Vector2(0, 6), Vector2(TILE, 5)), Color8(205, 40, 45))
		GLASS:
			draw_rect(r, Color8(70, 90, 110))
			draw_rect(Rect2(p + Vector2(1, 1), Vector2(18, 18)), Color8(95, 130, 160))
			draw_line(p + Vector2(4, 16), p + Vector2(14, 4), Color8(160, 195, 220), 2.0)
		PLANTER:
			draw_rect(r, Color8(120, 90, 60))
			draw_circle(p + Vector2(10, 9), 8.0, Color8(52, 120, 56))
			draw_circle(p + Vector2(6, 7), 3.0, Color8(80, 150, 75))
		PATIO:
			# Terracotta tiles.
			draw_rect(r, Color8(196, 120, 82))
			draw_rect(Rect2(p, Vector2(TILE, 1)), Color8(165, 98, 66))
			draw_rect(Rect2(p, Vector2(1, TILE)), Color8(165, 98, 66))
			draw_rect(Rect2(p + Vector2(10, 0), Vector2(1, TILE)), Color8(175, 106, 72))
		TABLE:
			# A round table under an umbrella.
			draw_rect(r, Color8(196, 120, 82))
			draw_circle(p + Vector2(10, 10), 9.0, Color8(40, 110, 70))
			draw_circle(p + Vector2(10, 10), 2.0, Color8(230, 230, 220))
		VOID:
			draw_rect(r, Color.BLACK)
		INTERIOR_WALL:
			# Painted school wall with a darker strip along the bottom.
			draw_rect(r, Color8(196, 190, 170))
			draw_rect(Rect2(p + Vector2(0, 15), Vector2(TILE, 5)), Color8(120, 110, 95))
		HALL_FLOOR:
			# Speckled school tiles in a checker pattern.
			var light := (x + y) % 2 == 0
			draw_rect(r, Color8(205, 205, 195) if light else Color8(185, 185, 178))
			_specks(x, y, r, Color8(160, 160, 155), 2)
		LOCKER:
			draw_rect(r, Color8(70, 95, 130))
			draw_rect(Rect2(p + Vector2(0, 0), Vector2(1, TILE)), Color8(45, 62, 88))
			draw_rect(Rect2(p + Vector2(4, 3), Vector2(12, 1)), Color8(45, 62, 88))
			draw_rect(Rect2(p + Vector2(4, 5), Vector2(12, 1)), Color8(45, 62, 88))
			draw_rect(Rect2(p + Vector2(15, 10), Vector2(2, 3)), Color8(190, 190, 190))
		CHALKBOARD:
			draw_rect(r, Color8(120, 90, 60))
			draw_rect(Rect2(p + Vector2(0, 2), Vector2(TILE, 15)), Color8(40, 75, 55))
			if (x + y) % 3 == 0:
				draw_line(p + Vector2(3, 7), p + Vector2(15, 6), Color8(220, 225, 215), 1.0)
		DESK:
			var floor_light := (x + y) % 2 == 0
			draw_rect(r, Color8(205, 205, 195) if floor_light else Color8(185, 185, 178))
			draw_rect(Rect2(p + Vector2(2, 3), Vector2(16, 9)), Color8(170, 125, 80))
			draw_rect(Rect2(p + Vector2(4, 12), Vector2(12, 5)), Color8(90, 90, 100))
		GYM_FLOOR, GYM_LINE:
			# Shiny wooden planks.
			draw_rect(r, Color8(214, 168, 108))
			draw_rect(Rect2(p + Vector2(0, (x % 2) * 10), Vector2(TILE, 1)), Color8(190, 145, 90))
			if tile == GYM_LINE:
				draw_rect(Rect2(p + Vector2(9, 0), Vector2(2, TILE)), Color8(250, 250, 250))
		PALM:
			_grass(x, y, r)
			draw_rect(Rect2(p + Vector2(9, 8), Vector2(3, 12)), Color8(140, 105, 60))
			for i in 5:
				var dir := Vector2.from_angle(-PI / 2 + (i - 2) * 0.7) * 9.0
				draw_line(p + Vector2(10, 7), p + Vector2(10, 7) + dir, Color8(50, 130, 60), 3.0)


func _grass(x: int, y: int, r: Rect2) -> void:
	draw_rect(r, Color8(72, 140, 62))
	_specks(x, y, r, Color8(60, 122, 52), 4)


## A few darker pixels scattered on a tile.
func _specks(x: int, y: int, r: Rect2, color: Color, count: int) -> void:
	for i in count:
		var h := _hash(x, y, i + 1)
		draw_rect(Rect2(r.position + Vector2(h % 18, (h / 18) % 18), Vector2(2, 2)), color)
