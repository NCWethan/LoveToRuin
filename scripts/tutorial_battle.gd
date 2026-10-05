class_name TutorialBattle
extends RefCounted
## Everything specific to the tutorial fight: Elric and Hop vs. Eggo and BigJoe6.
## battle.gd runs the fight; this file only describes it.

## Shown before the first enemy turn.
const INTRO := [
	"* BigJoe6 blocks the way!\n* Eggo is... also here.",
	"* BigJoe6: \"Hand over the fragment,\n*   Hopkuna's lackey!\"",
	"* (Use the ARROW KEYS to move your SOUL.\n*  Dodge the attacks!)",
]


static func create_party() -> Array[PartyMember]:
	var party: Array[PartyMember] = [
		PartyMember.new("Elric", 30, 6, Color(0.8, 0.65, 1.0), load("res://art/sprites/elric.png")),
		PartyMember.new("Hop", 35, 7, Color(0.75, 0.75, 0.75), load("res://art/sprites/hop.png")),
	]
	return party


static func create_enemies() -> Array[Enemy]:
	var eggo := Enemy.new()
	eggo.name = "Eggo"
	eggo.max_hp = 60
	eggo.hp = 60
	eggo.attack = 3
	eggo.defense = 1
	eggo.position = Vector2(410, 140)
	eggo.sprite = load("res://art/sprites/eggo.png")
	eggo.head_color = Color(1.0, 0.85, 0.2)
	eggo.body_color = Color(0.15, 0.2, 0.45)
	eggo.check_text = "* EGGO - ATK 6 DEF 1\n* Co-founder of Revolution. Chill.\n* Can't resist a good pun."
	eggo.acts = [
		{
			"name": "Pun",
			"mercy": 50,
			"lines": [
				"* {actor} tells Eggo a pun about fragments.\n* \"...frag-tastic.\" Eggo cracks a grin.",
				"* {actor} tells another pun.\n* Eggo is trying very hard not to laugh.",
			],
		},
		{
			"name": "Pet Bunny",
			"mercy": 25,
			"lines": [
				"* {actor} waves at the bunny on Eggo's shoulder.\n* It wiggles its nose. Eggo relaxes a little.",
			],
		},
	]
	eggo.patterns = ["rain", "egg_drop", "bunny_hop"]
	eggo.bullet_speed = 115.0
	eggo.taunts = ["...", "Yolk's on you.", "Eggs-actly."]
	eggo.spare_taunts = ["heh. good one."]

	var bigjoe := Enemy.new()
	bigjoe.name = "BigJoe6"
	bigjoe.max_hp = 70
	bigjoe.hp = 70
	bigjoe.attack = 4
	bigjoe.defense = 2
	bigjoe.position = Vector2(560, 140)
	bigjoe.sprite = load("res://art/sprites/bigjoe6.png")
	bigjoe.head_color = Color(0.78, 0.8, 0.86)
	bigjoe.body_color = Color(0.12, 0.12, 0.12)
	bigjoe.check_text = "* BIGJOE6 - ATK 8 DEF 2\n* Co-founder of Revolution.\n* Fights for justice and truth."
	bigjoe.acts = [
		{
			"name": "Tell Truth",
			"mercy": 40,
			"lines": [
				"* {actor} explains the fragment was just lying there.\n* BigJoe6 hesitates.",
				"* {actor} calmly tells the truth again.\n* BigJoe6's grip loosens.",
				"* {actor} keeps being honest.\n* BigJoe6 can't argue with the truth.",
			],
		},
		{
			"name": "Joke",
			"mercy": 20,
			"lines": [
				"* {actor} tries a joke.\n* BigJoe6 snorts despite himself.",
			],
		},
	]
	bigjoe.patterns = ["lance", "sweep", "aimed"]
	bigjoe.bullet_speed = 170.0
	bigjoe.taunts = ["Justice prevails!", "Hand it over!", "No mercy, lackey!"]
	bigjoe.spare_taunts = ["...you're legit?"]

	# If one of them goes down, the other takes it hard.
	eggo.partner_reactions = {"BigJoe6": {
		"line": "* Eggo: \"...joe? JOE.\"\n* Eggo stops joking. Eggo's hands are shaking.",
		"mood": "sad",
		"taunts": ["...get up, joe.", "not funny anymore.", "..."],
	}}
	bigjoe.partner_reactions = {"Eggo": {
		"line": "* BigJoe6: \"EGGO!!\"\n* BigJoe6 is FURIOUS. His attacks get fiercer!",
		"mood": "angry",
		"taunts": ["YOU'LL PAY FOR THAT!", "NO MORE HOLDING BACK!", "FOR EGGO!"],
		"attack": 1,
	}}

	var enemies: Array[Enemy] = [eggo, bigjoe]
	return enemies


## Each item is a Dictionary with a "name" and how much HP it "heal"s.
static func create_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = [
		{"name": "Salmon Burger", "heal": 30},
		{"name": "Trail Mix", "heal": 15},
		{"name": "Trail Mix", "heal": 15},
		{"name": "Soda", "heal": 10},
	]
	return items


## Which enemies attack on enemy turn number `enemy_turn` (the first is 0).
## In the tutorial, BigJoe6 attacks alone first so the player can learn to dodge.
static func attackers(enemy_turn: int, enemies: Array[Enemy]) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for enemy in enemies:
		if enemy.is_active() and (enemy_turn > 0 or enemy.name == "BigJoe6"):
			result.append(enemy)
	# If BigJoe6 is gone, whoever is left attacks.
	if result.is_empty():
		for enemy in enemies:
			if enemy.is_active():
				result.append(enemy)
	return result


## The text shown in the box at the start of each player turn.
## Turn by turn, it teaches one new mechanic.
static func flavor_text(turn: int, enemies: Array[Enemy]) -> String:
	# Once someone can be spared, always point that out first.
	for enemy in enemies:
		if enemy.is_active() and enemy.can_spare():
			return "* %s's name is YELLOW.\n* (Pick MERCY, then choose %s to SPARE.)" % [enemy.name, enemy.name]

	match turn:
		1:
			return "* Hop: \"Don't just stand there - hit 'em!\"\n* (Pick FIGHT. Press ENTER when the bar is\n*  in the middle.)"
		2:
			return "* Eggo: \"...you could also just talk to us.\"\n* (Try ACT. CHECK shows an enemy's stats.)"
		3:
			return "* (Every enemy has their own ACT options.\n*  Tell Eggo a pun, or tell BigJoe6 the truth.)"
		4:
			return "* (Party members take turns too.\n*  Hop can FIGHT, ACT, use ITEMs or DEFEND.)"
		5:
			return "* (Low on HP? ITEM heals.\n*  DEFEND halves the damage you take.)"
		_:
			return "* Eggo and BigJoe6 stand their ground."


## The tutorial fight as BattleData (enemies attack first, scripted hints each turn).
static func create_data() -> BattleData:
	var data := BattleData.new()
	data.id = "tutorial"
	data.enemies = create_enemies()
	data.intro = INTRO
	data.player_first = false
	data.flavor = TutorialBattle.flavor_text
	data.attackers = TutorialBattle.attackers
	return data
