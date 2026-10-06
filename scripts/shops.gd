class_name Shops
extends RefCounted
## Everything the PQ Mall's shopkeepers sell and say. Each shop is a Dictionary
## for Game.shop.open() (see shop_menu.gd):
##   title       the shop's name
##   scene       which room is drawn behind the counter: vons, jack, knotty, cards
##   music       its own song (audio/music; "_gone" on the end for the Genocide one)
##   keeper      the shopkeeper's name (for their voice)
##   sprite      their picture (art/sprites/<sprite>.png, and art/portraits for moods)
##   stock       what's for sale: food {"name", "heal", "price"} or gear (see Items)
##   greeting    what they say when you come in
##   back        what they say when you come back to the main menu
##   buy_prompt  the little line next to the list while you browse
##   bought      what they say when you buy something (one picked at random)...
##   bought_special  ...or this, for particular things
##   poor, full, sold_out  can't afford it / bag's full / only had one
##   sell        what they say when you try to sell them something (in order;
##               the last one repeats), unless "buys" is a price: then they really
##               do buy anything, for that much
##   talk        things to ask about: [{"topic", "lines"}]
##   exit        what they say when you leave
## A line is a String, or {"text", "mood"} for a facial expression (happy, angry,
## sad, shocked, smug). Lines in the left box can be up to four rows of about 34
## letters; lines in the small right box, about 17.


static func _time() -> String:
	return Game.flags.get("mall_time", "day")


## Elric has been killing things, and it shows. Shopkeepers notice.
static func _scared() -> bool:
	return Game.dread() > 0


## Genocide: everyone has gone. The shops are empty, the shopkeepers have left
## notes on the counter, and nobody is there to stop Elric from taking things.
static func gone() -> bool:
	return Game.dread() >= 3


## The note each shopkeeper leaves behind (by their sprite name).
const NOTES := {
	"gloria": "CLOSED.\nTwenty-two years I kept these lights\non. Fires. Floods. Cart 14.\nI turned them off because of you.\nThe kids who shopped here had names.\nYou never asked any of them.\n\n- Gloria",
	# Nassan's goes on for pages, on the back of receipts. It's to Elric.
	"nassan_vons": [
		"Elric,\nI told you not to carry it alone.\nI never thought you'd choose to.\n\nI'm writing this on receipt paper.\nIt's all I have left here.\nGloria won't be needing it.\n                              (over)",
		"I made a plan for you, you know.\nIt's still on my wall. Red string\nand everything. Westview first.\nThen the Corps. A bunk by the wall,\nyour name on the door.\nHop picked the color. Purple.\nHe said you'd like it.",
		"Hop came by my register every day.\nOne soda. An hour of talking.\nAll of it about you.\n\"Elric's gonna be fine,\" he said.\n\"They're just figuring it out.\"\n\nHe doesn't come by anymore.",
		"I planned for everything.\nMonsters. Fragments. Hopkuna.\nI never planned for you.\n\nI keep running it back, looking for\nthe step where I could have stopped\nthis. There isn't one.\nYou chose it. Every time.",
		"Take whatever you want.\nThe register's open. It doesn't\nmatter now.\n\nJust don't come looking for me.\nI don't want to be the next\nthing you finish.\n\nI'm sorry I believed in you.  - Nassan",
	],
	"dex": "Took the night off. First one in a\nyear. I was saving up for college.\nThe fries are still warm.\nTake them. You take everything.\n\nStay away from us.\n\n- Dex",
	"lou": "Kitchen's closed. First time in\nthirty years.\nMuffinMage never came in for his\nsalmon burger today.\nI kept it warm until midnight.\nI think you know why.\n\n- Lou",
	"pip": "BACK IN 5 MINUTES\n\nI always said that. I always came\nback. Not this time.\nThe cards were for kids who laughed.\nThere aren't any left.\nWe're all better off without you.\n\n- Pip",
}

## How much money is left in each register, for taking.
const REGISTERS := {"gloria": 46, "nassan_vons": 46, "dex": 23, "lou": 31, "pip": 9}


# --- Vons --------------------------------------------------------------------

const VONS_STOCK := [
	{"name": "Trail Mix", "heal": 15, "price": 8},
	{"name": "Soda", "heal": 10, "price": 5},
	{"name": "Granola Bar", "heal": 18, "price": 10},
	{"name": "Deli Sandwich", "heal": 25, "price": 15},
	# Gear a grocery store really has: the health and beauty aisle, and the
	# seasonal aisle by the door.
	{"name": "Nail File", "heal": 0, "slot": "weapon", "atk": 2, "def": 0, "price": 18},
	{"name": "Rain Poncho", "heal": 0, "slot": "torso", "atk": 0, "def": 2, "price": 20},
	{"name": "Flip-Flops", "heal": 0, "slot": "shoes", "atk": 0, "def": 1, "price": 12},
]


