class_name PartyMember
extends RefCounted
## One member of Elric's party during a battle.

var name: String
var max_hp: int
var hp: int
## Base damage for FIGHT. A perfect hit does roughly 3x this.
var attack: int
## The color of this member's name in the HP panel.
var color: Color
## True while this member is defending this turn (takes half damage).
var defending: bool = false


func _init(p_name: String, p_max_hp: int, p_attack: int, p_color: Color) -> void:
	name = p_name
	max_hp = p_max_hp
	hp = p_max_hp
	attack = p_attack
	color = p_color


## A member at 0 HP is "down" and skips their turns until healed.
func is_down() -> bool:
	return hp <= 0
