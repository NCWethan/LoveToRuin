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
## battle, mark it as beaten and say how it went. Returns true if that happened.
func handle_battle_return(goodbyes: Dictionary) -> bool:
	var battle_id: String = Game.battle_result.get("id", "")
	if battle_id == "" or flag("beat_" + battle_id):
		return false
	Game.flags["beat_" + battle_id] = true
	var spared: bool = not Game.battle_result.get("spared", []).is_empty()
	Game.battle_result = {}
	if goodbyes.has(battle_id):
		await Game.dialogue.say([goodbyes[battle_id][0 if spared else 1]])
	return true


# --- Effects ------------------------------------------------------------------

## Shakes the camera for a moment (explosions, big hits).
func shake(strength: float = 6.0, duration: float = 0.4) -> void:
	var tween := create_tween()
	var steps := int(duration / 0.04)
	for i in steps:
		var fade := 1.0 - float(i) / steps
		tween.tween_property(camera, "offset", Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength * fade, 0.04)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)