## Vons. Gloria, the manager, runs the register... until Nassan gets hired (right
## after Elric first meets him).
static func vons() -> Dictionary:
	if Game.flags.get("heard_westview", false):
		return _vons_nassan()
	return {
		"title": "Vons", "scene": "vons", "music": "vons", "keeper": "Gloria", "sprite": "gloria",
		"stock": VONS_STOCK,
		"greeting": "* ...Welcome to Vons.\n* Take what you need. Please.\n* No need to hurry. Or stay." if _scared()
			else "* Welcome to Vons, hon.\n* Carts are by the door. One of\n  them has a bad wheel.\n* You'll get that one.",
		"back": "* Anything else, hon?",
		"buy_prompt": "Take your time,\nhon.",
		"bought": ["Paper or plastic?\n...Kidding. We're\nout of both.", "There you go.\nKeep the receipt.\nIt's four feet\nlong."],
		"bought_special": {
			"Rain Poncho": "It hasn't rained\nsince March.\nBut you never\nknow, hon.",
		},
		"poor": "Short on cash?\nBeen there. Still\ncan't let you\nhave it.",
		"full": "Your arms are\nfull, hon. Eat\nsomething first.",
		"sold_out": "That was the only\none. I checked the\nback. Twice.",
		"sell": ["* We don't buy things, hon.\n* This is a grocery store.", {"text": "* Still a grocery store.", "mood": "smug"}],
		"talk": [
			{"topic": "About you", "lines": [
				"* I'm Gloria. Store manager.\n* Twenty-two years.",
				{"text": "* I've seen everything there is to\n  see in this store. Twice.\n* Some of it in aisle 9.", "mood": "smug"},
				"* Don't go in aisle 9.",
			]},
			{"topic": "Aisle 9", "lines": [
				"* ...",
				{"text": "* I said don't.", "mood": "angry"},
			]},
			{"topic": "Hiring?", "lines": [
				{"text": "* We're short-staffed. I put up a\n  HELP WANTED sign last week.", "mood": "sad"},
				"* Nobody's applied. Kids these days\n  would rather hang around the\n  parking lot.",
				"* If you know anyone organized...\n  send them my way.",
			]},
			{"topic": "The bad cart", "lines": [
				"* Cart 14.",
				{"text": "* It was here before me. Every\n  time we throw it out, it's back\n  by the door the next morning.", "mood": "shocked"},
				"* I've stopped asking questions.",
			]},
		],
		"exit": "* Come back soon, hon.\n* Mind the cart.",
	}


