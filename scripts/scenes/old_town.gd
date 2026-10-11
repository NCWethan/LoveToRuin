extends Area
## Old Town (fragment 6): a plaza under strings of paper flags, adobe shops with
## red clay roofs (Doña Rosa's tortilla stand, a candle shop that's always "back
## in 5 minutes"), an old wagon, a Mariachi Cactus, a ghost tour; and at the end
## of the street, the Casa Vieja, where one candle is always lit.
##
## Inside the Casa, the Hostess (the ghost of Isabel) has set the table for twelve
## every night since 1874. Nobody ever came. Sit in the empty chair and she
## serves dinner (the battle: oldtown_battles.gd). The fragment is in the
## candelabra. Its KEEPSAKE is the plaza bench, five years ago: an old man, a
## pigeon feather, and what Relic's backpack was really full of. The feather is
## still wedged in the bench. (It can go back to the Pigeon Man, at the mall:
## area.gd, _return_feather.)
##
## Reached by bus (from any stop) once fragment 5 is found.
##
##   Corps      Nat walks the plaza with you, and tells you Isabel's story.
##   Own way    Nat is on a bench by the Casa. He won't stop you.
##   With Hop   Nat is sitting on the Casa's steps, reading. He's read ahead.
##
## Before she'll serve, the Hostess needs her table ready (Chapter 2: the road to
## each fragment): the candles lit (the matches are in the candle shop, in the
## drawer under the one that sticks), and the four guests' name cards at their
## places (the invitations on the sideboard say where everyone sat).
##
## Story flags: ot_arrived, ot_inside, ot_matches, ot_candles_lit, ot_cards,
## ot_seat_<seat> (a guest's name), ot_table_set, ot_dinner_done, ot_candles_out,
## ot_fragment, has_fragment_6, has_feather.

const SCENE := "res://scenes/old_town.tscn"
const T := Room.TILE
const OUTSIDE := Rect2i(0, 0, 60, 30)
const INSIDE := Rect2i(0, 32, 30, 20)
## Where the bus lets you off (the east end of the street).
const ENTRY := Vector2(55 * T, 23 * T + 10)
## The Casa Vieja's door, outside and in.
const DOOR_OUT := Vector2(44 * T + 10, 9 * T + 4)
const OUTSIDE_DOOR := Vector2(44 * T + 10, 10 * T + 14)
const INSIDE_ENTRY := Vector2(14 * T + 10, 49 * T + 10)
const INSIDE_EXIT := Vector2(14 * T + 10, 51 * T - 2)
## The candle shop's door (it's never open).
const CANDLE_DOOR := Vector2(21 * T + 10, 7 * T + 4)
## The empty chair at the foot of the table, and the head (the Hostess's place).
const CHAIR := Vector2(5 * T + 10, 42 * T + 10)
const HEAD := Vector2(24 * T + 10, 42 * T + 10)
## The bench where Relic left the feather (tiles 19-20, row 20).
const FEATHER_BENCH := Vector2(20 * T, 21 * T + 4)
const NAT_PLAZA := Vector2(24 * T, 12 * T)
const NAT_BENCH := Vector2(38 * T, 12 * T + 10)
const NAT_STEPS := Vector2(44 * T + 10, 11 * T)
## The candles on the table (x positions, in tiles) and the candelabra.
const CANDLES := [8, 11, 14, 18, 21]
const CANDELABRA := Vector2(15 * T + 10, 42 * T)
## The candle shop: its own little room on the map.
const SHOP := Rect2i(33, 33, 18, 13)
const SHOP_ENTRY := Vector2(41 * T + 10, 43 * T + 10)
const SHOP_EXIT := Vector2(41 * T + 10, 45 * T - 2)
const OUTSIDE_SHOP := Vector2(21 * T + 10, 8 * T + 2)
const DRAWERS := Vector2(39 * T + 10, 40 * T + 4)
const SHOP_NOTE := Vector2(42 * T + 10, 40 * T + 4)
## The four guests, and where each one sat (the seats: N = the clock's side of
## the table, S = the window's side; 0 at the foot, 4 next to the Hostess).
const GUESTS := ["Don Esteban", "Señora Lupe", "Marisol", "Father Tomás"]
const GUEST_SEATS := {"Don Esteban": "N4", "Señora Lupe": "S4", "Marisol": "S3", "Father Tomás": "N2"}

var partner: Character
var nat: Character
var hostess: Character
var _decor: Node2D
var _shade: Node2D
var _font: Font
var _time: float = 0.0
## A fight is starting: don't start it again during the fade.
var _engaged: bool = false
## Back from the KEEPSAKE (its lines play first, from area.gd).
var _from_memory: bool = false


func _ready() -> void:
	_from_memory = not Game.keepsake_after.is_empty() and not Game.playing_relic
	rooms.assign([_px(OUTSIDE), _px(INSIDE), _px(SHOP)])
	setup_area(ENTRY)
	add_wild_encounters(SCENE, Rect2(T, 11 * T, 58 * T, 13 * T))
	add_wild_encounters(SCENE, _px(SHOP), true)
	_font = ThemeDB.fallback_font
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	add_static_layer(_draw_scenery)
	# Over everything: the dusk outside, the dark inside once the candles go out.
	_shade = Node2D.new()
	add_child(_shade)
	_shade.draw.connect(_draw_shade)
	_place_people()
	_dress()
	for spot in [[ENTRY + Vector2(10, -8), _bus_stop], [DOOR_OUT, _casa_door], [INSIDE_EXIT, _leave_casa],
			[CANDLE_DOOR, _candle_shop], [CHAIR, _empty_chair], [FEATHER_BENCH, _feather_bench],
			[Vector2(5 * T + 10, 18 * T + 4), _wagon], [Vector2(25 * T + 10, 18 * T + 4), _flagpole],
			[Vector2(3 * T + 10, 36 * T + 4), _clock], [Vector2(22 * T + 10, 36 * T + 4), _sideboard],
			[SHOP_EXIT, _leave_shop], [DRAWERS, _drawers], [SHOP_NOTE, _shop_note], [CANDELABRA, _candelabra],
			[Vector2(36 * T + 10, 36 * T + 4), _shelf.bind(0)], [Vector2(44 * T + 10, 36 * T + 4), _shelf.bind(1)],
			[Vector2(48 * T + 10, 36 * T + 4), _shelf.bind(2)]]:
		world.add_child(Hotspot.create(spot[0], spot[1]))
	for seat in _seats():
		world.add_child(Hotspot.create(_card_spot(seat), _place_card.bind(seat)))
	_play_music_here()
	# A SAVE point by the bus stop.
	add_save_point(ENTRY + Vector2(42, -4), "* (Somewhere, a trumpet. Badly. Happily.)")
	fit_camera_to_room()
	_start.call_deferred()


static func _px(r: Rect2i) -> Rect2:
	return Rect2(r.position * T, r.size * T)


func _genocide() -> bool:
	return Game.on_genocide_route()


func _route() -> String:
	return str(Game.flags.get("route", ""))


## In the Casa (not the candle shop).
func _inside() -> bool:
	return _px(INSIDE).has_point(player.position)


func _in_shop() -> bool:
	return _px(SHOP).has_point(player.position)


