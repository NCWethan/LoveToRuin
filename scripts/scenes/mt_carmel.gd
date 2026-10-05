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
const CAR_SCRIPT := preload("res://scripts/overworld/car.gd")

const START := Vector2(130, 470)            # on the bottom sidewalk, just off the road
## Where Elric appears when walking back from the PQ Mall.
const FROM_MALL := Vector2(900, 470)
const HOP_SPOT := Vector2(350, 238)         # in front of the school doors
const FRAGMENT_SPOT := Vector2(870, 360)    # in the field, by the bleachers
const SAVE_SPOT := Vector2(470, 370)        # in the courtyard
const ROAD_Y := 500.0                       # walking below this means "leaving"
const FIELD_EDGE_X := 570.0                 # walking left of this after the fragment triggers the ambush
## The field gate (two tiles tall) and the tree the gate key is stuck in.
const GATE_CELL := Vector2i(29, 18)
const KEY_TREE := Vector2i(16, 17)
## Where the "MC" is painted on the field, and where the Sundevils banner hangs.
const FIELD_LOGO := Vector2(760, 375)
const SUNDEVIL_BANNER := Vector2(760, 300)
const CURB_Y := 488.0                      # the bottom sidewalk, right at the curb
const CAR_LANE_Y := 538.0                   # where a car's wheels touch the road (the near lane)

var hop: Character
var fragment: Character
var eggo: Character
var bigjoe: Character


func _ready() -> void:
	setup_area(START)
	Game.play_music("mt_carmel")
	_add_school_pride()
	_place_characters()
	_start_story.call_deferred()


