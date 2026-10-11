extends Area
## Mission Beach (fragment 4): the boardwalk, the sand, the ocean, and the Dipper,
## an old wooden roller coaster that's been running all night with nobody on it.
## Reached by bus from the PQ Mall, after the choice on Westview Field.
##
## Crayola and N.C. Wethan are here (they swim here). What happens with them
## depends on the path:
##   Corps      they're on the mission with you; Crayola opens up, and gives
##              Elric his card (the Seven of Hearts) after the Dipper.
##   Own way    they're here for the fragment too; you get it first.
##   With Hop   they're waiting for you on the sand, and they have to die
##              (beach_battles.gd). The gate stays shut until they're gone.
##
## Story flags: mb_arrived, mb_talked_crayola, mb_talked_wethan, beat_dipper
## (set by Game), mb_fragment, has_fragment_4.

const SCENE := "res://scenes/mission_beach.tscn"
const MALL_SCENE := "res://scenes/pq_mall.tscn"
const T := Room.TILE
## Where the bus lets you off (the east end of the boardwalk).
const ENTRY := Vector2(60 * T, 6 * T + 10)
## The coaster's gate on the boardwalk.
const GATE := Vector2(9 * T + 10, 6 * T)
const CRAYOLA_SPOT := Vector2(26 * T, 12 * T)
## The beach, and the arcade on the boardwalk (its own room on the map).
const OUTSIDE := Rect2i(0, 0, 64, 30)
const ARCADE := Rect2i(2, 32, 24, 18)
const ARCADE_DOOR := Vector2(49 * T + 10, 4 * T + 4)
const OUTSIDE_ARCADE := Vector2(49 * T + 10, 5 * T + 6)
const ARCADE_ENTRY := Vector2(13 * T + 10, 47 * T + 6)
const ARCADE_EXIT := Vector2(13 * T + 10, 49 * T - 2)
## Where the arcade's machines stand (the spot in front of each).
const MEMORY_SPOT := Vector2(6 * T, 36 * T + 10)
const SKEE_SPOT := Vector2(11 * T, 38 * T + 10)
const STICKER_SPOT := Vector2(13 * T + 10, 36 * T + 10)
const FORTUNE_SPOT := Vector2(18 * T, 36 * T + 10)
const COUNTER_SPOT := Vector2(21 * T + 10, 44 * T + 10)
## Tickets: one strip from each machine. Three get the Dipper's key.
const TICKET_FLAGS := ["mb_t_memory", "mb_t_skee", "mb_t_fortune"]
const WETHAN_SPOT := Vector2(30 * T, 14 * T)

var partner: Character
var crayola: Character
var wethan: Character
var _decor: Node2D
var _font: Font
## A fight is starting: don't start it again during the fade.
var _engaged: bool = false


func _ready() -> void:
	rooms.assign([_px(OUTSIDE), _px(ARCADE)])
	setup_area(ENTRY)
	_dress()
	add_wild_encounters(SCENE, Rect2(0, 8 * T, room.pixel_size().x, 12 * T))
	_font = ThemeDB.fallback_font
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	Game.play_music("beach")
	_place_people()
	world.add_child(Hotspot.create(ENTRY + Vector2(10, -8), _bus_stop))
	world.add_child(Hotspot.create(GATE + Vector2(0, -2), _coaster_gate))
	for spot in [[ARCADE_DOOR, _enter_arcade], [ARCADE_EXIT, _leave_arcade], [MEMORY_SPOT, _memory_machine], [SKEE_SPOT, _skee_ball],
			[STICKER_SPOT, _skee_sticker], [FORTUNE_SPOT, _fortune_teller], [COUNTER_SPOT, _prize_counter]]:
		world.add_child(Hotspot.create(spot[0], spot[1]))
	add_static_layer(_draw_arcade)
	fit_camera_to_room()
	_start.call_deferred()


static func _px(r: Rect2i) -> Rect2:
	return Rect2(r.position * T, r.size * T)


func _genocide() -> bool:
	return Game.on_genocide_route()


# --- The map -----------------------------------------------------------------------