## The plaza tune outside; inside, nothing but a clock (until dinner).
func _play_music_here() -> void:
	if _inside():
		Game.stop_music(0.8)
	else:
		Game.play_music("oldtown")


func _process(delta: float) -> void:
	_time += delta
	# The candles flicker (and the one in the window).
	if int(_time * 8.0) != int((_time - delta) * 8.0):
		_decor.queue_redraw()


# --- The map -----------------------------------------------------------------------

## Set dressing (props.gd): papel picado over the plaza, barrels and crates by the
## shops, an elote cart, cactus pots, lamps along the road; in the Casa, a piano
## nobody plays.
func _dress() -> void:
	add_dressing([
		["barrel", Vector2(2 * T + 8, 7 * T + 12), {"look": ["* (A barrel of masa harina. Doña Rosa's.\n*  It's heavier than it looks. Everything here is.)"]}],
		["barrel", Vector2(14 * T + 8, 7 * T + 12)],
		["umbrella_table", Vector2(12 * T + 10, 9 * T + 6), {"color": Color8(220, 90, 50)}],
		["crates", Vector2(29 * T + 6, 7 * T + 12), {"look": ["* (Crates of candles, stacked. One is labeled\n*  UNSCENTED. It smells like cinnamon anyway.)"]}],
		["potted_plant", Vector2(20 * T, 7 * T + 10)],
		["potted_plant", Vector2(23 * T, 7 * T + 10)],
		["food_cart", Vector2(37 * T, 17 * T + 10), {"color": Color8(230, 190, 70), "text": "ELOTES", "look": ["* (An elote cart. Corn, mayo, cheese, chili, lime.\n*  The man who runs it is on a break. Forever?)"]}],
		["flower_bed", Vector2(25 * T + 10, 13 * T + 8), {"size": Vector2(50, 10), "walkable": true}],
		["rock", Vector2(8 * T, 13 * T)],
		["bush", Vector2(52 * T, 18 * T)],
		["bush", Vector2(13 * T, 18 * T), {"berries": true}],
		["sign", Vector2(48 * T, 23 * T + 10), {"text": "SAN DIEGO AVE", "look": ["* (SAN DIEGO AVE. HISTORIC OLD TOWN.\n*  EST. 1769. PLEASE DRIVE SLOWLY.)"]}],
		["lamp", Vector2(8 * T, 24 * T + 4)],
		["lamp", Vector2(22 * T, 24 * T + 4)],
		["lamp", Vector2(36 * T, 24 * T + 4)],
		["hydrant", Vector2(30 * T, 24 * T + 4)],
		["trash_can", Vector2(42 * T, 23 * T + 10)],
		# The Casa's dining room.
		["piano", Vector2(26 * T, 47 * T), {"look": ["* (An old upright piano. The keys are yellow.)", "* (When you're not looking, it plays one note.\n*  Always the same one. A low C.)"]}],
		["potted_plant", Vector2(2 * T, 49 * T + 10)],
		["bookshelf", Vector2(8 * T, 35 * T + 14), {"look": ["* (Old books with no titles on the spines.\n*  One of them is a ledger. Names, and dates.)"]}],
	])


func build_map() -> void:
	room.setup(60, 52, Room.VOID)
	# Outside: a dirt street, the shops along the top, the plaza in the middle,
	# the Casa Vieja at the end of the street, the road along the bottom.
	room.fill(0, 0, 60, 30, Room.DIRT)
	room.fill(0, 0, 60, 1, Room.TREE)
	room.fill(0, 29, 60, 1, Room.TREE)
	room.fill(0, 0, 1, 24, Room.TREE)
	room.fill(59, 0, 1, 24, Room.TREE)
	# Doña Rosa's tortillería, and the candle shop.
	room.fill(3, 2, 12, 1, Room.CLAY_ROOF)
	room.fill(3, 3, 12, 4, Room.ADOBE)
	room.fill(16, 2, 12, 1, Room.CLAY_ROOF)
	room.fill(16, 3, 12, 4, Room.ADOBE)
	for x in [5, 12, 18, 25]:
		room.set_tile(x, 4, Room.WINDOW)
	room.set_tile(21, 6, Room.DOOR)
	room.fill(7, 7, 4, 1, Room.PROP)          # Rosa's counter and comal
	# The Casa Vieja: bigger, older, and dark.
	room.fill(36, 1, 17, 2, Room.CLAY_ROOF)
	room.fill(36, 3, 17, 6, Room.ADOBE)
	for x in [39, 49]:
		room.set_tile(x, 5, Room.WINDOW)
	room.set_tile(44, 8, Room.DOOR)
	room.fill(36, 10, 7, 1, Room.FENCE)
	room.fill(46, 10, 7, 1, Room.FENCE)
	# The plaza: a grass square, the flagpole, four benches.
	room.fill(17, 13, 18, 9, Room.GRASS)
	room.set_tile(25, 18, Room.PROP)          # the flagpole
	for spot in [Vector2i(19, 14), Vector2i(30, 14), Vector2i(19, 20), Vector2i(30, 20)]:
		room.fill(spot.x, spot.y, 2, 1, Room.BENCH)
	# The old wagon, and the well.
	room.fill(4, 16, 3, 2, Room.PROP)
	room.set_tile(11, 21, Room.PROP)
	for spot in [Vector2i(2, 10), Vector2i(14, 11), Vector2i(33, 7), Vector2i(55, 6), Vector2i(56, 14), Vector2i(2, 21)]:
		room.set_tile(spot.x, spot.y, Room.TREE)
	# The road, and the sidewalk on both sides.
	room.fill(0, 24, 60, 1, Room.SIDEWALK)
	room.fill(0, 25, 60, 3, Room.ROAD)
	room.fill(0, 26, 60, 1, Room.ROAD_LINE)
	room.fill(0, 28, 60, 1, Room.SIDEWALK)
	# Inside the Casa: the dining room. One long table, set for twelve.
	room.fill(0, 32, 30, 20, Room.INTERIOR_WALL)
	room.fill(1, 35, 28, 16, Room.HOUSE_FLOOR)
	room.set_tile(14, 51, Room.DOOR)
	room.fill(7, 41, 16, 3, Room.HOUSE_PROP)  # the table
	room.set_tile(3, 35, Room.HOUSE_PROP)     # the grandfather clock
	room.fill(20, 35, 5, 1, Room.HOUSE_PROP)  # the sideboard
	# The candle shop: shelves of candles all around, the counter in the middle.
	room.fill(SHOP.position.x, SHOP.position.y, SHOP.size.x, SHOP.size.y, Room.INTERIOR_WALL)
	room.fill(34, 35, 16, 10, Room.HOUSE_FLOOR)
	room.fill(35, 35, 14, 1, Room.HOUSE_PROP)  # the shelves along the back
	room.fill(34, 37, 1, 6, Room.HOUSE_PROP)   # and down the sides
	room.fill(49, 37, 1, 6, Room.HOUSE_PROP)
	room.fill(37, 39, 7, 1, Room.HOUSE_PROP)   # the counter
	room.set_tile(41, 45, Room.DOOR)


