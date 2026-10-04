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
