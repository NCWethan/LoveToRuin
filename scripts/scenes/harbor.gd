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
## The elevator to the flight deck won't run without signal clearance (Chapter 2:
## the road to each fragment): four flags on the hoist, in order. The flag locker
## is by the elevator; what each flag means is on a chart in the engine room,
## below decks (a hatch in the hangar floor): "OUR NUMBER, THEN G-O." The number
## is painted on the hull: 41.
##
## Story flags: hb_arrived, hb_rps, hb_inside, hb_engine_seen, hb_hoist (the flags
## raised so far), hb_flags, hb_deck, hb_jet_done, hb_fragment,
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
## The engine room, below the hangar (its own room on the map), and the way down.
const ENGINE := Rect2i(42, 32, 18, 20)
const HATCH := Vector2(36 * T + 10, 47 * T + 10)
const HATCH_OUT := Vector2(36 * T + 10, 46 * T + 8)
const ENGINE_ENTRY := Vector2(50 * T + 10, 35 * T + 10)
const LADDER := Vector2(50 * T + 10, 34 * T + 2)
const CHART := Vector2(45 * T + 10, 34 * T + 4)
## The flag locker, by the elevator, and its flags: [what it looks like, what it means].
const LOCKER := Vector2(31 * T, 35 * T + 4)
const SIGNAL_FLAGS := [["Red, white cross", "4"], ["Blue, white square", "1"], ["Yellow, black dot", "2"],
	["Black + white checks", "7"], ["Yellow + blue stripes", "G"], ["Red + yellow halves", "O"]]
const CLEARANCE := ["4", "1", "G", "O"]

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
	rooms.assign([_px(OUTSIDE), _px(HANGAR), _px(DECK), _px(ENGINE)])
	setup_area(ENTRY)
	add_wild_encounters(SCENE, Rect2(T, 14 * T, 58 * T, 14 * T))
	add_wild_encounters(SCENE, _px(ENGINE))
	_font = ThemeDB.fallback_font
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	add_static_layer(_draw_scenery)
	_shade = Node2D.new()
	add_child(_shade)
	_shade.draw.connect(_draw_shade)
	_place_people()
	_dress()
	for spot in [[ENTRY + Vector2(10, -8), _bus_stop], [GANGWAY_TOP, _gangway], [HANGAR_EXIT, _leave_hangar],
			[LIFT_DOWN, _lift_up], [LIFT_UP, _lift_down], [Vector2(45 * T + 10, 26 * T + 4), _fish_stand],
			[Vector2(6 * T + 10, 26 * T + 4), _seal_statue], [Vector2(10 * T + 10, 36 * T + 4), _old_plane],
			[HATCH, _hatch], [LADDER, _ladder], [CHART, _chart], [LOCKER, _locker],
			[Vector2(52 * T, 39 * T + 4), _engines]]:
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
	if _px(ENGINE).has_point(player.position):
		return "engine"
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

func is_night() -> bool:
	return _night


