extends Area
## Downtown (fragment 7): the city at night. A hotel, an all-night diner, an office
## tower with one window lit, gaslamps, a trolley that rings its bell as it goes
## by, a little plaza with palms and a fountain, and at the end of the street the
## ballpark. A Hot Dog Vendor and a Superfan by the gates, a Living Statue in the
## plaza (he hasn't moved since noon).
##
## Inside the ballpark: the field, the empty stands, and the Big Screen over the
## outfield wall, which has been playing to an empty stadium for five years.
## Walk out to the pitcher's mound and it notices you (the battle:
## downtown_battles.gd). The fragment is inside it. Its KEEPSAKE is this same
## field, five years ago: Hop wakes up screaming, and Relic puts his nightmares
## into the only thing in their pocket, a Jack in the Box curly-fry token.
##
## Reached by bus (from any stop) once fragment 6 is found.
##
##   Corps      Supreme is in the dugout with his laptop. He reads the Big Screen's
##              attacks out loud, every turn. Afterwards: the 0.4%.
##   Own way    Supreme is on the field. He tells you your odds. Unhelpfully.
##   With Hop   Supreme is waiting at home plate. He's done the math on you.
##
## Story flags: dt_arrived, dt_inside, dt_screen_done, dt_fragment, dt_odds,
## has_fragment_7.

const SCENE := "res://scenes/downtown.tscn"
const T := Room.TILE
const OUTSIDE := Rect2i(0, 0, 64, 30)
const INSIDE := Rect2i(0, 32, 44, 28)
## Where the bus lets you off (the east end of the plaza).
const ENTRY := Vector2(59 * T, 17 * T + 10)
## The ballpark gates, outside and in.
const GATE_OUT := Vector2(51 * T, 8 * T + 4)
const OUTSIDE_GATE := Vector2(51 * T, 9 * T + 10)
const INSIDE_ENTRY := Vector2(22 * T + 10, 57 * T + 6)
const INSIDE_EXIT := Vector2(22 * T + 10, 59 * T - 2)
## On the field: the pitcher's mound, home plate, the dugout.
const MOUND := Vector2(22 * T + 10, 46 * T + 10)
const HOME_PLATE := Vector2(22 * T + 10, 54 * T)
const DUGOUT := Vector2(30 * T, 54 * T + 10)
const FIRST_BASE := Vector2(31 * T, 49 * T)
## The Big Screen, over the outfield wall.
const SCREEN := Rect2(15 * T, 32 * T + 4, 15 * T, 3 * T + 4)
const DINER_DOOR := Vector2(19 * T + 10, 8 * T + 4)
const HOTEL_DOOR := Vector2(6 * T + 10, 8 * T + 4)

var partner: Character
var supreme: Character
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
	# Just back from a fight here: nothing starts again until its scene has played.
	_engaged = str(Game.battle_result.get("id", "")) in ["big_screen", "corps_supreme"]
	rooms.assign([_px(OUTSIDE), _px(INSIDE)])
	setup_area(ENTRY)
	add_wild_encounters(SCENE, Rect2(T, 15 * T, 62 * T, 13 * T))
	_font = ThemeDB.fallback_font
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	_shade = Node2D.new()
	add_child(_shade)
	_shade.draw.connect(_draw_shade)
	_place_people()
	_dress()
	for spot in [[ENTRY + Vector2(10, -8), _bus_stop], [GATE_OUT, _ballpark_gate], [INSIDE_EXIT, _leave_ballpark],
			[DINER_DOOR, _diner], [HOTEL_DOOR, _hotel], [Vector2(32 * T, 21 * T + 4), _fountain],
			[Vector2(22 * T + 10, 36 * T + 4), _outfield_wall]]:
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


## The city outside; inside, the empty ballpark is quiet (until the screen wakes up).
func _play_music_here() -> void:
	if _inside():
		Game.stop_music(0.8)
	else:
		Game.play_music("downtown")


func _process(delta: float) -> void:
	_time += delta
	_decor.queue_redraw()
	# The trolley rings its bell as it comes by.
	var trolley_x := _trolley_x()
	var before := _trolley_x(_time - delta)
	if before < 0.0 and trolley_x >= 0.0 and not _inside():
		Game.play_sfx("select", 1.6)


