extends Area
## The junkyard by the freeway (no fragment): a chain-link fence, mountains of
## junk, stacks of crushed cars, an office shack, and a crane with a car crusher
## for a body (Scrap Heap). In the back corner, under a tarp, a van that's been
## sitting there for years. Sansworth has been looking for "his car" the whole
## game. It was always this one: an uncle he forgot he had left it to him.
##
## Reached by bus once fragment 10 is found.
##
##   Corps      Everyone cuts through here on Hopkuna's trail. Scrap Heap's in the
##              way (Sansworth's keys calm it down). Sansworth finds the van. One
##              of his 31 keys starts it: "I TOLD you I had a car." Then Nassan
##              admits what he's known all along: one of the twelve circles was
##              always on Hop's house.
##   Own way    Elric gets past Scrap Heap alone, and watches from behind the junk
##              as the Corps finds the van and cheers. Nobody sees Elric.
##   With Hop   Sansworth is at the van. It never starts.
##
## Story flags: jy_arrived, jy_heap_done, jy_van, jy_nassan.

const SCENE := "res://scenes/junkyard.tscn"
const T := Room.TILE
const OUTSIDE := Rect2i(0, 0, 56, 36)
const ENTRY := Vector2(51 * T, 32 * T + 10)
const HEAP_SPOT := Vector2(28 * T, 12 * T)
const VAN := Rect2(4 * T, 24 * T, 5 * T, 3 * T)
const VAN_FRONT := Vector2(10 * T, 26 * T)
const SANSWORTH_SPOT := Vector2(10 * T + 10, 25 * T)
const NASSAN_SPOT := Vector2(44 * T, 28 * T)

var partner: Character
var heap: Character
var sansworth: Character
var nassan: Character
var _decor: Node2D
var _shade: Node2D
var _font: Font
var _time: float = 0.0
var _engaged: bool = false
var _van_running: float = -1.0


func _ready() -> void:
	_engaged = str(Game.battle_result.get("id", "")) in ["scrap_heap", "corps_sansworth"]
	rooms.assign([_px(OUTSIDE)])
	setup_area(ENTRY)
	add_wild_encounters(SCENE, Rect2(T, 14 * T, 54 * T, 20 * T))
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
	for spot in [[ENTRY + Vector2(10, -8), _bus_stop], [VAN_FRONT + Vector2(0, 10), _van], [Vector2(8 * T + 10, 6 * T + 4), _shack],
			[Vector2(40 * T, 20 * T + 4), _car_stack]]:
		world.add_child(Hotspot.create(spot[0], spot[1]))
	Game.play_music("junkyard")
	if flag("jy_van"):
		_van_running = 0.0
	fit_camera_to_room()
	_start.call_deferred()


static func _px(r: Rect2i) -> Rect2:
	return Rect2(r.position * T, r.size * T)


func _genocide() -> bool:
	return Game.on_genocide_route()


func _route() -> String:
	return str(Game.flags.get("route", ""))


func _process(delta: float) -> void:
	_time += delta
	if _van_running >= 0.0:
		_van_running += delta
	_decor.queue_redraw()


# --- The map -----------------------------------------------------------------------