## Set dressing (props.gd): lobster traps, coiled rope, barrels and an anchor on the
## pier; buoys and a rowboat on the water; lamps, an ice cream cart and bikes on the
## promenade; crates and a sign in the hangar; cones and pallets on the flight deck.
func _dress() -> void:
	add_dressing([
		["buoy", Vector2(12 * T, 12 * T), {"walkable": true}],
		["buoy", Vector2(46 * T, 11 * T + 10), {"walkable": true}],
		["rowboat", Vector2(20 * T, 12 * T), {"color": Color8(230, 230, 235), "walkable": true}],
		["lobster_trap", Vector2(4 * T, 16 * T), {"look": ["* (A lobster trap. There's a crab in it.\n*  It's not a lobster. It seems embarrassed.)"]}],
		["lobster_trap", Vector2(5 * T + 6, 16 * T + 12)],
		["rope", Vector2(9 * T, 15 * T + 12), {"walkable": true}],
		["rope", Vector2(50 * T, 15 * T + 12), {"walkable": true}],
		["crates", Vector2(15 * T, 16 * T), {"look": ["* (Crates marked SURPLUS. One is open.\n*  It's full of rubber ducks in sailor hats.)"]}],
		["barrel", Vector2(54 * T, 16 * T)],
		["barrel", Vector2(55 * T, 16 * T + 8)],
		["anchor", Vector2(42 * T, 19 * T + 6), {"look": ["* (An old anchor, painted black. The plaque:\n*  IT HELD HER STEADY FOR 47 YEARS.)"]}],
		["lamp", Vector2(8 * T, 21 * T + 6), {"lit": _night}],
		["lamp", Vector2(20 * T, 21 * T + 6), {"lit": _night}],
		["lamp", Vector2(34 * T, 21 * T + 6), {"lit": _night}],
		["lamp", Vector2(46 * T, 21 * T + 6), {"lit": _night}],
		["trash_can", Vector2(15 * T, 24 * T + 10)],
		["trash_can", Vector2(34 * T, 24 * T + 10)],
		["food_cart", Vector2(40 * T, 27 * T + 8), {"color": Color8(240, 160, 190), "text": "ICE CREAM", "look": ["* (An ice cream cart. Today's special: ROCKY ROAD.\n*  Yesterday's special: ROCKY ROAD.)"]}],
		["bike_rack", Vector2(25 * T, 27 * T + 10), {"color": Color8(60, 120, 200)}],
		["news_box", Vector2(52 * T, 21 * T + 12), {"color": Color8(60, 100, 180), "look": ["* (THE HARBOR LOG. Headline: GHOST JET?\n*  NAVY SAYS \"NO COMMENT.\")"]}],
		["hydrant", Vector2(18 * T, 27 * T + 12)],
		# The hangar.
		["crates", Vector2(34 * T, 48 * T), {"look": ["* (Crates of spare parts, stenciled with a squadron's\n*  name. Someone drew a little cat on one.)"]}],
		["sign", Vector2(15 * T + 10, 41 * T + 14), {"text": "DO NOT CLIMB", "color": Color8(150, 40, 40), "look": ["* (PLEASE DO NOT CLIMB ON THE AIRCRAFT.)", "* (There are small footprints on the wing.)"]}],
		["cart", Vector2(3 * T, 48 * T + 6)],
		["barrel", Vector2(37 * T, 40 * T)],
		# The flight deck.
		["cone", Vector2(20 * T, 58 * T)],
		["cone", Vector2(24 * T, 58 * T)],
		["cone", Vector2(28 * T, 58 * T)],
		["pallet", Vector2(54 * T, 58 * T + 10), {"look": ["* (A pallet of chocks and chains. Everything up here\n*  is tied down, except the wind.)"]}],
		["barrel", Vector2(41 * T, 60 * T)],
	])


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
	# The flag locker, by the elevator.
	room.fill(30, 34, 2, 1, Room.PROP)
	# The engine room: steel, pipes, two huge old engines.
	room.fill(ENGINE.position.x, ENGINE.position.y, ENGINE.size.x, ENGINE.size.y, Room.BUNKER_WALL)
	room.fill(43, 34, 16, 17, Room.BUNKER_FLOOR)
	room.fill(47, 39, 4, 6, Room.PROP)
	room.fill(53, 39, 4, 6, Room.PROP)


func _draw_decor() -> void:
	# (The hull, the fish stand, the seal, the planes, the island: _draw_scenery.)
	# Glints on the water.
	for k in 30:
		var x := fmod(k * 83.0 + _time * 10.0, 60.0 * T)
		var y := 10 * T + 4 + (k % 4) * 18
		if y < 14 * T:
			_decor.draw_line(Vector2(x, y), Vector2(x + 10, y), Color(1, 1, 1, 0.3), 1.0)
	# The bus stop.
	Scenery.bus_stop(_decor, ENTRY + Vector2(9, -8))
	# The signal flags on the hoist over the elevator, flapping.
	var hoist: Array = ["4", "1", "G", "O"] if flag("hb_flags") else Game.flags.get("hb_hoist", [])
	var keys := ["4", "1", "2", "7", "G", "O"]
	var flag_colors := [[Color8(220, 40, 40), Color8(250, 250, 250)], [Color8(40, 70, 170), Color8(250, 250, 250)], [Color8(240, 200, 40), Color8(20, 20, 24)],
		[Color8(20, 20, 24), Color8(250, 250, 250)], [Color8(240, 200, 40), Color8(40, 70, 170)], [Color8(220, 40, 40), Color8(240, 200, 40)]]
	_decor.draw_line(Vector2(33 * T, 33 * T + 10), Vector2(38 * T, 33 * T + 10), Color8(200, 200, 205), 1.0)
	for i in hoist.size():
		var c: Array = flag_colors[keys.find(hoist[i])]
		var at := Vector2(33 * T + 8 + i * 22, 33 * T + 11 + sin(_time * 6.0 + i) * 1.5)
		_decor.draw_rect(Rect2(at, Vector2(14, 10)), c[0])
		_decor.draw_rect(Rect2(at + Vector2(4, 3), Vector2(6, 4)), c[1])
	# The radar on the island, turning.
	var dish := Vector2(47 * T, 57 * T - 30)
	_decor.draw_line(dish, dish + Vector2.from_angle(_time * 1.5) * 14.0, Color8(200, 200, 210), 3.0)
	_decor.draw_circle(dish, 2.0, Color8(160, 164, 174))


