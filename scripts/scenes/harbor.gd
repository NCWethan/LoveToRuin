extends Area
## The Harbor (fragment 8): the pier, gulls, a fish stand, and the old aircraft
## carrier, turned into a museum, as long as three city blocks. Up a gangway, the
## hangar deck (old planes, roped off); up the big elevator, the flight deck, where
## an old jet with no pilot has been running its engines every night for a week.
##
## Flight Deck (harbor_battles.gd) has the fragment in its cockpit. Its KEEPSAKE is
## this same deck at sunset, five years ago: "If you ever want him gone, I could
## try." Hop says no.
##
## Reached by bus (from any stop) once fragment 7 is found.
##
##   Corps      Agent and Eggo are on the pier (Agent calls the dodges in the
##              fight). Afterwards, everything changes: Agent works out that
##              breaking the fragments has been FEEDING Hopkuna. Hop tells Elric
##              everything, on the flight deck at night. Then the Corps votes on
##              whether to seal Hop away, and Elric speaks for him (their words, and
##              their BOND, decide the vote). However it falls, Hop leaves that
##              night: a note on the couch at the base.
##   Own way    Agent is at the gangway: Rock Paper Scissors for who goes up
##              first. Hop is on a bench on the pier. After this, the Corps' hatch
##              is locked: the offer stood. It doesn't anymore.
##   With Hop   Agent is waiting on the flight deck. The hardest fight in the game.
##
## Story flags: hb_arrived, hb_rps, hb_inside, hb_deck, hb_jet_done, hb_fragment,
## has_fragment_8, hb_feeding, hb_confession, hb_vote ("keep"/"seal"),
## hb_votes_keep, hb_vote_done, hb_hop_left (read the note, at the base).

const SCENE := "res://scenes/harbor.tscn"
const BASE_SCENE := "res://scenes/corps_base.tscn"
const T := Room.TILE
const OUTSIDE := Rect2i(0, 0, 60, 30)
const HANGAR := Rect2i(0, 32, 40, 20)
const DECK := Rect2i(0, 54, 60, 24)
## Where the bus lets you off (the east end of the promenade).
const ENTRY := Vector2(56 * T, 24 * T + 10)
## The gangway up into the carrier, and the hangar's door out.
const GANGWAY_TOP := Vector2(30 * T + 10, 10 * T + 4)
const OUTSIDE_GANGWAY := Vector2(30 * T + 10, 12 * T + 10)
const HANGAR_ENTRY := Vector2(20 * T + 10, 49 * T + 10)
const HANGAR_EXIT := Vector2(20 * T + 10, 51 * T - 2)
## The elevator between the hangar and the flight deck.
const LIFT_DOWN := Vector2(35 * T + 10, 36 * T + 10)
const LIFT_UP := Vector2(9 * T + 10, 66 * T + 10)
## The jet, at the far end of the deck, and where Agent stands (Genocide).
const JET_SPOT := Vector2(46 * T, 70 * T)
const AGENT_DECK := Vector2(30 * T, 68 * T)
## The pier: Agent and Eggo (Corps), Agent at the gangway (own way), Hop's bench.
const AGENT_PIER := Vector2(26 * T, 16 * T + 10)
const EGGO_PIER := Vector2(34 * T, 16 * T + 10)
const HOP_BENCH := Vector2(12 * T + 10, 23 * T + 2)
## Where everyone stands for the vote, in the hangar.
const VOTE_CENTER := Vector2(20 * T, 41 * T)

var partner: Character
var agent: Character
var eggo: Character
var hop: Character
var jet: Character
var _decor: Node2D
var _shade: Node2D
var _font: Font
var _time: float = 0.0
var _engaged: bool = false
var _from_memory: bool = false
## Night falls after the fragment (Corps): the deck goes dark.
var _night: bool = false


func _ready() -> void:
	_from_memory = not Game.keepsake_after.is_empty() and not Game.playing_relic
	_engaged = str(Game.battle_result.get("id", "")) in ["flight_deck", "corps_agent"]
	_night = flag("hb_feeding") and not flag("hb_vote_done")
	rooms.assign([_px(OUTSIDE), _px(HANGAR), _px(DECK)])
	setup_area(ENTRY)
	add_wild_encounters(SCENE, Rect2(T, 14 * T, 58 * T, 14 * T))
	_font = ThemeDB.fallback_font
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	_shade = Node2D.new()
	add_child(_shade)
	_shade.draw.connect(_draw_shade)
	_place_people()
	for spot in [[ENTRY + Vector2(10, -8), _bus_stop], [GANGWAY_TOP, _gangway], [HANGAR_EXIT, _leave_hangar],
			[LIFT_DOWN, _lift_up], [LIFT_UP, _lift_down], [Vector2(45 * T + 10, 26 * T + 4), _fish_stand],
			[Vector2(6 * T + 10, 26 * T + 4), _seal_statue], [Vector2(10 * T + 10, 36 * T + 4), _old_plane]]:
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


func _where() -> String:
	if player.position.y > 54 * T:
		return "deck"
	if player.position.y > 32 * T:
		return "hangar"
	return "outside"


func _play_music_here() -> void:
	if _where() == "outside" and not _night:
		Game.play_music("harbor")
	else:
		Game.stop_music(0.8)


