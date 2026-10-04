class_name Hotspot
extends Node2D
## An invisible spot Elric can inspect with Z, like a shop door or a sign.

var on_interact: Callable


static func create(at: Vector2, action: Callable) -> Hotspot:
	var spot := Hotspot.new()
	spot.position = at
	spot.on_interact = action
	return spot


func _ready() -> void:
	add_to_group("interactable")


func interact() -> void:
	if on_interact.is_valid():
		await on_interact.call()
