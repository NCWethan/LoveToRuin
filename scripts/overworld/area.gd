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

	var camera := Camera2D.new()
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
