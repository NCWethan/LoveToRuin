class_name Car
extends Node2D
## A little car, seen from the side, that can drive along a road.
## Its position is the middle of the bottom (where the wheels touch the road).
##
##   var car := Car.new()
##   car.position = Vector2(-80, 530)
##   world.add_child(car)
##   await car.drive_to(400.0)

const LENGTH := 76.0
const HEIGHT := 34.0
const WHEEL := 7.0

## The paint job.
var color: Color = Color8(70, 110, 200)
## Which way it's pointing: 1 = right, -1 = left.
var direction: int = 1

var _wheel_turn: float = 0.0
var _bounce: float = 0.0
var _moving: bool = false


func _process(delta: float) -> void:
	if _moving:
		_bounce += delta * 18.0
	queue_redraw()


## Drives to x (staying on this lane) and waits until it gets there.
## The car speeds up from a stop and slows down at the end.
func drive_to(x: float, speed: float = 220.0) -> void:
	var distance := absf(x - position.x)
	if distance < 1.0:
		return
	direction = 1 if x > position.x else -1
	_moving = true
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_move_to, position.x, x, distance / speed)
	await tween.finished
	_moving = false
	_bounce = 0.0


func _move_to(x: float) -> void:
	_wheel_turn += (x - position.x) / WHEEL
	position.x = x


func _draw() -> void:
	var lift := -absf(sin(_bounce)) * 1.0
	var d := float(direction)
	var outline := Color(0.08, 0.08, 0.12)
	var dark := color.darkened(0.35)
	var glass := Color8(150, 200, 230)

	# Shadow on the road.
	draw_rect(Rect2(-LENGTH / 2 + 4, -3, LENGTH - 8, 5), Color(0, 0, 0, 0.3))

	# The body, then the cabin on top (the cabin sits toward the back).
	var body := Rect2(-LENGTH / 2, -22 + lift, LENGTH, 15)
	draw_rect(body.grow(2), outline)
	draw_rect(body, color)
	draw_rect(Rect2(body.position.x, body.end.y - 4, body.size.x, 4), dark)
	var cabin := PackedVector2Array([
		Vector2(-30 * d, -22 + lift), Vector2(-24 * d, -HEIGHT + lift),
		Vector2(10 * d, -HEIGHT + lift), Vector2(20 * d, -22 + lift)])
	draw_colored_polygon(cabin, color)
	draw_polyline(cabin, outline, 2.0)
	# Two windows with a pillar between them.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-26 * d, -23 + lift), Vector2(-22 * d, -31 + lift),
		Vector2(-6 * d, -31 + lift), Vector2(-6 * d, -23 + lift)]), glass)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-2 * d, -23 + lift), Vector2(-2 * d, -31 + lift),
		Vector2(8 * d, -31 + lift), Vector2(16 * d, -23 + lift)]), glass)
	draw_line(Vector2(-20 * d, -30 + lift), Vector2(-14 * d, -24 + lift), Color(1, 1, 1, 0.6), 1.5)
	# Door line and handle.
	draw_line(Vector2(-4 * d, -21 + lift), Vector2(-4 * d, -9 + lift), dark, 1.0)
	draw_rect(Rect2(Vector2(2 * d - 2, -18 + lift), Vector2(4, 2)), dark.darkened(0.3))
	# Headlight in front, taillight in back.
	draw_rect(Rect2(Vector2(LENGTH / 2 * d - 3 - d * 1, -19 + lift), Vector2(4, 4)), Color8(255, 240, 150))
	draw_rect(Rect2(Vector2(-LENGTH / 2 * d - 1 + d * 1, -19 + lift), Vector2(3, 4)), Color8(230, 40, 40))
	if _moving:
		# A puff of exhaust behind it.
		var puff := fmod(_bounce * 0.2, 1.0)
		draw_circle(Vector2((-LENGTH / 2 - 4 - puff * 10) * d, -9 - puff * 4), 3 + puff * 3, Color(0.8, 0.8, 0.8, 0.5 * (1.0 - puff)))

	# Wheels, with a spoke so you can see them spin.
	for wheel_x in [-LENGTH / 2 + 15, LENGTH / 2 - 15]:
		var center := Vector2(wheel_x, -WHEEL)
		draw_circle(center, WHEEL + 1, outline)
		draw_circle(center, WHEEL - 1, Color8(60, 60, 66))
		draw_circle(center, 3, Color8(190, 190, 200))
		var spoke := Vector2.from_angle(_wheel_turn) * (WHEEL - 2)
		draw_line(center - spoke, center + spoke, Color8(190, 190, 200), 1.5)
