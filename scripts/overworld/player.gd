class_name Player
extends CharacterBody2D
## Elric in the overworld. Arrow keys walk; Z talks to / inspects whatever is in front.

@export var speed: float = 110.0

## Which way Elric is facing (used for talking to things and picking the sprite).
var facing: Vector2 = Vector2.DOWN
## Recent positions, oldest first. Followers (like Hop) walk along this trail.
var trail: Array[Vector2] = []

var _front: Texture2D = load("res://art/sprites/elric.png")
var _back: Texture2D = load("res://art/sprites/elric_back.png")
## Two side-view frames (legs together / mid-step). Flipped when walking left.
var _side: Array[Texture2D] = [load("res://art/sprites/elric_side.png"), load("res://art/sprites/elric_side2.png")]
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
		move_and_slide()
		_moving = true
		_walk_time += delta
		_record_trail()

	_update_sprite()

	if Input.is_action_just_pressed("confirm"):
		_interact()


## Picks the right picture for the direction Elric faces, and animates walking.
func _update_sprite() -> void:
	_sprite.flip_h = false
	if facing.x != 0:
		# Side view: swap between the two frames every 0.15 seconds while walking.
		var frame := int(_walk_time / 0.15) % 2 if _moving else 0
		_sprite.texture = _side[frame]
		_sprite.flip_h = facing.x < 0
		_sprite.position.y = 0
	else:
		_sprite.texture = _back if facing == Vector2.UP else _front
		# Facing up or down: a little bounce while walking.
		_sprite.position.y = -absf(sin(_walk_time * 12.0)) * 1.5 if _moving else 0.0


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