## What never changes: the papel picado, the signs, Rosa's counter, the Casa's
## windows, the flagpole, the wagon, the well, and the dining room's furniture.
## Drawn once (Area.add_static_layer).
func _draw_scenery(ci: CanvasItem) -> void:
	var colors := [Color8(230, 70, 110), Color8(250, 190, 50), Color8(80, 190, 120), Color8(70, 150, 230), Color8(180, 90, 210), Color8(250, 120, 50)]
	for row in 3:
		var y := (11 + row * 4) * T + 4
		Scenery.papel_picado(ci, Vector2(15 * T, y), Vector2(37 * T, y + 6), colors, row)
	Scenery.hanging_sign(ci, Vector2(5 * T, 3 * T + 4), "TORTILLERÍA", Color8(200, 60, 40))
	Scenery.hanging_sign(ci, Vector2(18 * T, 3 * T + 4), "VELAS · CANDLES", Color8(120, 70, 140))
	Scenery.hanging_sign(ci, Vector2(40 * T, 3 * T + 4), "CASA VIEJA · 1851", Color8(90, 70, 60))
	var note := Rect2(19 * T + 4, 6 * T - 6, 32, 12)
	ci.draw_rect(note, Color8(244, 240, 226))
	ci.draw_string(_font, note.position + Vector2(2, 9), "BACK IN 5", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color8(80, 50, 40))
	Scenery.comal_counter(ci, Rect2(7 * T, 7 * T + 2, 4 * T, 14))
	for x in [39, 49]:
		Scenery.shuttered_window(ci, Rect2(x * T + 2, 5 * T + 2, T - 4, T - 4), Color8(20, 18, 24))
	Scenery.flagpole(ci, Vector2(25 * T + 10, 18 * T + 10), 4 * T + 10, [Color8(60, 140, 80), Color8(240, 240, 240), Color8(200, 50, 50)])
	Scenery.old_wagon(ci, Rect2(4 * T - 2, 16 * T + 2, 3 * T + 4, 18))
	Scenery.stone_well(ci, Vector2(11 * T + 10, 21 * T + 10))
	Scenery.bus_stop(ci, ENTRY + Vector2(9, -8))
	_draw_dining_room(ci)
	_draw_candle_shop(ci)


func _draw_decor() -> void:
	# Steam off Rosa's comal.
	for k in 3:
		var puff := fmod(_time * 12.0 + k * 8.0, 24.0)
		_decor.draw_circle(Vector2(9 * T - 6 + k * 6, 7 * T - puff), 3.0, Color(1, 1, 1, 0.35 * (1.0 - puff / 24.0)))
	# One candle in one window of the Casa.
	if not flag("ot_candles_out"):
		var glow := 0.55 + 0.25 * sin(_time * 9.0) * sin(_time * 3.7)
		_decor.draw_circle(Vector2(49 * T + 10, 5 * T + 10), 7.0, Color(1.0, 0.8, 0.4, glow))
		_decor.draw_rect(Rect2(49 * T + 9, 5 * T + 10, 2, 6), Color8(240, 235, 220))
	# The feather, between the slats of the bench, until it's taken.
	if flag("ot_fragment") and not flag("has_feather"):
		_decor.draw_line(Vector2(19 * T + 14, 20 * T + 6), Vector2(20 * T + 4, 20 * T - 2), Color8(150, 150, 160), 3.0)
		_decor.draw_line(Vector2(19 * T + 15, 20 * T + 5), Vector2(20 * T + 3, 20 * T - 1), Color8(210, 210, 220), 1.0)
	# Pigeons, here and there in the plaza (all of them Gerald).
	for spot in [Vector2(22, 19), Vector2(23, 16), Vector2(29, 17), Vector2(21, 15), Vector2(32, 19)]:
		var bob := absf(sin(_time * 2.0 + spot.x)) * 2.0
		Scenery.pigeon(_decor, spot * T, 1.0 if int(spot.x) % 2 == 0 else -1.0, bob)
	_draw_candles()


## Inside the Casa: the wallpaper, portraits, the clock (stopped at seven), the
## sideboard, twelve chairs and twelve clean plates.
func _draw_dining_room(ci: CanvasItem) -> void:
	for x in range(1, 29):
		ci.draw_rect(Rect2(x * T, 33 * T, 2, 2 * T), Color8(120, 60, 70, 120))
		ci.draw_rect(Rect2(x * T + 10, 33 * T + (x % 3) * 8 + 6, 2, 2), Color8(200, 170, 110, 120))
	for i in 3:
		var x: int = [6, 12, 17][i]
		Scenery.painting(ci, Rect2(x * T, 33 * T + 4, 2 * T, 28), 1 + i * 3)
	Scenery.grandfather_clock(ci, Rect2(3 * T + 2, 34 * T - 6, T - 4, 2 * T + 6), 7)
	# The sideboard, with a punch bowl and silver.
	ci.draw_rect(Rect2(20 * T, 35 * T, 5 * T, T), Color8(100, 65, 40))
	ci.draw_rect(Rect2(20 * T, 35 * T, 5 * T, 2), Color8(130, 90, 58))
	for k in 4:
		ci.draw_rect(Rect2(20 * T + 6 + k * 24, 35 * T + 8, 18, 9), Color8(84, 54, 34))
		ci.draw_rect(Rect2(20 * T + 14 + k * 24, 35 * T + 12, 2, 2), Color8(220, 190, 100))
	ci.draw_circle(Vector2(22 * T + 10, 35 * T + 4), 7.0, Color(0.85, 0.9, 1.0, 0.6))
	ci.draw_circle(Vector2(22 * T + 8, 35 * T + 2), 2.0, Color(1, 1, 1, 0.7))
	# The table: chairs on both sides (and one at each end), a white cloth.
	var table := Rect2(7 * T, 41 * T, 16 * T, 3 * T)
	for k in 5:
		var cx := (8 + k * 3) * T + 10
		Scenery.dining_chair(ci, Vector2(cx, 40 * T + 10), true, Color8(110, 60, 45))
		Scenery.dining_chair(ci, Vector2(cx, 44 * T + 10), false, Color8(110, 60, 45))
	Scenery.dining_chair(ci, Vector2(5 * T + 10, 42 * T + 8), true, Color8(110, 60, 45))
	Scenery.dining_chair(ci, Vector2(24 * T, 42 * T + 8), true, Color8(130, 70, 50))
	ci.draw_rect(Rect2(table.position + Vector2(3, 3), table.size), Color(0, 0, 0, 0.2))
	ci.draw_rect(table, Color8(240, 236, 228))
	ci.draw_rect(Rect2(table.position, Vector2(table.size.x, 2)), Color8(250, 248, 242))
	ci.draw_rect(table, Color8(200, 190, 180), false, 1.0)
	var lace := table.position.x + 4
	while lace < table.end.x:
		ci.draw_circle(Vector2(lace, table.end.y), 2.0, Color8(240, 236, 228))
		lace += 6
	for k in 5:
		var cx := (8 + k * 3) * T + 10
		for py in [41 * T + 8, 43 * T + 12]:
			Scenery.place_setting(ci, Vector2(cx, py))


