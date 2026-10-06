class_name Player
extends CharacterBody2D
## Elric in the overworld. Arrow keys walk; hold SHIFT to sprint (until the stamina
## bar runs out); ENTER talks to / inspects whatever is in front; B opens the bag.

@export var speed: float = 110.0
## How much faster sprinting is than walking.
const SPRINT_MULTIPLIER := 1.75
## Stamina runs from 0 to 1. A full bar lasts this many seconds of sprinting...
const SPRINT_SECONDS := 2.6
## ...and refills in this many seconds, starting a moment after you stop.
const REFILL_SECONDS := 3.2
const REFILL_DELAY := 0.5
## Run the bar all the way down and Elric is winded: no sprinting again until it's
## back up to this much.
const WINDED_UNTIL := 0.35

var stamina: float = 1.0
## True while Elric is actually sprinting (followers run to keep up).
var sprinting: bool = false
var _winded: bool = false
var _refill_wait: float = 0.0

## Which way Elric is facing (used for talking to things and picking the sprite).
var facing: Vector2 = Vector2.DOWN
## Recent positions, oldest first. Followers (like Hop) walk along this trail.
var trail: Array[Vector2] = []
## How far Elric has walked in this area, in pixels (used for random encounters).
var distance_walked: float = 0.0

## Elric's pictures (loaded in _load_look: they get worse on the Genocide path).
var _front: Texture2D
var _back: Texture2D
## Side-view frames (legs together / mid-step, each arm). Flipped when walking left.
var _side: Array[Texture2D] = []
## Walking frames for the front and back views: one step with each leg.
var _front_walk: Array[Texture2D] = []
var _back_walk: Array[Texture2D] = []
## Running frames, for sprinting (see Cast.run_frames).
var _front_run: Array[Texture2D] = []
var _back_run: Array[Texture2D] = []
var _side_run: Array[Texture2D] = []
var _stamina_bar: CanvasLayer
var _sprite: Sprite2D
var _walk_time: float = 0.0
var _moving: bool = false


func _ready() -> void:
	add_to_group("player")
	_load_look()

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

	# The stamina bar, in the bottom-right corner of the screen.
	_stamina_bar = load("res://scripts/ui/stamina_bar.gd").new()
	_stamina_bar.player = self
	add_child(_stamina_bar)


## If the game window loses focus with Shift held, the key-up never arrives:
## let go of it, so Elric doesn't keep sprinting.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.action_release("sprint")
		sprinting = false

## Loads Elric's pictures: normal, or worse the further down the Genocide path.
func _load_look() -> void:
	var base := "res://art/sprites/" + Game.sprite_base("Elric")
	_front = load(base + ".png")
	_back = load(base + "_back.png")
	_side.assign([load(base + "_side.png"), load(base + "_side2.png"), load(base + "_side3.png")])
	_front_walk = Cast.walk_frames(base)
	_back_walk = Cast.walk_frames(base + "_back")
	_front_run = Cast.run_frames(base)
	_back_run = Cast.run_frames(base + "_back")
	_side_run = Cast.run_frames(base + "_side")


func _physics_process(delta: float) -> void:
	if Game.dread() >= 4:
		queue_redraw()
	_moving = false
	if Game.busy or Game.transitioning:
		sprinting = false
		_update_sprite()
		return

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		# Face whichever direction is pressed most.
		if absf(direction.x) > absf(direction.y):
			facing = Vector2(signf(direction.x), 0)
		else:
			facing = Vector2(0, signf(direction.y))
		# Only while Shift is actually held down, right now (never a toggle).
		sprinting = Input.is_action_pressed("sprint") and Input.is_physical_key_pressed(KEY_SHIFT) and not _winded and stamina > 0.0
		velocity = direction * speed * (SPRINT_MULTIPLIER if sprinting else 1.0)
		var before := position
		move_and_slide()
		distance_walked += position.distance_to(before)
		_moving = true
		_walk_time += delta * (1.3 if sprinting else 1.0)
		_record_trail()
	else:
		sprinting = false
	_update_stamina(delta)

	_update_sprite()

	if Input.is_action_just_pressed("confirm"):
		_interact()
	elif Input.is_action_just_pressed("menu"):
		Game.bag.open()


## Sprinting drains the stamina bar; it refills a moment after you stop. Draining
## it completely leaves Elric winded until it has partly refilled.
func _update_stamina(delta: float) -> void:
	if sprinting:
		stamina = maxf(stamina - delta / SPRINT_SECONDS, 0.0)
		_refill_wait = REFILL_DELAY
		if stamina == 0.0:
			_winded = true
			sprinting = false
	elif _refill_wait > 0.0:
		_refill_wait -= delta
	else:
		stamina = minf(stamina + delta / REFILL_SECONDS, 1.0)
	if _winded and stamina >= WINDED_UNTIL:
		_winded = false


## True while out of breath (the bar shows it).
func is_winded() -> bool:
	return _winded


## Sprinting: a faster four-step run cycle with its own pictures. Side view: stride,
## knee up, other stride, knee up. Front and back: step, stand, other step, stand.
## Returns false if there are no running pictures (then the walk is used).
func _update_run_sprite() -> bool:
	var phase := int(_walk_time / Character.WALK_STEP) % 4
	if facing.x != 0:
		if _side_run.size() < 3:
			return false
		_sprite.texture = _side_run[2] if phase % 2 == 1 else _side_run[phase / 2]
		_sprite.flip_h = facing.x < 0
		_sprite.position.y = -2.0 if phase % 2 == 1 else 0.0
		return true
	var runs := _back_run if facing == Vector2.UP else _front_run
	if runs.size() < 2:
		return false
	_sprite.texture = runs[phase / 2] if phase % 2 == 0 else (_back if facing == Vector2.UP else _front)
	_sprite.position.y = -2.0 if phase % 2 == 0 else 0.0
	return true


## Picks the right picture for the direction Elric faces, and animates walking.
func _update_sprite() -> void:
	_sprite.flip_h = false
	if sprinting and _moving and _update_run_sprite():
		return
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
	# A few spots in front of Elric, from right up close to an arm's length away,
	# so things are in reach whether Elric is pressed up against them or not.
	var best: Node2D = null
	var best_distance := 24.0
	for reach in [4.0, 10.0, 16.0, 24.0]:
		var probe: Vector2 = global_position + facing * reach + Vector2(0, -6)
		for node in get_tree().get_nodes_in_group("interactable"):
			var distance := (node as Node2D).global_position.distance_to(probe)
			if distance < best_distance:
				best = node
				best_distance = distance
	if best:
		Game.busy = true
		# (Call the action itself, not best.interact(): if the thing removes itself
		# (a fragment picked up, a person gone), waiting on it would never finish.)
		var action: Callable = best.get("on_interact")
		if action.is_valid():
			await action.call()
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
	# At the end (Relic), a deep green haze clings to Elric, with wisps
	# rising off them.
	if Game.dread() >= 4:
		var t := Time.get_ticks_msec() / 1000.0
		draw_circle(Vector2(0, -16), 18.0 + sin(t * 3.0) * 1.5, Color(0.0, 0.2, 0.07, 0.24))
		for w in 5:
			var rise := fmod(t * 0.7 + w * 0.2, 1.0)
			var wisp := Vector2(sin(t * 2.0 + w * 1.7) * 9.0, -4.0 - rise * 34.0)
			draw_circle(wisp, 2.5 * (1.0 - rise), Color(0.05, 0.4, 0.15, 0.6 * (1.0 - rise)))