## What never changes: drawn once (Area.add_static_layer).
func _draw_scenery(ci: CanvasItem) -> void:
	var f := ThemeDB.fallback_font
	# The carrier's hull, the gangway's hatch, the number and the museum's banner.
	Scenery.carrier_hull(ci, Rect2(6 * T, 1 * T, 50 * T, 9 * T), _night)
	ci.draw_rect(Rect2(29 * T, 7 * T, 3 * T, 3 * T), Color8(52, 56, 66))
	ci.draw_rect(Rect2(29 * T + 4, 7 * T + 4, 3 * T - 8, 3 * T - 4), Color8(28, 30, 36))
	ci.draw_rect(Rect2(29 * T, 7 * T, 3 * T, 2), Color8(150, 156, 166))
	ci.draw_string(f, Vector2(14 * T + 2, 8 * T + 2), "41", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0, 0, 0, 0.3))
	ci.draw_string(f, Vector2(14 * T, 8 * T), "41", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color8(232, 232, 238))
	var banner := Rect2(35 * T, 7 * T - 2, 8 * T + 6, 16)
	ci.draw_rect(banner.grow(1), Color8(240, 230, 200))
	ci.draw_rect(banner, Color8(30, 50, 90))
	ci.draw_string(f, banner.position + Vector2(6, 12), "MUSEUM - OPEN DAILY", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(240, 230, 200))
	# On the promenade: the fish stand and the seal statue.
	Scenery.fish_stand(ci, Rect2(44 * T, 25 * T - 14, 3 * T, 34))
	Scenery.seal_statue(ci, Vector2(6 * T + 10, 25 * T + 8))
	_draw_hangar(ci)
	_draw_deck(ci)
	_draw_engine_room(ci)


func _draw_hangar(ci: CanvasItem) -> void:
	# Old warbirds, each on its stand inside velvet ropes, in museum colors.
	var colors := [Color8(96, 116, 88), Color8(70, 96, 130), Color8(150, 150, 140), Color8(120, 100, 70)]
	var spots := [Vector2(8, 37), Vector2(18, 38), Vector2(8, 44), Vector2(26, 44)]
	for i in spots.size():
		var at: Vector2 = spots[i] * T
		Scenery.velvet_ropes(ci, Rect2(at + Vector2(-6, -10), Vector2(5 * T + 12, 2 * T + 22)))
		Scenery.warplane(ci, at + Vector2(2.5 * T, T), 4 * T, colors[i])
	# A red line painted along the wall, and the elevator.
	for x in range(2, 38, 4):
		ci.draw_line(Vector2(x * T, 34 * T + 4), Vector2(x * T + 3 * T, 34 * T + 4), Color8(200, 40, 40), 2.0)
	var lift := Rect2(33 * T, 34 * T, 5 * T, 4 * T)
	Scenery.hazard_platform(ci, lift)
	ci.draw_string(ThemeDB.fallback_font, lift.position + Vector2(10, lift.size.y - 12), "TO FLIGHT DECK", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(240, 200, 40))