## The candles on the table (flickering, or out), and the candelabra in the middle
## with the fragment glowing in it.
func _draw_candles() -> void:
	var out := flag("ot_candles_out") or not _candles_lit()
	for x in CANDLES:
		var at := Vector2(x * T + 10, 42 * T + 4)
		_decor.draw_rect(Rect2(at + Vector2(-3, -1), Vector2(6, 2)), Color8(200, 170, 80))
		_decor.draw_rect(Rect2(at + Vector2(-2, -10), Vector2(4, 10)), Color8(240, 235, 215))
		_decor.draw_rect(Rect2(at + Vector2(-2, -10), Vector2(1, 10)), Color8(250, 248, 236))
		if not out:
			var f := 0.7 + 0.3 * sin(_time * (9.0 + x) + x)
			_decor.draw_circle(at + Vector2(0, -13), 5.0 * f + 3.0, Color(1.0, 0.75, 0.3, 0.25))
			_decor.draw_circle(at + Vector2(0, -12), 2.5, Color(1.0, 0.9, 0.5, f))
		else:
			_decor.draw_line(at + Vector2(0, -11), at + Vector2(1, -16), Color(0.7, 0.7, 0.7, 0.4), 1.0)
	_decor.draw_rect(Rect2(CANDELABRA + Vector2(-6, 0), Vector2(12, 3)), Color8(200, 170, 80))
	_decor.draw_rect(Rect2(CANDELABRA + Vector2(-2, -14), Vector2(4, 16)), Color8(200, 170, 80))
	_decor.draw_rect(Rect2(CANDELABRA + Vector2(-2, -14), Vector2(1, 16)), Color8(236, 210, 120))
	_decor.draw_line(CANDELABRA + Vector2(-10, -10), CANDELABRA + Vector2(10, -10), Color8(200, 170, 80), 2.0)
	for side in [-10.0, 10.0]:
		_decor.draw_rect(Rect2(CANDELABRA + Vector2(side - 1, -16), Vector2(3, 6)), Color8(240, 235, 215))
	if not flag("ot_fragment"):
		var pulse := 0.6 + 0.4 * sin(_time * 4.0)
		_decor.draw_circle(CANDELABRA + Vector2(0, -18), 6.0 + pulse * 3.0, Color(1.0, 0.2, 0.25, 0.3))
		_decor.draw_circle(CANDELABRA + Vector2(0, -18), 4.0, Color(1.0, 0.25, 0.3, pulse))


## Dusk over Old Town; and inside, once the candles are out, the dark.
func _draw_shade() -> void:
	_shade.draw_rect(_px(OUTSIDE), Color(0.35, 0.15, 0.3, 0.12))
	if not _candles_lit():
		# Before the candles: dark, but for her own glow.
		_shade.draw_rect(_px(INSIDE), Color(0.02, 0.0, 0.05, 0.45))
	_draw_cards()
	if flag("ot_candles_out"):
		_shade.draw_rect(_px(INSIDE), Color(0.02, 0.0, 0.05, 0.55))
		var pulse := 0.6 + 0.4 * sin(_time * 4.0)
		if not flag("ot_fragment"):
			_shade.draw_circle(CANDELABRA + Vector2(0, -18), 30.0, Color(1.0, 0.2, 0.25, 0.12 * pulse))


# --- People ----------------------------------------------------------------------

func _place_people() -> void:
	if not Game.walking_alone():
		partner = Cast.make(Game.partner())
		add_character(partner, player.position + Vector2(-20, 0))
		partner.follow = player
	add_person("rosa", Vector2(9 * T, 8 * T + 14), SCENE)
	add_person("cactus", Vector2(27 * T, 12 * T + 4), SCENE)
	add_person("guide", Vector2(41 * T, 12 * T + 10), SCENE)
	# Nat: in the plaza (Corps), on a bench (own way), on the Casa's steps (with Hop).
	if Game.partner() != "Nat":
		match _route():
			"pacifist":
				nat = add_npc("Nat", NAT_PLAZA, _talk_nat)
			"neutral":
				nat = add_npc("Nat", NAT_BENCH, _talk_nat)
			_:
				if not flag("beat_corps_nat"):
					nat = add_npc("Nat", NAT_STEPS, _talk_nat)
	# The Hostess, at the head of her table, until dinner's over.
	if not flag("ot_dinner_done") and str(Game.battle_result.get("id", "")) != "hostess":
		hostess = Cast.make("hostess")
		hostess.glow = true
		hostess.glow_color = Color(0.75, 0.6, 1.0)
		hostess.modulate.a = 0.75
		add_character(hostess, HEAD)
		hostess.face(Vector2.LEFT)
		hostess.on_interact = _talk_hostess


func _talk_nat() -> void:
	match _route():
		"pacifist":
			if flag("ot_fragment"):
				await chat("ot_nat_after", [
					{"who": "Nat", "text": "Isabel Arroyo. 1874. Twelve guests.\n...One showed up. Eventually.", "mood": "happy"},
					{"who": "Nat", "text": "I'm putting that in the book.\nThe book needs a happier page.", "mood": ""},
				], [[{"who": "Nat", "text": "Footnote: the flan was good.", "mood": "smug"}]])
				return
			await chat("ot_nat", [
				{"who": "Nat", "text": "That's the Casa Vieja. Built 1851.\nAdobe walls, three feet thick.", "mood": ""},
				{"who": "Nat", "text": "Isabel Arroyo lived there. In 1874 she threw a\ndinner party. Twelve guests. The good silver.", "mood": ""},
				{"who": "Nat", "text": "Nobody came. A storm, maybe. A feud.\nThe book doesn't say.", "mood": "sad"},
				{"who": "Nat", "text": "She set the table again the next night.\nAnd the next. ...They say she still does.", "mood": "sad"},
				{"who": "Nat", "text": "The fragment's in there. I can feel it from here.\nLike a page you haven't read yet.", "mood": ""},
				{"who": "Elric", "choices": ["Are you coming in?", "You okay?"], "replies": [
					[{"who": "Nat", "text": "Me? No. I know too much history to get\nattached to anything.", "mood": ""}],
					[{"who": "Nat", "text": "Me? Fine. Just not going in there.\nI know too much history to get attached.", "mood": ""}]]},
				{"who": "Nat", "text": "...That's a lie. I just don't like ghosts.", "mood": "smug"},
				{"who": "Nat", "text": "Tip, though. Ghosts want to be NOTICED.\nIf she brings you something, say something nice.", "mood": ""},
				{"who": "Nat", "text": "About the thing she brought. Not something else.\nNobody likes that.", "mood": ""},
				{"who": "Nat", "text": "...Hop hasn't said anything yet. About the name.\nI'm not pushing.", "mood": "sad"},
			], [[{"who": "Nat", "text": "Compliment what's on the table.\nThe RIGHT thing.", "mood": ""}]])
		"neutral":
			await chat("ot_nat_neutral", [
				{"who": "Nat", "text": "...Elric.", "mood": ""},
				{"who": "Nat", "text": "I'm not Big Joe. I'm not going to make you\nduel me for it. I'd lose. I read ahead.", "mood": "smug"},
				{"who": "Nat", "text": "That house. Isabel's been waiting 150 years\nfor somebody to come to dinner.", "mood": "sad"},
				{"who": "Nat", "text": "Just be nice to her. Okay?\nWhatever you are.", "mood": "sad"},
				{"who": "Nat", "text": "If she serves soup, praise the soup.\nThat's all anybody wants. Somebody to notice the soup.", "mood": ""},
			], [[{"who": "Nat", "text": "Notice the soup.", "mood": ""}]])
		_:
			await _confront_nat()


