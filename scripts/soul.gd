class_name Soul
extends Sprite2D
## The player's SOUL: a red heart you move with the arrow keys.
## Outside of dodging, the battle also uses it as the menu cursor.

## How fast the heart moves, in pixels per second.
@export var speed: float = 120.0

## When false, the arrow keys don't move the heart (it's being used as a cursor).
var can_move: bool = true

## The battle box the heart has to stay inside (a sibling node named BattleBox).
@onready var box: BattleBox = get_node_or_null("../BattleBox")


func _ready() -> void:
	# Always draw the heart on top of the box.
	z_index = 1
	# Start in the middle of the box.
	if box:
		global_position = box.get_inner_rect().get_center()


## Hop's SOUL: a silver heart broken into shards that drift apart and back, with
## red light pulsing through the cracks. (Elric's is the plain red one.)
var fragmented: bool = false:
	set(value):
		fragmented = value
		if _red_heart == null:
			_red_heart = texture
		texture = null if value else _red_heart
		queue_redraw()
var _red_heart: Texture2D
var _time: float = 0.0

## The outline of a heart, about 16 pixels across, centered on (0, 0).
const HEART := [Vector2(0, -3), Vector2(3, -7), Vector2(6, -7), Vector2(8, -5), Vector2(8, -2),
	Vector2(0, 7), Vector2(-8, -2), Vector2(-8, -5), Vector2(-6, -7), Vector2(-3, -7)]


func _draw() -> void:
	if not fragmented:
		return
	var heart := PackedVector2Array(HEART)
	var pulse := 0.5 + 0.5 * sin(_time * 5.0)
	# The red glow underneath, showing through the gaps.
	var glow := PackedVector2Array()
	for p in heart:
		glow.append(p * 1.05)
	draw_colored_polygon(glow, Color(0.9, 0.08, 0.15, 0.5 + 0.4 * pulse))
	# Four shards, cut from the heart along two crooked lines, drifting apart.
	var spread := 1.0 + 0.8 * sin(_time * 2.3)
	var cuts := [
		PackedVector2Array([Vector2(-10, -10), Vector2(1, -10), Vector2(-1, -1), Vector2(-10, 1)]),
		PackedVector2Array([Vector2(1, -10), Vector2(10, -10), Vector2(10, 0), Vector2(-1, -1)]),
		PackedVector2Array([Vector2(-10, 1), Vector2(-1, -1), Vector2(1, 10), Vector2(-10, 10)]),
		PackedVector2Array([Vector2(-1, -1), Vector2(10, 0), Vector2(10, 10), Vector2(1, 10)]),
	]
	var directions := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	for i in 4:
		for piece in Geometry2D.intersect_polygons(heart, cuts[i]):
			var moved := PackedVector2Array()
			for p in piece:
				moved.append(p + directions[i].normalized() * spread)
			draw_colored_polygon(moved, Color(0.82, 0.84, 0.9))
			draw_polyline(moved + PackedVector2Array([moved[0]]), Color(0.45, 0.47, 0.55), 1.0)


func _process(delta: float) -> void:
	_time += delta
	if fragmented:
		queue_redraw()
	if not can_move:
		return

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
