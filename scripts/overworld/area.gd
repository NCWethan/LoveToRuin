class_name Area
extends Node2D
## Everything overworld areas have in common: the tile map, Elric, the camera,
## and helpers for story flags, cutscenes and talking to people.
##
## To make an area: extend this, override build_map(), and call setup_area()
## at the start of _ready().

var room: Room
## Everyone who walks around goes in here, sorted by height on screen
## so people further down are drawn in front.
var world: Node2D
var player: Player
var camera: Camera2D
## Rooms within this area's map (in pixels). The camera stays inside whichever
## room Elric is in. Leave empty to use the whole map as one room.
var rooms: Array[Rect2] = []

var _cutscene_running: bool = false


## Builds the map, places Elric (at `default_spawn` unless the game says otherwise)
## and attaches the camera.
func setup_area(default_spawn: Vector2) -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)

	room = Room.new()
	add_child(room)
	build_map()
	room.build()

	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)

	player = Player.new()
	player.position = Game.spawn_position if Game.spawn_position != null else default_spawn
	Game.spawn_position = null
	world.add_child(player)

	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(room.pixel_size().x)
	camera.limit_bottom = int(room.pixel_size().y)
	camera.position_smoothing_enabled = true
	player.add_child(camera)

	# A compass in the top-right corner (it never turns; north is always up).
	var compass_layer := CanvasLayer.new()
	compass_layer.layer = 5
	add_child(compass_layer)
	var compass := Control.new()
	compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	compass.position = Vector2(598, 42)
	compass_layer.add_child(compass)
	compass.draw.connect(_draw_compass.bind(compass))
	compass.queue_redraw()


## N, E, S and W around a little dial.
func _draw_compass(compass: Control) -> void:
	var font := ThemeDB.fallback_font
	compass.draw_circle(Vector2.ZERO, 27, Color(0, 0, 0, 0.55))
	compass.draw_arc(Vector2.ZERO, 27, 0, TAU, 32, Color(1, 1, 1, 0.85), 2.0)
	compass.draw_arc(Vector2.ZERO, 22, 0, TAU, 32, Color(1, 1, 1, 0.25), 1.0)
	# A small four-pointed star in the middle.
	var star := PackedVector2Array([Vector2(0, -9), Vector2(2, -2), Vector2(9, 0), Vector2(2, 2),
		Vector2(0, 9), Vector2(-2, 2), Vector2(-9, 0), Vector2(-2, -2)])
	compass.draw_colored_polygon(star, Color(1, 1, 1, 0.5))
	var letters := {"N": Vector2(0, -16), "E": Vector2(16, 0), "S": Vector2(0, 16), "W": Vector2(-16, 0)}
	for letter in letters:
		var size := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		var color := Color(1.0, 0.35, 0.35) if letter == "N" else Color.WHITE
		compass.draw_string(font, letters[letter] + Vector2(-size.x / 2, 4), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)


## A SAVE point: a star that twinkles between two frames, like in Undertale.
func make_save_star() -> Character:
	var star := Character.new().setup(load("res://art/sprites/save_star.png"), null, false)
	star.frames.assign([load("res://art/sprites/save_star.png"), load("res://art/sprites/save_star2.png")])
	star.frame_time = 0.22
	return star


# --- Looking at things ---------------------------------------------------------

## Called when Elric presses ENTER facing plain scenery (a tree, a wall, a desk...).
## Areas can override this to give a particular spot its own text or puzzle;
## call super(cell) for everything else.
func inspect_tile(cell: Vector2i) -> void:
	var lines := describe_tile(cell, room.get_tile(cell.x, cell.y))
	if not lines.is_empty():
		await Game.dialogue.say(lines)


