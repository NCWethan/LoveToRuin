class_name WestviewBattles
extends RefCounted
## The fights inside Westview High School, where fragment 2 has twisted the school itself.

## How often each random fight shows up, per room. Bigger number = more common.
## The tent is very, very rare.
const HALLWAY_ENCOUNTERS := {"hall_pass": 30, "tardy_bell": 25, "pop_quiz": 20, "mystery_meat": 15, "overdue_book": 10, "tent": 1}
const CLASSROOM_ENCOUNTERS := {"pop_quiz": 35, "overdue_book": 25, "mystery_meat": 20, "tardy_bell": 10, "hall_pass": 10, "tent": 1}


static func create(id: String) -> BattleData:
	var data := BattleData.new()
	data.id = id
	# Teal for the school's twisted halls; Wally gets gold below.
	data.backdrop = Color(0.15, 0.65, 0.6)
	match id:
		"pop_quiz":
			data.enemies.append(_pop_quiz())
			data.intro = ["* A Pop Quiz appears!", "* (Nobody studied for this.)"]
		"hall_pass":
			data.enemies.append(_hall_pass())
			data.intro = ["* A Hall Pass sprints into you!", "* (It's late for something.)"]
		"mystery_meat":
			data.enemies.append(_mystery_meat())
			data.intro = ["* Mystery Meat slides off a lunch tray!", "* (Nobody knows what it is.\n*  Including Mystery Meat.)"]
		"tardy_bell":
			data.enemies.append(_tardy_bell())
			data.intro = ["* The Tardy Bell rings itself off the wall!", "* (RRRRRING!)"]
		"overdue_book":
			data.enemies.append(_overdue_book())
			data.intro = ["* An Overdue Book flaps out of the stacks!", "* (It's 47 years late.)"]
		"tent":
			data.event = "tent"
			data.enemies.append(_tent())
			data.intro = ["* A tent."]
		"wally":
			data.enemies.append(_wally())
			data.music = "boss"
			data.backdrop = Color(0.9, 0.62, 0.2)
			data.boss_style = "wally"
			data.intro = [
				"* Wally Wolverine rises from center court!",
				"* (Something inside the costume is glowing red.)",
			]
	return data


static func _pop_quiz() -> Enemy:
	var e := Enemy.new()
	e.name = "Pop Quiz"
	e.max_hp = 40
	e.hp = 40
	e.attack = 3
	e.defense = 0
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/pop_quiz.png")
	e.check_text = "* POP QUIZ - ATK 5 DEF 0\n* A test nobody studied for.\n* It didn't study either."
	e.acts = [
		{
			"name": "Answer",
			"mercy": 50,
			"lines": [
				"* {actor} answers the first question.\n* It's C. It's always C.",
				"* {actor} answers the rest.\n* Pop Quiz looks... proud?",
			],
		},
		{
			"name": "Study",
			"mercy": 25,
			"lines": ["* {actor} pretends to study.\n* Pop Quiz relaxes its margins."],
		},
	]
	e.patterns = ["pencils", "bubbles", "scantron"]
	e.taunts = ["Show your work!", "Pencils down!", "No talking!"]
	e.spare_taunts = ["...A+?"]
	e.flavor_lines = [
		"* Pop Quiz rustles menacingly.",
		"* It smells like pencil shavings.",
		"* Pop Quiz is grading you silently.",
	]
	e.exp_reward = 8
	e.bond_reward = 8
	e.money_reward = 10
	return e


static func _hall_pass() -> Enemy:
	var e := Enemy.new()
	e.name = "Hall Pass"
	e.max_hp = 45
	e.hp = 45
	e.attack = 3
	e.defense = 1
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/hall_pass.png")
	e.check_text = "* HALL PASS - ATK 6 DEF 1\n* Always in a hurry.\n* Nobody knows where it's going."
	e.acts = [
		{
			"name": "Sign It",
			"mercy": 40,
			"lines": [
				"* {actor} signs Hall Pass.\n* It stands up a little straighter.",
				"* {actor} signs it again, very neatly.\n* Hall Pass feels extremely official.",
			],
		},
		{
			"name": "Ask Directions",
			"mercy": 30,
			"lines": ["* {actor} asks Hall Pass for directions.\n* It points in every direction at once."],
		},
	]
	e.patterns = ["papers", "zoom", "tardy_slips"]
	e.taunts = ["Where's your pass?!", "No running!", "LATE! LATE!"]
	e.spare_taunts = ["...you may go."]
	e.flavor_lines = [
		"* Hall Pass checks a watch it doesn't have.",
		"* Hall Pass is running late. For what?",
		"* Somewhere, a bell rings. Nobody rang it.",
	]
	e.exp_reward = 8
	e.bond_reward = 8
	e.money_reward = 10
	return e