## Where the trolley is (its left end, in pixels), or below 0 while it's away.
func _trolley_x(at: float = -1.0) -> float:
	var t := _time if at < 0.0 else at
	return fmod(t * 110.0, 64.0 * T + 1600.0) - 260.0


# --- The map -----------------------------------------------------------------------

func is_night() -> bool:
	return true


## Set dressing (props.gd): parked cars and a taxi, a phone booth, newspaper boxes,
## a trolley stop, lit lamps over the plaza, a dumpster in the alley; inside the
## ballpark, a ball cart and the grounds crew's gear.
func _dress() -> void:
	add_dressing([
		["car", Vector2(44 * T, 10 * T + 12), {"color": Color8(60, 60, 66), "look": ["* (A black car with tinted windows, parked\n*  under a NO PARKING sign. Of course.)"]}],
		["car", Vector2(9 * T, 14 * T + 8), {"color": Color8(240, 200, 50), "look": ["* (A taxi. The light on top says OFF DUTY.\n*  The driver is asleep with his hat over his face.)"]}],
		["car", Vector2(20 * T, 14 * T + 8), {"color": Color8(160, 160, 165)}],
		["phone_booth", Vector2(38 * T + 10, 8 * T + 14), {"look": ["* (A phone booth. There's a quarter on the shelf\n*  and a number scratched in the glass.)", "* (You don't call it. Some numbers are a trap.)"]}],
		["news_box", Vector2(13 * T + 6, 9 * T + 6), {"color": Color8(60, 100, 180), "look": ["* (THE CITY BEAT. Headline: BALLPARK LIGHTS\n*  LEFT ON ALL WEEK. \"WHO'S PAYING FOR THIS?\")"]}],
		["news_box", Vector2(14 * T + 6, 9 * T + 6), {"color": Color8(200, 60, 50)}],
		["hydrant", Vector2(25 * T + 10, 9 * T + 6)],
		["trash_can", Vector2(3 * T, 9 * T + 6)],
		["mailbox", Vector2(33 * T, 9 * T + 6)],
		["sign", Vector2(44 * T, 16 * T + 12), {"text": "TROLLEY", "color": Color8(200, 40, 40), "look": ["* (TROLLEY STOP. Next trolley: 12:04 AM.\n*  It's 12:04 AM. It's been 12:04 AM for a while.)"]}],
		["lamp", Vector2(3 * T + 10, 17 * T + 4), {"lit": true}],
		["lamp", Vector2(29 * T, 17 * T + 4), {"lit": true}],
		["lamp", Vector2(56 * T, 17 * T + 4), {"lit": true}],
		["lamp", Vector2(20 * T, 25 * T + 16), {"lit": true}],
		["lamp", Vector2(44 * T, 25 * T + 16), {"lit": true}],
		["trash_can", Vector2(34 * T, 23 * T + 10)],
		["bike_rack", Vector2(52 * T, 21 * T), {"color": Color8(200, 60, 55), "look": ["* (A rack of rental scooters. They all say\n*  0% BATTERY. Even the one that's charging.)"]}],
		["dumpster", Vector2(59 * T, 27 * T + 10), {"look": ["* (A dumpster behind the diner. A cat lives here.\n*  It looks at you like you owe it rent.)"]}],
		["trash_bag", Vector2(57 * T + 4, 28 * T), {"walkable": true}],
		["bollard", Vector2(4 * T, 27 * T + 4)],
		["bollard", Vector2(6 * T, 27 * T + 4)],
		["puddle", Vector2(40 * T, 27 * T + 10), {"size": Vector2(34, 10)}],
		# Inside the ballpark.
		["cart", Vector2(36 * T, 54 * T + 10), {"look": ["* (A cart full of baseballs. Somebody signed one.\n*  It just says SORRY.)"]}],
		["crates", Vector2(5 * T, 55 * T + 6), {"look": ["* (The grounds crew's boxes: chalk, rakes, and a\n*  tarp folded into a very neat square.)"]}],
		["cooler", Vector2(39 * T, 54 * T + 10)],
	])