func _process(delta: float) -> void:
	_time += delta
	_decor.queue_redraw()


# --- The map -----------------------------------------------------------------------

func build_map() -> void:
	room.setup(60, 78, Room.VOID)
	# Outside: the carrier's hull, the water, the pier, the promenade.
	room.fill(0, 0, 60, 30, Room.WATER)
	room.fill(6, 1, 50, 9, Room.WALL)
	room.set_tile(30, 9, Room.DOOR)
	room.fill(29, 10, 3, 4, Room.BOARDWALK)    # the gangway
	room.fill(0, 14, 60, 7, Room.BOARDWALK)    # the pier
	room.fill(0, 14, 29, 1, Room.FENCE)
	room.fill(32, 14, 28, 1, Room.FENCE)
	room.fill(0, 21, 60, 8, Room.SIDEWALK)     # the promenade
	room.fill(0, 29, 60, 1, Room.TREE)
	for x in [3, 16, 24, 38, 50]:
		room.set_tile(x, 22, Room.PALM)
	for spot in [Vector2i(11, 24), Vector2i(30, 24)]:
		room.fill(spot.x, spot.y, 3, 1, Room.BENCH)
	room.fill(44, 25, 3, 1, Room.PROP)          # the fish stand
	room.set_tile(6, 25, Room.PROP)             # the seal statue
	# The hangar deck: old planes, roped off; the elevator; the way out.
	room.fill(0, 32, 40, 20, Room.INTERIOR_WALL)
	room.fill(1, 34, 38, 17, Room.HALL_FLOOR)
	room.set_tile(20, 51, Room.DOOR)
	room.fill(8, 37, 5, 2, Room.PROP)
	room.fill(18, 38, 5, 2, Room.PROP)
	room.fill(8, 44, 5, 2, Room.PROP)
	room.fill(26, 44, 5, 2, Room.PROP)
	# The flight deck: the runway, the island tower, the sea all around.
	room.fill(0, 54, 60, 24, Room.WATER)
	room.fill(2, 56, 56, 20, Room.ASPHALT)
	room.fill(44, 57, 6, 6, Room.WALL)          # the island
	room.set_tile(47, 62, Room.DOOR)