static func _mystery_meat() -> Enemy:
	var e := Enemy.new()
	e.name = "Mystery Meat"
	e.max_hp = 50
	e.hp = 50
	e.attack = 3
	e.defense = 1
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/mystery_meat.png")
	e.check_text = "* MYSTERY MEAT - ATK 6 DEF 1\n* Served every Tuesday since 1987.\n* Its ingredients are classified."
	e.acts = [
		{
			"name": "Compliment",
			"mercy": 35,
			"lines": [
				"* {actor} says it smells \"interesting.\"\n* Mystery Meat jiggles happily.",
				"* {actor} asks for the recipe.\n* Mystery Meat doesn't know it either.",
			],
		},
		{
			"name": "Add Salt",
			"mercy": 30,
			"lines": [
				"* {actor} sprinkles a little salt on it.\n* Mystery Meat feels seasoned. And seen.",
				"* {actor} adds more salt.\n* ...That's enough salt.",
			],
		},
		{
			"name": "Take a Bite",
			"mercy": 0,
			"lines": [
				"* {actor} takes a tiny bite.\n* ...\n* {actor} regrets everything.",
			],
		},
	]
	e.patterns = ["gravy", "tray_toss", "peas"]
	e.bullet_speed = 90.0
	e.taunts = ["*squelch*", "TUESDAY!", "Finish your plate!", "*wobble*"]
	e.spare_taunts = ["...thank you for not eating me."]
	e.flavor_lines = [
		"* Mystery Meat wobbles. It might be a threat.",
		"* The smell of the cafeteria fills the air.",
		"* Mystery Meat is gaining sentience. Slowly.",
	]
	e.exp_reward = 9
	e.bond_reward = 9
	e.money_reward = 12
	return e


static func _tardy_bell() -> Enemy:
	var e := Enemy.new()
	e.name = "Tardy Bell"
	e.max_hp = 55
	e.hp = 55
	e.attack = 4
	e.defense = 1
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/tardy_bell.png")
	e.check_text = "* TARDY BELL - ATK 7 DEF 1\n* It rings at the worst possible time.\n* It's very proud of that."
	e.acts = [
		{
			"name": "Cover Ears",
			"mercy": 25,
			"lines": [
				"* {actor} covers their ears.\n* Tardy Bell rings louder, out of spite.",
				"* {actor} covers their ears again.\n* Tardy Bell gets tired of ringing.",
			],
		},
		{
			"name": "Be On Time",
			"mercy": 45,
			"lines": [
				"* {actor} stands perfectly still, exactly on time.\n* Tardy Bell has nothing to ring about.",
				"* {actor} is early. EARLY.\n* Tardy Bell is speechless.",
			],
		},
	]
	e.patterns = ["sound_waves", "ring", "alarm"]
	e.taunts = ["RRRING!", "YOU'RE LATE!", "DING DING DING!", "Class started!"]
	e.spare_taunts = ["...ding."]
	e.flavor_lines = [
		"* Your ears are still ringing.",
		"* Tardy Bell vibrates with excitement.",
		"* Somewhere, a class you aren't in has started.",
	]
	e.exp_reward = 10
	e.bond_reward = 10
	e.money_reward = 12
	return e