## Set dressing (props.gd): towels and a sandcastle and a cooler on the sand, a
## lifeguard tower, a rowboat pulled up, buoys bobbing; a sno-cone cart and bikes
## on the boardwalk.
func _dress() -> void:
	add_dressing([
		["towel", Vector2(7 * T, 12 * T), {"color": Color8(60, 120, 200), "walkable": true}],
		["cooler", Vector2(9 * T + 6, 13 * T + 4), {"look": ["* (A cooler. Inside: juice boxes, one sandwich,
*  and a crab that is NOT supposed to be in there.)"]}],
		["towel", Vector2(43 * T, 13 * T), {"color": Color8(220, 70, 70), "walkable": true}],
		["towel", Vector2(45 * T, 13 * T), {"color": Color8(240, 200, 60), "walkable": true}],
		["sandcastle", Vector2(16 * T, 17 * T), {"look": ["* (A sandcastle, with a moat and a flag.
*  A very small sign says: KING CRAB'S CASTLE. KEEP OUT.)"]}],
		["lifeguard", Vector2(36 * T, 15 * T), {"look": ["* (The lifeguard tower. Nobody's on duty.
*  A sign says: SWIM AT YOUR OWN RISK. SERIOUSLY.)"]}],
		["rowboat", Vector2(55 * T, 18 * T + 6), {"color": Color8(200, 200, 205), "look": ["* (A rowboat, pulled up on the sand. Painted on the
*  side: S.S. NOT TODAY.)"]}],
		["buoy", Vector2(10 * T, 23 * T), {"walkable": true}],
		["buoy", Vector2(30 * T, 25 * T), {"walkable": true}],
		["buoy", Vector2(48 * T, 22 * T + 10), {"walkable": true}],
		["food_cart", Vector2(42 * T, 5 * T + 14), {"color": Color8(80, 170, 220), "text": "SNO CONE", "look": ["* (A sno-cone cart. Flavors: CHERRY, BLUE,
*  and MYSTERY. Mystery is also blue.)"]}],
		["bike_rack", Vector2(52 * T, 5 * T + 14), {"color": Color8(240, 200, 60), "look": ["* (A bike rack. One beach cruiser, covered in
*  stickers. Most of them say ALOHA.)"]}],
		["trash_can", Vector2(30 * T, 7 * T + 16)],
		["trash_can", Vector2(48 * T, 7 * T + 16)],
	])


func build_map() -> void:
	room.setup(64, 52, Room.SAND)
	# Shops along the top: a surf shop, a taco stand, an arcade.
	room.fill(0, 0, 64, 1, Room.ROOF)
	room.fill(18, 0, 46, 1, Room.ROOF)
	room.fill(18, 1, 46, 3, Room.STUCCO)
	room.set_meta("displays", [[Rect2i(22, 2, 2, 2), "surf"], [Rect2i(34, 2, 2, 2), "taco"], [Rect2i(46, 2, 2, 2), "arcade"], [Rect2i(56, 2, 2, 2), "icecream"]])
	for x in [22, 34, 46, 56]:
		room.fill(x, 2, 2, 2, Room.GLASS)
		room.set_tile(x + 3, 3, Room.DOOR)
	# The Dipper: the wooden coaster, behind a fence at the west end.
	room.fill(0, 0, 18, 5, Room.PROP)
	room.fill(0, 5, 1, 15, Room.FENCE)
	# The boardwalk.
	room.fill(1, 4, 63, 1, Room.SIDEWALK)
	room.fill(1, 5, 63, 3, Room.BOARDWALK)
	# Palms on the sand, and the ocean.
	for spot in [Vector2i(12, 10), Vector2i(20, 15), Vector2i(38, 11), Vector2i(50, 16), Vector2i(58, 10)]:
		room.set_tile(spot.x, spot.y, Room.PALM)
	room.fill(0, 20, 64, 10, Room.WATER)
	# Below the beach on the map: the arcade, inside. Dark carpet, machines along
	# the walls, the prize counter, the door back out to the boardwalk.
	room.fill(0, 30, 64, 22, Room.VOID)
	room.fill(ARCADE.position.x, ARCADE.position.y, ARCADE.size.x, ARCADE.size.y, Room.INTERIOR_WALL)
	room.fill(3, 35, 22, 14, Room.ARCADE_CARPET)
	room.set_tile(13, 49, Room.DOOR)
	room.fill(5, 35, 2, 1, Room.PROP)      # Memory Mania
	room.fill(10, 35, 2, 3, Room.PROP)     # Skee-Ball lanes
	room.fill(17, 35, 2, 1, Room.PROP)     # the fortune teller
	room.fill(19, 43, 5, 1, Room.PROP)     # the prize counter
	for y in [38, 40, 42, 44]:
		room.set_tile(3, y, Room.PROP)       # cabinets along the walls
		room.set_tile(24, y, Room.PROP)


## The Dipper's track: where the rail is, at each x along the coaster.
func _dipper_track(x: float) -> float:
	return 30.0 + sin(x * 0.045) * 22.0


func _draw_decor() -> void:
	# The Dipper: white wooden trestle, red track, the train at the top.
	Scenery.wooden_coaster(_decor, Rect2(0, 0, 18 * T, 5 * T), _dipper_track)
	# Its sign: a marquee with chasing lights.
	var sign_rect := Rect2(GATE + Vector2(-66, -64), Vector2(132, 26))
	Scenery.marquee(_decor, sign_rect, "THE DIPPER", Color8(200, 50, 45), Color8(250, 235, 200), Color8(250, 235, 200), "", true, (Time.get_ticks_msec() / 250) % 2 == 0)
	PixelFont.draw_centered(_decor, "SINCE 1925", Vector2(GATE.x, sign_rect.end.y + 6), 1.0, Color8(60, 40, 30))
	# The gate (a turnstile), glowing red until the fragment is gone.
	Scenery.turnstile(_decor, GATE + Vector2(0, -2))
	if not flag("mb_fragment"):
		_decor.draw_circle(GATE + Vector2(0, -26), 8.0, Color(0.9, 0.15, 0.2, 0.35))
	# The shops: awnings, painted signs.
	var shops := [[22, "SURF", Color8(60, 150, 200), Color8(250, 250, 250), "surf", Color8(60, 150, 200), Color8(250, 250, 250)],
		[34, "TACOS", Color8(240, 190, 60), Color8(120, 40, 30), "taco", Color8(220, 70, 50), Color8(250, 210, 90)],
		[46, "ARCADE", Color8(40, 30, 70), Color8(120, 240, 250), "arcade", Color8(140, 60, 200), Color8(40, 30, 70)],
		[56, "ICE CREAM", Color8(250, 200, 220), Color8(160, 60, 100), "cone", Color8(250, 160, 200), Color8(250, 250, 250)]]
	for shop in shops:
		var x: int = shop[0]
		Scenery.awning(_decor, Rect2(x * T - 6, 2 * T - 6, 5 * T + 4, 8), shop[5], shop[6])
		Scenery.shop_sign(_decor, Rect2(x * T - 12, 1 * T - 8, 6 * T + 4, 22), shop[1], shop[2], shop[3], shop[4])
	# Surfboards leaning by the surf shop; a menu board by the tacos.
	for k in 3:
		var at := Vector2(21 * T - 6 + k * 5, 3 * T + 18)
		_decor.draw_set_transform(at, -0.15, Vector2.ONE)
		_decor.draw_rect(Rect2(-2, -22, 5, 22), [Color8(250, 250, 250), Color8(240, 120, 90), Color8(90, 200, 220)][k])
		_decor.draw_rect(Rect2(0, -22, 1, 22), Color8(60, 60, 70))
		_decor.draw_set_transform(Vector2.ZERO)
	_decor.draw_rect(Rect2(33 * T - 4, 3 * T, 14, 18), Color8(40, 40, 46))
	_decor.draw_rect(Rect2(33 * T - 3, 3 * T + 1, 12, 16), Color8(30, 60, 40))
	for k in 4:
		_decor.draw_rect(Rect2(33 * T - 1, 3 * T + 4 + k * 3, 8, 1), Color8(220, 224, 214))
	# Crayola's duck pool float, and a couple of umbrellas.
	if not _genocide() or not flag("beat_corps_crayola"):
		Scenery.duck_float(_decor, CRAYOLA_SPOT + Vector2(-28, 8))
	Scenery.beach_umbrella(_decor, Vector2(16 * T, 12 * T), Color8(230, 80, 80), Color8(250, 250, 250))
	Scenery.beach_umbrella(_decor, Vector2(44 * T, 14 * T), Color8(60, 150, 210), Color8(250, 220, 90))
	# The bus stop.
	Scenery.bus_stop(_decor, ENTRY + Vector2(9, -8))


# --- People ----------------------------------------------------------------------

func _place_people() -> void:
	if not Game.walking_alone():
		partner = Cast.make(Game.partner())
		add_character(partner, player.position + Vector2(-20, 0))
		partner.follow = player
	# Crayola and N.C. Wethan (unless one of them is the one coming along).
	if not (_genocide() and flag("beat_corps_crayola")) and Game.partner() != "Crayola":
		crayola = add_npc("Crayola", CRAYOLA_SPOT, _talk_crayola)
	if not (_genocide() and flag("beat_corps_ncwethan")) and Game.partner() != "NCWethan":
		wethan = add_npc("NCWethan", WETHAN_SPOT, _talk_wethan)


func _talk_crayola() -> void:
	if _genocide():
		await _confront()
		return
	if Game.flags.get("route", "") == "pacifist":
		await chat("mb_crayola", [
			{"who": "Crayola", "text": "Oh! Hi. You came.", "mood": "happy"},
			{"who": "Crayola", "text": "We swim here. Me and N.C.\nWell. I swim. He... floats. Loudly.", "mood": ""},
			{"who": "Crayola", "text": "The Dipper's been running since last night.\nNobody's on it. It just goes around.", "mood": "sad"},
			{"who": "Crayola", "text": "I think the fragment's in the front car.\nIt glows when it goes by.", "mood": ""},
			{"who": "Crayola", "text": "...I don't really like roller coasters.\nBut I'll wave at you from the bottom.", "mood": "happy"},
		], [[{"who": "Crayola", "text": "I'll wave. Promise.", "mood": "happy"}]])
		Game.flags["mb_talked_crayola"] = true
		Game.set_objective("Ride the Dipper. (The gate on the boardwalk.)")
	else:
		await chat("mb_crayola_n", [
			{"who": "Crayola", "text": "Oh. Elric. Hi.", "mood": "shocked"},
			{"who": "Crayola", "text": "We're... here for the fragment too.\nFor the Corps. Sorry.", "mood": "sad"},
			{"who": "Crayola", "text": "N.C. says we have to race you.\nI'm not very fast.", "mood": "sad"},
		], [[{"who": "Crayola", "text": "...We still have a spot. On the team.\nIf you ever want it.", "mood": "sad"}]])


func _talk_wethan() -> void:
	if _genocide():
		await _confront()
		return
	if Game.flags.get("route", "") == "pacifist":
		await chat("mb_wethan", [
			{"who": "NCWethan", "text": "ELRIC!!! BEACH DAY!!!", "mood": "happy"},
			{"who": "NCWethan", "text": "I can't really swim. Lightning and water.\nI CONDUCT. IT'S A WHOLE THING.", "mood": "happy"},
			{"who": "NCWethan", "text": "Crayola swims for both of us.\nHe's really good. He doesn't tell anybody.", "mood": ""},
			{"who": "NCWethan", "text": "GO GET THAT COASTER!! I'D COME BUT\nI'D ELECTROCUTE THE WHOLE TRACK!!", "mood": "happy"},
		], [[{"who": "NCWethan", "text": "KING ME!!! ...wait wrong game.", "mood": "happy"}]])
	else:
		await chat("mb_wethan_n", [
			{"who": "NCWethan", "text": "HEY!! LONE WOLF!!", "mood": "happy"},
			{"who": "NCWethan", "text": "RACE YOU TO THE COASTER!!\n...Actually Crayola's slow. Head start. Go.", "mood": "smug"},
		], [[{"who": "NCWethan", "text": "THIS IS A RACE!! WHY ARE YOU TALKING TO ME!!", "mood": "angry"}]])


# --- Story ------------------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if not is_inside_tree():
		return
	var id := str(Game.battle_result.get("id", ""))
	if id == "dipper":
		var spared: bool = not Game.battle_result.get("spared", []).is_empty()
		Game.battle_result = {}
		await run_cutscene(_after_dipper.bind(spared))
		return
	if id == "corps_crayola":
		Game.battle_result = {}
		await run_cutscene(_after_crayola)
		return
	if id == "corps_ncwethan":
		Game.battle_result = {}
		await run_cutscene(_after_wethan)
		return
	if not flag("mb_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked() or _engaged:
		return
	check_random_encounter(SCENE)
	# Going with Hop: get close, and they're waiting for you.
	if _genocide() and crayola and is_instance_valid(crayola) and player.position.distance_to(crayola.position) < 70.0:
		run_cutscene(_confront)


func _arrival() -> void:
	Game.flags["mb_arrived"] = true
	await Game.dialogue.say([
		"* (Mission Beach. Salt air, a boardwalk,\n*  and the ocean, going on forever.)",
		"* (At the end of the boardwalk, an old wooden\n*  roller coaster rattles around its track.)",
		"* (Nobody is on it.)",
	])
	match Game.flags.get("route", ""):
		"pacifist":
			await Game.dialogue.say([
				"* (Crayola and N.C. Wethan are down on the sand.)",
			])
			Game.set_objective("Find the fragment. (Crayola and N.C. are on the sand.)")
		"neutral":
			await Game.dialogue.say([
				"* (Down on the sand: Crayola and N.C. Wethan.\n*  The Corps got here first.)",
			])
			Game.set_objective("Get to the fragment before the Corps does.")
		_:
			await Game.dialogue.say([
				{"who": "Hop", "text": "...They're here. Crayola. N.C.", "mood": "sad"},
				{"who": "Hop", "text": "Elric. We can just- we can go around.\nWe can come back later.", "mood": "sad"},
				{"who": "Relic", "tag": "", "face": false, "text": "* We don't go around."},
			])
			Game.set_objective("...")


# --- The arcade ------------------------------------------------------------------------

func _enter_arcade() -> void:
	Game.play_sfx("door")
	await go_through_door(ARCADE_ENTRY)
	if not flag("mb_arcade_seen"):
		Game.flags["mb_arcade_seen"] = true
		await Game.dialogue.say([
			"* (The arcade. Carpet that glows under the black\n*  lights, a hundred machines beeping at nobody.)",
			"* (Behind the prize counter, on a hook, under a sign\n*  that says TOP PRIZE: a big brass key. DIPPER.)",
		])
		if _genocide():
			await Game.dialogue.say([{"who": "Relic", "tag": "", "face": false, "text": "* Tickets for a key.\n* Everything's for sale if you play long enough."}])
		if not flag("mb_key"):
			Game.set_objective("Win the Dipper's key. (3 ticket strips.)")


func _leave_arcade() -> void:
	Game.play_sfx("door")
	await go_through_door(OUTSIDE_ARCADE)


func _tickets() -> int:
	var n := 0
	for f in TICKET_FLAGS:
		if flag(f):
			n += 1
	return n


func _win_tickets(which: String) -> void:
	Game.flags[which] = true
	Game.play_sfx("save")
	await Game.dialogue.say(["* (DING DING DING. A strip of tickets comes curling out\n*  of the machine. %d of 3.)" % _tickets()])
	if _tickets() >= 3 and not flag("mb_key"):
		Game.set_objective("Trade your tickets at the prize counter.")


## MEMORY MANIA: five lights flash, then you press them back in the same order.
func _memory_machine() -> void:
	if flag("mb_t_memory"):
		await Game.dialogue.say(["* (MEMORY MANIA. HIGH SCORE: YOU.)"])
		return
	var colors := ["RED", "BLUE", "GREEN", "YELLOW"]
	var sequence: Array = []
	for k in 5:
		sequence.append(colors[randi() % 4])
	var play := await Game.dialogue.ask("* (MEMORY MANIA! Watch the lights, then press\n*  them in the same order. One token.)", ["Play", "Not now"])
	if play != 0:
		return
	await Game.dialogue.say(["* (The lights flash: " + ", ".join(sequence) + ".)", "* (...Then it goes dark, and waits.)"])
	for k in sequence.size():
		var pick := await Game.dialogue.ask("* (Press light %d of %d.)" % [k + 1, sequence.size()], colors)
		if colors[pick] != sequence[k]:
			Game.play_sfx("miss")
			await Game.dialogue.say(["* (BZZZT. The lights flash red.\n*  TRY AGAIN!)"])
			return
	await _win_tickets("mb_t_memory")


## The sticker on the side of the Skee-Ball machine (the trick to it).
func _skee_sticker() -> void:
	await Game.dialogue.say([
		"* (A sticker on the side of the Skee-Ball machine,\n*  in somebody's angry handwriting:)",
		"* (\"THE ONE THAT GLOWS NEVER PAYS. THE ONE THAT\n*  PAYS IS ALWAYS THE ONE TO ITS LEFT.\")",
	])


## SKEE-BALL: one hole glows; the one that pays is the one to its left.
func _skee_ball() -> void:
	if flag("mb_t_skee"):
		await Game.dialogue.say(["* (Skee-Ball. You've beaten it.\n*  It seems sulky about it.)"])
		return
	var holes := ["10", "20", "50", "100"]
	var glowing := 1 + randi() % 3
	var play := await Game.dialogue.ask("* (SKEE-BALL. The %s hole is glowing.\n*  Where do you roll?)" % holes[glowing], holes + ["Not now"])
	if play == holes.size():
		return
	if play == glowing - 1:
		await _win_tickets("mb_t_skee")
	elif play == glowing:
		Game.play_sfx("miss")
		await Game.dialogue.say(["* (Right in the glowing hole! ...Zero tickets.\n*  Of course. The glowing one never pays.)"])
	else:
		Game.play_sfx("miss")
		await Game.dialogue.say(["* (Clunk. Nothing. The machine blinks smugly.)"])


## THE GREAT ZALDO: a fortune teller in a glass booth, with a riddle.
func _fortune_teller() -> void:
	if flag("mb_t_fortune"):
		await Game.dialogue.say(["* (The Great Zaldo nods at you. \"YOUR FUTURE:\n*  A ROLLER COASTER.\" He's very proud of that.)"])
		return
	await Game.dialogue.say([
		"* (THE GREAT ZALDO, in his glass booth. His eyes light up.)",
		"* \"ANSWER ME THIS, TRAVELER:\"",
		"* \"I CLIMB AND I CLIMB AND YOU PAY FOR THE RIDE.\n*  THEN I DROP YOU, AND YOU SCREAM, AND YOU SMILE.\"",
	])
	var pick := await Game.dialogue.ask("* \"WHAT AM I?\"", ["A Ferris wheel", "The Dipper", "An elevator", "Rent"])
	if pick == 1:
		await Game.dialogue.say(["* \"THE DIPPER! WISDOM IS YOURS!\"", "* (He spits out a ticket.\n*  It smells like popcorn.)"])
		await _win_tickets("mb_t_fortune")
	else:
		Game.play_sfx("miss")
		await Game.dialogue.say(["* \"NO. THINK, TRAVELER. WHAT CLIMBS, AND DROPS,\n*  AND RATTLES, RIGHT OUTSIDE?\""])


## The prize counter: three strips of tickets for the Dipper's key.
func _prize_counter() -> void:
	if flag("mb_key"):
		await Game.dialogue.say(["* (The prize counter. The hook where the key hung\n*  is empty. The rubber spiders are still for sale.)"])
		return
	if _tickets() < 3:
		await Game.dialogue.say([
			"* (The prize counter. Nobody's working it. A sign:\n*  HONOR SYSTEM. PLEASE BE HONORABLE.)",
			"* (The Dipper's key: 3 STRIPS. You have %d.)" % _tickets(),
		])
		return
	Game.play_sfx("fragment")
	Game.flags["mb_key"] = true
	_decor.queue_redraw()
	await Game.dialogue.say([
		"* (You leave all three strips on the counter, neatly,\n*  and take the brass key off its hook.)",
		"* (A tag on it: DIPPER. DO NOT LOSE. Someone\n*  has added: AGAIN.)",
	])
	Game.set_objective("Ride the Dipper. (The gate on the boardwalk.)")


func _draw_arcade(ci: CanvasItem) -> void:
	var f := ThemeDB.fallback_font
	# Memory Mania: a cabinet with four big colored lights.
	var mem := Rect2(5 * T, 34 * T, 2 * T, 2 * T)
	ci.draw_rect(Rect2(mem.position + Vector2(3, 4), mem.size), Color(0, 0, 0, 0.3))
	ci.draw_rect(mem, Color8(40, 30, 70))
	ci.draw_rect(Rect2(mem.position, Vector2(mem.size.x, 3)), Color8(90, 70, 150))
	var lights := [Color8(230, 60, 60), Color8(60, 120, 230), Color8(70, 200, 90), Color8(240, 210, 60)]
	for k in 4:
		ci.draw_circle(mem.position + Vector2(10 + (k % 2) * 20, 12 + (k / 2) * 14), 6.0, lights[k].darkened(0.3))
		ci.draw_circle(mem.position + Vector2(10 + (k % 2) * 20, 12 + (k / 2) * 14), 4.0, lights[k])
	ci.draw_string(f, mem.position + Vector2(1, -2), "MEMORY", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color8(240, 200, 255))
	# Skee-Ball: two long ramps and the target rings at the top.
	var skee := Rect2(10 * T, 34 * T, 2 * T, 4 * T)
	ci.draw_rect(Rect2(skee.position + Vector2(3, 4), skee.size), Color(0, 0, 0, 0.3))
	ci.draw_rect(skee, Color8(110, 74, 44))
	ci.draw_rect(Rect2(skee.position + Vector2(4, 30), Vector2(skee.size.x - 8, skee.size.y - 34)), Color8(150, 104, 62))
	for k in 3:
		ci.draw_arc(skee.position + Vector2(skee.size.x / 2, 14), 4.0 + k * 4, 0, TAU, 16, [Color8(240, 200, 60), Color8(230, 80, 60), Color8(60, 140, 220)][k], 2.0)
	ci.draw_string(f, skee.position + Vector2(2, -2), "SKEE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color8(255, 220, 120))
	ci.draw_rect(Rect2(13 * T + 2, 35 * T + 4, 10, 8), Color8(240, 230, 120))
	# The Great Zaldo, in his glass booth.
	var booth := Rect2(17 * T, 33 * T + 6, 2 * T, 2 * T + 14)
	ci.draw_rect(Rect2(booth.position + Vector2(3, 4), booth.size), Color(0, 0, 0, 0.3))
	ci.draw_rect(booth, Color8(120, 30, 60))
	ci.draw_rect(Rect2(booth.position + Vector2(4, 4), Vector2(booth.size.x - 8, 24)), Color8(60, 40, 80))
	ci.draw_circle(booth.position + Vector2(booth.size.x / 2, 16), 6.0, Color8(220, 180, 140))
	ci.draw_rect(Rect2(booth.position + Vector2(booth.size.x / 2 - 7, 7), Vector2(14, 5)), Color8(200, 40, 60))
	ci.draw_circle(booth.position + Vector2(booth.size.x / 2, 7), 2.0, Color8(240, 210, 80))
	ci.draw_rect(Rect2(booth.position + Vector2(booth.size.x / 2 - 3, 16), Vector2(2, 1)), Color8(60, 220, 120))
	ci.draw_rect(Rect2(booth.position + Vector2(booth.size.x / 2 + 1, 16), Vector2(2, 1)), Color8(60, 220, 120))
	ci.draw_line(booth.position + Vector2(6, 26), booth.position + Vector2(booth.size.x - 8, 6), Color(1, 1, 1, 0.25), 2.0)
	ci.draw_string(f, booth.position + Vector2(2, booth.size.y - 4), "ZALDO", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color8(250, 220, 100))
	# The prize counter: a glass case of prizes, the key's hook on the wall behind.
	var counter := Rect2(19 * T, 42 * T + 6, 5 * T, T + 14)
	ci.draw_rect(Rect2(counter.position + Vector2(3, 4), counter.size), Color(0, 0, 0, 0.3))
	ci.draw_rect(counter, Color8(90, 60, 40))
	ci.draw_rect(Rect2(counter.position + Vector2(3, 3), Vector2(counter.size.x - 6, 14)), Color8(150, 200, 230, 180))
	var prizes := [Color8(240, 90, 120), Color8(90, 200, 120), Color8(250, 220, 80), Color8(120, 120, 240), Color8(30, 30, 30)]
	for k in 9:
		ci.draw_circle(counter.position + Vector2(8 + k * 10, 11), 3.0, prizes[k % prizes.size()])
	ci.draw_string(f, counter.position + Vector2(10, -16), "TOP PRIZE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color8(255, 220, 120))
	if not flag("mb_key"):
		ci.draw_rect(Rect2(counter.position + Vector2(24, -12), Vector2(12, 4)), Color8(220, 180, 70))
		ci.draw_circle(counter.position + Vector2(22, -10), 4.0, Color8(220, 180, 70))
		ci.draw_circle(counter.position + Vector2(22, -10), 2.0, Color8(60, 40, 30))
	# Cabinets along the walls, their screens glowing.
	var screens := [Color8(80, 220, 240), Color8(240, 100, 200), Color8(120, 240, 120), Color8(250, 200, 80)]
	for k in 4:
		for x in [3, 24]:
			var cab := Rect2(x * T + 2, [38, 40, 42, 44][k] * T - 12, T - 4, T + 10)
			ci.draw_rect(Rect2(cab.position + Vector2(2, 3), cab.size), Color(0, 0, 0, 0.3))
			ci.draw_rect(cab, Color8(30, 30, 46))
			ci.draw_rect(Rect2(cab.position + Vector2(2, 3), Vector2(cab.size.x - 4, 10)), screens[(k + x) % 4])
			ci.draw_rect(Rect2(cab.position + Vector2(4, 16), Vector2(2, 2)), Color8(230, 60, 60))
			ci.draw_rect(Rect2(cab.position + Vector2(9, 16), Vector2(2, 2)), Color8(60, 120, 230))


func _bus_stop() -> void:
	await ride_bus(SCENE)


func _coaster_gate() -> void:
	if flag("mb_fragment"):
		await Game.dialogue.say(["* (The Dipper sits quietly at the gate.)", "* (It's just a roller coaster again.)"])
		return
	if _genocide() and (not flag("beat_corps_crayola") or not flag("beat_corps_ncwethan")):
		await Game.dialogue.say(["* (Crayola and N.C. Wethan are watching you\n*  from the sand.)"])
		return
	if not flag("mb_key"):
		await Game.dialogue.say([
			"* (The gate's padlocked. A sign on it: OPERATOR ON\n*  BREAK. KEY = TOP PRIZE AT THE ARCADE.)",
			"* (The front car, behind the gate, is glowing red.)",
		])
		Game.set_objective("Win the Dipper's key. (The arcade, on the boardwalk.)")
		return
	var ride := await Game.dialogue.ask("* (The Dipper rolls up to the gate.\n*  The front car is glowing red. Get on?)", ["Ride", "Not yet"])
	if ride != 0:
		return
	await Game.dialogue.say([
		"* (You climb into the front car. The lap bar\n*  comes down by itself.)",
		"* (CLACK. CLACK. CLACK.)",
	])
	await Game.start_battle("dipper", SCENE, player.position)


## After the Dipper: it comes to a stop, and the fragment comes out of the front car.
func _after_dipper(spared: bool) -> void:
	Game.flags["mb_fragment"] = true
	_decor.queue_redraw()
	if spared:
		await Game.dialogue.say([
			"* (The Dipper rolls back into the gate,\n*  slow and happy, and stops.)",
			"* (For the first time all night, it's quiet.)",
		])
	else:
		await Game.dialogue.say(["* (The front car is just splinters now.)"])
	Game.play_sfx("fragment")
	await Game.dialogue.say([
		"* (Something red floats up out of the front car.)",
		"* (You take it. It's warm, and it hums.)",
		"* (You got the fourth FRAGMENT.)",
	])
	Game.flags["has_fragment_4"] = true
	Game.flags["fragments"] = maxi(int(Game.flags.get("fragments", 3)), 4)
	var after: Array = []
	match Game.flags.get("route", ""):
		"pacifist":
			if crayola:
				await crayola.walk_to(player.position + Vector2(-26, 8), 120.0)
			await Game.dialogue.say([
				{"who": "Crayola", "text": "You did it! I waved. Did you see me wave?", "mood": "happy"},
				{"who": "Crayola", "text": "...Here. I want you to have this.", "mood": ""},
				"* (The Seven of Hearts. The card from his trick\n*  at the mall. On the back, in crayon: \"for Elric\".)",
				{"who": "Crayola", "text": "It was your card. It's still your card.", "mood": "happy"},
			])
			await _give_card()
		"neutral":
			await Game.dialogue.say([
				"* (Crayola and N.C. Wethan come running up the\n*  boardwalk. Too late.)",
				{"who": "NCWethan", "text": "NO FAIR!!! YOU HAD A HEAD START!!!", "mood": "angry"},
				{"who": "NCWethan", "text": "...I GAVE you the head start. That's on me.", "mood": "sad"},
				{"who": "Crayola", "text": "...You got it first. That's okay.\nBe careful with it.", "mood": "sad"},
			])
	after = [
		"* (The ocean. A boy in a fedora teaching someone\n*  to bodysurf. Badly.)",
		"* (Laughing so hard you swallow half the Pacific.)",
	]
	Game.set_objective("4 of 12. (Nassan's map: Balboa Park. Take the bus.)")
	await Game.dialogue.say(["* (The fragment is warm in your hand.\n*  You close your eyes.)"])
	await Game.play_keepsakes([4], SCENE, player.position, after)


## Crayola's card, into the bag (or the storage box, if the bag is full).
func _give_card() -> void:
	var card := {"name": "Seven of Hearts", "heal": 0, "slot": "card", "price": 0}
	Game.play_sfx("item")
	if Game.items.size() < Game.MAX_ITEMS:
		Game.items.append(card)
		await Game.dialogue.say(["* (You put the Seven of Hearts in your bag.\n*  It goes in the Card slot.)"])
	else:
		Game.box_items.append(card)
		await Game.dialogue.say(["* (Your bag is full. The Seven of Hearts goes\n*  in the storage box, for safekeeping.)"])


# --- Going with Hop -----------------------------------------------------------------

## Crayola and N.C. Wethan are waiting on the sand.
func _confront() -> void:
	if not crayola or not is_instance_valid(crayola) or _engaged:
		return
	_engaged = true
	crayola.face(player.position - crayola.position)
	await Game.dialogue.say([
		{"who": "Crayola", "text": "...Elric? Is that... you?", "mood": "shocked"},
		{"who": "NCWethan", "text": "CRAYOLA. GET BEHIND ME.", "mood": "angry"},
		{"who": "Crayola", "text": "No. I want to talk to them.", "mood": "sad"},
		{"who": "Crayola", "text": "You remember my trick, right? At the mall?\nI still have the deck.", "mood": "sad"},
	])
	await Game.start_battle("corps_crayola", SCENE, player.position)


func _after_crayola() -> void:
	if crayola:
		crayola.queue_free()
		crayola = null
	_keep("Seven of Hearts")
	await Game.dialogue.say([
		"* (The cards blow down the beach.\n*  Every one of them is the Seven of Hearts.)",
		"* (You keep one.)",
	])
	if wethan:
		await wethan.walk_to(CRAYOLA_SPOT, 90.0)
		wethan.face(player.position - wethan.position)
	await Game.dialogue.say([
		{"who": "NCWethan", "text": "...", "mood": "sad"},
		{"who": "NCWethan", "text": "He was my best friend.", "mood": "sad"},
		{"who": "NCWethan", "text": "I'm not gonna hit you, Elric.\nI just want you to know I could have.", "mood": "sad"},
	])
	await Game.start_battle("corps_ncwethan", SCENE, player.position)


func _after_wethan() -> void:
	if wethan:
		wethan.queue_free()
		wethan = null
	_keep("Checker Piece")
	_decor.queue_redraw()
	await Game.dialogue.say([
		"* (Something small lands in the sand.\n*  A red checker piece.)",
		"* (You keep it.)",
		"* (Hop is staring at the water.\n*  He doesn't say anything.)",
		{"who": "Relic", "tag": "", "face": false, "text": "* The coaster is waiting for us."},
	])
	Game.set_objective("Ride the Dipper.")


## Something left behind, kept in the bag forever (Game.flags["mementos"]).
func _keep(thing: String) -> void:
	var kept: Array = Game.flags.get("mementos", [])
	if not thing in kept:
		kept.append(thing)
	Game.flags["mementos"] = kept
