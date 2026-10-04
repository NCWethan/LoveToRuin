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


## Sets the character up. Call before adding it to the scene.
func setup(front_texture: Texture2D, back_texture: Texture2D = null, is_solid: bool = true) -> Character:
	front = front_texture
	back = back_texture if back_texture else front_texture
	solid = is_solid
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


func face(direction: Vector2) -> void:
	if _sprite:
		_sprite.texture = back if direction.y < -absf(direction.x) else front


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

	_sprite.position.y = -absf(sin(_time * 12.0)) * 1.5 if _walking else 0.0
	if glow:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		_sprite.modulate = Color.WHITE.lerp(glow_color, pulse)
