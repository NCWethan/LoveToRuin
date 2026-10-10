extends RefCounted
## Balboa Park (fragment 5).
##
## The Empty Knight: a suit of armor from the museum's arms and armor exhibit,
## walking around on its own. Fragment 5 is inside its breastplate. All it has
## ever wanted is a worthy opponent. Spare it by fighting fair: salute it, keep
## it a fair fight, and offer a hand when it falls.
##
## Big Joe: on the own-way path he challenges Elric to a duel for the fragment
## (by the rules, and it can be spared). On the Genocide path he dies here,
## fighting fair to the end (see STORY.md, "How the Corps dies").

const RELIC_LINES := [
	"* No.",
	"* Justice. Ha.",
	"* He let us burn too.",
]


static func create(id: String) -> BattleData:
	match id:
		"duel_bigjoe":
			return _duel(false)
		"corps_bigjoe":
			return _duel(true)
	return _knight()


static func _knight() -> BattleData:
	var data := BattleData.new()
	data.id = "knight"
	data.music = "knight"
	data.backdrop = Color(0.55, 0.55, 0.65)
	data.backdrop_style = "banners"
	data.intro = ["* The Empty Knight raises its sword.\n* Its visor is empty. Something red glows inside."]
	var e := Enemy.new()
	e.name = "The Empty Knight"
	e.max_hp = 360
	e.hp = 360
	e.attack = 6
	e.defense = 3
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/empty_knight.png")
	e.check_text = "* THE EMPTY KNIGHT - ATK 6 DEF 3\n* A suit of armor from 1540. Nobody has ever\n  been inside it. It only wants a worthy opponent."
	e.acts.assign([
		{"name": "Salute", "mercy": 30, "lines": ["* {actor} salutes the Knight.\n* It stops. Then, slowly, it salutes back."]},
		{"name": "Fair Fight", "mercy": 30, "lines": ["* {actor} lowers their guard and waits for it\n  to get ready. The Knight's visor brightens."]},
		{"name": "Offer a Hand", "mercy": 40, "lines": ["* {actor} offers the Knight a hand.\n* For 480 years, nobody has done that."]},
	])
	e.patterns.assign(["sword_sweep", "armor_rain", "shield_charge"])
	e.taunts.assign(["En garde.", "...", "Again.", "Worthy."])
	e.flavor_lines.assign([
		"* The Empty Knight clanks into a ready stance.",
		"* Its armor is polished. Someone takes care of it.",
		"* There's a little plaque on its boot: PLEASE DO NOT TOUCH.",
		"* The breastplate glows red. Something is inside.",
	])
	e.spare_taunts.assign(["*bows*"])
	e.bullet_speed = 110.0
	e.exp_reward = 70
	e.bond_reward = 30
	e.money_reward = 30
	data.enemies.append(e)
	return data


## Big Joe, in his helmet, with his lance and his shield.
static func _duel(genocide: bool) -> BattleData:
	var data := BattleData.new()
	data.id = "corps_bigjoe" if genocide else "duel_bigjoe"
	data.backdrop = Color(0.6, 0.2, 0.2)
	data.backdrop_style = "banners"
	var e := Enemy.new()
	e.name = "Big Joe"
	e.max_hp = 230 if genocide else 200
	e.hp = e.max_hp
	e.attack = 7 if genocide else 6
	e.defense = 2
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/bigjoe6.png")
	e.patterns.assign(["lance", "sweep", "aimed", "joust", "shield_press", "rulebook", "salute", "helmet_bash"])
	e.finale_patterns.assign(["justice_for_all"])
	e.finale_line = "* Big Joe raises his lance to the sky.\n* \"JUSTICE! FOR! ALL!\""
	if genocide:
		data.silent = true
		data.intro = ["* Big Joe plants his feet.\n* \"By the rules. One on one. ...Leave Hop out of this.\""]
		data.locked_buttons.assign(["MERCY"])
		data.locked_lines.assign(RELIC_LINES)
		e.check_text = "* BIG JOE - ATK 7 DEF 2\n* Co-founder of Revolution. Justice and truth.\n* He's fighting fair. He's the only one who is."
		e.acts.assign([
			{"name": "Tell the Truth", "mercy": 0, "lines": ["* {actor} tells Big Joe the truth.\n* He believes it. That's the worst part."]},
			{"name": "Salute", "mercy": 0, "lines": ["* {actor} salutes.\n* Big Joe salutes back. He doesn't know why."]},
		])
		e.taunts.assign(["By the rules.", "Get up. I'll wait.", "Justice...", "I'm not hitting you while you're down."])
		e.flavor_lines.assign([
			"* Big Joe waits for you to get ready. Every time.",
			"* Big Joe's lance never comes from behind.",
			"* Behind you, Hop says something. You don't hear it.",
		])
		e.last_words = "* Big Joe: \"Justice was supposed to...\"\n* Big Joe: \"...Tell Eggo I'm sorry I was loud.\""
		e.exp_reward = 100
		e.money_reward = 0
		e.bond_reward = 0
	else:
		data.music = "eggo_joe"
		data.intro = ["* Big Joe raises his lance.\n* \"A duel! By the rules! Winner takes the fragment!\""]
		e.check_text = "* BIG JOE - ATK 6 DEF 2\n* Justice and truth. He wants this to be fair.\n* He wants you to come back, too. He won't say it."
		e.acts.assign([
			{"name": "Tell the Truth", "mercy": 40, "lines": ["* {actor} tells Big Joe why they walked away.\n* He listens. All of it."]},
			{"name": "Salute", "mercy": 30, "lines": ["* {actor} salutes.\n* Big Joe salutes back, very seriously."]},
			{"name": "Fair Fight", "mercy": 30, "lines": ["* {actor} waits for Big Joe to get ready.\n* \"...HONORABLE. I respect that.\""]},
		])
		e.taunts.assign(["BY THE RULES!", "JUSTICE!", "Fight fair!", "...Come back, okay?"])
		e.flavor_lines.assign([
			"* Big Joe is having the time of his life.",
			"* Big Joe announces each attack before he does it.",
		])
		e.spare_taunts.assign(["...Fine. FINE. You win."])
		e.exp_reward = 60
		e.bond_reward = 40
		e.money_reward = 20
	data.enemies.append(e)
	return data
