extends RefCounted
## Fights in the REVOLUTION Corps' bunker. For now just one: sparring with the
## training dummy in the main hall. It's safe practice (the dummy hits softly and
## never counts as a kill), and it's where you can try calling a friend for help.

static func create(id: String) -> BattleData:
	var data := BattleData.new()
	data.id = id
	data.enemies.append(_dummy())
	data.music = "battle"
	data.backdrop_style = "diamonds"
	data.backdrop = Color(0.55, 0.6, 0.7)
	data.intro = ["* The training dummy stares blankly.", "* (Practice! It won't hit hard.)"]
	return data


static func _dummy() -> Enemy:
	var e := Enemy.new()
	e.name = "Training Dummy"
	e.max_hp = 120
	e.hp = 120
	e.attack = 1
	e.defense = 0
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/training_dummy.png")
	e.check_text = "* TRAINING DUMMY - ATK 1 DEF 0\n* Stuffed with straw and good intentions.\n* N.C. Wethan has broken six of these."
	e.acts = [
		{
			"name": "Bow",
			"mercy": 100,
			"lines": ["* {actor} bows politely.\n* The dummy... nods? Practice over."],
		},
	]
	e.patterns = ["rain", "lance"]
	e.taunts = ["...", "(straw rustling)", "..."]
	e.spare_taunts = ["(a satisfied rustle)"]
	e.flavor_lines = ["* The dummy wobbles on its post.", "* Someone drew a mustache on it.", "* It smells like hay."]
	e.bullet_speed = 85.0
	e.exp_reward = 0
	e.bond_reward = 0
	e.money_reward = 0
	return e