func _draw_deck(ci: CanvasItem) -> void:
	# The runway: the centerline, the angled landing line, the number, skid marks.
	var deck := _px(Rect2i(2, 56, 56, 20))
	for k in 20:
		ci.draw_rect(Rect2(deck.position.x + 20 + k * 54, deck.get_center().y - 2, 26, 4), Color(1, 1, 1, 0.75))
	ci.draw_line(deck.position + Vector2(0, deck.size.y - 30), deck.end - Vector2(120, deck.size.y - 10), Color8(240, 200, 40), 3.0)
	ci.draw_line(deck.position + Vector2(0, deck.size.y - 36), deck.end - Vector2(120, deck.size.y - 4), Color8(240, 200, 40), 1.0)
	ci.draw_string(ThemeDB.fallback_font, deck.position + Vector2(30, 60), "41", HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(1, 1, 1, 0.6))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 14:
		var at := Vector2(rng.randf_range(deck.position.x + 100, deck.end.x - 200), rng.randf_range(deck.position.y + 30, deck.end.y - 30))
		ci.draw_line(at, at + Vector2(rng.randf_range(30, 60), rng.randf_range(-3, 3)), Color(0, 0, 0, 0.18), 3.0)
	# Deck edge: a safety net all the way around, and the edge lights.
	ci.draw_rect(Rect2(deck.position, Vector2(deck.size.x, 3)), Color8(150, 150, 140))
	ci.draw_rect(Rect2(deck.position.x, deck.end.y - 3, deck.size.x, 3), Color8(150, 150, 140))
	var lx := deck.position.x + 10
	while lx < deck.end.x:
		ci.draw_rect(Rect2(lx, deck.position.y + 4, 2, 2), Color8(250, 214, 120) if _night else Color8(200, 200, 190))
		ci.draw_rect(Rect2(lx, deck.end.y - 6, 2, 2), Color8(250, 214, 120) if _night else Color8(200, 200, 190))
		lx += 40
	# The island tower.
	Scenery.island_tower(ci, _px(Rect2i(44, 57, 6, 6)), _night)
	# The elevator up here, and the arresting wires across the deck.
	Scenery.hazard_platform(ci, Rect2(8 * T, 65 * T, 3 * T, 3 * T))
	ci.draw_string(ThemeDB.fallback_font, Vector2(8 * T + 14, 68 * T - 10), "DOWN", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(240, 200, 40))
	for k in 4:
		var x := 14 * T + k * 40
		ci.draw_line(Vector2(x, 57 * T), Vector2(x, 75 * T), Color8(50, 50, 52), 2.0)
		ci.draw_line(Vector2(x + 1, 57 * T), Vector2(x + 1, 75 * T), Color8(110, 110, 112), 1.0)


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
	if not flag("hb_flags"):
		await Game.dialogue.say(["* (The elevator won't budge. A placard on the rail:\n*  NO LIFT WITHOUT SIGNAL CLEARANCE.)", "* (FLAGS ON THE HOIST: NONE.)"])
		Game.set_objective("Raise the signal flags. (The locker by the elevator.)")
		return
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


# --- Below decks, and the signal flags -----------------------------------------------

func _hatch() -> void:
	Game.play_sfx("door", 0.7)
	await go_through_door(ENGINE_ENTRY)
	fit_camera_to_room()
	_play_music_here()
	if not flag("hb_engine_seen"):
		Game.flags["hb_engine_seen"] = true
		await Game.dialogue.say([
			"* (Down the ladder: the engine room. Two engines the\n*  size of houses. It smells like a hundred years of oil.)",
			"* (On the wall by the ladder: a chart, and some\n*  writing in grease pencil.)",
		])


func _ladder() -> void:
	Game.play_sfx("door", 0.7)
	await go_through_door(HATCH_OUT)
	fit_camera_to_room()
	_play_music_here()


func _engines() -> void:
	await Game.dialogue.say(["* (The engines. Cold, for decades. A brass plate:\n*  280,000 HORSEPOWER.)", "* (Someone has taped a note to one: SHE STILL\n*  REMEMBERS HOW. DON'T TEMPT HER.)"])


func _chart() -> void:
	await Game.dialogue.say([
		"* (A chart: SIGNAL FLAGS, and what each one means.)",
		"* (\"1: blue, white square.   2: yellow, black dot.\n*  4: red, white cross.     7: black and white checks.\")",
		"* (\"G: yellow and blue stripes.\n*  O: red and yellow, split corner to corner.\")",
		"* (Under it, in grease pencil: ELEVATOR CLEARANCE =\n*  OUR NUMBER, THEN G-O.  (IT'S ON THE HULL, GENIUS.))",
	])
	if not flag("hb_flags"):
		Game.set_objective("Raise the signal flags. (Our number, then G-O.)")


