extends RefCounted
## The Harbor (fragment 8).
##
## Flight Deck: an old jet on the carrier, with the fragment where its pilot used
## to sit. It hasn't flown in fifty years, and it wants to, very badly. A two-part
## fight: first it shows off (jet wash, afterburner, the catapult, a barrel roll,
## flares); from the fourth turn on, it's low on fuel and keeps trying to land.
## Spare it by guiding it in: "Guide It In" only works right after its landing
## approach (Enemy.last_pattern, an act's "when"). With the Corps, Agent calls every
## dodge (BattleData.announcer).
##
## On the Genocide path, Agent is waiting on the flight deck. The hardest fight in
## the game: he predicts where you're going and throws there.

const RELIC_LINES := [
	"* No.",
	"* He did the math. He saw this coming. He came anyway.",
	"* Check.",
]


static func create(id: String) -> BattleData:
	if id == "corps_agent":
		return _agent()
	return _flight_deck()


static func _flight_deck() -> BattleData:
	var data := BattleData.new()
	data.id = "flight_deck"
	data.music = "flight_deck"
	data.backdrop = Color(0.35, 0.45, 0.6)
	data.backdrop_style = "carrier"
	data.intro = ["* Flight Deck's engines scream to life.\n* It wants to FLY."]
	if Game.flags.get("route", "") == "pacifist":
		data.announcer = "Agent"
	var e := Enemy.new()
	e.name = "Flight Deck"
	e.max_hp = 400
	e.hp = 400
	e.attack = 6
	e.defense = 3
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/flight_deck.png")
	e.check_text = "* FLIGHT DECK - ATK 6 DEF 3\n* An old jet. It hasn't flown in fifty years.\n* It's never landed on a carrier. It always wanted to."
	e.patterns.assign(["jet_wash", "afterburner", "catapult", "barrel_roll", "flare_drop"])
	e.finale_patterns.assign(["landing_lights"])
	e.finale_turn = 4
	e.finale_at = 0.5
	e.finale_chance = 0.55
	e.finale_line = "* Flight Deck's fuel light is blinking.\n* It's coming around. It's trying to land."
	var wrong := "* {actor} waves it in.\n* It isn't trying to land. It does a loop instead."
	e.acts.assign([
		{"name": "Guide It In", "when": "landing_lights", "wrong": wrong, "mercy": 35, "lines": ["* {actor} waves the paddles, steady, slow.\n* Flight Deck comes in low. Lower. It's LISTENING."]},
		{"name": "Signal", "mercy": 15, "lines": ["* {actor} gives it a thumbs-up.\n* Flight Deck waggles its wings."]},
		{"name": "Clear the Deck", "mercy": 15, "lines": ["* {actor} clears a path down the deck.\n* Flight Deck's engines calm down a little."]},
	])
	e.taunts.assign(["VWOOOOOM", "*sonic boom*", "LOOK AT ME", "watch THIS", "...fuel low..."])
	e.spare_taunts.assign(["*touchdown*"])
	e.flavor_lines.assign([
		"* Flight Deck circles the carrier, showing off.",
		"* Flight Deck's canopy glows like an eye.",
		"* Somewhere, a museum alarm is going off.",
	])
	e.exp_reward = 100
	e.bond_reward = 45
	e.money_reward = 45
	data.enemies.append(e)
	return data


static func _agent() -> BattleData:
	var data := BattleData.new()
	data.id = "corps_agent"
	data.silent = true
	data.backdrop = Color(0.25, 0.5, 0.5)
	data.backdrop_style = "carrier"
	data.intro = ["* Agent puts his hands in his pockets.\n* \"I ran it a thousand times. Let's see.\""]
	data.locked_buttons.assign(["MERCY"])
	data.locked_lines.assign(RELIC_LINES)
	var e := Enemy.new()
	e.name = "Agent"
	e.max_hp = CorpsAttacks.boss_hp(260)
	e.hp = e.max_hp
	e.attack = 8
	e.defense = 3
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/agent.png")
	e.check_text = "* AGENT - ATK 8 DEF 3\n* Pure logic. He reads you like a Rock Paper Scissors\n  throw. He wanted Hop locked up. He was right."
	e.acts.assign([
		{"name": "Talk", "mercy": 0, "lines": ["* {actor} says nothing.\n* Agent: \"Predicted. Next.\""]},
		{"name": "Rock Paper Scissors", "mercy": 0, "lines": ["* {actor} holds up a fist.\n* Agent throws paper without looking. \"You always open with rock.\""]},
	])
	e.patterns.assign(["prediction", "counter_move", "rock_paper_scissors", "dart_volley", "bullseye_rings", "checkmate", "zugzwang"])
	e.finale_patterns.assign(["the_variable"])
	e.finale_line = "* Agent's hands are shaking.\n* \"This isn't in any of them. This isn't in ANY of them.\""
	e.taunts.assign(["Predicted.", "Left. Then up.", "You'll go there next.", "Checkmate in four.", "I counted."])
	e.flavor_lines.assign([
		"* Agent is already looking where you're about to go.",
		"* Agent mutters numbers. They're your next moves.",
		"* Agent hasn't blinked.",
	])
	e.last_words = "* Agent: \"I ran it a thousand times. You never did this\n*  in any of them.\"\n* Agent: \"...That's the one variable I'd change.\""
	e.bullet_speed = 120.0
	e.exp_reward = 140
	e.money_reward = 0
	e.bond_reward = 0
	data.enemies.append(e)
	return data