func _talk_hostess() -> void:
	if not _inside():
		return
	if not _table_ready():
		await _not_ready()
		return
	await Game.dialogue.say([
		"* The Hostess: \"Sit, sit! The soup's getting cold!\"",
		"* (It has been getting cold since 1874.)",
		"* (The empty chair is at the foot of the table.)",
	])


# --- Things --------------------------------------------------------------------------

func _candle_shop() -> void:
	if not flag("ot_shop_seen"):
		await Game.dialogue.say([
			"* (A sign in the door: BACK IN 5 MIN.)",
			"* (The sign is very, very old. The door isn't locked.)",
		])
	Game.play_sfx("door")
	await go_through_door(SHOP_ENTRY)
	fit_camera_to_room()
	if not flag("ot_shop_seen"):
		Game.flags["ot_shop_seen"] = true
		await Game.dialogue.say([
			"* (Candles. Hundreds of them. Tall ones, short ones,\n*  ones shaped like saints, one shaped like a cat.)",
			"* (Every wick is black. Wax has dripped down the\n*  shelves and frozen there, like it was in a hurry.)",
			"* (Somewhere in here, something is dripping.)",
		])
		if _genocide():
			await Game.dialogue.say([{"who": "Relic", "tag": "", "face": false, "text": "* \"Back in five minutes.\"\n* We said that to Hop once."}])


func _leave_shop() -> void:
	Game.play_sfx("door")
	await go_through_door(OUTSIDE_SHOP)
	fit_camera_to_room()


func _shelf(which: int) -> void:
	var lines: Array = [
		["* (Candles for saints: San Antonio, for lost things.\n*  Santa Lucía, for eyes. One with no name on it.)"],
		["* (Birthday candles. A box of them, all the same\n*  number: 9.)"],
		["* (A candle shaped like a cat. Its wick is its tail.\n*  Nobody has ever had the heart to light it.)"],
	][which]
	await Game.dialogue.say(lines)


func _shop_note() -> void:
	await Game.dialogue.say([
		"* (A note, pinned to the counter with a candle stub:)",
		"* (\"MATCHES: in the drawer UNDER the one that sticks.\n*  - R.  (Back in 5 min.)\")",
	])


## Three drawers behind the counter. The middle one sticks.
func _drawers() -> void:
	if flag("ot_matches"):
		await Game.dialogue.say(["* (The drawers. You already have the matches.)"])
		return
	var pick := await Game.dialogue.ask("* (Three drawers behind the counter.)", ["Top", "Middle", "Bottom", "Leave them"])
	match pick:
		0:
			await Game.dialogue.say(["* (Receipts. Hundreds of them, all from 1874.\n*  All for candles. All for the Casa Vieja.)"])
		1:
			Game.play_sfx("bonk")
			await Game.dialogue.say(["* (It's stuck. You pull. It doesn't budge.\n*  The whole counter creaks.)"])
		2:
			Game.play_sfx("item")
			Game.flags["ot_matches"] = true
			await Game.dialogue.say(["* (A box of long kitchen matches. A few are left.\n*  The box says LA VELERÍA, 1870.)", "* (You got the MATCHES.)"])
			if flag("ot_inside") and not _candles_lit():
				Game.set_objective("Light the candles. (The candelabra, on the table.)")


## The candles, the counter and its drawers, the dripping wax.
func _draw_candle_shop(ci: CanvasItem) -> void:
	var r := _px(SHOP)
	# Warm plaster, and wax frozen running down the walls.
	for x in range(SHOP.position.x + 1, SHOP.end.x - 1):
		ci.draw_rect(Rect2(x * T, (SHOP.position.y + 1) * T, 2, T), Color8(150, 110, 80, 110))
	var colors := [Color8(240, 235, 215), Color8(220, 70, 60), Color8(240, 200, 80), Color8(130, 90, 180), Color8(90, 160, 110), Color8(240, 150, 190)]
	var k := 0
	# The shelves: rows of candles, all sizes.
	for shelf in [Rect2(35 * T, 35 * T - 4, 14 * T, T + 4), Rect2(34 * T, 37 * T, T, 6 * T), Rect2(49 * T, 37 * T, T, 6 * T)]:
		ci.draw_rect(shelf, Color8(96, 62, 38))
		ci.draw_rect(Rect2(shelf.position, Vector2(shelf.size.x, 2)), Color8(130, 90, 58))
		if shelf.size.x > shelf.size.y:
			var x: float = shelf.position.x + 4
			while x < shelf.end.x - 4:
				var h := 6 + (k * 7) % 9
				var c: Color = colors[k % colors.size()]
				ci.draw_rect(Rect2(x, shelf.end.y - 3 - h, 4, h), c)
				ci.draw_rect(Rect2(x + 1, shelf.end.y - 4 - h, 1, 2), Color8(40, 30, 30))
				x += 7
				k += 1
		else:
			var y: float = shelf.position.y + 4
			while y < shelf.end.y - 6:
				for dx in [3, 9, 14]:
					var c: Color = colors[k % colors.size()]
					ci.draw_rect(Rect2(shelf.position.x + dx - 1, y, 3, 6), c)
					k += 1
				ci.draw_rect(Rect2(shelf.position.x, y + 7, shelf.size.x, 2), Color8(120, 80, 50))
				y += 12
	# Drips of wax, frozen down the front of the back shelf.
	for x in range(36, 48, 2):
		ci.draw_rect(Rect2(x * T + 6, 36 * T, 2, 4 + (x * 5) % 9), Color8(236, 230, 210))
	# The counter: three drawers, a brass bell, the note, a candle stub.
	var counter := Rect2(37 * T, 39 * T - 4, 7 * T, T + 4)
	ci.draw_rect(Rect2(counter.position + Vector2(2, 3), counter.size), Color(0, 0, 0, 0.25))
	ci.draw_rect(counter, Color8(110, 72, 44))
	ci.draw_rect(Rect2(counter.position, Vector2(counter.size.x, 3)), Color8(150, 104, 66))
	for d in 3:
		var drawer := Rect2(38 * T + 4, 39 * T - 1 + d * 7, 2 * T - 8, 6)
		ci.draw_rect(drawer, Color8(92, 58, 34))
		ci.draw_rect(Rect2(drawer.get_center() - Vector2(2, 1), Vector2(4, 2)), Color8(210, 180, 100))
	ci.draw_circle(Vector2(41 * T, 39 * T - 6), 4.0, Color8(200, 160, 70))
	ci.draw_rect(Rect2(41 * T - 1, 39 * T - 12, 2, 3), Color8(150, 110, 40))
	ci.draw_rect(Rect2(42 * T + 4, 39 * T - 8, 10, 7), Color8(244, 240, 226))
	ci.draw_rect(Rect2(42 * T + 8, 39 * T - 12, 3, 5), Color8(240, 235, 215))
	# A beaded curtain to the back, and the shop's own sign over it.
	for b in 8:
		for y in range(int(r.position.y) + T + 6, int(r.position.y) + 2 * T, 4):
			ci.draw_rect(Rect2(46 * T + b * 3, y + (b % 2) * 2, 2, 2), colors[(b + y) % colors.size()])
	PixelFont.draw(ci, "LA VELERÍA", Vector2(36 * T, 33 * T + 6), 2.0, Color8(240, 200, 110), Color8(60, 30, 30))