func build_map() -> void:
	room.setup(64, 60, Room.VOID)
	room.fill(0, 0, 64, 30, Room.SIDEWALK)
	room.fill(0, 0, 64, 1, Room.WALL)
	room.fill(0, 29, 64, 1, Room.WALL)
	room.fill(0, 0, 1, 30, Room.WALL)
	room.fill(63, 0, 1, 30, Room.WALL)
	# Along the top: the hotel, the diner, the office tower, the ballpark.
	room.fill(1, 1, 12, 7, Room.WALL)
	room.fill(14, 3, 11, 5, Room.RED_WALL)
	room.fill(26, 1, 11, 7, Room.WALL)
	room.fill(40, 1, 23, 7, Room.RED_WALL)
	for x in range(2, 12, 2):
		for y in [2, 4]:
			room.set_tile(x, y, Room.WINDOW)
	for x in range(27, 36, 2):
		for y in [2, 4, 6]:
			room.set_tile(x, y, Room.WINDOW)
	for x in [15, 17, 21, 23]:
		room.set_tile(x, 5, Room.GLASS)
	room.set_tile(6, 7, Room.DOOR)
	room.set_tile(19, 7, Room.DOOR)
	room.fill(50, 7, 2, 1, Room.DOOR)
	# The road, with the trolley tracks on the near side.
	room.fill(1, 10, 62, 5, Room.ROAD)
	room.fill(1, 12, 62, 1, Room.ROAD_LINE)
	# The plaza: palms, planters, benches, a fountain.
	room.fill(3, 17, 54, 9, Room.PATIO)
	for x in [4, 14, 24, 40, 50]:
		room.set_tile(x, 18, Room.PALM)
		room.set_tile(x + 2, 24, Room.PALM)
	for spot in [Vector2i(8, 21), Vector2i(18, 21), Vector2i(44, 21)]:
		room.fill(spot.x, spot.y, 3, 1, Room.PLANTER)
	room.fill(31, 20, 2, 1, Room.PROP)        # the fountain
	for spot in [Vector2i(27, 23), Vector2i(36, 23), Vector2i(10, 25)]:
		room.fill(spot.x, spot.y, 2, 1, Room.BENCH)
	# Inside the ballpark: the stands all around, the field in the middle.
	room.fill(0, 32, 44, 28, Room.BLEACHERS)
	room.fill(3, 36, 38, 21, Room.FIELD)
	room.fill(3, 35, 38, 1, Room.FENCE)       # the outfield wall
	room.fill(20, 57, 5, 2, Room.SIDEWALK)    # the tunnel out
	room.set_tile(22, 59, Room.DOOR)
	room.fill(27, 55, 6, 1, Room.FENCE)       # the dugout rail


