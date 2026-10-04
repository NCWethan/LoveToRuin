extends Area
## Chapter 1's starting area: outside Mt. Carmel High School.
##
## Story beats here, in order (each one sets a flag in Game.flags):
##   arrived            Elric shows up; controls are explained.
##   met_hop            Talk to Hop by the front doors; he starts following.
##   has_fragment_1     Find the glowing fragment by the bleachers.
##   tutorial_started   Leaving the field, Eggo and BigJoe6 confront Elric -> battle.
##   tutorial_done      After the battle, they react to how it went.
## Then the road at the bottom leads on to the PQ Mall.

const SCENE := "res://scenes/mt_carmel.tscn"
const MALL_SCENE := "res://scenes/pq_mall.tscn"

const START := Vector2(130, 470)            # on the bottom sidewalk, just off the road
## Where Elric appears when walking back from the PQ Mall.
const FROM_MALL := Vector2(900, 470)
const HOP_SPOT := Vector2(350, 238)         # in front of the school doors
const FRAGMENT_SPOT := Vector2(870, 360)    # in the field, by the bleachers
const SAVE_SPOT := Vector2(470, 370)        # in the courtyard
const ROAD_Y := 500.0                       # walking below this means "leaving"
const FIELD_EDGE_X := 570.0                 # walking left of this after the fragment triggers the ambush

var hop: Character
var fragment: Character
var eggo: Character
var bigjoe: Character


func _ready() -> void:
	setup_area(START)
	Game.play_music("mt_carmel")
	_place_characters()
	_start_story.call_deferred()


func _flag(name: String) -> bool:
	return flag(name)


# --- The map --------------------------------------------------------------

func build_map() -> void:
	room.setup(48, 30, Room.GRASS)

	# Trees around the edges.
	room.fill(0, 0, 48, 1, Room.TREE)
	room.fill(0, 1, 1, 24, Room.TREE)
	room.fill(47, 1, 1, 24, Room.TREE)

	# The school building: roof, brick wall, two rows of windows, front doors.
	room.fill(4, 1, 28, 2, Room.ROOF)
	room.fill(4, 3, 28, 7, Room.WALL)
	for x in range(6, 31, 3):
		room.set_tile(x, 4, Room.WINDOW)
		room.set_tile(x, 7, Room.WINDOW)
	room.fill(16, 7, 3, 3, Room.WALL)
	room.fill(16, 8, 3, 2, Room.DOOR)

	# Trees on the lawn beside the school.
	for spot in [Vector2i(35, 3), Vector2i(39, 6), Vector2i(43, 2), Vector2i(44, 7), Vector2i(36, 8)]:
		room.set_tile(spot.x, spot.y, Room.TREE)

	# Sidewalk along the front of the school.
	room.fill(1, 10, 46, 3, Room.SIDEWALK)

	# Parking lot (left).
	room.fill(1, 13, 14, 10, Room.ASPHALT)
	for x in range(2, 14, 3):
		room.fill(x, 14, 1, 3, Room.PARKING_LINE)
		room.fill(x, 19, 1, 3, Room.PARKING_LINE)

	# Courtyard (middle): a path, benches, a couple of trees.
	room.fill(18, 13, 3, 10, Room.SIDEWALK)
	room.fill(23, 15, 2, 1, Room.BENCH)
	room.fill(23, 20, 2, 1, Room.BENCH)
	room.set_tile(16, 17, Room.TREE)
	room.set_tile(26, 18, Room.TREE)

	# Sports field (right), fenced in, with bleachers and a gap in the fence.
	room.fill(29, 13, 18, 10, Room.FENCE)
	room.fill(30, 14, 16, 8, Room.FIELD)
	room.fill(30, 14, 16, 2, Room.BLEACHERS)
	room.fill(37, 16, 1, 6, Room.FIELD_LINE)
	room.fill(29, 18, 1, 2, Room.SIDEWALK)

	# Sidewalk and road at the bottom.
	room.fill(1, 23, 46, 2, Room.SIDEWALK)
	room.fill(0, 25, 48, 5, Room.ROAD)
	room.fill(0, 27, 48, 1, Room.ROAD_LINE)


