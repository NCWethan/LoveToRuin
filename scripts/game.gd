extends Node
## The "Game" autoload: one copy that lives the whole time the game runs, no matter
## which scene is showing. It remembers the party, items, BOND/EXP and story flags,
## and has helpers every scene uses: dialogue, fades, sounds, battles and saving.

const SAVE_PATH := "user://save.json"
## Automated test runs (started with --script) save here instead, so they can
## never overwrite or delete the player's real save.
const TEST_SAVE_PATH := "user://test_save.json"
const TITLE_SCENE := "res://scenes/title.tscn"
const BATTLE_SCENE := "res://battle.tscn"

## EXP needed to reach each LV (LOVE). LV 1 is the start.
const LV_THRESHOLDS := [0, 10, 30, 70, 120, 200, 300, 500, 800, 1200]

var party: Array[PartyMember] = []
var items: Array[Dictionary] = []
var bond: int = 0
var exp_points: int = 0
## Money, in dollars. Spent at shops.
var money: int = 0

## How many items Elric can carry.
const MAX_ITEMS := 8
## Items kept in storage boxes (every box shares the same storage).
var box_items: Array[Dictionary] = []
const MAX_BOX_ITEMS := 12
## Story progress, e.g. flags["met_hop"] = true.
var flags: Dictionary = {}

## Where the game is saved (see TEST_SAVE_PATH).
var save_path: String = SAVE_PATH

## True while a cutscene, dialogue or menu is running (the player can't walk).
var busy: bool = false
## True while fading between scenes.
var transitioning: bool = false

## Where the player should appear in the next scene (null = the scene's default spot).
var spawn_position = null

# Handing off to and from battles
var pending_battle: String = ""
var battle_result: Dictionary = {}
var return_scene: String = ""
## True if the current battle is a random encounter (not a wandering enemy you bumped into).
var battle_random: bool = false

var dialogue: DialogueBox
var shop: ShopMenu
var bag: BagMenu
var storage: StorageMenu
var settings_menu: CanvasLayer

var _fade: ColorRect
var _objective_banner: CanvasLayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sounds: Dictionary = {}

## Music: two players, so one song can fade out while the next fades in.
const MUSIC_FOLDER := "res://audio/music/"
const MUSIC_VOLUME_DB := -6.0
var _music_players: Array[AudioStreamPlayer] = []
var _music_current: int = 0
var _music_name: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_cmdline_args().has("--script"):
		save_path = TEST_SAVE_PATH
		settings_path = TEST_SETTINGS_PATH
	_add_input_actions()
	get_window().title = "LOVE TO RUIN"

	_make_audio_buses()
	_sounds = Sfx.make_all()
	for i in 2:
		var music_player := AudioStreamPlayer.new()
		music_player.volume_db = -80.0
		music_player.bus = "Music"
		add_child(music_player)
		_music_players.append(music_player)
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.size = Vector2(640, 480)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	layer.add_child(_fade)

	dialogue = DialogueBox.new()
	add_child(dialogue)
	shop = ShopMenu.new()
	bag = BagMenu.new()
	add_child(bag)
	storage = StorageMenu.new()
	add_child(storage)
	add_child(shop)
	_objective_banner = preload("res://scripts/ui/objective_banner.gd").new()
	add_child(_objective_banner)
	settings_menu = preload("res://scripts/ui/settings_menu.gd").new()
	add_child(settings_menu)
	load_settings()

	new_game()


# --- Settings -------------------------------------------------------------
# Kept in their own file, so starting a new game or loading a save never changes them.

const SETTINGS_PATH := "user://settings.cfg"
## Test runs keep their own settings, so they never change the player's.
const TEST_SETTINGS_PATH := "user://test_settings.cfg"
var settings_path: String = SETTINGS_PATH
## music / sound: 0 to 1.  text_speed: 0 slow, 1 normal, 2 fast.
var settings: Dictionary = {"music": 0.8, "sound": 0.8, "text_speed": 1, "fullscreen": false}


## Two audio buses, "Music" and "SFX", so each can have its own volume.
func _make_audio_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")


func load_settings() -> void:
	var file := ConfigFile.new()
	if file.load(settings_path) == OK:
		for key in settings:
			settings[key] = file.get_value("settings", key, settings[key])
	apply_settings()


func save_settings() -> void:
	var file := ConfigFile.new()
	for key in settings:
		file.set_value("settings", key, settings[key])
	file.save(settings_path)


