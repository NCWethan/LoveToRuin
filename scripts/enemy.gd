class_name Enemy
extends RefCounted
## One enemy in a battle: its stats, its ACT options, and how it attacks.

var name: String
var max_hp: int
var hp: int
## How much HP each of this enemy's bullets takes.
var attack: int
## Subtracted from the damage this enemy takes from FIGHT.
var defense: int
## Where the enemy stands on the battle screen.
var position: Vector2
## The enemy's picture. Drawn at 3x size, standing on `position`.
var sprite: Texture2D
## Placeholder colors, only used if there's no sprite.
var head_color: Color
var body_color: Color

## 0 to 100. At 100 the enemy's name turns yellow and it can be SPARED.
var mercy: int = 0
## What CHECK says about this enemy.
var check_text: String
## ACT options (besides Check). Each one is a Dictionary:
##   "name":  the option's name in the menu
##   "mercy": how much mercy it adds
##   "lines": what happens; the 1st use shows line 1, the 2nd use line 2, and so on.
##            "{actor}" is replaced by whoever is acting.
var acts: Array[Dictionary] = []

## The attacks this enemy knows (see attacks.gd). Each turn it picks one at random.
var patterns: Array[String] = []
## Speed for its simple bullets, in pixels per second.
var bullet_speed: float = 100.0

## If set, MERCY doesn't work on this enemy and this is shown instead.
var spare_refusal: String = ""
## If set, shown after every FIGHT hit (e.g. "It barely leaves a mark.").
var hit_line: String = ""
## What they say as they die (shown before they shatter). Mostly for the Corps.
var last_words: String = ""
## Courses (the Hostess): the enemy serves its patterns in order, one per turn
## (patterns[i] is courses[i]), and an ACT with a "course" only works on the turn
## that course is on the table. `course` is the one on the table now.
var courses: Array[String] = []
## Bosses (the Corps): attacks they only start using once they're nearly beaten
## (under a third of their HP), and what's said the first time they do.
var finale_patterns: Array[String] = []
var finale_line: String = ""
var finale_started: bool = false
var finale_announced: bool = false
## When the finale starts: under this much of their HP (a third, usually), or (if
## above 0) from this turn on, whichever comes first. And how often it comes up.
var finale_at: float = 1.0 / 3.0
var finale_turn: int = 0
var finale_chance: float = 0.4
## The attack they just used (some ACTs only work right after a certain one: see
## an act's "when").
var last_pattern: String = ""
## What they say once the finale starts (Rooster: the jokes fall apart).
var finale_taunts: Array[String] = []
## ACTs marked "once" that have been used (they don't work twice).
var _used_once: Array = []
## Ember: hits don't hurt it, they FEED it (it heals what it would have lost).
var feeds_on_hits: bool = false
## Ember: every turn it isn't hit, it burns a little lower (this much MERCY).
var burnout_mercy: int = 0
## (Was it hit since the last player turn? For burnout_mercy.)
var hit_this_round: bool = false
## The last fight: every friend called in adds their voice (this much MERCY).
var mercy_per_call: int = 0
## Supreme labels his own attacks with their odds of hitting you: pattern -> %.
var odds: Dictionary = {}
var course: int = 0
## How many turns this enemy has attacked so far (some attacks speed up over time).
var fury: int = 0

## Lines that can appear in the text box at the start of the player's turn.
var flavor_lines: Array[String] = []

## How many times bigger the sprite is drawn in battle (bosses can be bigger).
var battle_scale: float = 3.0
## Bounces to the beat, sways, and spins now and then (Wally's halftime show).
var dance: bool = false

## Short lines shown in a speech bubble during the enemy's turn.
var taunts: Array[String] = []
## Used instead of taunts once the enemy can be spared.
var spare_taunts: Array[String] = []

## If true, doing the same ACT twice in a row (even by different party members)
## does nothing; the enemy wants variety. Makes sparing a challenge.
var bores_easily: bool = false
## What it says when that happens.
var bored_line: String = "* {name} has seen that already.\n* (Try something different.)"

var exp_reward: int = 10
var bond_reward: int = 10
var money_reward: int = 15

## "active", "spared" or "defeated".
var state: String = "active"
## Counts down after getting hit; the enemy shakes while it's above 0.
var shake: float = 0.0
## Counts down after getting hit; the enemy flashes white while it's above 0.
var flash: float = 0.0
## The HP the health bar shows. It drains toward `hp` smoothly after a hit.
var shown_hp: float = -1.0
## Seconds since this enemy was knocked out (-1 if it hasn't been), for its KO animation.
var ko_time: float = -1.0
## Killed for real (not the tutorial, the training dummy or a boss): instead of
## falling over, they crack into green pieces and the wind carries them away.
var shattered: bool = false

## How this enemy reacts if a partner is knocked out, by the partner's name:
##   {"BigJoe6": {"line": "...", "mood": "sad", "taunts": [...], "attack": 1}}
## "mood" changes their face for the rest of the fight (from art/portraits/),
## "taunts" replaces what they say, "attack" is added to their attack.
var partner_reactions: Dictionary = {}
## Their current expression in battle ("" = normal).
var mood: String = ""
## Status effects on it: {name: turns left} (see effects.gd).
var statuses: Dictionary = {}

var _act_counts: Dictionary = {}
var _last_act: String = ""


## Has their finale started? (See finale_at, finale_turn.)
func in_finale() -> bool:
	if finale_patterns.is_empty():
		return false
	return hp < max_hp * finale_at or (finale_turn > 0 and fury >= finale_turn - 1)


func is_active() -> bool:
	return state == "active"


func can_spare() -> bool:
	return mercy >= 100


## The names shown in this enemy's ACT menu.
func act_names() -> Array[String]:
	var names: Array[String] = ["Check"]
	for act in acts:
		names.append(act["name"])
	return names


## Performs ACT option number `index` (0 is Check) and returns the text to show.
func do_act(index: int, actor: String) -> Array[String]:
	if index == 0:
		return [check_text]

	var act: Dictionary = acts[index - 1]
	# Some ACTs only work once (Rooster admitting he's scared of heights).
	if act.get("once", false):
		if act["name"] in _used_once:
			return [str(act.get("again", "* It already did all it could.")).format({"name": name, "actor": actor})]
		_used_once.append(act["name"])
	# Some ACTs only work right after a certain attack (Flight Deck: guide it in
	# right after its landing approach).
	if act.has("when") and act["when"] != last_pattern:
		return [str(act.get("wrong", "* Not now.")).format({"name": name, "actor": actor})]
	# Only the course that's on the table can be complimented.
	if act.has("course") and not courses.is_empty() and act["course"] != courses[course % courses.size()]:
		return [str(act.get("wrong", "* That isn't what's on the table.")).format({"name": name, "actor": actor})]
	if bores_easily and act["name"] == _last_act:
		return [bored_line.format({"name": name, "actor": actor})]
	_last_act = act["name"]
	var times_used: int = _act_counts.get(act["name"], 0)
	_act_counts[act["name"]] = times_used + 1

	var lines: Array = act["lines"]
	var text: String = lines[mini(times_used, lines.size() - 1)]
	var result: Array[String] = [text.format({"actor": actor})]

	var could_spare_before := can_spare()
	mercy = mini(mercy + int(act["mercy"]), 100)
	if can_spare() and not could_spare_before:
		result.append("* %s's name turned YELLOW!\n* %s can be SPARED now." % [name, name])
	return result


## A random line for the speech bubble.
func taunt() -> String:
	var options := spare_taunts if can_spare() and not spare_taunts.is_empty() else taunts
	return options.pick_random() if not options.is_empty() else ""
