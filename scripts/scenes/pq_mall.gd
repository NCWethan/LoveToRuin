extends Area
## The PQ Mall: Chapter 1's hub. Shops, a SAVE point, and a lot of the cast hanging out.
##
## Story beats (flags in Game.flags):
##   mall_arrived      First visit: Hop shows Elric around.
##   heard_lore        Nat tells the old story about the fragments (optional).
##   heard_westview    Nassan points Elric toward Westview High School (needed to move on).
##   mall_done         Elric heads east to Westview High School.

const SCENE := "res://scenes/pq_mall.tscn"
const MT_CARMEL_SCENE := "res://scenes/mt_carmel.tscn"
const WESTVIEW_SCENE := "res://scenes/westview.tscn"

## Where Elric appears when arriving from Mt. Carmel (bottom-left sidewalk).
const ENTRY := Vector2(50, 535)
const EAST_EXIT_X := 1075.0
const WEST_EXIT_X := 15.0
const ROAD_Y := 500.0

# --- What the shops sell ---

const VONS_STOCK := [
	{"name": "Trail Mix", "heal": 15, "price": 8},
	{"name": "Soda", "heal": 10, "price": 5},
	{"name": "Granola Bar", "heal": 18, "price": 10},
	{"name": "Deli Sandwich", "heal": 25, "price": 15},
]
const JACK_STOCK := [
	{"name": "Two Tacos", "heal": 12, "price": 6},
	{"name": "Curly Fries", "heal": 20, "price": 10},
	{"name": "Burger", "heal": 30, "price": 16},
]
const KNOTTY_STOCK := [
	{"name": "Fish & Chips", "heal": 32, "price": 18},
	{"name": "Salmon Burger", "heal": 40, "price": 22},
]

var hop: Character


func _ready() -> void:
	setup_area(ENTRY)
	Game.play_music("mall")
	_add_signs()
	_place_people()
	_place_hotspots()
	_start.call_deferred()


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
	signs.draw.connect(func() -> void:
		for label in labels:
			var width := font.get_string_size(label[0], HORIZONTAL_ALIGNMENT_LEFT, -1, label[2]).x
			signs.draw_string(font, label[1] - Vector2(width / 2, 0), label[0], HORIZONTAL_ALIGNMENT_LEFT, -1, label[2], label[3])
	)


# --- People ---------------------------------------------------------------

func _place_people() -> void:
	hop = Cast.make("Hop")
	add_character(hop, player.position + Vector2(-20, 0))
	hop.follow = player

	add_npc("Supreme", Vector2(250, 178), _talk_supreme)
	add_npc("Crayola", Vector2(390, 178), _talk_crayola)
	add_npc("NCWethan", Vector2(510, 218), _talk_ncwethan)
	add_npc("Ronin", Vector2(550, 218), _talk_ronin)
	add_npc("MuffinMage", Vector2(630, 218), _talk_muffinmage)
	add_npc("Rooster", Vector2(430, 298), _talk_rooster)
	add_npc("Sansworth", Vector2(250, 398), _talk_sansworth)
	add_npc("Nat", Vector2(910, 298), _talk_nat)
	add_npc("Nassan", Vector2(1050, 538), _talk_nassan)

	var star := Character.new().setup(preload("res://art/sprites/save_star.png"), null, false)
	star.glow = true
	star.glow_color = Color(1.0, 1.0, 1.0, 0.55)
	star.on_interact = _use_save_point
	add_character(star, Vector2(710, 178))


func _place_hotspots() -> void:
	world.add_child(Hotspot.create(Vector2(180, 138), _shop_vons))
	world.add_child(Hotspot.create(Vector2(430, 138), _shop_cards))
	world.add_child(Hotspot.create(Vector2(580, 138), _shop_knotty))
	world.add_child(Hotspot.create(Vector2(770, 138), _shop_lease))
	world.add_child(Hotspot.create(Vector2(1000, 418), _shop_jack))


# --- Story ----------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if not flag("mall_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked():
		return
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


func _head_east() -> void:
	if not flag("heard_westview"):
		await Game.dialogue.say([
			{"who": "Hop", "text": "Whoa, where are we even going?\nMaybe ask around first. Somebody here has to know something.", "mood": "shocked"},
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
		"* (Everyone's HP was restored.)",
	])
	var choice := await Game.dialogue.ask("* (Save your progress?)", ["Save", "Return"])
	if choice == 0:
		Game.save_game(SCENE, player.position)
		Game.play_sfx("save")
		await Game.dialogue.say(["* (File saved.)"])