## What Elric notices about each kind of tile. Areas can override this to change
## the text for a whole kind of tile (like the doors at Mt. Carmel).
func describe_tile(cell: Vector2i, tile: int) -> Array:
	# Pick one of the options based on the spot, so the same tree always says
	# the same thing but neighboring trees can differ.
	var pick := func(options: Array) -> Array:
		return [options[absi(cell.x * 7 + cell.y * 13) % options.size()]]
	match tile:
		Room.TREE:
			return pick.call(["* (It's a tree.)", "* (It's a tree. It's doing its best.)", "* (A tree. The leaves rustle a little.)", "* (It's a tree.\n*  You feel like it's judging you.)"])
		Room.PALM:
			return pick.call(["* (A palm tree. Very San Diego.)", "* (A palm tree. No coconuts. Disappointing.)"])
		Room.BENCH:
			return pick.call(["* (A bench. It's a little wobbly.)", "* (A bench. Someone carved a tiny heart into it.)"])
		Room.FENCE:
			return ["* (A chain-link fence.)"]
		Room.WINDOW:
			return ["* (You peek through the window.\n*  Rows of empty desks.)"]
		Room.DOOR:
			return ["* (A door. It's locked.)"]
		Room.WALL, Room.STUCCO, Room.WOOD_WALL, Room.RED_WALL, Room.INTERIOR_WALL:
			return pick.call(["* (A wall. Very solid.)", "* (It's a wall. It's not going anywhere.)"])
		Room.BLEACHERS:
			return ["* (The bleachers. Someone left a half-eaten\n*  sandwich up there.)"]
		Room.GLASS:
			return ["* (Your reflection looks back at you.)"]
		Room.PLANTER:
			return ["* (A planter full of little succulents.)"]
		Room.TABLE:
			return ["* (A table under a big green umbrella.)"]
		Room.LOCKER:
			return pick.call(["* (A locker. It won't open.)", "* (A locker. Something rattles inside.\n*  It won't open.)", "* (A locker covered in stickers.)"])
		Room.CHALKBOARD:
			return ["* (A chalkboard. Someone drew a wolverine on it.)"]
		Room.DESK:
			return pick.call(["* (A desk. There's gum stuck underneath.)", "* (A desk. Someone wrote \"HELP\" on it.\n*  ...In math class, that's fair.)"])
	return []


## Override this to lay out the area's tiles on `room`.
func build_map() -> void:
	pass


func flag(name: String) -> bool:
	return Game.flags.get(name, false)


## True while something else is happening (dialogue, a fade, a cutscene).
func is_blocked() -> bool:
	return Game.busy or Game.transitioning or _cutscene_running


## Waits until the fade-in after a scene change has finished.
func wait_for_fade() -> void:
	while Game.transitioning:
		if not is_inside_tree():
			return
		await get_tree().process_frame


## Runs a cutscene, keeping the player still until it's done.
func run_cutscene(cutscene: Callable) -> void:
	_cutscene_running = true
	Game.busy = true
	await cutscene.call()
	Game.busy = false
	_cutscene_running = false


## Adds a character to the area at `at` and returns it.
func add_character(character: Character, at: Vector2) -> Character:
	character.position = at
	world.add_child(character)
	return character


## Adds someone Elric can talk to. `talk` runs when Elric presses Z next to them.
func add_npc(who: String, at: Vector2, talk: Callable) -> Character:
	var npc := Cast.make(who)
	npc.on_interact = func() -> void:
		npc.face(player.position - npc.position)
		await talk.call()
	return add_character(npc, at)


## The usual way to talk to someone: `first` the first time,
## then each list in `repeats` in turn on later visits.
func chat(id: String, first: Array, repeats: Array) -> void:
	var count := int(Game.flags.get("talks_" + id, 0))
	Game.flags["talks_" + id] = count + 1
	if count == 0 or repeats.is_empty():
		await Game.dialogue.say(first)
	else:
		await Game.dialogue.say(repeats[(count - 1) % repeats.size()])


