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
## Sounds that are recordings rather than made in code. To swap one, replace the file.
## relic_wind: a wind recording ("No Copyright" sound effect), kept out of the public
## repo until its license is confirmed. Without it, the tent uses wind made in code.
const SOUND_FILES := {"ronin_riff": "res://audio/sfx/ronin_riff.wav", "relic_wind": "res://audio/sfx/relic_wind.mp3"}

## Music: two players, so one song can fade out while the next fades in.
const MUSIC_FOLDER := "res://audio/music/"
const MUSIC_VOLUME_DB := -6.0
var _music_players: Array[AudioStreamPlayer] = []
var _music_current: int = 0
var _music_name: String = ""
## How fast (and how low) the music plays: slowed down in the overworld on the
## Genocide path (see Area). Battles set it back to 1.
## If set, this song plays instead of whatever an area asks for (the Genocide song;
## see Area). Battles and scene changes clear it.
var music_override: String = ""
var music_pitch: float = 1.0:
	set(value):
		music_pitch = value
		for player in _music_players:
			player.pitch_scale = value


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_cmdline_args().has("--script"):
		save_path = TEST_SAVE_PATH
		settings_path = TEST_SETTINGS_PATH
	_add_input_actions()
	get_window().title = "LOVE TO RUIN"

	_make_audio_buses()
	_sounds = Sfx.make_all()
	# Recorded sounds, from audio/sfx (most sounds are made in code, see sfx.gd).
	for sound in SOUND_FILES:
		if ResourceLoader.exists(SOUND_FILES[sound]):
			_sounds[sound] = load(SOUND_FILES[sound])
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
var settings: Dictionary = {"music": 0.8, "sound": 0.8, "text_speed": 1, "fullscreen": false, "reduce_flashing": false}


## "Reduce flashing" (in Settings): fewer, gentler flashes and no strobing, for
## anyone sensitive to flashing lights.
func reduce_flashing() -> bool:
	return settings.get("reduce_flashing", false)

## Things that are remembered even after you RESET (kept with the settings, not
## the save). Hopkuna has DETERMINATION too: he notices.
## resets: how many times a save file has been erased.
## met_hopkuna: whether you've ever seen him wake up.
## last_answer: how you told him you'd do it, the last time ("talk", "fight",
##   "unsure", or "" if you never got that far).
var resets: int = 0
var met_hopkuna: bool = false
var last_answer: String = ""


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
		resets = file.get_value("memory", "resets", 0)
		met_hopkuna = file.get_value("memory", "met_hopkuna", false)
		last_answer = file.get_value("memory", "last_answer", "")
	apply_settings()


func save_settings() -> void:
	var file := ConfigFile.new()
	for key in settings:
		file.set_value("settings", key, settings[key])
	file.set_value("memory", "resets", resets)
	file.set_value("memory", "met_hopkuna", met_hopkuna)
	file.set_value("memory", "last_answer", last_answer)
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
	# Just Elric, until they meet Hop (see _build_partner).
	party = TutorialBattle.create_party()
	party.resize(1)
	items = TutorialBattle.create_items()
	bond = 0
	exp_points = 0
	money = 20
	box_items.clear()
	equipment = {}
	flags = {}
	busy = false
	spawn_position = null
	pending_battle = ""
	battle_result = {}
	update_stats()


## LOVE (LV), worked out from EXP like in Undertale.
func lv() -> int:
	var level := 1
	for i in LV_THRESHOLDS.size():
		if exp_points >= LV_THRESHOLDS[i]:
			level = i + 1
	return level


## LV for a given amount of EXP.
func lv_for(exp_amount: int) -> int:
	var level := 1
	for i in LV_THRESHOLDS.size():
		if exp_amount >= LV_THRESHOLDS[i]:
			level = i + 1
	return level


# --- BOND level, stats and accessories -------------------------------------
# Growing comes two ways. EXP (from fighting) raises your LV; BOND (from sparing)
# raises your BOND level. Both make the whole party stronger: LV gives more attack,
# BOND more HP. Neither raises defense: only accessories do.

const BOND_THRESHOLDS := [0, 20, 50, 100, 170, 260, 380, 530, 720, 950]
## Each member's starting max HP and attack.
const BASE_STATS := {"Elric": [30, 6], "Hop": [35, 7],
	# REVOLUTION Corps members, when they come along instead of Hop (see partner()).
	"BigJoe6": [44, 5], "Eggo": [32, 6], "Nassan": [30, 5], "Nat": [28, 5], "NCWethan": [34, 8],
	"Ronin": [30, 7], "Supreme": [28, 5], "Crayola": [26, 4], "Rooster": [30, 6], "Agent": [28, 6],
	"MuffinMage": [36, 6], "Sansworth": [32, 5]}