## Mt. Carmel's colors: a big yellow "MC" outlined in red painted at midfield, and a
## "HOME OF THE SUNDEVILS" banner hung on the bleachers.
func _add_school_pride() -> void:
	var paint := Node2D.new()
	add_child(paint)
	# On the ground, under everyone walking around.
	move_child(paint, world.get_index())
	var font := ThemeDB.fallback_font
	var yellow := Color8(250, 205, 40)
	var red := Color8(190, 30, 35)
	paint.draw.connect(func() -> void:
		var logo := "MC"
		var size := 60
		var width := font.get_string_size(logo, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var at := Vector2(FIELD_LOGO.x - width / 2, FIELD_LOGO.y + 22)
		paint.draw_string_outline(font, at, logo, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 10, red)
		paint.draw_string(font, at, logo, HORIZONTAL_ALIGNMENT_LEFT, -1, size, yellow)
		# The banner on the bleachers.
		var banner := Rect2(SUNDEVIL_BANNER.x - 110, SUNDEVIL_BANNER.y - 10, 220, 20)
		paint.draw_rect(banner, red)
		paint.draw_rect(banner, yellow, false, 2.0)
		var text := "HOME OF THE SUNDEVILS"
		var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		paint.draw_string(font, Vector2(SUNDEVIL_BANNER.x - text_width / 2, SUNDEVIL_BANNER.y + 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, yellow)
	)


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
	# The way in: a gate, chained shut until Elric finds the key.
	room.fill(GATE_CELL.x, GATE_CELL.y, 1, 2, Room.SIDEWALK if _flag("gate_open") else Room.GATE)

	# Sidewalk and road at the bottom.
	room.fill(1, 23, 46, 2, Room.SIDEWALK)
	room.fill(0, 25, 48, 5, Room.ROAD)
	room.fill(0, 27, 48, 1, Room.ROAD_LINE)


# --- People and things ----------------------------------------------------

func _place_characters() -> void:
	# Hop: by the doors until you meet him, then following Elric.
	hop = Cast.make("Hop")
	if _flag("met_hop"):
		hop.position = player.position + Vector2(-22, -4)
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
	var star := make_save_star()
	star.position = SAVE_SPOT
	star.glow = true
	star.glow_color = Color(1.0, 1.0, 1.0, 0.55)
	star.on_interact = _use_save_point
	add_storage_box(Vector2(432, 372))
	world.add_child(star)


# --- Looking around -------------------------------------------------------

func inspect_tile(cell: Vector2i) -> void:
	var tile := room.get_tile(cell.x, cell.y)
	if tile == Room.GATE:
		await _field_gate()
	elif cell == KEY_TREE and not _flag("has_gate_key") and not _flag("gate_open"):
		await _key_tree()
	elif tile == Room.DOOR:
		await _school_doors()
	elif tile == Room.BLEACHERS and not _flag("got_cleats"):
		await _find_cleats()
	else:
		await super(cell)


## Someone left a pair of cleats under the bleachers.
func _find_cleats() -> void:
	await Game.dialogue.say(["* (The bleachers. Someone left a half-eaten\n*  sandwich up there.)", "* (...And a pair of cleats underneath.)"])
	if Game.items.size() >= Game.MAX_ITEMS:
		await Game.dialogue.say(["* (Your bag is full. You leave them for now.)"])
		return
	Game.flags["got_cleats"] = true
	Game.items.append(Items.accessory("Cleats", "shoes", 1, 1))
	Game.play_sfx("item")
	await Game.dialogue.say(["* (You got the Cleats.)\n* (Shoes: ATK +1  DEF +1. EQUIP them from your bag.)"])


## The school's front doors lock themselves the moment Elric touches them.
func _school_doors() -> void:
	var tries := int(Game.flags.get("door_tries", 0))
	Game.flags["door_tries"] = tries + 1
	if tries == 0:
		Game.play_sfx("door")
		var lines: Array = [
			"* (You reach for the door handle.)",
			"* (Click.)",
			"* (It locked. Right as you touched it.)",
		]
		if _flag("met_hop"):
			lines.append({"who": "Hop", "text": "...That was open a second ago.\nI literally just came out of there.", "mood": "shocked"})
		await Game.dialogue.say(lines)
	else:
		await Game.dialogue.say(["* (Locked. It doesn't want you inside.)"])


## The field gate: chained shut until Elric has the key.
func _field_gate() -> void:
	if _flag("has_gate_key"):
		Game.play_sfx("item")
		await Game.dialogue.say([
			"* (You try the key in the padlock.)",
			"* (...It fits. The chain slides off.)",
		])
		Game.flags["gate_open"] = true
		room.fill(GATE_CELL.x, GATE_CELL.y, 1, 2, Room.SIDEWALK)
		room.build()
		return
	var lines: Array = [
		"* (The gate to the field is chained shut.)",
		"* (A heavy padlock hangs from the chain.)",
	]
	if _flag("met_hop") and not _flag("gate_hint"):
		Game.flags["gate_hint"] = true
		lines.append_array([
			{"who": "Hop", "text": "Coach Ramirez locks this every day.\nThen he loses the key. Every day.", "mood": "smug"},
			{"who": "Hop", "text": "Last week it was in the trophy case.\nThe week before, a tree. Don't ask me how."},
		])
	await Game.dialogue.say(lines)


## One tree in the courtyard has something caught in its branches.
func _key_tree() -> void:
	await Game.dialogue.say([
		"* (It's a tree.)",
		"* (...Something glints between the leaves.)",
	])
	var choice := await Game.dialogue.ask("* (Shake the tree?)", ["Shake it", "Leave it"])
	if choice == 1:
		return
	shake(3.0, 0.3)
	Game.play_sfx("item")
	var lines: Array = [
		"* (You shake the tree. Leaves rain down.)",
		"* (Jingle. A ring of keys drops into the grass.)",
		"* (You got COACH'S KEYS.)",
	]
	if _flag("met_hop"):
		lines.append({"who": "Hop", "text": "A TREE. Again. How does he even\nget them up there?", "mood": "shocked"})
	await Game.dialogue.say(lines)
	Game.flags["has_gate_key"] = true


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
	])
	await _the_voice()
	await Game.dialogue.say([
		"* (Use the ARROW KEYS to walk.\n*  Press ENTER to talk to people or look at things.)",
		"* (Press B to open your BAG.)",
	])
	Game.flags["arrived"] = true
	Game.busy = false
	_cutscene_running = false


## A voice with no face explains what Elric is here to do, and how the game works,
## then asks how they plan to do it. (It's Hopkuna. Nobody knows that yet.)
func _the_voice() -> void:
	var voice := func(text: String) -> Dictionary:
		return {"who": "Hopkuna", "tag": "???", "face": false, "text": text}
	Game.stop_music(1.0)
	await get_tree().create_timer(0.8).timeout
	await Game.dialogue.say([
		"* (...)",
		"* (Something speaks.\n*  You can't tell where it's coming from.)",
		voice.call("...Oh? A wanderer.\nHaven't seen one of you in a while."),
		voice.call("You feel it, don't you? Something pulling at you.\nThat's the FRAGMENTS."),
		voice.call("Twelve of them. Scattered all over this city.\nLittle pieces of something very old."),
		voice.call("Here is your OBJECTIVE, little wanderer:\nfind them. All twelve."),
		voice.call("Easy to say. Not so easy to do.\nPeople will get in your way."),
		voice.call("You could TALK to them. ACT. Listen.\nWin them over, and SPARE them."),
		voice.call("Every friend you make like that gives you BOND.\nIt's slow. It's... sweet."),
		voice.call("Or you could FIGHT.\nKnock them down and step over them."),
		voice.call("That gives you LOVE.\nIt's much faster."),
		voice.call("If you ever get tired, look for a glowing star.\nIt'll let you SAVE."),
		voice.call("And keep your BAG close.\nSnacks fix a surprising number of problems."),
		voice.call("So."),
		voice.call("Here is your objective.\nHow will you do it?"),
	])
	var choice := await Game.dialogue.ask("* (How will you do it?)", ["Talk it out", "Fight my way", "...I don't know"])
	Game.flags["first_answer"] = ["talk", "fight", "unsure"][choice]
	match choice:
		0:
			await Game.dialogue.say([
				voice.call("Talk it out. How noble."),
				voice.call("Let's see how long that lasts."),
			])
		1:
			await Game.dialogue.say([
				voice.call("...Heh."),
				voice.call("I think we're going to get along just fine."),
			])
		_:
			await Game.dialogue.say([
				voice.call("Honest. I like that."),
				voice.call("Don't worry. The city will decide for you."),
			])
	await Game.dialogue.say([
		voice.call("Go on, then. The first one's close.\nI'll be watching."),
		"* (The voice is gone.)",
	])
	Game.play_music("mt_carmel", 1.0)
	Game.set_objective("Find the 12 FRAGMENTS.")
	await get_tree().create_timer(0.6).timeout


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
	Game.set_objective("Check out the glow by the bleachers.")
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
	Game.set_objective("Leave Mt. Carmel with the fragment.")
	Game.flags["fragments"] = 1
	fragment.queue_free()


