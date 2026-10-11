class_name WildBattles
extends RefCounted
## Wild creatures: the little things you can run into anywhere around town (not
## people, and not the Corps). Battles are "wild_<id>". Each area lists which
## ones live there (ZONES), and Area.check_random_encounter() picks one now and
## then as you walk.

const CREATURES := {
	# --- Chapter 2: Downtown ---
	"pigeon_gang": {
		"name": "Pigeon Gang", "sprite": "wild_pigeon_gang",
		"intro": "* The Pigeon Gang surrounds you.\n* They're wearing tiny bandanas.",
		"hp": 100, "atk": 9, "def": 3, "patterns": ["pigeon_swoop", "pigeon_crumbs"],
		"check": "* PIGEON GANG - ATK 9 DEF 3\n* Run this block. Want your fries. All of them.",
		"acts": [
			{"name": "Share Fries", "mercy": 50, "lines": ["* {actor} tosses them a fry.\n* The Pigeon Gang has never been offered anything. They're stunned."]},
			{"name": "Coo", "mercy": 40, "lines": ["* {actor} coos. Badly.\n* The Pigeon Gang coos back, out of pity."]},
		],
		"taunts": ["COO.", "*flap flap*", "FRIES."],
		"flavor": ["* The Pigeon Gang bobs its heads in unison. Menacingly.", "* One of the pigeons is just a guy in a pigeon costume.\n* Nobody mentions it."],
		"backdrop": Color(0.45, 0.45, 0.55), "style": "skyline", "exp": 23, "money": 16,
	},
	"parking_meter": {
		"name": "Parking Meter", "sprite": "wild_parking_meter",
		"intro": "* A Parking Meter blocks your path.\n* Its little flag says EXPIRED.",
		"hp": 112, "atk": 9, "def": 6, "patterns": ["meter_coins", "meter_expired"],
		"check": "* PARKING METER - ATK 9 DEF 6\n* Has given out 40,000 tickets. Has never been thanked.",
		"acts": [
			{"name": "Feed It", "mercy": 50, "lines": ["* {actor} feeds it a quarter.\n* The flag flips to TIME LEFT. It hasn't felt this full in years."]},
			{"name": "Thank It", "mercy": 40, "lines": ["* {actor} thanks it for its service.\n* The Parking Meter makes a small, grateful ding."]},
		],
		"taunts": ["EXPIRED", "*ding*", "*tick tick*"],
		"flavor": ["* The Parking Meter ticks.", "* The Parking Meter is judging where you're standing.\n* It's a loading zone."],
		"backdrop": Color(0.35, 0.4, 0.5), "style": "grid", "exp": 24, "money": 25,
	},
	"neon_sign": {
		"name": "Neon Sign", "sprite": "wild_neon_sign",
		"intro": "* A Neon Sign buzzes to life!\n* Half its letters are out.",
		"hp": 96, "atk": 10, "def": 2, "patterns": ["neon_flicker", "neon_buzz"],
		"check": "* NEON SIGN - ATK 10 DEF 2\n* Used to say OPEN. Now says OP N. It's sensitive about it.",
		"acts": [
			{"name": "Fix Letter", "mercy": 50, "lines": ["* {actor} jiggles the loose E.\n* It flickers back on. OPEN. The sign glows with pride."]},
			{"name": "Read It", "mercy": 40, "lines": ["* {actor} reads it out loud: \"OP N!\"\n* Close enough. The sign is moved."]},
		],
		"taunts": ["*bzzzt*", "OP N", "*hummmm*"],
		"flavor": ["* The Neon Sign flickers. Off. On. Off.", "* Moths are circling the Neon Sign. It loves them."],
		"backdrop": Color(0.6, 0.2, 0.55), "style": "static", "exp": 25, "money": 15,
	},
	# --- Chapter 2: Old Town ---
	"tumbleweed": {
		"name": "Tumbleweed", "sprite": "wild_tumbleweed",
		"intro": "* A Tumbleweed rolls up.\n* It stops. Right in front of you. On purpose.",
		"hp": 92, "atk": 8, "def": 3, "patterns": ["weed_roll", "weed_gust"],
		"check": "* TUMBLEWEED - ATK 8 DEF 3\n* Has rolled here all the way from Arizona. Won't say why.",
		"acts": [
			{"name": "Whistle", "mercy": 50, "lines": ["* {actor} whistles a lonesome tune.\n* The Tumbleweed rolls back and forth, slowly. It's dancing."]},
			{"name": "Untangle", "mercy": 40, "lines": ["* {actor} picks a candy wrapper out of it.\n* It feels lighter. It rolls a happy little circle."]},
		],
		"taunts": ["*rustle*", "*tumble*", "..."],
		"flavor": ["* The Tumbleweed drifts in a wind you can't feel.", "* There's a sock in the Tumbleweed.\n* Nobody asks."],
		"backdrop": Color(0.75, 0.55, 0.35), "style": "plaza", "exp": 19, "money": 12,
	},
	"pinata": {
		"name": "Piñata", "sprite": "wild_pinata",
		"intro": "* A Piñata swings down from the papel picado!\n* It's FULL.",
		"hp": 104, "atk": 8, "def": 4, "patterns": ["pinata_candy", "pinata_swing"],
		"check": "* PIÑATA - ATK 8 DEF 4\n* Survived three birthday parties. Has opinions about sticks.",
		"acts": [
			{"name": "Sing", "mercy": 50, "lines": ["* {actor} sings \"Dale, dale, dale.\"\n* The Piñata sways along. It knows all the words."]},
			{"name": "Put Stick Down", "mercy": 40, "lines": ["* {actor} puts down the stick. Nobody had a stick.\n* The Piñata relaxes anyway."]},
		],
		"taunts": ["DALE DALE", "*crinkle*", "NOT THE STICK"],
		"flavor": ["* The Piñata twirls on its string.", "* Candy rattles inside the Piñata. It's a little smug about it."],
		"backdrop": Color(0.85, 0.35, 0.55), "style": "banners", "exp": 21, "money": 18,
	},
	"wax_ghost": {
		"name": "Wax Ghost", "sprite": "wild_wax_ghost",
		"intro": "* A Wax Ghost drips out of the shadows.\n* Its little flame flickers at you.",
		"hp": 96, "atk": 9, "def": 2, "patterns": ["wax_drip", "wax_flame"],
		"check": "* WAX GHOST - ATK 9 DEF 2\n* Was a candle. Burned all the way down. Kept going.",
		"acts": [
			{"name": "Shield Flame", "mercy": 50, "lines": ["* {actor} cups their hands around its little flame.\n* It stops flickering. It feels safe."]},
			{"name": "Make a Wish", "mercy": 40, "lines": ["* {actor} makes a wish, and doesn't blow.\n* The Wax Ghost has waited a long time for that."]},
		],
		"taunts": ["*drip*", "*fssss*", "...warm..."],
		"flavor": ["* The Wax Ghost drips on the floor. The drips crawl back.", "* Its flame leans toward you, like it's listening."],
		"backdrop": Color(0.45, 0.3, 0.55), "style": "stars", "exp": 22, "money": 14,
	},
	# --- Chapter 2: Balboa Park ---
	"peacock": {
		"name": "Peacock", "sprite": "wild_peacock",
		"intro": "* A Peacock fans its tail at you.\n* Every eye on it is staring.",
		"hp": 80, "atk": 7, "def": 3, "patterns": ["peacock_fan", "peacock_strut"],
		"check": "* PEACOCK - ATK 7 DEF 3\n* Lives in the park. Owns the park. Ask it.",
		"acts": [
			{"name": "Admire", "mercy": 50, "lines": ["* {actor} admires its feathers. Out loud.\n* The Peacock turns, slowly, so you get every angle."]},
			{"name": "Strut", "mercy": 40, "lines": ["* {actor} struts back at it.\n* The Peacock stops. It respects the commitment."]},
		],
		"taunts": ["*MEEE-OWW*", "*rustle*", "*AAAAH*"],
		"flavor": ["* The Peacock's tail shimmers.", "* The Peacock screams for no reason.\n*  Peacocks do that."],
		"backdrop": Color(0.3, 0.6, 0.55), "style": "leaves", "exp": 17, "money": 10,
	},
	"marble_bust": {
		"name": "Marble Bust", "sprite": "wild_marble_bust",
		"intro": "* A Marble Bust has rolled off its pedestal,\n*  and it is FURIOUS about it.",
		"hp": 96, "atk": 8, "def": 5, "patterns": ["bust_roll", "bust_glare"],
		"check": "* MARBLE BUST - ATK 8 DEF 5\n* Some general. Or a poet. The plaque fell off.",
		"acts": [
			{"name": "Read Plaque", "mercy": 50, "lines": ["* {actor} finds the plaque and reads it out loud.\n* The Bust remembers who it is. It stands taller."]},
			{"name": "Dust It", "mercy": 40, "lines": ["* {actor} dusts off its nose.\n* Two hundred years. Nobody ever dusted the nose."]},
		],
		"taunts": ["...", "*crack*", "HMPH"],
		"flavor": ["* The Marble Bust stares blankly.\n*  It has no pupils. Somehow you feel judged.", "* The Marble Bust is missing its nose. Rude to mention."],
		"backdrop": Color(0.7, 0.68, 0.62), "style": "rings", "exp": 19, "money": 12,
	},
	"tour_group": {
		"name": "Tour Group", "sprite": "wild_tour_group",
		"intro": "* A Tour Group surrounds you!\n* Their guide holds the flag high.",
		"hp": 88, "atk": 7, "def": 2, "patterns": ["tour_flags", "tour_flash"],
		"check": "* TOUR GROUP - ATK 7 DEF 2\n* Twelve people, one flag, no idea where they are.",
		"acts": [
			{"name": "Give Directions", "mercy": 50, "lines": ["* {actor} points them to the museum.\n* Twelve people say THANK YOU at slightly different times."]},
			{"name": "Pose", "mercy": 40, "lines": ["* {actor} poses for a photo.\n* Everyone takes one. Nobody checks if it's good."]},
		],
		"taunts": ["*click click*", "IS THIS THE ZOO?", "*murmur*"],
		"flavor": ["* The Tour Group shuffles in a tight circle.", "* Somebody in the back is still eating a churro."],
		"backdrop": Color(0.75, 0.55, 0.4), "style": "plaza", "exp": 18, "money": 15,
	},
	# --- Chapter 2: Mission Beach ---
	"sand_crab": {
		"name": "Sand Crab", "sprite": "wild_sand_crab",
		"intro": "* A Sand Crab bursts up out of the sand,\n*  claws first!",
		"hp": 70, "atk": 6, "def": 3, "patterns": ["crab_pinch", "crab_scuttle"],
		"check": "* SAND CRAB - ATK 6 DEF 3\n* Walks sideways. Thinks sideways. Is never wrong.",
		"acts": [
			{"name": "Walk Sideways", "mercy": 50, "lines": ["* {actor} walks sideways too.\n* The Sand Crab is impressed. Finally, someone gets it."]},
			{"name": "Offer Shell", "mercy": 40, "lines": ["* {actor} holds out a nice shell.\n* The crab considers it. It's a very good shell."]},
		],
		"taunts": ["*click click*", "*CLACK*", "*bubble*"],
		"flavor": ["* The Sand Crab snaps its claws.", "* The Sand Crab is guarding a sandcastle\n*  nobody asked it to guard."],
		"backdrop": Color(0.85, 0.75, 0.5), "style": "waves", "exp": 14, "money": 9,
	},
	"jellyfish": {
		"name": "Jellyfish", "sprite": "wild_jellyfish",
		"intro": "* A Jellyfish wobbles up out of the surf.\n* It shouldn't be able to do that.",
		"hp": 60, "atk": 7, "def": 1, "patterns": ["jelly_drift", "jelly_sting"],
		"check": "* JELLYFISH - ATK 7 DEF 1\n* No brain, no heart, no bones. Plenty of sting.",
		"acts": [
			{"name": "Float", "mercy": 50, "lines": ["* {actor} lies back and floats.\n* The Jellyfish floats too. You're both just... drifting."]},
			{"name": "Back to Sea", "mercy": 40, "lines": ["* {actor} points at the ocean.\n* The Jellyfish looks. It looks for a long time."]},
		],
		"taunts": ["*bloop*", "...", "*wobble*"],
		"flavor": ["* The Jellyfish pulses gently.", "* You can see right through it.\n*  It's thinking about nothing at all."],
		"backdrop": Color(0.3, 0.55, 0.85), "style": "waves", "exp": 15, "money": 7,
	},
	"beach_kite": {
		"name": "Runaway Kite", "sprite": "wild_beach_kite",
		"intro": "* A Runaway Kite swoops down at you,\n*  string trailing!",
		"hp": 64, "atk": 7, "def": 2, "patterns": ["kite_dive", "kite_string"],
		"check": "* RUNAWAY KITE - ATK 7 DEF 2\n* Snapped its string at 9 AM. Never coming down.",
		"acts": [
			{"name": "Grab String", "mercy": 50, "lines": ["* {actor} grabs the trailing string.\n* The Kite tugs, then lets itself be held."]},
			{"name": "Run With It", "mercy": 40, "lines": ["* {actor} runs down the beach with it.\n* The Kite soars. It's the best day of its life."]},
		],
		"taunts": ["*flap*", "*WHOOSH*", "*rustle*"],
		"flavor": ["* The Runaway Kite loops the loop.", "* Somewhere, a kid is still holding\n*  the other end of a string."],
		"backdrop": Color(0.55, 0.8, 0.95), "style": "cliffs", "exp": 15, "money": 8,
	},
	"cart": {
		"name": "Runaway Cart", "sprite": "wild_cart",
		"intro": "* A shopping cart rattles toward you!\n* Nobody is pushing it.",
		"hp": 40, "atk": 4, "def": 1, "patterns": ["cart_ram", "coin_roll"],
		"check": "* RUNAWAY CART - ATK 4 DEF 1\n* Escaped the cart corral. Never looked back.",
		"acts": [
			{"name": "Return It", "mercy": 60, "lines": ["* {actor} walks the cart back to the corral.\n* It rattles. Gratefully?"]},
			{"name": "Fix Wheel", "mercy": 40, "lines": ["* {actor} straightens its wobbly wheel.\n* It rolls in a straight line for the first time ever."]},
		],
		"taunts": ["*rattle*", "*squeak squeak*", "*CLANK*"],
		"flavor": ["* The Runaway Cart's wheel wobbles.", "* There's a single coupon in its child seat."],
		"backdrop": Color(0.75, 0.35, 0.3), "style": "skyline", "exp": 6, "money": 5,
	},
	"receipt": {
		"name": "Receipt", "sprite": "wild_receipt",
		"intro": "* A very, very long receipt\n*  curls up in front of you.",
		"hp": 32, "atk": 3, "def": 0, "patterns": ["receipt_ribbon", "ink_blots"],
		"check": "* RECEIPT - ATK 3 DEF 0\n* Four feet long. You bought one gum.",
		"acts": [
			{"name": "Read It", "mercy": 50, "lines": ["* {actor} reads every line.\n* The Receipt has never felt so seen."]},
			{"name": "Fold", "mercy": 50, "lines": ["* {actor} folds it neatly.\n* It's a lot shorter now. It looks relieved."]},
		],
		"taunts": ["SAVE 10%!", "THANK YOU!", "SURVEY!!"],
		"flavor": ["* The Receipt keeps printing.", "* Take our survey for a chance to win!"],
		"backdrop": Color(0.8, 0.8, 0.8), "style": "skyline", "exp": 5, "money": 4,
	},
	"balloon": {
		"name": "Lost Balloon", "sprite": "wild_balloon",
		"intro": "* A Lost Balloon drifts down to you.",
		"hp": 28, "atk": 3, "def": 0, "patterns": ["balloon_rise", "balloon_pop"],
		"check": "* LOST BALLOON - ATK 3 DEF 0\n* Somebody let go. It's been looking for them all day.",
		"acts": [
			{"name": "Hold String", "mercy": 60, "lines": ["* {actor} holds its string.\n* For a moment, it isn't lost."]},
			{"name": "Look Around", "mercy": 40, "lines": ["* {actor} looks around for whoever lost it.\n* ...Nobody. The balloon sags a little."]},
		],
		"taunts": ["...", "*squeak*", "(bob)"],
		"flavor": ["* The Lost Balloon bobs sadly.", "* Its string trails behind it."],
		"backdrop": Color(0.9, 0.4, 0.5), "style": "skyline", "exp": 5, "money": 2,
	},
	"goose": {
		"name": "Goose", "sprite": "wild_goose",
		"intro": "* HONK.",
		"hp": 50, "atk": 5, "def": 1, "patterns": ["goose_chase", "feathers"],
		"check": "* GOOSE - ATK 5 DEF 1\n* Has no reason to be angry. Is angry.",
		"acts": [
			{"name": "Back Away", "mercy": 50, "lines": ["* {actor} slowly backs away.\n* The Goose accepts this as surrender."]},
			{"name": "Honk Back", "mercy": 50, "lines": ["* {actor} honks back.\n* The Goose stares. A mutual respect forms."]},
		],
		"taunts": ["HONK", "HONK!!", "hiss"],
		"flavor": ["* The Goose spreads its wings.", "* The Goose is looking directly at you."],
		"backdrop": Color(0.4, 0.65, 0.35), "style": "leaves", "exp": 8, "money": 3,
	},
	"sprinkler": {
		"name": "Sprinkler", "sprite": "wild_sprinkler",
		"intro": "* A sprinkler pops up out of the grass!",
		"hp": 38, "atk": 4, "def": 2, "patterns": ["spray_arc", "puddle_splash"],
		"check": "* SPRINKLER - ATK 4 DEF 2\n* On a timer. The timer is broken.",
		"acts": [
			{"name": "Turn Off", "mercy": 60, "lines": ["* {actor} twists the valve.\n* The Sprinkler sputters, and calms down."]},
			{"name": "Run Through", "mercy": 40, "lines": ["* {actor} runs through the spray.\n* ...Okay, that was actually fun."]},
		],
		"taunts": ["tick tick tick", "*fsssh*", "tick tick"],
		"flavor": ["* The Sprinkler ticks around.", "* Everything nearby is soaked."],
		"backdrop": Color(0.3, 0.6, 0.8), "style": "leaves", "exp": 6, "money": 2,
	},
	"gnome": {
		"name": "Garden Gnome", "sprite": "wild_gnome",
		"intro": "* A Garden Gnome is standing in the path.\n* It wasn't there a second ago.",
		"hp": 44, "atk": 4, "def": 3, "patterns": ["gnome_hats", "tiny_shovels"],
		"check": "* GARDEN GNOME - ATK 4 DEF 3\n* Moves when nobody's looking. You're looking.",
		"acts": [
			{"name": "Look Away", "mercy": 50, "lines": ["* {actor} looks away.\n* When they look back, the gnome is smiling."]},
			{"name": "Compliment Hat", "mercy": 50, "lines": ["* {actor} says it's a great hat.\n* The gnome stands a little taller."]},
		],
		"taunts": ["...", "(stares)", "(doesn't move)"],
		"flavor": ["* The Garden Gnome hasn't blinked.", "* Its tiny shovel is very sharp."],
		"backdrop": Color(0.35, 0.55, 0.3), "style": "leaves", "exp": 7, "money": 4,
	},
	"flamingo": {
		"name": "Lawn Flamingo", "sprite": "wild_flamingo",
		"intro": "* A plastic Lawn Flamingo\n*  steps off its lawn.",
		"hp": 40, "atk": 4, "def": 1, "patterns": ["flamingo_stomp", "pink_feathers"],
		"check": "* LAWN FLAMINGO - ATK 4 DEF 1\n* Plastic. Fabulous. Stands on one leg out of spite.",
		"acts": [
			{"name": "Stand on One Leg", "mercy": 60, "lines": ["* {actor} stands on one leg.\n* The flamingo is impressed. Reluctantly."]},
			{"name": "Admire", "mercy": 40, "lines": ["* {actor} admires its pinkness.\n* It knows."]},
		],
		"taunts": ["*clack*", "Fabulous.", "*wobble*"],
		"flavor": ["* The Lawn Flamingo balances perfectly.", "* It's very, very pink."],
		"backdrop": Color(0.95, 0.5, 0.7), "style": "leaves", "exp": 6, "money": 4,
	},
	"seagull": {
		"name": "Hungry Seagull", "sprite": "wild_seagull",
		"intro": "* A Hungry Seagull swoops down!\n* It thinks you have fries.",
		"hp": 34, "atk": 4, "def": 0, "patterns": ["seagull_dive", "fry_steal"],
		"check": "* HUNGRY SEAGULL - ATK 4 DEF 0\n* Has eaten 40 fries today. Wants 41.",
		"acts": [
			{"name": "Show Hands", "mercy": 50, "lines": ["* {actor} shows their empty hands.\n* The seagull does not believe them."]},
			{"name": "Share Snack", "mercy": 50, "lines": ["* {actor} shares a crumb.\n* The seagull screams with joy."]},
		],
		"taunts": ["MINE", "MINE!", "Fry?"],
		"flavor": ["* The Hungry Seagull eyes your pockets.", "* It smells like the beach."],
		"backdrop": Color(0.45, 0.7, 0.9), "style": "waves", "exp": 6, "money": 3,
	},
	"squirrel": {
		"name": "Squirrel", "sprite": "wild_squirrel",
		"intro": "* A Squirrel freezes in front of you.\n* Then it doesn't.",
		"hp": 26, "atk": 3, "def": 0, "patterns": ["acorn_drop", "squirrel_dash"],
		"check": "* SQUIRREL - ATK 3 DEF 0\n* Hid 200 acorns this year. Remembers 3.",
		"acts": [
			{"name": "Hold Still", "mercy": 50, "lines": ["* {actor} holds very still.\n* The Squirrel holds very still too."]},
			{"name": "Offer Acorn", "mercy": 50, "lines": ["* {actor} offers an acorn.\n* It's buried immediately. Somewhere. Forever."]},
		],
		"taunts": ["chk chk!", "!!", "chk?"],
		"flavor": ["* The Squirrel twitches its tail.", "* It has an acorn in each cheek."],
		"backdrop": Color(0.6, 0.45, 0.25), "style": "leaves", "exp": 5, "money": 2,
	},
	"bag": {
		"name": "Plastic Bag", "sprite": "wild_bag",
		"intro": "* A Plastic Bag drifts by on the wind.",
		"hp": 24, "atk": 3, "def": 0, "patterns": ["bag_drift", "gust"],
		"check": "* PLASTIC BAG - ATK 3 DEF 0\n* Drifting through the wind.\n* Wants to start again.",
		"acts": [
			{"name": "Recycle", "mercy": 60, "lines": ["* {actor} folds it up for recycling.\n* It feels like it has a purpose again."]},
			{"name": "Let It Fly", "mercy": 40, "lines": ["* {actor} lets it ride the wind.\n* It does a little loop. Happy."]},
		],
		"taunts": ["*rustle*", "(floats)", "*crinkle*"],
		"flavor": ["* The Plastic Bag rustles.", "* The wind picks up."],
		"backdrop": Color(0.75, 0.8, 0.85), "style": "static", "exp": 4, "money": 1,
	},
}

