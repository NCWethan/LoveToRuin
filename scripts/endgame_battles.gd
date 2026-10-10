extends RefCounted
## The last of the Corps, on the Genocide path.
##
## Eggo, on the couch in the bunker. He used the same attacks the day you met. Only
## FIGHT works; everything else is chained, like the glowbug. Before long, he stops
## defending himself at all (JUST TALK).
##
## MuffinMage, in the bunker kitchen. Calm, almost bored, salmon burger in hand.
## His face is never shown, not even now.
##
## Nassan, at the register at Vons. The last of them. Only FIGHT works. Before long
## he stops, and holds out his note, five pages, and waits for you to read it.

const LOCKED := ["ACT", "ITEM", "MERCY", "DEFEND"]


static func create(id: String) -> BattleData:
	match id:
		"hopkuna_unbound":
			return _unbound()
		"hopkuna_underdog":
			return _underdog()
		"corps_muffinmage":
			return _muffinmage()
		"corps_nassan":
			return _nassan()
	return _eggo()


static func _eggo() -> BattleData:
	var data := BattleData.new()
	data.id = "corps_eggo"
	data.silent = true
	data.backdrop = Color(0.9, 0.8, 0.4)
	data.backdrop_style = "static"
	data.intro = ["* Eggo doesn't get up off the couch.\n* \"Hey, Elric.\""]
	data.locked_buttons.assign(LOCKED)
	data.locked_lines.assign(["* No.", "* He's sitting down. Good.", "* FIGHT."])
	var e := Enemy.new()
	e.name = "Eggo"
	e.max_hp = CorpsAttacks.boss_hp(200)
	e.hp = e.max_hp
	e.attack = 6
	e.defense = 0
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/eggo.png")
	e.check_text = "* EGGO - ATK 6 DEF 0\n* Co-founder of Revolution. Always the first to forgive.\n* He fought you once, the day you met. He's tired."
	e.patterns.assign(["rain", "straw", "bullseye", "egg_drop", "bunny_hop", "hard_boiled", "toast", "sunny_side"])
	e.finale_patterns.assign(["just_talk"])
	e.finale_at = 0.6
	e.finale_chance = 1.0
	e.finale_line = "* Eggo stops. He puts his hands in his lap.\n* \"...I don't want to do this part.\""
	e.taunts.assign(["Remember this one?", "Egg-cellent dodge.", "Sorry. Sorry.", "This is how we met."])
	e.finale_taunts.assign(["...", "...you could also just talk to us.", "..."])
	e.flavor_lines.assign([
		"* Eggo's bunny, Toast, is hiding under the couch.",
		"* Eggo is using the same attacks as the day you met.\n* He isn't trying very hard.",
		"* Behind you, Hop is sitting on the stairs.",
	])
	e.last_words = "* Eggo: \"...you could also just talk to us.\"\n* Eggo: \"Welp. Guess I'm... over easy.\"\n* (It's a perfect pun. Nobody laughs.)\n* (Toast hops away into the hall, and is never seen again.)"
	e.exp_reward = 120
	e.money_reward = 0
	e.bond_reward = 0
	data.enemies.append(e)
	return data


