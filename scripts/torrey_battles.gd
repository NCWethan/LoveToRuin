extends RefCounted
## Torrey Pines (fragment 9).
##
## The Glider: a hang glider with nobody in the harness, hanging over the cliffs
## for five years. It won't come down. The fight is in the open sky: the box drifts
## on the wind (BattleData.box_drift). Spare it by convincing it that coming down
## isn't the same as giving up. With the Corps, Rooster has to admit he's scared of
## heights to help ("once" ACT). When it runs out of wind, it tries to land (the
## finale, from the fifth turn).
##
## On the Genocide path, Rooster is at the gliderport. He roasts you through the
## whole fight; past halfway, the jokes fall apart (Enemy.finale_taunts).
##
## With the Corps, after the fragment: Hopkuna, stronger than he's ever been, a
## fight you can't win, only survive (like the field).

const RELIC_LINES := [
	"* No.",
	"* He roasted us once. We laughed.",
	"* That was Elric. Not us.",
]


static func create(id: String) -> BattleData:
	match id:
		"corps_rooster":
			return _rooster()
		"hopkuna_cliffs":
			return _hopkuna()
	return _glider()


static func _glider() -> BattleData:
	var data := BattleData.new()
	data.id = "glider"
	data.music = "glider"
	data.backdrop = Color(0.45, 0.6, 0.8)
	data.backdrop_style = "cliffs"
	data.box_drift = 26.0
	data.intro = ["* The Glider dips its wing at you.\n* The wind picks up. The box starts to drift."]
	var e := Enemy.new()
	e.name = "The Glider"
	e.max_hp = 420
	e.hp = 420
	e.attack = 6
	e.defense = 2
	e.position = Vector2(470, 130)
	e.sprite = load("res://art/sprites/glider.png")
	e.check_text = "* THE GLIDER - ATK 6 DEF 2\n* Nobody in the harness. It's been up here five years.\n* It's afraid that if it lands, that's the end."
	e.patterns.assign(["updraft", "thermal", "crosswind", "gull_escort", "dive", "pinecones"])
	e.finale_patterns.assign(["the_ground"])
	e.finale_turn = 5
	e.finale_chance = 0.5
	e.finale_line = "* The wind is dying down.\n* The Glider is dropping. It's terrified."
	var acts: Array = [
		{"name": "Talk It Down", "mercy": 20, "lines": ["* {actor} tells it the ground is right there.\n* The Glider wobbles. It doesn't believe it."]},
		{"name": "Coming Down", "mercy": 25, "lines": ["* {actor} says coming down isn't giving up.\n* \"...It isn't?\" The Glider drops, a little."]},
	]
	if Game.flags.get("route", "") == "pacifist":
		acts.append({"name": "Rooster", "once": true, "mercy": 45, "again": "* Rooster already said it.\n* He's still shaking.", "lines": [
			"* {actor} looks at Rooster.\n* Rooster: \"...Fine. FINE.\"",
			"* Rooster: \"I'm scared of heights. I've been scared\n*  the WHOLE time. I roast people so they don't notice.\"",
			"* Rooster: \"Coming down is the bravest thing I do.\n*  Every single time. ...Come down, man.\"",
		]})
	else:
		acts.append({"name": "Admit It", "once": true, "mercy": 40, "again": "* You already said it.", "lines": [
			"* {actor} says they're scared too.\n* Of stopping. Of landing somewhere and staying.",
			"* The Glider is very still in the wind.",
		]})
	e.acts.assign(acts)
	e.taunts.assign(["*whoosh*", "...higher...", "don't make me", "the ground is so FAR", "*creak*"])
	e.spare_taunts.assign(["...okay. okay."])
	e.flavor_lines.assign([
		"* The Glider hangs in the wind, perfectly still.",
		"* Far below, the ocean.",
		"* A seagull overtakes the Glider. It doesn't notice.",
	])
	e.exp_reward = 110
	e.bond_reward = 50
	e.money_reward = 45
	data.enemies.append(e)
	return data


static func _rooster() -> BattleData:
	var data := BattleData.new()
	data.id = "corps_rooster"
	data.silent = true
	data.backdrop = Color(0.6, 0.45, 0.4)
	data.backdrop_style = "cliffs"
	data.intro = ["* Rooster tips his hat.\n* \"Okay. Okay okay okay. Opening joke.\""]
	data.locked_buttons.assign(["MERCY"])
	data.locked_lines.assign(RELIC_LINES)
	var e := Enemy.new()
	e.name = "Rooster"
	e.max_hp = CorpsAttacks.boss_hp(240)
	e.hp = e.max_hp
	e.attack = 8
	e.defense = 2
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/rooster.png")
	e.check_text = "* ROOSTER - ATK 8 DEF 2\n* Roasts everyone because he's scared of everything.\n* He's very, very scared."
	e.acts.assign([
		{"name": "Roast Back", "mercy": 0, "lines": ["* {actor} tries to roast him back.\n* Rooster: \"...You used to be good at this.\""]},
		{"name": "Laugh", "mercy": 0, "lines": ["* {actor} doesn't laugh.\n* Rooster's next joke doesn't come out."]},
	])
	e.patterns.assign(["roast", "top_hat_trick", "mic_drop", "split_suit", "heckle", "callback", "tongue_out"])
	e.finale_patterns.assign(["not_a_joke"])
	e.finale_at = 0.5
	e.finale_line = "* Rooster opens his mouth for the next joke.\n* Nothing comes out."
	e.taunts.assign(["Nice eyes. Very evil. Ten out of ten.", "Is that a GLOW-UP?", "You call that a smile?", "Roast me. I DARE you.", "You look like a haunted pickle."])
	e.finale_taunts.assign(["Ha. Ha ha.", "...okay that one wasn't good.", "Say something. Please.", "I'm not funny right now.", "..."])
	e.flavor_lines.assign([
		"* Rooster is talking very fast.",
		"* Rooster's hands are shaking. He keeps them in his pockets.",
		"* Behind you, Hop is looking at the ground.",
	])
	e.last_words = "* Rooster: \"You were my favorite person to roast.\"\n* Rooster: \"You always roasted back.\"\n* (It isn't a joke.)"
	e.exp_reward = 130
	e.money_reward = 0
	e.bond_reward = 0
	data.enemies.append(e)
	return data


## Hopkuna, at the cliffs: stronger than he's been in five years. You can't win.
static func _hopkuna() -> BattleData:
	var data := HilltopBattles.create("hopkuna")
	data.id = "hopkuna_cliffs"
	data.party_only.clear()
	data.survive_turns = 4
	data.backdrop_style = "cliffs"
	data.backdrop = Color(0.85, 0.12, 0.2)
	data.intro = ["* Hopkuna attacks!", "* (He's stronger than at the field.\n*  Much, much stronger.)"]
	data.survive_lines = [
		"* (Hopkuna lowers his hand.)",
		"* (\"No. I don't need to finish you. I just need\n*  what's in your pockets.\")",
	]
	data.flavor = func(turn: int, _enemies: Array[Enemy]) -> String:
		match turn:
			1: return "* Hopkuna is wearing Hop's face. He's smiling.\n* (You can't win this. Just survive.)"
			2: return "* \"You've been breaking my things. Thank you.\""
			3: return "* Every fragment in your pocket is burning."
			_: return "* Somewhere inside, Hop is screaming your name."
	var e: Enemy = data.enemies[0]
	e.attack = 9
	e.bullet_speed = 130.0
	return data