## The flag locker: hoist flags one at a time; four up, the elevator checks them.
func _locker() -> void:
	if flag("hb_flags"):
		await Game.dialogue.say(["* (The flags are up: 4, 1, G, O. The elevator's\n*  light is green.)"])
		return
	await Game.dialogue.say(["* (The flag locker. Six signal flags, rolled up neat,\n*  and a hoist that runs up over the elevator.)"])
	while true:
		var hoist: Array = Game.flags.get("hb_hoist", [])
		var names: Array = []
		for f in SIGNAL_FLAGS:
			names.append(f[0])
		names.append("Haul them down" if not hoist.is_empty() else "Leave it")
		var pick := await Game.dialogue.ask("* (Flag %d of 4. Which one goes up?)" % (hoist.size() + 1), names)
		if pick < 0 or pick == SIGNAL_FLAGS.size():
			if not hoist.is_empty():
				Game.flags["hb_hoist"] = []
				Game.play_sfx("move")
				_decor.queue_redraw()
			return
		hoist = hoist.duplicate()
		hoist.append(SIGNAL_FLAGS[pick][1])
		Game.flags["hb_hoist"] = hoist
		Game.play_sfx("select")
		_decor.queue_redraw()
		if hoist.size() < 4:
			continue
		if hoist == CLEARANCE:
			Game.flags["hb_flags"] = true
			Game.play_sfx("save")
			await Game.dialogue.say([
				"* (Four flags snap in the wind over the elevator.)",
				"* (A bell rings somewhere in the ship. The elevator's\n*  light goes from red to green.)",
			])
			Game.set_objective("The elevator. (Up to the flight deck.)")
		else:
			Game.play_sfx("miss")
			await Game.dialogue.say(["* (A buzzer. The elevator's light stays red.\n*  CLEARANCE DENIED.)", "* (You haul the flags back down.)"])
			Game.flags["hb_hoist"] = []
			_decor.queue_redraw()
		return


