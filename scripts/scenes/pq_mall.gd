extends Area
## The PQ Mall: Chapter 1's hub. Shops, a SAVE point, and a lot of the cast hanging out.
##
## Story beats (flags in Game.flags):
##   mall_arrived      First visit: Hop shows Elric around.
##   heard_lore        Nat tells the old story about the fragments (optional).
##   heard_westview    Nassan points Elric toward Westview High School... after dark.
##   played_games      NCWethan and Ronin rope Elric into Rock Paper Scissors. Hours pass.
##   mall_time         "day" -> "afternoon" -> "evening" -> "night". People move around
##                     and say new things as the day goes on. Talking to a few people in
##                     the afternoon makes it evening; Nassan sends everyone off at nightfall.
##   mall_done         Elric heads east to Westview High School (only once it's night).

const SCENE := "res://scenes/pq_mall.tscn"
const MT_CARMEL_SCENE := "res://scenes/mt_carmel.tscn"
const WESTVIEW_SCENE := "res://scenes/westview.tscn"

## Where Elric appears when arriving from Mt. Carmel (bottom-left sidewalk).
const ENTRY := Vector2(50, 535)
const EAST_EXIT_X := 1075.0
const WEST_EXIT_X := 15.0
const ROAD_Y := 500.0
## The sidewalk path running up the right side of the lot, past Jack in the Box.
const SIDE_PATH_X := 870.0
## The patio table by MuffinMage (Knotty Barrel), with his salmon burger on it.
const MUFFIN_TABLE := Vector2(30 * 20 + 10, 10 * 20 + 6)

# (What the shops sell, and what their shopkeepers say, is in shops.gd.)

# --- Time of day ---

## The color the world is tinted at each time of day.
const TINTS := {
	"day": Color(1, 1, 1),
	"afternoon": Color(1.0, 0.9, 0.76),
	"evening": Color(0.92, 0.66, 0.62),
	"night": Color(0.5, 0.52, 0.76),
}

## Where everyone stands at each time of day. Anyone missing has gone home.
const SPOTS := {
	"day": {
		"Supreme": Vector2(250, 178), "Crayola": Vector2(390, 178), "NCWethan": Vector2(510, 218),
		"Ronin": Vector2(550, 218), "MuffinMage": Vector2(630, 218), "Rooster": Vector2(430, 298),
		"Sansworth": Vector2(250, 398), "Nat": Vector2(910, 298), "Nassan": Vector2(1050, 538),
		"Agent": Vector2(820, 178),
	},
	"afternoon": {
		"Supreme": Vector2(960, 440), "Crayola": Vector2(560, 236), "NCWethan": Vector2(470, 300),
		"Ronin": Vector2(510, 300), "MuffinMage": Vector2(640, 236), "Rooster": Vector2(300, 300),
		"Sansworth": Vector2(200, 420), "Nat": Vector2(910, 298),
		"Agent": Vector2(820, 300),
	},
	"evening": {
		"Crayola": Vector2(950, 298), "NCWethan": Vector2(700, 470), "Ronin": Vector2(740, 470),
		"MuffinMage": Vector2(600, 236), "Rooster": Vector2(430, 528), "Sansworth": Vector2(330, 330),
		"Nat": Vector2(910, 298), "Nassan": Vector2(640, 400),
		"Agent": Vector2(690, 400),
		# Gloria, out front, locking up Vons.
		"Gloria": Vector2(222, 172),
	},
	"night": {
		"NCWethan": Vector2(700, 470), "Ronin": Vector2(740, 470), "Nat": Vector2(910, 298),
		"Nassan": Vector2(1050, 538),
	},
}

## Shoppers and regulars at each time of day (townsfolk.gd): where they stand, and
## where they walk to and back (if they do).
const SHOPPERS := {
	"day": {"mallcop": [Vector2(790, 470)], "mom": [Vector2(330, 250)], "pigeons": [Vector2(110, 330)], "teen": [Vector2(690, 330)]},
	"afternoon": {"mallcop": [Vector2(790, 470)], "mom": [Vector2(330, 250)], "pigeons": [Vector2(110, 330)], "teen": [Vector2(690, 330)], "jogger": [Vector2(220, 470), Vector2(480, 470)]},
	"evening": {"mallcop": [Vector2(790, 470)], "pigeons": [Vector2(110, 330)], "teen": [Vector2(690, 330)]},
	"night": {"mallcop": [Vector2(900, 470)]},
}

## People who wander back and forth at a time of day: [from, to].
const WANDERERS := {
	"afternoon": {"Rooster": [Vector2(300, 300), Vector2(760, 300)], "Sansworth": [Vector2(200, 420), Vector2(820, 420)]},
}

## How many people to talk to in the afternoon before the sun starts going down.
const AFTERNOON_TALKS := 3

var hop: Character
## Everyone at the mall right now, by name.
var people: Dictionary = {}


func _ready() -> void:
	setup_area(ENTRY)
	add_wild_encounters(SCENE, Rect2(Vector2.ZERO, room.pixel_size()))
	# A soft, quiet theme at night; the usual upbeat one during the day.
	Game.play_music("mall_night" if _time_of_day() == "night" else "mall")
	var tint := CanvasModulate.new()
	tint.color = TINTS[_time_of_day()]
	add_child(tint)
	_add_signs()
	_add_muffin_burger()
	_place_people()
	_place_hotspots()
	_start.call_deferred()


func _time_of_day() -> String:
	return Game.flags.get("mall_time", "day")


# --- The map --------------------------------------------------------------