func _draw_decor() -> void:
	# The diner's front: dark, with big lit windows.
	_decor.draw_rect(Rect2(14 * T, 3 * T, 11 * T, 5 * T), Color8(48, 50, 62))
	for x in [15, 17, 21, 23]:
		_decor.draw_rect(Rect2(x * T + 2, 5 * T + 2, T - 4, T - 4), Color(1.0, 0.88, 0.6, 0.85))
	_decor.draw_rect(Rect2(19 * T + 3, 7 * T, T - 6, T), Color8(90, 60, 40))
	# The ballpark: red brick, with mortar lines.
	_decor.draw_rect(Rect2(40 * T, 1 * T, 23 * T, 7 * T), Color8(150, 62, 48))
	for row in 14:
		var y := 1 * T + row * 10
		_decor.draw_line(Vector2(40 * T, y), Vector2(63 * T, y), Color8(110, 44, 36), 1.0)
		var x := 40 * T + (10 if row % 2 == 0 else 0)
		while x < 63 * T:
			_decor.draw_line(Vector2(x, y), Vector2(x, y + 10), Color8(110, 44, 36), 1.0)
			x += 20
	_decor.draw_rect(Rect2(50 * T, 6 * T, 2 * T, 2 * T), Color8(40, 40, 46))
	_decor.draw_rect(Rect2(50 * T + 4, 6 * T + 4, 2 * T - 8, 2 * T - 4), Color8(70, 70, 78))
	# The hotel's sign, the diner's neon, the ballpark's name.
	_decor.draw_string(_font, Vector2(2 * T + 4, 1 * T + 14), "HOTEL GRANDE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(240, 210, 120))
	var neon := 0.7 + 0.3 * sin(_time * 5.0) if fmod(_time, 7.0) > 0.3 else 0.15
	_decor.draw_rect(Rect2(14 * T + 6, 3 * T + 4, 10 * T, 18), Color(0.05, 0.05, 0.1, 0.8))
	_decor.draw_string(_font, Vector2(14 * T + 14, 3 * T + 18), "ALL-NIGHT DINER", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.35, 0.55, neon))
	# Brick lines on the ballpark wall, and its arch over the gates.
	_decor.draw_arc(Vector2(51 * T, 7 * T), 2 * T, PI, TAU, 16, Color8(230, 220, 200), 3.0)
	_decor.draw_string(_font, Vector2(46 * T, 3 * T), "THE BALLPARK", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color8(240, 230, 210))
	# One lit window in the office tower, high up. (Someone's working late. Or
	# someone forgot to turn it off five years ago.)
	_decor.draw_rect(Rect2(33 * T + 2, 2 * T + 2, T - 4, T - 4), Color(1.0, 0.9, 0.55, 0.8))
	# Gaslamps along the sidewalk.
	for x in range(3, 62, 6):
		var at := Vector2(x * T + 10, 9 * T)
		_decor.draw_rect(Rect2(at + Vector2(-1.5, -26), Vector2(3, 26)), Color8(40, 40, 46))
		_decor.draw_rect(Rect2(at + Vector2(-5, -36), Vector2(10, 10)), Color8(40, 40, 46))
		_decor.draw_rect(Rect2(at + Vector2(-3, -34), Vector2(6, 6)), Color(1.0, 0.85, 0.5, 0.9 + 0.1 * sin(_time * 7.0 + x)))
	# The crosswalk, and the trolley tracks.
	for k in 5:
		_decor.draw_rect(Rect2(30 * T + 4 + k * 8, 10 * T + 2, 5, 5 * T - 4), Color(1, 1, 1, 0.35))
	for y in [13 * T + 6, 14 * T + 6]:
		_decor.draw_line(Vector2(T, y), Vector2(63 * T, y), Color8(150, 150, 160), 2.0)
	# The trolley: red, with a lit window and a little pole up to the wire.
	var tx := _trolley_x()
	if tx > -200.0 and tx < 64 * T:
		var body := Rect2(tx, 12 * T + 14, 5 * T, 30)
		_decor.draw_rect(body, Color8(200, 40, 45))
		_decor.draw_rect(Rect2(tx + 6, 12 * T + 18, 5 * T - 12, 10), Color(1.0, 0.92, 0.6, 0.85))
		_decor.draw_line(Vector2(tx + 2.5 * T, 12 * T + 14), Vector2(tx + 3 * T, 10 * T), Color8(60, 60, 60), 2.0)
		_decor.draw_string(_font, Vector2(tx + 8, 14 * T + 10), "TROLLEY", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	_decor.draw_line(Vector2(T, 10 * T), Vector2(63 * T, 10 * T), Color8(60, 60, 60), 1.0)
	# The fountain.
	_decor.draw_circle(Vector2(32 * T, 20 * T + 10), 24.0, Color8(200, 200, 210))
	_decor.draw_circle(Vector2(32 * T, 20 * T + 10), 19.0, Color8(70, 120, 170))
	for k in 5:
		var arc := Vector2.from_angle(-PI / 2 + (k - 2) * 0.35)
		_decor.draw_line(Vector2(32 * T, 20 * T + 6), Vector2(32 * T, 20 * T + 6) + arc * (14.0 + 3.0 * sin(_time * 6.0 + k)), Color(0.8, 0.95, 1.0, 0.7), 2.0)
	# The bus stop.
	_decor.draw_rect(Rect2(ENTRY + Vector2(8, -46), Vector2(3, 38)), Color8(150, 150, 156))
	_decor.draw_rect(Rect2(ENTRY + Vector2(0, -54), Vector2(20, 12)), Color8(40, 90, 190))
	_decor.draw_string(_font, ENTRY + Vector2(2, -44), "BUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	_draw_ballpark()


## The field: the infield dirt, the bases, the mound, the foul lines; and the Big
## Screen over the outfield wall.
func _draw_ballpark() -> void:
	var dirt := Color8(176, 128, 82)
	var home := HOME_PLATE
	var diamond := PackedVector2Array([home + Vector2(0, 10), home + Vector2(130, -110), home + Vector2(0, -230), home + Vector2(-130, -110)])
	_decor.draw_colored_polygon(diamond, dirt)
	var grass := PackedVector2Array([home + Vector2(0, -26), home + Vector2(98, -110), home + Vector2(0, -196), home + Vector2(-98, -110)])
	_decor.draw_colored_polygon(grass, Color8(70, 140, 70))
	_decor.draw_circle(MOUND + Vector2(0, 6), 18.0, dirt)
	_decor.draw_rect(Rect2(MOUND + Vector2(-6, 4), Vector2(12, 3)), Color.WHITE)
	for base in [home + Vector2(120, -110), home + Vector2(0, -222), home + Vector2(-120, -110)]:
		_decor.draw_rect(Rect2(base - Vector2(6, 6), Vector2(12, 12)), Color.WHITE)
	_decor.draw_colored_polygon(PackedVector2Array([home + Vector2(-7, -6), home + Vector2(7, -6), home + Vector2(7, 0), home + Vector2(0, 6), home + Vector2(-7, 0)]), Color.WHITE)
	_decor.draw_line(home, home + Vector2(400, -344), Color(1, 1, 1, 0.8), 2.0)
	_decor.draw_line(home, home + Vector2(-400, -344), Color(1, 1, 1, 0.8), 2.0)
	# The Big Screen.
	_decor.draw_rect(Rect2(SCREEN.position + Vector2(40, SCREEN.size.y), Vector2(8, 10)), Color8(80, 80, 90))
	_decor.draw_rect(Rect2(SCREEN.end + Vector2(-48, 0), Vector2(8, 10)), Color8(80, 80, 90))
	_decor.draw_rect(SCREEN.grow(4), Color8(30, 30, 36))
	_decor.draw_rect(SCREEN, Color8(14, 14, 20))
	var on := flag("dt_arrived") and _inside()
	if flag("dt_fragment") and flag("dt_screen_killed"):
		return
	if flag("dt_screen_done"):
		# Happy: a replay of you doing the wave, over and over.
		_decor.draw_string(_font, SCREEN.position + Vector2(16, 26), "THANK YOU, [CROWD]!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color8(255, 220, 80))
		var bob := absf(sin(_time * 3.0)) * 8.0
		_decor.draw_rect(Rect2(SCREEN.get_center() + Vector2(-4, 12 - bob), Vector2(8, 12)), Color8(200, 170, 235))
		return
	if on:
		var flicker := 0.6 + 0.4 * sin(_time * 11.0) * sin(_time * 3.1)
		_decor.draw_string(_font, SCREEN.position + Vector2(18, 24), "HOME 0   VISITORS 0", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.85, 0.3, flicker))
		_decor.draw_string(_font, SCREEN.position + Vector2(40, 52), "IS ANYONE THERE?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.4, 0.4, flicker))
		if not flag("dt_fragment"):
			_decor.draw_circle(SCREEN.get_center() + Vector2(110, 0), 4.0 + 2.0 * sin(_time * 4.0), Color(1.0, 0.2, 0.25, 0.9))


## Night over downtown (with pools of lamplight); the stadium lights inside.
func _draw_shade() -> void:
	_shade.draw_rect(_px(OUTSIDE), Color(0.05, 0.06, 0.2, 0.28))
	for x in range(3, 62, 6):
		_shade.draw_circle(Vector2(x * T + 10, 9 * T - 30), 26.0, Color(1.0, 0.85, 0.5, 0.08))
	_shade.draw_rect(_px(INSIDE), Color(0.05, 0.05, 0.12, 0.18))


# --- People ----------------------------------------------------------------------

func _place_people() -> void:
	if not Game.walking_alone():
		partner = Cast.make(Game.partner())
		add_character(partner, player.position + Vector2(-20, 0))
		partner.follow = player
	add_person("hotdog", Vector2(46 * T, 9 * T + 6), SCENE)
	add_person("superfan", Vector2(56 * T, 9 * T + 6), SCENE)
	add_person("statue", Vector2(12 * T, 19 * T + 10), SCENE)
	if Game.partner() != "Supreme":
		match _route():
			"pacifist":
				supreme = add_npc("Supreme", DUGOUT, _talk_supreme)
			"neutral":
				supreme = add_npc("Supreme", FIRST_BASE, _talk_supreme)
			_:
				if not flag("beat_corps_supreme"):
					supreme = add_npc("Supreme", HOME_PLATE + Vector2(0, -24), _talk_supreme)


func _talk_supreme() -> void:
	match _route():
		"pacifist":
			if flag("dt_odds"):
				await chat("dt_supreme_after", [
					{"who": "Supreme", "text": "Don't look at me like that.\nI said what I said. 0.4%.", "mood": ""},
					{"who": "Supreme", "text": "...I'm still here, aren't I?", "mood": "smug"},
				], [[{"who": "Supreme", "text": "Recalculating. (Still staying.)", "mood": ""}]])
				return
			await chat("dt_supreme", [
				{"who": "Supreme", "text": "Ah. Good. You're here.\nI've been modeling the scoreboard.", "mood": "smug"},
				{"who": "Supreme", "text": "It's got the fragment in it. It's been running\nreplays for an empty stadium for five years.", "mood": ""},
				{"who": "Supreme", "text": "It learns. Whatever you did last turn,\nit throws back at you. So don't do it twice.", "mood": ""},
				{"who": "Supreme", "text": "I'll be in the dugout. I'll call out every\nattack before it comes. Odds included. Free of charge.", "mood": "happy"},
				{"who": "Supreme", "text": "And it wants a crowd. Give it one.\nCheer. Do the wave. ...Don't make me do the wave.", "mood": "smug"},
			], [[{"who": "Supreme", "text": "Walk out to the mound.\nI'll be right here. Computing.", "mood": ""}]])
		"neutral":
			await chat("dt_supreme_neutral", [
				{"who": "Supreme", "text": "Elric. Interesting. I had you at 34%\nto show up here. You keep beating the odds.", "mood": "smug"},
				{"who": "Supreme", "text": "The screen, though. Your odds against it:\n61%. Your odds of being nice about it: 12%.", "mood": ""},
				{"who": "Supreme", "text": "Prove me wrong. I'd love to update my model.", "mood": "smug"},
			], [[{"who": "Supreme", "text": "61%. Rounded.", "mood": ""}]])
		_:
			await _confront_supreme()


# --- Things --------------------------------------------------------------------------

func _diner() -> void:
	await Game.dialogue.say([
		"* (The All-Night Diner. Through the window: a waitress\n*  refilling a coffee nobody's drinking.)",
		"* (A sign: OPEN 24 HOURS. Under it, smaller:\n*  (EXCEPT WHEN WE'RE NOT).)",
	])


func _hotel() -> void:
	await Game.dialogue.say(["* (The Hotel Grande. The doorman is asleep standing up.\n*  You don't wake him.)"])


func _fountain() -> void:
	await Game.dialogue.say(["* (A fountain. There are a lot of pennies in it.)", "* (One of them is a Jack in the Box token.\n*  ...No. It's just a penny. You looked twice.)"])


func _outfield_wall() -> void:
	await Game.dialogue.say(["* (The outfield wall. 400 FEET, it says.)", "* (Someone scratched something into the padding,\n*  low down: R + H.)"])


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
	if id in ["big_screen", "corps_supreme"]:
		Game.battle_result = {}
	match id:
		"big_screen":
			await run_cutscene(_after_screen.bind(spared))
			return
		"corps_supreme":
			await run_cutscene(_after_supreme)
			return
	if await handle_person_return():
		return
	if not flag("dt_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked() or _engaged:
		return
	if not _inside():
		check_random_encounter(SCENE)
		return
	# With Hop: Supreme is waiting at home plate.
	if _genocide() and supreme and is_instance_valid(supreme) and player.position.distance_to(supreme.position) < 80.0:
		run_cutscene(_confront_supreme)
		return
	# Out on the mound, the Big Screen notices you.
	if not flag("dt_screen_done") and player.position.distance_to(MOUND) < 36.0:
		if _genocide() and supreme and is_instance_valid(supreme):
			return
		run_cutscene(_wake_screen)


func _arrival() -> void:
	Game.flags["dt_arrived"] = true
	await Game.dialogue.say([
		"* (Downtown. Tall buildings, gaslamps, a trolley\n*  ringing its bell somewhere down the street.)",
		"* (At the end of the street: the ballpark.\n*  No game tonight. But the lights are on.)",
		"* (Over the wall, the Big Screen is flickering.\n*  It's showing the same thing over and over.)",
	])
	match _route():
		"pacifist":
			await Game.dialogue.say([{"who": "Supreme", "text": "(over the phone) I'm already inside. Dugout.\nBring snacks. Statistically, you won't.", "mood": "smug"}])
			Game.set_objective("Find the fragment. (The ballpark. Supreme's inside.)")
		"neutral":
			Game.set_objective("Find the fragment. (The ballpark?)")
		_:
			await Game.dialogue.say([
				{"who": "Hop", "text": "...Supreme's in there. I can see him on the screen.\nHe's just standing at home plate. Doing math.", "mood": "sad"},
				{"who": "Hop", "text": "He always does math when he's scared.", "mood": "sad"},
				{"who": "Relic", "tag": "", "face": false, "text": "* Let him count."},
			])
			Game.set_objective("...")


func _ballpark_gate() -> void:
	Game.play_sfx("door")
	await go_through_door(INSIDE_ENTRY)
	fit_camera_to_room()
	_play_music_here()
	if flag("dt_inside"):
		return
	Game.flags["dt_inside"] = true
	await Game.dialogue.say([
		"* (The ballpark. Forty thousand empty seats.)",
		"* (Over the outfield wall, the Big Screen is on.\n*  HOME 0, VISITORS 0. IS ANYONE THERE?)",
	])
	if not _genocide():
		Game.set_objective("Walk out to the pitcher's mound.")


func _leave_ballpark() -> void:
	Game.play_sfx("door")
	await go_through_door(OUTSIDE_GATE)
	fit_camera_to_room()
	_play_music_here()


func _wake_screen() -> void:
	if _engaged:
		return
	_engaged = true
	await Game.dialogue.say([
		"* (You step onto the mound.)",
		"* (Every light in the stadium snaps on at once.)",
		"* (The Big Screen shows you. Huge. From above.\n*  PLAYER ONE!! it says. PLAYER ONE!!!)",
		"* (A red light is glowing behind the screen.\n*  The fragment.)",
	])
	if _route() == "pacifist" and supreme:
		await Game.dialogue.say([{"who": "Supreme", "text": "(from the dugout) Here it comes!\nI'll call them! Just DODGE!", "mood": "shocked"}])
	await Game.start_battle("big_screen", SCENE, MOUND + Vector2(0, 30))


func _after_screen(spared: bool) -> void:
	Game.flags["dt_screen_done"] = true
	if spared:
		await Game.dialogue.say([
			"* (The Big Screen shows: THANK YOU, [CROWD]!)",
			"* (Then a replay. Of you, doing the wave, alone,\n*  in an empty stadium. It plays it again. And again.)",
			"* (It's the happiest thing it's shown in five years.)",
			"* (Something red drops out of the back of the\n*  scoreboard and rolls all the way to the mound.)",
		])
	else:
		Game.flags["dt_screen_killed"] = true
		await Game.dialogue.say([
			"* (The Big Screen goes dark. Every bulb, one by one,\n*  left to right, like a wave going the wrong way.)",
			"* (One pixel stays lit. Red. It falls out of the\n*  screen and rolls to the mound.)",
		])
		if _genocide():
			await Game.dialogue.say([{"who": "Relic", "tag": "", "face": false, "text": "* Game over."}])
	Game.play_sfx("fragment")
	await Game.dialogue.say([
		"* (You pick it up. It's warm, and it hums.)",
		"* (You got the seventh FRAGMENT.)",
	])
	Game.flags["dt_fragment"] = true
	Game.flags["has_fragment_7"] = true
	Game.flags["fragments"] = maxi(int(Game.flags.get("fragments", 6)), 7)
	Game.set_objective("..." if _genocide() else "7 of 12 FRAGMENTS.")
	await Game.dialogue.say(["* (The fragment is warm in your hand.\n*  You close your eyes.)"])
	await Game.play_keepsakes([7], SCENE, player.position, [
		"* (A boy screaming in an empty ballpark. A token,\n*  taking it all.)",
		"* (A Jack in the Box curly-fry token. Good for one\n*  free curly fries. Relic wore it on a cord.)",
		"* (It held Hop's nightmares.)",
		"* (...What's it holding now?)",
	])


## Back from the memory: with the Corps, the 0.4%.
func _after_memory() -> void:
	match _route():
		"pacifist":
			if not supreme or flag("dt_odds"):
				return
			Game.flags["dt_odds"] = true
			await supreme.walk_to(player.position + Vector2(30, 0), 80.0)
			supreme.face(player.position - supreme.position)
			await Game.dialogue.say([
				{"who": "Supreme", "text": "Seven. That's more than half.\nWhich means I have to tell you something.", "mood": ""},
				{"who": "Supreme", "text": "I ran the numbers. On the end of this.\nOn us, against Hopkuna.", "mood": ""},
				{"who": "Supreme", "text": "0.4%.", "mood": "sad"},
				"* (He lets it sit there.)",
				{"who": "Supreme", "text": "Statistically, I should leave.\nEveryone sane would leave.", "mood": "sad"},
				{"who": "Supreme", "text": "Emotionally, I'm staying.", "mood": ""},
				{"who": "Supreme", "text": "...I didn't know I had that column.", "mood": "happy"},
			])
			Game.set_objective("7 of 12. Next: the Harbor. (Take the bus.)")
		"neutral":
			if supreme:
				await Game.dialogue.say([
					{"who": "Supreme", "text": "Huh.", "mood": "shocked"},
					{"who": "Supreme", "text": "Updating my model. You're 23% more\ndecent than I predicted.", "mood": "smug"},
					{"who": "Supreme", "text": "...Don't let it go to your head.\nIt's still under half.", "mood": ""},
				])
			Game.set_objective("7 of 12. Next: the Harbor. (Take the bus.)")


func _bus_stop() -> void:
	await ride_bus(SCENE)


# --- With Hop: Supreme ------------------------------------------------------------

func _confront_supreme() -> void:
	if not supreme or not is_instance_valid(supreme) or _engaged:
		return
	_engaged = true
	supreme.face(player.position - supreme.position)
	await Game.dialogue.say([
		{"who": "Supreme", "text": "Don't come closer. I'm computing.", "mood": ""},
		{"who": "Supreme", "text": "Crayola. N.C. Big Joe. Nat.\nFour for four. I've plotted it.", "mood": "sad"},
		{"who": "Supreme", "text": "The line goes one way, Elric.\nThere's no outlier. I checked. Twice.", "mood": "sad"},
		{"who": "Hop", "text": "Supreme, RUN. You said it yourself,\nthe numbers say RUN-", "mood": "sad"},
		{"who": "Supreme", "text": "The numbers say a lot of things, Hop.", "mood": ""},
		{"who": "Supreme", "text": "...I didn't know I had that column.", "mood": "sad"},
	])
	await Game.start_battle("corps_supreme", SCENE, player.position)


func _after_supreme() -> void:
	if supreme:
		supreme.queue_free()
		supreme = null
	var kept: Array = Game.flags.get("mementos", [])
	if not "Spreadsheet Printout" in kept:
		kept.append("Spreadsheet Printout")
	Game.flags["mementos"] = kept
	await Game.dialogue.say([
		"* (A printout blows across home plate.\n*  A spreadsheet. Twelve rows. Four are crossed out.)",
		"* (At the bottom, circled twice, in pen: 0.4%.\n*  And under it, smaller: STAYING ANYWAY.)",
		"* (You keep it.)",
		"* (On the Big Screen, the replay shows Hop.\n*  He's sitting in the stands with his head down.)",
		{"who": "Relic", "tag": "", "face": false, "text": "* Five."},
	])
	Game.set_objective("...")
	_engaged = false
