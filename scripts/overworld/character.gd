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
## Walking frames for the front and back views (optional): one step with each leg.
var front_walk: Array[Texture2D] = []
var back_walk: Array[Texture2D] = []
## Running frames (optional), used when following Elric while he sprints.
## Side runs have three: stride, stride (other arm), knee up.
var front_run: Array[Texture2D] = []
var back_run: Array[Texture2D] = []
var side_run: Array[Texture2D] = []
var _running: bool = false
## How long each frame of the walk cycle shows, in seconds.
const WALK_STEP := 0.11
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
## If set, the picture flips through these frames (like the SAVE star twinkling).
var frames: Array[Texture2D] = []
## Seconds each of those frames shows for.
var frame_time: float = 0.25
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
		# Never walk right on top of the player (that would hide them): when the
		# trail is too short to stay behind, just wait where we are.
		if step.length() > 0.5 and target.distance_to(follow.global_position) > 16.0:
			face(step)
			# Run to keep up when Elric sprints.
			_running = follow.sprinting
			var pace := 160.0 * (Player.SPRINT_MULTIPLIER if _running else 1.0)
			global_position = global_position.move_toward(target, pace * delta)
			_walking = true
		else:
			_walking = false
			_running = false

	_update_patrol(delta)
	_update_sprite()
	if glow:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		_sprite.modulate = Color.WHITE.lerp(glow_color, pulse)


func _update_sprite() -> void:
	if not frames.is_empty():
		_sprite.texture = frames[int(_time / frame_time) % frames.size()]
		return
	_sprite.flip_h = false
	if _running and _walking and _update_run_sprite():
		return
	# A four-step walk cycle: step, stand, other step, stand.
	var phase := int(_time / WALK_STEP) % 4 if _walking else 1
	if _facing.x != 0 and not side.is_empty():
		# Stand, step (arm forward), stand, step (arm back).
		var frame := 0
		if _walking and phase % 2 == 0:
			frame = 2 if phase == 2 and side.size() > 2 else 1
		_sprite.texture = side[frame]
		_sprite.flip_h = _facing.x < 0
		_sprite.position.y = -1.0 if _walking and phase % 2 == 0 else 0.0
	else:
		var up := _facing == Vector2.UP
		var steps: Array[Texture2D] = back_walk if up else front_walk
		if _walking and steps.size() == 2 and phase % 2 == 0:
			_sprite.texture = steps[phase / 2]
		else:
			_sprite.texture = back if up else front
		_sprite.position.y = -1.0 if _walking and phase % 2 == 0 else 0.0


## Running (see Player._update_run_sprite). False if there are no running pictures.
func _update_run_sprite() -> bool:
	var phase := int(_time * 1.3 / WALK_STEP) % 4
	if _facing.x != 0:
		if side_run.size() < 3:
			return false
		_sprite.texture = side_run[2] if phase % 2 == 1 else side_run[phase / 2]
		_sprite.flip_h = _facing.x < 0
		_sprite.position.y = -2.0 if phase % 2 == 1 else 0.0
		return true
	var up := _facing == Vector2.UP
	var runs := back_run if up else front_run
	if runs.size() < 2:
		return false
	_sprite.texture = runs[phase / 2] if phase % 2 == 0 else (back if up else front)
	_sprite.position.y = -2.0 if phase % 2 == 0 else 0.0
	return true


## True while walking somewhere on its own (a cutscene walk or a patrol).
func is_busy_moving() -> bool:
	return not _patrol_points.is_empty() or (_walking and follow == null)


## Walks back and forth between two points forever. Stops in place (and stays
## stopped) whenever anyone is talking, so you can chat with someone mid-walk.
func patrol(a: Vector2, b: Vector2, speed: float = 50.0) -> void:
	_patrol_points = [b, a]
	_patrol_speed = speed


var _patrol_points: Array = []
var _patrol_speed: float = 50.0
var _patrol_index: int = 0
var _patrol_rest: float = 0.0


## One frame of patrolling (called from _process).
func _update_patrol(delta: float) -> void:
	if _patrol_points.is_empty():
		return
	if Game.busy or Game.transitioning:
		_walking = false
		return
	if _patrol_rest > 0.0:
		_patrol_rest -= delta
		_walking = false
		return
	var target: Vector2 = _patrol_points[_patrol_index]
	if position.distance_to(target) < 1.0:
		_patrol_index = 1 - _patrol_index
		_patrol_rest = 0.6
		return
	face(target - position)
	position = position.move_toward(target, _patrol_speed * delta)
	_walking = true


## Changes how the character looks (e.g. Hop becoming Hopkuna) to another
## character's pictures, by name.
func set_look(who: String) -> void:
	var look := Cast.make(who)
	front = look.front
	back = look.back
	side = look.side
	front_walk = look.front_walk
	back_walk = look.back_walk
	front_run = look.front_run
	back_run = look.back_run
	side_run = look.side_run
	look.free()


## Lies down (fallen over) or gets back up.
func lie_down(down: bool = true) -> void:
	# Tipping the picture over around the feet lays it flat on the ground.
	if _sprite:
		_sprite.rotation = PI / 2 if down else 0.0


## A soft oval shadow on the ground under them (drawn before their picture, so
## it sits underneath).
func _draw() -> void:
	var width := front.get_width() * 0.42 if front else 8.0
	draw_set_transform(Vector2(0, -1), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, width, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO)
