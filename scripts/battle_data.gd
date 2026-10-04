class_name BattleData
extends RefCounted
## Everything that makes one battle different from another: who you fight,
## what's said at the start, and the text at the start of each of your turns.
## Battles are looked up by name in Battles.create().

var id: String
var enemies: Array[Enemy] = []
## Lines shown before the fight starts.
var intro: Array = []
## True: the player acts first (most fights). False: the enemies attack first.
var player_first: bool = true
## Optional. Called as flavor.call(turn, enemies) -> String for the text at the start
## of each player turn. If not set, a line from one of the enemies is used.
var flavor: Callable
## Optional. Called as attackers.call(enemy_turn, enemies) -> Array[Enemy] to decide
## who attacks. If not set, every enemy still fighting attacks.
var attackers: Callable
## Song to play ("battle" if left empty). See audio/music/.
var music: String = ""
## If not empty, only these party members fight (e.g. ["Elric"] when Hop can't).
var party_only: Array[String] = []
## If above 0, this is a fight you can't win: survive this many enemy turns
## and it ends, showing `survive_lines`.
var survive_turns: int = 0
var survive_lines: Array = []
## If not transparent: during the enemy's turns, the screen around the box pulses
## this color and the box glows (Hopkuna's red aura).
var aura: Color = Color(0, 0, 0, 0)


func flavor_text(turn: int) -> String:
	if flavor.is_valid():
		return flavor.call(turn, enemies)
	# Point out anyone who can be spared first.
	for enemy in enemies:
		if enemy.is_active() and enemy.can_spare():
			return "* %s's name is YELLOW.\n* (Pick MERCY, then choose %s to SPARE.)" % [enemy.name, enemy.name]
	var lines: Array[String] = []
	for enemy in enemies:
		if enemy.is_active():
			lines.append_array(enemy.flavor_lines)
	return lines.pick_random() if not lines.is_empty() else "* ..."


func who_attacks(enemy_turn: int) -> Array[Enemy]:
	if attackers.is_valid():
		return attackers.call(enemy_turn, enemies)
	var result: Array[Enemy] = []
	for enemy in enemies:
		if enemy.is_active():
			result.append(enemy)
	return result