# --- People and things ----------------------------------------------------

func _place_characters() -> void:
	# Hop: by the doors until you meet him, then following Elric.
	hop = Cast.make("Hop")
	if _flag("met_hop"):
		hop.position = player.position + Vector2(0, -20)
		hop.follow = player
	else:
		hop.position = HOP_SPOT
		hop.on_interact = _talk_to_hop
	world.add_child(hop)

	# The fragment, until Elric picks it up.
	if not _flag("has_fragment_1"):
		fragment = Character.new().setup(preload("res://art/sprites/fragment.png"), null, false)
		fragment.position = FRAGMENT_SPOT
		fragment.glow = true
		fragment.on_interact = _inspect_fragment
		world.add_child(fragment)

	# A SAVE point in the courtyard.
	var star := Character.new().setup(preload("res://art/sprites/save_star.png"), null, false)
	star.position = SAVE_SPOT
	star.glow = true
	star.glow_color = Color(1.0, 1.0, 1.0, 0.55)
	star.on_interact = _use_save_point
	world.add_child(star)


func _make_enemy_npc(who: String, at: Vector2) -> Character:
	var npc := Cast.make(who)
	npc.position = at
	world.add_child(npc)
	return npc


# --- Story ----------------------------------------------------------------

func _start_story() -> void:
	# Wait for the fade-in to finish before any cutscene starts.
	while Game.transitioning:
		if not is_inside_tree():
			return
		await get_tree().process_frame

	if _flag("tutorial_started") and not _flag("tutorial_done"):
		await _after_tutorial_battle()
	elif not _flag("arrived"):
		await _arrival()


func _physics_process(_delta: float) -> void:
	if Game.busy or Game.transitioning or _cutscene_running:
		return

	# Leaving the field with the fragment: Eggo and BigJoe6 show up.
	if _flag("has_fragment_1") and not _flag("tutorial_started") and player.position.x < FIELD_EDGE_X:
		_run(_ambush)
	# Walking out onto the road.
	elif player.position.y > ROAD_Y:
		_run(_try_to_leave)


func _run(cutscene: Callable) -> void:
	await run_cutscene(cutscene)


func _arrival() -> void:
	_cutscene_running = true
	Game.busy = true
	await Game.dialogue.say([
		"* (Mt. Carmel High School.)",
		"* (School let out a while ago.\n*  The campus is quiet.)",
		"* (Use the ARROW KEYS to walk.\n*  Press Z to talk to people or look at things.)",
	])
	Game.flags["arrived"] = true
	Game.busy = false
	_cutscene_running = false


func _talk_to_hop() -> void:
	hop.face(player.position - hop.position)
	await Game.dialogue.say([
		{"who": "Hop", "text": "Hey. You lost?\nYou've got the whole \"nowhere to be\" look going on.", "mood": "smug"},
		{"who": "Hop", "text": "Name's Hop. I'd shake your hand, but I just did\nforty push-ups and I can't feel my arms.", "mood": "happy"},
		"* (You tell Hop your name.)",
		{"who": "Hop", "text": "Elric, huh? Very \"mysterious traveler.\"\nIs that the vibe? That's totally the vibe.", "mood": "smug"},
		{"who": "Hop", "text": "Well, mysterious traveler, you picked the most\nboring place in San Diego to be mysterious."},
		{"who": "Hop", "text": "...Unless you count that weird glow\nover by the bleachers. It's been there all day."},
		{"who": "Hop", "text": "Wanna go poke it? I'll race you.\nI'll win, obviously. But you can try.", "mood": "happy"},
		"* (Hop is now following you.)",
	])
	Game.flags["met_hop"] = true
	hop.on_interact = Callable()
	hop.remove_from_group("interactable")
	hop.follow = player


