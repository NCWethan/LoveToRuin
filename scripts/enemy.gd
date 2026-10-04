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

## Attack style: "rain" (falls from the top) or "lance" (flies in from the sides).
var pattern: String
## Seconds between bullets.
var spawn_interval: float
## Bullet speed, in pixels per second.
var bullet_speed: float

## Short lines shown in a speech bubble during the enemy's turn.
var taunts: Array[String] = []
## Used instead of taunts once the enemy can be spared.
var spare_taunts: Array[String] = []

var exp_reward: int = 10
var bond_reward: int = 10

## "active", "spared" or "defeated".
var state: String = "active"
## Counts down after getting hit; the enemy shakes while it's above 0.
var shake: float = 0.0

var _act_counts: Dictionary = {}


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
