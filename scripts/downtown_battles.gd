extends RefCounted
## Downtown (fragment 7).
##
## The Big Screen: the ballpark's scoreboard, which has been playing to an empty
## stadium since the fragment got into it. It replays your own last turn and
## fires it back at you (INSTANT REPLAY). Spare it by giving it a crowd: do the
## wave, cheer, wave at yourself on the Kiss Cam. With the Corps, Supreme reads
## its next attack out loud every turn (BattleData.announcer).
##
## On the Genocide path, Supreme waits at home plate, and he has to die there. A
## bullet-hell made of statistics: every attack is labeled with its odds of
## hitting you.

const RELIC_LINES := [
	"* No.",
	"* He did the math on us. He stayed anyway. Bad math.",
	"* Round down.",
]


static func create(id: String) -> BattleData:
	if id == "corps_supreme":
		return _supreme()
	return _big_screen()


static func _big_screen() -> BattleData:
	var data := BattleData.new()
	data.id = "big_screen"
	data.music = "big_screen"
	data.backdrop = Color(0.3, 0.5, 0.35)
	data.backdrop_style = "stadium"
	data.intro = ["* The Big Screen flickers on.\n* PLAYER ONE: YOU. PLAY BALL!"]
	if Game.flags.get("route", "") == "pacifist":
		data.announcer = "Supreme"
	var e := Enemy.new()
	e.name = "The Big Screen"
	e.max_hp = 380
	e.hp = 380
	e.attack = 6
	e.defense = 2
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/big_screen.png")
	e.check_text = "* THE BIG SCREEN - ATK 6 DEF 2\n* The ballpark's scoreboard. It's been playing to\n  an empty stadium for five years. It's so lonely."
	e.patterns.assign(["instant_replay", "kiss_cam", "the_wave", "foul_ball", "fireworks", "scoreboard"])
	e.finale_patterns.assign(["instant_replay"])
	e.finale_line = "* The Big Screen shows the whole fight again.\n* It's mostly you, dodging. It's kind of a highlight reel."
	e.bores_easily = true
	e.acts.assign([
		{"name": "Do the Wave", "mercy": 40, "lines": ["* {actor} does the wave, alone, in an empty stadium.\n* The Big Screen flashes: THE WAVE!! THE WAVE!!"]},
		{"name": "Cheer", "mercy": 30, "lines": ["* {actor} cheers as loud as they can.\n* The Big Screen's NOISE METER goes all the way up."]},
		{"name": "Kiss Cam", "mercy": 30, "lines": ["* {actor} waves at themself on the Kiss Cam.\n* The Big Screen draws a heart around them. Twice."]},
	])
	e.taunts.assign(["CHARGE!", "MAKE SOME NOISE!", "REPLAY!", "DO THE WAVE!", "HOME TEAM: 0", "IS ANYONE THERE?"])
	e.spare_taunts.assign(["THANK YOU, [CROWD]!"])
	e.flavor_lines.assign([
		"* The Big Screen shows an empty stadium.\n* It's this one.",
		"* The Big Screen's NOISE METER reads 0.",
		"* The Big Screen plays a sad organ chord.",
	])
	e.bullet_speed = 100.0
	e.exp_reward = 90
	e.bond_reward = 40
	e.money_reward = 40
	data.enemies.append(e)
	return data


static func _supreme() -> BattleData:
	var data := BattleData.new()
	data.id = "corps_supreme"
	data.silent = true
	data.backdrop = Color(0.4, 0.3, 0.6)
	data.backdrop_style = "stadium"
	data.intro = ["* Supreme pushes up his visor.\n* \"I ran the numbers. Want to hear them?\""]
	data.locked_buttons.assign(["MERCY"])
	data.locked_lines.assign(RELIC_LINES)
	var e := Enemy.new()
	e.name = "Supreme"
	e.max_hp = CorpsAttacks.boss_hp(220)
	e.hp = e.max_hp
	e.attack = 7
	e.defense = 2
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/supreme.png")
	e.check_text = "* SUPREME - ATK 7 DEF 2\n* Lives by the numbers. Stays when the numbers say go.\n* The numbers are saying go."
	e.acts.assign([
		{"name": "Talk", "mercy": 0, "lines": ["* {actor} says nothing.\n* Supreme: \"Silence. 91% of the time, that means guilt.\""]},
		{"name": "Ask the Odds", "mercy": 0, "lines": ["* {actor} asks the odds.\n* Supreme: \"Of you stopping? I keep it above zero.\""]},
	])
	e.patterns.assign(["bell_curve", "standard_deviation", "pie_chart", "bar_graph", "scatter_plot", "regression_line", "margin_of_error"])
	e.finale_patterns.assign(["zero_point_four"])
	e.finale_line = "* Supreme closes his laptop.\n* \"I ran it again. 0.4%. ...I stayed anyway.\""
	e.odds.merge(DowntownAttacks.ODDS)
	e.taunts.assign(["Statistically...", "Recalculating.", "That's an outlier.", "You're an outlier."])
	e.flavor_lines.assign([
		"* Supreme is muttering numbers. They keep going down.",
		"* Supreme labels every attack with its odds.\n* He's usually right.",
		"* Supreme's purple eye is wet. He'd say it's allergies.\n* The odds of that are low.",
	])
	e.last_words = "* Supreme: \"I kept the odds you'd stop above zero.\"\n* Supreme: \"...I rounded up.\""
	e.exp_reward = 100
	e.money_reward = 0
	e.bond_reward = 0
	data.enemies.append(e)
	return data