static func _vons_nassan() -> Dictionary:
	var first: bool = not Game.flags.get("vons_nassan_met", false)
	Game.flags["vons_nassan_met"] = true
	var greeting := "* Welcome to Vons. Still new.\n* Still planning.\n* What do you need?"
	if first:
		greeting = "* Welcome to Vons.\n* ...Hi, Elric. Yes, it's me.\n* I got hired here. Recently.\n  Very recently. Tuesday."
	if _scared():
		greeting = "* ...Elric.\n* I've heard what's been happening\n  out there.\n* Just buy what you need."
	return {
		"title": "Vons", "scene": "vons", "music": "vons", "keeper": "Nassan", "sprite": "nassan_vons",
		"stock": VONS_STOCK,
		"greeting": greeting,
		"back": "* Anything else on the list?",
		"buy_prompt": "I organized the\nshelves by how\nuseful they are.",
		"bought": ["Good choice.\nIt was in the\nplan.", "Rung up. I'm\ngetting faster.\nGloria timed me.", "Bagged. Heavy\nthings on the\nbottom. Always."],
		"bought_special": {
			"Flip-Flops": "Flip-flops. For\nfighting. That's\nnot in any plan\nI've ever made.",
			"Trail Mix": "Supreme says it's\nthe best value.\nHe made me a\nchart about it.",
		},
		"poor": "That's over your\nbudget. I'd know.\nI made you one.",
		"full": "Your bag's full.\nPlan ahead. Eat\nsomething first.",
		"sold_out": "Sold out. I wrote\nit down, so it's\nofficial.",
		"sell": ["* Vons doesn't buy things.\n* I asked. On day one.", {"text": "* Gloria said \"no.\"\n* I respect a clear policy.", "mood": "smug"}],
		"talk": [
			{"topic": "The new job", "lines": [
				"* I got hired. Recently. Tuesday.",
				{"text": "* Every good plan needs funding.\n* This is the funding.", "mood": "smug"},
				"* There's an employee discount.\n* I'm not allowed to give it to\n  you. I asked.",
			]},
			{"topic": "Gloria", "lines": [
				"* The manager. Twenty-two years\n  here. She hired me on the spot.",
				{"text": "* She timed how fast I bag\n  groceries. With a stopwatch.\n* She keeps a stopwatch.", "mood": "shocked"},
				{"text": "* I think we're going to get\n  along.", "mood": "smug"},
			]},
			{"topic": "Your shirt", "lines": [
				"* The apron covers it.\n* Company policy.",
				{"text": "* But I know it's there.\n* That's what matters.", "mood": "smug"},
			]},
			{"topic": "Westview", "lines": [
				"* After dark. Not before.",
				"* Stock up here first. Food heals.\n* Gear helps. Put it on from your\n  BAG.",
				{"text": "* ...And come back after.\n* That's the most important part\n  of the plan.", "mood": "sad"},
			]},
			{"topic": "Cart 14", "lines": [
				"* The cart with the bad wheel.",
				{"text": "* I put it in the dumpster on my\n  first day. It was by the door\n  the next morning.", "mood": "shocked"},
				"* I've added it to my reports.",
			]},
		],
		"exit": "* Thanks for shopping at Vons.\n* ...I have to say that.\n* Stay safe, Elric.",
	}


# --- Jack in the Box ---------------------------------------------------------

const JACK_STOCK := [
	{"name": "Two Tacos", "heal": 12, "price": 6},
	{"name": "Egg Rolls", "heal": 15, "price": 8},
	{"name": "Curly Fries", "heal": 20, "price": 10},
	{"name": "Burger", "heal": 30, "price": 16},
]


## Jack in the Box, open late. Dex works the counter, day and night.
static func jack() -> Dictionary:
	var late := _time() in ["evening", "night"]
	var greeting := "* Welcome to Jack in the Box.\n* I'm Dex. I'm required to say\n  \"welcome.\"\n* So. Welcome."
	if late:
		greeting = "* Oh. Customers. At night.\n* We're open late. I'm here late.\n* Everything is late."
	if _scared():
		greeting = "* W-welcome to Jack in the Box.\n* I'm... not required to say\n  anything else. So I won't."
	return {
		"title": "Jack in the Box", "scene": "jack", "music": "jack", "keeper": "Dex", "sprite": "dex",
		"stock": JACK_STOCK,
		"greeting": greeting,
		"back": "* Anything else? Please say no.",
		"buy_prompt": "The menu's up\nthere. It's a\nmenu.",
		"bought": ["Order up.\nCongratulations,\nI guess.", "Here. It's hot.\nOr it was.", "*beep*\nThat was the\nregister. Not me."],
		"bought_special": {
			"Curly Fries": "Curly fries. The\nonly thing here\nI'd defend with\nmy life.",
			"Two Tacos": "Two tacos. Don't\nask what's in\nthem. I don't\nknow either.",
		},
		"poor": "You can't afford\nthat. Neither can\nI. On my pay.",
		"full": "Your bag's full.\nI'm not a\nmagician.",
		"sold_out": "Sold out.\nThat's new.",
		"sell": ["* You want to sell me... something?", {"text": "* This is a drive-thru.\n* You walked here.", "mood": "angry"}],
		"talk": [
			{"topic": "About you", "lines": [
				"* I'm Dex. I'm sixteen.\n* I've worked here since I was\n  fifteen and a half.",
				{"text": "* The fryer and I understand each\n  other now.", "mood": "sad"},
			]},
			{"topic": "The headset", "lines": [
				"* It's for the drive-thru.",
				{"text": "* Sometimes people order through\n  it at 3 AM, and there's no car\n  outside.", "mood": "shocked"},
				"* I just give them curly fries.\n* They seem happy.",
			]},
			{"topic": "Supreme", "lines": [
				"* The kid with the spreadsheets?\n* He's in here every day after 3.",
				{"text": "* He says we sell 40% more curly\n  fries after 3 PM.\n* That's because of HIM.", "mood": "smug"},
			]},
			{"topic": "Working late", "lines": [
				"* I close at 2 AM.",
				"* Nights are weird out here.\n* Lights on at Westview. Nobody\n  inside. Noises.",
				{"text": "* ...If you're going that way,\n  take extra fries.", "mood": "sad"},
			]},
		],
		"exit": "* Thanks for coming to Jack in the\n  Box.\n* Please don't come back too soon.",
	}


