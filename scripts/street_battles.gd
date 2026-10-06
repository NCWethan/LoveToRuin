extends RefCounted
## On the way to Hop's house, after going with him from Westview Field.
##
## The glowbug: a tiny, lost, glowing bug that can't fight back. It's the fight that
## starts the Genocide route. No music. Hop stands behind Elric, worried, and never
## gets a turn. MERCY, ACT, ITEM and DEFEND are chained shut; trying them, a voice
## in green (Relic) says no. The only way out is to FIGHT it. (Killing it sets the
## route: see Game.finish_battle.)

const RELIC_LINES := [
	"* No.",
	"* That isn't for us.",
	"* Kill it.",
	"* Why are you waiting? It's so small.",
	"* It won't even notice. Kill it.",
	"* We don't have all night.",
]


static func create(id: String) -> BattleData:
	var data := BattleData.new()
	data.id = id
	data.enemies.append(_glowbug())
	data.backdrop_style = "stars"
	data.backdrop = Color(0.45, 0.42, 0.25)
	data.aura = Color(1.0, 0.85, 0.35, 0.0)
	data.intro = ["* A little glowbug blinks at you."]
	data.party_only.assign(["Elric"])
	data.watcher = "Hop"
	data.silent = true
	data.locked_buttons.assign(["ACT", "ITEM", "MERCY", "DEFEND"])
	data.locked_lines.assign(RELIC_LINES)
	return data


static func _glowbug() -> Enemy:
	var e := Enemy.new()
	e.name = "Glowbug"
	e.max_hp = 5
	e.hp = 5
	e.attack = 0
	e.defense = 0
	e.position = Vector2(470, 150)
	e.sprite = load("res://art/sprites/glowbug.png")
	e.check_text = "* GLOWBUG - ATK 0 DEF 0\n* Lost. Looking for its family.\n* It can't fight back."
	e.patterns.assign(["tremble"])
	e.taunts.assign(["...", "(blink)", "(blink... blink...)"])
	e.flavor_lines.assign([
		"* The glowbug's light flickers.",
		"* It's looking for its family.",
		"* It isn't going to hurt you.",
		"* Behind you, Hop doesn't move.",
	])
	e.exp_reward = 10
	e.bond_reward = 0
	e.money_reward = 0
	return e