## The candles: lit, from the candelabra, with the matches.
func _candelabra() -> void:
	if flag("ot_dinner_done"):
		if not flag("ot_fragment"):
			await _take_fragment()
		else:
			await Game.dialogue.say(["* (The candelabra. It's just a candelabra now.)"])
		return
	if _candles_lit():
		await Game.dialogue.say(["* (The candelabra. Every candle on the table is lit.\n*  In the middle of it, something is glowing red.)"])
		return
	if not flag("ot_matches"):
		await Game.dialogue.say([
			"* (The candelabra, in the middle of the table.\n*  Every candle around it is cold.)",
			"* (You'd need matches.)",
		])
		if flag("ot_inside"):
			Game.set_objective("Find matches. (The candle shop, up the street.)")
		return
	await Game.dialogue.say(["* (You strike a match.)"])
	Game.flags["ot_candles_lit"] = true
	for k in CANDLES.size():
		Game.play_sfx("ping", 1.2 + k * 0.08)
		_decor.queue_redraw()
		_shade.queue_redraw()
		await get_tree().create_timer(0.3).timeout
	await Game.dialogue.say([
		"* (One by one, down the whole table, you light\n*  the candles.)",
		"* The Hostess: \"Oh! OH. There. THERE it is.\n*  That's how it looked. That's EXACTLY how it looked.\"",
	])
	await _after_table_step()


# --- The table: name cards ----------------------------------------------------------

func _candles_lit() -> bool:
	return flag("ot_candles_lit") or flag("ot_dinner_done")


func _table_ready() -> bool:
	return _candles_lit() and (flag("ot_table_set") or flag("ot_dinner_done"))


## Every place at the table: "N0".."N4" (the clock's side), "S0".."S4".
func _seats() -> Array:
	var seats: Array = []
	for side in ["N", "S"]:
		for k in 5:
			seats.append("%s%d" % [side, k])
	return seats


## Where a seat's place card sits on the table (at its place setting).
func _card_spot(seat: String) -> Vector2:
	var k := int(seat.substr(1))
	return Vector2((8 + k * 3) * T + 10, 41 * T + 8 if seat[0] == "N" else 43 * T + 12)


func _seat_of(guest: String) -> String:
	for seat in _seats():
		if Game.flags.get("ot_seat_" + seat, "") == guest:
			return seat
	return ""


func _draw_cards() -> void:
	if flag("ot_dinner_done"):
		return
	for seat in _seats():
		var guest: String = Game.flags.get("ot_seat_" + seat, "")
		if guest == "":
			continue
		var at := _card_spot(seat) + Vector2(0, -8 if seat[0] == "N" else 6)
		_shade.draw_rect(Rect2(at - Vector2(5, 3), Vector2(10, 6)), Color8(250, 248, 240))
		_shade.draw_rect(Rect2(at - Vector2(3, 1), Vector2(6, 1)), Color8(120, 70, 90))


## The sideboard: the invitations (they say who sat where), and the place cards.
func _sideboard() -> void:
	if flag("ot_dinner_done"):
		await Game.dialogue.say(["* (Twelve invitations, in neat handwriting.\n*  Every one of them is crossed out but one.)"])
		return
	await Game.dialogue.say([
		"* (Twelve invitations, in neat handwriting. Four have\n*  a note on the back, in the same hand:)",
		"* (\"Don Esteban Ruiz.\" On the back: \"At my right\n*  hand, as always.\")",
		"* (\"Señora Lupe Ortega.\" On the back: \"Across from\n*  Don Esteban. They argue. I LOVE it.\")",
		"* (\"Marisol Ortega, age 9.\" On the back: \"Right\n*  next to her mother, where I can see her.\")",
		"* (\"Father Tomás.\" On the back: \"Right in the middle.\n*  The clock's side of the table.\")",
	])
	if not flag("ot_cards"):
		Game.flags["ot_cards"] = true
		Game.play_sfx("item")
		await Game.dialogue.say(["* (Under them: place cards. Only four have names on\n*  them so far. You take those.)", "* (You got the PLACE CARDS.)"])
		if not flag("ot_table_set"):
			Game.set_objective("Set the place cards. (Who sat where?)")


## A place at the table: put a name card down (or pick it back up).
func _place_card(seat: String) -> void:
	if flag("ot_dinner_done"):
		await Game.dialogue.say(["* (A clean plate, a folded napkin.)"])
		return
	if flag("ot_table_set"):
		var guest: String = Game.flags.get("ot_seat_" + seat, "")
		await Game.dialogue.say(["* (%s's place.)" % guest if guest != "" else "* (A clean plate, a folded napkin. Nobody's place.)"])
		return
	if not flag("ot_cards"):
		await Game.dialogue.say(["* (A clean plate, a folded napkin, and a little\n*  silver card holder. It's empty.)"])
		return
	var here: String = Game.flags.get("ot_seat_" + seat, "")
	var options: Array = []
	for guest in GUESTS:
		if guest != here:
			options.append(guest)
	options.append("Take it back" if here != "" else "Leave it")
	var prompt := "* (%s's card is here.)" % here if here != "" else "* (An empty card holder. Whose card goes here?)"
	var pick := await Game.dialogue.ask(prompt, options)
	if pick < 0 or pick >= options.size():
		return
	if pick == options.size() - 1:
		if here != "":
			Game.flags.erase("ot_seat_" + seat)
			_shade.queue_redraw()
		return
	var guest: String = options[pick]
	# (A card goes in one place: from wherever it was, to here.)
	var old := _seat_of(guest)
	if old != "":
		Game.flags.erase("ot_seat_" + old)
	Game.flags["ot_seat_" + seat] = guest
	Game.play_sfx("select")
	_shade.queue_redraw()
	for g in GUESTS:
		if _seat_of(g) == "":
			return
	await _check_table()


## All four cards are down: is it right?
func _check_table() -> void:
	var wrong: Array = GUESTS.filter(func(g: String) -> bool: return _seat_of(g) != GUEST_SEATS[g])
	if wrong.is_empty():
		Game.flags["ot_table_set"] = true
		Game.play_sfx("spare")
		await Game.dialogue.say([
			"* The Hostess: \"Esteban at my right. Lupe across,\n*  so they can bicker. Marisol by her mama.\"",
			"* \"And Father Tomás right in the middle, so he can\n*  bless the food AND keep an eye on the clock.\"",
			"* \"...It's perfect. It's exactly how it was.\"",
		])
		await partner_cheer(2)
		await _after_table_step()
		return
	Game.play_sfx("miss")
	var hints := {
		"Don Esteban": "* \"Esteban sits at my RIGHT hand, dear. I'm standing\n*  at the head of the table, looking down it.\"",
		"Señora Lupe": "* \"Lupe sits ACROSS from Esteban. Right across.\n*  Otherwise how would they argue?\"",
		"Marisol": "* \"Marisol sits right NEXT to her mother.\n*  She's nine. She needs watching.\"",
		"Father Tomás": "* \"Father Tomás sits in the very middle, on the\n*  side with the clock. He likes to know the time.\"",
	}
	await Game.dialogue.say([
		"* The Hostess: \"Oh. Oh, dear. No, no, no.\"",
		hints[wrong[0]],
		"* (She gently hands the wrong cards back to you.)",
	])
	for g in wrong:
		Game.flags.erase("ot_seat_" + _seat_of(g))
	_shade.queue_redraw()