# --- Knotty Barrel -----------------------------------------------------------

const KNOTTY_STOCK := [
	{"name": "Clam Chowder", "heal": 26, "price": 14},
	{"name": "Fish & Chips", "heal": 32, "price": 18},
	{"name": "Salmon Burger", "heal": 40, "price": 22},
]


## Knotty Barrel. Big Lou cooks, serves, and yells, all at once.
static func knotty() -> Dictionary:
	return {
		"title": "Knotty Barrel", "scene": "knotty", "music": "knotty", "keeper": "Lou", "sprite": "lou",
		"stock": KNOTTY_STOCK,
		"greeting": "* ...Welcome to Knotty Barrel.\n* Kitchen's... real quiet today.\n* Real quiet." if _scared()
			else "* WELCOME to Knotty Barrel!\n* I'm Big Lou! Sit anywhere!\n* Everything's fresh! ESPECIALLY\n  the fish!",
		"back": "* What ELSE can I get ya?!",
		"buy_prompt": "EVERYTHING'S\nGOOD! Except\nnothing! It's\nall good!",
		"bought": ["ORDER UP!!\nEnjoy it, kid!", "Made with love!\nAnd butter!\nMostly butter!", "Lou's special!\nThey're ALL Lou's\nspecial!"],
		"bought_special": {
			"Salmon Burger": "SALMON BURGER!\nThe kid in the\nfish mask orders\nsix a day. SIX.",
		},
		"poor": "Short a few\nbucks? Can't do\nit, kid. Lou's\ngot rent!",
		"full": "Your bag's\nstuffed! Come\nback hungry!",
		"sold_out": "All out! Fish\nwasn't biting!",
		"sell": ["* SELL?! To ME?!", {"text": "* Kid, if it ain't fish, I don't\n  want it! HA HA HA!", "mood": "happy"}],
		"talk": [
			{"topic": "About you", "lines": [
				"* Big Lou! Chef, owner, dishwasher,\n  and the guy who yells!",
				{"text": "* Knotty Barrel's been here thirty\n  years! The barrels are older\n  than ME!", "mood": "happy"},
			]},
			{"topic": "The fish mask kid", "lines": [
				"* MuffinMage! Best customer I got!",
				{"text": "* Orders salmon burgers... while\n  WEARING a fish.\n* I got questions. Ethical ones.", "mood": "shocked"},
				{"text": "* But he tips! So I don't ask!", "mood": "happy"},
			]},
			{"topic": "The recipe", "lines": [
				"* The secret to my Salmon Burger?\n* Okay. I'll tell ya.",
				"* ...",
				{"text": "* It's a SECRET! HA HA HA!", "mood": "smug"},
			]},
			{"topic": "Why \"Knotty\"?", "lines": [
				"* The wood's got knots in it!",
				{"text": "* Folks think it's a pun.\n* It's not a pun.\n* ...It's a little bit a pun.", "mood": "sad"},
			]},
		],
		"exit": "* COME BACK HUNGRY, KID!!",
	}


# --- Games & Cards -----------------------------------------------------------

const CARDS_STOCK := [
	{"name": "Card Pack Gum", "heal": 5, "price": 2},
	{"name": "Candy Dice", "heal": 8, "price": 4},
	# Cards go in their own slot (Card), and each has a power (see Items.CARDS).
	{"name": "Lucky Card", "heal": 0, "slot": "card", "price": 30},
	{"name": "Heart Card", "heal": 0, "slot": "card", "price": 45},
	{"name": "Clover Card", "heal": 0, "slot": "card", "price": 25},
	{"name": "Snack Card", "heal": 0, "slot": "card", "price": 20},
	{"name": "Clock Card", "heal": 0, "slot": "card", "price": 40},
	# From the glass case of oddities. It came in a box of old cards.
	{"name": "Divergent Glove", "heal": 0, "slot": "weapon", "atk": 1, "def": 0, "price": 35},
]

## What Old Man Pip pays for anything you sell him.
const PIP_PAYS := 2


## Games & Cards. Its sign has said BACK IN 5 MINUTES for years... until the
## afternoon, when Old Man Pip finally comes back from his sandwich.
static func cards_open() -> bool:
	return _time() != "day"


