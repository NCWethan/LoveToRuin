extends RefCounted
## Mission Beach (fragment 4).
##
## The Dipper: the old wooden roller coaster on the boardwalk, running all night
## with nobody on it. Fragment 4 is in its front car. A guardian, like Wally:
## its own song, and you spare it by riding it properly (Hands Up on the drops,
## and a good scream).
##
## On the Genocide path, Crayola and N.C. Wethan are waiting on the beach, and
## they have to be killed (see STORY.md, "How the Corps dies"). They never fight
## to win. MERCY is chained shut, like with the glowbug.

const RELIC_LINES := [
	"* No.",
	"* We don't spare them. Not anymore.",
	"* They let us burn.",
]


static func create(id: String) -> BattleData:
	match id:
		"corps_crayola":
			return _corps(_crayola(), "* Crayola steps in front of you.\n* His hands are shaking. He holds up a card.")
		"corps_ncwethan":
			return _corps(_ncwethan(), "* N.C. Wethan stands where Crayola was.\n* He isn't yelling.")
	return _dipper()


static func _dipper() -> BattleData:
	var data := BattleData.new()
	data.id = "dipper"
	data.music = "dipper"
	data.backdrop = Color(0.75, 0.5, 0.3)
	data.backdrop_style = "waves"
	data.intro = ["* CLACK. CLACK. CLACK.\n* The Dipper rolls up to meet you!"]
	var e := Enemy.new()
	e.name = "The Dipper"
	e.max_hp = 320
	e.hp = 320
	e.attack = 5
	e.defense = 1
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/dipper.png")
	e.check_text = "* THE DIPPER - ATK 5 DEF 1\n* A wooden roller coaster from 1925.\n* It just wants someone to ride it."
	e.acts.assign([
		{"name": "Hands Up", "mercy": 34, "lines": ["* {actor} throws their hands up on the drop.\n* The Dipper rattles with joy."]},
		{"name": "Scream", "mercy": 33, "lines": ["* {actor} screams their head off.\n* The Dipper has missed this sound."]},
		{"name": "Hold On", "mercy": 0, "lines": ["* {actor} grips the lap bar.\n* ...The Dipper is a little disappointed."]},
	])
	e.patterns.assign(["coaster_cars", "the_drop", "loop_track"])
	e.taunts.assign(["CLACK CLACK CLACK", "WHEEEEE", "...DROP.", "Keep your hands inside! (Don't.)"])
	e.flavor_lines.assign([
		"* The Dipper climbs. CLACK. CLACK. CLACK.",
		"* The Dipper smells like salt and old popcorn.",
		"* Nobody has ridden the Dipper in a long time.",
		"* The front car glows red. Something is in it.",
	])
	e.spare_taunts.assign(["*happy clacking*"])
	e.bullet_speed = 110.0
	e.exp_reward = 60
	e.bond_reward = 30
	e.money_reward = 25
	data.enemies.append(e)
	return data


## A fight with someone from the Corps, on the Genocide path.
static func _corps(e: Enemy, intro: String) -> BattleData:
	var data := BattleData.new()
	data.id = "corps_" + e.name.to_lower().replace(".", "").replace(" ", "")
	data.music = ""
	data.silent = true
	data.backdrop = Color(0.3, 0.45, 0.6)
	data.backdrop_style = "waves"
	data.intro = [intro]
	data.locked_buttons.assign(["MERCY"])
	data.locked_lines.assign(RELIC_LINES)
	data.enemies.append(e)
	return data


static func _crayola() -> Enemy:
	var e := Enemy.new()
	e.name = "Crayola"
	e.max_hp = 60
	e.hp = 60
	e.attack = 3
	e.defense = 0
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/crayola.png")
	e.check_text = "* CRAYOLA - ATK 3 DEF 0\n* He swims with N.C. Wethan. He did a card trick\n  for you once. He remembers your card."
	e.acts.assign([
		{"name": "Talk", "mercy": 0, "lines": ["* {actor} says nothing.\n* Crayola: \"...You used to talk to me.\""]},
		{"name": "Pick a Card", "mercy": 0, "lines": ["* {actor} picks a card.\n* It's the Seven of Hearts. Every card is."]},
	])
	e.patterns.assign(["come_back"])
	e.taunts.assign(["...Elric?", "Come back.", "Please.", "It's still you. Right?"])
	e.flavor_lines.assign([
		"* Crayola is holding a deck of cards.\n* They're all the Seven of Hearts.",
		"* Crayola isn't looking at Relic. He's looking for Elric.",
		"* Behind you, Hop doesn't move.",
	])
	e.last_words = "* Crayola: \"...Was it this one?\n*  Your card?\""
	e.exp_reward = 30
	e.money_reward = 0
	e.bond_reward = 0
	return e


static func _ncwethan() -> Enemy:
	var e := Enemy.new()
	e.name = "N.C. Wethan"
	e.max_hp = 80
	e.hp = 80
	e.attack = 6
	e.defense = 1
	e.position = Vector2(470, 140)
	e.sprite = load("res://art/sprites/ncwethan.png")
	e.check_text = "* N.C. WETHAN - ATK 6 DEF 1\n* The loudest person you've ever met.\n* He's being very quiet."
	e.acts.assign([
		{"name": "Talk", "mercy": 0, "lines": ["* {actor} tries to say something.\n* N.C. Wethan: \"...Don't.\""]},
		{"name": "Checkers", "mercy": 0, "lines": ["* {actor} mentions checkers.\n* N.C. Wethan's lightning flickers out for a second."]},
	])
	e.patterns.assign(["near_miss"])
	e.taunts.assign(["...", "Why.", "He was my best friend.", "I'm not gonna hit you."])
	e.flavor_lines.assign([
		"* N.C. Wethan's lightning hits the sand. Not you.",
		"* N.C. Wethan isn't aiming at you. He never was.",
		"* Behind you, Hop has his eyes shut.",
	])
	e.last_words = "* N.C. Wethan: \"...KING ME?\"\n* (Quietly, for once.)"
	e.exp_reward = 40
	e.money_reward = 0
	e.bond_reward = 0
	return e
