class_name HilltopBattles
extends RefCounted
## The fight at Hilltop Park: Hopkuna, wearing Hop's body. It can't be won,
## only survived, until the REVOLUTION Corps arrives.

const SURVIVE_TURNS := 5


static func create(id: String) -> BattleData:
	var data := BattleData.new()
	data.id = id
	data.enemies.append(_hopkuna())
	data.music = "hopkuna"
	data.party_only.assign(["Elric"])
	data.player_first = false
	data.survive_turns = SURVIVE_TURNS
	data.aura = Color(0.95, 0.1, 0.18)
	data.backdrop = Color(0.85, 0.12, 0.2)
	data.boss_style = "hopkuna"
	data.intro = [
		"* Hopkuna attacks!",
		"* (Hop isn't here to fight beside you.\n*  You're on your own.)",
	]
	data.survive_lines = [
		"* (Hopkuna raises his hand for one last strike...)",
		"* (...and a whistle splits the air.)",
	]
	data.flavor = HilltopBattles._flavor
	return data


static func _flavor(turn: int, _enemies: Array[Enemy]) -> String:
	match turn:
		1:
			return "* Hopkuna is smiling with Hop's face.\n* (You can't win this. Just survive.)"
		2:
			return "* Somewhere inside, Hop is screaming."
		3:
			return "* The fragments in your pocket are burning hot."
		4:
			return "* Your legs are shaking.\n* You stay DETERMINED."
		_:
			return "* In the distance... footsteps?"


static func _hopkuna() -> Enemy:
	var e := Enemy.new()
	e.name = "Hopkuna"
	e.max_hp = 9999
	e.hp = 9999
	e.attack = 6
	e.defense = 999
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/hopkuna.png")
	e.check_text = "* HOPKUNA - ATK ??? DEF ???\n* Hop's body. Not Hop.\n* You can't win this. Just survive."
	e.acts = [
		{
			"name": "Talk to Hop",
			"mercy": 0,
			"lines": [
				"* {actor} calls out Hop's name.\n* For a split second, Hopkuna flinches.",
				"* {actor} tells Hop they're not leaving.\n* Hopkuna laughs. But his hand is shaking.",
				"* {actor} keeps talking to Hop.\n* Hopkuna snarls: \"Stop that.\"",
			],
		},
		{
			"name": "Stand Firm",
			"mercy": 0,
			"lines": [
				"* {actor} plants their feet.\n* {actor} isn't running.",
				"* {actor} holds the fragments tight.\n* Hopkuna's eyes follow them hungrily.",
			],
		},
	]
	e.patterns = ["cleave", "red_arrows", "slash_grid", "burst", "fire_arrow"]
	e.taunts = ["Run, little wanderer.", "Is that all?", "Hop can't hear you.", "Give me the fragments.", "Finally. FREE."]
	e.spare_refusal = "* You can't spare Hopkuna.\n* He isn't fighting the way you are."
	e.hit_line = "* It barely leaves a mark."
	e.exp_reward = 0
	e.bond_reward = 0
	e.money_reward = 0
	return e
