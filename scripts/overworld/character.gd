class_name Character
extends Node2D
## Anyone or anything in the overworld besides Elric: people like Hop, and objects
## like the fragment or a SAVE star.
##
## - Give it `on_interact` to make it something Elric can talk to / inspect with Z.
## - Set `follow` to the player to make it walk behind Elric (like Hop does).
## - Use `await walk_to(...)` in cutscenes.

var front: Texture2D
var back: Texture2D
## Two side-view walking frames (optional). Flipped when facing left.
var side: Array[Texture2D] = []
## What happens when Elric presses Z next to it. Can use `await` inside.
var on_interact: Callable
## If set, this character trails behind the player instead of standing still.
var follow: Player:
	set(value):
		follow = value
		_set_solid(value == null and solid)
## Whether Elric bumps into it.
var solid: bool = true
## Makes the sprite gently pulse (for glowing things).
var glow: bool = false
## The color it pulses toward while glowing.
var glow_color: Color = Color(1.0, 0.5, 0.5)

var _sprite: Sprite2D
var _body: StaticBody2D
var _time: float = 0.0
var _walking: bool = false
var _facing: Vector2 = Vector2.DOWN


## Sets the character up. Call before adding it to the scene.
func setup(front_texture: Texture2D, back_texture: Texture2D = null, is_solid: bool = true) -> Character:
	front = front_texture
	back = back_texture if back_texture else front_texture
	solid = is_solid
	return self


## Adds side-view walking frames. Call before adding it to the scene.
func with_side(frame_1: Texture2D, frame_2: Texture2D) -> Character:
	side = [frame_1, frame_2]
	return self


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = front
	_sprite.offset = Vector2(0, -front.get_height() / 2.0)
	add_child(_sprite)

	_body = StaticBody2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 8)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0, -4)
	_body.add_child(collision)
	add_child(_body)
	_set_solid(solid and follow == null)

	if on_interact.is_valid():
		add_to_group("interactable")


func _set_solid(value: bool) -> void:
	if _body:
		_body.collision_layer = 1 if value else 0


## Called by the player. Runs `on_interact` and waits for it to finish.
func interact() -> void:
	if on_interact.is_valid():
		await on_interact.call()


## Walks to `target` at `speed` pixels per second. Use with await in cutscenes.
func walk_to(target: Vector2, speed: float = 90.0) -> void:
	var distance := global_position.distance_to(target)
	if distance < 1.0:
		return
	face(target - global_position)
	_walking = true
	var tween := create_tween()
	tween.tween_property(self, "global_position", target, distance / speed)
	await tween.finished
	_walking = false


## Turns to look in a direction (up, down, left or right, whichever is closest).
func face(direction: Vector2) -> void:
	if direction.length() < 0.01:
		return
	if absf(direction.x) > absf(direction.y) and not side.is_empty():
		_facing = Vector2(signf(direction.x), 0)
	elif direction.y < 0:
		_facing = Vector2.UP
	else:
		_facing = Vector2.DOWN


func _process(delta: float) -> void:
	_time += delta

	if follow and not follow.trail.is_empty():
		# Stay about 14 trail steps (~28 pixels of walking) behind the player.
		var index := maxi(0, follow.trail.size() - 14)
		var target := follow.trail[index]
		var step := target - global_position
		if step.length() > 0.5:
			face(step)
			global_position = global_position.move_toward(target, 160.0 * delta)
			_walking = true
		else:
			_walking = false

	_update_sprite()
	if glow:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		_sprite.modulate = Color.WHITE.lerp(glow_color, pulse)


func _update_sprite() -> void:
	_sprite.flip_h = false
	if _facing.x != 0 and not side.is_empty():
		var frame := int(_time / 0.15) % 2 if _walking else 0
		_sprite.texture = side[frame]
		_sprite.flip_h = _facing.x < 0
		_sprite.position.y = 0.0
	else:
		_sprite.texture = back if _facing == Vector2.UP else front
		_sprite.position.y = -absf(sin(_time * 12.0)) * 1.5 if _walking else 0.0


## Walks back and forth between two points forever (pausing during dialogue).
func patrol(a: Vector2, b: Vector2, speed: float = 50.0) -> void:
	_patrol.call_deferred(a, b, speed)


func _patrol(a: Vector2, b: Vector2, speed: float) -> void:
	var targets := [b, a]
	var i := 0
	while is_inside_tree():
		if Game.busy or Game.transitioning:
			await get_tree().process_frame
			continue
		await walk_to(targets[i % 2], speed)
		i += 1
		if is_inside_tree():
			await get_tree().create_timer(0.6).timeout