static func cards() -> Dictionary:
	var first: bool = not Game.flags.get("cards_met", false)
	Game.flags["cards_met"] = true
	var greeting := "* Welcome back to Games & Cards!\n* Mind the dust. It's vintage."
	if first:
		greeting = "* Oh! A customer!\n* Sorry about the sign. I did say\n  five minutes. And here I am!"
	if _time() == "night":
		greeting = "* Still open! I don't close.\n* I just get sleepier."
	if _scared():
		greeting = "* Oh. Oh my.\n* You have the look of someone who\n  doesn't wait five minutes."
	var talk: Array = [
		{"topic": "The sign", "lines": [
			"* BACK IN 5 MINUTES.",
			{"text": "* Has it been more than five\n  minutes? I only went to get a\n  sandwich.", "mood": "shocked"},
			{"text": "* It was a very good sandwich.", "mood": "happy"},
		]},
		{"topic": "The cards", "lines": [
			"* Ah! These aren't just any cards.\n* Hold one, and it does something.",
			{"text": "* Don't ask me how. I just sell\n  them. Put one in your CARD slot\n  from your BAG.", "mood": "happy"},
			"* Everyone gets one card each.\n* Choose wisely! Or don't.\n  I'm not your grandpa.",
		]},
		{"topic": "The glass case", "lines": [
			"* My case of oddities! Things that\n  come in with the cards.",
			{"text": "* That black glove showed up in a\n  box from an estate sale.\n* Its stitching... moves. A bit.", "mood": "shocked"},
			"* Well! Everything here is a bit\n  odd. Including me!",
		]},
		{"topic": "About you", "lines": [
			"* Pip! I've run this shop since\n  before the mall had a roof.",
			"* Trading cards, board games, dice,\n  and puzzles with three pieces\n  missing.",
		]},
	]
	if Game.flags.get("played_games", false):
		talk.append({"topic": "Rock Paper Scissors", "lines": [
			"* I heard you youngsters playing\n  Rock Paper Scissors all day.",
			{"text": "* In my day, we played with REAL\n  rocks.\n* Lost a lot of windows.", "mood": "smug"},
		]})
	talk.append({"topic": "N.C. Wethan", "lines": [
		"* That boy tried to trade me a\n  \"lightning card.\"",
		{"text": "* It was a sticky note.\n* It shocked me anyway.", "mood": "shocked"},
	]})
	if Game.flags.get("heard_lore", false):
		talk.append({"topic": "Old stories", "lines": [
			"* Nat comes in to read the backs\n  of the board game boxes.",
			{"text": "* He told me a story once. Red\n  glass. Broken things.\n* Gave me the chills.", "mood": "sad"},
		]})
	return {
		"title": "Games & Cards", "scene": "cards", "music": "cards", "keeper": "Pip", "sprite": "pip",
		"stock": CARDS_STOCK,
		"greeting": greeting,
		"back": "* Anything else catch your eye?",
		"buy_prompt": "Take your time.\nI certainly do.",
		"bought": ["A fine choice!\nVery collectible.", "Sold! I'll put it\nin the ledger.\nWhen I find it."],
		"bought_special": {
			"Lucky Card": "The ace! Luck is\na funny thing.\nIt likes you now.",
			"Heart Card": "The queen of\nhearts. Keep her\nclose. She'll keep\nyou going.",
			"Clover Card": "Four leaves! The\nmoney will find\nyou. It found me\nonce. In 1987.",
			"Snack Card": "The holo burger!\nEverything tastes\nbetter with it.\nI tested it.",
			"Clock Card": "Tick, tock! Hold\nit, and trouble\ncomes slower.\nLike me!",
			"Card Pack Gum": "From a 1991 pack!\nStill chewy.\nSomehow.",
			"Divergent Glove": "...Ah. That one\ncame in a box of\nold cards. The box\nwas warm. Boxes\naren't warm.",
		},
		"poor": "Oh, dear. Not\nquite enough.\nCome back in\nfive minutes!",
		"full": "Your bag's full!\nI know the\nfeeling. Look at\nthis place.",
		"sold_out": "Gone! Sold! A\nfirst this\ndecade!",
		"buys": PIP_PAYS,
		"sell_intro": "* I buy anything! Two dollars.\n* Flat rate. Since 1987.",
		"sold": "Two dollars!\nA pleasure doing\nbusiness!",
		"talk": talk,
		"exit": "* Come back soon!\n* I'll be right here.\n* ...Probably.",
	}