## What each level adds, for every party member.
const HP_PER_LV := 3
const ATTACK_PER_LV := 2
const HP_PER_BOND_LV := 4
const ATTACK_PER_BOND_LV := 1

## Accessory slots. Each member can wear one item in each.
## Where accessories go. "card" holds one of Old Man Pip's cards (see
## Items.CARDS), each with its own power instead of stats.
const SLOTS := ["weapon", "torso", "shoes", "card"]
const SLOT_NAMES := {"weapon": "Weapon", "torso": "Torso", "shoes": "Shoes", "card": "Card"}
## What everyone's wearing: {member name: {slot: item}}.
var equipment: Dictionary = {}


func bond_level_for(bond_amount: int) -> int:
	var level := 1
	for i in BOND_THRESHOLDS.size():
		if bond_amount >= BOND_THRESHOLDS[i]:
			level = i + 1
	return level


func bond_level() -> int:
	return bond_level_for(bond)


## The EXP needed for the next LV, or -1 at the top level.
func next_lv_exp() -> int:
	var level := lv()
	return LV_THRESHOLDS[level] if level < LV_THRESHOLDS.size() else -1


## The BOND needed for the next BOND level, or -1 at the top level.
func next_bond() -> int:
	var level := bond_level()
	return BOND_THRESHOLDS[level] if level < BOND_THRESHOLDS.size() else -1


## Works out everyone's max HP, attack and defense from their levels and what
## they're wearing. Growing taller max HP also heals by the same amount.
func update_stats() -> void:
	for member in party:
		var base: Array = BASE_STATS.get(member.id, [member.max_hp, member.attack])
		var new_max: int = base[0] + HP_PER_LV * (lv() - 1) + HP_PER_BOND_LV * (bond_level() - 1)
		var attack: int = base[1] + ATTACK_PER_LV * (lv() - 1) + ATTACK_PER_BOND_LV * (bond_level() - 1)
		var defense := 0
		for item in worn_by(member.name).values():
			attack += int(item.get("atk", 0))
			defense += int(item.get("def", 0))
		if new_max > member.max_hp:
			member.hp += new_max - member.max_hp
		member.max_hp = new_max
		member.hp = mini(member.hp, member.max_hp)
		member.attack = attack
		member.defense = defense


# --- The team ------------------------------------------------------------
# Elric always goes, and one partner comes along (in battle and walking around).
# In Chapter 1 that's Hop. Once you've been to the Corps' base, any Corps member
# can come instead, but the team can only be changed at the base (in the bag).

## Who's coming along with Elric: "Hop", or a Corps member's id ("BigJoe6").
func partner() -> String:
	return flags.get("partner", "Hop")


## After the Westview Field choice, the city is seen by day: once Elric has been
## to the Corps' base, or (going their own way) after wandering till morning.
## (Not on the Genocide route.)
func daytime() -> bool:
	if not flags.get("chapter1_done", false) or flags.get("route", "") == "genocide":
		return false
	return flags.get("base_arrived", false) or flags.get("morning_after", false)


## Going their own way, Elric travels alone (Hop stayed with the Corps) until they
## go down to the Corps' base.
func walking_alone() -> bool:
	return flags.get("route", "") == "neutral" and not flags.get("base_arrived", false)


## Everyone who could come along right now.
func team_choices() -> Array:
	var choices: Array = ["Hop"]
	if flags.get("base_arrived", false):
		choices.append_array(load("res://scripts/helpers.gd").CORPS)
	return choices


## Joined the REVOLUTION Corps (the Pacifist route): friends can be called into fights.
func joined_corps() -> bool:
	return flags.get("route", "") == "pacifist"


func set_partner(id: String) -> void:
	flags["partner"] = id
	_build_partner()
	heal_party()


