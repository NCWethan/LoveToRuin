extends Area
## The burned hills (fragment 10): the hills behind Westview Field, where the fire
## went five years ago. Black stumps, ash, a fire road switchbacking up, and new
## green coming up through it, a little, where a Firefighter has been planting
## saplings every weekend since. At the top, where you can see the field (and the
## crater), Ember: what's left of the fire.
##
## Ember (hills_battles.gd) has the fragment. Hitting it feeds it; spare it by
## letting it burn out. Its KEEPSAKE is the tent on Westview Field, the night
## before the fire: "Room for three."
##
## Reached by bus (from any stop) once fragment 9 is found.
##
##   Corps      Ronin is at the top, with the others behind him. He learns to hold
##              his fire still. The Corps keeps this fragment whole: they know now.
##              Then Hopkuna's trail goes north, through the junkyard.
##   Own way    Ronin is at the top: the Corps got here first, and Ember beat them.
##              He stays, in case. He helps anyway.
##   With Hop   Ember doesn't fight. It's Relic's fire; it knows them. Ronin is
##              waiting at the top with his guitar.
##
## Story flags: bh_arrived, bh_ember_done, bh_fragment, has_fragment_10.

const SCENE := "res://scenes/burned_hills.tscn"
const T := Room.TILE
const OUTSIDE := Rect2i(0, 0, 48, 40)
const ENTRY := Vector2(44 * T, 37 * T + 10)
const EMBER_SPOT := Vector2(20 * T, 5 * T)
const RONIN_SPOT := Vector2(20 * T, 9 * T)
const LOOKOUT := Vector2(30 * T, 4 * T + 6)

var partner: Character
var ronin: Character
var ember: Character
var _decor: Node2D
var _shade: Node2D
var _font: Font
var _time: float = 0.0
var _engaged: bool = false
var _from_memory: bool = false


func _ready() -> void:
	_from_memory = not Game.keepsake_after.is_empty() and not Game.playing_relic
	_engaged = str(Game.battle_result.get("id", "")) in ["ember", "corps_ronin"]
	rooms.assign([_px(OUTSIDE)])
	setup_area(ENTRY)
	add_wild_encounters(SCENE, Rect2(T, 12 * T, 46 * T, 22 * T))
	_font = ThemeDB.fallback_font
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	_shade = Node2D.new()
	add_child(_shade)
	_shade.draw.connect(_draw_shade)
	_place_people()
	for spot in [[ENTRY + Vector2(10, -8), _bus_stop], [LOOKOUT, _lookout], [Vector2(9 * T + 10, 30 * T + 4), _saplings],
			[Vector2(36 * T + 10, 36 * T + 4), _trailhead_sign]]:
		world.add_child(Hotspot.create(spot[0], spot[1]))
	Game.play_music("burned_hills")
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
	_decor.queue_redraw()
	if ember and is_instance_valid(ember):
		ember.position = EMBER_SPOT + Vector2(0, sin(_time * 3.0) * 2.0)


# --- The map -----------------------------------------------------------------------

func build_map() -> void:
	room.setup(48, 40, Room.SCORCHED)
	room.fill(0, 0, 48, 1, Room.STUMP)
	room.fill(0, 0, 1, 40, Room.STUMP)
	room.fill(47, 0, 1, 40, Room.STUMP)
	# The trailhead: a little gravel lot, a gate, the bus stop.
	room.fill(1, 34, 46, 6, Room.SIDEWALK)
	room.fill(0, 39, 48, 1, Room.TREE)
	room.fill(1, 33, 30, 1, Room.FENCE)
	# The fire road, switchbacking up.
	room.fill(31, 30, 4, 4, Room.DIRT)
	room.fill(6, 30, 29, 2, Room.DIRT)
	room.fill(6, 21, 2, 11, Room.DIRT)
	room.fill(6, 21, 34, 2, Room.DIRT)
	room.fill(38, 11, 2, 12, Room.DIRT)
	room.fill(12, 11, 28, 2, Room.DIRT)
	room.fill(12, 3, 2, 10, Room.DIRT)
	# The clearing at the top, ringed with burned stumps.
	room.fill(10, 1, 24, 9, Room.SCORCHED)
	for k in 14:
		var angle := k * TAU / 14.0
		var at := Vector2(20, 5) + Vector2(cos(angle) * 6.0, sin(angle) * 3.5)
		var tile := Vector2i(roundi(at.x), roundi(at.y))
		if tile.y > 7 and absi(tile.x - 20) < 3:
			continue
		room.set_tile(tile.x, tile.y, Room.STUMP)
	# Burned trees everywhere else, off the road.
	for spot in [Vector2i(3, 5), Vector2i(5, 14), Vector2i(10, 17), Vector2i(15, 26), Vector2i(22, 16), Vector2i(26, 26), Vector2i(30, 15),
			Vector2i(34, 6), Vector2i(43, 8), Vector2i(44, 17), Vector2i(42, 27), Vector2i(17, 33), Vector2i(3, 27), Vector2i(26, 7)]:
		room.set_tile(spot.x, spot.y, Room.STUMP)
	# A few patches of new grass, where the Firefighter has been planting.
	for spot in [Vector2i(8, 28), Vector2i(10, 28), Vector2i(12, 29), Vector2i(20, 27), Vector2i(36, 19), Vector2i(24, 14)]:
		room.fill(spot.x, spot.y, 2, 1, Room.GRASS)