func _draw_decor() -> void:
	# The carrier's hull: a number, portholes, the flight deck's edge overhead.
	_decor.draw_rect(Rect2(6 * T, 1 * T, 50 * T, 9 * T), Color8(110, 116, 128))
	_decor.draw_rect(Rect2(6 * T, 1 * T, 50 * T, 12), Color8(80, 84, 94))
	for x in range(8, 55, 3):
		_decor.draw_circle(Vector2(x * T + 10, 5 * T), 5.0, Color8(40, 44, 54))
		if (x * 7) % 5 == 0:
			_decor.draw_circle(Vector2(x * T + 10, 5 * T), 3.0, Color(1.0, 0.85, 0.5, 0.6))
	_decor.draw_string(_font, Vector2(14 * T, 8 * T), "41", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color8(230, 230, 236))
	_decor.draw_rect(Rect2(29 * T, 8 * T, 3 * T, 2 * T), Color8(60, 64, 74))
	_decor.draw_string(_font, Vector2(36 * T, 8 * T + 6), "MUSEUM - OPEN DAILY", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(240, 230, 200))
	# Glints on the water.
	for k in 30:
		var x := fmod(k * 83.0 + _time * 10.0, 60.0 * T)
		var y := 10 * T + 4 + (k % 4) * 18
		if y < 14 * T:
			_decor.draw_line(Vector2(x, y), Vector2(x + 10, y), Color(1, 1, 1, 0.3), 1.0)
	# The fish stand and the seal statue.
	_decor.draw_rect(Rect2(44 * T, 25 * T - 10, 3 * T, 30), Color8(70, 120, 170))
	_decor.draw_string(_font, Vector2(44 * T + 4, 25 * T + 2), "FISH", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	_decor.draw_circle(Vector2(6 * T + 10, 25 * T + 4), 9.0, Color8(130, 125, 120))
	_decor.draw_circle(Vector2(6 * T + 14, 25 * T - 4), 5.0, Color8(130, 125, 120))
	# The bus stop.
	_decor.draw_rect(Rect2(ENTRY + Vector2(8, -46), Vector2(3, 38)), Color8(150, 150, 156))
	_decor.draw_rect(Rect2(ENTRY + Vector2(0, -54), Vector2(20, 12)), Color8(40, 90, 190))
	_decor.draw_string(_font, ENTRY + Vector2(2, -44), "BUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	_draw_hangar()
	_draw_deck()


func _draw_hangar() -> void:
	# Old planes, roped off, each on its own little stand.
	for spot in [Vector2(8, 37), Vector2(18, 38), Vector2(8, 44), Vector2(26, 44)]:
		var at: Vector2 = spot * T
		_decor.draw_rect(Rect2(at + Vector2(0, 14), Vector2(5 * T, 8)), Color8(90, 110, 90))
		_decor.draw_rect(Rect2(at + Vector2(2 * T - 4, 0), Vector2(T + 8, 2 * T)), Color8(110, 130, 105))
		_decor.draw_circle(at + Vector2(2.5 * T, 6), 5.0, Color(0.6, 0.8, 1.0, 0.7))
	for x in range(2, 38, 4):
		_decor.draw_line(Vector2(x * T, 34 * T + 4), Vector2(x * T + 3 * T, 34 * T + 4), Color8(200, 40, 40), 2.0)
	# The elevator: a big square with hazard stripes.
	var lift := Rect2(33 * T, 34 * T, 5 * T, 4 * T)
	_decor.draw_rect(lift, Color8(70, 74, 80))
	for k in 10:
		_decor.draw_line(lift.position + Vector2(k * 10, 0), lift.position + Vector2(k * 10 - 8, 8), Color8(240, 200, 40), 3.0)
	_decor.draw_string(_font, lift.position + Vector2(8, lift.size.y - 10), "TO FLIGHT DECK", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(240, 200, 40))


func _draw_deck() -> void:
	# The runway: the angled landing line, the centerline, the numbers.
	var deck := _px(Rect2i(2, 56, 56, 20))
	for k in 20:
		_decor.draw_rect(Rect2(deck.position.x + 20 + k * 54, deck.get_center().y - 2, 26, 4), Color(1, 1, 1, 0.75))
	_decor.draw_line(deck.position + Vector2(0, deck.size.y - 30), deck.end - Vector2(120, deck.size.y - 10), Color8(240, 200, 40), 3.0)
	_decor.draw_string(_font, deck.position + Vector2(30, 60), "41", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(1, 1, 1, 0.6))
	# The island tower: windows, a radar dish turning.
	_decor.draw_rect(_px(Rect2i(44, 57, 6, 6)), Color8(110, 116, 128))
	for x in range(44, 50):
		_decor.draw_rect(Rect2(x * T + 4, 58 * T, 12, 8), Color(1.0, 0.85, 0.5, 0.7) if not _night or x % 2 == 0 else Color8(30, 30, 36))
	var dish := Vector2(47 * T, 57 * T - 6)
	_decor.draw_line(dish, dish + Vector2.from_angle(_time * 1.5) * 14.0, Color8(200, 200, 210), 3.0)
	# The elevator up here, and the arresting wires across the deck.
	_decor.draw_rect(Rect2(8 * T, 65 * T, 3 * T, 3 * T), Color8(80, 84, 90))
	_decor.draw_string(_font, Vector2(8 * T + 4, 68 * T - 4), "DOWN", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(240, 200, 40))
	for k in 4:
		_decor.draw_line(Vector2(14 * T + k * 40, 57 * T), Vector2(14 * T + k * 40, 75 * T), Color8(60, 60, 60), 1.0)


## Sunset over the water, and night later (Corps), when the deck goes dark.
func _draw_shade() -> void:
	if _night:
		_shade.draw_rect(Rect2(0, 0, 60 * T, 78 * T), Color(0.03, 0.04, 0.15, 0.5))
		for k in 30:
			_shade.draw_rect(Rect2(Vector2((k * 197) % (60 * T), 54 * T + (k * 41) % 60), Vector2(2, 2)), Color(1, 1, 1, 0.6))
	else:
		_shade.draw_rect(_px(OUTSIDE), Color(1.0, 0.55, 0.3, 0.08))
		_shade.draw_rect(_px(DECK), Color(1.0, 0.5, 0.3, 0.12))


# --- People ----------------------------------------------------------------------

func _place_people() -> void:
	if not Game.walking_alone():
		partner = Cast.make(Game.partner())
		add_character(partner, player.position + Vector2(-20, 0))
		partner.follow = player
	add_person("sailor", Vector2(36 * T, 22 * T + 10), SCENE)
	add_person("tourist", Vector2(20 * T, 25 * T), SCENE)
	add_person("pelican", Vector2(47 * T + 10, 25 * T + 10), SCENE)
	match _route():
		"pacifist":
			if not flag("hb_feeding"):
				if Game.partner() != "Agent":
					agent = add_npc("Agent", AGENT_PIER, _talk_agent)
				if Game.partner() != "Eggo":
					eggo = add_npc("Eggo", EGGO_PIER, _talk_eggo)
			# Hop came too (he wasn't supposed to: he's on probation).
			if Game.partner() != "Hop" and not flag("hb_vote_done"):
				hop = add_npc("Hop", Vector2(31 * T, 18 * T), _talk_hop)
		"neutral":
			if not flag("hb_jet_done"):
				agent = add_npc("Agent", OUTSIDE_GANGWAY + Vector2(30, 0), _talk_agent)
			hop = add_npc("Hop", HOP_BENCH, _talk_hop)
		_:
			if not flag("beat_corps_agent"):
				agent = add_npc("Agent", AGENT_DECK, _talk_agent)
	if not flag("hb_jet_done") and str(Game.battle_result.get("id", "")) != "flight_deck":
		jet = Cast.make("flight_deck")
		jet.glow = true
		jet.glow_color = Color(1.0, 0.3, 0.3, 0.4)
		add_character(jet, JET_SPOT)


func _talk_agent() -> void:
	match _route():
		"pacifist":
			await chat("hb_agent", [
				{"who": "Agent", "text": "Flight Deck. A jet, on the carrier.\nIt's run its engines every night for a week.", "mood": ""},
				{"who": "Agent", "text": "The tourists think it's a show.\nThe fragment is in the cockpit. 97% sure.", "mood": "smug"},
				{"who": "Agent", "text": "I've studied its flight patterns.\nIn the fight, I'll call every dodge. Listen to me.", "mood": ""},
				{"who": "Agent", "text": "And when it tries to land, help it.\nRight after its approach. Not before.", "mood": ""},
				{"who": "Agent", "text": "...Hop shouldn't be here. He's on probation.\nThe host is the risk. I'm watching him.", "mood": "angry"},
			], [[{"who": "Agent", "text": "Gangway. Hangar. Elevator. Deck.\nIn that order. Efficiency.", "mood": ""}]])
		"neutral":
			if flag("hb_rps"):
				await chat("hb_agent_after", [
					{"who": "Agent", "text": "Go on up. I'm collecting data.", "mood": ""},
				], [[{"who": "Agent", "text": "Data.", "mood": ""}]])
				return
			await _rps_with_agent()
		_:
			await _confront_agent()


func _talk_eggo() -> void:
	await chat("hb_eggo", [
		{"who": "Eggo", "text": "A haunted jet. On a boat.\nThat's a plane-ly strange situation.", "mood": "happy"},
		{"who": "Eggo", "text": "...Don't look at me like that. It's been\na long week. Agent won't stop watching Hop.", "mood": "sad"},
		{"who": "Eggo", "text": "You could also just talk to him, you know.\nI keep saying that. Nobody listens.", "mood": ""},
	], [[{"who": "Eggo", "text": "Ship happens.", "mood": "smug"}]])


func _talk_hop() -> void:
	match _route():
		"neutral":
			if flag("hb_fragment"):
				await chat("hb_hop_neutral_after", [
					{"who": "Hop", "text": "...You got it. Of course you did.", "mood": "sad"},
					{"who": "Hop", "text": "Agent says the hatch is locked now.\nThe offer's closed. ...I wanted to tell you myself.", "mood": "sad"},
					{"who": "Hop", "text": "I miss you, man. That's all.", "mood": "sad"},
				], [[{"who": "Hop", "text": "...See you around, Elric.", "mood": "sad"}]])
				return
			await chat("hb_hop_neutral", [
				{"who": "Hop", "text": "...Hey. Elric.", "mood": "sad"},
				{"who": "Hop", "text": "Agent dragged everyone out here. I'm supposed\nto stay on this bench. I'm on probation.", "mood": "smug"},
				{"who": "Hop", "text": "It's fine. It's a good bench.", "mood": "sad"},
				{"who": "Hop", "text": "...You look tired. Are you sleeping?\nYou- never mind. Be careful up there.", "mood": "sad"},
			], [[{"who": "Hop", "text": "Still here. Still benching.", "mood": "smug"}]])
		_:
			await chat("hb_hop", [
				{"who": "Hop", "text": "Agent says I'm a 'risk.' He keeps writing\nthings down when I sneeze.", "mood": "smug"},
				{"who": "Hop", "text": "...He's not wrong, though. Is he.", "mood": "sad"},
			], [[{"who": "Hop", "text": "Go get the jet. I'll stay out of the way.", "mood": "sad"}]])


# --- Things --------------------------------------------------------------------------

func _fish_stand() -> void:
	await Game.dialogue.say(["* (A fish stand. FRESH FISH, the sign says.\n*  The pelican behind it is eating the stock.)"])


func _seal_statue() -> void:
	await Game.dialogue.say(["* (A bronze seal statue. Someone put a\n*  sailor hat on it. It looks proud.)"])


func _old_plane() -> void:
	await Game.dialogue.say(["* (An old propeller plane. The plaque says\n*  it flew in a war a long time ago.)", "* (Now kids sit in the cockpit and make\n*  engine noises. It seems happier.)"])


# --- Getting around ------------------------------------------------------------------

func _gangway() -> void:
	if _route() == "neutral" and not flag("hb_rps") and agent and is_instance_valid(agent):
		await _rps_with_agent()
		return
	Game.play_sfx("door")
	await go_through_door(HANGAR_ENTRY)
	fit_camera_to_room()
	_play_music_here()
	if flag("hb_inside"):
		return
	Game.flags["hb_inside"] = true
	await Game.dialogue.say([
		"* (The hangar deck. Old planes, polished,\n*  roped off. It echoes.)",
		"* (Overhead, through the steel: an engine. Running.)",
	])
	Game.set_objective("The elevator. (Up to the flight deck.)")


func _leave_hangar() -> void:
	Game.play_sfx("door")
	await go_through_door(OUTSIDE_GANGWAY)
	fit_camera_to_room()
	_play_music_here()


func _lift_up() -> void:
	var go := await Game.dialogue.ask("* (The elevator. TO FLIGHT DECK.\n*  The button is shiny from being pressed.)", ["Up", "Not yet"])
	if go != 0:
		return
	Game.play_sfx("door", 0.6)
	await go_through_door(LIFT_UP + Vector2(0, 30))
	fit_camera_to_room()
	_play_music_here()
	if flag("hb_deck"):
		return
	Game.flags["hb_deck"] = true
	await Game.dialogue.say([
		"* (The flight deck. The sun is going down\n*  over the ocean. Everything is orange.)",
		"* (At the far end, an old jet sits with its\n*  engines running. Its canopy glows red.)",
	])
	if not _genocide():
		Game.set_objective("The jet, at the end of the deck.")


func _lift_down() -> void:
	Game.play_sfx("door", 0.6)
	await go_through_door(LIFT_DOWN + Vector2(0, 40))
	fit_camera_to_room()
	_play_music_here()


func _bus_stop() -> void:
	if _night:
		await Game.dialogue.say(["* (Not now.)"])
		return
	await ride_bus(SCENE)


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
	if id in ["flight_deck", "corps_agent"]:
		Game.battle_result = {}
	match id:
		"flight_deck":
			await run_cutscene(_after_jet.bind(spared))
			return
		"corps_agent":
			await run_cutscene(_after_agent)
			return
	if await handle_person_return():
		return
	if not flag("hb_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked() or _engaged:
		return
	if _where() == "outside":
		check_random_encounter(SCENE)
		return
	if _where() != "deck":
		return
	# With Hop: Agent is waiting on the deck.
	if _genocide() and agent and is_instance_valid(agent) and player.position.distance_to(agent.position) < 90.0:
		run_cutscene(_confront_agent)
		return
	# The jet notices you.
	if jet and is_instance_valid(jet) and player.position.distance_to(jet.position) < 70.0:
		if _genocide() and agent and is_instance_valid(agent):
			return
		run_cutscene(_meet_jet)


func _arrival() -> void:
	Game.flags["hb_arrived"] = true
	await Game.dialogue.say([
		"* (The Harbor. Sailboats, gulls, the smell\n*  of fish tacos.)",
		"* (And the carrier: an old aircraft carrier turned\n*  museum, three city blocks long, gray as a storm.)",
		"* (Up on its deck, an engine is running.\n*  Nobody's flying it.)",
	])
	match _route():
		"pacifist":
			await Game.dialogue.say([
				{"who": "Eggo", "text": "ELRIC! Over here! Agent made a SPREADSHEET.\nFor a BOAT.", "mood": "happy"},
			])
			Game.set_objective("Find the fragment. (Up on the carrier.)")
		"neutral":
			await Game.dialogue.say(["* (Agent is standing at the bottom of the gangway.\n*  He's been waiting for you. Of course he has.)"])
			Game.set_objective("Get onto the carrier.")
		_:
			await Game.dialogue.say([
				{"who": "Hop", "text": "...Agent's up there. On the deck.\nHe's not hiding either. None of them hide anymore.", "mood": "sad"},
				{"who": "Hop", "text": "Elric, he's- he's going to have a plan.\nHe always has a plan.", "mood": "sad"},
				{"who": "Relic", "tag": "", "face": false, "text": "* So do we."},
			])
			Game.set_objective("...")


func _meet_jet() -> void:
	if _engaged:
		return
	_engaged = true
	jet.face(player.position - jet.position)
	await Game.dialogue.say([
		"* (The jet swings its nose toward you.\n*  The canopy flares red.)",
		"* (Its engines scream. It wants to FLY.)",
	])
	if _route() == "pacifist":
		await Game.dialogue.say([{"who": "Agent", "text": "(over the radio) I'm in the tower.\nListen to me and you won't get hit. Much.", "mood": ""}])
	await Game.start_battle("flight_deck", SCENE, player.position)


func _after_jet(spared: bool) -> void:
	Game.flags["hb_jet_done"] = true
	if spared:
		await Game.dialogue.say([
			"* (Flight Deck comes around one last time.\n*  Low. Lower. Wheels down.)",
			"* (It catches the wire, and stops, right at the end\n*  of the deck. Its first carrier landing.)",
			"* (The engines wind down. For the first time in a\n*  week, the harbor is quiet.)",
			"* (The canopy slides open. Something red is\n*  sitting where the pilot used to be.)",
		])
	else:
		await Game.dialogue.say([
			"* (Flight Deck skids off the end of the deck.)",
			"* (It doesn't make a sound when it hits the water.)",
			"* (Something red is left on the deck,\n*  where the canopy came apart.)",
		])
		if _genocide():
			await Game.dialogue.say([{"who": "Relic", "tag": "", "face": false, "text": "* Grounded."}])
	Game.play_sfx("fragment")
	await Game.dialogue.say([
		"* (You pick it up. It's warm, and it hums.)",
		"* (You got the eighth FRAGMENT.)",
	])
	Game.flags["hb_fragment"] = true
	if _route() == "neutral":
		Game.flags["hatch_locked"] = true
	Game.flags["has_fragment_8"] = true
	Game.flags["fragments"] = maxi(int(Game.flags.get("fragments", 7)), 8)
	Game.set_objective("..." if _genocide() else "8 of 12 FRAGMENTS.")
	await Game.dialogue.say(["* (The fragment is warm in your hand.\n*  You close your eyes.)"])
	await Game.play_keepsakes([8], SCENE, player.position, [
		"* (A boy who said no. \"Ask me again someday.\")",
		"* (Nobody ever asked him again.)",
	])


## Back from the memory.
func _after_memory() -> void:
	match _route():
		"pacifist":
			await _feeding()
		"neutral":
			Game.flags["hatch_locked"] = true
			await Game.dialogue.say([
				"* (Down on the pier, the Corps is packing up.\n*  Agent is on the phone. He looks at you, and away.)",
			])
			Game.set_objective("8 of 12 FRAGMENTS. (To be continued.)")
		_:
			Game.set_objective("...")


# --- Corps: the plan backfires ---------------------------------------------------

## On the deck, after the fragment: Agent figures it out.
func _feeding() -> void:
	Game.flags["hb_feeding"] = true
	var who_agent: Character = agent if agent and is_instance_valid(agent) else null
	if who_agent == null and Game.partner() != "Agent":
		who_agent = add_character(Cast.make("Agent"), LIFT_UP + Vector2(20, 30))
	if who_agent:
		await who_agent.walk_to(player.position + Vector2(40, 0), 120.0)
		who_agent.face(player.position - who_agent.position)
	if hop == null and Game.partner() != "Hop":
		hop = add_character(Cast.make("Hop"), LIFT_UP + Vector2(-10, 30))
		await hop.walk_to(player.position + Vector2(-40, 10), 100.0)
	await Game.dialogue.say([
		{"who": "Agent", "text": "Elric. I need to show you something.\nI've been tracking Hop since the beach.", "mood": ""},
		{"who": "Agent", "text": "Every time we break a fragment, his readings\ngo up. Every single time. I checked six ways.", "mood": ""},
		{"who": "Agent", "text": "Breaking a fragment frees Relic's piece.\nBut Hopkuna's power doesn't die.", "mood": ""},
		{"who": "Agent", "text": "It drifts home. Back into Hop.", "mood": "shocked"},
		"* (Nobody says anything.)",
		{"who": "Agent", "text": "We haven't been destroying him.\nWe've been feeding him.", "mood": "sad"},
		{"who": "Hop", "text": "...", "mood": "sad"},
		{"who": "Agent", "text": "I'm calling everyone. Tonight. Here.\nThere has to be a vote.", "mood": "angry"},
	])
	if who_agent:
		await who_agent.walk_to(LIFT_UP + Vector2(0, 20), 120.0)
		who_agent.queue_free()
	if agent and is_instance_valid(agent):
		agent.queue_free()
		agent = null
	# Night falls.
	await Game.fade_out(1.2)
	_night = true
	_shade.queue_redraw()
	Game.stop_music(1.0)
	await get_tree().create_timer(1.0).timeout
	await Game.fade_in(1.2)
	await _confession()


## Hop tells Elric everything, on the flight deck, at night.
func _confession() -> void:
	Game.flags["hb_confession"] = true
	var h: Character = partner if Game.partner() == "Hop" and partner else hop
	if h:
		h.follow = null
		await h.walk_to(Vector2(30 * T, 74 * T), 90.0)
		h.face(Vector2.DOWN)
	player.position = Vector2(28 * T, 74 * T)
	player.facing = Vector2.RIGHT
	await Game.dialogue.say([
		"* (Night. Everyone else is down in the hangar,\n*  waiting for the others to get here.)",
		"* (Hop is sitting at the edge of the deck,\n*  his feet over the water.)",
		{"who": "Hop", "text": "...Their name was Relic.", "mood": "sad"},
		{"who": "Hop", "text": "You knew. Nat knew. I could tell.\nYou were waiting for me to say it.", "mood": "sad"},
		{"who": "Elric", "choices": ["...Yeah.", "(Sit down next to him.)"]},
		{"who": "Hop", "text": "They came to town five years ago with a backpack\nthat clinked. Just passing through.", "mood": ""},
		{"who": "Hop", "text": "I bought them curly fries. They stayed\nall summer. Best summer of my life.", "mood": "happy"},
		{"who": "Hop", "text": "They carried everybody's junk. Everybody's worst\nday. I didn't understand what that meant until-", "mood": "sad"},
		{"who": "Hop", "text": "The tent. On the field. We set it up for three.\nThere was supposed to be room for three.", "mood": "sad"},
		{"who": "Hop", "text": "And then the voice got out. And there was fire.\nAnd it was me. It was my hands.", "mood": "sad"},
		{"who": "Hop", "text": "Relic held him. Hopkuna. All of him.\nAnd it was too heavy, and they broke.", "mood": "sad"},
		{"who": "Hop", "text": "Twelve pieces. All over the city.\nAnd I killed the last one who had it.", "mood": "sad"},
		"* (The ocean is very loud.)",
		{"who": "Elric", "choices": ["It wasn't you.", "...Why didn't you tell me?"]},
		{"who": "Hop", "text": "Because you look like them. You walk like them.\nYou stand on the edge of things like them.", "mood": "sad"},
		{"who": "Hop", "text": "I couldn't tell you. I didn't want you\nto be a replacement.", "mood": "sad"},
		{"who": "Hop", "text": "I wanted you to be you.", "mood": "sad"},
		"* (He wipes his face with his sleeve, hard.)",
		{"who": "Hop", "text": "...They're voting. On me. Down there.\nAgent wants me sealed up somewhere. He's right.", "mood": "sad"},
		{"who": "Elric", "choices": ["I'll speak for you.", "He's not right."]},
		{"who": "Hop", "text": "...You'd do that?", "mood": "shocked"},
		{"who": "Hop", "text": "Okay. Okay. Let's go hear it.", "mood": "sad"},
	])
	await _vote()


# --- Corps: the vote -----------------------------------------------------------------

## How each of the Corps starts out voting: "keep" (don't seal Hop away), "seal",
## or "torn" (Elric can win them over).
const START_VOTES := {
	"Agent": "seal", "Supreme": "seal", "Rooster": "seal", "Sansworth": "seal",
	"Eggo": "keep", "Crayola": "keep", "NCWethan": "keep", "Nat": "keep", "MuffinMage": "keep",
	"BigJoe6": "torn", "Nassan": "torn", "Ronin": "torn",
}


func _vote() -> void:
	# Down in the hangar, everyone's here.
	await Game.fade_out(0.8)
	player.position = VOTE_CENTER + Vector2(0, 80)
	player.facing = Vector2.UP
	fit_camera_to_room()
	var circle: Dictionary = {}
	var ids: Array = START_VOTES.keys()
	for i in ids.size():
		var id: String = ids[i]
		if partner and Game.partner() == id:
			partner.follow = null
			partner.position = VOTE_CENTER + Vector2.from_angle(PI + i * PI / (ids.size() - 1)) * Vector2(150, 70)
			circle[id] = partner
			continue
		var member := Cast.make(id)
		add_character(member, VOTE_CENTER + Vector2.from_angle(PI + i * PI / (ids.size() - 1)) * Vector2(150, 70))
		member.face(Vector2.DOWN)
		circle[id] = member
	var h: Character = partner if Game.partner() == "Hop" and partner else hop
	if h:
		h.follow = null
		h.position = VOTE_CENTER + Vector2(0, 30)
		h.face(Vector2.UP)
	await Game.fade_in(0.8)
	var votes: Dictionary = START_VOTES.duplicate()
	await Game.dialogue.say([
		"* (The hangar deck. All twelve of them, in a circle,\n*  under the old planes. Hop in the middle.)",
		{"who": "Nassan", "text": "Okay. Everybody heard Agent. Everybody heard\nthe numbers. ...We vote. Then we live with it.", "mood": "sad"},
		{"who": "Agent", "text": "The host is the risk. Remove the risk.\nSeal him somewhere safe, before he gets stronger.", "mood": ""},
		{"who": "Eggo", "text": "...or you could just talk to him.", "mood": "sad"},
		{"who": "Agent", "text": "We TALKED to him. For five years.\nHe lied to us for five years.", "mood": "angry"},
		{"who": "Nassan", "text": "Elric. You were up there with him.\nYou get to talk first.", "mood": ""},
	])
	# Big Joe: justice.
	var answer := await Game.dialogue.ask("* (Big Joe is staring at the floor.\n*  \"Justice says... I don't know what it says.\")", ["Justice is for what you DO.", "Maybe Agent's right."])
	if answer == 0:
		votes["BigJoe6"] = "keep"
		await Game.dialogue.say([{"who": "BigJoe6", "text": "...For what you DO. Not what you might.\nYeah. YEAH. That's justice. I'm with Hop.", "mood": "happy"}])
	else:
		votes["BigJoe6"] = "seal"
		await Game.dialogue.say([{"who": "BigJoe6", "text": "...Yeah. Okay. I'm sorry, Hop.\nThe rules are the rules.", "mood": "sad"}])
	# Nassan: the plan.
	answer = await Game.dialogue.ask("* (Nassan is looking at his map. Twelve circles.\n*  \"There has to be a step two. There has to be.\")", ["We find step two. Together.", "There isn't one."])
	if answer == 0:
		votes["Nassan"] = "keep"
		await Game.dialogue.say([{"who": "Nassan", "text": "...Together. Step two: together. I can plan\naround that. I can't plan around losing him.", "mood": ""}])
	else:
		votes["Nassan"] = "seal"
		await Game.dialogue.say([{"who": "Nassan", "text": "...No. I guess there isn't.", "mood": "sad"}])
	# Ronin: the fire.
	answer = await Game.dialogue.ask("* (Ronin's hands are glowing, a little.\n*  \"I know what fire does. I KNOW what it does.\")", ["Hop didn't choose the fire. Neither did you.", "Fire's fire."])
	if answer == 0:
		votes["Ronin"] = "keep"
		await Game.dialogue.say([{"who": "Ronin", "text": "...No. I didn't.\nNobody locked ME up for it. Keep him.", "mood": ""}])
	else:
		votes["Ronin"] = "seal"
		await Game.dialogue.say([{"who": "Ronin", "text": "...Yeah. It is. Seal.", "mood": "sad"}])
	# With enough BOND, even the numbers bend.
	if Game.bond_level() >= 4:
		votes["Supreme"] = "keep"
		await Game.dialogue.say([
			{"who": "Supreme", "text": "...My model says seal.", "mood": ""},
			{"who": "Supreme", "text": "My model also didn't predict Elric.\nKeep. I'm adjusting for the outlier.", "mood": "smug"},
		])
	answer = await Game.dialogue.ask("* (Everyone's looking at you. Your vote.)", ["Keep him.", "Seal him."])
	var keep := 1 if answer == 0 else 0
	var seal := 1 - keep
	for id in votes:
		if votes[id] == "keep":
			keep += 1
		else:
			seal += 1
	# Hands go up, one at a time.
	var lines: Array = ["* (Nassan counts the hands.)"]
	lines.append("* (KEEP: %d.  SEAL: %d.)" % [keep, seal])
	Game.flags["hb_votes_keep"] = keep
	Game.flags["hb_vote"] = "keep" if keep > seal else "seal"
	if keep > seal:
		lines.append_array([
			{"who": "Nassan", "text": "...Hop stays. With us. We figure it out.", "mood": "happy"},
			{"who": "Agent", "text": "...Noted. I'll be wrong in writing, then.\nI hope I'm wrong.", "mood": "sad"},
			{"who": "Hop", "text": "...You voted for me.", "mood": "shocked"},
			{"who": "Hop", "text": "All of you. Even after-", "mood": "sad"},
		])
	else:
		lines.append_array([
			{"who": "Nassan", "text": "...Seal. We'll- we'll find somewhere safe.\nTomorrow. We'll figure it out tomorrow.", "mood": "sad"},
			{"who": "Hop", "text": "It's okay. It's okay.\nAgent's right. He's always right.", "mood": "sad"},
			{"who": "Eggo", "text": "...", "mood": "sad"},
		])
	lines.append_array([
		"* (Everyone walks back to the base together,\n*  through the city, at night. Nobody talks much.)",
		"* (Hop walks in the middle, the whole way.)",
	])
	await Game.dialogue.say(lines)
	Game.flags["hb_vote_done"] = true
	Game.flags["hb_feeding"] = true
	# (Hop can't come along anymore: he leaves tonight. Whoever's next is the partner.)
	if Game.partner() == "Hop":
		Game.set_partner("BigJoe6")
	Game.set_objective("Get some sleep. (The base.)")
	await Game.change_scene(BASE_SCENE)


# --- With Hop: Agent ----------------------------------------------------------------

func _confront_agent() -> void:
	if not agent or not is_instance_valid(agent) or _engaged:
		return
	_engaged = true
	agent.face(player.position - agent.position)
	await Game.dialogue.say([
		{"who": "Agent", "text": "Stop there. Exactly there. I knew you would.", "mood": ""},
		{"who": "Agent", "text": "Crayola. N.C. Big Joe. Nat. Supreme.\nI ran this a thousand times after the beach.", "mood": ""},
		{"who": "Agent", "text": "In none of them do I win.\nI came anyway. Supreme taught me that.", "mood": "sad"},
		{"who": "Hop", "text": "Agent, please. You SAID it. You said I was\nthe risk. Take ME. Lock ME up-", "mood": "sad"},
		{"who": "Agent", "text": "You were never the risk, Hop.\nI had the wrong variable.", "mood": "sad"},
	])
	await Game.start_battle("corps_agent", SCENE, player.position)


func _after_agent() -> void:
	if agent:
		agent.queue_free()
		agent = null
	var kept: Array = Game.flags.get("mementos", [])
	if not "Bullseye Dart" in kept:
		kept.append("Bullseye Dart")
	Game.flags["mementos"] = kept
	await Game.dialogue.say([
		"* (A dart is stuck in the deck, right where\n*  you were about to step. Dead center.)",
		"* (You keep it.)",
		"* (Hop is standing at the edge of the deck,\n*  looking at the water. He doesn't turn around.)",
		{"who": "Relic", "tag": "", "face": false, "text": "* Six."},
	])
	_engaged = false
	Game.set_objective("...")


# --- Own way: Rock Paper Scissors with Agent ---------------------------------------

func _rps_with_agent() -> void:
	if _engaged:
		return
	_engaged = true
	await Game.dialogue.say([
		{"who": "Agent", "text": "Elric. I predicted you'd come. 88%.", "mood": "smug"},
		{"who": "Agent", "text": "We both want that fragment. So: a rematch.\nRock Paper Scissors. Five throws.", "mood": ""},
		{"who": "Agent", "text": "Win, and you go up first. Lose,\nand you go up first anyway. I want the data.", "mood": "smug"},
	])
	var game = load("res://scripts/ui/rps_game.gd").new()
	add_child(game)
	var rounds: Array = []
	for i in 5:
		rounds.append({"opponent": "Agent", "throw": -1, "tell": "math"})
	var wins: int = await game.play(rounds)
	game.queue_free()
	_play_music_here()
	Game.flags["hb_rps"] = true
	if wins >= 3:
		await Game.dialogue.say([
			{"who": "Agent", "text": "...%d out of 5. You countered my counter." % wins, "mood": "shocked"},
			{"who": "Agent", "text": "Go. I'll be updating everything I know.", "mood": ""},
		])
	else:
		await Game.dialogue.say([
			{"who": "Agent", "text": "%d out of 5. As predicted." % wins, "mood": "smug"},
			{"who": "Agent", "text": "Go up anyway. ...Be careful. That jet\ndoesn't care who wins anything.", "mood": ""},
		])
	if agent:
		await agent.walk_to(AGENT_PIER, 100.0)
	_engaged = false
	Game.set_objective("Get onto the carrier. (The gangway.)")
