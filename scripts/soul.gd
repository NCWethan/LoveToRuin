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
	dread = Game.dread()
	# Start in the middle of the box.
	if box:
		global_position = box.get_inner_rect().get_center()


## Hop's SOUL: a silver heart broken into shards that drift apart and back, with
## red light pulsing through the cracks. (Elric's is the plain red one.)
var fragmented: bool = false:
	set(value):
		fragmented = value
		_update_texture()

## Elric's dread (Game.dread()): 0 is the plain red heart. With each stage it's
## more warped and cracked with green; at 4 (Relic), twisted and dark green.
var dread: int = 0:
	set(value):
		dread = value
		_update_texture()


func _update_texture() -> void:
	if _red_heart == null:
		_red_heart = texture
	texture = null if fragmented or dread > 0 else _red_heart
	queue_redraw()
var _red_heart: Texture2D
var _time: float = 0.0

## The outline of a heart, about 16 pixels across, centered on (0, 0).
const HEART := [Vector2(0, -3), Vector2(3, -7), Vector2(6, -7), Vector2(8, -5), Vector2(8, -2),
	Vector2(0, 7), Vector2(-8, -2), Vector2(-8, -5), Vector2(-6, -7), Vector2(-3, -7)]


func _draw() -> void:
	if dread > 0 and not fragmented:
		_draw_dread_heart()
		return
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


## The heart's outline with more points along each edge, so it can bend.
func _smooth_heart() -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in HEART.size():
		var a: Vector2 = HEART[i]
		var b: Vector2 = HEART[(i + 1) % HEART.size()]
		for k in 4:
			points.append(a.lerp(b, k / 4.0))
	return points


## Cracks across the heart (in heart coordinates), added one by one with dread.
const CRACKS := [
	[Vector2(-2, -6), Vector2(0, -2), Vector2(-2, 1), Vector2(0, 4)],
	[Vector2(5, -6), Vector2(3, -3), Vector2(5, -1)],
	[Vector2(-6, -4), Vector2(-3, -2), Vector2(-4, 1)],
	[Vector2(2, 1), Vector2(4, 2), Vector2(3, 4)],
	[Vector2(-7, -2), Vector2(-4, 0), Vector2(-1, 0), Vector2(1, -1)],
	[Vector2(7, -3), Vector2(4, 0), Vector2(1, 3)],
]


func _draw_dread_heart() -> void:
	var stage := clampi(dread, 1, 4)
	var warp: float = [0.0, 0.35, 0.8, 1.3, 2.0][stage]
	var heart := PackedVector2Array()
	for p in _smooth_heart():
		# Bent out of shape: a slow writhe, and at the end a twist.
		var bent: Vector2 = p + Vector2(sin(p.y * 0.9 + _time * 1.7), cos(p.x * 0.8 + _time * 1.3) * 0.6) * warp
		if stage >= 4:
			bent = bent.rotated(p.y * 0.05 * sin(_time * 0.9))
		heart.append(bent)
	var body: Color = [Color(1, 0, 0), Color(0.92, 0.05, 0.1), Color(0.7, 0.12, 0.12), Color(0.35, 0.3, 0.12), Color(0.06, 0.28, 0.12)][stage]
	draw_colored_polygon(heart, body)
	if stage >= 4:
		draw_polyline(heart + PackedVector2Array([heart[0]]), Color(0.02, 0.12, 0.05), 1.0)
	var glow := 0.6 + 0.4 * sin(_time * 4.0)
	var crack_color := Color(0.25, 1.0, 0.45, glow) if stage < 4 else Color(0.2, 0.75, 0.35, glow)
	var count: int = [0, 2, 3, 5, 6][stage]
	for c in count:
		var line := PackedVector2Array()
		for p in CRACKS[c]:
			line.append(p + Vector2(sin(p.y * 0.9 + _time * 1.7), 0) * warp)
		draw_polyline(line, crack_color, 1.0)


func _process(delta: float) -> void:
	_time += delta
	if fragmented or dread > 0:
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
