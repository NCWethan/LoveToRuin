class_name WildBattles
extends RefCounted
## Wild creatures: the little things you can run into anywhere around town (not
## people, and not the Corps). Battles are "wild_<id>". Each area lists which
## ones live there (ZONES), and Area.check_random_encounter() picks one now and
## then as you walk.

const CREATURES := {
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
		"backdrop": Color(0.75, 0.35, 0.3), "style": "grid", "exp": 6, "money": 5,
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
		"backdrop": Color(0.8, 0.8, 0.8), "style": "grid", "exp": 5, "money": 4,
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
		"backdrop": Color(0.9, 0.4, 0.5), "style": "bubbles", "exp": 5, "money": 2,
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
		"backdrop": Color(0.4, 0.65, 0.35), "style": "rings", "exp": 8, "money": 3,
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
		"backdrop": Color(0.3, 0.6, 0.8), "style": "bubbles", "exp": 6, "money": 2,
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
		"backdrop": Color(0.35, 0.55, 0.3), "style": "stars", "exp": 7, "money": 4,
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
		"backdrop": Color(0.95, 0.5, 0.7), "style": "spotlights", "exp": 6, "money": 4,
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
		"backdrop": Color(0.45, 0.7, 0.9), "style": "rings", "exp": 6, "money": 3,
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
		"backdrop": Color(0.6, 0.45, 0.25), "style": "stars", "exp": 5, "money": 2,
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