static func _muffinmage() -> BattleData:
	var data := BattleData.new()
	data.id = "corps_muffinmage"
	data.silent = true
	data.backdrop = Color(0.7, 0.45, 0.3)
	data.backdrop_style = "dining"
	data.intro = ["* MuffinMage takes a bite of his salmon burger.\n* He doesn't put it down."]
	data.locked_buttons.assign(["MERCY"])
	data.locked_lines.assign(["* No.", "* He warned us.", "* Warnings are for people who listen."])
	var e := Enemy.new()
	e.name = "MuffinMage"
	e.max_hp = CorpsAttacks.boss_hp(260)
	e.hp = e.max_hp
	e.attack = 9
	e.defense = 3
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/muffinmage.png")
	e.check_text = "* MUFFINMAGE - ATK 9 DEF 3\n* The cook. Calm, almost bored.\n* He warned you about the fragment. On day one."
	e.acts.assign([
		{"name": "Talk", "mercy": 0, "lines": ["* {actor} says nothing.\n* MuffinMage chews. \"Mm.\""]},
		{"name": "The Burger", "mercy": 0, "lines": ["* {actor} looks at the salmon burger.\n* \"Want a bite? No? Your loss.\""]},
	])
	e.patterns.assign(["muffin_rain", "grill_flames", "spatula_flip", "salmon_leap", "sprinkles", "oven_timer", "magic_missile"])
	e.finale_patterns.assign(["the_warning"])
	e.finale_line = "* MuffinMage finishes the burger.\n* \"I warned you. On day one. I remember exactly.\""
	e.taunts.assign(["Mm.", "Order up.", "Too much salt.", "Eat something.", "..."])
	e.flavor_lines.assign([
		"* MuffinMage is cooking and fighting at the same time.\n* The food smells incredible.",
		"* MuffinMage hasn't raised his voice once.",
		"* You still can't see his face. You never will.",
	])
	e.last_words = "* MuffinMage: \"I warned you about the fragment.\"\n* MuffinMage: \"Should've warned you about yourself.\""
	e.exp_reward = 140
	e.money_reward = 0
	e.bond_reward = 0
	data.enemies.append(e)
	return data


static func _nassan() -> BattleData:
	var data := BattleData.new()
	data.id = "corps_nassan"
	data.silent = true
	data.backdrop = Color(0.45, 0.55, 0.85)
	data.backdrop_style = "grid"
	data.intro = ["* Nassan takes off his name tag and sets it on\n* the counter. \"Okay. Step one.\""]
	data.locked_buttons.assign(LOCKED)
	data.locked_lines.assign(["* No.", "* The last one.", "* FIGHT."])
	var e := Enemy.new()
	e.name = "Nassan"
	e.max_hp = CorpsAttacks.boss_hp(260)
	e.hp = e.max_hp
	e.attack = 8
	e.defense = 2
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/nassan.png")
	e.check_text = "* NASSAN - ATK 8 DEF 2\n* He had a plan for everything.\n* He didn't have one for this."
	e.patterns.assign(["step_one", "red_string", "five_pages", "circle_the_map", "contingency", "push_pins", "price_check"])
	e.finale_patterns.assign(["the_note"])
	e.finale_at = 0.5
	e.finale_chance = 1.0
	e.finale_line = "* Nassan stops. He holds out a note. Five pages.\n* \"Read it. Please. I'll wait.\""
	e.taunts.assign(["Step one.", "I planned for this.", "Plan B.", "Plan C.", "...Plan D."])
	e.finale_taunts.assign(["I'll wait.", "...", "Page three is the important one."])
	e.flavor_lines.assign([
		"* Nassan is still wearing his apron.",
		"* The register beeps. Nobody's buying anything.",
		"* Behind you, Hop has stopped walking. He's just standing in the aisle.",
	])
	e.last_words = "* Nassan: \"I told you not to carry it alone.\""
	e.exp_reward = 150
	e.money_reward = 0
	e.bond_reward = 0
	data.enemies.append(e)
	return data