## Set dressing (props.gd): wrecked cars, a couch and a fridge and a dead arcade
## cabinet out between the piles, a dumpster by the shack, pallets, barrels, crates,
## a stray cart, oil puddles.
func _dress() -> void:
	add_dressing([
		["dumpster", Vector2(15 * T, 4 * T + 10)],
		["trash_bag", Vector2(16 * T + 14, 6 * T + 6), {"walkable": true}],
		["sign", Vector2(13 * T + 10, 7 * T + 4), {"text": "BEWARE OF DOG", "color": Color8(170, 40, 35), "look": ["* (BEWARE OF DOG.)", "* (There is no dog. There's a very old cat on the\n*  shack's roof, and it's looking at you.)"]}],
		["couch", Vector2(26 * T, 9 * T), {"color": Color8(120, 90, 140), "look": ["* (A purple couch, out in the open. It's still\n*  comfy. There's 35 cents in the cushions.)"]}],
		["fridge", Vector2(24 * T, 15 * T), {"look": ["* (An old fridge with no door. Magnets on the side:\n*  a pizza place, a dentist, a little Eiffel Tower.)"]}],
		["arcade", Vector2(12 * T, 20 * T), {"look": ["* (An arcade cabinet. The screen is cracked.\n*  HIGH SCORE: RLC  999999.)"]}],
		["cart", Vector2(31 * T, 14 * T)],
		["pallet", Vector2(40 * T, 11 * T + 6)],
		["crates", Vector2(52 * T, 4 * T)],
		["barrel", Vector2(42 * T, 24 * T), {"look": ["* (A rusty barrel. Something sloshes inside.\n*  You decide not to find out what.)"]}],
		["barrel", Vector2(43 * T + 4, 24 * T + 8)],
		["car", Vector2(8 * T, 31 * T), {"color": Color8(140, 110, 90), "look": ["* (A rusted-out sedan with no wheels, sitting on\n*  cinderblocks. A bird lives in the glovebox.)"]}],
		["car", Vector2(28 * T, 32 * T), {"color": Color8(170, 100, 60)}],
		["car_v", Vector2(52 * T, 20 * T), {"color": Color8(110, 120, 110)}],
		["puddle", Vector2(26 * T, 21 * T + 10), {"size": Vector2(30, 10)}],
		["puddle", Vector2(48 * T, 25 * T), {"size": Vector2(24, 8)}],
		["bike", Vector2(14 * T, 29 * T), {"color": Color8(200, 60, 55), "look": ["* (A kid's bike with one wheel bent into a taco.\n*  The bell still works. Ding.)"]}],
		["lamp", Vector2(46 * T, 34 * T)],
	])


func build_map() -> void:
	room.setup(56, 36, Room.ASPHALT)
	room.fill(0, 0, 56, 1, Room.FENCE)
	room.fill(0, 0, 1, 36, Room.FENCE)
	room.fill(55, 0, 1, 36, Room.FENCE)
	room.fill(0, 35, 56, 1, Room.FENCE)
	room.fill(47, 35, 8, 1, Room.ASPHALT)        # the gate (open)
	# The office shack.
	room.fill(3, 2, 10, 4, Room.WOOD_WALL)
	room.set_tile(8, 5, Room.DOOR)
	# The crane's pad, and the junk piles all around it.
	for pile in [Rect2i(18, 3, 5, 3), Rect2i(34, 3, 6, 3), Rect2i(44, 6, 7, 4), Rect2i(16, 16, 6, 3), Rect2i(30, 18, 4, 3),
			Rect2i(44, 14, 5, 3), Rect2i(20, 25, 7, 3), Rect2i(34, 27, 5, 3), Rect2i(2, 13, 6, 3)]:
		room.fill(pile.position.x, pile.position.y, pile.size.x, pile.size.y, Room.PROP)
	room.fill(38, 19, 4, 2, Room.PROP)             # the stack of crushed cars
	room.fill(4, 24, 5, 3, Room.PROP)              # the van, under its tarp


