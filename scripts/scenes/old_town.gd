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
## Story flags: ot_arrived, ot_inside, ot_dinner_done, ot_candles_out,
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
	rooms.assign([_px(OUTSIDE), _px(INSIDE)])
	setup_area(ENTRY)
	add_wild_encounters(SCENE, Rect2(T, 11 * T, 58 * T, 13 * T))
	_font = ThemeDB.fallback_font
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	# Over everything: the dusk outside, the dark inside once the candles go out.
	_shade = Node2D.new()
	add_child(_shade)
	_shade.draw.connect(_draw_shade)
	_place_people()
	for spot in [[ENTRY + Vector2(10, -8), _bus_stop], [DOOR_OUT, _casa_door], [INSIDE_EXIT, _leave_casa],
			[CANDLE_DOOR, _candle_shop], [CHAIR, _empty_chair], [FEATHER_BENCH, _feather_bench],
			[Vector2(5 * T + 10, 18 * T + 4), _wagon], [Vector2(25 * T + 10, 18 * T + 4), _flagpole],
			[Vector2(3 * T + 10, 36 * T + 4), _clock], [Vector2(22 * T + 10, 36 * T + 4), _sideboard]]:
		world.add_child(Hotspot.create(spot[0], spot[1]))
	_play_music_here()
	fit_camera_to_room()
	_start.call_deferred()


static func _px(r: Rect2i) -> Rect2:
	return Rect2(r.position * T, r.size * T)


func _genocide() -> bool:
	return Game.on_genocide_route()


func _route() -> String:
	return str(Game.flags.get("route", ""))


func _inside() -> bool:
	return player.position.y > 32 * T


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


