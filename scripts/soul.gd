extends Sprite2D
## The player's SOUL: a red heart you move with the arrow keys.

## How fast the heart moves, in pixels per second.
@export var speed: float = 120.0

## The battle box the heart has to stay inside (a sibling node named BattleBox).
@onready var box: BattleBox = get_node_or_null("../BattleBox")


func _ready() -> void:
	# Always draw the heart on top of the box.
	z_index = 1
	# Start in the middle of the box.
	if box:
		global_position = box.get_inner_rect().get_center()


func _process(delta: float) -> void:
	# Read the arrow keys. This gives a direction like (1, 0) for right
	# or (-1, -1) for up-left.
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Move in that direction. Multiplying by delta (the time since the
	# last frame) keeps the speed the same on fast and slow computers.
	position += direction * speed * delta

	# Keep the heart inside the box. The heart is 16 pixels wide, so we
	# shrink the box by 8 pixels (half the heart) on every side.
	if box:
		var area := box.get_inner_rect().grow(-8)
		global_position = global_position.clamp(area.position, area.end)