func _draw_decor() -> void:
	# Junk on the piles: hubcaps, tires, a fridge, a shopping cart.
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for pile in [Rect2i(18, 3, 5, 3), Rect2i(34, 3, 6, 3), Rect2i(44, 6, 7, 4), Rect2i(16, 16, 6, 3), Rect2i(30, 18, 4, 3),
			Rect2i(44, 14, 5, 3), Rect2i(20, 25, 7, 3), Rect2i(34, 27, 5, 3), Rect2i(2, 13, 6, 3)]:
		var r := _px(pile)
		_decor.draw_rect(r, Color8(110, 95, 80))
		for k in 10:
			var at := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
			match k % 4:
				0: _decor.draw_circle(at, 6.0, Color8(30, 30, 34))
				1: _decor.draw_circle(at, 4.0, Color8(190, 190, 196))
				2: _decor.draw_rect(Rect2(at, Vector2(10, 7)), Color8(150, 80, 60))
				_: _decor.draw_rect(Rect2(at, Vector2(6, 10)), Color8(120, 140, 170))
	# The crushed cars, stacked like pancakes.
	for k in 4:
		_decor.draw_rect(Rect2(38 * T, 19 * T + 30 - k * 9, 4 * T, 8), [Color8(170, 60, 50), Color8(60, 90, 160), Color8(200, 190, 80), Color8(90, 140, 90)][k])
	# The van: tan, boxy, a tarp half off it, flat tires. (Running, it shakes.)
	var shake := Vector2(sin(_time * 40.0) * 1.0, 0) if _van_running >= 0.0 else Vector2.ZERO
	var van := Rect2(VAN.position + shake, VAN.size)
	_decor.draw_rect(van, Color8(200, 180, 140))
	_decor.draw_rect(Rect2(van.position + Vector2(6, 6), Vector2(30, 16)), Color8(120, 160, 190))
	_decor.draw_rect(Rect2(van.position + Vector2(44, 6), Vector2(40, 16)), Color8(120, 160, 190))
	for wx in [van.position.x + 16, van.end.x - 16]:
		_decor.draw_circle(Vector2(wx, van.end.y), 8.0, Color8(30, 30, 34))
	if not flag("jy_van"):
		_decor.draw_colored_polygon(PackedVector2Array([van.position + Vector2(40, -4), van.end + Vector2(4, -10), Vector2(van.end.x + 4, van.position.y - 4)]), Color8(60, 90, 140))
	else:
		# Exhaust.
		for k in 3:
			var age := fmod(_time * 2.0 + k * 0.33, 1.0)
			_decor.draw_circle(Vector2(van.position.x - 6 - age * 20, van.end.y - 6 - age * 16), 4.0 + age * 6.0, Color(0.4, 0.4, 0.42, 0.6 * (1.0 - age)))
	# The shack sign, the gate, the bus stop.
	_decor.draw_string(_font, Vector2(3 * T + 6, 3 * T), "OFFICE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(240, 230, 210))
	_decor.draw_string(_font, Vector2(46 * T, 35 * T - 4), "GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(240, 200, 60))
	_decor.draw_rect(Rect2(ENTRY + Vector2(8, -46), Vector2(3, 38)), Color8(150, 150, 156))
	_decor.draw_rect(Rect2(ENTRY + Vector2(0, -54), Vector2(20, 12)), Color8(40, 90, 190))
	_decor.draw_string(_font, ENTRY + Vector2(2, -44), "BUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	# The freeway, roaring past beyond the back fence.
	for k in 6:
		var x := fmod(k * 210.0 + _time * 160.0, 56.0 * T + 200.0) - 100.0
		_decor.draw_rect(Rect2(x, -6, 40, 6), Color(0.9, 0.9, 1.0, 0.25))


## Overcast, the freeway's noise, a little dusty.
func _draw_shade() -> void:
	_shade.draw_rect(_px(OUTSIDE), Color(0.5, 0.45, 0.4, 0.1))


# --- People ----------------------------------------------------------------------

func _place_people() -> void:
	if not Game.walking_alone():
		partner = Cast.make(Game.partner())
		add_character(partner, player.position + Vector2(-20, 0))
		partner.follow = player
	add_person("junkdealer", Vector2(10 * T, 7 * T + 4), SCENE)
	match _route():
		"pacifist":
			if Game.partner() != "Sansworth":
				sansworth = add_npc("Sansworth", Vector2(46 * T, 30 * T), _talk_sansworth)
			if Game.partner() != "Nassan":
				nassan = add_npc("Nassan", NASSAN_SPOT, _talk_nassan)
		"neutral":
			pass
		_:
			if not flag("beat_corps_sansworth"):
				sansworth = add_npc("Sansworth", SANSWORTH_SPOT, _talk_sansworth)
	if not flag("jy_heap_done") and str(Game.battle_result.get("id", "")) != "scrap_heap":
		heap = Cast.make("scrap_heap")
		heap.glow = true
		heap.glow_color = Color(1.0, 0.85, 0.5, 0.3)
		add_character(heap, HEAP_SPOT)


func _talk_sansworth() -> void:
	match _route():
		"pacifist":
			if flag("jy_van"):
				await chat("jy_sans_after", [{"who": "Sansworth", "text": "I TOLD you I had a car.\nI TOLD everyone. Nobody listens to Sansworth.", "mood": "happy"}], [[{"who": "Sansworth", "text": "VROOM. (For real this time.)", "mood": "happy"}]])
				return
			await chat("jy_sans", [
				{"who": "Sansworth", "text": "My car's here. I can FEEL it.\nIn my keys. All thirty-one of them.", "mood": "happy"},
				{"who": "Sansworth", "text": "I have been looking for my car my WHOLE life.\nI don't remember buying a car. But it's here.", "mood": "smug"},
				{"who": "Sansworth", "text": "That big crane thing's in the way, though.\nIt yelled at me. In crane.", "mood": "sad"},
			], [[{"who": "Sansworth", "text": "Back corner. I just know it.", "mood": "happy"}]])
		_:
			await _confront_sansworth()


func _talk_nassan() -> void:
	if flag("jy_nassan"):
		await chat("jy_nassan_after", [{"who": "Nassan", "text": "Hop's house. That's step two.\nIt was always step two.", "mood": "sad"}], [[{"who": "Nassan", "text": "Let's go.", "mood": ""}]])
		return
	await chat("jy_nassan_first", [
		{"who": "Nassan", "text": "The trail goes right through here.\nBurned tire marks. North, then... it just stops.", "mood": ""},
		{"who": "Nassan", "text": "Get past the crane. Help Sansworth find his...\nwhatever it is. We'll need a way to move fast.", "mood": ""},
	], [[{"who": "Nassan", "text": "The crane. Then the back corner.", "mood": ""}]])


# --- Things --------------------------------------------------------------------------

func _van() -> void:
	if flag("jy_van"):
		await Game.dialogue.say(["* (The van is running. It smells like 1994.)", "* (There's a sticker on the bumper: MY OTHER CAR\n*  IS ALSO THIS CAR.)"])
		return
	await Game.dialogue.say(["* (A van, under a tarp. Tan, boxy, four flat tires.\n*  The registration in the window is very old.)", "* (Under the wiper, a note, sun-faded:\n*  \"FOR MY NEPHEW. HE'LL KNOW WHICH KEY. - UNCLE S.\")"])


func _shack() -> void:
	await Game.dialogue.say(["* (The office. A sign: WE BUY JUNK. WE SELL JUNK.\n*  WE ARE JUNK. - MGMT)"])


func _car_stack() -> void:
	await Game.dialogue.say(["* (Four crushed cars, stacked like pancakes.\n*  One of them still has fuzzy dice.)"])


func _bus_stop() -> void:
	await ride_bus(SCENE)


# --- Story ------------------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if not is_inside_tree():
		return
	var id := str(Game.battle_result.get("id", ""))
	var spared: bool = not Game.battle_result.get("spared", []).is_empty()
	if id in ["scrap_heap", "corps_sansworth"]:
		Game.battle_result = {}
	match id:
		"scrap_heap":
			await run_cutscene(_after_heap.bind(spared))
			return
		"corps_sansworth":
			await run_cutscene(_after_sansworth)
			return
	if await handle_person_return():
		return
	if not flag("jy_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked() or _engaged:
		return
	check_random_encounter(SCENE)
	if heap and is_instance_valid(heap) and player.position.distance_to(heap.position) < 80.0:
		run_cutscene(_meet_heap)
		return
	if _genocide() and not heap and sansworth and is_instance_valid(sansworth) and player.position.distance_to(sansworth.position) < 80.0:
		run_cutscene(_confront_sansworth)


func _arrival() -> void:
	Game.flags["jy_arrived"] = true
	await Game.dialogue.say([
		"* (The junkyard, under the freeway. Mountains of\n*  junk. A crane in the middle, moving by itself.)",
		"* (The crane has a car crusher for a body.\n*  It's sorting. It's been sorting for a long time.)",
	])
	match _route():
		"pacifist":
			await Game.dialogue.say([{"who": "Nassan", "text": "Elric. Over here. The trail comes right through.", "mood": ""}])
			Game.set_objective("Get past the crane. (Scrap Heap.)")
		"neutral":
			await Game.dialogue.say(["* (Tire tracks, burned into the asphalt.\n*  Heading north, straight through.)"])
			Game.set_objective("Get past the crane.")
		_:
			await Game.dialogue.say([
				"* (In the back corner, next to a van under a tarp:\n*  Sansworth, sitting on the bumper, smiling.)",
				{"who": "Hop", "text": "...He's still smiling. Why is he smiling.", "mood": "sad"},
				{"who": "Relic", "tag": "", "face": false, "text": "* He doesn't know any better."},
			])
			Game.set_objective("...")


func _meet_heap() -> void:
	if _engaged:
		return
	_engaged = true
	heap.face(player.position - heap.position)
	await Game.dialogue.say([
		"* (Scrap Heap's magnet swings around to face you.)",
		"* (Its headlights snap on. A car alarm goes off,\n*  somewhere inside it, like a growl.)",
	])
	await Game.start_battle("scrap_heap", SCENE, player.position)


func _after_heap(spared: bool) -> void:
	Game.flags["jy_heap_done"] = true
	if spared:
		await Game.dialogue.say([
			"* (Scrap Heap lowers its magnet. Its headlights dim.)",
			"* (It goes back to sorting. It moves a tire\n*  out of your way. Then a whole car.)",
		])
	else:
		await Game.dialogue.say(["* (Scrap Heap shudders, and stops. Steam hisses out\n*  of it. It doesn't move again.)"])
		if _genocide():
			await Game.dialogue.say([{"who": "Relic", "tag": "", "face": false, "text": "* Scrap."}])
	_engaged = false
	match _route():
		"pacifist":
			await _van_found()
		"neutral":
			await _watch_from_behind()
		_:
			Game.set_objective("...")


## Corps: Sansworth finds his van. One of his 31 keys starts it.
func _van_found() -> void:
	if sansworth:
		sansworth.follow = null
		await sansworth.walk_to(VAN_FRONT + Vector2(20, 20), 140.0)
		sansworth.face(Vector2.LEFT)
	await Game.dialogue.say([
		{"who": "Sansworth", "text": "...", "mood": "shocked"},
		{"who": "Sansworth", "text": "That's my car.", "mood": "shocked"},
		"* (He pulls off the tarp. A van. Tan, boxy,\n*  very old. There's a note under the wiper.)",
		"* (\"FOR MY NEPHEW. HE'LL KNOW WHICH KEY.\")",
		{"who": "Sansworth", "text": "I have an UNCLE?", "mood": "shocked"},
		"* (He tries a key. It doesn't fit. He tries another.)",
		"* (...)",
		"* (Key thirty-one.)",
		"* (The van coughs, and shakes, and STARTS.)",
	])
	Game.flags["jy_van"] = true
	_van_running = 0.0
	Game.play_sfx("honk" if Game.has_sfx("honk") else "brakes")
	await Game.dialogue.say([
		{"who": "Sansworth", "text": "I TOLD you I had a car!", "mood": "happy"},
		{"who": "Sansworth", "text": "I TOLD EVERYONE I HAD A CAR!", "mood": "happy"},
		"* (He did. Nobody believed him. He didn't know\n*  he had a car either.)",
	])
	await _nassan_admits()


func _nassan_admits() -> void:
	if nassan:
		await nassan.walk_to(player.position + Vector2(40, 0), 100.0)
		nassan.face(player.position - nassan.position)
	Game.flags["jy_nassan"] = true
	await Game.dialogue.say([
		{"who": "Nassan", "text": "Elric. I need to tell you something. All of you.", "mood": "sad"},
		{"who": "Nassan", "text": "The map. Twelve circles. I made it the first week.\nOne of them was always on Hop's house.", "mood": "sad"},
		{"who": "Nassan", "text": "I knew. From the start. I never said anything,\nbecause I couldn't plan around my friend lying to me.", "mood": "sad"},
		{"who": "Nassan", "text": "I thought if I didn't say it, it wasn't real.", "mood": "sad"},
		{"who": "Nassan", "text": "Fragment eleven is at Hop's house.\nAnd if Hopkuna knows that, he's going there next.", "mood": ""},
		{"who": "Sansworth", "text": "EVERYBODY IN THE VAN.", "mood": "happy"},
	])
	Game.set_objective("Hop's house. (Fragment eleven. To be continued.)")


## Own way: Elric watches from behind the junk as the Corps finds the van.
func _watch_from_behind() -> void:
	await Game.dialogue.say([
		"* (Voices, at the gate. You duck behind a pile of hubcaps.)",
		"* (The Corps. All of them, minus one. They walk right past.)",
	])
	var crowd: Array[Character] = []
	for i in 4:
		var who: String = ["Sansworth", "Nassan", "BigJoe6", "NCWethan"][i]
		var member := add_character(Cast.make(who), ENTRY + Vector2(-30 * i, 0))
		crowd.append(member)
	for member in crowd:
		member.walk_to(VAN_FRONT + Vector2(30 + crowd.find(member) * 24, 30), 120.0)
	await get_tree().create_timer(2.2).timeout
	Game.flags["jy_van"] = true
	_van_running = 0.0
	await Game.dialogue.say([
		"* (Sansworth pulls a tarp off a van, and starts\n*  trying keys. Thirty-one of them.)",
		"* (The thirty-first one works.)",
		{"who": "Sansworth", "text": "I TOLD you I had a car!", "mood": "happy"},
		"* (Everyone cheers. N.C. picks Sansworth up.\n*  Big Joe is crying a little.)",
		"* (Nobody looks behind the hubcaps.)",
		{"who": "Relic", "tag": "", "face": false, "text": "* (quietly) You could still go over there."},
		"* (You don't.)",
	])
	Game.set_objective("Hop's house. (The last circle on the map.)")


# --- With Hop: Sansworth ---------------------------------------------------------------

func _confront_sansworth() -> void:
	if not sansworth or not is_instance_valid(sansworth) or _engaged:
		return
	_engaged = true
	sansworth.face(player.position - sansworth.position)
	await Game.dialogue.say([
		{"who": "Sansworth", "text": "ELRIC! HOP! You came! I found my CAR!", "mood": "happy"},
		{"who": "Sansworth", "text": "It's a van. It's MY van. I'm gonna drive\neverybody somewhere safe! Where's everybody?", "mood": "happy"},
		"* (He looks at you, and at Hop, and at the gate.\n*  Nobody else is coming.)",
		{"who": "Sansworth", "text": "...Oh.", "mood": "sad"},
		{"who": "Sansworth", "text": "That's okay. Shotgun's open. Get in.\nI'll drive. I just need the right key.", "mood": "happy"},
		{"who": "Hop", "text": "Sansworth. RUN. Please. Just run.", "mood": "sad"},
		{"who": "Sansworth", "text": "I can't run, Hop. I've got a car now.", "mood": "happy"},
	])
	await Game.start_battle("corps_sansworth", SCENE, player.position)


func _after_sansworth() -> void:
	if sansworth:
		sansworth.queue_free()
		sansworth = null
	var kept: Array = Game.flags.get("mementos", [])
	if not "One of His Keys" in kept:
		kept.append("One of His Keys")
	Game.flags["mementos"] = kept
	await Game.dialogue.say([
		"* (Thirty-one keys on the asphalt.)",
		"* (You pick one up. It's the thirty-first.\n*  It would have started the van.)",
		"* (You keep it.)",
		{"who": "Relic", "tag": "", "face": false, "text": Game.corps_dead_count()},
	])
	_engaged = false
	Game.set_objective("...")