## Puts the partner into the party (after Elric), with their stats.
func _build_partner() -> void:
	# Nobody comes along until Elric meets Hop.
	if not flags.get("met_hop", false):
		if party.size() > 1:
			party.resize(1)
		update_stats()
		return
	var id := partner()
	if party.size() > 1 and party[1].id == id:
		return
	var colors := {"Hop": Color(0.75, 0.75, 0.75)}
	var helpers: Dictionary = load("res://scripts/helpers.gd").HELPERS
	var color: Color = colors.get(id, helpers.get(id, {}).get("color", Color.WHITE))
	var member := PartyMember.new(DialogueBox.display_name(id), 30, 5, color, load("res://art/sprites/%s.png" % id.to_lower()))
	member.id = id
	if party.size() > 1:
		party[1] = member
	else:
		party.append(member)
	update_stats()


## The name of the card a member holds ("" for none).
func card_of(member_name: String) -> String:
	return str(worn_by(member_name).get("card", {}).get("name", ""))


## Does anyone in the party hold this card?
func party_has_card(card: String) -> bool:
	for member in party:
		if card_of(member.name) == card:
			return true
	return false


## {slot: item} for everything one member is wearing.
func worn_by(member_name: String) -> Dictionary:
	return equipment.get(member_name, {})


## Puts an accessory from the bag on a member. Whatever they had in that slot
## goes back in the bag. Returns the item they took off (or an empty Dictionary).
func equip(member_name: String, item: Dictionary) -> Dictionary:
	var slot: String = item["slot"]
	var worn := worn_by(member_name)
	var old: Dictionary = worn.get(slot, {})
	items.erase(item)
	if not old.is_empty():
		items.append(old)
	worn[slot] = item
	equipment[member_name] = worn
	update_stats()
	return old


## Takes an accessory off a member and puts it back in the bag. Returns false if
## the bag is full (then nothing changes).
func unequip(member_name: String, slot: String) -> bool:
	var worn := worn_by(member_name)
	if not worn.has(slot):
		return true
	if items.size() >= MAX_ITEMS:
		return false
	items.append(worn[slot])
	worn.erase(slot)
	equipment[member_name] = worn
	update_stats()
	return true


func heal_party() -> void:
	for member in party:
		member.hp = member.max_hp


# --- Music ----------------------------------------------------------------

## Plays a song from audio/music/ (by name, like "battle"), fading out whatever was
## playing. Does nothing if that song is already playing. "" means silence.
func play_music(song: String, fade_time: float = 0.6) -> void:
	if music_override != "" and song != "":
		song = music_override
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
	new.pitch_scale = music_pitch
	new.volume_db = -40.0
	new.play()
	_fade_music(new, MUSIC_VOLUME_DB, fade_time, false)


## The name of the song playing now ("" for silence).
func current_music() -> String:
	return _music_name


## How many seconds into the current song we are (for things that move to the
## beat), or -1.0 if nothing is playing.
func music_time() -> float:
	var player := _music_players[_music_current]
	if _music_name == "" or not player.playing:
		return -1.0
	return player.get_playback_position() + AudioServer.get_time_since_last_mix()


## Turns the music way down (or back up), e.g. while Ronin plays his riff.
func duck_music(on: bool) -> void:
	_fade_music(_music_players[_music_current], MUSIC_VOLUME_DB - (30.0 if on else 0.0), 0.5, false)


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

## Plays a sound. `start` skips into it (in seconds); `boost_db` makes it louder.
func play_sfx(sound: String, pitch: float = 1.0, start: float = 0.0, boost_db: float = 0.0) -> void:
	if not _sounds.has(sound):
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = _sounds[sound]
			player.pitch_scale = pitch
			player.volume_db = boost_db
			player.play(start)
			return


func has_sfx(sound: String) -> bool:
	return _sounds.has(sound)


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
	# Normal music unless the new scene says otherwise (see Area, Genocide).
	music_pitch = 1.0
	music_override = ""
	get_tree().change_scene_to_file(path)
	# Whatever was going on in the old scene (a cutscene, a conversation) is gone
	# now, and it can't finish to say so. Start the new scene free to move; its own
	# cutscenes only begin once the fade-in is done.
	busy = false
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


## How far down the Genocide path Elric has gone, from 0 to 3, by how many enemies
## they've defeated instead of sparing (or 3 once they've gone with Hop). It changes
## how Elric looks (sprite_base), how the world looks (Area), and how people act.
const DREAD_KILLS := [8, 20, 40, 75]


## Elric chose to go with Hop (Hopkuna) at the end of Chapter 1. Killing a lot
## before then raises dread() too, but things that only happen once everyone
## has turned away (empty shops, Relic saying "we") wait for the route itself.
func on_genocide_route() -> bool:
	return flags.get("route", "") == "genocide"