## The engine room: the engines, pipes, the ladder and the chart; the locker.
func _draw_engine_room(ci: CanvasItem) -> void:
	var r := _px(ENGINE)
	for k in 4:
		var y := r.position.y + T + 2 + k * 8
		ci.draw_rect(Rect2(r.position.x + T, y, r.size.x - 2 * T, 4), Color8(110, 116, 120).darkened(k * 0.12))
		ci.draw_rect(Rect2(r.position.x + T, y, r.size.x - 2 * T, 1), Color8(160, 166, 170))
	for spot in [Rect2(47 * T, 39 * T - 10, 4 * T, 6 * T + 10), Rect2(53 * T, 39 * T - 10, 4 * T, 6 * T + 10)]:
		ci.draw_rect(Rect2(spot.position + Vector2(3, 4), spot.size), Color(0, 0, 0, 0.3))
		ci.draw_rect(spot, Color8(84, 92, 86))
		ci.draw_rect(Rect2(spot.position, Vector2(spot.size.x, 4)), Color8(120, 130, 122))
		for k in 5:
			ci.draw_rect(Rect2(spot.position.x + 6, spot.position.y + 16 + k * 20, spot.size.x - 12, 3), Color8(60, 66, 62))
		ci.draw_circle(spot.position + Vector2(spot.size.x / 2, 30), 9.0, Color8(200, 170, 90))
		ci.draw_circle(spot.position + Vector2(spot.size.x / 2, 30), 6.0, Color8(240, 236, 220))
	# The ladder up, and the chart beside it.
	for k in 6:
		ci.draw_rect(Rect2(50 * T + 2, 32 * T + 4 + k * 6, T - 4, 2), Color8(150, 150, 156))
	ci.draw_rect(Rect2(50 * T + 1, 32 * T, 2, 2 * T), Color8(120, 120, 126))
	ci.draw_rect(Rect2(51 * T - 3, 32 * T, 2, 2 * T), Color8(120, 120, 126))
	var chart := Rect2(44 * T, 32 * T + 4, 3 * T, 2 * T - 6)
	ci.draw_rect(chart, Color8(236, 232, 216))
	var flag_colors := [[Color8(220, 40, 40), Color8(250, 250, 250)], [Color8(40, 70, 170), Color8(250, 250, 250)], [Color8(240, 200, 40), Color8(20, 20, 24)],
		[Color8(20, 20, 24), Color8(250, 250, 250)], [Color8(240, 200, 40), Color8(40, 70, 170)], [Color8(220, 40, 40), Color8(240, 200, 40)]]
	for i in 6:
		var at := chart.position + Vector2(4 + (i % 3) * 18, 4 + (i / 3) * 14)
		ci.draw_rect(Rect2(at, Vector2(10, 8)), flag_colors[i][0])
		ci.draw_rect(Rect2(at + Vector2(3, 2), Vector2(4, 4)), flag_colors[i][1])
		PixelFont.draw(ci, ["4", "1", "2", "7", "G", "O"][i], at + Vector2(12, 1), 1.0, Color8(40, 40, 50))
	# The hatch in the hangar floor.
	ci.draw_circle(HATCH, 9.0, Color8(70, 74, 82))
	ci.draw_circle(HATCH, 7.0, Color8(100, 106, 116))
	ci.draw_line(HATCH + Vector2(-6, 0), HATCH + Vector2(6, 0), Color8(60, 64, 70), 2.0)
	ci.draw_line(HATCH + Vector2(0, -6), HATCH + Vector2(0, 6), Color8(60, 64, 70), 2.0)
	# The flag locker, by the elevator.
	var locker := Rect2(30 * T, 34 * T - 6, 2 * T, T + 6)
	ci.draw_rect(locker, Color8(70, 90, 120))
	ci.draw_rect(Rect2(locker.position, Vector2(locker.size.x, 3)), Color8(110, 130, 160))
	for i in 6:
		ci.draw_rect(Rect2(locker.position + Vector2(3 + i * 6, 8), Vector2(4, 12)), flag_colors[i][0])


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
	if _where() in ["outside", "engine"]:
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
			# The offer's closed: whoever came along from the Corps goes with them.
			if not Game.walking_alone():
				var who := DialogueBox.display_name(Game.partner())
				await Game.dialogue.say(["* (%s goes with them. At the end of the pier,\n*  they look back once.)" % who])
				Game.flags["partner"] = "Hop"
				Game._build_partner()
				if partner and is_instance_valid(partner):
					partner.follow = null
					await partner.walk_to(partner.position + Vector2(0, 160), 110.0)
					partner.queue_free()
					partner = null
			Game.set_objective("8 of 12. Next: Torrey Pines. (Take the bus.)")
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
		{"who": "Elric", "choices": ["...Yeah.", "(Sit down next to him.)"], "replies": [
			[{"who": "Hop", "text": "Yeah. Of course you did.", "mood": "sad"}],
			["* (You sit. Your feet hang over the water\n*  next to his.)", {"who": "Hop", "text": "...Thanks.", "mood": "sad"}]]},
		{"who": "Hop", "text": "They came to town five years ago with a backpack\nthat clinked. Just passing through.", "mood": ""},
		{"who": "Hop", "text": "I bought them curly fries. They stayed\nall summer. Best summer of my life.", "mood": "happy"},
		{"who": "Hop", "text": "They carried everybody's junk. Everybody's worst\nday. I didn't understand what that meant until-", "mood": "sad"},
		{"who": "Hop", "text": "The tent. On the field. We set it up for three.\nThere was supposed to be room for three.", "mood": "sad"},
		{"who": "Hop", "text": "And then the voice got out. And there was fire.\nAnd it was me. It was my hands.", "mood": "sad"},
		{"who": "Hop", "text": "Relic held him. Hopkuna. All of him.\nAnd it was too heavy, and they broke.", "mood": "sad"},
		{"who": "Hop", "text": "Twelve pieces. All over the city.\nAnd I killed the last one who had it.", "mood": "sad"},
		"* (The ocean is very loud.)",
		{"who": "Elric", "choices": ["It wasn't you.", "...Why didn't you tell me?"], "replies": [
			[{"who": "Hop", "text": "...It was my hands, Elric.\nAnd I never even told you. You know why?", "mood": "sad"}], []]},
		{"who": "Hop", "text": "Because you look like them. You walk like them.\nYou stand on the edge of things like them.", "mood": "sad"},
		{"who": "Hop", "text": "I couldn't tell you. I didn't want you\nto be a replacement.", "mood": "sad"},
		{"who": "Hop", "text": "I wanted you to be you.", "mood": "sad"},
		"* (He wipes his face with his sleeve, hard.)",
		{"who": "Hop", "text": "...They're voting. On me. Down there.\nAgent wants me sealed up somewhere. He's right.", "mood": "sad"},
		{"who": "Elric", "choices": ["I'll speak for you.", "He's not right."], "replies": [
			[{"who": "Hop", "text": "...You'd do that?", "mood": "shocked"}],
			[{"who": "Hop", "text": "He is. He's always right.", "mood": "sad"}, {"who": "Hop", "text": "...Nobody's ever said that out loud before, though.", "mood": "shocked"}]]},
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
	# (Checks the stored partner: partner() already says Big Joe once Hop has left.)
	if str(Game.flags.get("partner", "Hop")) == "Hop":
		Game.set_partner("BigJoe6")
	else:
		Game._build_partner()
	# #1: the couch, not the bunk (Hop's note is waiting there).
	Game.set_objective("Get some sleep. (The couch in the base.)")
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
		{"who": "Relic", "tag": "", "face": false, "text": Game.corps_dead_count()},
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