# --- Shops ----------------------------------------------------------------

func _shop_vons() -> void:
	await Game.shop.open("Vons", "* (Bright lights. Soft music. A shopping cart\n*  with one bad wheel squeaks somewhere.)", VONS_STOCK)


func _shop_jack() -> void:
	await Game.shop.open("Jack in the Box", "* (The menu board glows. It smells amazing in here.)", JACK_STOCK)


func _shop_knotty() -> void:
	await Game.shop.open("Knotty Barrel", "* (Wooden tables, a busy kitchen.\n*  Someone is very loudly recommending the salmon burger.)", KNOTTY_STOCK)


func _shop_cards() -> void:
	await Game.dialogue.say([
		"* (A sign on the door says: BACK IN 5 MINUTES.)",
		"* (The sign looks like it's been there for years.)",
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
			first.append({"who": "Supreme", "text": "Word travels fast. You talked down two Revolution guys\nwithout throwing a punch. The odds of that? Basically zero.", "mood": "shocked"})
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
			[{"who": "Crayola", "text": "NCWethan keeps asking me to go swimming.\nHe cannonballs. Every time. Even in the shallow end."}],
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
	await chat("ncwethan", [
		{"who": "NCWethan", "text": "KING ME!!!", "mood": "happy"},
		{"who": "Ronin", "text": "THAT'S NOT EVEN A REAL MOVE!\nYOU JUMPED THREE PIECES SIDEWAYS!", "mood": "angry"},
		{"who": "NCWethan", "text": "AND IT WORKED!!", "mood": "happy"},
		{"who": "NCWethan", "text": "Oh! Hey! New person! I'm NCWethan! I'm winning!!"},
		{"who": "Ronin", "text": "HE'S CHEATING.", "mood": "angry"},
		{"who": "NCWethan", "text": "Can't cheat if you don't know the rules!! Checkmate!!", "mood": "smug"},
		{"who": "Ronin", "text": "THAT'S CHESS.", "mood": "angry"},
		"* (A spark of lightning jumps off NCWethan's goggles.)",
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
	await chat("ronin", [
		{"who": "Ronin", "text": "Don't let him fool you.\nI am a MASTER strategist.", "mood": "smug"},
		"* (Ronin has lost 14 games of checkers in a row.)",
		{"who": "Ronin", "text": "That's 14 games of LEARNING.", "mood": "angry"},
		{"who": "Ronin", "text": "Also, I'm a mage. And I play guitar.\nSometimes at the same time. Mostly, fire happens."},
		{"who": "Hop", "text": "The mall banned his guitar after the fire alarm thing."},
		{"who": "Ronin", "text": "ONE TIME!!", "mood": "angry"},
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
			{"who": "Elric", "text": "...Nice suit. Couldn't pick a color?", "mood": "smug"},
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
	if flag("heard_westview"):
		await chat("nassan", [], [
			[{"who": "Nassan", "text": "The plan: food, save, Westview. In that order."}],
			[{"who": "Nassan", "text": "I'd come with you, but someone has to\nplan what happens after the plan."}],
			[
				{"who": "Hop", "text": "...Why does your shirt say \"im batman\"?", "mood": "shocked"},
				{"who": "Nassan", "text": "Because I am.", "mood": "smug"},
				{"who": "Hop", "text": "..."},
				{"who": "Nassan", "text": "Next question."},
			],
		])
		return

	await Game.dialogue.say([
		{"who": "Nassan", "text": "You must be Elric. I've heard about you.\nEggo and BigJoe6 have been busy."},
		{"who": "Nassan", "text": "I'm Nassan. I plan things.\nMostly other people's things."},
		{"who": "Nassan", "text": "If you're following the fragments, I've been mapping\nstrange reports around the area."},
		{"who": "Nassan", "text": "Lights in Westview High School after dark.\nDoors that lock on their own."},
		{"who": "Nassan", "text": "Hallways that are longer than they should be."},
		{"who": "Nassan", "text": "If I had to bet? The next fragment is there."},
		{"who": "Hop", "text": "Westview? At night?\n...Sounds fun. Totally not terrifying.", "mood": "shocked"},
		{"who": "Nassan", "text": "Here's the plan: stock up on food, save your progress,\nthen head east down the road."},
		{"who": "Nassan", "text": "And Elric... whatever you're carrying,\nit's heavier than it looks. Don't carry it alone.", "mood": "sad"},
	])
	Game.flags["heard_westview"] = true