func _use_save_point() -> void:
	Game.play_sfx("heal")
	Game.heal_party()
	await Game.dialogue.say([
		"* (The quiet school courtyard.\n*  A breeze rolls through the trees.)",
		"* (It fills you with DETERMINATION.)",
		Game.restored_line(),
	])
	var choice := await Game.dialogue.ask("* (Save your progress?)", ["Save", "Return"])
	if choice == 0:
		Game.save_game(SCENE, player.position)
		Game.play_sfx("save")
		await Game.dialogue.say(Game.saved_lines())


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
	# The music cuts out with a dramatic sting as BigJoe6 shouts...
	Game.stop_music(0.05)
	Game.play_sfx("stinger")
	await Game.dialogue.say([{"who": "BigJoe6", "tag": "???", "text": "HOLD IT!", "face": false}])
	# ...and Revolution's theme kicks in as they come into view.
	Game.play_music("revolution", 0.2)
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
	# Revolution's theme while Eggo and BigJoe6 are still here.
	Game.play_music("revolution", 0.5)

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

	await _ride_home()

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
	Game.set_objective("Head down the road to the PQ Mall.")
	Game.battle_result = {}
	Game.busy = false
	_cutscene_running = false


## Eggo and BigJoe6's ride shows up. They walk to the curb, the car pulls up,
## they get in, and it drives off down the road.
func _ride_home() -> void:
	# The camera slides down so the road is on screen.
	var look := create_tween()
	look.tween_property(camera, "offset:y", maxf(0.0, CAR_LANE_Y - player.position.y - 150.0), 0.8)

	eggo.walk_to(Vector2(eggo.position.x - 20, CURB_Y - 6), 120.0)
	await bigjoe.walk_to(Vector2(bigjoe.position.x - 20, CURB_Y + 4), 120.0)

	# A car comes down the road, pulls up, and honks.
	var stop_x := bigjoe.position.x + 10.0
	var car := CAR_SCRIPT.new()
	car.scale = Vector2(1.5, 1.5)
	car.color = Color8(214, 168, 60)
	car.position = Vector2(stop_x - 640.0, CAR_LANE_Y)
	world.add_child(car)
	await car.drive_to(stop_x, 260.0)
	Game.play_sfx("brakes")
	Game.play_sfx("honk")
	await get_tree().create_timer(0.3).timeout
	await Game.dialogue.say([
		{"who": "Eggo", "text": "oh. that's our ride."},
		{"who": "Mom", "tag": "Eggo's Mom", "face": false, "text": "GET IN THE CAR. BOTH OF YOU.\nYOU WERE SUPPOSED TO BE HOME AN HOUR AGO!"},
		{"who": "BigJoe6", "text": "Coming, Mrs.-", "mood": "shocked"},
		{"who": "Mom", "tag": "Eggo's Mom", "face": false, "text": "NOW!!"},
	])

	# In they go.
	for who in [eggo, bigjoe]:
		await who.walk_to(Vector2(stop_x - 10, CAR_LANE_Y - 12), 160.0)
		Game.play_sfx("door")
		who.queue_free()
		await get_tree().create_timer(0.2).timeout
	await get_tree().create_timer(0.4).timeout

	Game.play_sfx("honk")
	Game.play_music("mt_carmel", 1.5)
	await car.drive_to(room.pixel_size().x + 160.0, 240.0)
	car.queue_free()
	await Game.dialogue.say([{"who": "Hop", "text": "...Their mom came and got them.\nWimps.", "mood": "smug"}])

	look = create_tween()
	look.tween_property(camera, "offset:y", 0.0, 0.6)
	await look.finished