func _draw_decor() -> void:
	# Ash drifting across the hill.
	for k in 26:
		var at := Vector2(fmod(k * 131.0 + _time * 14.0, 48.0 * T), fmod(k * 59.0 + _time * 6.0, 34.0 * T))
		_decor.draw_rect(Rect2(at, Vector2(2, 2)), Color(0.75, 0.72, 0.7, 0.5))
	# Saplings, each with a little stake and a tag.
	for spot in [Vector2(8.5, 28), Vector2(10.5, 28), Vector2(12.5, 29), Vector2(20.5, 27), Vector2(36.5, 19), Vector2(24.5, 14)]:
		var at: Vector2 = spot * T + Vector2(0, 8)
		_decor.draw_line(at, at + Vector2(0, -12), Color8(110, 80, 50), 2.0)
		_decor.draw_circle(at + Vector2(0, -12), 4.0, Color8(80, 170, 80))
	# The lookout: a railing and, far below, Westview Field with its crater.
	_decor.draw_rect(Rect2(28 * T, 3 * T, 5 * T, 4), Color8(150, 120, 90))
	_decor.draw_string(_font, Vector2(28 * T, 2 * T + 14), "LOOKOUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(230, 220, 200))
	# Ember's glow on the ground, if it's still burning.
	if ember and is_instance_valid(ember):
		var pulse := 0.6 + 0.4 * sin(_time * 5.0)
		_decor.draw_circle(EMBER_SPOT + Vector2(0, 10), 60.0, Color(1.0, 0.4, 0.1, 0.1 * pulse))
		_decor.draw_circle(EMBER_SPOT + Vector2(0, 10), 30.0, Color(1.0, 0.6, 0.2, 0.12 * pulse))
	# The trailhead sign, and the bus stop.
	_decor.draw_rect(Rect2(36 * T, 35 * T, 2 * T, 16), Color8(110, 80, 50))
	_decor.draw_string(_font, Vector2(36 * T + 4, 35 * T + 12), "FIRE RD", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(240, 230, 210))
	_decor.draw_rect(Rect2(ENTRY + Vector2(8, -46), Vector2(3, 38)), Color8(150, 150, 156))
	_decor.draw_rect(Rect2(ENTRY + Vector2(0, -54), Vector2(20, 12)), Color8(40, 90, 190))
	_decor.draw_string(_font, ENTRY + Vector2(2, -44), "BUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)


## A hazy, orange-gray sky over everything.
func _draw_shade() -> void:
	_shade.draw_rect(_px(OUTSIDE), Color(0.6, 0.35, 0.2, 0.12))


# --- People ----------------------------------------------------------------------

func _place_people() -> void:
	if not Game.walking_alone():
		partner = Cast.make(Game.partner())
		add_character(partner, player.position + Vector2(-20, 0))
		partner.follow = player
	add_person("firefighter", Vector2(11 * T, 31 * T), SCENE)
	if Game.partner() != "Ronin" and not flag("beat_corps_ronin"):
		ronin = add_npc("Ronin", RONIN_SPOT + Vector2(0, 30 if _genocide() else 0), _talk_ronin)
	if not flag("bh_ember_done") and str(Game.battle_result.get("id", "")) != "ember":
		ember = Cast.make("ember")
		ember.glow = true
		ember.glow_color = Color(1.0, 0.6, 0.2, 0.5)
		add_character(ember, EMBER_SPOT)


func _talk_ronin() -> void:
	match _route():
		"pacifist":
			await chat("bh_ronin", [
				{"who": "Ronin", "text": "That's it. That's the fire. What's left of it.", "mood": ""},
				{"who": "Ronin", "text": "I've had fire in my hands my whole life.\nI always throw it. Throwing it is easy.", "mood": ""},
				{"who": "Ronin", "text": "You can't hit that thing. It eats it.\nWe have to wait it out. I don't wait well.", "mood": "angry"},
				{"who": "Ronin", "text": "...If it gets bad, tell me. I'll try something.\nSomething I've never done.", "mood": "sad"},
			], [[{"who": "Ronin", "text": "Don't feed it.", "mood": ""}]])
		"neutral":
			await chat("bh_ronin_neutral", [
				{"who": "Ronin", "text": "We got here first. It beat us.\nIt beat all of us. Nassan's got burns.", "mood": "angry"},
				{"who": "Ronin", "text": "You want to try? Fine. Try.\nI'm staying. In case.", "mood": ""},
				{"who": "Ronin", "text": "...Don't hit it. That's all I learned.\nIt LIKES being hit.", "mood": ""},
			], [[{"who": "Ronin", "text": "In case.", "mood": ""}]])
		_:
			await _confront_ronin()


# --- Things --------------------------------------------------------------------------

func _lookout() -> void:
	await Game.dialogue.say([
		"* (The lookout. Down the hill: Westview Field.)",
		"* (From up here you can see the crater in the middle\n*  of it, perfectly round. Like something landed.)",
		"* (Like something left.)",
	])


func _saplings() -> void:
	await Game.dialogue.say(["* (Little trees, each one tied to a stake.\n*  Each one has a tag with a name on it.)", "* (One of them says RELIC. Someone wrote it\n*  very small.)"])


func _trailhead_sign() -> void:
	await Game.dialogue.say(["* (FIRE ROAD. CLOSED DURING HIGH WINDS.)", "* (Under it, a smaller sign, older:\n*  5 YEARS AGO TODAY. WE REMEMBER.)"])


func _bus_stop() -> void:
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
	if id in ["ember", "corps_ronin"]:
		Game.battle_result = {}
	match id:
		"ember":
			await run_cutscene(_after_ember.bind(spared))
			return
		"corps_ronin":
			await run_cutscene(_after_ronin)
			return
	if await handle_person_return():
		return
	if not flag("bh_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked() or _engaged:
		return
	check_random_encounter(SCENE)
	if _genocide() and ronin and is_instance_valid(ronin) and player.position.distance_to(ronin.position) < 80.0:
		run_cutscene(_confront_ronin)
		return
	if ember and is_instance_valid(ember) and player.position.distance_to(EMBER_SPOT) < 70.0:
		if _genocide() and ronin and is_instance_valid(ronin):
			return
		run_cutscene(_meet_ember)


func _arrival() -> void:
	Game.flags["bh_arrived"] = true
	await Game.dialogue.say([
		"* (The hills behind Westview Field. Where the fire\n*  went, five years ago.)",
		"* (Black stumps. Ash. A fire road going up.\n*  Here and there, something small and green.)",
		"* (At the top of the hill, something is still burning.)",
	])
	match _route():
		"pacifist":
			Game.set_objective("The top of the hill. (Ronin's there.)")
		"neutral":
			Game.set_objective("The top of the hill.")
		_:
			await Game.dialogue.say([
				"* (Hop stops at the bottom of the fire road.\n*  He won't look up the hill.)",
				{"who": "Relic", "tag": "", "face": false, "text": "* Smell that? That's us.\n* That's what's left of us."},
			])
			Game.set_objective("...")


func _meet_ember() -> void:
	if _engaged:
		return
	_engaged = true
	if _genocide():
		await _ember_knows_us()
		return
	ember.face(player.position - ember.position)
	await Game.dialogue.say([
		"* (Ember turns toward you. The heat is like\n*  opening an oven.)",
		"* (Inside the red, very faintly, something green.)",
		"* (It's the same fire. You'd know it anywhere.\n*  You've never seen it before. You know it anyway.)",
	])
	if ronin and is_instance_valid(ronin):
		await Game.dialogue.say([{"who": "Ronin", "text": "DON'T hit it. Whatever you do.", "mood": "shocked"}])
	await Game.start_battle("ember", SCENE, player.position)


func _after_ember(_spared: bool) -> void:
	Game.flags["bh_ember_done"] = true
	await Game.dialogue.say([
		"* (Ember gutters. It's just a coal now, in the ash.)",
		"* (It looks up at you. The green inside it is\n*  brighter than the red, now.)",
		"* (It goes out. Gently. Like it was tired.)",
		"* (In the ash where it was, something red.)",
	])
	if _route() == "pacifist" and ronin:
		await Game.dialogue.say([
			{"who": "Ronin", "text": "...I held it still. Did you see?\nI've never held it still. Not once.", "mood": "shocked"},
		])
	await _take_fragment()


## With Hop: Ember doesn't fight. It knows who we are.
func _ember_knows_us() -> void:
	await Game.dialogue.say([
		"* (Ember sees you. It goes very, very still.)",
		"* (Then it bows, down into the ash,\n*  like a dog that knows whose it is.)",
		{"who": "Relic", "tag": "", "face": false, "text": "* It remembers us."},
		"* (You reach into it. It doesn't even burn.)",
	])
	ember.queue_free()
	ember = null
	Game.flags["bh_ember_done"] = true
	await _take_fragment()


func _take_fragment() -> void:
	Game.play_sfx("fragment")
	await Game.dialogue.say([
		"* (You pick it up. It's warm, and it hums.)",
		"* (You got the tenth FRAGMENT.)",
	])
	Game.flags["bh_fragment"] = true
	Game.flags["has_fragment_10"] = true
	Game.flags["fragments"] = maxi(int(Game.flags.get("fragments", 9)), 10)
	match _route():
		"pacifist":
			if ronin:
				await Game.dialogue.say([{"who": "Ronin", "text": "We're not breaking this one. Not this one.\nNot ever again. We know now.", "mood": ""}])
			Game.set_objective("10 of 12. (We're keeping this one whole.)")
		"neutral":
			Game.set_objective("10 of 12 FRAGMENTS.")
		_:
			Game.set_objective("...")
	await Game.dialogue.say(["* (The fragment is warm in your hand.\n*  You close your eyes.)"])
	await Game.play_keepsakes([10], SCENE, player.position, [
		"* (A tent, on Westview Field. Room for three.)",
		"* (That night, the voice wasn't quiet.)",
	])


func _after_memory() -> void:
	match _route():
		"pacifist":
			await Game.dialogue.say([
				"* (Ronin's phone buzzes. Nassan.)",
				{"who": "Ronin", "text": "...Hopkuna's trail. Burned grass, all the way north.\nPast the freeway. Through the junkyard.", "mood": ""},
				{"who": "Ronin", "text": "Everybody's meeting there. Come on.", "mood": ""},
			])
			Game.set_objective("10 of 12. (Hopkuna's trail: the junkyard. To be continued.)")
		"neutral":
			Game.set_objective("10 of 12 FRAGMENTS. (To be continued.)")
		_:
			Game.set_objective("...")


# --- With Hop: Ronin -----------------------------------------------------------------

func _confront_ronin() -> void:
	if not ronin or not is_instance_valid(ronin) or _engaged:
		return
	_engaged = true
	ronin.face(player.position - ronin.position)
	await Game.dialogue.say([
		"* (Ronin is standing in front of the fire, with\n*  his guitar plugged into an amp that isn't\n*  plugged into anything.)",
		"* (He doesn't say anything.)",
		"* (He looks at Hop, once. Hop looks away.)",
		"* (He starts to play.)",
	])
	if Game.has_sfx("ronin_riff"):
		Game.play_sfx("ronin_riff")
	await Game.start_battle("corps_ronin", SCENE, player.position)


func _after_ronin() -> void:
	if ronin:
		ronin.queue_free()
		ronin = null
	var kept: Array = Game.flags.get("mementos", [])
	if not "Guitar Pick" in kept:
		kept.append("Guitar Pick")
	Game.flags["mementos"] = kept
	await Game.dialogue.say([
		"* (A guitar pick, in the ash. Red. Bitten at\n*  the corner, the way he always bit them.)",
		"* (You keep it.)",
		{"who": "Relic", "tag": "", "face": false, "text": "* Eight."},
	])
	_engaged = false
	Game.set_objective("...")