## Gently walks Elric back a step (used when they try to leave too early).
func push_player(offset: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(player, "position", player.position + offset, 0.25)
	await tween.finished


# --- Rooms and doors --------------------------------------------------------

## Keeps the camera inside the room Elric is standing in (if the area has rooms).
func fit_camera_to_room() -> void:
	var bounds := Rect2(Vector2.ZERO, room.pixel_size())
	for r in rooms:
		if r.has_point(player.position):
			bounds = r
			break
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	camera.reset_smoothing()


## Moves Elric (and anyone following) to `to`, with a quick fade, like walking through a door.
func go_through_door(to: Vector2) -> void:
	await Game.fade_out(0.2)
	teleport_player(to)
	await Game.fade_in(0.2)


## Moves Elric (and followers) instantly, keeping everyone in the same formation.
func teleport_player(to: Vector2) -> void:
	var offset := to - player.position
	player.position = to
	for i in player.trail.size():
		player.trail[i] += offset
	for node in world.get_children():
		var character := node as Character
		if character and character.follow == player:
			character.position += offset
	fit_camera_to_room()


# --- Wandering enemies ------------------------------------------------------

## An enemy walking back and forth between `from` and `to`. Touching it starts the
## battle `battle_id`. Once it's been beaten or spared, it doesn't come back.
func add_roamer(sprite_name: String, battle_id: String, from: Vector2, to: Vector2) -> Character:
	if flag("beat_" + battle_id):
		return null
	var roamer := add_character(Cast.make(sprite_name, false), from)
	roamer.set_meta("battle", battle_id)
	roamer.patrol(from, to)
	return roamer


## Call from _physics_process: starts a battle if Elric touches a wandering enemy.
func check_roamers(scene_path: String) -> void:
	for node in world.get_children():
		var roamer := node as Character
		if roamer and roamer.has_meta("battle") and roamer.position.distance_to(player.position) < 20.0:
			var battle_id: String = roamer.get_meta("battle")
			roamer.remove_meta("battle")
			run_cutscene(func() -> void:
				await Game.start_battle(battle_id, scene_path, player.position))
			return


## Call at the start of the area: if we just came back from a wandering enemy's
## battle, say how it went (random fights stay quiet). Returns true if we did.
func handle_battle_return(goodbyes: Dictionary) -> bool:
	var battle_id: String = Game.battle_result.get("id", "")
	if battle_id == "":
		return false
	# (Game.finish_battle already marked a bumped-into enemy as beaten.)
	var random: bool = Game.battle_result.get("random", false)
	var spared: bool = not Game.battle_result.get("spared", []).is_empty()
	Game.battle_result = {}
	if not random and goodbyes.has(battle_id):
		await Game.dialogue.say([goodbyes[battle_id][0 if spared else 1]])
	return true


# --- Random encounters -------------------------------------------------------

## Places where random fights can happen: each entry is [room Rect2, [battle names]]
## or [room Rect2, {battle name: weight}].
## Walking around inside one of these rooms eventually starts a random fight.
var encounter_zones: Array = []
## How far Elric walks between random fights, in pixels (a random amount in this range).
const ENCOUNTER_DISTANCE := Vector2(450, 850)
var _next_encounter: float = -1.0


## Call from _physics_process: starts a random fight once Elric has walked far enough.
func check_random_encounter(scene_path: String) -> void:
	if encounter_zones.is_empty():
		return
	if _next_encounter < 0.0:
		_next_encounter = player.distance_walked + randf_range(ENCOUNTER_DISTANCE.x, ENCOUNTER_DISTANCE.y)
	if player.distance_walked < _next_encounter:
		return
	for zone in encounter_zones:
		if (zone[0] as Rect2).has_point(player.position):
			_next_encounter = -1.0
			var battle_id := _pick_encounter(zone[1])
			run_cutscene(func() -> void:
				# A "!" pops up over Elric, like in Undertale.
				player.show_alert(true)
				await get_tree().create_timer(0.45).timeout
				await Game.start_battle(battle_id, scene_path, player.position, true))
			return


## Picks a fight from a zone's list. A list is "all equally likely"; a Dictionary
## gives each fight a weight (bigger = more common), like {"pop_quiz": 3, "tent": 1}.
func _pick_encounter(options) -> String:
	if options is Array:
		return options.pick_random()
	var total := 0
	for id in options:
		total += int(options[id])
	var roll := randi() % total
	for id in options:
		roll -= int(options[id])
		if roll < 0:
			return id
	return options.keys()[0]


# --- Effects ------------------------------------------------------------------

## Shakes the camera for a moment (explosions, big hits).
func shake(strength: float = 6.0, duration: float = 0.4) -> void:
	var tween := create_tween()
	var steps := int(duration / 0.04)
	for i in steps:
		var fade := 1.0 - float(i) / steps
		tween.tween_property(camera, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * fade, 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)


# --- Storage boxes ------------------------------------------------------------

## A storage box. Every box opens the same storage, so items put in one
## can be taken out of any other.
func add_storage_box(at: Vector2) -> Character:
	var box := Character.new().setup(load("res://art/sprites/storage_box.png"))
	box.on_interact = func() -> void:
		if not flag("seen_storage_box"):
			Game.flags["seen_storage_box"] = true
			await Game.dialogue.say([
				"* (A storage box.)",
				"* (Anything you put in here can be taken\n*  out of any other box, anywhere.)",
			])
		await Game.storage.open()
	return add_character(box, at)