func build_map() -> void:
	room.setup(56, 32, Room.GRASS)

	# Trees along the top and sides.
	room.fill(0, 0, 56, 1, Room.TREE)
	room.fill(0, 1, 1, 25, Room.TREE)
	room.fill(55, 1, 1, 25, Room.TREE)

	# The long row of stores.
	room.fill(2, 1, 40, 2, Room.ROOF)
	room.fill(2, 3, 40, 4, Room.STUCCO)
	# Vons (the big one on the left).
	room.fill(3, 4, 4, 2, Room.GLASS)
	room.fill(11, 4, 4, 2, Room.GLASS)
	room.fill(8, 5, 2, 2, Room.DOOR)
	# Games & Cards.
	room.fill(17, 4, 3, 2, Room.GLASS)
	room.fill(21, 5, 1, 2, Room.DOOR)
	# Knotty Barrel (wooden front).
	room.fill(24, 3, 10, 4, Room.WOOD_WALL)
	room.fill(25, 4, 2, 2, Room.GLASS)
	room.fill(31, 4, 2, 2, Room.GLASS)
	room.fill(28, 5, 2, 2, Room.DOOR)
	# An empty store, for lease.
	room.fill(36, 4, 2, 2, Room.GLASS)
	room.fill(39, 4, 2, 2, Room.GLASS)
	room.fill(38, 5, 1, 2, Room.DOOR)

	# Sidewalk in front of the stores.
	room.fill(1, 7, 42, 2, Room.SIDEWALK)

	# The parking lot.
	room.fill(1, 9, 42, 17, Room.ASPHALT)
	for x in range(2, 23, 3):
		room.fill(x, 10, 1, 3, Room.PARKING_LINE)
	for x in range(2, 42, 3):
		room.fill(x, 15, 1, 3, Room.PARKING_LINE)
		room.fill(x, 21, 1, 3, Room.PARKING_LINE)
	# Planter islands with palm trees.
	for island_x in [5, 17, 34]:
		room.fill(island_x, 18, 3, 1, Room.PLANTER)
		room.set_tile(island_x + 1, 18, Room.PALM)

	# Knotty Barrel's patio, with two tables and planters around it.
	room.fill(24, 9, 10, 3, Room.PATIO)
	room.set_tile(26, 10, Room.TABLE)
	room.set_tile(30, 10, Room.TABLE)
	room.fill(24, 12, 10, 1, Room.PLANTER)
	room.fill(28, 12, 2, 1, Room.PATIO)

	# The right side: a path, a bench, palm trees, and Jack in the Box.
	room.fill(43, 7, 1, 19, Room.SIDEWALK)
	room.fill(45, 13, 2, 1, Room.BENCH)
	for spot in [Vector2i(50, 4), Vector2i(53, 8), Vector2i(47, 9), Vector2i(52, 12), Vector2i(46, 24)]:
		room.set_tile(spot.x, spot.y, Room.PALM)
	room.fill(46, 15, 8, 1, Room.ROOF)
	room.fill(46, 16, 8, 5, Room.RED_WALL)
	room.fill(47, 18, 2, 1, Room.GLASS)
	room.fill(52, 18, 1, 1, Room.GLASS)
	room.fill(49, 20, 2, 1, Room.DOOR)
	room.fill(44, 21, 10, 1, Room.SIDEWALK)

	# Sidewalk and road along the bottom.
	room.fill(1, 26, 54, 1, Room.SIDEWALK)
	room.fill(0, 27, 56, 5, Room.ROAD)
	room.fill(0, 29, 56, 1, Room.ROAD_LINE)


## Store names on the roofs.
## A salmon burger on MuffinMage's table on the Knotty Barrel patio.
func _add_muffin_burger() -> void:
	var plate := Node2D.new()
	plate.z_index = 1
	plate.draw.connect(func() -> void:
		plate.draw_circle(MUFFIN_TABLE + Vector2(0, 2), 8.0, Color(0.95, 0.95, 0.95))
		ShopArt.draw_centered(plate, "Salmon Burger", MUFFIN_TABLE, 1.0))
	add_child(plate)


