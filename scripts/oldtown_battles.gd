extends RefCounted
## Old Town (fragment 6).
##
## The Hostess: the ghost of Isabel, who set the table for twelve guests in 1874,
## and kept setting it, every night, for 150 years. Nobody came. Fragment 6 is in
## the candelabra in the middle of her table. She won't fight until you sit
## down, and her attacks are the courses: soup, the roast, dessert. Spare her by
## complimenting whatever's on the table (the right course, on the right turn).
##
## On the Genocide path, Nat waits at her door, and he has to die there. He reads
## your next move out loud, every turn, so you'll know he saw it coming.

const RELIC_LINES := [
	"* No.",
	"* He read about us. He never said our name.",
	"* Turn the page.",
]


static func create(id: String) -> BattleData:
	if id == "corps_nat":
		return _nat()
	return _hostess()


static func _hostess() -> BattleData:
	var data := BattleData.new()
	data.id = "hostess"
	data.music = "hostess"
	data.backdrop = Color(0.55, 0.4, 0.65)
	data.backdrop_style = "dining"
	data.intro = ["* The Hostess sets a bowl in front of you.\n* \"Dinner is SERVED!\""]
	data.flavor = func(turn: int, enemies: Array[Enemy]) -> String:
		var her: Enemy = enemies[0]
		if her.is_active() and her.can_spare():
			return "* The Hostess's name is YELLOW.\n* (She's happy. Pick MERCY, then SPARE her.)"
		match (turn - 1) % 3:
			0: return "* The Hostess ladles out the SOUP.\n* It's still hot. After 150 years."
			1: return "* The Hostess carves the ROAST.\n* She's very, very good with a knife."
			_: return "* The Hostess brings out DESSERT. A flan.\n* It wobbles."
	var e := Enemy.new()
	e.name = "The Hostess"
	e.max_hp = 340
	e.hp = 340
	e.attack = 5
	e.defense = 1
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/hostess.png")
	e.check_text = "* THE HOSTESS - ATK 5 DEF 1\n* She has set this table every night since 1874.\n* Nobody ever came. Until now."
	e.courses.assign(["soup", "roast", "dessert"])
	e.patterns.assign(["soup_waves", "carving_knives", "dessert_tray"])
	var wrong := "* {actor} compliments a dish that isn't on the table.\n* The Hostess looks confused. Then a little hurt."
	e.acts.assign([
		{"name": "Praise Soup", "course": "soup", "mercy": 34, "wrong": wrong, "lines": ["* {actor} tries the soup. It's actually amazing.\n* The Hostess clasps her hands. \"MORE?\""]},
		{"name": "Praise Roast", "course": "roast", "mercy": 33, "wrong": wrong, "lines": ["* {actor} says the roast is perfect.\n* The Hostess puts down the knife. She's glowing."]},
		{"name": "Praise Dessert", "course": "dessert", "mercy": 33, "wrong": wrong, "lines": ["* {actor} asks for seconds of the flan.\n* The Hostess laughs. It sounds like a bell."]},
		{"name": "Ask Her Name", "mercy": 0, "lines": ["* {actor} asks her name.\n* \"...Isabel.\" Nobody has asked in 150 years."]},
	])
	e.taunts.assign(["Eat, eat!", "You're too thin.", "Guests! At LAST!", "Is it good? Tell me it's good.", "Elbows OFF the table."])
	e.spare_taunts.assign(["Thank you for coming."])
	e.flavor_lines.assign(["* The candles flicker."])
	e.bullet_speed = 100.0
	e.exp_reward = 80
	e.bond_reward = 35
	e.money_reward = 35
	data.enemies.append(e)
	return data


static func _nat() -> BattleData:
	var data := BattleData.new()
	data.id = "corps_nat"
	data.silent = true
	data.backdrop = Color(0.45, 0.35, 0.6)
	data.backdrop_style = "plaza"
	data.intro = ["* Nat closes his book and stands up.\n* \"I read ahead. I know how this goes.\""]
	data.locked_buttons.assign(["MERCY"])
	data.locked_lines.assign(RELIC_LINES)
	# Hop won't fight Nat. He just watches.
	data.party_only.assign(["Elric"])
	data.watcher = "Hop"
	var e := Enemy.new()
	e.name = "Nat"
	e.max_hp = 70
	e.hp = 70
	e.attack = 5
	e.defense = 1
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/nat.png")
	e.check_text = "* NAT - ATK 5 DEF 1\n* Knows too much history to get attached to anything.\n* Got attached anyway. To all of you."
	e.acts.assign([
		{"name": "Talk", "mercy": 0, "lines": ["* {actor} says nothing.\n* Nat: \"...I know. I read ahead.\""]},
		{"name": "The Page", "mercy": 0, "lines": ["* {actor} mentions the torn page.\n* Nat: \"Hop tore it. I never told him I knew.\""]},
	])
	e.patterns.assign(["chapter_break", "dog_ear"])
	e.taunts.assign(["Page 211: you swing.", "Page 212: you swing again.", "Page 212. Still you.", "I read ahead."])
	e.flavor_lines.assign([
		"* Nat turns a page. He's reading your next move.",
		"* Nat isn't dodging. He knows where you'll hit.",
		"* Behind you, Hop has stopped walking.",
	])
	e.last_words = "* Nat: \"Page 213. The last page.\"\n* Nat: \"...I always wanted to know how it ended.\""
	e.exp_reward = 45
	e.money_reward = 0
	e.bond_reward = 0
	data.enemies.append(e)
	return data