## Who lives where (scene path -> creature ids).
const ZONES := {
	"res://scenes/mt_carmel.tscn": ["squirrel", "seagull", "bag"],
	"res://scenes/pq_mall.tscn": ["cart", "receipt", "balloon", "seagull"],
	"res://scenes/westview.tscn": ["bag", "squirrel", "seagull"],
	"res://scenes/hilltop.tscn": ["goose", "sprinkler", "balloon"],
	"res://scenes/hop_house.tscn": ["gnome", "flamingo", "bag"],
	"res://scenes/mission_beach.tscn": ["sand_crab", "jellyfish", "beach_kite"],
	"res://scenes/balboa_park.tscn": ["peacock", "marble_bust", "tour_group"],
	"res://scenes/old_town.tscn": ["tumbleweed", "pinata", "wax_ghost"],
	"res://scenes/downtown.tscn": ["pigeon_gang", "parking_meter", "neon_sign"],
	"res://scenes/harbor.tscn": ["seagull", "balloon", "bag"],
	"res://scenes/torrey_pines.tscn": ["seagull", "squirrel", "goose"],
	"res://scenes/burned_hills.tscn": ["squirrel", "bag"],
	"res://scenes/junkyard.tscn": ["cart", "bag", "receipt"],
}


## The battle names for an area's wild creatures (empty if none live there).
static func encounters_for(scene_path: String) -> Array:
	var ids: Array = []
	for id in ZONES.get(scene_path, []):
		ids.append("wild_" + id)
	return ids


static func create(id: String) -> BattleData:
	var c: Dictionary = CREATURES[id]
	var data := BattleData.new()
	data.id = "wild_" + id
	data.backdrop = c["backdrop"]
	data.backdrop_style = c["style"]
	data.intro = [c["intro"]]
	var e := Enemy.new()
	e.name = c["name"]
	e.max_hp = c["hp"]
	e.hp = c["hp"]
	e.attack = c["atk"]
	e.defense = c["def"]
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/%s.png" % c["sprite"])
	e.check_text = c["check"]
	e.acts.assign(c["acts"])
	e.patterns.assign(c["patterns"])
	e.taunts.assign(c["taunts"])
	e.flavor_lines.assign(c["flavor"])
	e.bullet_speed = 90.0
	e.exp_reward = c["exp"]
	e.bond_reward = 6
	e.money_reward = c["money"]
	data.enemies.append(e)
	return data