func _add_signs() -> void:
	var signs := Node2D.new()
	add_child(signs)
	var font := ThemeDB.fallback_font
	var labels := [
		["VONS", Vector2(180, 33), 18, Color8(225, 45, 45)],
		["GAMES & CARDS", Vector2(400, 31), 12, Color8(240, 240, 240)],
		["KNOTTY BARREL", Vector2(580, 31), 13, Color8(235, 195, 125)],
		["FOR LEASE", Vector2(770, 31), 12, Color8(170, 170, 170)],
		["JACK IN THE BOX", Vector2(1000, 314), 11, Color8(255, 255, 255)],
	]
	var closed := _stores_closed()
	signs.draw.connect(func() -> void:
		# The faded MISSING flyer: bleached paper, a blank square where the photo was.
		signs.draw_rect(Rect2(681, 86, 18, 24), Color8(232, 228, 214))
		signs.draw_rect(Rect2(685, 89, 10, 3), Color8(150, 140, 140))
		signs.draw_rect(Rect2(684, 94, 12, 9), Color8(244, 242, 236))
		signs.draw_rect(Rect2(684, 105, 12, 1), Color8(185, 180, 175))
		for label in labels:
			var width := font.get_string_size(label[0], HORIZONTAL_ALIGNMENT_LEFT, -1, label[2]).x
			signs.draw_string(font, label[1] - Vector2(width / 2, 0), label[0], HORIZONTAL_ALIGNMENT_LEFT, -1, label[2], label[3])
		# Once the sun goes down, CLOSED signs hang on Vons and Knotty Barrel.
		if closed:
			for door_x in CLOSING_DOORS:
				var plaque := Rect2(door_x - 16, 108, 32, 11)
				signs.draw_rect(plaque, Color8(200, 30, 35))
				signs.draw_rect(plaque, Color8(250, 240, 230), false, 1.0)
				var w := font.get_string_size("CLOSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
				signs.draw_string(font, Vector2(door_x - w / 2, 117), "CLOSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	)
	_add_streetlights()


## The middle of the doors that get a CLOSED sign at night (Vons, Knotty Barrel).
const CLOSING_DOORS := [180, 580]
## Where the parking lot's streetlights stand.
const STREETLIGHTS := [Vector2(130, 368), Vector2(370, 368), Vector2(710, 368), Vector2(870, 186), Vector2(520, 518), Vector2(1000, 518)]


## Vons and Knotty Barrel close in the evening. (Jack in the Box is open late.)
func _stores_closed() -> bool:
	return _time_of_day() in ["evening", "night"]


## Streetlights around the parking lot. They switch on in the evening, and glow a
## warm orange at night.
func _add_streetlights() -> void:
	var time := _time_of_day()
	var lit := time in ["evening", "night"]
	for spot in STREETLIGHTS:
		var lamp := Node2D.new()
		lamp.position = spot
		lamp.draw.connect(func() -> void:
			lamp.draw_rect(Rect2(-1.5, -44, 3, 44), Color8(70, 70, 76))
			lamp.draw_rect(Rect2(-1.5, -44, 12, 3), Color8(70, 70, 76))
			lamp.draw_rect(Rect2(6, -42, 8, 4), Color8(255, 190, 90) if lit else Color8(150, 150, 140))
			lamp.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
			lamp.draw_circle(Vector2.ZERO, 5, Color(0, 0, 0, 0.3))
			lamp.draw_set_transform(Vector2.ZERO)
		)
		if lit:
			var light := make_light(Color(1.0, 0.6, 0.25), 95.0, 1.3 if time == "night" else 0.6)
			light.position = Vector2(10, -6)
			lamp.add_child(light)
		world.add_child(lamp)


# --- People ---------------------------------------------------------------

func _place_people() -> void:
	hop = Cast.make("Hop")
	add_character(hop, player.position + Vector2(-20, 0))
	hop.follow = player

	var time := _time_of_day()
	var day_talks := {
		"Supreme": _talk_supreme, "Crayola": _talk_crayola, "NCWethan": _talk_ncwethan,
		"Ronin": _talk_ronin, "MuffinMage": _talk_muffinmage, "Rooster": _talk_rooster,
		"Sansworth": _talk_sansworth, "Nat": _talk_nat, "Nassan": _talk_nassan,
		"Agent": _talk_agent,
	}
	var spots: Dictionary = SPOTS[time]
	for who in spots:
		# Once Nassan starts his shift, he's inside Vons (until it closes).
		if who == "Nassan" and time == "day" and flag("heard_westview"):
			continue
		var talk: Callable = day_talks[who] if time == "day" else _talk_later.bind(who)
		var npc := add_npc(who, spots[who], talk)
		people[who] = npc
		var wander: Dictionary = WANDERERS.get(time, {})
		if wander.has(who):
			npc.patrol(wander[who][0], wander[who][1], 45.0)

	# Shoppers and regulars (townsfolk.gd). Anyone can be challenged.
	var shoppers: Dictionary = SHOPPERS[time]
	for id in shoppers:
		var person := add_person(id, shoppers[id][0], SCENE, "talk_night" if time == "night" else "talk")
		if person and shoppers[id].size() > 1:
			person.patrol(shoppers[id][0], shoppers[id][1], 40.0)

	var star := make_save_star()
	star.glow = true
	star.glow_color = Color(1.0, 1.0, 1.0, 0.55)
	star.on_interact = _use_save_point
	add_storage_box(Vector2(752, 178))
	add_character(star, Vector2(710, 178))


func _place_hotspots() -> void:
	# A faded MISSING flyer on the wall by the empty store.
	world.add_child(Hotspot.create(Vector2(690, 138), _missing_flyer))
	world.add_child(Hotspot.create(Vector2(180, 138), _shop_vons))
	world.add_child(Hotspot.create(Vector2(430, 138), _shop_cards))
	world.add_child(Hotspot.create(Vector2(580, 138), _shop_knotty))
	world.add_child(Hotspot.create(Vector2(770, 138), _shop_lease))
	world.add_child(Hotspot.create(Vector2(1000, 418), _shop_jack))


# --- Story ----------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if await handle_person_return():
		return
	if not flag("mall_arrived"):
		await run_cutscene(_arrival)
	elif not flag("seen_" + _time_of_day()):
		await run_cutscene(_new_time_of_day)


func _physics_process(_delta: float) -> void:
	if is_blocked():
		return
	check_random_encounter(SCENE)
	if player.position.y > ROAD_Y and player.position.x > EAST_EXIT_X:
		run_cutscene(_head_east)
	elif player.position.y > ROAD_Y and player.position.x < WEST_EXIT_X:
		run_cutscene(_head_west)


func _arrival() -> void:
	await Game.dialogue.say([
		"* (The PQ Mall.)",
		{"who": "Hop", "text": "Welcome to the PQ Mall! Groceries, burgers, tacos,\nand the most confusing parking lot in San Diego.", "mood": "happy"},
		{"who": "Hop", "text": "Everybody ends up here eventually.\nSeriously. Look around."},
		{"who": "Hop", "text": "If you need snacks, Vons and Jack in the Box\ntake actual money. Which I don't have. So, uh. You.", "mood": "smug"},
		"* (You have $%d.)" % Game.money,
	])
	Game.flags["mall_arrived"] = true
	Game.set_objective("Ask around the mall about the fragments.")


func _head_east() -> void:
	if flag("mall_done"):
		await Game.change_scene(WESTVIEW_SCENE)
		return
	if not flag("heard_westview"):
		await Game.dialogue.say([
			{"who": "Hop", "text": "Whoa, where are we even going?\nMaybe ask around first.\nSomebody here has to know something.", "mood": "shocked"},
		])
		await push_player(Vector2(-30, 0))
		return
	if _time_of_day() != "night":
		await Game.dialogue.say([
			{"who": "Hop", "text": "It's still light out. Nassan said Westview\nonly gets weird after DARK.", "mood": "sad"},
			{"who": "Hop", "text": "...Not that I'm in a hurry to go.", "mood": "smug"},
		])
		await push_player(Vector2(-30, 0))
		return
	await Game.dialogue.say([
		{"who": "Hop", "text": "Westview it is. At night. Totally normal plan.", "mood": "smug"},
		{"who": "Hop", "text": "...You're going first, by the way.", "mood": "smug"},
	])
	Game.flags["mall_done"] = true
	await Game.change_scene(WESTVIEW_SCENE)


func _head_west() -> void:
	await Game.change_scene(MT_CARMEL_SCENE, Vector2(900, 470))


func _use_save_point() -> void:
	Game.play_sfx("heal")
	Game.heal_party()
	await Game.dialogue.say([
		"* (The smell of curly fries drifts across the parking lot.)",
		"* (It fills you with DETERMINATION.)",
		Game.restored_line(),
	])
	var choice := await Game.dialogue.ask("* (Save your progress?)", ["Save", "Return"])
	if choice == 0:
		Game.save_game(SCENE, player.position)
		Game.play_sfx("save")
		await Game.dialogue.say(Game.saved_lines())


# --- Shops ----------------------------------------------------------------

func _shop_vons() -> void:
	if _stores_closed() and not Shops.gone():
		await Game.dialogue.say(["* (A sign on the door: CLOSED.)", "* (Through the glass, someone is mopping the floor.)"])
		return
	await Game.shop.open(Shops.vons())
	# The first time out of Vons with Nassan working there, Hop has thoughts.
	if flag("heard_westview") and not flag("hop_saw_apron") and not Shops.gone():
		Game.flags["hop_saw_apron"] = true
		await Game.dialogue.say([
			{"who": "Hop", "text": "Nassan. In an apron.\nWith a NAME TAG.", "mood": "shocked"},
			{"who": "Hop", "text": "I'm never letting him live this down.\nThis is the best day of my life.", "mood": "happy"},
		])


func _shop_jack() -> void:
	await Game.shop.open(Shops.jack())


func _shop_knotty() -> void:
	if _stores_closed() and not Shops.gone():
		await Game.dialogue.say(["* (A sign on the door: CLOSED.)", "* (The chairs are up on the tables.)"])
		return
	await Game.shop.open(Shops.knotty())


## Games & Cards: BACK IN 5 MINUTES, for years... until the afternoon.
func _shop_cards() -> void:
	if not Shops.cards_open() and not Shops.gone():
		await Game.dialogue.say([
			"* (A sign on the door says: BACK IN 5 MINUTES.)",
			"* (The sign looks like it's been there for years.)",
		])
		return
	await Game.shop.open(Shops.cards())
	# The first time it's actually open, Hop can't believe it.
	if not flag("hop_saw_pip") and not Shops.gone():
		Game.flags["hop_saw_pip"] = true
		await Game.dialogue.say([
			{"who": "Hop", "text": "That sign has said BACK IN 5 MINUTES\nsince I was in diapers.", "mood": "shocked"},
			{"who": "Hop", "text": "He came back. The legends were true.", "mood": "happy"},
		])


## A flyer, years old. Nobody remembers who it was for. Hop does.
func _missing_flyer() -> void:
	await Game.dialogue.say([
		"* (A flyer taped to the wall. It's old.\n*  The sun has bleached it almost white.)",
		"* (MISSING. The photo has faded to nothing.\n*  There's no name.)",
		"* (Just: LAST SEEN NEAR WESTVIEW FIELD.)",
		"* (Hop doesn't look at it.)",
		{"who": "Hop", "text": "...C'mon. Let's keep moving.", "mood": "sad"},
	])


func _shop_lease() -> void:
	await Game.dialogue.say(["* (FOR LEASE. The windows are dusty.\n*  Somebody wrote \"REVOLUTION HQ??\" in the dust.)"])


# --- The cast -------------------------------------------------------------

func _talk_supreme() -> void:
	var first: Array = [
		{"who": "Supreme", "text": "Oh. New face. Statistically, 73% of people\nat this mall are here for Vons."},
		{"who": "Supreme", "text": "The other 27% are here for Jack in the Box\nat 2 AM. I've done the research."},
		{"who": "Hop", "text": "He has. He has a spreadsheet.", "mood": "smug"},
		{"who": "Supreme", "text": "Seven spreadsheets. ...Name's Supreme.", "mood": "smug"},
	]
	match Game.flags.get("tutorial_path", ""):
		"spared":
			first.append({"who": "Supreme", "text": "Word travels fast. You talked down two\nRevolution guys without throwing a punch.\nThe odds of that? Basically zero.", "mood": "shocked"})
		"fought":
			first.append({"who": "Supreme", "text": "Word travels fast. You beat two Revolution guys.\nI'm updating my threat assessment spreadsheet.", "mood": "shocked"})
	first.append({"who": "Supreme", "text": "Fun fact: Trail Mix heals 15 HP for $8.\nThat's 1.875 HP per dollar. Best value in the mall."})

	await chat("supreme", first, [
		[{"who": "Supreme", "text": "Fun fact: the average cart here has\na 41% chance of having one bad wheel."}],
		[
			{"who": "Supreme", "text": "Fun fact: Hop has said \"I'll win, obviously\"\n112 times this month. He has won 9 times."},
			{"who": "Hop", "text": "...That's a lie.", "mood": "angry"},
			{"who": "Supreme", "text": "It's a spreadsheet.", "mood": "smug"},
		],
		[{"who": "Supreme", "text": "Fun fact: Knotty Barrel's Salmon Burger heals 40 HP.\nMuffinMage would like you to know that. Constantly."}],
	])


func _talk_crayola() -> void:
	if int(Game.flags.get("talks_crayola", 0)) > 0:
		await chat("crayola", [], [
			[{"who": "Crayola", "text": "...Thanks for talking to me. People usually\njust ask about my shirt.", "mood": "happy"}],
			[{"who": "Crayola", "text": "It's a job application. I keep meaning to fill it out."}],
			[{"who": "Crayola", "text": "N.C. Wethan keeps asking me to go swimming.\nHe cannonballs. Every time. Even in the shallow end."}],
		])
		return

	Game.flags["talks_crayola"] = 1
	await Game.dialogue.say([
		{"who": "Crayola", "text": "Oh! Um. Hi.", "mood": "shocked"},
		"* (Crayola is holding a deck of cards very tightly.)",
		{"who": "Crayola", "text": "Sorry. I don't... talk to new people much.", "mood": "sad"},
		{"who": "Hop", "text": "He's shy. But he's the best card player in,\nlike, the whole zip code."},
		{"who": "Crayola", "text": "...It's not that impressive.", "mood": "happy"},
	])
	var choice := await Game.dialogue.ask({"who": "Crayola", "text": "Do you, um... want to see a card trick?"}, ["Yes", "No"])
	if choice == 0:
		await Game.dialogue.say([
			{"who": "Crayola", "text": "Pick a card. Any card."},
			"* (You pick a card. It's the Seven of Hearts.)",
			{"who": "Crayola", "text": "Was it... the Seven of Hearts?"},
			"* (It was.)",
			{"who": "Hop", "text": "HOW.", "mood": "shocked"},
			{"who": "Crayola", "text": "...Practice.", "mood": "happy"},
			"* (Crayola smiles a little.)",
		])
	else:
		await Game.dialogue.say([
			{"who": "Crayola", "text": "Oh. Okay. That's fine. Totally fine.", "mood": "sad"},
			"* (Crayola shuffles the deck, a little embarrassed.)",
		])


func _talk_ncwethan() -> void:
	if flag("heard_westview") and not flag("played_games"):
		await _play_games()
		return
	await chat("ncwethan", [
		{"who": "NCWethan", "text": "KING ME!!!", "mood": "happy"},
		{"who": "Ronin", "text": "THAT'S NOT EVEN A REAL MOVE!\nYOU JUMPED THREE PIECES SIDEWAYS!", "mood": "angry"},
		{"who": "NCWethan", "text": "AND IT WORKED!!", "mood": "happy"},
		{"who": "NCWethan", "text": "Oh! Hey! New person! I'm N.C. Wethan! I'm winning!!"},
		{"who": "Ronin", "text": "HE'S CHEATING.", "mood": "angry"},
		{"who": "NCWethan", "text": "Can't cheat if you don't know the rules!! Checkmate!!", "mood": "smug"},
		{"who": "Ronin", "text": "THAT'S CHESS.", "mood": "angry"},
		"* (A spark of lightning jumps off N.C. Wethan's goggles.)",
		{"who": "NCWethan", "text": "Sorry! That happens when I get excited!\nWhich is always!!", "mood": "happy"},
	], [
		[{"who": "NCWethan", "text": "Wanna arm wrestle? I've never lost!\nI've also never won! I mostly just zap people!"}],
		[{"who": "NCWethan", "text": "Me and Crayola go swimming sometimes!\nLightning and water is TOTALLY fine! Probably!"}],
		[
			{"who": "NCWethan", "text": "Hop! Rematch on the push-up contest! Right now!"},
			{"who": "Hop", "text": "You did eleven and then fell asleep on the floor.", "mood": "smug"},
			{"who": "NCWethan", "text": "STRATEGICALLY.", "mood": "smug"},
		],
	])


func _talk_ronin() -> void:
	if flag("heard_westview") and not flag("played_games"):
		await _play_games()
		return
	await chat("ronin", [
		{"who": "Ronin", "text": "Don't let him fool you.\nI am a MASTER strategist.", "mood": "smug"},
		"* (Ronin has lost 14 games of checkers in a row.)",
		{"who": "Ronin", "text": "That's 14 games of LEARNING.", "mood": "angry"},
		{"who": "Ronin", "text": "Also, I'm a mage. And I play guitar.\nSometimes at the same time. Mostly, fire happens."},
		{"who": "Hop", "text": "The mall banned his guitar after the fire alarm thing."},
		{"who": "Ronin", "text": "ONE TIME!!", "mood": "angry"},
		"* (Hop laughs. A second too late.)",
	], [
		[{"who": "Ronin", "text": "Rematch. Rematch. REMATCH.", "mood": "angry"}],
		[{"who": "Ronin", "text": "My staff is NOT a guitar stand.\n...It is sometimes."}],
		[{"who": "Ronin", "text": "Want to hear my new song? It's called\n\"I Was Robbed (At Checkers).\""}],
	])


func _talk_muffinmage() -> void:
	await chat("muffinmage", [
		{"who": "MuffinMage", "text": "Yo."},
		"* (Someone in a huge fish mask is eating a salmon burger.)",
		"* (You decide not to think about it too hard.)",
		{"who": "MuffinMage", "text": "Knotty Barrel's salmon burger.\nBest thing in San Diego. Not up for debate."},
		{"who": "Hop", "text": "...You know you're wearing a fish head, right?", "mood": "shocked"},
		{"who": "MuffinMage", "text": "And?"},
		{"who": "Hop", "text": "...Nothing. Never mind.", "mood": "sad"},
		{"who": "MuffinMage", "text": "Hey. You're the one with the fragment, right?"},
		{"who": "MuffinMage", "text": "Be careful with that. Stuff like that\ndoesn't just show up for no reason."},
		{"who": "MuffinMage", "text": "...Anyway. Get the salmon burger.\nHeals 40 HP. Changes lives."},
	], [
		[{"who": "MuffinMage", "text": "Salmon burger. Trust."}],
		[{"who": "MuffinMage", "text": "I'm not picking sides in this fragment thing.\nI'm just here for the food."}],
	])


func _talk_rooster() -> void:
	if int(Game.flags.get("talks_rooster", 0)) > 0:
		var lines: Array = [{"who": "Rooster", "text": "Still here? Bold. Bold choice."}]
		if flag("roasted_rooster"):
			lines = [
				{"who": "Rooster", "text": "...I'm still thinking about the suit thing.", "mood": "sad"},
				{"who": "Rooster", "text": "It's called DUALITY."},
			]
		await chat("rooster", [], [
			lines,
			[
				{"who": "Rooster", "text": "Hop! Nice hat. Did a 1940s detective lose a bet?", "mood": "smug"},
				{"who": "Hop", "text": "...I will put you in a shopping cart.", "mood": "angry"},
			],
		])
		return

	Game.flags["talks_rooster"] = 1
	await Game.dialogue.say([
		{"who": "Rooster", "text": "Well, well, well. Look who it is.\nScruffy McNowhere.", "mood": "smug"},
		{"who": "Rooster", "text": "Nice clothes. Did you get them from a dumpster,\nor did the dumpster get them from you?", "mood": "smug"},
	])
	var choice := await Game.dialogue.ask("* (Roast him back?)", ["Yes", "No"])
	if choice == 0:
		Game.flags["roasted_rooster"] = true
		await Game.dialogue.say([
			{"who": "Elric", "choices": ["...Nice suit. Couldn't pick a color?", "...Did a penguin dress you?"], "mood": "smug"},
			{"who": "Rooster", "text": "...", "mood": "shocked"},
			{"who": "Rooster", "text": "HEY. That's- that's a FASHION choice.\nIt's called DUALITY.", "mood": "angry"},
			"* (Rooster is visibly upset.)",
			{"who": "Hop", "text": "Oh, they GOT you.", "mood": "happy"},
			{"who": "Rooster", "text": "Nobody got me! I'm unbeatable!\nI'm the best person in this parking lot!", "mood": "angry"},
			"* (Rooster storms off three steps. Then comes back.)",
		])
	else:
		await Game.dialogue.say([
			{"who": "Rooster", "text": "Ha! Speechless. Typical.\nBeing this amazing is a burden, honestly.", "mood": "smug"},
			{"who": "Hop", "text": "He's like this with everyone. Don't take it personally."},
		])


func _talk_sansworth() -> void:
	if int(Game.flags.get("talks_sansworth", 0)) > 0:
		await chat("sansworth", [], [
			[{"who": "Sansworth", "text": "I'm going to keep looking.\nFor the car I don't have."}],
			[
				{"who": "Sansworth", "text": "Do you think birds know they're birds?"},
				{"who": "Hop", "text": "Please stop talking to him.\nYou'll lose brain cells.", "mood": "angry"},
			],
			[{"who": "Sansworth", "text": "I tried to return a shopping cart once.\nIt returned me instead. Long story."}],
		])
		return

	Game.flags["talks_sansworth"] = 1
	await Game.dialogue.say([
		{"who": "Sansworth", "text": "Excuse me. Have you seen my car?", "mood": "happy"},
		"* (Sansworth is standing in the middle of the parking lot.)",
		{"who": "Sansworth", "text": "It's blue. Or red. It has four wheels.\nPossibly five."},
		{"who": "Hop", "text": "Sansworth, you don't have a car.", "mood": "smug"},
		{"who": "Sansworth", "text": "...That would explain a lot.", "mood": "shocked"},
		{"who": "Sansworth", "text": "Oh! But I found this!", "mood": "happy"},
	])
	if Game.items.size() < Game.MAX_ITEMS:
		Game.items.append({"name": "Trail Mix", "heal": 15})
		Game.play_sfx("item")
		await Game.dialogue.say([
			"* (Sansworth hands you something.)",
			"* (You got the Trail Mix.)",
			{"who": "Sansworth", "text": "I don't know whose it is. Now it's yours.\nThat's how property works."},
		])
	else:
		await Game.dialogue.say([
			"* (Sansworth tries to hand you a Trail Mix,\n*  but your bag is full.)",
			{"who": "Sansworth", "text": "I'll just hold onto it. Forever. It's fine."},
		])


func _talk_agent() -> void:
	var first: Array = [
		{"who": "Agent", "text": "Elric. The wanderer with the fragment. I know."},
		{"who": "Agent", "text": "Agent. Revolution. And before you ask:\nyes, I'm the smart one.", "mood": "smug"},
		{"who": "Hop", "text": "He says that to everyone.", "mood": "smug"},
		{"who": "Agent", "text": "Because it's true for everyone."},
	]
	match Game.flags.get("tutorial_path", ""):
		"spared":
			first.append({"who": "Agent", "text": "You talked Big Joe down. Nobody does that.\nHe doesn't even listen to me. His mistake."})
		"fought":
			first.append({"who": "Agent", "text": "You beat Big Joe and Eggo. Fine. Don't let it go\nto your head. Being impressive is my job.", "mood": "smug"})
	first.append({"who": "Agent", "text": "That fragment. Keep it in your bag, not your pocket.\nPockets get picked."})
	await chat("agent", first, [
		[{"who": "Agent", "text": "I don't repeat myself.", "mood": "smug"}, {"who": "Agent", "text": "...That didn't count."}],
		[
			"* (Someone wrote \"REVOLUTION HQ??\" in the dust on the window.)",
			{"who": "Agent", "text": "I wrote \"REVOLUTION HQ.\"\nThe question marks were Eggo.", "mood": "angry"},
		],
		[
			{"who": "Hop", "text": "Agent. Quick. What's two plus two?", "mood": "smug"},
			{"who": "Agent", "text": "Four. Next."},
			{"who": "Hop", "text": "...I had a trick question ready.", "mood": "sad"},
			{"who": "Agent", "text": "I know. That's why I answered fast.", "mood": "smug"},
		],
	])


func _talk_nat() -> void:
	if flag("heard_lore"):
		await chat("nat", [], [
			[{"who": "Nat", "text": "Zzz."}, "* (Nat is definitely awake.)"],
			[{"who": "Nat", "text": "Chapter 4 is where it gets good. Don't spoil it."}],
			[{"who": "Nat", "text": "...Keep that fragment close.\nAnd keep an eye on the people around you."}],
		])
		return

	await Game.dialogue.say([
		"* (Someone is sitting by the bench\n*  with an open book on their head.)",
		"* (They appear to be asleep.)",
		{"who": "Nat", "text": "...I'm not asleep. I'm reading.", "mood": "smug"},
		{"who": "Hop", "text": "Your eyes were closed."},
		{"who": "Nat", "text": "I'm reading with my eyes closed.\nIt's advanced.", "mood": "smug"},
		{"who": "Nat", "text": "...That shard you're carrying. It's a fragment."},
		{"who": "Nat", "text": "There's an old story. Twelve pieces of something\nthat shouldn't exist, scattered so it could never wake up."},
		{"who": "Nat", "text": "Somebody gave everything to break it apart.\nThe book doesn't say who."},
		{"who": "Nat", "text": "The story calls it Hopkuna."},
		"* (Hop goes still.)",
		{"who": "Nat", "text": "Whoever gathers all twelve... well.\nThe book doesn't say. The last page is torn out."},
		{"who": "Nat", "text": "Convenient. Anyway. Goodnight."},
		"* (Nat puts the book back on his head and doesn't move again.)",
		{"who": "Hop", "text": "...Ha. Spooky story. Right? Super fake.", "mood": "happy"},
		{"who": "Hop", "text": "Let's go.", "mood": "sad"},
	])
	Game.flags["heard_lore"] = true


func _talk_nassan() -> void:
	await Game.dialogue.say([
		{"who": "Nassan", "text": "You must be Elric. I've heard about you.\nEggo and Big Joe have been busy."},
		{"who": "Nassan", "text": "I'm Nassan. I plan things.\nMostly other people's things."},
		{"who": "Nassan", "text": "If you're following the fragments, I've been mapping\nstrange reports around the area."},
		{"who": "Nassan", "text": "Lights in Westview High School after dark.\nDoors that lock on their own."},
		{"who": "Nassan", "text": "Hallways that are longer than they should be."},
		{"who": "Nassan", "text": "If I had to bet? The next fragment is there."},
		{"who": "Hop", "text": "Westview? At night?\n...Sounds fun. Totally not terrifying.", "mood": "shocked"},
		{"who": "Nassan", "text": "Here's the plan: stock up on food, save your progress,\nthen head east down the road."},
		{"who": "Nassan", "text": "After dark. Not before. Whatever's in there\nonly wakes up at night."},
		{"who": "Hop", "text": "It's like... two in the afternoon.", "mood": "shocked"},
		{"who": "Nassan", "text": "Then you've got time to kill.", "mood": "smug"},
		{"who": "Nassan", "text": "And Elric... whatever you're carrying,\nit's heavier than it looks. Don't carry it alone.", "mood": "sad"},
		{"who": "Nassan", "text": "Now, if you'll excuse me. My shift starts in five."},
		{"who": "Hop", "text": "Your... shift?", "mood": "shocked"},
		{"who": "Nassan", "text": "I got hired at Vons. Recently.\nVery recently. Tuesday.", "mood": "smug"},
		{"who": "Nassan", "text": "Every good plan needs funding.\nIf you need supplies, you know where to find me."},
	])
	Game.flags["heard_westview"] = true
	Game.set_objective("Kill some time until it gets dark.")
	# Off to work: across the parking lot and in through the Vons doors.
	var nassan: Character = people.get("Nassan")
	if nassan:
		# Along the road, up the path beside Jack in the Box (not through it),
		# across the lot, and in.
		await nassan.walk_to(Vector2(SIDE_PATH_X, nassan.position.y), 130.0)
		await nassan.walk_to(Vector2(SIDE_PATH_X, 275), 130.0)
		await nassan.walk_to(Vector2(180, 275), 130.0)
		await nassan.walk_to(Vector2(180, 150), 130.0)
		# Gone inside. (Hidden rather than deleted: this conversation is still
		# running from him, and deleting him would cut it off.)
		people.erase("Nassan")
		nassan.remove_from_group("npc")
		nassan.on_interact = Callable()
		nassan.hide()
		nassan.position = Vector2(-1000, -1000)
	await Game.dialogue.say([
		{"who": "Hop", "text": "Nassan has a JOB? Nassan has a job.\nI'm so proud. And a little scared.", "mood": "happy"},
	])
	await get_tree().create_timer(0.3).timeout
	# If you've met him, you know that voice.
	var caller := "N.C. Wethan" if int(Game.flags.get("talks_ncwethan", 0)) > 0 else "???"
	await Game.dialogue.say([
		{"who": "NCWethan", "tag": caller, "face": false, "text": "HEYYY!! NEW PERSON!! OVER HERE!!"},
		{"who": "NCWethan", "tag": caller, "face": false, "text": "WE NEED A THIRD PLAYER!! IT'S AN EMERGENCY!!"},
		{"who": "Hop", "text": "...That's N.C. Wethan. It's never an emergency.", "mood": "smug"},
		{"who": "Hop", "text": "We should probably go anyway.\nHe'll just keep yelling.", "mood": "happy"},
	])
	Game.set_objective("See what N.C. Wethan and Ronin are yelling about.")


# --- Killing time: Rock Paper Scissors --------------------------------------
# A minigame (see rps_game.gd). NCWethan and Ronin can't hide their throws if
# you look closely. Then Agent steps in, and he plays the odds out loud.

const RPS_GAME := preload("res://scripts/ui/rps_game.gd")
const ROUNDS := [
	{"opponent": "NCWethan", "throw": -1, "tell": "sparks"},
	{"opponent": "NCWethan", "throw": -1, "tell": "sparks"},
	{"opponent": "NCWethan", "throw": -1, "tell": "sparks"},
	{"opponent": "Ronin", "throw": -1, "tell": "shadow"},
	{"opponent": "Agent", "throw": -1, "tell": "math"},
]


func _play_games() -> void:
	await Game.dialogue.say([
		{"who": "NCWethan", "text": "NEW PERSON!! You came!!", "mood": "happy"},
		{"who": "Ronin", "text": "We need a tiebreaker. He says he won checkers.\nHe did NOT win checkers.", "mood": "angry"},
		{"who": "NCWethan", "text": "So we're settling it with the most scientific\ngame ever invented!!", "mood": "happy"},
		{"who": "NCWethan", "text": "ROCK!! PAPER!! SCISSORS!!", "mood": "happy"},
		{"who": "Agent", "tag": "???", "face": false, "text": "Scientific. Sure."},
	])
	# Agent strolls over from the empty store.
	if people.has("Agent"):
		await people["Agent"].walk_to(Vector2(470, 220), 150.0)
		people["Agent"].face(Vector2.DOWN)
	await Game.dialogue.say([
		{"who": "Agent", "text": "Rock Paper Scissors is a game of probability.\nYou two are playing it like a game of yelling.", "mood": "smug"},
		{"who": "Agent", "text": "Three rounds against N.C. Wethan. One against Ronin.\nThen me. I don't lose. I calculate."},
		{"who": "Hop", "text": "I'll hold your stuff. And judge. Mostly judge.", "mood": "happy"},
		"* (Watch your opponent closely. Pick a throw with LEFT/RIGHT.\n*  Press ENTER to start the countdown.)",
	])
	# Music: overly ambitious.
	Game.play_music("rps", 0.3)
	var game = RPS_GAME.new()
	add_child(game)
	# A fresh random throw for N.C. Wethan and Ronin every time (their tells still
	# give it away). Agent works his out from your throws.
	var rounds: Array = []
	for round_info in ROUNDS:
		var this_round: Dictionary = round_info.duplicate()
		if this_round["tell"] != "math":
			this_round["throw"] = randi() % 3
		rounds.append(this_round)
	var wins: int = await game.play(rounds)
	Game.play_music("mall", 0.8)
	var beat_agent: bool = game._result == 1
	game.queue_free()

	Game.flags["played_games"] = true
	Game.flags["rps_wins"] = wins
	if wins == ROUNDS.size():
		Game.flags["rps_champion"] = true
		await Game.dialogue.say([
			{"who": "NCWethan", "text": "FIVE FOR FIVE?! Are you PSYCHIC?!", "mood": "shocked"},
			{"who": "Ronin", "text": "...How did you know? I hid my hand.\nI hid it PERFECTLY.", "mood": "shocked"},
			{"who": "Agent", "text": "...", "mood": "shocked"},
			{"who": "Agent", "text": "You read my reasoning and countered it.\nThat's... a 0.4% outcome. I ran it twice.", "mood": "shocked"},
			{"who": "Agent", "text": "Fine. You're smart. Second smartest here.", "mood": "smug"},
			{"who": "Hop", "text": "Elric's the champion! Bow before the champion!", "mood": "happy"},
			{"who": "Ronin", "text": "Loser buys the curly fries. ...That's me. Here.", "mood": "sad"},
		])
		if Game.items.size() < Game.MAX_ITEMS:
			Game.items.append({"name": "Curly Fries", "heal": 20})
			Game.play_sfx("item")
			await Game.dialogue.say(["* (You got the Curly Fries.)"])
	else:
		var lines: Array = [{"who": "NCWethan", "text": "%d out of 5! Not bad, new person!" % wins, "mood": "happy"}]
		if beat_agent:
			lines.append({"who": "Agent", "text": "You beat me. Statistically, that was luck.\n...I'm going to be thinking about it all day.", "mood": "angry"})
		else:
			lines.append({"who": "Agent", "text": "As calculated. I told you exactly what I'd do.\nYou just had to do the math.", "mood": "smug"})
		lines.append({"who": "Ronin", "text": "Rematch. We need a rematch.\nBest of... a hundred.", "mood": "angry"})
		await Game.dialogue.say(lines)
	await Game.dialogue.say([
		{"who": "Hop", "text": "Oh no. They're doing best of a hundred.", "mood": "shocked"},
		{"who": "Agent", "text": "A best of a hundred takes about three hours.\nPerfect. It'll be dark by then."},
		{"who": "Hop", "text": "...Well. We DID have time to kill.", "mood": "smug"},
		"* (You play. And play. And play.)",
		"* (Agent keeps score in his head. He's never wrong.\n*  Hop loses eleven games of checkers and blames the board.)",
		"* (The shadows in the parking lot get longer.)",
	])
	await _pass_time("afternoon")


# --- The day goes on ---------------------------------------------------------

## Fades out, moves the clock forward, and reloads the mall: everyone moves to
## where they'd be at that time, and the light changes.
func _pass_time(to: String) -> void:
	Game.flags["mall_time"] = to
	await Game.change_scene(SCENE, player.position)


## The first moment of a new time of day.
func _new_time_of_day() -> void:
	var time := _time_of_day()
	Game.flags["seen_" + time] = true
	match time:
		"afternoon":
			await Game.dialogue.say([
				"* (A few hours pass.)",
				"* (The afternoon sun turns the parking lot gold.\n*  People drift around the mall.)",
				{"who": "Hop", "text": "Still not dark. Let's go bug people\nuntil the sun gets the hint.", "mood": "smug"},
			])
			Game.set_objective("Hang around the mall until it gets dark.")
		"evening":
			await Game.dialogue.say([
				"* (The sky turns orange, then pink.)",
				"* (Shops start flipping their signs to CLOSED.)",
				{"who": "Hop", "text": "Hey. Nassan's waving at us.", "mood": "sad"},
			])
			Game.set_objective("Talk to Nassan.")
		"night":
			await Game.dialogue.say([
				"* (Night falls over the PQ Mall.)",
				"* (The parking lot lights buzz on, one by one.)",
				{"who": "Hop", "text": "...Okay. It's dark.", "mood": "sad"},
				{"who": "Hop", "text": "Westview's down the road, to the east.\nI'm right behind you. ...Way behind you.", "mood": "sad"},
			])
			Game.set_objective("Head east to Westview High.")


## Talking to people in the afternoon, evening and at night.
func _talk_later(who: String) -> void:
	var time := _time_of_day()
	if time == "evening" and who == "Nassan":
		await _nightfall()
		return
	var lines: Array = LATER_LINES[time].get(who, [["* (%s waves.)" % who]])
	var id := who.to_lower() + "_" + time
	var first_time := int(Game.flags.get("talks_" + id, 0)) == 0
	await chat(id, lines[0], lines.slice(1))
	# A few conversations in, the sun starts going down.
	if time == "afternoon" and first_time:
		var talks := int(Game.flags.get("afternoon_talks", 0)) + 1
		Game.flags["afternoon_talks"] = talks
		if talks >= AFTERNOON_TALKS:
			await Game.dialogue.say([{"who": "Hop", "text": "Is it just me, or is the sky getting... orange-er?", "mood": "shocked"}])
			await _pass_time("evening")


func _nightfall() -> void:
	await Game.dialogue.say([
		{"who": "Nassan", "text": "There you are. I just clocked out.\nGloria says I bag faster than anyone she's trained.", "mood": "smug"},
		{"who": "Nassan", "text": "Anyway. The sun's almost down."},
		{"who": "Nassan", "text": "Everyone's heading home.\nYou two are heading to Westview."},
		{"who": "Nassan", "text": "Remember: the fragment's somewhere inside.\nIf something feels wrong in there...\nit probably is."},
		{"who": "Hop", "text": "Great pep talk. Really. Ten out of ten.", "mood": "sad"},
		{"who": "Nassan", "text": "I'll be at the road. Go when you're ready.", "mood": "smug"},
		"* (The last bit of sunlight slips away.)",
	])
	await _pass_time("night")


## What everyone says later in the day: [first conversation, then repeats...].
const LATER_LINES := {
	"afternoon": {
		"Supreme": [
			[{"who": "Supreme", "text": "Field research. Jack in the Box sells 40% more\ncurly fries after 3 PM. I'm here to find out why."}, {"who": "Supreme", "text": "...It's because they're good. Research complete.", "mood": "happy"}],
			[{"who": "Supreme", "text": "Fun fact: you've been at this mall for four hours.\nThat's above average. Congratulations."}],
		],
		"Crayola": [
			[{"who": "Crayola", "text": "MuffinMage is teaching me a card game.\nI think he's making up the rules.", "mood": "happy"}, {"who": "MuffinMage", "text": "I am absolutely making up the rules."}, {"who": "Crayola", "text": "...I'm still winning.", "mood": "smug"}],
			[{"who": "Crayola", "text": "Are you going somewhere tonight?\n...Be careful. Okay?", "mood": "sad"}],
		],
		"MuffinMage": [
			[{"who": "MuffinMage", "text": "Second salmon burger of the day."}, {"who": "Hop", "text": "Is that... healthy?", "mood": "shocked"}, {"who": "MuffinMage", "text": "It's fish. Fish is brain food. I'm a genius now."}],
			[{"who": "MuffinMage", "text": "Crayola beat me at my own made-up game.\nI've never been prouder or more upset."}],
		],
		"NCWethan": [
			[{"who": "NCWethan", "text": "Ronin's on game 58 of best-of-a-hundred!!\nI'm winning by... uh... a lot? Maybe?", "mood": "happy"}, {"who": "Ronin", "text": "You're LOSING by six.", "mood": "angry"}, {"who": "NCWethan", "text": "That's a lot!!", "mood": "happy"}],
			[{"who": "NCWethan", "text": "If you see Hop doing push-ups, tell him I'm\nstill the champion! Of push-ups! I did eleven!"}],
		],
		"Ronin": [
			[{"who": "Ronin", "text": "Game 58. I've studied his every move.\nHe has no strategy. That's his strategy.", "mood": "angry"}, {"who": "Ronin", "text": "It's working, and I hate it."}],
			[{"who": "Ronin", "text": "I'd play my guitar to pass the time, but\nmall security knows my face now.", "mood": "sad"}],
		],
		"Rooster": [
			[{"who": "Rooster", "text": "Power walking. Look at this form.\nOlympic. Absolutely Olympic.", "mood": "smug"}, {"who": "Hop", "text": "You're walking in circles around a parking lot.", "mood": "smug"}, {"who": "Rooster", "text": "AROUND IT. Like a CHAMPION.", "mood": "angry"}],
			[{"who": "Rooster", "text": "Can't talk. Lap 40.", "mood": "smug"}],
		],
		"Sansworth": [
			[{"who": "Sansworth", "text": "I'm checking every car. One of them\nhas to be mine.", "mood": "happy"}, {"who": "Hop", "text": "Sansworth. You don't have a car.", "mood": "smug"}, {"who": "Sansworth", "text": "Not with THAT attitude."}],
			[{"who": "Sansworth", "text": "This one's close. It's a car. My car is also a car."}],
		],
		"Nat": [
			[{"who": "Nat", "text": "...Still reading.", "mood": "smug"}, "* (The book on his head has moved one page.)"],
			[{"who": "Nat", "text": "Sunset's in about two hours.\nThe old stories always start at sunset."}],
		],
		"Agent": [
			[{"who": "Agent", "text": "You waited instead of going in early. Smart.\nMost people would've gone in and lost."}, {"who": "Agent", "text": "...Not as smart as me. But smart.", "mood": "smug"}],
			[{"who": "Agent", "text": "Sunset's at 7:42. I checked. Be ready."}],
		],
	},
	"evening": {
		"Gloria": [
			[
				{"who": "Gloria", "text": "We're closed, hon. Come back tomorrow."},
				{"who": "Gloria", "text": "Your friend Nassan bags faster than anyone\nI've trained in twenty-two years.", "mood": "happy"},
				{"who": "Gloria", "text": "Don't tell him I said that.\nHe'll make a chart.", "mood": "smug"},
			],
			[{"who": "Gloria", "text": "Go home, hon. It's getting dark.\nNothing good happens around here after dark.", "mood": "sad"}],
		],
		"Crayola": [
			[{"who": "Crayola", "text": "Nat said I could sit here if I was quiet.", "mood": "happy"}, {"who": "Nat", "text": "You're doing great.", "mood": "smug"}, {"who": "Crayola", "text": "...Thanks.", "mood": "happy"}],
		],
		"NCWethan": [
			[{"who": "NCWethan", "text": "Final score: Ronin 51, me 49!\nBut I had more FUN, so I win!!", "mood": "happy"}, {"who": "Ronin", "text": "That's not how winning works!!", "mood": "angry"}],
		],
		"Ronin": [
			[{"who": "Ronin", "text": "Fifty-one to forty-nine. I WON.\nNobody is going to remember this, are they.", "mood": "sad"}],
		],
		"MuffinMage": [
			[{"who": "MuffinMage", "text": "Knotty Barrel's closing. Last salmon burger of the day."}, {"who": "MuffinMage", "text": "Be careful tonight, fragment kid.\n...Kidding. Mostly."}],
		],
		"Rooster": [
			[{"who": "Rooster", "text": "...Lap 112. My legs don't work anymore.", "mood": "sad"}, {"who": "Rooster", "text": "Don't tell anyone. I'm still the best person here.", "mood": "smug"}],
		],
		"Sansworth": [
			[{"who": "Sansworth", "text": "I found a car! It's not mine.\nBut it let me sit on it. That's basically ownership.", "mood": "happy"}],
		],
		"Agent": [
			[{"who": "Agent", "text": "Westview. Three rooms you'll care about."}, {"who": "Agent", "text": "The hallway lies. Trust the chalkboard.\nDon't trust the mascot."},{"who": "Hop", "text": "How do you know all that?", "mood": "shocked"}, {"who": "Agent", "text": "I read. Go.", "mood": "smug"}],
		],
		"Nat": [
			[{"who": "Nat", "text": "The sun's going down.", "mood": "sad"}, {"who": "Nat", "text": "In the old story, the fragments glowed brighter\nat night. Keep yours close."}],
		],
	},
	"night": {
		"NCWethan": [
			[{"who": "NCWethan", "text": "We're staying to look at the stars!!\nRonin says that one's a planet. It's a plane.", "mood": "happy"}, {"who": "NCWethan", "text": "Good luck at Westview, new person!!\nIf anything's scary, just ZAP IT!!", "mood": "happy"}],
		],
		"Ronin": [
			[{"who": "Ronin", "text": "It's a planet.", "mood": "smug"}, "* (It's blinking.)", {"who": "Ronin", "text": "...Planets can blink."}],
		],
		"Nat": [
			[{"who": "Nat", "text": "Goodnight.", "mood": "smug"}, "* (He's not going anywhere. He's just saying it.)"],
		],
		"Nassan": [
			[{"who": "Nassan", "text": "Westview's east, down the road.\nGo. Before I change the plan."}],
		],
	},
}
