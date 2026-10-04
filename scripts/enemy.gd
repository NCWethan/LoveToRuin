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
## How many turns this enemy has attacked so far (some attacks speed up over time).
var fury: int = 0

## Lines that can appear in the text box at the start of the player's turn.
var flavor_lines: Array[String] = []

## How many times bigger the sprite is drawn in battle (bosses can be bigger).
var battle_scale: float = 3.0

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

var _act_counts: Dictionary = {}
var _last_act: String = ""


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