static func _overdue_book() -> Enemy:
	var e := Enemy.new()
	e.name = "Overdue Book"
	e.max_hp = 60
	e.hp = 60
	e.attack = 4
	e.defense = 2
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/overdue_book.png")
	e.check_text = "* OVERDUE BOOK - ATK 7 DEF 2\n* Checked out in 1979. Never returned.\n* It has been waiting a long time."
	e.acts = [
		{
			"name": "Read It",
			"mercy": 35,
			"lines": [
				"* {actor} reads the first chapter.\n* Overdue Book's pages flutter. Nobody's read it in years.",
				"* {actor} keeps reading.\n* It's actually pretty good.",
			],
		},
		{
			"name": "Return It",
			"mercy": 40,
			"lines": [
				"* {actor} offers to take it back to the library.\n* Overdue Book hesitates.",
				"* {actor} promises. Really promises.\n* Overdue Book closes its cover gently.",
			],
		},
		{
			"name": "Shush",
			"mercy": 15,
			"lines": ["* {actor} says \"shhh.\"\n* Overdue Book respects the library rules."],
		},
	]
	e.patterns = ["pages", "bookmark", "shelf"]
	e.taunts = ["SHHHH!", "Late fees!", "47 years...", "Return me!"]
	e.spare_taunts = ["...due back soon?"]
	e.flavor_lines = [
		"* Overdue Book smells like old paper.",
		"* A bookmark sticks out. It's from 1979.",
		"* Overdue Book is very quiet. It's a library thing.",
	]
	e.exp_reward = 11
	e.bond_reward = 11
	e.money_reward = 14
	return e


## Not a real enemy. Just a tent. Three people could fit inside.
static func _tent() -> Enemy:
	var e := Enemy.new()
	e.name = "Tent"
	e.max_hp = 1
	e.hp = 1
	e.position = Vector2(400, 150)
	e.sprite = load("res://art/sprites/tent.png")
	e.check_text = "* TENT.\n* Three people could fit inside."
	e.patterns = ["rain"]
	return e


## Wally Wolverine, Westview's mascot. The costume is empty; fragment 2 is what's moving him.
## A miniboss: tougher attacks, a boss health bar, and sparing him takes a lot of
## different ACTs (he gets bored if you do the same one twice in a row).
static func _wally() -> Enemy:
	var e := Enemy.new()
	e.name = "Wally Wolverine"
	e.max_hp = 200
	e.hp = 200
	e.attack = 5
	e.defense = 2
	e.position = Vector2(470, 170)
	e.sprite = load("res://art/sprites/wally.png")
	e.check_text = "* WALLY WOLVERINE - ATK 10 DEF 2\n* Westview's mascot. Nobody's inside.\n* He loves a crowd that keeps things fresh."
	e.acts = [
		{
			"name": "Cheer",
			"mercy": 12,
			"lines": [
				"* {actor} chants \"GO WOLVERINES!\"\n* Wally does a little dance. He looks confused.",
				"* {actor} cheers louder!\n* Wally pumps a big furry fist in the air.",
				"* {actor} starts a whole chant.\n* Wally is having the time of his life.",
			],
		},
		{
			"name": "Look Inside",
			"mercy": 10,
			"lines": [
				"* {actor} peeks inside the costume.\n* It's empty. Except for a red glow.",
				"* {actor} looks again.\n* The glow pulses. Wally seems... tired.",
				"* {actor} looks closer.\n* The red glow flickers, like it's losing its grip.",
			],
		},
		{
			"name": "Paw Five",
			"mercy": 10,
			"lines": [
				"* {actor} holds up a hand for a high five.\n* Wally's giant paw misses completely.",
				"* {actor} tries again.\n* SMACK! A perfect paw five. (Claws and all.)",
				"* {actor} goes for the double paw five!\n* Wally nails it. He's never been prouder.",
			],
		},
		{
			"name": "The Wave",
			"mercy": 14,
			"lines": [
				"* {actor} starts the wave!\n* It's just {actor}. Wally joins in anyway.",
				"* {actor} does the wave again!\n* Wally does it so hard he falls over.",
			],
		},
	]
	e.bores_easily = true
	e.bored_line = "* Wally yawns a huge furry yawn.\n* He's seen that already. (Mix it up!)"
	e.patterns = ["confetti", "claw_swipe", "dodgeballs", "claw_drop", "foam_finger", "bleacher_wave", "mascot_spin", "frenzy"]
	e.taunts = ["GO WOLVERINES!!", "GRRR... GO TEAM!", "DEFENSE! DEFENSE!", "GIMME A W!", "..."]
	e.spare_taunts = ["...go wolverines."]
	e.flavor_lines = [
		"* Wally does a backflip. Badly.",
		"* Wally sharpens his claws on the bleachers.",
		"* Something inside the costume hums.",
		"* There's no crowd. Wally cheers anyway.",
		"* Wally wants a show. Something new every time.",
	]
	e.exp_reward = 30
	e.bond_reward = 30
	e.money_reward = 40
	return e