func _inspect_fragment() -> void:
	if not _flag("met_hop"):
		await Game.dialogue.say([
			"* (Something is glowing in the grass.\n*  It's dark red, and it's... humming?)",
			"* (You get the feeling you shouldn't touch it alone.)",
		])
		return

	Game.play_sfx("fragment")
	await Game.dialogue.say([
		"* (A jagged shard, dark red and faintly warm.\n*  It hums, like it's breathing.)",
		{"who": "Hop", "text": "...Huh.", "mood": "shocked"},
		{"who": "Hop", "text": "Okay. That's definitely not a rock.", "mood": "shocked"},
	])
	var choice := await Game.dialogue.ask("* (Pick it up?)", ["Yes", "No"])
	if choice == 1:
		await Game.dialogue.say([
			{"who": "Hop", "text": "Smart. It's probably radioactive.\n...Probably.", "mood": "smug"},
		])
		return

	Game.play_sfx("fragment")
	await Game.dialogue.say([
		"* (You pick up the shard.)",
		"* (For a moment, the hum gets louder.\n*  Then it goes quiet.)",
		"* (You got the FRAGMENT.)",
		"* (Hop stares at it a little too long.)",
		{"who": "Hop", "text": "...Anyway! Cool rock. Very sparkly.", "mood": "happy"},
		{"who": "Hop", "text": "Let's get out of here before somebody\nthinks we stole school property.", "mood": "happy"},
	])
	Game.flags["has_fragment_1"] = true
	Game.flags["fragments"] = 1
	fragment.queue_free()


func _use_save_point() -> void:
	Game.play_sfx("heal")
	Game.heal_party()
	await Game.dialogue.say([
		"* (The quiet school courtyard.\n*  A breeze rolls through the trees.)",
		"* (It fills you with DETERMINATION.)",
		"* (Everyone's HP was restored.)",
	])
	var choice := await Game.dialogue.ask("* (Save your progress?)", ["Save", "Return"])
	if choice == 0:
		Game.save_game(SCENE, player.position)
		Game.play_sfx("save")
		await Game.dialogue.say(["* (File saved.)"])


func _try_to_leave() -> void:
	if not _flag("tutorial_done"):
		await Game.dialogue.say(["* (You feel like you should look around\n*  a little more before moving on.)"])
		var tween := create_tween()
		tween.tween_property(player, "position:y", ROAD_Y - 16.0, 0.25)
		await tween.finished
		return

	if not _flag("mall_arrived"):
		await Game.dialogue.say([
			{"who": "Hop", "text": "PQ Mall's this way. Keep up, mysterious traveler.", "mood": "happy"},
		])
	await Game.change_scene(MALL_SCENE)


# --- The tutorial fight ---------------------------------------------------

func _ambush() -> void:
	Game.flags["tutorial_started"] = true

	# Eggo and BigJoe6 come over from the parking lot.
	# They start just off the left edge of the screen.
	var ahead := player.position
	eggo = _make_enemy_npc("Eggo", Vector2(ahead.x - 330, ahead.y - 30))
	bigjoe = _make_enemy_npc("BigJoe6", Vector2(ahead.x - 350, ahead.y + 10))

	# BigJoe6 is still off-screen, so no portrait yet.
	await Game.dialogue.say([{"who": "BigJoe6", "tag": "???", "text": "HOLD IT!", "face": false}])
	# Both walk at once: start Eggo without waiting, then wait for BigJoe6.
	eggo.walk_to(ahead + Vector2(-70, -24), 140.0)
	await bigjoe.walk_to(ahead + Vector2(-60, 16), 160.0)
	await get_tree().create_timer(0.3).timeout

	await Game.dialogue.say([
		{"who": "BigJoe6", "text": "That fragment. Hand it over. Now.", "mood": "angry"},
		{"who": "Eggo", "text": "...hey."},
		{"who": "Hop", "text": "Whoa, whoa. Who are you guys? Hall monitors?", "mood": "shocked"},
		{"who": "BigJoe6", "text": "We're the ones who've been tracking that thing\nfor a week. And you just walked off with it.", "mood": "angry"},
		{"who": "BigJoe6", "text": "Nobody picks up a fragment by accident.\nYou're working for Hopkuna, aren't you?", "mood": "angry"},
		"* (Hop goes very quiet.)",
		{"who": "Elric", "text": "...I'm not."},
		{"who": "BigJoe6", "text": "That's EXACTLY what a lackey would say!", "mood": "angry"},
		{"who": "Eggo", "text": "he's not wrong. that is what a lackey would say.", "mood": "smug"},
		{"who": "Eggo", "text": "...it's also what a not-lackey would say.\njust saying.", "mood": "smug"},
		{"who": "BigJoe6", "text": "Enough talk!", "mood": "angry"},
	])
	await Game.start_battle("tutorial", SCENE, player.position)


