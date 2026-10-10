extends RefCounted
## The burned hills (fragment 10).
##
## Ember: the fire's leftover heart. Pure fire, the same fire. The hardest
## guardian. Hits don't hurt it; they feed it (Enemy.feeds_on_hits). Spare it by
## letting it burn out: survive, and don't feed it. Every turn it isn't hit, it
## burns a little lower (Enemy.burnout_mercy). Ronin, who knows what fire does,
## learns to hold his flame still instead of throwing it ("once" ACT).
##
## On the Genocide path Ember doesn't fight. It's Relic's fire, recognizing them.
## Ronin is waiting at the top, with his guitar. He plays his POWER RIFF, the last
## time, and the battle music doesn't step aside for it. He doesn't finish it.

const RELIC_LINES := [
	"* No.",
	"* He made fire into music. We made it into this.",
	"* Let it ring.",
]


static func create(id: String) -> BattleData:
	if id == "corps_ronin":
		return _ronin()
	return _ember()


static func _ember() -> BattleData:
	var data := BattleData.new()
	data.id = "ember"
	data.music = "ember"
	data.backdrop = Color(0.75, 0.25, 0.1)
	data.backdrop_style = "shards"
	data.aura = Color(1.0, 0.45, 0.1, 0.0)
	data.intro = ["* Ember flares up, as tall as a house.\n* It's the same fire. You'd know it anywhere."]
	data.flavor = func(turn: int, enemies: Array[Enemy]) -> String:
		var e: Enemy = enemies[0]
		if e.can_spare():
			return "* Ember is just a coal now, glowing in the ash.\n* (Its name is YELLOW. SPARE it.)"
		if turn == 1:
			return "* (Hitting it only feeds it. Survive.\n*  Let it burn out.)"
		if e.mercy >= 60:
			return "* Ember is burning low. Smaller. Quieter."
		return ["* Ember crackles. It sounds like laughing.", "* The ash around you is still warm.\n* Five years, and it's still warm.", "* Ember reaches for the dry grass. There isn't any."][turn % 3]
	var e := Enemy.new()
	e.name = "Ember"
	e.max_hp = 500
	e.hp = 500
	e.attack = 7
	e.defense = 0
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/ember.png")
	e.check_text = "* EMBER - ATK 7 DEF ???\n* What's left of the fire. It still wants to burn.\n* Feed it, and it grows. Don't, and it can't."
	e.feeds_on_hits = true
	e.burnout_mercy = 15
	e.patterns.assign(["wildfire", "spark_burst", "smoke_screen", "firestorm", "heat_shimmer", "the_tent", "ash_fall"])
	e.finale_patterns.assign(["burning_out"])
	e.finale_turn = 7
	e.finale_chance = 0.6
	e.finale_line = "* Ember is guttering. It's running out of\n* everything it had."
	var acts: Array = [
		{"name": "Hold Still", "mercy": 10, "lines": ["* {actor} holds very still.\n* Ember has nothing to catch on to."]},
		{"name": "Smother", "mercy": 5, "lines": ["* {actor} kicks ash over the edges.\n* Ember hisses. It shrinks, a little."]},
	]
	var route: String = Game.flags.get("route", "")
	if route in ["pacifist", "neutral"]:
		acts.append({"name": "Ronin", "once": true, "mercy": 30, "again": "* Ronin's still holding it.\n* His hands are shaking. He doesn't let go.", "lines": [
			"* {actor} looks at Ronin.\n* Ronin: \"...I know what you are. I've got some of you in me.\"",
			"* Ronin lights a flame in his palm.\n* He doesn't throw it. He just holds it. Still.",
			"* Ember stares at it for a long time.\n* Then it burns lower.",
		]})
	e.acts.assign(acts)
	e.taunts.assign(["*crackle*", "MORE", "feed me", "it was SO bright", "...", "remember?"])
	e.spare_taunts.assign(["...", "*hiss*"])
	e.flavor_lines.assign(["* Ember crackles."])
	e.bullet_speed = 110.0
	e.exp_reward = 140
	e.bond_reward = 60
	e.money_reward = 0
	data.enemies.append(e)
	return data


static func _ronin() -> BattleData:
	var data := BattleData.new()
	data.id = "corps_ronin"
	# (The battle music doesn't step aside for his riff. Not this time.)
	data.music = "relic_slow"
	data.backdrop = Color(0.6, 0.15, 0.15)
	data.backdrop_style = "shards"
	data.intro = ["* Ronin plugs in. He doesn't say anything.\n* He starts to play."]
	data.locked_buttons.assign(["MERCY"])
	data.locked_lines.assign(RELIC_LINES)
	var e := Enemy.new()
	e.name = "Ronin"
	e.max_hp = CorpsAttacks.boss_hp(250)
	e.hp = e.max_hp
	e.attack = 8
	e.defense = 3
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/ronin.png")
	e.check_text = "* RONIN - ATK 8 DEF 3\n* He's playing his POWER RIFF. The whole thing.\n* He's never once finished it."
	e.acts.assign([
		{"name": "Listen", "mercy": 0, "lines": ["* {actor} listens.\n* It's the best he's ever played it."]},
		{"name": "Checkers", "mercy": 0, "lines": ["* {actor} thinks about the checkers game.\n* Red was winning. Red was always winning."]},
	])
	e.patterns.assign(["power_chord", "flame_solo", "feedback", "pick_slide", "stage_dive", "encore", "riff_loop"])
	e.finale_patterns.assign(["held_note"])
	e.finale_line = "* Ronin hits the last note of the riff and holds it.\n* He holds it. He holds it."
	e.taunts.assign(["...", "...", "*riff*", "*riff*", "..."])
	e.finale_taunts.assign(["...", "...", "..."])
	e.flavor_lines.assign([
		"* Ronin's fingers are bleeding. He doesn't stop.",
		"* The riff fills the whole hillside.",
		"* Behind you, Hop knows every note of this. He mouths them.",
	])
	e.last_words = "* (Ronin doesn't say anything.)\n* (The note he was holding rings out over the hills\n*  after him, for a long, long time.)"
	e.exp_reward = 130
	e.money_reward = 0
	e.bond_reward = 0
	data.enemies.append(e)
	return data
