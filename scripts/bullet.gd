class_name Bullet
extends Node2D
## A white pellet that flies in a straight line. Touching it hurts the SOUL.

## Which way and how fast the bullet moves, in pixels per second.
@export var velocity: Vector2 = Vector2.ZERO
## How big the bullet is, in pixels.
@export var size: float = 6.0
## How much HP the SOUL loses when this bullet hits it.
@export var damage: int = 3

## The area the bullet lives in. Once it flies out, it disappears.
var bounds: Rect2


func _ready() -> void:
	# Draw on top of the battle box, like the SOUL.
	z_index = 1


func _process(delta: float) -> void:
	position += velocity * delta

	# Remove the bullet once it has left the box, so they don't pile up forever.
	if bounds.has_area() and not bounds.grow(size).has_point(global_position):
		queue_free()


## Returns the square the SOUL has to touch to get hit, in screen coordinates.
func get_hitbox() -> Rect2:
	return Rect2(global_position - Vector2(size, size) / 2, Vector2(size, size))


func _draw() -> void:
	draw_rect(Rect2(-Vector2(size, size) / 2, Vector2(size, size)), Color.WHITE)
