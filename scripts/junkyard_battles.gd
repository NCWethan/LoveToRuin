extends RefCounted
## The junkyard by the freeway (no fragment).
##
## Scrap Heap: a crane with a car crusher for a body and a magnet for a hand. It's
## been sorting junk alone for years and it doesn't want anyone taking anything.
## Spare it by calming it down: with the Corps, Sansworth tries his 31 keys on it
## (one of them fits); going your own way, oil its gears. From the sixth turn it
## overheats (THE COMPACTOR).
##
## On the Genocide path, Sansworth is at his van. He was going to drive everyone to
## safety. He's too dumb to run. The van never starts.

const RELIC_LINES := [
	"* No.",
	"* He thinks the van will start. It won't.",
	"* Nothing here starts again.",
]


static func create(id: String) -> BattleData:
	if id == "corps_sansworth":
		return _sansworth()
	return _scrap_heap()


static func _scrap_heap() -> BattleData:
	var data := BattleData.new()
	data.id = "scrap_heap"
	data.music = "scrap_heap"
	data.backdrop = Color(0.55, 0.4, 0.3)
	data.backdrop_style = "grid"
	data.intro = ["* Scrap Heap's magnet swings around.\n* Its headlights snap on. It's MAD."]
	var e := Enemy.new()
	e.name = "Scrap Heap"
	e.max_hp = 440
	e.hp = 440
	e.attack = 7
	e.defense = 4
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/scrap_heap.png")
	e.check_text = "* SCRAP HEAP - ATK 7 DEF 4\n* A crane and a crusher, welded together, sorting junk\n  alone for years. Everything here is ITS."
	e.patterns.assign(["car_fling", "crusher_press", "magnet_pull", "tire_roll", "hubcaps", "spring_coil"])
	e.finale_patterns.assign(["compactor"])
	e.finale_turn = 6
	e.finale_line = "* Scrap Heap is overheating. Steam everywhere.\n* It's going to crush EVERYTHING."
	var acts: Array = [
		{"name": "Kick the Tires", "mercy": 15, "lines": ["* {actor} kicks its tires.\n* Scrap Heap's headlights flicker. It... likes that?"]},
		{"name": "Sort the Junk", "mercy": 20, "lines": ["* {actor} helps sort a pile. Hubcaps here, springs there.\n* Scrap Heap watches. Then it helps."]},
	]
	if Game.flags.get("route", "") == "pacifist":
		acts.append({"name": "Sansworth", "once": true, "mercy": 45, "again": "* Sansworth already found the right key.\n* He's still very proud.", "lines": [
			"* {actor} looks at Sansworth.\n* Sansworth: \"I got this. I got thirty-one of this.\"",
			"* Sansworth tries every key on the crane's control box.\n* Key 30 fits. He has no idea why.",
			"* The crane goes quiet. Its magnet lowers, slowly.\n* Somebody's finally got the keys.",
		]})
	else:
		acts.append({"name": "Oil the Gears", "once": true, "mercy": 40, "again": "* The gears are already oiled.", "lines": [
			"* {actor} finds an oil can and does the gears.\n* All of them. It takes a while.",
			"* Scrap Heap makes a sound like a very long sigh.",
		]})
	e.acts.assign(acts)
	e.taunts.assign(["*CLANK*", "MINE", "*grind*", "NO TOUCHING", "*hiss*"])
	e.spare_taunts.assign(["*clunk*"])
	e.flavor_lines.assign([
		"* Scrap Heap stacks a car on another car, neatly.",
		"* The magnet drags a shopping cart across the lot.",
		"* Somewhere in the pile, a car alarm starts. Then stops.",
	])
	e.exp_reward = 120
	e.bond_reward = 50
	e.money_reward = 60
	data.enemies.append(e)
	return data


static func _sansworth() -> BattleData:
	var data := BattleData.new()
	data.id = "corps_sansworth"
	data.silent = true
	data.backdrop = Color(0.45, 0.45, 0.5)
	data.backdrop_style = "grid"
	data.intro = ["* Sansworth stands in front of the van, with all\n* 31 keys in his fist. \"Get in. I'll drive.\""]
	data.locked_buttons.assign(["MERCY"])
	data.locked_lines.assign(RELIC_LINES)
	var e := Enemy.new()
	e.name = "Sansworth"
	e.max_hp = CorpsAttacks.boss_hp(240)
	e.hp = e.max_hp
	e.attack = 8
	e.defense = 2
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/sansworth.png")
	e.check_text = "* SANSWORTH - ATK 8 DEF 2\n* Thought he'd drive everyone somewhere safe.\n* Doesn't know how to drive."
	e.acts.assign([
		{"name": "Talk", "mercy": 0, "lines": ["* {actor} says nothing.\n* Sansworth: \"Shotgun's open! For anybody! Hop?\""]},
		{"name": "The Keys", "mercy": 0, "lines": ["* {actor} looks at the keys.\n* Sansworth: \"One of these is for the van. I'm SURE.\""]},
	])
	e.patterns.assign(["honk", "key_ring", "rev_engine", "high_beams", "wrong_turn", "parallel_park", "traffic"])
	e.finale_patterns.assign(["vroom"])
	e.finale_line = "* Sansworth jumps in the van and turns the key.\n* It sputters. It doesn't start."
	e.taunts.assign(["VROOM!", "HONK HONK!", "Seatbelts!", "I got a car! I GOT A CAR!", "Left! No, other left!"])
	e.finale_taunts.assign(["Come on. Come on come on.", "Start. Please start.", "...vroom?"])
	e.flavor_lines.assign([
		"* Sansworth is trying a different key in the van.\n* It doesn't fit. None of them fit.",
		"* Sansworth is smiling. He's always smiling.",
		"* Behind you, Hop is staring at the van.\n* He's thinking about getting in.",
	])
	e.last_words = "* Sansworth: \"...Vroom?\""
	e.exp_reward = 120
	e.money_reward = 0
	e.bond_reward = 0
	data.enemies.append(e)
	return data
