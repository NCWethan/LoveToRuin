class_name Player
extends CharacterBody2D
## Elric in the overworld. Arrow keys walk; ENTER talks to / inspects whatever is in front;
## B opens the bag.

@export var speed: float = 110.0

## Which way Elric is facing (used for talking to things and picking the sprite).
var facing: Vector2 = Vector2.DOWN
## Recent positions, oldest first. Followers (like Hop) walk along this trail.
var trail: Array[Vector2] = []
## How far Elric has walked in this area, in pixels (used for random encounters).
var distance_walked: float = 0.0

var _front: Texture2D = load("res://art/sprites/elric.png")
var _back: Texture2D = load("res://art/sprites/elric_back.png")
## Two side-view frames (legs together / mid-step). Flipped when walking left.
var _side: Array[Texture2D] = [load("res://art/sprites/elric_side.png"), load("res://art/sprites/elric_side2.png"), load("res://art/sprites/elric_side3.png")]
## Walking frames for the front and back views: one step with each leg.
var _front_walk: Array[Texture2D] = Cast.walk_frames("res://art/sprites/elric")
var _back_walk: Array[Texture2D] = Cast.walk_frames("res://art/sprites/elric_back")
var _sprite: Sprite2D
var _walk_time: float = 0.0
var _moving: bool = false


func _ready() -> void:
	add_to_group("player")

	# The node's position is Elric's feet; the picture sits above it.
	_sprite = Sprite2D.new()
	_sprite.texture = _front
	_sprite.offset = Vector2(0, -_front.get_height() / 2.0)
	add_child(_sprite)

	# Only the feet collide, so Elric can walk "in front of" walls and trees.
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 8)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -4)
	add_child(collision)

	trail.append(global_position)


func _physics_process(delta: float) -> void:
	_moving = false
	if Game.busy or Game.transitioning:
		_update_sprite()
		return

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		# Face whichever direction is pressed most.
		if absf(direction.x) > absf(direction.y):
			facing = Vector2(signf(direction.x), 0)
		else:
			facing = Vector2(0, signf(direction.y))
		velocity = direction * speed
		var before := position
		move_and_slide()
		distance_walked += position.distance_to(before)
		_moving = true
		_walk_time += delta
		_record_trail()

	_update_sprite()

	if Input.is_action_just_pressed("confirm"):
		_interact()
	elif Input.is_action_just_pressed("menu"):
		Game.bag.open()


## Picks the right picture for the direction Elric faces, and animates walking.
func _update_sprite() -> void:
	_sprite.flip_h = false
	# A four-step walk cycle: step, stand, other step, stand (see Character.WALK_STEP).
	var phase := int(_walk_time / Character.WALK_STEP) % 4 if _moving else 1
	var stepping := _moving and phase % 2 == 0
	if facing.x != 0:
		# Stand, step (arm forward), stand, step (arm back).
		_sprite.texture = _side[(2 if phase == 2 else 1) if stepping else 0]
		_sprite.flip_h = facing.x < 0
	else:
		var up := facing == Vector2.UP
		var steps := _back_walk if up else _front_walk
		if stepping and steps.size() == 2:
			_sprite.texture = steps[phase / 2]
		else:
			_sprite.texture = _back if up else _front
	# A tiny bob on each step.
	_sprite.position.y = -1.0 if stepping else 0.0


func _record_trail() -> void:
	if trail.is_empty() or trail.back().distance_to(global_position) >= 2.0:
		trail.append(global_position)
		if trail.size() > 60:
			trail.pop_front()


## Talks to / inspects the nearest interactable thing just in front of Elric.
func _interact() -> void:
	var probe := global_position + facing * 16 + Vector2(0, -6)
	var best: Node2D = null
	var best_distance := 24.0
	for node in get_tree().get_nodes_in_group("interactable"):
		var distance := (node as Node2D).global_position.distance_to(probe)
		if distance < best_distance:
			best = node
			best_distance = distance
	if best:
		Game.busy = true
		await best.interact()
		Game.busy = false
		return
	# Nobody there: look at the scenery in front instead (trees, walls, doors...).
	var area := get_tree().current_scene as Area
	if area:
		var spot := global_position + Vector2(0, -4) + facing * 14
		Game.busy = true
		await area.inspect_tile(Vector2i(floori(spot.x / Room.TILE), floori(spot.y / Room.TILE)))
		Game.busy = false


## Shows (or hides) a "!" above Elric's head, like when a random fight starts.
func show_alert(on: bool) -> void:
	var alert := get_node_or_null("Alert") as Label
	if alert == null:
		alert = Label.new()
		alert.name = "Alert"
		alert.text = "!"
		alert.add_theme_font_size_override("font_size", 22)
		alert.add_theme_color_override("font_color", Color.WHITE)
		alert.add_theme_color_override("font_outline_color", Color.BLACK)
		alert.add_theme_constant_override("outline_size", 4)
		alert.position = Vector2(-5, -_front.get_height() - 30)
		add_child(alert)
	alert.visible = on
	if on:
		Game.play_sfx("alert")


## A soft oval shadow on the ground under Elric (drawn underneath the picture).
func _draw() -> void:
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO)