## After a step of getting the table ready: what's left (or sit down).
func _after_table_step() -> void:
	if _table_ready():
		await Game.dialogue.say(["* The Hostess: \"Now. NOW. Sit, sit! The soup's\n*  getting cold!\""])
		Game.set_objective("Sit down. (The empty chair at the end.)")
	elif not _candles_lit():
		Game.set_objective("Light the candles. (Matches: the candle shop.)" if not flag("ot_matches") else "Light the candles. (The candelabra, on the table.)")
	else:
		Game.set_objective("Set the place cards. (The sideboard.)" if not flag("ot_cards") else "Set the place cards. (Who sat where?)")


## The Hostess, before her table's ready.
func _not_ready() -> void:
	if not _candles_lit():
		await Game.dialogue.say([
			"* The Hostess: \"Not in the DARK, dear! The candles!\"",
			"* \"Rodrigo, next door, has the matches. He's just\n*  stepped out. Back in five minutes.\"",
			"* (She says it like she's said it before.\n*  For a long time.)",
		] if not flag("ot_matches") else [
			"* The Hostess: \"Matches! Oh, you FOUND some.\n*  Light them, dear. Start with the candelabra.\"",
		])
	else:
		await Game.dialogue.say([
			"* The Hostess: \"The place cards! Nobody sits until\n*  everybody knows where to sit.\"",
			"* \"The invitations are on the sideboard.\n*  I wrote down where everyone goes. I always do.\"",
		])
	await _after_table_step()


func _wagon() -> void:
	await Game.dialogue.say(["* (An old wooden wagon. A plaque says it carried\n*  the mail to Los Angeles. It took four days.)", "* (Someone left a churro on it. It's been there\n*  long enough that you don't want it.)"])


func _flagpole() -> void:
	await Game.dialogue.say(["* (The flagpole in the middle of the plaza.\n*  A plaque at the bottom says 1846.)", "* (A pigeon is sitting on the plaque.\n*  It's probably Gerald.)"])


func _clock() -> void:
	await Game.dialogue.say(["* (A grandfather clock. It's stopped at seven.)", "* (Dinner was at seven.)"])