func _after_tutorial_battle() -> void:
	_cutscene_running = true
	Game.busy = true

	var result := Game.battle_result
	var spared: Array = result.get("spared", [])
	var defeated: Array = result.get("defeated", [])

	eggo = _make_enemy_npc("Eggo", player.position + Vector2(-70, -24))
	bigjoe = _make_enemy_npc("BigJoe6", player.position + Vector2(-60, 16))
	if not hop.follow:
		hop.position = player.position + Vector2(24, -10)

	if spared.size() == 2:
		Game.flags["tutorial_path"] = "spared"
		await Game.dialogue.say([
			{"who": "BigJoe6", "text": "...Okay. Okay. I believe you.", "mood": "happy"},
			{"who": "BigJoe6", "text": "Nobody working for Hopkuna would've\nheld back like that."},
			{"who": "Eggo", "text": "told you. fragment-ally a good egg.", "mood": "happy"},
			{"who": "Eggo", "text": "...fragment-ally. like \"fundamentally.\"\nno? ok. the egg part was good though.", "mood": "smug"},
			{"who": "BigJoe6", "text": "Listen. That fragment is dangerous. There are more\nout there, and Hopkuna wants every single one."},
			{"who": "BigJoe6", "text": "We're Revolution. Eggo and I started it\nto stop him."},
			{"who": "Eggo", "text": "membership: two. we're very exclusive.\nnot on purpose.", "mood": "happy"},
			{"who": "BigJoe6", "text": "If you're sticking around, head toward the PQ Mall.\nAnd keep that fragment safe."},
		])
	elif defeated.size() == 2:
		Game.flags["tutorial_path"] = "fought"
		await Game.dialogue.say([
			{"who": "BigJoe6", "text": "Ugh... you're stronger than you look...", "mood": "sad"},
			{"who": "Eggo", "text": "ow. ...ow.", "mood": "sad"},
			{"who": "BigJoe6", "text": "This isn't over. If you're with Hopkuna,\nRevolution WILL stop you.", "mood": "angry"},
		])
	else:
		Game.flags["tutorial_path"] = "mixed"
		await Game.dialogue.say([
			{"who": "BigJoe6", "text": "...I still don't know what to make of you."},
			{"who": "Eggo", "text": "same. but in a chill way.", "mood": "happy"},
			{"who": "BigJoe6", "text": "We'll be watching. Revolution doesn't\nlet fragments just walk around."},
		])

	# They head off toward the road.
	eggo.walk_to(Vector2(eggo.position.x - 40, 560), 120.0)
	await bigjoe.walk_to(Vector2(bigjoe.position.x - 40, 560), 120.0)
	await get_tree().create_timer(0.4).timeout
	eggo.queue_free()
	bigjoe.queue_free()

	match Game.flags["tutorial_path"]:
		"spared":
			await Game.dialogue.say([
				{"who": "Hop", "text": "...Revolution, huh.", "mood": "sad"},
				{"who": "Hop", "text": "Well! That's the most exciting thing to happen here\nsince the vending machine caught fire.", "mood": "happy"},
				{"who": "Hop", "text": "Mall's down the road. C'mon, mysterious traveler."},
			])
		"fought":
			await Game.dialogue.say([
				{"who": "Hop", "text": "...Remind me to never make you mad.", "mood": "shocked"},
				{"who": "Hop", "text": "Maybe go easier next time?\nThey didn't seem THAT evil.", "mood": "sad"},
				{"who": "Hop", "text": "Anyway. Mall's down the road. C'mon."},
			])
		_:
			await Game.dialogue.say([
				{"who": "Hop", "text": "Okay, that got intense.", "mood": "shocked"},
				{"who": "Hop", "text": "Mall's down the road. Let's go before they come back."},
			])

	Game.flags["tutorial_done"] = true
	Game.battle_result = {}
	Game.busy = false
	_cutscene_running = false