func apply_settings() -> void:
	for bus_name in ["Music", "SFX"]:
		var amount: float = settings["music" if bus_name == "Music" else "sound"]
		var index := AudioServer.get_bus_index(bus_name)
		AudioServer.set_bus_mute(index, amount <= 0.0)
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(amount, 0.001)))
	# (Tests run without a window, so leave the window alone there.)
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)


## How fast text types out, compared to normal (slow, normal or fast).
func text_speed() -> float:
	return [0.55, 1.0, 1.8][clampi(int(settings["text_speed"]), 0, 2)]


## What Elric is trying to do right now (shown in the bag).
func objective() -> String:
	return flags.get("objective", "")


## Changes the objective and shows the "NEW OBJECTIVE" banner.
func set_objective(text: String) -> void:
	if objective() == text:
		return
	flags["objective"] = text
	_objective_banner.show_objective(text)


## Resets everything to the very start of the game.
func new_game() -> void:
	party = TutorialBattle.create_party()
	items = TutorialBattle.create_items()
	bond = 0
	exp_points = 0
	money = 20
	box_items.clear()
	flags = {}
	busy = false
	spawn_position = null
	pending_battle = ""
	battle_result = {}


## LOVE (LV), worked out from EXP like in Undertale.
func lv() -> int:
	var level := 1
	for i in LV_THRESHOLDS.size():
		if exp_points >= LV_THRESHOLDS[i]:
			level = i + 1
	return level


func heal_party() -> void:
	for member in party:
		member.hp = member.max_hp


# --- Music ----------------------------------------------------------------

## Plays a song from audio/music/ (by name, like "battle"), fading out whatever was
## playing. Does nothing if that song is already playing. "" means silence.
func play_music(song: String, fade_time: float = 0.6) -> void:
	if song == _music_name:
		return
	_music_name = song
	var old := _music_players[_music_current]
	_fade_music(old, -80.0, fade_time, true)
	if song == "":
		return
	var path := MUSIC_FOLDER + song + ".res"
	if not ResourceLoader.exists(path):
		push_warning("No music called " + song)
		return
	_music_current = 1 - _music_current
	var new := _music_players[_music_current]
	new.stream = load(path)
	new.volume_db = -40.0
	new.play()
	_fade_music(new, MUSIC_VOLUME_DB, fade_time, false)


func stop_music(fade_time: float = 0.6) -> void:
	play_music("", fade_time)


func _fade_music(player: AudioStreamPlayer, to_db: float, time: float, stop_after: bool) -> void:
	# Cancel any fade already happening on this player, so an old fade-out
	# can't stop a song that just started.
	if player.has_meta("fade"):
		(player.get_meta("fade") as Tween).kill()
	var tween := create_tween()
	player.set_meta("fade", tween)
	tween.tween_property(player, "volume_db", to_db, time)
	if stop_after:
		tween.tween_callback(player.stop)


# --- Sounds ---------------------------------------------------------------

func play_sfx(sound: String, pitch: float = 1.0) -> void:
	if not _sounds.has(sound):
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = _sounds[sound]
			player.pitch_scale = pitch
			player.play()
			return


# --- Scene changes --------------------------------------------------------

func fade_out(time: float = 0.4) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, time)
	await tween.finished


func fade_in(time: float = 0.4) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 0.0, time)
	await tween.finished


## Fades to black, switches scenes, and fades back in.
## `spawn` is where the player appears in the new scene (or null for its default).
func change_scene(path: String, spawn = null) -> void:
	# Already changing scenes? Ignore the extra request (e.g. Z pressed twice).
	if transitioning:
		return
	transitioning = true
	await fade_out()
	spawn_position = spawn
	get_tree().change_scene_to_file(path)
	# The new scene loads on the next frame; give it a moment to set itself up.
	await get_tree().process_frame
	await get_tree().process_frame
	await fade_in()
	transitioning = false


# --- Battles --------------------------------------------------------------

## Leaves the overworld for a battle. Afterwards the player comes back to `at` in `from_scene`.
func start_battle(battle_id: String, from_scene: String, at: Vector2, random: bool = false) -> void:
	busy = true
	play_sfx("encounter")
	pending_battle = battle_id
	battle_random = random
	return_scene = from_scene
	battle_result = {}
	await change_scene(BATTLE_SCENE, at)