# --- Story ------------------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if not is_inside_tree():
		return
	if _from_memory:
		while is_blocked() or not Game.keepsake_after.is_empty():
			await get_tree().process_frame
		await run_cutscene(_after_memory)
		return
	var id := str(Game.battle_result.get("id", ""))
	var spared: bool = not Game.battle_result.get("spared", []).is_empty()
	if id in ["hostess", "corps_nat"]:
		Game.battle_result = {}
	match id:
		"hostess":
			await run_cutscene(_after_hostess.bind(spared))
			return
		"corps_nat":
			await run_cutscene(_after_nat)
			return
	if await handle_person_return():
		return
	if not flag("ot_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked() or _engaged:
		return
	if not _inside():
		check_random_encounter(SCENE)
	# With Hop: Nat is waiting on the steps.
	if _genocide() and nat and is_instance_valid(nat) and player.position.distance_to(nat.position) < 70.0:
		run_cutscene(_confront_nat)


func _arrival() -> void:
	Game.flags["ot_arrived"] = true
	await Game.dialogue.say([
		"* (Old Town. Adobe walls, red clay roofs, and strings\n*  of paper flags over the plaza.)",
		"* (Somebody's playing a trumpet. Badly. Happily.\n*  Something smells like tortillas.)",
		"* (At the end of the street, there's an old house\n*  with every window dark. Except one.)",
		"* (A candle is burning in it.)",
	])
	match _route():
		"pacifist":
			await Game.dialogue.say([{"who": "Nat", "text": "Over here. I'll give you the tour.\nThe REAL one. Not the heron's.", "mood": "smug"}])
			Game.set_objective("Find the fragment. (Nat's in the plaza.)")
		"neutral":
			await Game.dialogue.say(["* (On a bench by the old house: Nat. He's reading.\n*  He sees you, and closes the book.)"])
			Game.set_objective("Find the fragment. (The house with the candle?)")
		_:
			await Game.dialogue.say([
				"* (Someone is sitting on the steps of the old house,\n*  reading a book. Nat.)",
				{"who": "Hop", "text": "...He's just sitting there. He's not even hiding.", "mood": "sad"},
				{"who": "Hop", "text": "Nat always reads the last page first.\nHe always knows how it ends.", "mood": "sad"},
				{"who": "Relic", "tag": "", "face": false, "text": "* Then he knows."},
			])
			Game.set_objective("...")


func _casa_door() -> void:
	if nat and is_instance_valid(nat) and _genocide():
		await _confront_nat()
		return
	Game.play_sfx("door")
	await go_through_door(INSIDE_ENTRY)
	fit_camera_to_room()
	_play_music_here()
	if flag("ot_inside") or flag("ot_dinner_done"):
		return
	Game.flags["ot_inside"] = true
	await Game.dialogue.say([
		"* (A dining room. One long table, set for twelve.\n*  Silver, crystal, folded napkins.)",
		"* (Every plate is clean. Every chair is empty.\n*  Every candle is cold.)",
		"* (At the head of the table, a woman is standing.\n*  You can see the wallpaper through her.)",
		"* (She sees you. Her whole face lights up.)",
		"* The Hostess: \"Oh! OH! You CAME!\"",
		"* \"Come in, come in! I kept your seat.\n*  I kept ALL the seats!\"",
		"* \"Sit at the end. That one's the best one.\n*  ...Everyone always wanted that one.\"",
		"* \"...Oh! But it's so DARK. And the place cards!\n*  Nobody can sit until the table's ready.\"",
	])
	if _genocide():
		await Game.dialogue.say([{"who": "Relic", "tag": "", "face": false, "text": "* She doesn't know what we are.\n* Nobody's told her."}])
	await _not_ready()


func _leave_casa() -> void:
	if hostess and is_instance_valid(hostess):
		await Game.dialogue.say([
			"* The Hostess: \"...Oh. You're going?\"",
			"* \"That's alright. That's alright.\n*  Everyone does.\"",
			"* (She starts straightening the silverware.\n*  It's already straight.)",
		])
	Game.play_sfx("door")
	await go_through_door(OUTSIDE_DOOR)
	fit_camera_to_room()
	_play_music_here()


func _empty_chair() -> void:
	if not hostess or not is_instance_valid(hostess):
		await Game.dialogue.say(["* (The chair at the foot of the table.\n*  You sat here. Somebody finally did.)"])
		return
	if _engaged:
		return
	if not _table_ready():
		await _not_ready()
		return
	var sit := await Game.dialogue.ask("* (The empty chair at the foot of the table.\n*  Sit down?)", ["Sit", "Not yet"])
	if sit != 0:
		return
	_engaged = true
	player.position = CHAIR + Vector2(0, 2)
	player.facing = Vector2.RIGHT
	await Game.dialogue.say([
		"* (You sit. The chair creaks like it's surprised.)",
		"* (The Hostess clasps her hands. Every candle on\n*  the table flares up at once.)",
	])
	if _genocide():
		await Game.dialogue.say([{"who": "Relic", "tag": "", "face": false, "text": "* We're not hungry."}])
	await Game.start_battle("hostess", SCENE, CHAIR + Vector2(0, 2))


func _after_hostess(spared: bool) -> void:
	Game.flags["ot_dinner_done"] = true
	if spared:
		# She's still standing at the head of the table (she was placed before
		# the battle result was read): she sits down, and fades.
		var her := Cast.make("hostess")
		her.glow = true
		her.glow_color = Color(0.75, 0.6, 1.0)
		her.modulate.a = 0.75
		add_character(her, HEAD)
		her.face(Vector2.LEFT)
		await Game.dialogue.say([
			"* (The Hostess sets down the flan.)",
			"* The Hostess: \"...Somebody came.\"",
			"* \"After all this time. Somebody actually CAME,\n*  and ate, and said it was GOOD.\"",
			"* (She pulls out the chair at the head of the table.)",
			"* (She sits down. For the first time in\n*  a hundred and fifty years, she sits down.)",
			"* (She takes one bite of the flan, and closes her eyes.)",
			"* \"...It IS good. Isn't it.\"",
		])
		var fade := create_tween()
		fade.tween_property(her, "modulate:a", 0.0, 2.6)
		await fade.finished
		her.queue_free()
		await Game.dialogue.say([
			"* (When you look again, the chair is empty.\n*  Her plate is clean.)",
			"* (The candles are still burning. But the one in the\n*  middle, the candelabra, is glowing red.)",
		])
	else:
		Game.flags["ot_candles_out"] = true
		await Game.dialogue.say(["* (Pieces of her drift down onto the tablecloth\n*  like dust.)"])
		for k in CANDLES.size():
			Game.play_sfx("blip", 0.6 - k * 0.05)
			_decor.queue_redraw()
			await get_tree().create_timer(0.35).timeout
		_shade.queue_redraw()
		await Game.dialogue.say([
			"* (One by one, every candle on the table goes out.)",
			"* (Except the candelabra in the middle.\n*  It's glowing red.)",
		])
		if _genocide():
			await Game.dialogue.say([{"who": "Relic", "tag": "", "face": false, "text": "* Nobody came for a hundred and fifty years.\n* Then we did."}])
	await _take_fragment()


func _take_fragment() -> void:
	Game.play_sfx("fragment")
	await Game.dialogue.say([
		"* (You reach into the candelabra. Something red,\n*  and warm, and humming.)",
		"* (You got the sixth FRAGMENT.)",
	])
	Game.flags["ot_fragment"] = true
	Game.flags["has_fragment_6"] = true
	Game.flags["fragments"] = maxi(int(Game.flags.get("fragments", 5)), 6)
	_decor.queue_redraw()
	_shade.queue_redraw()
	Game.set_objective("..." if _genocide() else "6 of 12. (The bench in the plaza.)")
	await Game.dialogue.say(["* (The fragment is warm in your hand.\n*  You close your eyes.)"])
	await Game.play_keepsakes([6], SCENE, player.position, [
		"* (An old man on a bench. A feather. Something heavy,\n*  going from him to Relic.)",
		"* (Relic's backpack. The bottle cap on the road.\n*  The things they picked up, and kept.)",
		"* (It was never junk.)",
		"* (Every piece of it was somebody's pain.\n*  Relic carried it, so they wouldn't have to.)",
	])


## Back from the memory: the bench is out there.
func _after_memory() -> void:
	_decor.queue_redraw()
	if _route() == "pacifist" and partner and Game.partner() == "Hop":
		await Game.dialogue.say([
			{"who": "Hop", "text": "...You okay? You zoned out.", "mood": "sad"},
			{"who": "Hop", "text": "You looked like you were somewhere else.\nLike, years away.", "mood": "sad"},
		])


## On the plaza bench: the feather Relic left, five years ago.
func _feather_bench() -> void:
	if not flag("ot_fragment") or flag("has_feather"):
		await Game.dialogue.say(["* (A bench. The paint's worn off where people sit.)"])
		return
	Game.flags["has_feather"] = true
	_decor.queue_redraw()
	await Game.dialogue.say([
		"* (A bench in the plaza. You know this bench.)",
		"* (Wedged between two slats, right where Relic left it:\n*  a grey pigeon feather.)",
		"* (Five years of rain, and it's still here.)",
		"* (You pick it up. It's heavy.\n*  It's way too heavy for a feather.)",
	])
	var kept: Array = Game.flags.get("mementos", [])
	if not "Pigeon Feather" in kept:
		kept.append("Pigeon Feather")
	Game.flags["mementos"] = kept
	if _genocide():
		await Game.dialogue.say([
			{"who": "Relic", "tag": "", "face": false, "text": "* Ours.\n* We said we'd come back for it."},
			{"who": "Relic", "tag": "", "face": false, "text": "* We keep what's ours."},
		])
		Game.set_objective("...")
		return
	if Townsfolk.is_gone("pigeons"):
		await Game.dialogue.say([
			"* (It belonged to an old man who fed the pigeons\n*  at the PQ Mall.)",
			"* (He's gone. You did that.)",
			"* (You keep it. There's nobody to give it back to.)",
		])
		Game.set_objective("6 of 12. Next: Downtown. (Take the bus.)")
		return
	await Game.dialogue.say([
		"* (You can feel what's in it: an old man's grief,\n*  five years old, waiting for somebody to come back.)",
		"* (It isn't yours. It's his.)",
	])
	Game.set_objective("6 of 12. Next: Downtown. (Or the Pigeon Man?)")


func _bus_stop() -> void:
	await ride_bus(SCENE)


# --- With Hop: Nat --------------------------------------------------------------

func _confront_nat() -> void:
	if not nat or not is_instance_valid(nat) or _engaged:
		return
	_engaged = true
	nat.face(player.position - nat.position)
	await Game.dialogue.say([
		"* (Nat closes his book.)",
		{"who": "Nat", "text": "I read ahead, Elric. Or- whoever's driving.", "mood": ""},
		{"who": "Nat", "text": "Crayola. N.C. Big Joe.\nI know how this chapter ends.", "mood": "sad"},
		{"who": "Nat", "text": "I've read it a hundred times.\nI always skip it.", "mood": "sad"},
		{"who": "Hop", "text": "Nat. Nat, please. Just MOVE.\nJust get out of the way-", "mood": "sad"},
		{"who": "Nat", "text": "No. Somebody has to be in the way, Hop.\nThat's what the Corps is.", "mood": ""},
		{"who": "Nat", "text": "...Somebody has to be in the way.", "mood": "sad"},
	])
	await Game.start_battle("corps_nat", SCENE, player.position)


func _after_nat() -> void:
	if nat:
		nat.queue_free()
		nat = null
	var kept: Array = Game.flags.get("mementos", [])
	if not "Nat's Book" in kept:
		kept.append("Nat's Book")
	Game.flags["mementos"] = kept
	await Game.dialogue.say([
		"* (Nat's book is lying open on the steps.)",
		"* (Page 213 is blank. He never got to read it.)",
		"* (You keep it.)",
		"* (Hop puts his hand on the steps where Nat was\n*  sitting. They're still warm.)",
		{"who": "Hop", "text": "...He knew. He knew the whole time,\nand he sat here anyway.", "mood": "sad"},
		{"who": "Relic", "tag": "", "face": false, "text": "* Dinner's ready."},
	])
	Game.set_objective("...")
