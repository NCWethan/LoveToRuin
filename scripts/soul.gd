extends Sprite2D
## The player's SOUL: a red heart you move with the arrow keys.

## How fast the heart moves, in pixels per second.
@export var speed: float = 120.0


func _process(delta: float) -> void:
	# Read the arrow keys. This gives a direction like (1, 0) for right
	# or (-1, -1) for up-left.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Move in that direction. Multiplying by delta (the time since the
	# last frame) keeps the speed the same on fast and slow computers.
	position += direction * speed * delta