## Called by the battle when it's won. Adds the rewards and goes back to the overworld.
func finish_battle(result: Dictionary) -> void:
	battle_result = result
	battle_result["random"] = battle_random
	# A wandering enemy (or boss) you fought is gone for good. Marking it now,
	# before the area reloads, keeps it from popping back up.
	if not battle_random and not result.get("fled", false):
		flags["beat_" + str(result.get("id", ""))] = true
	battle_random = false
	bond += int(result.get("bond", 0))
	exp_points += int(result.get("exp", 0))
	money += int(result.get("money", 0))
	pending_battle = ""
	# Anyone knocked down gets back up with a little HP, like in Deltarune.
	for member in party:
		if member.is_down():
			member.hp = maxi(1, member.max_hp / 4)
	busy = false
	# (Falls back to the title screen if nobody said where to go back to.)
	await change_scene(return_scene if return_scene != "" else TITLE_SCENE, spawn_position)


## After a GAME OVER: go back to the last save, or start over if there isn't one.
func continue_after_game_over() -> void:
	pending_battle = ""
	if has_save():
		await load_game()
	else:
		new_game()
		await change_scene(TITLE_SCENE)


# --- Saving and loading ---------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game(scene_path: String, at: Vector2) -> void:
	var data := {
		"scene": scene_path,
		"x": at.x,
		"y": at.y,
		"flags": flags,
		"bond": bond,
		"exp": exp_points,
		"money": money,
		"items": items,
		"box_items": box_items,
		"party": party.map(func(m: PartyMember) -> Dictionary: return {"name": m.name, "hp": m.hp}),
	}
	# Write to a temporary file first, then swap it in, so the old save is never
	# left half-written if the game closes mid-save.
	var temp_path := save_path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save the game.")
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(save_path))


## A short summary of the save file for the title screen, or "" if there's none.
func save_summary() -> String:
	var data := _read_save()
	if data.is_empty():
		return ""
	var level := 1
	for i in LV_THRESHOLDS.size():
		if int(data.get("exp", 0)) >= LV_THRESHOLDS[i]:
			level = i + 1
	var place: String = AREA_NAMES.get(data.get("scene", ""), "")
	return "Elric   LV %d   BOND %d   -   %s" % [level, int(data.get("bond", 0)), place]


## The name of each area, for save messages and the title screen.
const AREA_NAMES := {
	"res://scenes/mt_carmel.tscn": "Mt. Carmel",
	"res://scenes/pq_mall.tscn": "PQ Mall",
	"res://scenes/westview.tscn": "Westview High",
	"res://scenes/hilltop.tscn": "Westview Field",
}


## What a SAVE point says after saving. The very first time, it also explains
## how saving works.
func saved_lines() -> Array:
	var data := _read_save()
	var lines: Array = ["* (File saved.  %s)" % AREA_NAMES.get(data.get("scene", ""), "")]
	if not flags.get("save_tip_seen", false):
		flags["save_tip_seen"] = true
		lines.append("* (Your game is only saved at SAVE points like this one.\n*  Choose Continue on the title screen to come back here.)")
		# Save once more so the tip is remembered too.
		save_game(data.get("scene", ""), Vector2(data.get("x", 0.0), data.get("y", 0.0)))
	return lines


func load_game() -> void:
	var data := _read_save()
	if data.is_empty():
		return
	new_game()
	flags = data.get("flags", {})
	bond = int(data.get("bond", 0))
	exp_points = int(data.get("exp", 0))
	money = int(data.get("money", 0))
	items.clear()
	for item in data.get("items", []):
		items.append({"name": item["name"], "heal": int(item["heal"])})
	box_items.clear()
	for item in data.get("box_items", []):
		box_items.append({"name": item["name"], "heal": int(item["heal"])})
	for saved in data.get("party", []):
		for member in party:
			if member.name == saved["name"]:
				member.hp = int(saved["hp"])
	var scene: String = data.get("scene", "")
	if not ResourceLoader.exists(scene):
		scene = "res://scenes/mt_carmel.tscn"
	await change_scene(scene, Vector2(float(data.get("x", 130.0)), float(data.get("y", 470.0))))


func _read_save() -> Dictionary:
	if not has_save():
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	return parsed if parsed is Dictionary else {}


# --- Controls -------------------------------------------------------------

## Enter confirms, X / Shift goes back, and B opens the bag.
func _add_input_actions() -> void:
	_add_keys("confirm", [KEY_ENTER, KEY_KP_ENTER])
	_add_keys("cancel", [KEY_X, KEY_SHIFT])
	_add_keys("menu", [KEY_B])
	# WASD works for moving (and for menus) as well as the arrow keys.
	var wasd := {"ui_up": KEY_W, "ui_left": KEY_A, "ui_down": KEY_S, "ui_right": KEY_D}
	for action in wasd:
		var event := InputEventKey.new()
		event.physical_keycode = wasd[action]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


func _add_keys(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
