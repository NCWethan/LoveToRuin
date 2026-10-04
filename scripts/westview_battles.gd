class_name WestviewBattles
extends RefCounted
## The fights inside Westview High School, where fragment 2 has twisted the school itself.


static func create(id: String) -> BattleData:
	var data := BattleData.new()
	data.id = id
	match id:
		"pop_quiz":
			data.enemies.append(_pop_quiz())
			data.intro = ["* A Pop Quiz appears!", "* (Nobody studied for this.)"]
		"hall_pass":
			data.enemies.append(_hall_pass())
			data.intro = ["* A Hall Pass sprints into you!", "* (It's late for something.)"]
		"wally":
			data.enemies.append(_wally())
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
	e.patterns = ["pencils", "bubbles"]
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
	e.patterns = ["papers", "zoom"]
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


## Wally Wolverine, Westview's mascot. The costume is empty; fragment 2 is what's moving him.
static func _wally() -> Enemy:
	var e := Enemy.new()
	e.name = "Wally Wolverine"
	e.max_hp = 160
	e.hp = 160
	e.attack = 4
	e.defense = 2
	e.position = Vector2(470, 170)
	e.sprite = load("res://art/sprites/wally.png")
	e.check_text = "* WALLY WOLVERINE - ATK 8 DEF 2\n* Westview's mascot. Nobody's inside.\n* Something red glows where his heart should be."
	e.acts = [
		{
			"name": "Cheer",
			"mercy": 30,
			"lines": [
				"* {actor} chants \"GO WOLVERINES!\"\n* Wally does a little dance. He looks confused.",
				"* {actor} cheers louder!\n* Wally pumps a big furry fist in the air.",
				"* {actor} starts a whole chant.\n* Wally is having the time of his life.",
			],
		},
		{
			"name": "Look Inside",
			"mercy": 25,
			"lines": [
				"* {actor} peeks inside the costume.\n* It's empty. Except for a red glow.",
				"* {actor} looks again.\n* The glow pulses. Wally seems... tired.",
			],
		},
		{
			"name": "Paw Five",
			"mercy": 20,
			"lines": [
				"* {actor} holds up a hand for a high five.\n* Wally's giant paw misses completely.",
				"* {actor} tries again.\n* SMACK! A perfect paw five. (Claws and all.)",
			],
		},
	]
	e.patterns = ["confetti", "claw_swipe", "dodgeballs", "claw_drop", "foam_finger"]
	e.taunts = ["GO WOLVERINES!!", "GRRR... GO TEAM!", "DEFENSE! DEFENSE!", "GIMME A W!", "..."]
	e.spare_taunts = ["...go wolverines."]
	e.flavor_lines = [
		"* Wally does a backflip. Badly.",
		"* Wally sharpens his claws on the bleachers.",
		"* Something inside the costume hums.",
		"* There's no crowd. Wally cheers anyway.",
	]
	e.exp_reward = 30
	e.bond_reward = 30
	e.money_reward = 40
	return e