func _draw_decor() -> void:
	# Papel picado: strings of paper flags across the plaza, in every color.
	var colors := [Color8(230, 70, 110), Color8(250, 190, 50), Color8(80, 190, 120), Color8(70, 150, 230), Color8(180, 90, 210), Color8(250, 120, 50)]
	for row in 3:
		var y := (11 + row * 4) * T + 4
		_decor.draw_line(Vector2(15 * T, y), Vector2(37 * T, y + 6), Color8(90, 80, 70), 1.0)
		for k in 22:
			var at := Vector2(15 * T + 8 + k * 20, y + k * 6.0 / 22.0)
			var flag_rect := Rect2(at, Vector2(12, 12))
			_decor.draw_rect(flag_rect, Color(colors[(k + row) % colors.size()], 0.9))
			_decor.draw_rect(Rect2(at + Vector2(4, 4), Vector2(4, 4)), Color8(60, 50, 50, 140))
	# Signs over the shops.
	_sign(Vector2(5 * T, 3 * T + 2), "TORTILLERÍA", Color8(200, 60, 40))
	_sign(Vector2(18 * T, 3 * T + 2), "VELAS · CANDLES", Color8(120, 70, 140))
	_decor.draw_string(_font, Vector2(19 * T + 6, 6 * T + 4), "BACK IN 5 MIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color8(80, 50, 40))
	# Rosa's comal: a black griddle, steaming.
	_decor.draw_rect(Rect2(7 * T, 7 * T + 2, 4 * T, 14), Color8(150, 110, 70))
	_decor.draw_circle(Vector2(9 * T, 7 * T + 8), 10.0, Color8(40, 36, 36))
	for k in 3:
		var puff := fmod(_time * 12.0 + k * 8.0, 24.0)
		_decor.draw_circle(Vector2(9 * T - 6 + k * 6, 7 * T - puff), 3.0, Color(1, 1, 1, 0.35 * (1.0 - puff / 24.0)))
	# The Casa Vieja: the sign, and one candle in one window.
	_sign(Vector2(40 * T, 3 * T + 2), "CASA VIEJA · 1851", Color8(90, 70, 60))
	for x in [39, 49]:
		_decor.draw_rect(Rect2(x * T + 2, 5 * T + 2, T - 4, T - 4), Color8(20, 18, 24))
	if not flag("ot_candles_out"):
		var glow := 0.55 + 0.25 * sin(_time * 9.0) * sin(_time * 3.7)
		_decor.draw_circle(Vector2(49 * T + 10, 5 * T + 10), 7.0, Color(1.0, 0.8, 0.4, glow))
		_decor.draw_rect(Rect2(49 * T + 9, 5 * T + 10, 2, 6), Color8(240, 235, 220))
	# The flagpole, and its flag.
	_decor.draw_rect(Rect2(25 * T + 9, 14 * T, 3, 4 * T + 10), Color8(190, 190, 196))
	_decor.draw_rect(Rect2(25 * T + 12, 14 * T, 26, 16), Color8(60, 140, 80))
	_decor.draw_rect(Rect2(25 * T + 20, 14 * T, 10, 16), Color8(240, 240, 240))
	_decor.draw_rect(Rect2(25 * T + 30, 14 * T, 8, 16), Color8(200, 50, 50))
	# The wagon: a wooden bed on two big wheels.
	_decor.draw_rect(Rect2(4 * T - 2, 16 * T + 2, 3 * T + 4, 22), Color8(130, 90, 55))
	_decor.draw_rect(Rect2(4 * T - 2, 16 * T + 2, 3 * T + 4, 22), Color8(80, 55, 35), false, 2.0)
	for wx in [4 * T + 6, 7 * T - 6]:
		_decor.draw_arc(Vector2(wx, 17 * T + 12), 11.0, 0, TAU, 16, Color8(70, 50, 30), 3.0)
		for s in 4:
			var dir := Vector2.from_angle(s * PI / 4.0)
			_decor.draw_line(Vector2(wx, 17 * T + 12) - dir * 10.0, Vector2(wx, 17 * T + 12) + dir * 10.0, Color8(90, 65, 40), 1.0)
	# The well.
	_decor.draw_circle(Vector2(11 * T + 10, 21 * T + 10), 11.0, Color8(150, 140, 130))
	_decor.draw_circle(Vector2(11 * T + 10, 21 * T + 10), 7.0, Color8(30, 40, 60))
	# The feather, between the slats of the bench, until it's taken.
	if flag("ot_fragment") and not flag("has_feather"):
		_decor.draw_line(Vector2(19 * T + 14, 20 * T + 6), Vector2(20 * T + 4, 20 * T - 2), Color8(150, 150, 160), 3.0)
	# Pigeons, here and there in the plaza (all of them Gerald).
	for spot in [Vector2(22, 19), Vector2(23, 16), Vector2(29, 17), Vector2(21, 15), Vector2(32, 19)]:
		var hop := absf(sin(_time * 2.0 + spot.x)) * 2.0
		_decor.draw_circle(spot * T + Vector2(0, -hop), 4.0, Color8(130, 130, 145))
		_decor.draw_circle(spot * T + Vector2(4, -4 - hop), 2.5, Color8(110, 120, 140))
	# The bus stop.
	_decor.draw_rect(Rect2(ENTRY + Vector2(8, -46), Vector2(3, 38)), Color8(150, 150, 156))
	_decor.draw_rect(Rect2(ENTRY + Vector2(0, -54), Vector2(20, 12)), Color8(40, 90, 190))
	_decor.draw_string(_font, ENTRY + Vector2(2, -44), "BUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	_draw_dining_room()


func _sign(at: Vector2, text: String, color: Color) -> void:
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x + 8
	_decor.draw_rect(Rect2(at, Vector2(w, 13)), Color8(245, 230, 200))
	_decor.draw_rect(Rect2(at, Vector2(w, 13)), color, false, 1.0)
	_decor.draw_string(_font, at + Vector2(4, 10), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)


## The dining room: wallpaper, portraits, the clock (stopped at seven), twelve
## chairs, twelve clean plates, the candles and the candelabra.
func _draw_dining_room() -> void:
	for x in range(1, 29):
		_decor.draw_rect(Rect2(x * T, 33 * T, 2, 2 * T), Color8(120, 60, 70, 120))
	for x in [6, 12, 17]:
		_decor.draw_rect(Rect2(x * T, 33 * T + 4, 2 * T, 28), Color8(130, 100, 50))
		_decor.draw_rect(Rect2(x * T + 4, 33 * T + 8, 2 * T - 8, 20), Color8(60 + x * 4, 50, 70))
		_decor.draw_circle(Vector2(x * T + T, 33 * T + 16), 5.0, Color8(200, 170, 140))
	# The grandfather clock, stopped at seven o'clock.
	_decor.draw_rect(Rect2(3 * T + 2, 34 * T, T - 4, 2 * T), Color8(90, 55, 35))
	_decor.draw_circle(Vector2(3 * T + 10, 34 * T + 8), 6.0, Color8(235, 225, 200))
	_decor.draw_line(Vector2(3 * T + 10, 34 * T + 8), Vector2(3 * T + 10, 34 * T + 3), Color8(30, 30, 30), 1.0)
	_decor.draw_line(Vector2(3 * T + 10, 34 * T + 8), Vector2(3 * T + 10, 34 * T + 12), Color8(30, 30, 30), 1.0)
	# The sideboard, with a punch bowl.
	_decor.draw_rect(Rect2(20 * T, 35 * T, 5 * T, T), Color8(100, 65, 40))
	_decor.draw_circle(Vector2(22 * T + 10, 35 * T + 4), 7.0, Color(0.85, 0.9, 1.0, 0.6))
	# The table: a white cloth, chairs on both sides (and one at each end).
	var table := Rect2(7 * T, 41 * T, 16 * T, 3 * T)
	for k in 5:
		var cx := (8 + k * 3) * T + 10
		_decor.draw_rect(Rect2(cx - 7, 40 * T + 2, 14, 16), Color8(110, 60, 45))
		_decor.draw_rect(Rect2(cx - 7, 44 * T + 2, 14, 16), Color8(110, 60, 45))
	_decor.draw_rect(Rect2(5 * T + 3, 42 * T - 2, 14, 20), Color8(110, 60, 45))
	_decor.draw_rect(Rect2(23 * T + 9, 42 * T - 2, 14, 20), Color8(130, 70, 50))
	_decor.draw_rect(table, Color8(240, 236, 228))
	_decor.draw_rect(table, Color8(200, 190, 180), false, 1.0)
	for k in 5:
		var cx := (8 + k * 3) * T + 10
		for py in [41 * T + 8, 43 * T + 12]:
			_decor.draw_circle(Vector2(cx, py), 6.0, Color8(250, 250, 250))
			_decor.draw_arc(Vector2(cx, py), 6.0, 0, TAU, 12, Color8(170, 170, 190), 1.0)
			_decor.draw_line(Vector2(cx - 9, py - 4), Vector2(cx - 9, py + 4), Color8(190, 190, 200), 1.0)
			_decor.draw_line(Vector2(cx + 9, py - 4), Vector2(cx + 9, py + 4), Color8(190, 190, 200), 1.0)
	# Candles: lit (flickering), or out.
	var out := flag("ot_candles_out")
	for x in CANDLES:
		var at := Vector2(x * T + 10, 42 * T + 4)
		_decor.draw_rect(Rect2(at + Vector2(-2, -10), Vector2(4, 10)), Color8(240, 235, 215))
		if not out:
			var f := 0.7 + 0.3 * sin(_time * (9.0 + x) + x)
			_decor.draw_circle(at + Vector2(0, -13), 5.0 * f + 3.0, Color(1.0, 0.75, 0.3, 0.25))
			_decor.draw_circle(at + Vector2(0, -12), 2.5, Color(1.0, 0.9, 0.5, f))
	# The candelabra in the middle, with the fragment glowing in it.
	_decor.draw_rect(Rect2(CANDELABRA + Vector2(-2, -14), Vector2(4, 16)), Color8(200, 170, 80))
	_decor.draw_line(CANDELABRA + Vector2(-10, -10), CANDELABRA + Vector2(10, -10), Color8(200, 170, 80), 2.0)
	if not flag("ot_fragment"):
		var pulse := 0.6 + 0.4 * sin(_time * 4.0)
		_decor.draw_circle(CANDELABRA + Vector2(0, -18), 6.0 + pulse * 3.0, Color(1.0, 0.2, 0.25, 0.3))
		_decor.draw_circle(CANDELABRA + Vector2(0, -18), 4.0, Color(1.0, 0.25, 0.3, pulse))


## Dusk over Old Town; and inside, once the candles are out, the dark.
func _draw_shade() -> void:
	_shade.draw_rect(_px(OUTSIDE), Color(0.35, 0.15, 0.3, 0.12))
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
				{"who": "Elric", "choices": ["Are you coming in?", "You okay?"]},
				{"who": "Nat", "text": "Me? No. I know too much history to get\nattached to anything.", "mood": ""},
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
	await Game.dialogue.say([
		"* The Hostess: \"Sit, sit! The soup's getting cold!\"",
		"* (It has been getting cold since 1874.)",
		"* (The empty chair is at the foot of the table.)",
	])


# --- Things --------------------------------------------------------------------------

func _candle_shop() -> void:
	await Game.dialogue.say([
		"* (A sign in the door: BACK IN 5 MIN.)",
		"* (The sign is very, very old.)",
	])


func _wagon() -> void:
	await Game.dialogue.say(["* (An old wooden wagon. A plaque says it carried\n*  the mail to Los Angeles. It took four days.)", "* (Someone left a churro on it. It's been there\n*  long enough that you don't want it.)"])


func _flagpole() -> void:
	await Game.dialogue.say(["* (The flagpole in the middle of the plaza.\n*  A plaque at the bottom says 1846.)", "* (A pigeon is sitting on the plaque.\n*  It's probably Gerald.)"])


func _clock() -> void:
	await Game.dialogue.say(["* (A grandfather clock. It's stopped at seven.)", "* (Dinner was at seven.)"])


func _sideboard() -> void:
	if flag("ot_dinner_done"):
		await Game.dialogue.say(["* (Twelve invitations, in neat handwriting.\n*  Every one of them is crossed out but one.)"])
		return
	await Game.dialogue.say(["* (A stack of invitations, in neat handwriting.)", "* (\"Mrs. Isabel Arroyo requests the pleasure\n*  of your company. Seven o'clock.\")", "* (They were never sent.)"])


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
		"* (Every plate is clean. Every chair is empty.\n*  Every candle is lit.)",
		"* (At the head of the table, a woman is standing.\n*  You can see the wallpaper through her.)",
		"* (She sees you. Her whole face lights up.)",
		"* The Hostess: \"Oh! OH! You CAME!\"",
		"* \"Come in, come in! I kept your seat.\n*  I kept ALL the seats!\"",
		"* \"Sit at the end. That one's the best one.\n*  ...Everyone always wanted that one.\"",
	])
	if _genocide():
		await Game.dialogue.say([{"who": "Relic", "tag": "", "face": false, "text": "* She doesn't know what we are.\n* Nobody's told her."}])
	Game.set_objective("Sit down. (The empty chair at the end.)")


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
	Game.set_objective("6 of 12. Next: Downtown. (And the Pigeon Man, at the mall?)")


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
