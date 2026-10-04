extends Node
## The "Game" autoload: one copy that lives the whole time the game runs, no matter
## which scene is showing. It remembers the party, items, BOND/EXP and story flags,
## and has helpers every scene uses: dialogue, fades, sounds, battles and saving.

const SAVE_PATH := "user://save.json"
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
## Story progress, e.g. flags["met_hop"] = true.
var flags: Dictionary = {}

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

var dialogue: DialogueBox
var shop: ShopMenu

var _fade: ColorRect
var _sfx_players: Array[AudioStreamPlayer] = []
var _sounds: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_add_input_actions()

	_sounds = Sfx.make_all()
	for i in 8:
		var player := AudioStreamPlayer.new()
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
	add_child(shop)

	new_game()


## Resets everything to the very start of the game.
func new_game() -> void:
	party = TutorialBattle.create_party()
	items = TutorialBattle.create_items()
	bond = 0
	exp_points = 0
	money = 20
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
func start_battle(battle_id: String, from_scene: String, at: Vector2) -> void:
	busy = true
	play_sfx("encounter")
	pending_battle = battle_id
	return_scene = from_scene
	battle_result = {}
	await change_scene(BATTLE_SCENE, at)


## Called by the battle when it's won. Adds the rewards and goes back to the overworld.
func finish_battle(result: Dictionary) -> void:
	battle_result = result
	bond += int(result.get("bond", 0))
	exp_points += int(result.get("exp", 0))
	money += int(result.get("money", 0))
	pending_battle = ""
	# Anyone knocked down gets back up with a little HP, like in Deltarune.
	for member in party:
		if member.is_down():
			member.hp = maxi(1, member.max_hp / 4)
	busy = false
	await change_scene(return_scene, spawn_position)


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
	return FileAccess.file_exists(SAVE_PATH)


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
		"party": party.map(func(m: PartyMember) -> Dictionary: return {"name": m.name, "hp": m.hp}),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  "))


## A short summary of the save file for the title screen, or "" if there's none.
func save_summary() -> String:
	var data := _read_save()
	if data.is_empty():
		return ""
	var level := 1
	for i in LV_THRESHOLDS.size():
		if int(data.get("exp", 0)) >= LV_THRESHOLDS[i]:
			level = i + 1
	return "Elric   LV %d   BOND %d" % [level, int(data.get("bond", 0))]


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
	for saved in data.get("party", []):
		for member in party:
			if member.name == saved["name"]:
				member.hp = int(saved["hp"])
	await change_scene(data["scene"], Vector2(data["x"], data["y"]))


func _read_save() -> Dictionary:
	if not has_save():
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	return parsed if parsed is Dictionary else {}


# --- Controls -------------------------------------------------------------

## Z / Enter confirms, X / Shift goes back, like in Undertale.
func _add_input_actions() -> void:
	_add_keys("confirm", [KEY_Z, KEY_ENTER, KEY_KP_ENTER])
	_add_keys("cancel", [KEY_X, KEY_SHIFT])


func _add_keys(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