## The last fight (Corps): Hopkuna, Unbound, with all twelve fragments. This one
## you can win, but not by fighting. Talk to Hop; every friend you call adds their
## voice. At the lowest point, BOND. Then: "Hop. Let go." (MERCY.)
static func _unbound() -> BattleData:
	var data := HilltopBattles.create("hopkuna")
	data.id = "hopkuna_unbound"
	data.party_only.clear()
	data.survive_turns = 0
	data.bond_reveal = true
	data.intro = ["* Hopkuna, Unbound.", "* All twelve of them, in a circle around you.\n* (Call them. Talk to Hop. Don't let go.)"]
	data.flavor = func(turn: int, enemies: Array[Enemy]) -> String:
		var e: Enemy = enemies[0]
		if e.can_spare():
			return "* Hop is right there, behind his eyes.\n* (MERCY. Say it. \"Hop. Let go.\")"
		if e.mercy >= 60:
			return "* Hopkuna's tattoos are flickering. Red. Green. Red."
		if turn == 1:
			return "* Hopkuna has all twelve fragments.\n* (You can't hurt him. Talk to Hop. Call your friends.)"
		return ["* Somewhere inside, Hop is listening.", "* \"Thirteen of us,\" Agent says. \"I did the math.\"", "* The grass is burning in a ring around the park."][turn % 3]
	var e: Enemy = data.enemies[0]
	e.name = "Hopkuna"
	e.attack = 9
	e.bullet_speed = 130.0
	e.patterns.assign(["cleave", "red_arrows", "slash_grid", "burst", "fire_arrow", "ember_rain", "cage", "twelve_tattoos", "everything"])
	e.spare_refusal = ""
	e.mercy_per_call = 8
	e.check_text = "* HOPKUNA, UNBOUND - ATK ??? DEF ???\n* All twelve fragments. Every scar glowing.\n* Hop is still in there. He can hear you."
	e.acts.assign([
		{"name": "Talk to Hop", "mercy": 9, "lines": [
			"* {actor} calls out Hop's name.\n* Hopkuna flinches. Just a little.",
			"* {actor} tells Hop about the curly fries.\n* Hopkuna: \"Stop that.\" His hand is shaking.",
			"* {actor} tells Hop it wasn't his fault.\n* Hopkuna's eyes flicker. Brown. Red. Brown.",
			"* {actor} tells Hop they're not going anywhere.\n* \"...Elric?\" (That was Hop.)",
		]},
		{"name": "Stand Together", "mercy": 5, "lines": ["* {actor} stands their ground.\n* Behind them, twelve people do the same."]},
	])
	e.taunts.assign(["Little wanderer.", "ALL of them!", "You're NOTHING!", "Hop can't hear you!", "I am WHOLE!"])
	e.spare_taunts.assign(["...Elric?"])
	return data


## The last fight (With Hop): Relic turns on Hopkuna, and he fights for his life.
## The underdog now. Desperate, furious, scared. His twelve tattoos burn, one by
## one, from red to green.
static func _underdog() -> BattleData:
	var data := HilltopBattles.create("hopkuna")
	data.id = "hopkuna_underdog"
	data.party_only.assign(["Elric"])
	data.survive_turns = 0
	data.music = "relic_slow"
	data.locked_buttons.assign(["MERCY"])
	data.locked_lines.assign(["* No.", "* He wanted us. Let him have us.", "* All of him. Now."])
	data.intro = ["* Relic reaches for Hopkuna.\n* For the first time in his life, Hopkuna is afraid."]
	data.flavor = func(turn: int, enemies: Array[Enemy]) -> String:
		var e: Enemy = enemies[0]
		var burned := clampi(12 - int(12.0 * e.hp / e.max_hp), 0, 12)
		if turn == 1:
			return "* Hopkuna is fighting for his life."
		return "* %d of his twelve tattoos have burned green." % burned
	var e: Enemy = data.enemies[0]
	e.name = "Hopkuna"
	e.max_hp = CorpsAttacks.boss_hp(500)
	e.hp = e.max_hp
	e.defense = 3
	e.attack = 10
	e.bullet_speed = 140.0
	e.hit_line = ""
	e.patterns.assign(["cleave", "red_arrows", "slash_grid", "burst", "fire_arrow", "ember_rain", "cage", "twelve_tattoos"])
	e.finale_patterns.assign(["last_stand"])
	e.finale_line = "* Hopkuna is screaming.\n* \"You were supposed to be MINE!\""
	e.check_text = "* HOPKUNA - ATK 10 DEF 3\n* The underdog now. He knows what you are.\n* He's the only one who ever did."
	e.acts.assign([{"name": "Look at Him", "mercy": 0, "lines": ["* {actor} looks at him.\n* Hopkuna: \"That isn't them. Relic would NEVER smile like that.\""]}])
	e.taunts.assign(["Get AWAY from me!", "You're not them!", "Hop, RUN!", "I won't go back in the dark!"])
	e.finale_taunts.assign(["Please.", "You were MY little wanderer.", "Not the dark. Not again."])
	e.last_words = "* Hopkuna: \"You were supposed to be MINE.\n*  You were MY little wanderer.\"\n* Relic: \"We were never anyone's.\""
	return data
