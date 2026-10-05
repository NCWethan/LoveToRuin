class_name PartyMember
extends RefCounted
## One member of Elric's party during a battle.

## The name shown ("Big Joe").
var name: String
## Who they are, for pictures and stats ("BigJoe6"). The same as `name` unless
## their display name is different.
var id: String
var max_hp: int
var hp: int
## Base damage for FIGHT. A perfect hit does roughly 3x this.
var attack: int
## The color of this member's name in the HP panel.
var color: Color
## Extra HP on top of the max (from The-Eggo Benedict). Hits use it up first. It
## only lasts for the battle it was given in.
var overheal: int = 0
## True while this member is defending this turn (takes half damage).
var defending: bool = false
## The member's picture on the left side of the battle screen.
var sprite: Texture2D
## Subtracted from every hit this member takes. Only accessories raise it.
var defense: int = 0
## Counts down after getting hit; the member shakes while it's above 0.
var shake: float = 0.0
## Seconds since this member was knocked out (for the falling-over animation).
var ko_time: float = 0.0


func _init(p_name: String, p_max_hp: int, p_attack: int, p_color: Color, p_sprite: Texture2D = null) -> void:
	name = p_name
	id = p_name
	max_hp = p_max_hp
	hp = p_max_hp
	attack = p_attack
	color = p_color
	sprite = p_sprite


## A member at 0 HP is "down" and skips their turns until healed.
func is_down() -> bool:
	return hp <= 0