## (1: green eyes. 2: halfway. 3: nearly gone. 4: Relic, in the flesh.) The Genocide route
## starts halfway; only the very end of the killing makes Elric into Relic.
func dread() -> int:
	var kills := int(flags.get("kills", 0))
	var stage := 0
	for needed in DREAD_KILLS:
		if kills >= needed:
			stage += 1
	if flags.get("route", "") == "genocide":
		stage = maxi(stage, 2)
	return stage


## The start of a character's picture file names: "hop" for Hop, and for Elric
## "elric", or "elric_dread1" to "elric_dread4" (Relic) as they get worse.
func sprite_base(who: String) -> String:
	if who == "Elric" and dread() > 0:
		return "elric_dread%d" % dread()
	return who.to_lower()


## Called by the battle when it's won. Adds the rewards and goes back to the overworld.
func finish_battle(result: Dictionary) -> void:
	battle_result = result
	battle_result["random"] = battle_random
	# A wandering enemy (or boss) you fought is gone for good. Marking it now,
	# before the area reloads, keeps it from popping back up.
	if not battle_random and not result.get("fled", false):
		flags["beat_" + str(result.get("id", ""))] = true
	battle_random = false
	# Only real kills count (see dread()): someone who shattered. Knockouts (the
	# tutorial, the training dummy, bosses) don't.
	flags["kills"] = int(flags.get("kills", 0)) + result.get("killed", []).size()
	# The glowbug, on the way to Hop's house: killing it is what starts the
	# Genocide route, officially.
	if result.get("id", "") == "glowbug" and not result.get("defeated", []).is_empty():
		flags["route"] = "genocide"
	# Someone you challenged (townsfolk.gd): gone for good, or they remember you spared them.
	var fight_id := str(result.get("id", ""))
	if fight_id.begins_with("person_") and not result.get("fled", false):
		if not result.get("defeated", []).is_empty():
			flags["killed_" + fight_id] = true
		elif not result.get("spared", []).is_empty():
			flags["spared_" + fight_id] = true
	bond += int(result.get("bond", 0))
	exp_points += int(result.get("exp", 0))
	money += int(result.get("money", 0))
	# More EXP or BOND can mean a new level: bigger max HP and attack.
	update_stats()
	pending_battle = ""
	# Anyone knocked down gets back up with a little HP, like in Deltarune.
	# (And overheal from the fight wears off.)
	for member in party:
		member.overheal = 0
		member.overheal_purple = 0
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


## Erases the save file (the title screen's Reset). Settings are kept.
func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		# Everyone forgets. Almost everyone.
		resets += 1
		save_settings()
	new_game()


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
		"equipment": equipment,
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
	"res://scenes/hop_house.tscn": "Hop's House",
	"res://scenes/corps_base.tscn": "REVOLUTION Base",
}


## What a SAVE point says about healing: just Elric when they're on their own
## (before meeting Hop, or after going their own way), otherwise everyone.
func restored_line() -> String:
	var alone: bool = not flags.get("met_hop", false) or flags.get("route", "") == "neutral"
	return "* (Your HP has been restored.)" if alone else "* (Everyone's HP was restored.)"


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
		items.append(_item_from_save(item))
	box_items.clear()
	for item in data.get("box_items", []):
		box_items.append(_item_from_save(item))
	equipment = {}
	var worn: Dictionary = data.get("equipment", {})
	for member_name in worn:
		equipment[member_name] = {}
		for slot in worn[member_name]:
			equipment[member_name][slot] = _item_from_save(worn[member_name][slot])
	# The team (who's coming along), then levels and accessories, then the HP they
	# had when they saved.
	_build_partner()
	update_stats()
	for saved in data.get("party", []):
		for member in party:
			if member.name == saved["name"]:
				member.hp = clampi(int(saved["hp"]), 0, member.max_hp)
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
	_add_keys("sprint", [KEY_SHIFT])
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


## An item read back from the save file. JSON turns every number into a decimal,
## so the stats are turned back into whole numbers.
func _item_from_save(saved: Dictionary) -> Dictionary:
	var item := {"name": str(saved.get("name", "???")), "heal": int(saved.get("heal", 0))}
	if saved.has("slot"):
		item["slot"] = str(saved["slot"])
		item["atk"] = int(saved.get("atk", 0))
		item["def"] = int(saved.get("def", 0))
	return item
