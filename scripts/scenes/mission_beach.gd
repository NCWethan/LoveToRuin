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
const WETHAN_SPOT := Vector2(30 * T, 14 * T)

var partner: Character
var crayola: Character
var wethan: Character
var _decor: Node2D
var _font: Font


func _ready() -> void:
	setup_area(ENTRY)
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
	fit_camera_to_room()
	_start.call_deferred()


func _genocide() -> bool:
	return Game.on_genocide_route()


# --- The map -----------------------------------------------------------------------

func build_map() -> void:
	room.setup(64, 30, Room.SAND)
	# Shops along the top: a surf shop, a taco stand, an arcade.
	room.fill(0, 0, 64, 1, Room.ROOF)
	room.fill(18, 0, 46, 1, Room.ROOF)
	room.fill(18, 1, 46, 3, Room.STUCCO)
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


func _draw_decor() -> void:
	# The Dipper: a white wooden lattice, a red track rising over it, and a sign.
	var base := Vector2(0, 0)
	_decor.draw_rect(Rect2(base, Vector2(18 * T, 5 * T)), Color8(70, 60, 55))
	for k in 12:
		var x := 6.0 + k * 30.0
		_decor.draw_line(base + Vector2(x, 100), base + Vector2(x + 26, 4), Color8(235, 230, 220), 2.0)
		_decor.draw_line(base + Vector2(x + 26, 100), base + Vector2(x, 4), Color8(235, 230, 220), 2.0)
	var track := PackedVector2Array()
	for k in 37:
		var x := k * 10.0
		track.append(base + Vector2(x, 30 + sin(k * 0.45) * 22.0))
	_decor.draw_polyline(track, Color8(200, 50, 45), 4.0)
	var sign_rect := Rect2(GATE + Vector2(-46, -60), Vector2(92, 22))
	_decor.draw_rect(sign_rect, Color8(200, 50, 45))
	_decor.draw_rect(sign_rect, Color8(250, 235, 200), false, 2.0)
	_decor.draw_string(_font, sign_rect.position + Vector2(10, 15), "THE DIPPER", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(250, 235, 200))
	_decor.draw_string(_font, sign_rect.position + Vector2(18, 32), "since 1925", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(60, 40, 30))
	# The gate (a turnstile), glowing red until the fragment is gone.
	_decor.draw_rect(Rect2(GATE + Vector2(-14, -16), Vector2(28, 14)), Color8(120, 90, 60))
	if not flag("mb_fragment"):
		_decor.draw_circle(GATE + Vector2(0, -26), 8.0, Color(0.9, 0.15, 0.2, 0.35))
	# Shop signs.
	var shops := [[22, "SURF"], [34, "TACOS"], [46, "ARCADE"], [56, "ICE CREAM"]]
	for shop in shops:
		_decor.draw_string(_font, Vector2(shop[0] * T, 1 * T + 10), shop[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(80, 60, 50))
	# Crayola's duck pool float, and a couple of umbrellas.
	if not _genocide() or not flag("beat_corps_crayola"):
		_decor.draw_circle(CRAYOLA_SPOT + Vector2(-26, 10), 9.0, Color8(250, 210, 60))
		_decor.draw_circle(CRAYOLA_SPOT + Vector2(-32, 2), 4.0, Color8(250, 210, 60))
		_decor.draw_rect(Rect2(CRAYOLA_SPOT + Vector2(-38, 1), Vector2(4, 2)), Color8(240, 140, 40))
	for spot in [Vector2(16 * T, 12 * T), Vector2(44 * T, 14 * T)]:
		_decor.draw_circle(spot, 16.0, Color8(230, 80, 80))
		_decor.draw_arc(spot, 16.0, 0, TAU, 16, Color8(250, 250, 250), 2.0)
		_decor.draw_line(spot, spot + Vector2(0, 18), Color8(120, 120, 120), 2.0)
	# The bus stop.
	_decor.draw_rect(Rect2(ENTRY + Vector2(8, -46), Vector2(3, 38)), Color8(150, 150, 156))
	_decor.draw_rect(Rect2(ENTRY + Vector2(0, -54), Vector2(20, 12)), Color8(40, 90, 190))
	_decor.draw_string(_font, ENTRY + Vector2(2, -44), "BUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)


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
	if is_blocked():
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


func _bus_stop() -> void:
	var go := await Game.dialogue.ask("* (The bus back to the PQ Mall?)", ["Ride", "Not now"])
	if go == 0:
		Game.play_sfx("door")
		await Game.change_scene(MALL_SCENE, Vector2(640, 545))


func _coaster_gate() -> void:
	if flag("mb_fragment"):
		await Game.dialogue.say(["* (The Dipper sits quietly at the gate.)", "* (It's just a roller coaster again.)"])
		return
	if _genocide() and (not flag("beat_corps_crayola") or not flag("beat_corps_ncwethan")):
		await Game.dialogue.say(["* (Crayola and N.C. Wethan are watching you\n*  from the sand.)"])
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
	Game.set_objective("4 of 12 FRAGMENTS. (The rest is still being written.)")
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
	if not crayola or not is_instance_valid(crayola):
		return
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
