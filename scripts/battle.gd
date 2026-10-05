extends Node2D
## Runs a battle, Deltarune-style:
##   1. Each party member picks FIGHT, ACT, ITEM, MERCY or DEFEND.
##   2. Their actions play out.
##   3. The enemies attack, and the SOUL dodges inside the box.
##   4. Repeat until every enemy is spared or knocked out.
##
## The fighters and their lines come from tutorial_battle.gd.
## Controls: arrow keys to move, Enter to confirm, X / Shift to go back.

enum State { TEXT, MENU, TARGET_ENEMY, ACT_LIST, ITEM_LIST, TARGET_PARTY, MERCY_MENU, READY, FIGHT_BAR, FIGHT_ANIM, ENEMY_TURN, GAME_OVER, EVENT, FLEEING, CALL_LIST, CALLING, DONE }

const BUTTONS := ["FIGHT", "ACT", "ITEM", "MERCY", "DEFEND"]

## The box is wide while showing text, and small while dodging.
const BOX_CENTER := Vector2(320, 320)
const TEXT_BOX_SIZE := Vector2(570, 120)
const ATTACK_BOX_SIZE := Vector2(160, 120)

## How long each enemy turn lasts, in seconds.
const ENEMY_TURN_TIME := 5.0
## How long the FIGHT bar takes to cross the box, in seconds.
const FIGHT_BAR_TIME := 1.6
## How long "READY..." shows before the FIGHT bar starts moving, in seconds.
const FIGHT_WINDUP := 0.7
## A hit this accurate (0 to 1) counts as a CRITICAL.
const CRITICAL := 0.9
## How long the slash takes to cross the enemy before the hit lands, in seconds.
const ATTACK_SLASH_TIME := 0.35
## How fast text appears, in letters per second.
const TYPE_SPEED := 45.0
const FONT_SIZE := 16
const LINE_HEIGHT := 22

const BUTTON_Y := 436.0
const BUTTON_SIZE := Vector2(108, 32)
const BUTTON_SPACING := 122.0
const PANEL_Y := 410.0

const ORANGE := Color(1.0, 0.5, 0.0)
const YELLOW := Color(1.0, 1.0, 0.0)

## After getting hit, how long the SOUL can't be hurt again, in seconds.
@export var invincibility_time: float = 1.0

## The fight being played (enemies, intro text, turn text). See battles.gd.
var _data: BattleData
var party: Array[PartyMember] = []
var enemies: Array[Enemy] = []
var items: Array[Dictionary] = []
var bond_gained: int = 0
var exp_gained: int = 0

var state: State = State.TEXT
var turn: int = 0
var enemy_turn: int = 0

## Which party member is choosing right now (index into `party`).
var current_member: int = 0
## The actions chosen this turn, one Dictionary per party member.
var actions: Array[Dictionary] = []

var _button: int = 0          # highlighted button in the menu
var _cursor: int = 0          # highlighted row in a list
var _list: Array = []         # what the current list contains
var _pending: String = ""     # the button picked before choosing a target
var _act_target: Enemy
var _chosen_item: Dictionary

# Text box
var _messages: Array = []
var _on_messages_done: Callable
var _text: String = ""
var _typed: float = 0.0
var _flavor: String = ""

# Running the chosen actions
var _action_index: int = -1

# FIGHT bar
var _bar_pos: float = 0.0
var _bar_member: PartyMember
var _bar_target: Enemy
var _bar_wait: float = 0.0
## Which way the FIGHT bar moves: 1 = left to right, -1 = right to left.
var _bar_dir: float = 1.0
## Recent bar positions, drawn as a fading afterimage.
var _bar_trail: Array[float] = []
## Nail File only: three bars cross one after another, each stopped with its own
## press. Each is {"pos": 0..1, "done": bool, "accuracy": float (-1 = missed)}.
## Every bar deals a third of the damage.
var _file_bars: Array[Dictionary] = []
## How far apart the Nail File's bars are (as a fraction of the bar's width).
const FILE_BAR_GAP := 0.24

## Hop's BLACK FLASH (only with the Divergent Glove): a 1 in 20 chance on each hit.
const BLACK_FLASH_CHANCE := 0.05
const BLACK_FLASH_DAMAGE := 2.5
var _black_flash: bool = false
## For tests: the next hit by Hop with the glove is always a Black Flash.
var force_black_flash: bool = false

# The attack animation after the bar is stopped.
var _anim_time: float = 0.0
var _anim_damage: int = 0
var _anim_accuracy: float = 0.0
var _anim_landed: bool = false

# Enemy turn
var _enemy_timer: float = 0.0
var _spawn_timers: Dictionary = {}
var _spawn_steps: Dictionary = {}
## When each enemy last launched an attack this turn (seconds into the turn), for its "throw" animation.
var _last_spawn: Dictionary = {}
var _turn_patterns: Dictionary = {}
## The attack each enemy used last turn, so it doesn't repeat right away.
var _last_patterns: Dictionary = {}
var _attackers: Array[Enemy] = []
var _speech: Dictionary = {}
var _invincible_timer: float = 0.0

## Game time in this battle, and when ENTER will next be accepted in the text box.
var _battle_clock: float = 0.0
var _confirm_ready_at: float = 0.0

## The animation each party member is playing: {member: {"type": "ACT", "time": seconds}}.
var _member_anim: Dictionary = {}

# Floating damage numbers
var _popups: Array[Dictionary] = []

var _overlay: Node2D
var _backdrop: Node2D
var _font: Font

@onready var soul: Soul = $Soul
@onready var box: BattleBox = $BattleBox


func _ready() -> void:
	# Battles happen on a black background, like in Undertale and Deltarune.
	RenderingServer.set_default_clear_color(Color.BLACK)
	_font = ThemeDB.fallback_font

	# Everything except the box and the SOUL (text, menus, enemies, HP) is drawn
	# by this overlay. It's added last so it draws on top of the box.
	_overlay = Node2D.new()
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)

	# The drifting diamond pattern behind the fight (drawn first, behind everything).
	_backdrop = Node2D.new()
	add_child(_backdrop)
	move_child(_backdrop, 0)
	_backdrop.draw.connect(_draw_backdrop)

	if Game.pending_battle != "":
		# Started from the overworld: use the real party and inventory,
		# so HP and used items carry over.
		party = Game.party
		items = Game.items
	else:
		# Started on its own (F6 in the editor): use a fresh party for testing.
		party = TutorialBattle.create_party()
		items = TutorialBattle.create_items()
	# Which fight this is (the tutorial when testing with F6).
	_data = Battles.create(Game.pending_battle if Game.pending_battle != "" else "tutorial")
	# Elric looks how they look in the overworld (worse, the more they've killed).
	for member in party:
		var look := "res://art/sprites/%s.png" % Game.sprite_base(member.id)
		if ResourceLoader.exists(look):
			member.sprite = load(look)
	# Battle music always plays at normal speed (the overworld slows down on Genocide).
	Game.music_pitch = 1.0
	Game.music_override = ""
	Game.play_music(_data.music if _data.music != "" else "battle", 0.2)
	# Some fights only let certain party members join in.
	# (A new list, so the real party in Game isn't changed.)
	if not _data.party_only.is_empty():
		var fighting: Array[PartyMember] = []
		for member in party:
			if member.name in _data.party_only:
				fighting.append(member)
		party = fighting
	enemies = _data.enemies

	box.center = BOX_CENTER
	box.size = TEXT_BOX_SIZE
	soul.can_move = false

	if _data.event == "tent":
		_show_messages(_data.intro, _tent_silence)
	else:
		_show_messages(_data.intro, _start_player_turn if _data.player_first else _start_enemy_turn)


func _process(delta: float) -> void:
	# The tent's red text crawls out slowly.
	_battle_clock += delta
	_typed += delta * TYPE_SPEED * Game.text_speed() * (0.35 if _text_color != Color.WHITE else 1.0)
	_update_effects(delta)
	_text_beeps()

	match state:
		State.TEXT:
			_process_text()
		State.MENU:
			_process_menu()
		State.TARGET_ENEMY, State.ACT_LIST, State.ITEM_LIST, State.TARGET_PARTY, State.MERCY_MENU, State.CALL_LIST:
			_process_list()
		State.CALLING:
			_process_call(delta)
		State.READY:
			_process_ready()
		State.FIGHT_BAR:
			_process_fight_bar(delta)
		State.FIGHT_ANIM:
			_process_fight_anim(delta)
		State.ENEMY_TURN:
			_process_enemy_turn(delta)
		State.GAME_OVER:
			_process_game_over(delta)
		State.EVENT:
			_process_tent(delta)
		State.FLEEING:
			_process_flee(delta)

	_overlay.queue_redraw()
	_backdrop.queue_redraw()


var _last_beep: int = 0

## A little beep every other letter while text types out.
func _text_beeps() -> void:
	var shown := clampi(int(_typed), 0, _text.length())
	if shown < _last_beep:
		_last_beep = 0
	if shown > _last_beep and shown % 2 == 0 and _text[shown - 1] != " ":
		if _text_color == Color.WHITE:
			Game.play_sfx("text")
		else:
			Game.play_sfx("voice", 0.45)
	_last_beep = shown


# --- Text ------------------------------------------------------------------

## Shows each line in the box, one at a time (press Enter for the next), then calls `then`.
func _show_messages(lines: Array, then: Callable) -> void:
	_messages = lines.duplicate()
	_on_messages_done = then
	state = State.TEXT
	soul.visible = false
	_next_message()


func _next_message() -> void:
	if _messages.is_empty():
		_text = ""
		_on_messages_done.call()
		return
	_set_text(_messages.pop_front())


func _set_text(text: String) -> void:
	_text = text
	_typed = 0.0


func _text_finished() -> bool:
	return _typed >= _text.length()


func _process_text() -> void:
	# The same hidden quarter-second pause as the overworld text box, so battle text
	# can't be mashed straight through either.
	if _pressed("confirm") and _battle_clock < _confirm_ready_at:
		return
	if _pressed("confirm"):
		_confirm_ready_at = _battle_clock + DialogueBox.CONFIRM_BUFFER
		if _text_finished():
			_next_message()
		else:
			_typed = _text.length()  # Skip to the end of the line.
	elif _pressed("cancel"):
		_typed = _text.length()


# --- Player turn: picking actions -----------------------------------------

func _start_player_turn() -> void:
	turn += 1
	actions.clear()
	current_member = -1
	_flavor = _data.flavor_text(turn)
	_set_text(_flavor)
	# Wait for the box to finish growing back before the text starts typing.
	_typed = -0.3 * TYPE_SPEED
	_next_member()


## Moves on to the next party member who can act, or runs the actions if everyone has chosen.
func _next_member() -> void:
	current_member += 1
	while current_member < party.size() and party[current_member].is_down():
		actions.append({"type": "NONE"})
		current_member += 1

	if current_member >= party.size():
		_open_ready()
	else:
		_open_menu()


## After everyone has chosen: show the plan, and let the player go back and change it.
func _open_ready() -> void:
	state = State.READY
	soul.visible = false
	var lines: Array[String] = []
	for action in actions:
		if action["type"] == "NONE":
			continue
		lines.append("* " + _describe(action))
	lines.append("* (ENTER: go!     X: change something)")
	_text = "\n".join(lines)
	_typed = _text.length()


## A short description of a chosen action, like "Elric: ACT (Pun) on Eggo".
func _describe(action: Dictionary) -> String:
	var who: String = action["member"].name
	match action["type"]:
		"FIGHT":
			return "%s: FIGHT %s" % [who, action["target"].name]
		"ACT":
			var target: Enemy = action["target"]
			return "%s: ACT (%s) on %s" % [who, target.act_names()[action["act"]], target.name]
		"ITEM":
			return "%s: give %s the %s" % [who, action["target"].name, action["item"]["name"]]
		"MERCY":
			return "%s: SPARE %s" % [who, action["target"].name]
		"DEFEND":
			return "%s: DEFEND" % who
		"CALL":
			return "%s: CALL %s" % [who, DialogueBox.display_name(action["helper"])]
	return who


func _process_ready() -> void:
	if _pressed("confirm"):
		Game.play_sfx("select")
		_run_actions()
	elif _pressed("cancel"):
		Game.play_sfx("move")
		_go_back()


func _open_menu() -> void:
	state = State.MENU
	if _text != _flavor:
		_text = _flavor
		_typed = _flavor.length()
	soul.visible = true
	_place_soul_on_button()


func _place_soul_on_button() -> void:
	soul.global_position = Vector2(22 + _button * BUTTON_SPACING + 14, BUTTON_Y + BUTTON_SIZE.y / 2)


func _process_menu() -> void:
	# Moving to another button clears any "no items" message.
	if (_pressed("ui_left") or _pressed("ui_right")) and _text != _flavor:
		_text = _flavor
		_typed = _flavor.length()
	if _pressed("ui_left"):
		_button = wrapi(_button - 1, 0, BUTTONS.size())
		Game.play_sfx("move")
	elif _pressed("ui_right"):
		_button = wrapi(_button + 1, 0, BUTTONS.size())
		Game.play_sfx("move")
	elif _pressed("confirm"):
		Game.play_sfx("select")
		_pending = BUTTONS[_button]
		match _pending:
			"FIGHT", "ACT":
				_open_list(State.TARGET_ENEMY, _active_enemies())
			"MERCY":
				_open_list(State.MERCY_MENU, _mercy_options())
			"ITEM":
				var available := _available_items()
				if not available.is_empty():
					_open_list(State.ITEM_LIST, available)
				else:
					# Say so, instead of silently doing nothing.
					Game.play_sfx("miss")
					_text = "* (You don't have any items.)" if items.all(func(i: Dictionary) -> bool: return Items.is_accessory(i)) else "* (Your teammate already picked the last item.)"
					_typed = _text.length()
			"DEFEND":
				party[current_member].defending = true
				_choose({"type": "DEFEND"})
	elif _pressed("cancel"):
		_go_back()

	if state == State.MENU:
		_place_soul_on_button()


## Saves the current member's action and moves on to the next member.
func _choose(action: Dictionary) -> void:
	action["member"] = party[current_member]
	actions.append(action)
	_next_member()


## Undoes the previous member's choice (X / Shift in the menu).
func _go_back() -> void:
	var previous := current_member - 1
	while previous >= 0 and party[previous].is_down():
		previous -= 1
	if previous < 0:
		return
	actions.resize(previous)
	current_member = previous
	party[previous].defending = false
	_open_menu()


func _open_list(list_state: State, list: Array) -> void:
	state = list_state
	_list = list
	_cursor = 0
	soul.visible = true


func _process_list() -> void:
	if _pressed("ui_up"):
		_cursor = wrapi(_cursor - 1, 0, _list.size())
		Game.play_sfx("move")
	elif _pressed("ui_down"):
		_cursor = wrapi(_cursor + 1, 0, _list.size())
		Game.play_sfx("move")
	elif _pressed("confirm"):
		Game.play_sfx("select")
		_confirm_list_choice()
		return
	elif _pressed("cancel"):
		if state == State.ACT_LIST:
			_open_list(State.TARGET_ENEMY, _active_enemies())
		elif state == State.TARGET_PARTY:
			_open_list(State.ITEM_LIST, _available_items())
		elif state == State.CALL_LIST:
			_open_list(State.MERCY_MENU, _mercy_options())
		elif state == State.TARGET_ENEMY and _pending == "MERCY":
			_open_list(State.MERCY_MENU, _mercy_options())
		else:
			_open_menu()
		return

	var area := box.get_inner_rect()
	if state == State.CALL_LIST:
		# Two columns of five.
		soul.global_position = Vector2(area.position.x + 26 + (_cursor / CALL_ROWS) * CALL_COLUMN, _row_y(_cursor % CALL_ROWS) - 5)
		return
	soul.global_position = Vector2(area.position.x + 26, _row_y(_cursor) - 5)


func _confirm_list_choice() -> void:
	var choice = _list[_cursor]
	match state:
		State.TARGET_ENEMY:
			if _pending == "ACT":
				_act_target = choice
				_open_list(State.ACT_LIST, _act_target.act_names())
			else:
				_choose({"type": _pending, "target": choice})
		State.ACT_LIST:
			_choose({"type": "ACT", "target": _act_target, "act": _cursor})
		State.ITEM_LIST:
			_chosen_item = choice
			_open_list(State.TARGET_PARTY, party)
		State.TARGET_PARTY:
			_choose({"type": "ITEM", "item": _chosen_item, "target": choice})
		State.MERCY_MENU:
			if choice == "Spare":
				_open_list(State.TARGET_ENEMY, _active_enemies())
			elif choice == "Call":
				if _call_wait() > 0:
					Game.play_sfx("miss")
					return
				_open_list(State.CALL_LIST, _callable_helpers())
			else:
				_try_flee()
		State.CALL_LIST:
			var wait := _helper_wait(choice)
			if wait != 0:
				Game.play_sfx("miss")
				return
			_choose({"type": "CALL", "helper": choice})


# --- Player turn: running the actions -------------------------------------

func _run_actions() -> void:
	_turn_number += 1
	_action_index = -1
	_run_next_action()


func _run_next_action() -> void:
	_action_index += 1
	if _action_index >= actions.size():
		_after_actions()
		return

	var action := actions[_action_index]
	var member: PartyMember = action.get("member")
	if member:
		_member_anim[member] = {"type": action["type"], "time": 0.0}
	match action["type"]:
		"NONE":
			_run_next_action()
		"DEFEND":
			_show_messages(["* %s is defending." % member.name], _run_next_action)
		"FIGHT":
			var target := _retarget(action["target"])
			if target == null:
				_run_next_action()
			else:
				_start_fight_bar(member, target)
		"ACT":
			var target: Enemy = action["target"]
			if not target.is_active():
				_show_messages(["* %s isn't fighting anymore." % target.name], _run_next_action)
			else:
				_show_messages(target.do_act(action["act"], member.name), _run_next_action)
		"ITEM":
			_use_item(member, action["item"], action["target"])
		"MERCY":
			_try_spare(member, action["target"])
		"CALL":
			_start_call(member, action["helper"])


func _use_item(member: PartyMember, item: Dictionary, target: PartyMember) -> void:
	items.erase(item)
	var was_down := target.is_down()
	var healed := mini(int(item["heal"]), target.max_hp - target.hp)
	target.hp += healed
	_add_popup("+%d" % healed, _panel_position(target), Color.GREEN)
	Game.play_sfx("heal")

	var lines: Array[String] = []
	if target == member:
		lines.append("* %s ate the %s.\n* Recovered %d HP!" % [member.name, item["name"], healed])
	else:
		lines.append("* %s gave %s the %s.\n* %s recovered %d HP!" % [member.name, target.name, item["name"], target.name, healed])
	if was_down and not target.is_down():
		lines.append("* %s got back up!" % target.name)
	_show_messages(lines, _run_next_action)


func _try_spare(member: PartyMember, target: Enemy) -> void:
	if not target.is_active():
		_run_next_action()
	elif target.spare_refusal != "":
		_show_messages([target.spare_refusal], _run_next_action)
	elif target.can_spare():
		target.state = "spared"
		bond_gained += target.bond_reward
		Game.play_sfx("spare")
		_show_messages(["* %s spared %s!" % [member.name, target.name]], _run_next_action)
	else:
		_show_messages(["* %s tried to spare %s...\n* But %s isn't ready to stop fighting yet." % [member.name, target.name, target.name]], _run_next_action)


## If the chosen enemy already left the fight, attack another one instead.
func _retarget(target: Enemy) -> Enemy:
	if target.is_active():
		return target
	var active := _active_enemies()
	return active[0] if not active.is_empty() else null


func _after_actions() -> void:
	if _active_enemies().is_empty():
		_victory()
	else:
		_start_enemy_turn()


# --- CALL: a friend jumps in (Pacifist route) ------------------------------------
# MERCY > Call a friend: a REVOLUTION Corps member who isn't in the party runs in,
# does their move, and runs off again (see helpers.gd). Only once Elric has joined
# the Corps. It isn't free: after any call, nobody can be called for CALL_COOLDOWN
# turns, and each friend has their own wait (`cooldown`) and a number of `charges`
# per battle.

const CALL_ROWS := 5
const CALL_COLUMN := 250.0
## Turns before anyone can be called again.
const CALL_COOLDOWN := 3
## When the helper's move lands, and when they're gone, in seconds.
const CALL_HIT_TIME := 0.75
const CALL_LENGTH := 1.6
## Big Joe's shield: how much damage gets through while it's up.
const SHIELD_LETS_THROUGH := 0.2

var _helpers_script: GDScript
## How many turns the party has taken this battle (counted when the actions run).
var _turn_number: int = 0
## The turn of the last call (-99: no call yet), and each friend's last call and
## how many times they've been called.
var _last_call_turn: int = -99
var _helper_last_turn: Dictionary = {}
var _helper_uses: Dictionary = {}
## The call happening right now: who, how long they've been here, their target.
var _call: Dictionary = {}
## Big Joe's shield is up for this enemy turn (damage cut by 80%).
var _shield_up: bool = false


func _helpers() -> GDScript:
	if _helpers_script == null:
		_helpers_script = load("res://scripts/helpers.gd")
	return _helpers_script


## Spare and Flee, and Call a friend once Elric has joined the Corps.
func _mercy_options() -> Array:
	var options: Array = ["Spare", "Flee"]
	if Game.joined_corps() and not _callable_helpers().is_empty() and not actions.any(func(a: Dictionary) -> bool: return a["type"] == "CALL"):
		options.append("Call")
	return options


## Corps members who aren't already fighting.
func _callable_helpers() -> Array:
	var fighting := party.map(func(m: PartyMember) -> String: return m.id)
	return _helpers().CORPS.filter(func(id: String) -> bool: return not id in fighting)


## Turns until anyone can be called (0 = now).
func _call_wait() -> int:
	return maxi(0, _last_call_turn + CALL_COOLDOWN - (_turn_number + 1))


## Turns until this friend can be called (0 = now), counting the shared wait too.
## -1 means they're out of charges for this battle.
func _helper_wait(id: String) -> int:
	var info: Dictionary = _helpers().HELPERS[id]
	var charges: int = info.get("charges", -1)
	if charges >= 0 and int(_helper_uses.get(id, 0)) >= charges:
		return -1
	var own: int = int(_helper_last_turn.get(id, -99)) + int(info.get("cooldown", CALL_COOLDOWN)) - (_turn_number + 1)
	return maxi(_call_wait(), maxi(own, 0))


func _start_call(member: PartyMember, helper: String) -> void:
	var targets := _active_enemies()
	if targets.is_empty():
		_run_next_action()
		return
	_last_call_turn = _turn_number
	_helper_last_turn[helper] = _turn_number
	_helper_uses[helper] = int(_helper_uses.get(helper, 0)) + 1
	var info: Dictionary = _helpers().HELPERS[helper]
	var sprite_path := "res://art/sprites/%s.png" % helper.to_lower()
	_call = {"id": helper, "time": 0.0, "target": targets.pick_random(), "landed": false, "member": member,
		"sprite": load(sprite_path) if ResourceLoader.exists(sprite_path) else null, "damage": 0}
	_text = "* %s called for help!\n* %s" % [member.name, info["line"]]
	_typed = _text.length()
	soul.visible = false
	Game.play_sfx("alert")
	state = State.CALLING


func _process_call(delta: float) -> void:
	_call["time"] += delta
	var target: Enemy = _call["target"]
	var info: Dictionary = _helpers().HELPERS[_call["id"]]
	var shield: bool = info.get("kind", "hit") == "shield"
	if not _call["landed"] and _call["time"] >= CALL_HIT_TIME:
		_call["landed"] = true
		if shield:
			# Big Joe plants his shield in front of the party.
			_shield_up = true
			Game.play_sfx("bonk", 0.6)
			Game.play_sfx("shing", 0.7)
			_add_popup(info["move"], Vector2(150, 40), info["color"], 20, true)
		else:
			var damage := 4 + Game.lv() * 2 + randi() % 4
			# Pacifists don't finish anyone off.
			damage = mini(damage, target.hp - 1)
			_call["damage"] = maxi(damage, 0)
			target.hp -= _call["damage"]
			target.shake = 0.5
			target.flash = 0.2
			Game.play_sfx("punch_hit")
			_impact(target, 0.07, false)
			_add_popup(info["move"], target.position + Vector2(0, -95), info["color"], 18)
			_add_popup(str(_call["damage"]), target.position + Vector2(0, -30), Color(1, 0.25, 0.25), 26, true)
	if _call["time"] < CALL_LENGTH:
		return
	var helper_name := DialogueBox.display_name(_call["id"])
	var line := "* %s used %s!\n* %s took %d damage." % [helper_name, info["move"], target.name, _call["damage"]]
	if shield:
		line = "* %s used %s!\n* All damage is cut by 80%% this turn!" % [helper_name, info["move"]]
	elif _call["damage"] == 0:
		line = "* %s used %s!\n* (%s is hanging on by a thread. They won't finish it.)" % [helper_name, info["move"], target.name]
	_call = {}
	_show_messages([line, "* %s waved and ran off." % helper_name], _run_next_action)


## The helper running in from the left, doing their move, and running off. Most
## lunge at their target; Big Joe plants himself in front of the party instead.
func _draw_call() -> void:
	if _call.is_empty() or _call["sprite"] == null:
		return
	var t: float = _call["time"]
	var target: Enemy = _call["target"]
	var info: Dictionary = _helpers().HELPERS[_call["id"]]
	var shield: bool = info.get("kind", "hit") == "shield"
	var texture: Texture2D = _call["sprite"]
	# Attackers strike from the open space between the party and the enemies.
	var stop_x := 250.0 if shield else 290.0
	var x: float
	var leaving := t > 1.1
	if t < 0.45:
		x = lerpf(-60.0, stop_x, 1.0 - pow(1.0 - t / 0.45, 2.0))
	elif t < 1.1:
		var lunge := clampf((t - 0.6) / 0.15, 0.0, 1.0) * clampf((1.1 - t) / 0.25, 0.0, 1.0)
		x = stop_x + (0.0 if shield else 40.0 * lunge)
	else:
		x = lerpf(stop_x, -80.0, (t - 1.1) / 0.5)
	var bob := -absf(sin(t * 18.0)) * 6.0 if (t < 0.45 or leaving) else 0.0
	var size := texture.get_size() * 3.0
	var feet := Vector2(x, 180.0 + bob)
	_overlay.draw_set_transform(feet, 0.0, Vector2(-1.0 if leaving else 1.0, 1.0))
	_overlay.draw_texture_rect(texture, Rect2(Vector2(-size.x / 2, -size.y), size), false)
	_overlay.draw_set_transform(Vector2.ZERO)
	var since := t - CALL_HIT_TIME
	if since < 0.0 or since > 0.4:
		return
	var fade := 1.0 - since / 0.4
	if shield:
		# The shield going up: a golden flash spreading over the party.
		_overlay.draw_circle(Vector2(130, 120), 40.0 + since * 200.0, Color(info["color"], 0.3 * fade))
		return
	var center := target.position + Vector2(0, -20)
	_overlay.draw_circle(center, 20.0 + since * 120.0, Color(info["color"], 0.25 * fade))
	for k in 12:
		var dir := Vector2.from_angle(k * TAU / 12 + 0.2)
		_overlay.draw_line(center + dir * (14.0 + since * 80.0), center + dir * (30.0 + since * 140.0), Color(info["color"], fade), 3.0)


## Big Joe's shield, while it's up: a glowing golden wall in front of the party,
## with a big kite shield in the middle, and a note over the box.
func _draw_shield() -> void:
	if not _shield_up:
		return
	var gold := Color(1.0, 0.82, 0.25)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 200.0)
	var wall := Rect2(30, 40, 230, 160)
	_overlay.draw_rect(wall, Color(gold, 0.06 + 0.04 * pulse))
	_overlay.draw_rect(wall, Color(gold, 0.5), false, 2.0)
	var middle := Vector2(240, 115)
	var s := 26.0
	var outline := PackedVector2Array([middle + Vector2(-s, -s), middle + Vector2(s, -s), middle + Vector2(s * 0.95, s * 0.2), middle + Vector2(0, s * 1.3), middle + Vector2(-s * 0.95, s * 0.2)])
	_overlay.draw_colored_polygon(outline, Color(0.82, 0.84, 0.9, 0.85))
	var field := PackedVector2Array()
	for p in outline:
		field.append(middle + (p - middle) * 0.75)
	_overlay.draw_colored_polygon(field, Color(0.2, 0.32, 0.65, 0.9))
	_overlay.draw_string(_font, middle + Vector2(-9, 7), "BJ", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, gold)
	if state == State.ENEMY_TURN:
		var frame := box.get_inner_rect()
		_overlay.draw_string(_font, Vector2(frame.end.x + 12, frame.position.y + 14), "SHIELD", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, gold)
		_overlay.draw_string(_font, Vector2(frame.end.x + 12, frame.position.y + 30), "-80% damage", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, gold)


# --- FIGHT bar ------------------------------------------------------------

func _start_fight_bar(member: PartyMember, target: Enemy) -> void:
	_bar_member = member
	_bar_target = target
	# The bar comes in from the left or the right, at random.
	_bar_dir = 1.0 if randf() < 0.5 else -1.0
	_bar_pos = 0.0 if _bar_dir > 0.0 else 1.0
	_bar_wait = FIGHT_WINDUP
	_bar_trail.clear()
	_file_bars.clear()
	if _weapon_style(member) == "file":
		# The second and third bars start further back, so they come in one by one.
		for i in 3:
			_file_bars.append({"pos": _bar_pos - _bar_dir * FILE_BAR_GAP * i, "done": false, "accuracy": -1.0})
	_text = ""
	soul.visible = false
	state = State.FIGHT_BAR


func _process_fight_bar(delta: float) -> void:
	# A short "READY..." first, so there's time to get set.
	if _bar_wait > 0.0:
		_bar_wait -= delta
		return
	if not _file_bars.is_empty():
		_process_file_bars(delta)
		return
	_bar_trail.append(_bar_pos)
	if _bar_trail.size() > 6:
		_bar_trail.pop_front()
	_bar_pos += _bar_dir * delta / FIGHT_BAR_TIME
	if _pressed("confirm"):
		# 1.0 for a hit dead in the middle, 0.0 at the very edges.
		_resolve_hit(1.0 - absf(_bar_pos - 0.5) * 2.0)
	elif _bar_pos >= 1.0 or _bar_pos <= 0.0 and _bar_dir < 0:
		_resolve_hit(-1.0)


## Nail File: all three bars move together; ENTER stops the one in front. Once
## every bar is stopped (or has run off the end), the hit is worked out.
func _process_file_bars(delta: float) -> void:
	var lead := -1
	for i in _file_bars.size():
		var bar := _file_bars[i]
		if bar["done"]:
			continue
		bar["pos"] += _bar_dir * delta / FIGHT_BAR_TIME
		if (bar["pos"] >= 1.0 and _bar_dir > 0.0) or (bar["pos"] <= 0.0 and _bar_dir < 0.0):
			bar["done"] = true
			Game.play_sfx("miss")
			_add_popup("MISS", _bar_target.position + Vector2(-30 + i * 30, -30), Color.LIGHT_GRAY, 16)
		elif lead == -1:
			lead = i
	if lead != -1 and _pressed("confirm"):
		var bar := _file_bars[lead]
		# A bar that hasn't come onto the track yet can't be stopped.
		if bar["pos"] >= 0.0 and bar["pos"] <= 1.0:
			bar["done"] = true
			bar["accuracy"] = 1.0 - absf(bar["pos"] - 0.5) * 2.0
			Game.play_sfx("shing", 0.8 + 0.2 * lead)
	if _file_bars.all(func(b: Dictionary) -> bool: return b["done"]):
		_resolve_file()


## Nail File: each bar that hit deals a third of a normal hit's damage (for its own
## accuracy). All three in the CRITICAL zone makes the whole thing a CRITICAL.
func _resolve_file() -> void:
	var member := _bar_member
	var target := _bar_target
	var total := 0.0
	var hits := 0
	var sum := 0.0
	var criticals := 0
	for bar in _file_bars:
		var accuracy: float = bar["accuracy"]
		if accuracy < 0.0:
			continue
		hits += 1
		sum += accuracy
		total += member.attack * (0.8 + 2.2 * accuracy) / 3.0
		if accuracy >= CRITICAL:
			criticals += 1
	if hits == 0:
		_resolve_hit(-1.0)
		return
	var damage := maxi(1, roundi(total) - target.defense)
	var accuracy := sum / hits
	if criticals == 3:
		damage = roundi(damage * 1.25)
		accuracy = 1.0
	else:
		accuracy = minf(accuracy, CRITICAL - 0.01)
	_start_attack_anim(damage, accuracy)


## The bar was stopped (or ran out). Work out the damage, then play the attack animation.
func _resolve_hit(accuracy: float) -> void:
	var member := _bar_member
	var target := _bar_target
	if accuracy < 0.0:
		_add_popup("MISS", target.position + Vector2(0, -30), Color.LIGHT_GRAY, 22)
		Game.play_sfx("miss")
		_show_messages(["* %s missed!" % member.name], _run_next_action)
		return

	var damage := maxi(1, roundi(member.attack * (0.8 + 2.2 * accuracy)) - target.defense)
	if accuracy >= CRITICAL:
		damage = roundi(damage * 1.25)
	_start_attack_anim(damage, accuracy)


## Hop, wearing the Divergent Glove? Then every hit has a chance to be a BLACK FLASH.
func _can_black_flash(member: PartyMember) -> bool:
	return member.name == "Hop" and Game.worn_by("Hop").get("weapon", {}).get("name", "") == "Divergent Glove"


func _start_attack_anim(damage: int, accuracy: float) -> void:
	var member := _bar_member
	_black_flash = _can_black_flash(member) and (force_black_flash or randf() < BLACK_FLASH_CHANCE)
	if _black_flash:
		force_black_flash = false
		damage = roundi(damage * BLACK_FLASH_DAMAGE)
	_anim_damage = damage
	_anim_accuracy = accuracy
	_anim_time = 0.0
	_anim_landed = false
	if member.name != "Hop":
		Game.play_sfx("slash")
	state = State.FIGHT_ANIM


## The slash plays across the enemy; when it lands, the damage pops out and the
## HP bar drains. Then the result is shown in the text box.
func _process_fight_anim(delta: float) -> void:
	# Hit-stop: everything holds still for a split second when a blow lands.
	if _hitstop > 0.0:
		_hitstop -= delta
		return
	var before := _anim_time
	_anim_time += delta
	var member := _bar_member
	var target := _bar_target
	var weapon := _weapon_style(member)
	if weapon == "file":
		# One quick jab for each bar that hit, each with a metallic shing and its
		# share of the damage.
		for i in FILE_JABS.size():
			if before < FILE_JABS[i] and _anim_time >= FILE_JABS[i] and _file_jab_landed(i):
				Game.play_sfx("shing", randf_range(0.9, 1.2))
				target.shake = 0.12
				var share := roundi(_anim_damage / float(_file_hit_count()))
				_add_popup(str(share), target.position + Vector2(-34 + i * 34, -60 - i * 8), Color(0.85, 0.88, 0.95), 16)
	elif weapon == "finger":
		if before < 0.02 and _anim_time >= 0.02:
			Game.play_sfx("slash", 0.6)
	elif member.name == "Hop":
		# Hop's punches each land with their own thump, and a tiny freeze.
		for at in HOP_PUNCHES:
			if before < at and _anim_time >= at:
				Game.play_sfx("punch", randf_range(0.9, 1.15))
				target.shake = 0.15
				_hitstop = 0.035
	if not _anim_landed and _anim_time >= ATTACK_SLASH_TIME:
		_anim_landed = true
		target.hp = maxi(target.hp - _anim_damage, 0)
		target.shake = 0.5
		target.flash = 0.25
		# Each way of attacking has its own sound when it connects.
		match weapon:
			"file": Game.play_sfx("file_hit")
			"finger": Game.play_sfx("squeak")
			_: Game.play_sfx("punch_hit" if member.name == "Hop" else "claw_hit")
		var critical := _anim_accuracy >= CRITICAL
		# The impact frame: a freeze, a flash, and the enemy as a silhouette.
		_impact(target, 0.13 if critical else 0.08, critical)
		if _black_flash:
			# BLACK FLASH: a much longer freeze, flickering black and red.
			Game.play_sfx("black_flash")
			_impact(target, BLACK_FLASH_FREEZE, true)
			_impact_black = true
			target.shake = 0.9
			_add_popup("BLACK FLASH", target.position + Vector2(0, -105), Color(1.0, 0.12, 0.18), 30, true)
		if weapon == "finger":
			Game.play_sfx("bonk")
			_squash_enemy = target
			_squash_time = 0.45
			_add_popup("BONK!", target.position + Vector2(-40, -90), Color(1.0, 0.85, 0.2), 24, true)
		_add_popup(str(_anim_damage), target.position + Vector2(0, -30), YELLOW if critical else Color(1, 0.25, 0.25), 32 if critical else 26, true)
		if critical and not _black_flash:
			_add_popup("CRITICAL!", target.position + Vector2(0, -70), YELLOW, 18)
	if _anim_time < ATTACK_SLASH_TIME + 0.9:
		return

	var lines: Array[String] = ["* %s hit %s for %d damage!" % [member.name, target.name, _anim_damage]]
	if _anim_accuracy >= CRITICAL:
		lines[0] = "* CRITICAL HIT!\n" + lines[0]
	if _black_flash:
		lines[0] = lines[0].trim_prefix("* CRITICAL HIT!\n")
		lines.insert(0, "* BLACK FLASH!!\n* For an instant, the air around Hop's fist went black.")
	if target.hit_line != "":
		lines[0] += "\n" + target.hit_line
	if target.hp == 0:
		target.state = "defeated"
		target.ko_time = 0.0
		Game.play_sfx("thud")
		exp_gained += target.exp_reward
		lines.append("* %s was knocked out!" % target.name)
		# Their partner reacts.
		for other in _active_enemies():
			var reaction: Dictionary = other.partner_reactions.get(target.name, {})
			if reaction.is_empty():
				continue
			lines.append(reaction["line"])
			other.mood = reaction.get("mood", "")
			other.shake = 0.3
			if reaction.has("taunts"):
				other.taunts.assign(reaction["taunts"])
			other.attack += int(reaction.get("attack", 0))
	_show_messages(lines, _run_next_action)


# --- Enemy turn -----------------------------------------------------------

func _start_enemy_turn() -> void:
	state = State.ENEMY_TURN
	_text = ""
	_enemy_timer = ENEMY_TURN_TIME
	_attackers = _data.who_attacks(enemy_turn)
	enemy_turn += 1

	_spawn_timers.clear()
	_spawn_steps.clear()
	_last_spawn.clear()
	_turn_patterns.clear()
	_speech.clear()
	for enemy in _attackers:
		_spawn_timers[enemy] = 0.0
		_spawn_steps[enemy] = 0
		_turn_patterns[enemy] = _pick_pattern(enemy)
		enemy.fury = enemy_turn - 1
	for enemy in _active_enemies():
		_speech[enemy] = enemy.taunt()

	create_tween().tween_property(box, "size", ATTACK_BOX_SIZE, 0.25)
	soul.global_position = BOX_CENTER
	# Whose SOUL is out (and takes the hits). X switches it during the turn.
	if _soul_member().is_down():
		_soul_owner = party.find(_first_standing())
	_update_soul_look()
	soul.visible = true
	soul.can_move = true


## Picks this turn's attack for an enemy at random, so fights don't feel repetitive.
## The enemy's first attack is always its first (easiest) one, and it never uses
## the same attack two turns in a row.
func _pick_pattern(enemy: Enemy) -> String:
	var pattern: String
	if not _last_patterns.has(enemy):
		pattern = enemy.patterns[0]
	else:
		var choices := enemy.patterns.filter(func(p: String) -> bool: return p != _last_patterns[enemy])
		pattern = choices.pick_random() if not choices.is_empty() else enemy.patterns[0]
	_last_patterns[enemy] = pattern
	return pattern


func _process_enemy_turn(delta: float) -> void:
	_enemy_timer -= delta
	if _pressed("cancel"):
		_switch_soul()

	# Give the box a moment to shrink before the bullets start.
	# Stop spawning a moment before the turn ends, so the last bullets can clear out.
	if _enemy_timer < ENEMY_TURN_TIME - 0.4 and _enemy_timer > 0.6:
		# When two enemies attack together, each one attacks a bit less often.
		var crowding := 1.0 if _attackers.size() == 1 else 1.5
		for enemy in _attackers:
			_spawn_timers[enemy] -= delta
			if _spawn_timers[enemy] <= 0.0:
				var wait := Attacks.spawn(_turn_patterns[enemy], enemy, self, box.get_inner_rect(), soul.global_position, _spawn_steps[enemy])
				_spawn_timers[enemy] = wait * crowding
				_spawn_steps[enemy] += 1
				_last_spawn[enemy] = ENEMY_TURN_TIME - _enemy_timer

	if _invincible_timer > 0.0:
		# Just got hit: make the SOUL blink until the invincibility wears off.
		_invincible_timer -= delta
		soul.visible = _invincible_timer <= 0.0 or fmod(_invincible_timer, 0.2) > 0.1
	else:
		_check_hits()

	if state == State.ENEMY_TURN and _enemy_timer <= 0.0:
		_end_enemy_turn()


## Checks whether any bullet is touching the SOUL.
func _check_hits() -> void:
	# The SOUL's hitbox is smaller than the heart picture, so close
	# dodges feel fair (Undertale does the same thing).
	var soul_hitbox := Rect2(soul.global_position - Vector2(4, 4), Vector2(8, 8))

	for child in get_children():
		var bullet := child as Bullet
		if bullet and bullet.hits(soul_hitbox):
			# Slashes stay to finish their flash (the SOUL is briefly invincible
			# after a hit, so they can't hit twice). Everything else vanishes.
			if not bullet.shape in ["beam", "claw_slash", "ring", "clapper"]:
				bullet.queue_free()
			_hurt_party(bullet.damage)
			return


## A bullet hit. The SOUL is Elric's, so Elric (the first party member) takes the damage.
## If Elric is knocked down, the next member still standing takes it instead.
## Which party member's SOUL is out during enemy turns (an index into `party`).
## Elric's SOUL is red; Hop's is silver, cracked into shards, with red light inside.
var _soul_owner: int = 0


func _soul_member() -> PartyMember:
	return party[clampi(_soul_owner, 0, party.size() - 1)]


func _first_standing() -> PartyMember:
	for candidate in party:
		if not candidate.is_down():
			return candidate
	return party[0]


## X during the enemy's turn: switch to the next party member who's still standing.
func _switch_soul() -> void:
	for step in range(1, party.size()):
		var next := (_soul_owner + step) % party.size()
		if not party[next].is_down():
			_soul_owner = next
			Game.play_sfx("select")
			_soul_flash = 0.25
			_update_soul_look()
			return


func _update_soul_look() -> void:
	soul.fragmented = _soul_member().name == "Hop"


## A quick flash when the SOUL switches owners.
var _soul_flash: float = 0.0


## The label over the box during the enemy's turn: whose SOUL it is, and how to switch.
func _draw_soul_owner() -> void:
	if state != State.ENEMY_TURN:
		return
	var member := _soul_member()
	var frame := box.get_inner_rect()
	var label := "%s'S SOUL" % member.name.to_upper()
	if party.filter(func(m: PartyMember) -> bool: return not m.is_down()).size() > 1:
		label += "    X: switch"
	_draw_centered(label, Vector2(frame.get_center().x, frame.position.y - 10), 12, member.color)
	if _soul_flash > 0.0:
		_overlay.draw_circle(soul.global_position, 14.0 * (1.0 - _soul_flash / 0.25) + 6.0, Color(member.color, _soul_flash * 2.0))


func _hurt_party(amount: int) -> void:
	# Whoever's SOUL is out takes the hit (or the first one still standing).
	var member := _soul_member()
	if member.is_down():
		member = _first_standing()
	if member == null:
		return
	# Defense (from accessories) softens every hit; defending halves what's left.
	var after_defense := maxi(1, amount - member.defense)
	var damage := ceili(after_defense / 2.0) if member.defending else after_defense
	if _shield_up:
		damage = roundi(damage * SHIELD_LETS_THROUGH)
	member.hp = maxi(member.hp - damage, 0)
	member.shake = 0.4
	_add_popup(str(damage), _panel_position(member), Color.RED)
	Game.play_sfx("hurt")
	_invincible_timer = invincibility_time

	if party.all(func(m: PartyMember) -> bool: return m.is_down()):
		_game_over()


func _end_enemy_turn() -> void:
	# Big Joe's shield only lasts one turn.
	_shield_up = false
	# Back to the plain red cursor for the menus.
	soul.fragmented = false
	_clear_bullets()
	soul.can_move = false
	soul.visible = true
	_invincible_timer = 0.0
	_speech.clear()
	for member in party:
		member.defending = false
	create_tween().tween_property(box, "size", TEXT_BOX_SIZE, 0.25)
	# In a fight you can't win, lasting long enough ends it.
	if _data.survive_turns > 0 and enemy_turn >= _data.survive_turns:
		_survived()
	else:
		_start_player_turn()


## The player lasted long enough in an unwinnable fight.
func _survived() -> void:
	var result := {"id": _data.id, "survived": true, "spared": [], "defeated": [], "bond": 0, "exp": 0, "money": 0}
	if Game.pending_battle != "":
		_show_messages(_data.survive_lines, func() -> void: _leave_battle(func() -> void: Game.finish_battle(result)))
	else:
		_show_messages(_data.survive_lines + ["* (Press ENTER to fight again.)"], func() -> void: _leave_battle(get_tree().reload_current_scene))


func _clear_bullets() -> void:
	for child in get_children():
		if child is Bullet:
			child.queue_free()


# --- Winning and losing ---------------------------------------------------

func _victory() -> void:
	var lines: Array[String] = ["* YOU WON!"]
	if bond_gained > 0:
		lines.append("* You earned %d BOND." % bond_gained)
	if exp_gained > 0:
		lines.append("* You earned %d EXP." % exp_gained)
	# Every enemy leaves a little money behind, spared or not.
	var money := 0
	for enemy in enemies:
		money += enemy.money_reward
	lines.append("* You found $%d." % money)
	# Growing a level (the rewards are added once the battle ends).
	if Game.lv_for(Game.exp_points + exp_gained) > Game.lv():
		lines.append("* Your LV increased to %d!\n* (Max HP and attack went up.)" % Game.lv_for(Game.exp_points + exp_gained))
	if Game.bond_level_for(Game.bond + bond_gained) > Game.bond_level():
		lines.append("* Your BOND grew to level %d!\n* (Max HP and attack went up.)" % Game.bond_level_for(Game.bond + bond_gained))

	if Game.pending_battle != "":
		# Tell the overworld how it went, so the story can react.
		var result := {"id": _data.id, "spared": [], "defeated": [], "bond": bond_gained, "exp": exp_gained, "money": money}
		for enemy in enemies:
			if enemy.state == "spared":
				result["spared"].append(enemy.name)
			elif enemy.state == "defeated":
				result["defeated"].append(enemy.name)
		_show_messages(lines, func() -> void: _leave_battle(func() -> void: Game.finish_battle(result)))
	else:
		lines.append("* (Press ENTER to fight again.)")
		_show_messages(lines, func() -> void: _leave_battle(get_tree().reload_current_scene))


## The battle is over: stop reacting to keys (so pressing Z during the fade-out
## can't end the battle a second time), then run `then`.
func _leave_battle(then: Callable) -> void:
	state = State.DONE
	then.call()


# --- GAME OVER ------------------------------------------------------------
# Like Undertale: the SOUL stops, cracks in half, shatters into pieces,
# then "GAME OVER" fades in and "Stay determined..." types out.

const CRACK_TIME := 0.8
const SHATTER_TIME := 1.6
const TITLE_TIME := 2.8
const MESSAGE_TIME := 3.6

var _game_over_time: float = 0.0
var _heart_position: Vector2
var _shards: Array[Dictionary] = []
var _cracked: bool = false
var _shattered: bool = false


func _game_over() -> void:
	state = State.GAME_OVER
	# Silence while the SOUL breaks; the GAME OVER theme starts with the title.
	Game.stop_music(0.15)
	_clear_bullets()
	_heart_position = soul.global_position
	soul.can_move = false
	soul.visible = false
	box.visible = false
	_text = ""
	_game_over_time = 0.0
	_cracked = false
	_shattered = false
	_shards.clear()


func _process_game_over(delta: float) -> void:
	_game_over_time += delta

	if not _cracked and _game_over_time >= CRACK_TIME:
		_cracked = true
		Game.play_sfx("crack")
	if not _shattered and _game_over_time >= SHATTER_TIME:
		_shattered = true
		Game.play_sfx("shatter")
		for i in 6:
			var angle := randf_range(-PI, 0.0)
			_shards.append({
				"position": _heart_position,
				"velocity": Vector2(cos(angle), sin(angle)) * randf_range(60, 160),
			})
	for shard in _shards:
		shard["velocity"] += Vector2(0, 300) * delta
		shard["position"] += shard["velocity"] * delta

	if _game_over_time >= TITLE_TIME and not has_meta("game_over_music"):
		set_meta("game_over_music", true)
		Game.play_music("game_over", 1.5)
	if _game_over_time >= MESSAGE_TIME and _text == "":
		_set_text("Stay determined...")

	if _game_over_time >= MESSAGE_TIME and _text_finished() and _pressed("confirm"):
		set_process(false)
		if Game.pending_battle != "":
			Game.continue_after_game_over()
		else:
			get_tree().reload_current_scene()


func _draw_game_over() -> void:
	var heart: Texture2D = soul.texture
	var half := heart.get_size() / Vector2(2, 1)
	var corner := _heart_position - heart.get_size() / 2

	if not _shattered:
		if _cracked:
			# Two halves, pulled slightly apart.
			_overlay.draw_texture_rect_region(heart, Rect2(corner + Vector2(-2, 0), half), Rect2(Vector2.ZERO, half))
			_overlay.draw_texture_rect_region(heart, Rect2(corner + Vector2(half.x + 2, 0), half), Rect2(Vector2(half.x, 0), half))
		else:
			_overlay.draw_texture(heart, corner)
	for shard in _shards:
		_overlay.draw_rect(Rect2(shard["position"] - Vector2(2, 2), Vector2(4, 4)), Color.RED)

	if _game_over_time >= TITLE_TIME:
		var alpha := clampf((_game_over_time - TITLE_TIME) / 0.8, 0.0, 1.0)
		_draw_centered("GAME OVER", Vector2(320, 160), 56, Color(1, 1, 1, alpha))
	if _text != "":
		_draw_centered(_text.substr(0, clampi(int(_typed), 0, _text.length())), Vector2(320, 320), 20, Color.WHITE)
		if _text_finished():
			_draw_centered("(press ENTER)", Vector2(320, 360), 14, Color.GRAY)


# --- Fleeing ----------------------------------------------------------------
# MERCY -> Flee: everyone turns and walks off the left side of the screen,
# then it's back to the overworld, right where the fight started.

const FLEE_TIME := 1.8
var _flee_time: float = 0.0
## Side-view walking frames for each party member, loaded when someone flees.
var _side_frames: Dictionary = {}


## True for fights you can't run from: bosses, story fights and scripted ones.
func _can_flee() -> bool:
	return _data.boss_style == "" and _data.survive_turns == 0 and _data.event == "" and _data.id != "tutorial"


func _try_flee() -> void:
	if not _can_flee():
		Game.play_sfx("miss")
		_text = "* You can't run from this fight!"
		_typed = _text.length()
		state = State.MENU
		_place_soul_on_button()
		return
	Game.play_sfx("select")
	for member in party:
		member.defending = false
		var base := "res://art/sprites/" + Game.sprite_base(member.id)
		# (Members without side-view pictures run off with their front picture.)
		if ResourceLoader.exists(base + "_side.png") and ResourceLoader.exists(base + "_side2.png"):
			_side_frames[member] = [load(base + "_side.png"), load(base + "_side2.png")]
		else:
			_side_frames[member] = [member.sprite, member.sprite]
	var names := party.filter(func(m: PartyMember) -> bool: return not m.is_down()).map(func(m: PartyMember) -> String: return m.name)
	_text = "* %s ran away!" % " and ".join(names)
	_typed = _text.length()
	soul.visible = false
	_flee_time = 0.0
	state = State.FLEEING


func _process_flee(delta: float) -> void:
	_flee_time += delta
	if _flee_time >= FLEE_TIME:
		var result := {"id": _data.id, "fled": true, "spared": [], "defeated": [], "bond": 0, "exp": 0, "money": 0}
		if Game.pending_battle != "":
			_leave_battle(func() -> void: Game.finish_battle(result))
		else:
			_leave_battle(get_tree().reload_current_scene)


## How far a party member has walked off to the left while fleeing.
## Everyone turns around first, then walks (the second one a moment later).
func _flee_offset(index: int) -> float:
	var walking := maxf(0.0, _flee_time - 0.25 - index * 0.12)
	return -walking * 230.0


# --- The tent -------------------------------------------------------------
# A very rare "encounter" in Westview. It's just a tent. Then the music stops.

const TENT_LINES := [
	"* ...",
	"* We were here, too.",
	"* Three of us.",
	"* We remember.",
]
const TENT_SCREAM := "DID YOU THINK WE WOULD FORGET?"
## How long each part lasts: silence, the scream, black, and the laugh (the
## jumpscare plays over the start of the laugh).
const TENT_SILENCE := 1.6
const TENT_SCREAM_TIME := 3.0
## (A long, silent black, so you think it's over...)
const TENT_BLACK_TIME := 1.4
const TENT_LAUGH_TIME := 3.8

## "silence", "scream", "black" or "laugh".
var _tent_phase: String = ""
var _tent_time: float = 0.0
## The color of the text in the box (red for the tent).
var _text_color: Color = Color.WHITE
## When the tent froze the background (so it stops right where it was).
var _frozen_at: float = 0.0

## The jumpscare: Hopkuna, laughing, right up against the screen.
const JUMPSCARE_TIME := 2.9
## How much light falls on him: barely any. You know he's there, but all you can
## really see are his eyes.
const JUMPSCARE_LIGHT := 0.07
## When each "HA" of the laugh sound starts and how long it lasts (see Sfx.laugh),
## so his jaw can move with it.
const LAUGH_SYLLABLES := [[0.0, 0.32], [0.5, 0.32], [1.0, 0.3], [1.45, 0.2], [1.7, 0.2], [1.95, 0.2], [2.2, 0.45]]
var _hopkuna_sprite: Texture2D
## Where things are on Hopkuna's sprite (in its pixels, counting the outline): the
## point between his eyes, the two eye pixels, and his teeth.
const HOPKUNA_EYES_MIDDLE := Vector2(13.0, 8.5)
const HOPKUNA_EYE_PIXELS := [Vector2(11, 8), Vector2(14, 8)]
const HOPKUNA_TEETH := [Vector2(11, 11), Vector2(13, 11), Vector2(15, 11)]

## The recorded laugh (audio/sfx/hopkuna_laugh, if it's there): where in the file the
## laughing starts, and how loud it is every 50th of a second from there (0 to 9),
## measured from the recording. His jaw follows it.
const LAUGH_FILE_START := 0.7
const LAUGH_FILE_BOOST_DB := 6.0
const LAUGH_ENVELOPE := "011111122233333444455545555556555656555557765565555455565555665454455555556656653334344545646554444455565555443333445555544333333445444433322345566666654433333445666665544333334678767666645455555555534567777654465565666554445566655444444456655554445677665444433345566655444433222334566777666543322222222334566554444443332222233334789754333455555432111111111"
## The recording's last, loudest burst: his face comes back for a second scare.
const SECOND_SCARE_AT := 6.52
const SECOND_SCARE_TIME := 0.34


## The recorded laugh if there is one, or the made-up one.
func _recorded_laugh() -> bool:
	return Game.has_sfx("hopkuna_laugh")


## The music cuts off. Nothing happens for a moment.
func _tent_silence() -> void:
	Game.stop_music(0.0)
	_frozen_at = Time.get_ticks_msec() / 1000.0
	_text = ""
	state = State.EVENT
	_tent_phase = "silence"
	_tent_time = 0.0


func _process_tent(delta: float) -> void:
	_tent_time += delta
	match _tent_phase:
		"silence":
			if _tent_time >= TENT_SILENCE:
				_text_color = Color(0.85, 0.05, 0.08)
				_show_messages(TENT_LINES, _tent_scream)
		"scream":
			if _tent_time >= TENT_SCREAM_TIME:
				_tent_phase = "black"
				_tent_time = 0.0
				Game.play_sfx("shatter")
		"black":
			if _tent_time >= TENT_BLACK_TIME:
				_tent_phase = "laugh"
				_tent_time = 0.0
				Game.play_sfx("scream")
				if _recorded_laugh():
					Game.play_sfx("hopkuna_laugh", 1.0, LAUGH_FILE_START, LAUGH_FILE_BOOST_DB)
				else:
					Game.play_sfx("laugh")
		"laugh":
			if _recorded_laugh() and _tent_time - delta < SECOND_SCARE_AT and _tent_time >= SECOND_SCARE_AT:
				Game.play_sfx("scream", 0.85)
			var laugh_length := LAUGH_ENVELOPE.length() * 0.02 + 0.3 if _recorded_laugh() else TENT_LAUGH_TIME
			if _tent_time >= laugh_length:
				_tent_phase = "done"
				var result := {"id": _data.id, "spared": [], "defeated": [], "bond": 0, "exp": 0, "money": 0}
				if Game.pending_battle != "":
					_leave_battle(func() -> void: Game.finish_battle(result))
				else:
					_leave_battle(get_tree().reload_current_scene)


func _tent_scream() -> void:
	_text = ""
	state = State.EVENT
	_tent_phase = "scream"
	_tent_time = 0.0
	Game.play_sfx("hurt", 0.5)


## Big shaking red letters, then black.
func _draw_tent() -> void:
	if _tent_phase == "scream":
		# Everything darkens, and the words shake like they're trying to get out.
		_overlay.draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, clampf(_tent_time * 0.6, 0.0, 0.85)))
		var size := 28
		var shown := mini(TENT_SCREAM.length(), int(_tent_time * 40.0))
		# Each letter gets the same width, so they can shake on their own.
		var step := 18.0
		var x := 320.0 - step * TENT_SCREAM.length() / 2.0
		for i in shown:
			var letter := TENT_SCREAM[i]
			var letter_width := _font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			var at := Vector2(x + (step - letter_width) / 2, 190) + Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.5))
			_overlay.draw_string(_font, at + Vector2(2, 2), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.3, 0, 0))
			_overlay.draw_string(_font, at, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.95, 0.05, 0.1))
			x += step
	elif _tent_phase in ["black", "laugh", "done"]:
		_overlay.draw_rect(Rect2(-20, -20, 680, 520), Color.BLACK)
		if _tent_phase == "laugh" and _tent_time < JUMPSCARE_TIME:
			_draw_jumpscare(_tent_time)
		elif _tent_phase == "laugh" and _recorded_laugh() and _tent_time >= SECOND_SCARE_AT and _tent_time < SECOND_SCARE_AT + SECOND_SCARE_TIME:
			_draw_second_scare(_tent_time - SECOND_SCARE_AT)


## How far open Hopkuna's jaw is at `time` into the laugh: wide open for the
## scream, then snapping open on each "HA".
func _laugh_jaw(time: float) -> float:
	if time < 0.35:
		return 1.0
	if _recorded_laugh():
		var index := clampi(int(time / 0.02), 0, LAUGH_ENVELOPE.length() - 1)
		# Averaged with its neighbours, so the jaw doesn't rattle.
		var level := 0.0
		for k in range(index - 2, index + 3):
			level += int(LAUGH_ENVELOPE[clampi(k, 0, LAUGH_ENVELOPE.length() - 1)])
		return clampf((level / 5.0 - 2.0) / 6.0, 0.1, 1.0)
	var open := 0.15
	for syllable in LAUGH_SYLLABLES:
		var into: float = time - syllable[0]
		if into >= 0.0 and into < syllable[1] + 0.1:
			open = maxf(open, sin(clampf(into / (syllable[1] + 0.1), 0.0, 1.0) * PI))
	return open


## The jumpscare, over black. It's Hopkuna's own sprite, blown up huge, almost
## entirely in the dark: just the shape of him, his two red eyes glowing, and a
## glint off his teeth. He jerks with each burst of the laugh.
##   SLAM    he lunges in from huge to filling the screen, with the scream
##   HOLD    for half a second, shaking, laughing
##   FLICKER cutting between him, a red ghosted copy, a tighter close-up, an even
##           darker frame, and black with only the eyes (never faster than about 8
##           cuts a second; with Reduce flashing on, it just holds on him)
##   LUNGE   one last rush at the screen, then black (the laugh carries on)
func _draw_jumpscare(time: float) -> void:
	var focus := Vector2(320, 210)
	var laugh := _laugh_jaw(time)
	var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * (14.0 if time < 0.6 else 6.0)
	var size := 34.0 + time * 2.0
	var mode := 0
	if time < 0.14:
		var slam := time / 0.14
		size = lerpf(80.0, 34.0, 1.0 - pow(1.0 - slam, 3.0))
	elif time > JUMPSCARE_TIME - 0.22:
		var lunge := (time - (JUMPSCARE_TIME - 0.22)) / 0.22
		size = lerpf(40.0, 110.0, lunge * lunge)
	elif time > 0.6 and not Game.reduce_flashing():
		# A new cut every 0.13 seconds, chosen at random (but never two blacks in a row).
		var cut := int((time - 0.6) / 0.13)
		var rng := RandomNumberGenerator.new()
		rng.seed = cut * 7919 + 3
		mode = rng.randi_range(0, 9)
		if mode == 2 and cut % 2 == 1:
			mode = 0
	match mode:
		2, 3:
			# Black: only the eyes.
			_draw_hopkuna_in_dark(focus + shake, size, laugh, 0.0)
		4:
			_draw_hopkuna_in_dark(focus + shake, size * 1.15, laugh, JUMPSCARE_LIGHT * 0.4)
		5, 6:
			# A tight close-up on his eyes and grin.
			_draw_hopkuna_in_dark(focus + Vector2(0, 40) + shake, size * 1.8, laugh, JUMPSCARE_LIGHT)
		7:
			# Ghosted: a red copy split off to one side.
			_draw_hopkuna_in_dark(focus + shake + Vector2(18, 0), size, laugh, JUMPSCARE_LIGHT, Color(1.0, 0.1, 0.1, 0.5))
			_draw_hopkuna_in_dark(focus + shake, size, laugh, JUMPSCARE_LIGHT)
		_:
			_draw_hopkuna_in_dark(focus + shake, size, laugh, JUMPSCARE_LIGHT)
	_draw_jumpscare_grime(time)


## The second scare, on the laugh's last burst: out of the dark, he rushes in even
## closer than before, then he's gone.
func _draw_second_scare(time: float) -> void:
	var rush := clampf(time / 0.08, 0.0, 1.0)
	var size := lerpf(110.0, 52.0, 1.0 - pow(1.0 - rush, 3.0)) + time * 20.0
	var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 18.0
	_draw_hopkuna_in_dark(Vector2(320, 200) + shake, size, 1.0, JUMPSCARE_LIGHT)
	_draw_jumpscare_grime(time + 10.0)


## Hopkuna's sprite, `size` screen pixels per sprite pixel, with the point between
## his eyes at `focus`. `light` is how much of him you can see (0 = only the eyes).
## His eyes glow at full strength no matter what, and his teeth catch a little light.
func _draw_hopkuna_in_dark(focus: Vector2, size: float, laugh: float, light: float, tint: Color = Color.WHITE) -> void:
	if _hopkuna_sprite == null:
		_hopkuna_sprite = load("res://art/sprites/hopkuna.png")
	# He jerks up and stretches a little with each burst of laughter.
	var stretch := Vector2(1.0 - 0.03 * laugh, 1.0 + 0.06 * laugh)
	var pixel := Vector2(size, size) * stretch
	var origin := focus - HOPKUNA_EYES_MIDDLE * pixel - Vector2(0, laugh * size * 0.5)
	var spot := func(texel: Vector2) -> Vector2: return origin + texel * pixel
	if light > 0.0:
		var dim := Color(light * 1.3, light, light, 1.0) * tint
		_overlay.draw_texture_rect(_hopkuna_sprite, Rect2(origin, _hopkuna_sprite.get_size() * pixel), false, dim)
		# The grin: his tooth pixels catch a little of the light.
		for tooth in HOPKUNA_TEETH:
			_overlay.draw_rect(Rect2(spot.call(tooth), pixel), Color(0.9, 0.85, 0.7, 0.12) * tint)
	# The eyes: two glowing red pixels with soft light around them.
	for eye in HOPKUNA_EYE_PIXELS:
		var middle: Vector2 = spot.call(eye + Vector2(0.5, 0.5))
		_soft_glow(middle, size * 3.2, Color(1.0, 0.08, 0.1, 0.32) * tint)
		_soft_glow(middle, size * 1.3, Color(1.0, 0.15, 0.12, 0.6) * tint)
		_overlay.draw_rect(Rect2(spot.call(eye), pixel), Color(1.0, 0.12, 0.12) * tint)
		_overlay.draw_rect(Rect2(spot.call(eye) + pixel * 0.3, pixel * 0.4), Color(1.0, 0.75, 0.6) * tint)


## A soft round glow that fades out to nothing at `radius`.
func _soft_glow(center: Vector2, radius: float, color: Color) -> void:
	var clear := Color(color, 0.0)
	for k in 24:
		var a := center + Vector2.from_angle(k * TAU / 24) * radius
		var b := center + Vector2.from_angle((k + 1) * TAU / 24) * radius
		_overlay.draw_polygon(PackedVector2Array([center, a, b]), PackedColorArray([color, clear, clear]))


## Over the face: a red vignette, scanlines, film grain, and torn glitch bars.
func _draw_jumpscare_grime(time: float) -> void:
	for k in 8:
		_overlay.draw_rect(Rect2(-20, -20, 680, 520).grow(-k * 16), Color(0.25, 0.0, 0.02, 0.07), false, 16.0)
	for y in range(0, 480, 3):
		_overlay.draw_line(Vector2(0, y), Vector2(640, y), Color(0, 0, 0, 0.22), 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(time * 30.0)
	for g in 300:
		var spot := Vector2(rng.randf() * 640.0, rng.randf() * 480.0)
		_overlay.draw_rect(Rect2(spot, Vector2(2, 2)), Color(1, 1, 1, rng.randf() * 0.12))
	if time > 0.14 and not Game.reduce_flashing():
		for bar in rng.randi_range(0, 3):
			var y := rng.randf() * 480.0
			var height := rng.randf_range(3.0, 14.0)
			_overlay.draw_rect(Rect2(0, y, 640, height), Color(0, 0, 0, 0.8) if rng.randf() < 0.5 else Color(0.9, 0.05, 0.1, 0.35))


# --- Helpers --------------------------------------------------------------

func _pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)


func _active_enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for enemy in enemies:
		if enemy.is_active():
			result.append(enemy)
	return result


## Items nobody has already picked this turn.
func _available_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in items:
		var taken := false
		for action in actions:
			# is_same() checks for this exact item, so two Trail Mixes count separately.
			if is_same(action.get("item"), item):
				taken = true
		# Accessories are worn, not eaten: they stay out of the ITEM menu.
		if not taken and not Items.is_accessory(item):
			result.append(item)
	return result


## A number or word that pops up and fades (damage, healing, MISS...).
## Bouncing ones jump up and fall back down, like a hit landing.
func _add_popup(text: String, at: Vector2, color: Color, size: int = 20, bounce: bool = false) -> void:
	_popups.append({
		"text": text, "position": at, "color": color, "size": size, "time": 1.1 if bounce else 0.8,
		"velocity": Vector2(0, -170) if bounce else Vector2(0, -30), "gravity": 520.0 if bounce else 0.0,
	})


func _update_effects(delta: float) -> void:
	for popup in _popups:
		popup["time"] -= delta
		popup["velocity"] += Vector2(0, popup["gravity"]) * delta
		popup["position"] += popup["velocity"] * delta
	_popups.assign(_popups.filter(func(p: Dictionary) -> bool: return p["time"] > 0.0))
	for enemy in enemies:
		enemy.shake = maxf(enemy.shake - delta, 0.0)
		enemy.flash = maxf(enemy.flash - delta, 0.0)
		if enemy.ko_time >= 0.0:
			enemy.ko_time += delta
		# The health bar drains smoothly toward the real HP.
		if enemy.shown_hp < 0.0:
			enemy.shown_hp = enemy.hp
		enemy.shown_hp = move_toward(enemy.shown_hp, enemy.hp, enemy.max_hp * 0.8 * delta)
	_impact_time = maxf(_impact_time - delta, 0.0)
	_soul_flash = maxf(_soul_flash - delta, 0.0)
	_squash_time = maxf(_squash_time - delta, 0.0)
	for member in _member_anim:
		_member_anim[member]["time"] += delta
	for member in party:
		member.shake = maxf(member.shake - delta, 0.0)
		member.ko_time = member.ko_time + delta if member.is_down() else 0.0


func _row_y(row: int) -> float:
	return box.get_inner_rect().position.y + 26 + row * LINE_HEIGHT


func _panel_position(member: PartyMember) -> Vector2:
	return Vector2(110 + party.find(member) * 300, PANEL_Y - 12)


# --- Drawing --------------------------------------------------------------

func _draw_overlay() -> void:
	if state == State.GAME_OVER:
		_draw_game_over()
		return

	_draw_aura()
	_draw_party_sprites()
	_draw_shield()
	_draw_call()
	_draw_enemies()
	_draw_boss_bar()
	_draw_soul_owner()
	_draw_slash()
	_draw_party_panel()
	_draw_buttons()
	_draw_box_contents()

	for popup in _popups:
		# A dark outline behind the text keeps numbers readable over anything.
		var size: int = popup["size"]
		for offset in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
			_draw_centered(popup["text"], popup["position"] + offset, size, Color(0, 0, 0, 0.8))
		_draw_centered(popup["text"], popup["position"], size, popup["color"])

	if _data and _data.event == "tent":
		_draw_tent()
	_draw_impact()


# --- Impact frames ------------------------------------------------------------
# When a blow lands, everything freezes for an instant (hit-stop), and for a couple
# of frames the screen goes stark white with the enemy as a black silhouette and
# speed lines bursting from the hit, like a manga panel. A CRITICAL also flips to
# an inverted frame (black screen, white silhouette, red lines).

const IMPACT_FLASH := 0.07

var _hitstop: float = 0.0
var _impact_time: float = 0.0
var _impact_length: float = 0.0
var _impact_target: Enemy
var _impact_critical: bool = false
## A BLACK FLASH's impact: longer, flickering between black and red, with lightning.
var _impact_black: bool = false
const BLACK_FLASH_FREEZE := 0.42


func _impact(target: Enemy, freeze: float, critical: bool) -> void:
	_hitstop = freeze
	_impact_target = target
	_impact_critical = critical
	_impact_black = false
	_impact_length = maxf(IMPACT_FLASH * (2.0 if critical else 1.0), freeze if freeze >= BLACK_FLASH_FREEZE else 0.0)
	_impact_time = _impact_length


func _draw_impact() -> void:
	if _impact_time <= 0.0 or _impact_target == null:
		return
	if _impact_black:
		_draw_black_flash_frames()
		return
	# Reduce flashing: keep the freeze and shake, skip the full-screen flash.
	if Game.reduce_flashing():
		return
	var inverted := _impact_critical and _impact_time < _impact_length / 2
	var background := Color.BLACK if inverted else Color(1, 1, 1, 0.92)
	var ink := Color.WHITE if inverted else Color.BLACK
	_overlay.draw_rect(Rect2(-20, -20, 680, 520), background)
	# Speed lines bursting out from the hit.
	var center := _impact_target.position + Vector2(0, -20)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_impact_time * 1000.0)
	for i in 28:
		var angle := i * TAU / 28 + rng.randf_range(-0.08, 0.08)
		var dir := Vector2.from_angle(angle)
		var from := center + dir * rng.randf_range(50, 90)
		var to := center + dir * 700
		var width := rng.randf_range(1.0, 5.0)
		_overlay.draw_line(from, to, Color(1.0, 0.15, 0.2) if inverted else ink, width)
	# The enemy, as a solid silhouette.
	var enemy := _impact_target
	if enemy.sprite:
		var size := enemy.sprite.get_size() * enemy.battle_scale
		var rect := Rect2(Vector2(enemy.position.x - size.x / 2, enemy.position.y + 40.0 - size.y), size)
		_overlay.draw_texture_rect(enemy.sprite, rect, false, Color(8, 8, 8) if inverted else Color(0, 0, 0))


# --- Weapon attacks -----------------------------------------------------------
# What the attacker has in their Weapon slot changes how they attack:
#   Nail File    a flurry of quick silver jabs, sparks flying
#   Foam Finger  a giant foam finger swings down and BONKS the enemy flat
# Without a weapon, Elric slashes with their claws and Hop throws punches.

## When each Nail File jab lands, in seconds after the bar is stopped (one per bar).
const FILE_JABS := [0.06, 0.15, 0.24]

## Squashing an enemy flat (after a BONK).
var _squash_enemy: Enemy
var _squash_time: float = 0.0


## "file", "finger", or "" (no weapon / a weapon with no special attack).
func _weapon_style(member: PartyMember) -> String:
	if member == null or Game.pending_battle == "":
		return ""
	var weapon: Dictionary = Game.worn_by(member.name).get("weapon", {})
	match weapon.get("name", ""):
		"Nail File": return "file"
		"Foam Finger": return "finger"
	return ""


## Did the Nail File's bar number `i` hit? (Outside of Nail File attacks, every jab counts.)
func _file_jab_landed(i: int) -> bool:
	return _file_bars.is_empty() or (i < _file_bars.size() and _file_bars[i]["accuracy"] >= 0.0)


func _file_hit_count() -> int:
	var count := 0
	for i in FILE_JABS.size():
		if _file_jab_landed(i):
			count += 1
	return maxi(count, 1)


## A jagged lightning bolt from `from` to `to`. The same `seed` gives the same bolt.
func _draw_bolt(from: Vector2, to: Vector2, color: Color, width: float, seed_value: int, canvas: CanvasItem = null) -> void:
	if canvas == null:
		canvas = _overlay
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points := PackedVector2Array([from])
	var steps := 9
	var side := (to - from).orthogonal().normalized()
	for k in range(1, steps):
		points.append(from.lerp(to, float(k) / steps) + side * rng.randf_range(-16.0, 16.0))
	points.append(to)
	canvas.draw_polyline(points, color, width)
	# A short fork off the middle.
	var fork_at := points[steps / 2]
	canvas.draw_polyline(PackedVector2Array([fork_at, fork_at + side * 22.0 + (to - from).normalized() * 18.0, fork_at + side * 30.0 + (to - from).normalized() * 40.0]), color, width * 0.6)


## BLACK FLASH impact frames: the screen snaps between black-on-red and
## red-on-black several times, with black and red lightning crashing into the
## enemy (a silhouette, then inverted), and the hit warping the air around it.
func _draw_black_flash_frames() -> void:
	var enemy := _impact_target
	var center := enemy.position + Vector2(0, -20)
	var progress := 1.0 - _impact_time / _impact_length
	# Reduce flashing: one steady dark frame instead of flickering black and red.
	var frame := 0 if Game.reduce_flashing() else int(progress * 7.0)
	var red := Color(0.85, 0.02, 0.08)
	var black := Color(0.02, 0.0, 0.0)
	var background := black if frame % 2 == 0 else red
	if Game.reduce_flashing():
		background = Color(0, 0, 0, 0.55)
	var ink := red if frame % 2 == 0 else black
	_overlay.draw_rect(Rect2(-20, -20, 680, 520), background)
	# Bolts crashing down from every direction into the hit.
	for b in 7:
		var angle := b * TAU / 7 + frame * 0.6
		var from := center + Vector2.from_angle(angle) * 420.0
		_draw_bolt(from, center, Color(ink, 0.35), 9.0, frame * 31 + b)
		_draw_bolt(from, center, ink, 3.0, frame * 31 + b)
		_draw_bolt(from, center, Color(1, 1, 1, 0.8) if frame % 2 == 1 else Color(1, 0.6, 0.6, 0.8), 1.0, frame * 31 + b)
	# The warp: rings squeezing in on the hit.
	for r in 3:
		_overlay.draw_arc(center, (1.0 - fmod(progress * 3.0 + r / 3.0, 1.0)) * 140.0, 0, TAU, 40, ink, 2.0)
	if enemy.sprite:
		var size := enemy.sprite.get_size() * enemy.battle_scale
		var rect := Rect2(Vector2(enemy.position.x - size.x / 2, enemy.position.y + 40.0 - size.y), size)
		_overlay.draw_texture_rect(enemy.sprite, rect, false, Color(0, 0, 0) if frame % 2 == 1 else Color(10, 1, 1))
	_overlay.draw_circle(center, 14.0 + 10.0 * sin(progress * PI), Color(1, 1, 1))
	_overlay.draw_circle(center, 7.0, Color(0, 0, 0))


## Nail File: a silver jab for each bar that hit, stabbing in from the left, each leaving a spark,
## then a final bright slash.
func _draw_file_strike() -> void:
	var center := _bar_target.position + Vector2(0, -20)
	var silver := Color(0.88, 0.9, 0.95)
	for i in FILE_JABS.size():
		var age: float = _anim_time - FILE_JABS[i]
		if age < -0.04 or age > 0.25 or not _file_jab_landed(i):
			continue
		var at := center + Vector2(-6 + (i % 2) * 12, -22 + i * 13)
		var reach := clampf((age + 0.04) / 0.05, 0.0, 1.0)
		var fade := clampf(1.0 - age / 0.25, 0.0, 1.0)
		var from := at + Vector2(-70, 8)
		_overlay.draw_line(from, from.lerp(at, reach), Color(silver, 0.35 * fade), 7.0)
		_overlay.draw_line(from, from.lerp(at, reach), Color(silver, fade), 2.0)
		if age >= 0.0:
			for s in 6:
				var dir := Vector2.from_angle(s * TAU / 6 + i)
				_overlay.draw_line(at + dir * (3 + age * 40), at + dir * (7 + age * 60), Color(1, 1, 0.8, fade), 1.5)
	if _anim_landed:
		var fade := clampf(1.0 - (_anim_time - ATTACK_SLASH_TIME) / 0.4, 0.0, 1.0)
		_overlay.draw_line(center + Vector2(-50, 40), center + Vector2(50, -40), Color(silver, fade), 3.0)
		_overlay.draw_line(center + Vector2(-50, 40), center + Vector2(50, -40), Color(1, 1, 1, fade), 1.0)


## Foam Finger: a giant yellow foam finger swings down from above like a hammer,
## then hangs there for a moment while stars circle the enemy's head.
func _draw_foam_finger() -> void:
	var target := _bar_target
	var pivot := target.position + Vector2(-90, -105)
	var swing := clampf(_anim_time / ATTACK_SLASH_TIME, 0.0, 1.0)
	var angle := lerpf(-1.8, 0.6, swing * swing)
	var fade := clampf(1.0 - (_anim_time - ATTACK_SLASH_TIME - 0.5) / 0.3, 0.0, 1.0)
	if fade <= 0.0:
		return
	_overlay.draw_set_transform(pivot, angle, Vector2(0.8, 0.8))
	var yellow := Color(1.0, 0.85, 0.2, fade)
	var dark := Color(0.75, 0.55, 0.05, fade)
	# The handle, the big foam hand, and the pointing finger.
	_overlay.draw_rect(Rect2(0, -6, 60, 12), dark)
	_overlay.draw_rect(Rect2(56, -22, 46, 44), yellow)
	_overlay.draw_rect(Rect2(56, -22, 46, 44), dark, false, 2.0)
	_overlay.draw_rect(Rect2(98, -10, 44, 16), yellow)
	_overlay.draw_rect(Rect2(98, -10, 44, 16), dark, false, 2.0)
	_overlay.draw_string(_font, Vector2(62, 6), "#1", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.1, 0.1, fade))
	_overlay.draw_set_transform(Vector2.ZERO)
	# Stars circling after the BONK.
	if _anim_landed:
		var head := target.position + Vector2(0, -70)
		var t := _anim_time * 6.0
		for s in 4:
			var star := head + Vector2(cos(t + s * TAU / 4) * 26.0, sin(t + s * TAU / 4) * 8.0)
			_overlay.draw_line(star + Vector2(-4, 0), star + Vector2(4, 0), Color(1, 0.95, 0.4, fade), 2.0)
			_overlay.draw_line(star + Vector2(0, -4), star + Vector2(0, 4), Color(1, 0.95, 0.4, fade), 2.0)


## The attack animation: three glowing slashes sweep across the enemy, in the
## attacker's color (gold for a CRITICAL), then flare out.
func _draw_slash() -> void:
	if state != State.FIGHT_ANIM or _bar_target == null:
		return
	match _weapon_style(_bar_member):
		"file":
			_draw_file_strike()
			return
		"finger":
			_draw_foam_finger()
			return
	if _bar_member.name == "Hop":
		_draw_hop_strike()
		return
	var progress := clampf(_anim_time / ATTACK_SLASH_TIME, 0.0, 1.0)
	var fade := clampf(1.0 - (_anim_time - ATTACK_SLASH_TIME) / 0.35, 0.0, 1.0)
	if fade <= 0.0:
		return
	var color := YELLOW if _anim_accuracy >= CRITICAL else _bar_member.color
	var center := _bar_target.position + Vector2(0, -20)
	for i in 3:
		var offset := Vector2(-16 + i * 16, -6 + i * 6)
		var from := center + offset + Vector2(38, -42)
		var to := center + offset + Vector2(-38, 42)
		var tip := from.lerp(to, progress)
		_overlay.draw_line(from, tip, Color(color, 0.35 * fade), 10.0)
		_overlay.draw_line(from, tip, Color(color, fade), 4.0)
		_overlay.draw_line(from, tip, Color(1, 1, 1, fade), 1.5)
	# A burst of sparks where the hit lands.
	if _anim_landed:
		var burst := (_anim_time - ATTACK_SLASH_TIME) / 0.35
		for i in 10:
			var dir := Vector2.from_angle(i * TAU / 10 + 0.3)
			_overlay.draw_line(center + dir * (10 + burst * 30), center + dir * (18 + burst * 46), Color(color, fade), 2.0)


## Wally's dance, in time with his song (152 beats per minute): a hop on every beat
## (squashing a little when he lands), a sway side to side, and every eighth beat
## a full spin. `feet` is where his feet touch the ground.
func _dance_transform(feet: Vector2) -> void:
	var beat := Time.get_ticks_msec() / 1000.0 * 152.0 / 60.0
	var hop := absf(sin(beat * PI))
	var squash := 1.0 - 0.08 * (1.0 - hop)
	var sway := sin(beat * PI * 0.5) * 0.07
	var spin := 1.0
	var into_bar := fmod(beat, 8.0)
	if into_bar > 7.0:
		spin = cos((into_bar - 7.0) * TAU)
	_overlay.draw_set_transform(feet - Vector2(0, hop * 10.0), sway, Vector2(spin * (2.0 - squash), squash))


## When each of Hop's three punches lands, in seconds after the bar is stopped.
const HOP_PUNCHES := [0.06, 0.18, 0.3]

## Hop doesn't slash. He throws three fast punches, each one cracking the air with
## a red shockwave, and finishes with a red X that lingers a little too long...
func _draw_hop_strike() -> void:
	var center := _bar_target.position + Vector2(0, -20)
	var red := Color(1.0, 0.15, 0.2)
	var dark := Color(0.35, 0.0, 0.05)
	var critical := _anim_accuracy >= CRITICAL
	var spots := [Vector2(-18, -14), Vector2(16, 6), Vector2(-4, -2)]
	for i in HOP_PUNCHES.size():
		var age: float = _anim_time - HOP_PUNCHES[i]
		if age < 0.0 or age > 0.45:
			continue
		var at: Vector2 = center + spots[i]
		var grow := age / 0.45
		var fade := 1.0 - grow
		# A fist-sized impact flash...
		_overlay.draw_circle(at, 10.0 * (1.0 - grow * 0.5), Color(1, 0.9, 0.9, fade))
		# ...a shockwave ring...
		_overlay.draw_arc(at, 8.0 + grow * 34.0, 0, TAU, 20, Color(red, fade), 3.0)
		_overlay.draw_arc(at, 4.0 + grow * 22.0, 0, TAU, 16, Color(dark, fade), 2.0)
		# ...and jagged cracks shooting out from the hit.
		for c in 5:
			var dir := Vector2.from_angle(c * TAU / 5 + i)
			var mid := at + dir * (10 + grow * 14) + dir.orthogonal() * 4.0
			var end := at + dir * (16 + grow * 26)
			_overlay.draw_polyline(PackedVector2Array([at + dir * 6, mid, end]), Color(red, fade), 2.0)
	# After a BLACK FLASH, black and red sparks of lightning keep crackling off the target.
	if _black_flash and _anim_landed:
		var crackle := _anim_time - ATTACK_SLASH_TIME
		if crackle < 0.8:
			var seed_step := int(crackle * 20.0)
			for b in 4:
				var dir := Vector2.from_angle(b * TAU / 4 + seed_step)
				var fade := 1.0 - crackle / 0.8
				_draw_bolt(center + dir * 8.0, center + dir * (50.0 + 20.0 * fade), Color(0.02, 0, 0, fade), 4.0, seed_step * 7 + b)
				_draw_bolt(center + dir * 8.0, center + dir * (50.0 + 20.0 * fade), Color(1, 0.1, 0.15, fade), 1.5, seed_step * 7 + b)
	# The finisher: a red X burned across the target, with a dark smoky edge.
	var x_age := _anim_time - ATTACK_SLASH_TIME
	if x_age >= 0.0:
		var fade := clampf(1.0 - (x_age - 0.35) / 0.5, 0.0, 1.0)
		var size := 30.0 + minf(x_age, 0.1) * 120.0 + (8.0 if critical else 0.0)
		for diagonal in [Vector2(1, 1), Vector2(1, -1)]:
			var arm: Vector2 = diagonal.normalized() * size
			_overlay.draw_line(center - arm, center + arm, Color(dark, 0.6 * fade), 12.0)
			_overlay.draw_line(center - arm, center + arm, Color(YELLOW if critical else red, fade), 5.0)
			_overlay.draw_line(center - arm, center + arm, Color(1, 0.85, 0.85, fade), 1.5)
		# Embers drifting up off the hit.
		for e in 8:
			var drift := Vector2(sin(e * 2.3) * 22.0, -x_age * (40.0 + e * 8.0))
			_overlay.draw_rect(Rect2(center + drift + Vector2(e * 3 - 12, 10), Vector2(2, 2)), Color(red, fade))


## How each kind of enemy moves when it winds up an attack (at the start of its
## turn) and when it throws one (every time it launches bullets).
##   bounce  (Eggo)            squashes down, then hops with each throw
##   charge  (BigJoe6)         leans back, then lunges forward
##   flutter (papers & books)  wobbles, then flicks
##   swing   (Tardy Bell)      swings like a ringing bell
##   jiggle  (Mystery Meat)    wobbles like jelly, then splats
##   menace  (Hopkuna)         swells up, then snaps forward
##   dance   (Wally)           his halftime show (see _dance_transform)
const ENEMY_STYLES := {
	"eggo": "bounce", "bigjoe6": "charge", "pop_quiz": "flutter", "hall_pass": "flutter",
	"overdue_book": "flutter", "tardy_bell": "swing", "mystery_meat": "jiggle", "hopkuna": "menace",
}
const ENEMY_WINDUP_TIME := 0.45


## The enemy's sprite file name, like "eggo".
func _enemy_kind(enemy: Enemy) -> String:
	return enemy.sprite.resource_path.get_file().get_basename() if enemy.sprite else ""


## [offset, rotation, scale] for an enemy right now: idle bobbing, its windup at the
## start of an attack, the jolt each time it throws something, or its KO.
func _enemy_motion(enemy: Enemy) -> Array:
	var t := Time.get_ticks_msec() / 1000.0
	var offset := Vector2.ZERO
	var rot := 0.0
	var scale := Vector2.ONE
	var style: String = ENEMY_STYLES.get(_enemy_kind(enemy), "")
	if enemy.state == "defeated":
		# KO: shudder, then topple over backwards and stay down.
		var k := maxf(enemy.ko_time, 0.0)
		if k < 0.3:
			offset.x = sin(k * 70.0) * 5.0
		var fall := clampf((k - 0.3) / 0.4, 0.0, 1.0)
		# (They fall toward the middle of the screen, so they stay in view.)
		rot = -PI / 2 * (1.0 - pow(1.0 - fall, 3)) * 0.92
		offset.x -= 14.0 * fall
		return [offset, rot, scale]
	if not enemy.is_active() or _data.event != "":
		return [offset, rot, scale]
	# Idle: everyone still fighting bobs gently, each at their own pace.
	offset.y = sin(t * 2.2 + enemy.position.x * 0.05) * 2.5
	# Flattened by a BONK, springing back.
	if enemy == _squash_enemy and _squash_time > 0.0:
		var flat := _squash_time / 0.45
		scale = Vector2(1.0 + 0.4 * flat, 1.0 - 0.45 * flat)
		return [offset, rot, scale]
	if state != State.ENEMY_TURN or not _attackers.has(enemy):
		return [offset, rot, scale]
	var clock := ENEMY_TURN_TIME - _enemy_timer
	# Rises and falls once over the windup.
	var windup := sin(clampf(clock / ENEMY_WINDUP_TIME, 0.0, 1.0) * PI)
	var throw := clampf(1.0 - (clock - float(_last_spawn.get(enemy, -9.0))) / 0.25, 0.0, 1.0)
	match style:
		"bounce":
			scale = Vector2(1.0 + 0.15 * windup, 1.0 - 0.18 * windup)
			offset.y -= 18.0 * sin(throw * PI)
		"charge":
			rot = 0.14 * windup - 0.08 * throw
			offset.x = 6.0 * windup - 22.0 * throw
		"flutter":
			rot = sin(t * 30.0) * 0.12 * windup - 0.25 * throw
			scale = Vector2.ONE * (1.0 + 0.1 * throw)
		"swing":
			rot = sin(t * 12.0) * (0.12 + 0.2 * windup) + sin(t * 40.0) * 0.08 * throw
		"jiggle":
			var wobble := sin(t * 18.0) * (0.06 + 0.1 * windup)
			scale = Vector2(1.0 + wobble + 0.2 * throw, 1.0 - wobble - 0.2 * throw)
		"menace":
			scale = Vector2.ONE * (1.0 + 0.12 * windup + 0.06 * throw)
			offset.x = -10.0 * throw
		_:
			rot = 0.08 * windup
			offset.x = -12.0 * throw
	return [offset, rot, scale]


## The picture shown for a moment when an enemy is hit: their shocked face, for
## anyone who has one (Eggo and BigJoe6), otherwise their normal picture.
var _hurt_pictures: Dictionary = {}

func _enemy_hurt_picture(enemy: Enemy) -> Texture2D:
	var kind := _enemy_kind(enemy)
	if not _hurt_pictures.has(kind):
		var path := "res://art/portraits/%s_shocked.png" % kind
		_hurt_pictures[kind] = load(path) if ResourceLoader.exists(path) else enemy.sprite
	return _hurt_pictures[kind]


## An enemy's face for their current mood (art/portraits/<kind>_<mood>.png), if they have one.
func _enemy_mood_picture(enemy: Enemy) -> Texture2D:
	var key := _enemy_kind(enemy) + "_" + enemy.mood
	if not _hurt_pictures.has(key):
		var path := "res://art/portraits/%s.png" % key
		_hurt_pictures[key] = load(path) if ResourceLoader.exists(path) else enemy.sprite
	return _hurt_pictures[key]


## Dust puffing up as a knocked-out enemy hits the ground.
func _draw_enemy_ko_dust(enemy: Enemy, feet: Vector2) -> void:
	if enemy.state != "defeated" or enemy.ko_time < 0.55 or enemy.ko_time > 1.3:
		return
	var age := (enemy.ko_time - 0.55) / 0.75
	for puff in 6:
		var dir := -1.0 if puff % 2 == 0 else 1.0
		var at := feet + Vector2(dir * (10.0 + puff * 6.0 + age * 30.0), -4.0 - age * 14.0 - puff * 2.0)
		_overlay.draw_circle(at, 6.0 * (1.0 - age) + 2.0, Color(0.75, 0.72, 0.68, 0.6 * (1.0 - age)))


func _draw_enemies() -> void:
	for enemy in enemies:
		var pos := enemy.position
		if enemy.shake > 0.0:
			pos.x += sin(enemy.shake * 60.0) * 4.0

		var alpha := 1.0 if enemy.is_active() else 0.35
		# Knocked-out enemies turn gray; spared ones fade out.
		var tint := Color(0.4, 0.4, 0.4) if enemy.state == "defeated" else Color(1, 1, 1, alpha)
		var top := pos.y - 40.0

		if enemy.sprite:
			# Pixel art is drawn big (3x by default) so each pixel shows up as a crisp block.
			var sprite_size := enemy.sprite.get_size() * enemy.battle_scale
			top = pos.y + 40.0 - sprite_size.y
			var feet := Vector2(pos.x, pos.y + 40.0)
			var feet_rect := Rect2(Vector2(-sprite_size.x / 2, -sprite_size.y), sprite_size)
			# A soft shadow on the ground.
			if enemy.state != "spared":
				_overlay.draw_set_transform(feet, 0.0, Vector2(1.0, 0.28))
				_overlay.draw_circle(Vector2.ZERO, sprite_size.x * 0.4, Color(0, 0, 0, 0.35))
				_overlay.draw_set_transform(Vector2.ZERO)
			if enemy.dance and enemy.is_active():
				_dance_transform(feet + _enemy_motion(enemy)[0])
			else:
				var motion := _enemy_motion(enemy)
				_overlay.draw_set_transform(feet + motion[0], motion[1], motion[2])
			# When hit, some enemies show their shocked face for a moment.
			var picture := enemy.sprite
			if enemy.shake > 0.2 and enemy.is_active():
				picture = _enemy_hurt_picture(enemy)
			elif enemy.mood != "":
				picture = _enemy_mood_picture(enemy)
			_overlay.draw_texture_rect(picture, feet_rect, false, tint)
			# Flash white for a moment when hit.
			if enemy.flash > 0.0:
				_overlay.draw_texture_rect(picture, feet_rect, false, Color(4, 4, 4, enemy.flash * 3.0))
			_overlay.draw_set_transform(Vector2.ZERO)
			_draw_enemy_ko_dust(enemy, feet)
		else:
			# Placeholder figure: a blocky head and body.
			_overlay.draw_rect(Rect2(pos + Vector2(-24, -10), Vector2(48, 50)), enemy.body_color * tint)
			_overlay.draw_rect(Rect2(pos + Vector2(-16, -40), Vector2(32, 30)), enemy.head_color * tint)

		var name_color := YELLOW if enemy.is_active() and enemy.can_spare() else Color.WHITE
		name_color.a = alpha
		_draw_centered(enemy.name, Vector2(pos.x, top - 8), FONT_SIZE, name_color)

		match enemy.state:
			"spared":
				_draw_centered("SPARED", pos + Vector2(0, 62), FONT_SIZE, YELLOW)
			"defeated":
				_draw_centered("KO", pos + Vector2(0, 62), FONT_SIZE, Color.LIGHT_GRAY)
			_:
				# Bosses show their health in the big bar at the top instead,
				# and the tent event has no health at all.
				if _data.boss_style == "" and _data.event == "":
					_draw_bar(Rect2(pos + Vector2(-45, 47), Vector2(90, 10)), float(enemy.hp) / enemy.max_hp, Color.GREEN, enemy.shown_hp / enemy.max_hp)

		if _speech.has(enemy) and _speech[enemy] != "":
			_draw_speech(_speech[enemy], Vector2(pos.x, top - 30))


const BOSS_BAR := Rect2(200, 8, 412, 14)

## A boss's health, in a big bar across the top of the screen that's always visible,
## styled to match the boss.
##   wally:   gold fur, a dark brown frame, and three claw marks torn into it.
##   hopkuna: pulsing red, black tattoo zigzags, and "???" instead of numbers.
func _draw_boss_bar() -> void:
	if _data.boss_style == "" or enemies.is_empty():
		return
	var boss := enemies[0]
	var fraction := float(boss.hp) / boss.max_hp
	var trailing := boss.shown_hp / boss.max_hp
	var rect := BOSS_BAR
	var t := Time.get_ticks_msec() / 1000.0
	match _data.boss_style:
		"wally":
			var fill := Color(0.95, 0.68, 0.18)
			_draw_outlined(boss.name.to_upper(), Vector2(22, rect.end.y), 15, fill)
			_overlay.draw_rect(rect.grow(3), Color(0.3, 0.18, 0.08))
			_overlay.draw_rect(rect.grow(1), Color(0.55, 0.36, 0.16))
			_overlay.draw_rect(rect, Color(0.2, 0.1, 0.05))
			if trailing > fraction:
				_overlay.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(trailing, 0, 1), rect.size.y)), Color(1, 0.95, 0.75))
			var filled := Rect2(rect.position, Vector2(rect.size.x * clampf(fraction, 0, 1), rect.size.y))
			_overlay.draw_rect(filled, fill)
			# Fur: little darker tufts along the bar.
			var x := rect.position.x + 4
			while x < filled.end.x - 2:
				_overlay.draw_line(Vector2(x, rect.end.y - 2), Vector2(x + 3, rect.position.y + 4), Color(0.75, 0.5, 0.12), 1.0)
				x += 7
			_overlay.draw_rect(Rect2(filled.position, Vector2(filled.size.x, 3)), Color(1, 1, 1, 0.3))
			# Three claw marks ripped through the right end of the frame.
			for i in 3:
				var from := Vector2(rect.end.x - 34 + i * 8, rect.position.y - 4)
				_overlay.draw_line(from, from + Vector2(-8, rect.size.y + 8), Color(0.15, 0.08, 0.03), 2.0)
			_draw_outlined("HP %d / %d" % [boss.hp, boss.max_hp], Vector2(rect.end.x - 74, rect.end.y + 15), 12, Color(1, 0.9, 0.6))
		"hopkuna":
			var pulse := 0.5 + 0.5 * sin(t * 4.0)
			var red := Color(1.0, 0.15, 0.22)
			_draw_outlined(boss.name.to_upper(), Vector2(22, rect.end.y), 15, red)
			# A glow that breathes around the frame.
			for i in 3:
				_overlay.draw_rect(rect.grow(3 + i * 2), Color(red, (0.3 - i * 0.09) * (0.5 + 0.5 * pulse)), false, 2.0)
			_overlay.draw_rect(rect.grow(2), Color(0.1, 0.0, 0.02))
			_overlay.draw_rect(rect, Color(0.25, 0.0, 0.05))
			var filled := Rect2(rect.position, Vector2(rect.size.x * clampf(fraction, 0, 1), rect.size.y))
			_overlay.draw_rect(filled, red.lerp(Color(1, 0.4, 0.4), pulse * 0.3))
			# Tattoo markings: a black zigzag running along the bar.
			var points := PackedVector2Array()
			var x := rect.position.x
			var up := true
			while x <= filled.end.x:
				points.append(Vector2(x, rect.position.y + (3.0 if up else rect.size.y - 3.0)))
				x += 9
				up = not up
			if points.size() > 1:
				_overlay.draw_polyline(points, Color(0.05, 0.0, 0.0, 0.85), 2.0)
			_draw_outlined("HP ??? / ???", Vector2(rect.end.x - 74, rect.end.y + 15), 12, Color(1, 0.5, 0.5))


## Text with a black outline, so it reads over anything.
func _draw_outlined(text: String, at: Vector2, size: int, color: Color) -> void:
	for offset in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		_overlay.draw_string(_font, at + offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.BLACK)
	_overlay.draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## Some enemies (Hopkuna) fill the screen with a pulsing aura during their turns:
## everything around the box darkens toward their color, and the box glows.
func _draw_aura() -> void:
	if _data == null or _data.aura.a <= 0.0 or state != State.ENEMY_TURN:
		return
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
	var frame := box.get_inner_rect().grow(box.border)
	var screen := Rect2(0, 0, 640, 480)
	var tint := Color(_data.aura, 0.08 + 0.08 * pulse)
	# Four bands around the box, so the inside of the box stays clear.
	_overlay.draw_rect(Rect2(screen.position, Vector2(640, frame.position.y)), tint)
	_overlay.draw_rect(Rect2(0, frame.end.y, 640, 480 - frame.end.y), tint)
	_overlay.draw_rect(Rect2(0, frame.position.y, frame.position.x, frame.size.y), tint)
	_overlay.draw_rect(Rect2(frame.end.x, frame.position.y, 640 - frame.end.x, frame.size.y), tint)
	# The glowing edge of the box.
	for i in 3:
		_overlay.draw_rect(frame.grow(2 + i * 3), Color(_data.aura, (0.45 - i * 0.13) * (0.6 + 0.4 * pulse)), false, 2.0)


## Draws Elric's party on the left side of the screen, facing the enemies.
func _draw_party_sprites() -> void:
	for i in party.size():
		var member := party[i]
		if member.sprite == null:
			continue
		var pos := Vector2(80 + i * 100, 140)
		if member.shake > 0.0:
			pos.x += sin(member.shake * 60.0) * 4.0
		var sprite_size := member.sprite.get_size() * 3.0
		var top := pos.y + 40.0 - sprite_size.y
		var choosing := _is_choosing(i)
		var someone_choosing := _is_choosing(current_member)
		var tint := Color.WHITE
		if member.is_down():
			tint = Color(0.4, 0.4, 0.4)
		elif someone_choosing and not choosing:
			# Teammates who aren't choosing dim a little, so it's clear whose turn it is.
			tint = Color(0.55, 0.55, 0.55)

		if choosing:
			# A soft glow at their feet...
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
			_overlay.draw_set_transform(Vector2(pos.x, pos.y + 40), 0.0, Vector2(1.0, 0.3))
			_overlay.draw_circle(Vector2.ZERO, 34, Color(member.color, 0.25 + 0.15 * pulse))
			_overlay.draw_circle(Vector2.ZERO, 22, Color(member.color, 0.25 + 0.15 * pulse))
			_overlay.draw_set_transform(Vector2.ZERO)
		if state == State.FLEEING and _side_frames.has(member) and not member.is_down():
			# Turned around (side view, flipped to face left) and walking off screen.
			var frames: Array = _side_frames[member]
			var walk_x := _flee_offset(i)
			var frame: Texture2D = frames[int(_flee_time / 0.12) % 2] if walk_x < 0.0 else frames[0]
			var size := frame.get_size() * 3.0
			var feet := Vector2(pos.x + walk_x, pos.y + 40.0)
			_overlay.draw_set_transform(feet, 0.0, Vector2(-1, 1))
			_overlay.draw_texture_rect(frame, Rect2(Vector2(-size.x / 2, -size.y), size), false)
			_overlay.draw_set_transform(Vector2.ZERO)
			# Little dust puffs behind their heels.
			if walk_x < 0.0:
				for d in 3:
					var puff := fmod(_flee_time * 3.0 + d * 0.33, 1.0)
					_overlay.draw_circle(feet + Vector2(14 + puff * 18, -3 - puff * 6), 3.0 * (1.0 - puff), Color(0.8, 0.8, 0.8, 0.5 * (1.0 - puff)))
			continue
		_draw_member(member, i, Vector2(pos.x, pos.y + 40.0), sprite_size, tint)

		if choosing:
			# ...and a bouncing arrow and their name above their head.
			var bob := absf(sin(Time.get_ticks_msec() / 200.0)) * 6.0
			var tip := Vector2(pos.x, top - 12 - bob)
			_overlay.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-9, -12), tip + Vector2(9, -12)]), member.color)
			_overlay.draw_polyline(PackedVector2Array([tip, tip + Vector2(-9, -12), tip + Vector2(9, -12), tip]), Color.WHITE, 1.5)
			_draw_centered(member.name.to_upper() + "'S TURN", Vector2(pos.x, top - 32 - bob), 14, member.color)


## Battle pose pictures (art/sprites/battle/<name>_<pose>.png), loaded once.
var _pose_cache: Dictionary = {}


## A party member's picture for a pose ("windup", "strike", "guard", "raise", "hurt",
## "ko"), or their normal picture if they don't have that pose.
func _pose(member: PartyMember, pose: String) -> Texture2D:
	if pose == "":
		return member.sprite
	var path := "res://art/sprites/battle/%s_%s.png" % [Game.sprite_base(member.id), pose]
	if not _pose_cache.has(path):
		_pose_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _pose_cache[path] if _pose_cache[path] else member.sprite


## Draws a party member in their current pose, standing on `feet`.
##   idle     breathing (a gentle stretch and squash)
##   choosing a little bounce
##   FIGHT    each has their own attack:
##            Elric draws their arm back (nails glinting), then dashes in and rakes
##            with their claws, leaving afterimages behind.
##            Hop crouches and charges up a punch (energy gathers around his fist),
##            then rockets forward and slams it home.
##   ACT / ITEM / MERCY   the arm goes up (a hop, a squash with sparkles, a wave)
##   DEFEND   arms crossed behind a shimmering shield
##   hurt     a shocked face, arms flung out, flashing red and knocked back
##   KO       falls over with a bounce, X'd-out eyes, little stars circling
func _draw_member(member: PartyMember, index: int, feet: Vector2, _sprite_size: Vector2, tint: Color) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var offset := Vector2.ZERO
	var rot := 0.0
	var scale := Vector2.ONE
	var anim: Dictionary = _member_anim.get(member, {})
	var anim_time: float = anim.get("time", 99.0)
	var pose := ""
	var is_hop := member.name == "Hop"
	var attacking := _bar_member == member and state in [State.FIGHT_BAR, State.FIGHT_ANIM]

	if member.is_down():
		pose = "ko"
		# Topple over backwards with a little bounce, then stay down.
		var fall := clampf(member.ko_time / 0.45, 0.0, 1.0)
		var bounce := absf(sin(clampf((member.ko_time - 0.45) / 0.3, 0.0, 1.0) * PI)) * 0.12
		rot = -PI / 2 * (1.0 - pow(1.0 - fall, 3)) + bounce
		# (Slides right a little as they fall, so they land on screen.)
		offset.x = 34.0 * fall
	elif member.shake > 0.0:
		pose = "hurt"
		var hurt := member.shake / 0.4
		rot = -0.15 * hurt
		offset.x = -10.0 * hurt
		tint = tint.lerp(Color(1.0, 0.35, 0.35), hurt)
	elif attacking and state == State.FIGHT_BAR:
		pose = "windup"
		if is_hop:
			# Crouched, coiled, shaking harder as the punch charges.
			scale = Vector2(1.06, 0.9)
			offset.x = -8.0 + sin(t * 40.0) * 1.5
			rot = -0.08
		else:
			rot = -0.14 + sin(t * 16.0) * 0.02
			offset.x = -6.0
	elif attacking:
		var out := clampf(_anim_time / (0.06 if is_hop else 0.12), 0.0, 1.0)
		var back := clampf((_anim_time - 0.7) / 0.3, 0.0, 1.0)
		var lunge := out * (1.0 - back)
		pose = "strike" if lunge > 0.3 else "windup"
		if is_hop:
			# Rockets straight in, low and fast, then shudders with each punch.
			offset.x = 90.0 * lunge
			rot = 0.12 * lunge
			if _anim_time < 0.36:
				offset.x += sin(_anim_time * 90.0) * 5.0
		else:
			# Dashes in with a hop, claws first.
			offset.x = 70.0 * lunge
			offset.y = -sin(clampf(_anim_time / 0.2, 0.0, 1.0) * PI) * 22.0 * (1.0 - back)
			rot = 0.2 * lunge
	else:
		var breath := sin(t * 2.4 + index * 1.3)
		scale = Vector2(1.0 - 0.015 * breath, 1.0 + 0.025 * breath)
		if _is_choosing(index):
			offset.y -= absf(sin(t * 5.0)) * 3.0
		if member.defending:
			pose = "guard"
			scale *= Vector2(1.05, 0.92)
		match anim.get("type", ""):
			"ACT":
				if anim_time < 0.6:
					pose = "raise"
					offset.y -= sin(anim_time / 0.5 * PI) * 22.0 if anim_time < 0.5 else 0.0
			"ITEM":
				if anim_time < 0.6:
					pose = "raise"
					var squash := sin(anim_time / 0.6 * PI * 2.0)
					scale *= Vector2(1.0 + 0.12 * squash, 1.0 - 0.12 * squash)
					for s in 6:
						var spark := feet + Vector2(cos(s * 1.1) * 24.0, -20.0 - anim_time * 80.0 - s * 6.0)
						_overlay.draw_rect(Rect2(spark, Vector2(3, 3)), Color(0.4, 1.0, 0.5, 1.0 - anim_time / 0.6))
			"MERCY":
				if anim_time < 0.8:
					pose = "raise"
					rot = sin(anim_time * 20.0) * 0.12 * (1.0 - anim_time / 0.8)
					offset.y -= absf(sin(anim_time * 10.0)) * 6.0
			"DEFEND":
				if anim_time < 0.25:
					offset.y -= sin(anim_time / 0.25 * PI) * 8.0

	var texture := _pose(member, pose)
	var size := texture.get_size() * 3.0

	# A soft shadow on the ground.
	_overlay.draw_set_transform(feet + Vector2(offset.x, 0), 0.0, Vector2(1.0, 0.28))
	_overlay.draw_circle(Vector2.ZERO, 26.0, Color(0, 0, 0, 0.35))
	_overlay.draw_set_transform(Vector2.ZERO)

	# Elric's dash leaves a trail of afterimages.
	if attacking and state == State.FIGHT_ANIM and not is_hop and _anim_time < 0.4:
		for ghost in 3:
			var behind := offset - Vector2(18.0 * (ghost + 1), 0)
			_overlay.draw_set_transform(feet + behind, rot, scale)
			_overlay.draw_texture_rect(texture, Rect2(Vector2(-size.x / 2, -size.y), size), false, Color(member.color, 0.25 - ghost * 0.07))
		_overlay.draw_set_transform(Vector2.ZERO)

	_overlay.draw_set_transform(feet + offset, rot, scale)
	_overlay.draw_texture_rect(texture, Rect2(Vector2(-size.x / 2, -size.y), size), false, tint)
	_overlay.draw_set_transform(Vector2.ZERO)

	# Effects around the pose.
	if attacking and state == State.FIGHT_BAR:
		# Where the raised hand is in the windup pose.
		var hand := feet + offset + (Vector2(40, -72) if not is_hop else Vector2(36, -64))
		if is_hop:
			# Energy gathering around his fist: rings closing in, getting redder.
			var charge := clampf(1.0 - _bar_wait / FIGHT_WINDUP, 0.0, 1.0) if _bar_wait > 0.0 else 1.0
			for ring in 3:
				var r := fmod(t * 1.5 + ring / 3.0, 1.0)
				_overlay.draw_arc(hand, 26.0 * (1.0 - r) + 4.0, 0, TAU, 16, Color(1.0, 0.5 - 0.3 * charge, 0.3, (0.3 + 0.5 * charge) * r), 2.0)
			_overlay.draw_circle(hand, 4.0 + 4.0 * charge, Color(1.0, 0.3, 0.3, 0.35 + 0.25 * sin(t * 20.0)))
		else:
			# A glint running along the nails.
			var glint := fmod(t * 1.4, 1.0)
			if glint < 0.25:
				var at := hand + Vector2(-6 + glint * 40.0, 0)
				_overlay.draw_line(at + Vector2(-5, 0), at + Vector2(5, 0), Color(1, 1, 1, 0.9), 1.5)
				_overlay.draw_line(at + Vector2(0, -5), at + Vector2(0, 5), Color(1, 1, 1, 0.9), 1.5)
	elif attacking and is_hop and _anim_time < 0.12:
		# Speed lines as Hop launches.
		for line in 5:
			var y := feet.y - 20.0 - line * 14.0
			_overlay.draw_line(Vector2(feet.x + offset.x - 70, y), Vector2(feet.x + offset.x - 20, y), Color(1, 1, 1, 0.5), 2.0)
	if member.is_down() and member.ko_time > 0.5:
		# Little stars circling where their head ended up.
		var head := feet + Vector2(-44, -14)
		for s in 3:
			var angle := t * 3.0 + s * TAU / 3
			var star := head + Vector2(cos(angle) * 16.0, sin(angle) * 5.0)
			_overlay.draw_line(star + Vector2(-3, 0), star + Vector2(3, 0), Color(1, 0.95, 0.4), 1.5)
			_overlay.draw_line(star + Vector2(0, -3), star + Vector2(0, 3), Color(1, 0.95, 0.4), 1.5)
	# A shimmering shield in front of anyone defending.
	if member.defending and not member.is_down():
		var shimmer := 0.5 + 0.5 * sin(t * 6.0)
		var center := feet + Vector2(34, -size.y * 0.45)
		_overlay.draw_arc(center, 30.0, -1.1, 1.1, 16, Color(0.5, 0.8, 1.0, 0.35 + 0.3 * shimmer), 4.0)
		_overlay.draw_arc(center, 24.0, -0.9, 0.9, 12, Color(0.8, 0.95, 1.0, 0.25 + 0.2 * shimmer), 2.0)


func _is_choosing(member_index: int) -> bool:
	var picking := state in [State.MENU, State.TARGET_ENEMY, State.ACT_LIST, State.ITEM_LIST, State.TARGET_PARTY, State.MERCY_MENU, State.CALL_LIST]
	return picking and member_index == current_member


func _draw_speech(text: String, bottom_center: Vector2) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 16
	var rect := Rect2(bottom_center - Vector2(width / 2, 26), Vector2(width, 24))
	_overlay.draw_rect(rect, Color.WHITE)
	_overlay.draw_string(_font, rect.position + Vector2(8, 17), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)


func _draw_party_panel() -> void:
	for i in party.size():
		var member := party[i]
		var x := 40.0 + i * 300.0
		var choosing := _is_choosing(i)
		if choosing:
			# A highlighted box around whoever is choosing.
			var panel := Rect2(x - 10, PANEL_Y - 18, 278, 24)
			_overlay.draw_rect(panel, Color(member.color, 0.22))
			_overlay.draw_rect(panel, member.color, false, 2.0)
		var name_color := member.color if not member.is_down() else Color.DIM_GRAY
		_overlay.draw_string(_font, Vector2(x, PANEL_Y), member.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, name_color)
		# Their level, right next to their name.
		var name_width := _font.get_string_size(member.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		_overlay.draw_string(_font, Vector2(x + name_width + 6, PANEL_Y - 1), "LV %d" % Game.lv(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.8, 0.8))
		_draw_bar(Rect2(x + 98, PANEL_Y - 13, 96, 14), float(member.hp) / member.max_hp, YELLOW)
		_overlay.draw_string(_font, Vector2(x + 200, PANEL_Y), "%d / %d" % [member.hp, member.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
		if member.defending:
			_overlay.draw_string(_font, Vector2(x + 256, PANEL_Y - 1), "DEF", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.SKY_BLUE)


func _draw_buttons() -> void:
	for i in BUTTONS.size():
		var rect := Rect2(Vector2(22 + i * BUTTON_SPACING, BUTTON_Y), BUTTON_SIZE)
		var selected := state == State.MENU and i == _button
		var color := YELLOW if selected else ORANGE
		_overlay.draw_rect(rect, color, false, 2.0)
		_overlay.draw_string(_font, rect.position + Vector2(32, 22), BUTTONS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
		# The SOUL sits where the icon is on the selected button (like Undertale).
		if not selected:
			_draw_button_icon(BUTTONS[i], rect.position + Vector2(15, 16), color)


## Little pictures on the battle buttons: a sword, a megaphone, a bag, a white flag
## and a shield. `c` is the center of the icon.
func _draw_button_icon(button: String, c: Vector2, color: Color) -> void:
	match button:
		"FIGHT":
			# A sword, pointing up and to the right.
			_overlay.draw_line(c + Vector2(-6, 6), c + Vector2(7, -7), color, 3.0)
			_overlay.draw_line(c + Vector2(-7, 1), c + Vector2(-1, 7), color, 2.0)
			_overlay.draw_line(c + Vector2(-6, 6), c + Vector2(-9, 9), color, 3.0)
		"ACT":
			# A megaphone with sound coming out of it.
			_overlay.draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -2), c + Vector2(2, -7), c + Vector2(2, 7), c + Vector2(-8, 2)]), color)
			_overlay.draw_line(c + Vector2(-6, 2), c + Vector2(-6, 7), color, 2.0)
			_overlay.draw_arc(c + Vector2(3, 0), 5, -0.9, 0.9, 6, color, 1.5)
			_overlay.draw_arc(c + Vector2(3, 0), 9, -0.8, 0.8, 6, color, 1.5)
		"ITEM":
			# A bag with a handle.
			_overlay.draw_rect(Rect2(c + Vector2(-7, -3), Vector2(14, 11)), color)
			_overlay.draw_arc(c + Vector2(0, -3), 4, PI, TAU, 8, color, 2.0)
			_overlay.draw_line(c + Vector2(-3, 1), c + Vector2(3, 1), Color.BLACK, 1.5)
		"MERCY":
			# A white flag on a pole.
			_overlay.draw_line(c + Vector2(-6, -8), c + Vector2(-6, 9), color, 2.0)
			_overlay.draw_colored_polygon(PackedVector2Array([c + Vector2(-5, -8), c + Vector2(8, -6), c + Vector2(5, -2), c + Vector2(8, 2), c + Vector2(-5, 1)]), color)
		"DEFEND":
			# A shield.
			_overlay.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -7), c + Vector2(7, -7), c + Vector2(7, 1), c + Vector2(0, 9), c + Vector2(-7, 1)]), color)
			_overlay.draw_line(c + Vector2(0, -5), c + Vector2(0, 6), Color.BLACK, 1.5)


func _draw_box_contents() -> void:
	var area := box.get_inner_rect()
	match state:
		State.TEXT, State.MENU, State.READY, State.CALLING:
			var visible_text := _text.substr(0, int(maxf(_typed, 0.0)))
			var lines := visible_text.split("\n")
			for i in lines.size():
				_overlay.draw_string(_font, Vector2(area.position.x + 14, _row_y(i)), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, _text_color)
		State.TARGET_ENEMY:
			for i in _list.size():
				var enemy: Enemy = _list[i]
				var color := YELLOW if enemy.can_spare() else Color.WHITE
				var info := "%s     HP %d%%     MERCY %d%%" % [enemy.name, roundi(100.0 * enemy.hp / enemy.max_hp), enemy.mercy]
				_draw_row(i, info, color)
		State.ACT_LIST:
			for i in _list.size():
				_draw_row(i, str(_list[i]), Color.WHITE)
		State.ITEM_LIST:
			for i in _list.size():
				var item: Dictionary = _list[i]
				_draw_row(i, "%s  (+%d HP)" % [item["name"], item["heal"]], Color.WHITE)
		State.TARGET_PARTY:
			for i in _list.size():
				var member: PartyMember = _list[i]
				_draw_row(i, "%s   HP %d / %d" % [member.name, member.hp, member.max_hp], member.color)
		State.MERCY_MENU:
			var anyone_spareable := _active_enemies().any(func(e: Enemy) -> bool: return e.can_spare())
			_draw_row(0, "Spare", YELLOW if anyone_spareable else Color.WHITE)
			_draw_row(1, "Flee", Color.WHITE)
			if _list.size() > 2:
				var wait := _call_wait()
				_draw_row(2, "Call a friend" if wait == 0 else "Call a friend  (%d turn%s)" % [wait, "" if wait == 1 else "s"], Color(0.6, 0.9, 1.0) if wait == 0 else Color(0.45, 0.45, 0.45))
		State.CALL_LIST:
			for i in _list.size():
				var id: String = _list[i]
				var helper: Dictionary = _helpers().HELPERS[id]
				var spot := Vector2(area.position.x + 50 + (i / CALL_ROWS) * CALL_COLUMN, _row_y(i % CALL_ROWS))
				var wait := _helper_wait(id)
				var label := DialogueBox.display_name(id)
				if wait == -1:
					label += "  (no charges)"
				elif wait > 0:
					label += "  (%d turn%s)" % [wait, "" if wait == 1 else "s"]
				elif helper.get("charges", -1) >= 0:
					label += "  (%d left)" % (int(helper["charges"]) - int(_helper_uses.get(id, 0)))
				_overlay.draw_string(_font, spot, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, helper["color"] if wait == 0 else Color(0.45, 0.45, 0.45))
		State.FLEEING:
			_overlay.draw_string(_font, Vector2(area.position.x + 14, _row_y(0)), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
		State.FIGHT_BAR, State.FIGHT_ANIM:
			_draw_fight_bar(area)

	# A reminder of the controls in the corner of the box.
	var hint := ""
	if state == State.MENU:
		hint = "ENTER: choose   X: back" if _can_go_back() else "ENTER: choose"
	elif state in [State.TARGET_ENEMY, State.ACT_LIST, State.ITEM_LIST, State.TARGET_PARTY, State.MERCY_MENU, State.CALL_LIST]:
		hint = "ENTER: choose   X: back"
	if hint != "":
		var width := _font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		_overlay.draw_string(_font, Vector2(area.end.x - width - 8, area.end.y - 8), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.55, 0.55))


## True if there's an earlier party member whose choice can be undone.
func _can_go_back() -> bool:
	for i in range(current_member - 1, -1, -1):
		if not party[i].is_down():
			return true
	return false


## Draws one option in a list. The SOUL sits to its left as the cursor.
func _draw_row(row: int, text: String, color: Color) -> void:
	var area := box.get_inner_rect()
	_overlay.draw_string(_font, Vector2(area.position.x + 50, _row_y(row)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)


## The FIGHT timing bar: a target with colored zones (red at the edges, green in the
## middle), and a glowing bar in the attacker's color that sweeps across, leaving a
## fading trail. "READY..." shows first, before the bar starts moving.
func _draw_fight_bar(area: Rect2) -> void:
	var color := _bar_member.color
	var title := "* %s attacks %s!" % [_bar_member.name, _bar_target.name]
	_overlay.draw_string(_font, Vector2(area.position.x + 14, _row_y(0)), title, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
	var prompt := "READY..." if _bar_wait > 0.0 else "Press ENTER in the green!"
	if not _file_bars.is_empty() and _bar_wait <= 0.0:
		prompt = "ENTER for each bar!"
	if state == State.FIGHT_ANIM:
		prompt = "CRITICAL!" if _anim_accuracy >= CRITICAL else "HIT!"
	var prompt_color := YELLOW if state == State.FIGHT_ANIM or _bar_wait <= 0.0 else Color.GRAY
	if state == State.FIGHT_ANIM and _black_flash:
		# Flickers between red and a dark red, like the flash itself.
		prompt = "BLACK FLASH!"
		prompt_color = Color(1.0, 0.15, 0.2) if int(Time.get_ticks_msec() / 80) % 2 == 0 else Color(0.45, 0.0, 0.05)
	var prompt_width := _font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	_overlay.draw_string(_font, Vector2(area.end.x - prompt_width - 14, _row_y(0)), prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, prompt_color)

	var target := Rect2(area.position + Vector2(24, 40), Vector2(area.size.x - 48, area.size.y - 56))
	var mid := target.get_center().x
	_overlay.draw_rect(target, Color(0.08, 0.08, 0.1))
	# The zones, from the outside in: red, orange, yellow, green. Hitting closer
	# to the middle does more damage.
	var zones := [[1.0, Color(0.55, 0.12, 0.12)], [0.62, Color(0.7, 0.38, 0.1)], [0.32, Color(0.75, 0.68, 0.15)], [0.1, Color(0.2, 0.75, 0.3)]]
	for zone in zones:
		var half: float = target.size.x * 0.5 * zone[0]
		_overlay.draw_rect(Rect2(mid - half, target.position.y + 4, half * 2, target.size.y - 8), zone[1])
	# Tick marks and the dead-center line.
	for t in 11:
		var x := target.position.x + target.size.x * t / 10.0
		_overlay.draw_line(Vector2(x, target.end.y - 6), Vector2(x, target.end.y), Color(1, 1, 1, 0.4), 1.0)
	_overlay.draw_line(Vector2(mid, target.position.y), Vector2(mid, target.end.y), Color(1, 1, 1, 0.8), 1.0)
	_overlay.draw_rect(target, Color.WHITE, false, 2.0)

	if not _file_bars.is_empty():
		_draw_file_bars(target, color)
		return
	# The bar, with an afterimage trail.
	for i in _bar_trail.size():
		var tx := target.position.x + clampf(_bar_trail[i], 0.0, 1.0) * target.size.x
		_overlay.draw_rect(Rect2(tx - 3, target.position.y - 2, 6, target.size.y + 4), Color(color, 0.08 * (i + 1)))
	var x := target.position.x + clampf(_bar_pos, 0.0, 1.0) * target.size.x
	var glow := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 90.0) if _bar_wait > 0.0 else 1.0
	_overlay.draw_rect(Rect2(x - 7, target.position.y - 6, 14, target.size.y + 12), Color(color, 0.3 * glow))
	_overlay.draw_rect(Rect2(x - 3, target.position.y - 6, 6, target.size.y + 12), Color(color, glow))
	_overlay.draw_rect(Rect2(x - 1, target.position.y - 6, 2, target.size.y + 12), Color(1, 1, 1, glow))


## Nail File: three thinner silver bars. Stopped bars stay where they stopped,
## marked with their share of the hit; bars that ran off the end are gone.
func _draw_file_bars(target: Rect2, color: Color) -> void:
	var glow := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 90.0) if _bar_wait > 0.0 else 1.0
	var silver := Color(0.85, 0.88, 0.95)
	for i in _file_bars.size():
		var bar := _file_bars[i]
		var pos: float = bar["pos"]
		if pos < 0.0 or pos > 1.0:
			continue
		if bar["done"] and bar["accuracy"] < 0.0:
			continue
		var x := target.position.x + pos * target.size.x
		var top := target.position.y - 6
		var height := target.size.y + 12
		if bar["done"]:
			# Stopped: a solid silver line with a little notch number on top.
			_overlay.draw_rect(Rect2(x - 2, top, 4, height), silver)
			_overlay.draw_string(_font, Vector2(x - 4, top - 4), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, silver)
		else:
			_overlay.draw_rect(Rect2(x - 5, top, 10, height), Color(color, 0.3 * glow))
			_overlay.draw_rect(Rect2(x - 2, top, 4, height), Color(silver, glow))
			_overlay.draw_rect(Rect2(x - 0.5, top, 1, height), Color(1, 1, 1, glow))


## A health bar with a thin border. `trailing` (if given) is the HP still draining
## away, shown in yellow-white behind the real amount.
func _draw_bar(rect: Rect2, fraction: float, color: Color, trailing: float = -1.0) -> void:
	_overlay.draw_rect(rect.grow(1), Color(0.9, 0.9, 0.9))
	_overlay.draw_rect(rect, Color(0.45, 0.0, 0.0))
	if trailing > fraction:
		_overlay.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(trailing, 0.0, 1.0), rect.size.y)), Color(1.0, 0.9, 0.6))
	_overlay.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(fraction, 0.0, 1.0), rect.size.y)), color)
	# A lighter strip along the top makes it look a bit shiny.
	_overlay.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(fraction, 0.0, 1.0), rect.size.y * 0.3)), Color(1, 1, 1, 0.25))


func _draw_centered(text: String, center: Vector2, font_size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_overlay.draw_string(_font, Vector2(center.x - width / 2, center.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


# --- Background -----------------------------------------------------------

const BACKDROP := Rect2(20, 20, 600, 215)
const DIAMOND_SPACING := 36.0



## The scene behind the fight. Each kind of battle has its own (see BattleData.backdrop_style):
##   diamonds    a drifting lattice of diamonds with twinkling points
##   grid        graph paper rolling toward you, like a test (Pop Quiz)
##   stripes     hallway lines rushing past (Hall Pass)
##   bubbles     bubbles rising and popping (Mystery Meat)
##   rings       rings of sound pulsing out from the middle (Tardy Bell)
##   stars       a slowly turning starfield with dust (Overdue Book)
##   spotlights  stadium lights sweeping, with confetti (Wally)
##   shards      red fragments falling past cracks of light (Hopkuna)
##   static      a fuzzy, flickering screen (the tent)
func _draw_backdrop() -> void:
	if state == State.GAME_OVER or _data == null:
		return
	var color := _data.backdrop
	# Once the tent's music cuts out, the background goes dim and stops moving.
	var frozen := _tent_phase != ""
	if frozen:
		color = color.darkened(0.6)
	var t := Time.get_ticks_msec() / 1000.0 if not frozen else _frozen_at
	match _data.backdrop_style:
		"grid":
			_backdrop_grid(color, t)
			_backdrop_pencils(color, t)
		"stripes":
			_backdrop_stripes(color, t)
			_backdrop_lockers(color, t)
		"bubbles":
			_backdrop_bubbles(color, t)
		"rings":
			_backdrop_rings(color, t)
			_backdrop_bell(color, t)
		"stars":
			_backdrop_stars(color, t)
			_backdrop_books(color, t)
		"spotlights":
			_backdrop_arena(color, t)
			_backdrop_spotlights(color, t)
			_backdrop_crowd(color, t)
		"shards":
			_backdrop_heartbeat(color, t)
			_backdrop_shards(color, t)
		"static":
			_backdrop_static(color, t)
		_:
			_backdrop_sigil(color, t)
			_backdrop_diamonds(color, t)


## How visible something is at `point`: full in the middle, fading out near the edges.
func _edge_fade(point: Vector2) -> float:
	var edge := minf(minf(point.x - BACKDROP.position.x, BACKDROP.end.x - point.x), minf(point.y - BACKDROP.position.y, BACKDROP.end.y - point.y))
	return clampf((edge - 6.0) / 40.0, 0.0, 1.0)


func _backdrop_diamonds(color: Color, t: float) -> void:
	var drift := Vector2(fmod(t * 8.0, DIAMOND_SPACING), fmod(t * 4.0, DIAMOND_SPACING))
	var columns := int(BACKDROP.size.x / DIAMOND_SPACING) + 2
	var rows := int(BACKDROP.size.y / (DIAMOND_SPACING * 0.5)) + 3
	for gx in range(-1, columns):
		for gy in range(-2, rows):
			var center := BACKDROP.position + drift + Vector2(gx * DIAMOND_SPACING + (DIAMOND_SPACING / 2 if gy % 2 != 0 else 0.0), gy * DIAMOND_SPACING * 0.5)
			var alpha := _edge_fade(center) * 0.45
			if alpha <= 0.0:
				continue
			var r := 9.0
			_backdrop.draw_polyline(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0), center + Vector2(0, -r)]), Color(color, alpha), 1.5)
			if posmod(gx * 7 + gy * 13, 11) == 0:
				var twinkle := 0.5 + 0.5 * sin(t * 3.0 + gx + gy)
				_backdrop.draw_circle(center, 2.0, Color(color.lightened(0.5), alpha * twinkle * 1.6))


## Graph paper on a floor, rolling toward you, with a horizon glow.
func _backdrop_grid(color: Color, t: float) -> void:
	var horizon := BACKDROP.position.y + 50.0
	var center_x := BACKDROP.get_center().x
	_backdrop.draw_rect(Rect2(BACKDROP.position.x, horizon - 2, BACKDROP.size.x, 3), Color(color, 0.35))
	# Lines running toward the horizon.
	for i in range(-12, 13):
		var bottom := Vector2(center_x + i * 60.0, BACKDROP.end.y)
		var top := Vector2(center_x + i * 6.0, horizon)
		for k in 8:
			var a := top.lerp(bottom, k / 8.0)
			var b := top.lerp(bottom, (k + 1) / 8.0)
			_backdrop.draw_line(a, b, Color(color, 0.4 * _edge_fade((a + b) / 2)), 1.0)
	# Cross lines rolling forward, closer together near the horizon.
	for k in 10:
		var depth := fmod(k / 10.0 + t * 0.12, 1.0)
		var y := horizon + (BACKDROP.end.y - horizon) * depth * depth
		_backdrop.draw_line(Vector2(BACKDROP.position.x, y), Vector2(BACKDROP.end.x, y), Color(color, 0.45 * depth * _edge_fade(Vector2(center_x, y))), 1.0)
	# A few faint answer bubbles floating in the sky.
	for i in 6:
		var at := Vector2(BACKDROP.position.x + 60 + i * 95, horizon - 22 + sin(t * 1.3 + i) * 6)
		_backdrop.draw_arc(at, 6, 0, TAU, 12, Color(color, 0.3 * _edge_fade(at)), 1.5)


## Lines of a hallway rushing past, left to right.
func _backdrop_stripes(color: Color, t: float) -> void:
	for i in 14:
		var y := BACKDROP.position.y + 10 + i * 15.0
		var speed := 120.0 + (i * 37 % 5) * 50.0
		var length := 40.0 + (i * 13 % 4) * 30.0
		for copy in 3:
			var x := BACKDROP.position.x + fmod(t * speed + copy * 230.0 + i * 47.0, BACKDROP.size.x + length) - length
			var a := Vector2(x, y)
			var b := Vector2(x + length, y)
			var alpha := 0.4 * minf(_edge_fade(a), _edge_fade(b)) + 0.05
			_backdrop.draw_line(a, b, Color(color, alpha), 2.0 if i % 3 == 0 else 1.0)


## The school cafeteria, gone wrong (Mystery Meat): flickering ceiling lights, a
## checkered floor stretching back, a vat of bubbling stew along the bottom with
## blobs splashing out of it, steam curling up, and trays drifting through the air.
func _backdrop_bubbles(color: Color, t: float) -> void:
	var top := BACKDROP.position.y
	var bottom := BACKDROP.end.y
	var center_x := BACKDROP.get_center().x
	# Fluorescent lights along the ceiling, one of them flickering.
	for i in 5:
		var at := Vector2(BACKDROP.position.x + 70 + i * 115.0, top + 14)
		var flicker := 1.0 if i != 2 else (0.2 if fmod(t * 7.3, 1.0) < 0.15 or fmod(t * 2.1, 1.0) < 0.05 else 1.0)
		_backdrop.draw_rect(Rect2(at - Vector2(26, 2), Vector2(52, 4)), Color(color.lightened(0.6), 0.55 * flicker * _edge_fade(at)))
		var glow := PackedVector2Array([at + Vector2(-26, 2), at + Vector2(26, 2), at + Vector2(46, 50), at + Vector2(-46, 50)])
		_backdrop.draw_colored_polygon(glow, Color(color.lightened(0.5), 0.05 * flicker))
	# A checkered floor running back toward the far wall.
	var horizon := top + 70.0
	for row in 7:
		var near := float(row + 1) / 7.0
		var far := float(row) / 7.0
		var y0 := horizon + (bottom - horizon) * far * far
		var y1 := horizon + (bottom - horizon) * near * near
		for col in range(-8, 8):
			if (col + row) % 2 != 0:
				continue
			var x0 := center_x + col * 70.0 * lerpf(0.2, 1.0, far)
			var x1 := center_x + (col + 1) * 70.0 * lerpf(0.2, 1.0, far)
			var x2 := center_x + (col + 1) * 70.0 * lerpf(0.2, 1.0, near)
			var x3 := center_x + col * 70.0 * lerpf(0.2, 1.0, near)
			var tile := PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x2, y1), Vector2(x3, y1)])
			_backdrop.draw_colored_polygon(tile, Color(color, 0.1 * _edge_fade(Vector2((x0 + x2) / 2, (y0 + y1) / 2))))
	# Lunch trays drifting through the air, slowly spinning.
	for i in 4:
		var at := Vector2(BACKDROP.position.x + fmod(i * 157.0 + t * (14.0 + i * 5.0), BACKDROP.size.x + 60.0) - 30.0, top + 50 + i * 22 + sin(t * 1.4 + i) * 8)
		var tilt := sin(t * 1.1 + i * 2.0) * 0.4
		_backdrop.draw_set_transform(at, tilt, Vector2.ONE)
		_backdrop.draw_rect(Rect2(-14, -6, 28, 12), Color(0.75, 0.75, 0.8, 0.25 * _edge_fade(at)), false, 1.5)
		_backdrop.draw_rect(Rect2(-10, -3, 8, 6), Color(0.75, 0.75, 0.8, 0.15 * _edge_fade(at)), false, 1.0)
		_backdrop.draw_set_transform(Vector2.ZERO)
	# The stew: a wobbling surface along the bottom.
	var surface := PackedVector2Array()
	for k in 41:
		var x := BACKDROP.position.x + k * BACKDROP.size.x / 40.0
		surface.append(Vector2(x, bottom - 26 + sin(t * 2.4 + k * 0.6) * 3.0 + sin(t * 1.3 + k * 0.23) * 2.0))
	var stew := surface.duplicate()
	stew.append(Vector2(BACKDROP.end.x, bottom))
	stew.append(Vector2(BACKDROP.position.x, bottom))
	_backdrop.draw_colored_polygon(stew, Color(color.darkened(0.35), 0.45))
	_backdrop.draw_polyline(surface, Color(color.lightened(0.2), 0.7), 2.0)
	# Bubbles rising out of it and popping.
	for i in 16:
		var life := fmod(t * (0.5 + (i % 4) * 0.15) + i * 0.37, 1.0)
		var x := BACKDROP.position.x + fmod(i * 83.0, BACKDROP.size.x)
		var at := Vector2(x + sin(t * 2.0 + i) * 4.0, bottom - 22 - life * 30.0)
		var radius := 2.5 + (i % 3) * 1.5
		var alpha := 0.6 * _edge_fade(at)
		if life > 0.85:
			var pop := (life - 0.85) / 0.15
			_backdrop.draw_arc(at, radius + pop * 5.0, 0, TAU, 10, Color(color, alpha * (1.0 - pop)), 1.0)
		else:
			_backdrop.draw_arc(at, radius, 0, TAU, 10, Color(color.lightened(0.3), alpha), 1.5)
	# Blobs of stew splashing up and falling back.
	for i in 3:
		var period := 1.8 + i * 0.5
		var hop := fmod(t + i * 0.9, period) / period
		var base := Vector2(BACKDROP.position.x + 120 + i * 180.0, bottom - 26)
		var at := base + Vector2(hop * 26.0, -sin(hop * PI) * 60.0)
		_backdrop.draw_circle(at, 4.0, Color(color.lightened(0.1), 0.7 * _edge_fade(at)))
		_backdrop.draw_circle(at + Vector2(-5, 3), 2.0, Color(color.lightened(0.1), 0.5 * _edge_fade(at)))
	# Steam curling up.
	for i in 6:
		var life := fmod(t * 0.3 + i * 0.17, 1.0)
		var base := Vector2(BACKDROP.position.x + 50 + i * 100.0, bottom - 30)
		var points := PackedVector2Array()
		for k in 6:
			var rise := life * 60.0 + k * 8.0
			points.append(base + Vector2(sin(t * 2.0 + k * 0.9 + i) * 6.0, -rise))
		_backdrop.draw_polyline(points, Color(1, 1, 1, 0.12 * (1.0 - life)), 3.0)


## Rings of sound pulsing outward from the middle, like a bell ringing.
func _backdrop_rings(color: Color, t: float) -> void:
	var center := BACKDROP.get_center()
	for i in 7:
		var r := fmod(t * 40.0 + i * 45.0, 315.0)
		var points := PackedVector2Array()
		for k in 64:
			points.append(center + Vector2.from_angle(k * TAU / 63.0) * Vector2(r * 1.5, r * 0.75))
		for k in 63:
			var mid := (points[k] + points[k + 1]) / 2
			var alpha := 0.4 * _edge_fade(mid) * (1.0 - r / 315.0)
			if alpha > 0.01:
				_backdrop.draw_line(points[k], points[k + 1], Color(color, alpha), 2.0)


## A slowly turning field of stars.
func _backdrop_stars(color: Color, t: float) -> void:
	var center := BACKDROP.get_center()
	for i in 60:
		var radius := 20.0 + fmod(i * 47.0, 300.0)
		var angle := i * 2.39996 + t * (0.05 + 0.02 * (i % 3))
		var at := center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.45)
		var twinkle := 0.5 + 0.5 * sin(t * (1.5 + i % 4) + i)
		var alpha := _edge_fade(at) * (0.25 + 0.4 * twinkle)
		var size := 1.0 if i % 5 != 0 else 2.0
		var light := color.lightened(0.4)
		_backdrop.draw_rect(Rect2(at - Vector2(size, size) / 2, Vector2(size, size)), Color(light, alpha))
		if i % 9 == 0:
			_backdrop.draw_line(at - Vector2(4, 0), at + Vector2(4, 0), Color(light, alpha * 0.6), 1.0)
			_backdrop.draw_line(at - Vector2(0, 4), at + Vector2(0, 4), Color(light, alpha * 0.6), 1.0)


## Stadium spotlights sweeping back and forth, with confetti falling through them.
func _backdrop_spotlights(color: Color, t: float) -> void:
	var frame := PackedVector2Array([BACKDROP.position, Vector2(BACKDROP.end.x, BACKDROP.position.y), BACKDROP.end, Vector2(BACKDROP.position.x, BACKDROP.end.y)])
	for i in 4:
		var base := Vector2(BACKDROP.position.x + 75 + i * 150.0, BACKDROP.end.y + 10)
		var dir := Vector2.from_angle(-PI / 2 + sin(t * (0.7 + i * 0.2) + i * 1.7) * 0.6)
		var side := dir.orthogonal()
		var far := base + dir * 260.0
		var beam := PackedVector2Array([base - side * 6.0, base + side * 6.0, far + side * 46.0, far - side * 46.0])
		# Each beam its own color, brighter on the beat.
		var beam_color: Color = ARENA_COLORS[(i + int(t * 0.5)) % ARENA_COLORS.size()]
		for shape in Geometry2D.intersect_polygons(beam, frame):
			_backdrop.draw_colored_polygon(shape, Color(beam_color.lerp(color, 0.3), 0.16))
	var colors := [Color(1, 0.3, 0.3), Color(1, 0.85, 0.2), Color(0.3, 0.8, 1), Color(0.5, 1, 0.4), Color(1, 0.5, 1)]
	for i in 34:
		var fall := fmod(t * (30.0 + i % 4 * 12.0) + i * 41.0, BACKDROP.size.y)
		var at := Vector2(BACKDROP.position.x + fmod(i * 71.0, BACKDROP.size.x) + sin(t * 3.0 + i) * 10.0, BACKDROP.position.y + fall)
		var flip := absf(sin(t * 6.0 + i))
		_backdrop.draw_rect(Rect2(at, Vector2(4 * flip + 1, 3)), Color(colors[i % colors.size()], 0.6 * _edge_fade(at)))


## Red fragments tumbling down past jagged cracks of light (Hopkuna).
func _backdrop_shards(color: Color, t: float) -> void:
	for i in 5:
		var start := Vector2(BACKDROP.position.x + 50 + i * 125.0, BACKDROP.position.y + 10)
		var points := PackedVector2Array([start])
		for k in 7:
			points.append(points[-1] + Vector2(((i * 7 + k * 13) % 9 - 4) * 4.0, 28.0))
		var flicker := 0.25 + 0.25 * absf(sin(t * 3.0 + i * 1.9))
		_backdrop.draw_polyline(points, Color(color.lightened(0.3), flicker * 0.6), 1.5)
	for i in 22:
		var fall := fmod(t * (25.0 + i % 5 * 10.0) + i * 53.0, BACKDROP.size.y + 30.0) - 15.0
		var at := Vector2(BACKDROP.position.x + fmod(i * 97.0, BACKDROP.size.x), BACKDROP.position.y + fall)
		var spin := t * (1.0 + i % 3) + i
		var size := 4.0 + (i % 3) * 2.0
		var shard := PackedVector2Array([Vector2(0, -1.4), Vector2(0.7, -0.3), Vector2(0.4, 0.9), Vector2(-0.6, 0.2)])
		for p in shard.size():
			shard[p] = at + shard[p].rotated(spin) * size
		_backdrop.draw_colored_polygon(shard, Color(color, 0.55 * _edge_fade(at)))


## Fuzzy TV static (the tent).
func _backdrop_static(color: Color, t: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(t * 20.0)
	for i in 260:
		var at := Vector2(BACKDROP.position.x + rng.randf() * BACKDROP.size.x, BACKDROP.position.y + rng.randf() * BACKDROP.size.y)
		var bright := rng.randf()
		_backdrop.draw_rect(Rect2(at, Vector2(2, 2)), Color(color.lerp(Color.WHITE, bright * 0.5), 0.25 * bright * _edge_fade(at)))
	# A slow rolling band, like an old TV.
	var band := BACKDROP.position.y + fmod(t * 30.0, BACKDROP.size.y)
	_backdrop.draw_rect(Rect2(BACKDROP.position.x, band, BACKDROP.size.x, 6), Color(color, 0.08))


# --- Extra layers for the backgrounds ------------------------------------------

## A huge eight-pointed star slowly turning behind the diamonds, glowing, with
## sparks drifting up (the tutorial).
func _backdrop_sigil(color: Color, t: float) -> void:
	var center := BACKDROP.get_center()
	for layer in 2:
		var spin := t * (0.15 if layer == 0 else -0.1)
		var size := 90.0 - layer * 30.0
		for square in 2:
			var points := PackedVector2Array()
			for k in 5:
				points.append(center + Vector2.from_angle(spin + square * PI / 4 + k * PI / 2) * Vector2(size * 1.6, size))
			_backdrop.draw_polyline(points, Color(color, 0.18 - layer * 0.05), 2.0)
	_backdrop.draw_circle(center, 30.0 + sin(t * 2.0) * 4.0, Color(color, 0.06))
	for i in 18:
		var life := fmod(t * 0.25 + i * 0.13, 1.0)
		var at := Vector2(BACKDROP.position.x + fmod(i * 67.0, BACKDROP.size.x), BACKDROP.end.y - life * BACKDROP.size.y)
		_backdrop.draw_rect(Rect2(at, Vector2(2, 2)), Color(color.lightened(0.5), 0.6 * (1.0 - life) * _edge_fade(at)))


## Pencils tumbling down, and red marks (checks and crosses) popping up (Pop Quiz).
func _backdrop_pencils(color: Color, t: float) -> void:
	for i in 7:
		var fall := fmod(t * (22.0 + i * 4.0) + i * 47.0, BACKDROP.size.y + 40.0) - 20.0
		var at := Vector2(BACKDROP.position.x + 40 + fmod(i * 89.0, BACKDROP.size.x - 80), BACKDROP.position.y + fall)
		var dir := Vector2.from_angle(t * (1.0 + i % 3) + i)
		var alpha := 0.55 * _edge_fade(at)
		_backdrop.draw_line(at - dir * 10, at + dir * 6, Color(0.95, 0.8, 0.25, alpha), 3.0)
		_backdrop.draw_line(at + dir * 6, at + dir * 10, Color(0.3, 0.25, 0.2, alpha), 2.0)
		_backdrop.draw_line(at - dir * 10, at - dir * 7, Color(1.0, 0.6, 0.7, alpha), 3.0)
	for i in 5:
		var life := fmod(t * 0.4 + i * 0.21, 1.0)
		var at := Vector2(BACKDROP.position.x + 60 + i * 120.0, BACKDROP.position.y + 40 + (i * 37) % 90)
		var alpha := sin(life * PI) * 0.6 * _edge_fade(at)
		var red := Color(1.0, 0.25, 0.25, alpha)
		if i % 2 == 0:
			_backdrop.draw_polyline(PackedVector2Array([at + Vector2(-6, 0), at + Vector2(-2, 5), at + Vector2(7, -6)]), red, 2.0)
		else:
			_backdrop.draw_line(at + Vector2(-5, -5), at + Vector2(5, 5), red, 2.0)
			_backdrop.draw_line(at + Vector2(5, -5), at + Vector2(-5, 5), red, 2.0)


## Rows of lockers rushing past along the top and bottom, and a wall clock whose
## hands spin way too fast (Hall Pass).
func _backdrop_lockers(color: Color, t: float) -> void:
	for band in 2:
		var y := BACKDROP.position.y + 8.0 if band == 0 else BACKDROP.end.y - 34.0
		var speed := 160.0 if band == 0 else 260.0
		for i in 14:
			var x := BACKDROP.position.x + fmod(i * 48.0 + t * speed, BACKDROP.size.x + 48.0) - 48.0
			var locker := Rect2(x, y, 44, 26)
			var alpha := 0.35 * _edge_fade(locker.get_center())
			_backdrop.draw_rect(locker, Color(color, alpha * 0.5))
			_backdrop.draw_rect(locker, Color(color, alpha), false, 1.0)
			for vent in 3:
				_backdrop.draw_line(Vector2(x + 8, y + 5 + vent * 3), Vector2(x + 22, y + 5 + vent * 3), Color(color, alpha), 1.0)
	var clock := Vector2(BACKDROP.get_center().x, BACKDROP.position.y + 100)
	_backdrop.draw_circle(clock, 22, Color(color, 0.08))
	_backdrop.draw_arc(clock, 22, 0, TAU, 24, Color(color, 0.4), 2.0)
	_backdrop.draw_line(clock, clock + Vector2.from_angle(t * 6.0) * 16, Color(color, 0.6), 2.0)
	_backdrop.draw_line(clock, clock + Vector2.from_angle(t * 0.5) * 10, Color(color, 0.6), 3.0)


## A giant bell swinging in the middle, and music notes floating off it (Tardy Bell).
func _backdrop_bell(color: Color, t: float) -> void:
	var pivot := Vector2(BACKDROP.get_center().x, BACKDROP.position.y + 20)
	var swing := sin(t * 2.2) * 0.35
	_backdrop.draw_set_transform(pivot, swing, Vector2.ONE)
	var bell := PackedVector2Array([Vector2(-12, 10), Vector2(12, 10), Vector2(22, 60), Vector2(34, 72), Vector2(-34, 72), Vector2(-22, 60)])
	_backdrop.draw_colored_polygon(bell, Color(color, 0.12))
	_backdrop.draw_polyline(bell + PackedVector2Array([bell[0]]), Color(color, 0.4), 2.0)
	_backdrop.draw_circle(Vector2(sin(t * 4.4) * 10, 80), 7, Color(color, 0.35))
	_backdrop.draw_set_transform(Vector2.ZERO)
	for i in 8:
		var life := fmod(t * 0.35 + i * 0.125, 1.0)
		var side := -1.0 if i % 2 == 0 else 1.0
		var at := pivot + Vector2(side * (40 + life * 200.0), 70 - life * 50.0 + sin(t * 3 + i) * 8)
		var alpha := 0.6 * sin(life * PI) * _edge_fade(at)
		_backdrop.draw_circle(at, 3.5, Color(color.lightened(0.3), alpha))
		_backdrop.draw_line(at + Vector2(3, 0), at + Vector2(3, -12), Color(color.lightened(0.3), alpha), 1.5)
		_backdrop.draw_line(at + Vector2(3, -12), at + Vector2(8, -9), Color(color.lightened(0.3), alpha), 1.5)


## Books flapping across like birds, and loose pages drifting (Overdue Book).
func _backdrop_books(color: Color, t: float) -> void:
	for i in 6:
		var x := BACKDROP.position.x + fmod(i * 131.0 + t * (30.0 + i * 6.0), BACKDROP.size.x + 60.0) - 30.0
		var at := Vector2(x, BACKDROP.position.y + 30 + i * 28 + sin(t * 2.0 + i) * 10)
		var flap := sin(t * 9.0 + i) * 7.0
		var alpha := 0.5 * _edge_fade(at)
		var light := color.lightened(0.3)
		_backdrop.draw_colored_polygon(PackedVector2Array([at, at + Vector2(-12, -flap - 2), at + Vector2(-12, -flap + 5), at + Vector2(0, 6)]), Color(light, alpha * 0.6))
		_backdrop.draw_colored_polygon(PackedVector2Array([at, at + Vector2(12, -flap - 2), at + Vector2(12, -flap + 5), at + Vector2(0, 6)]), Color(light, alpha * 0.6))
		_backdrop.draw_line(at, at + Vector2(0, 6), Color(light, alpha), 1.5)
	for i in 8:
		var fall := fmod(t * 15.0 + i * 37.0, BACKDROP.size.y + 20.0) - 10.0
		var at := Vector2(BACKDROP.position.x + fmod(i * 73.0, BACKDROP.size.x) + sin(t * 1.5 + i) * 20.0, BACKDROP.position.y + fall)
		_backdrop.draw_set_transform(at, sin(t * 2.0 + i) * 0.8, Vector2.ONE)
		_backdrop.draw_rect(Rect2(-4, -5, 8, 10), Color(0.95, 0.92, 0.82, 0.3 * _edge_fade(at)))
		_backdrop.draw_set_transform(Vector2.ZERO)


## A crowd of silhouettes along the bottom, bouncing and waving (Wally's game).
func _backdrop_crowd(color: Color, t: float) -> void:
	for i in 26:
		var x := BACKDROP.position.x + 12 + i * 23.0
		var bounce := absf(sin(t * (4.0 + i % 3) + i * 0.7)) * 6.0
		var at := Vector2(x, BACKDROP.end.y - 8 - bounce)
		var shade := Color(0.05, 0.04, 0.03, 0.75 * _edge_fade(Vector2(x, BACKDROP.end.y - 30)))
		_backdrop.draw_circle(at + Vector2(0, -16), 5, shade)
		_backdrop.draw_rect(Rect2(at + Vector2(-7, -11), Vector2(14, 14)), shade)
		if i % 4 == 2:
			# Pom-poms, gold and black, shaking.
			var shake := sin(t * 14.0 + i) * 3.0
			_backdrop.draw_circle(at + Vector2(-9 + shake, -22), 5, Color(1.0, 0.8, 0.15, 0.85))
			_backdrop.draw_circle(at + Vector2(9 - shake, -22), 5, Color(0.08, 0.08, 0.08, 0.85))
		if i % 4 == 0:
			# Someone waving a pennant.
			var wave := sin(t * 6.0 + i) * 0.5
			var hand := at + Vector2(6, -20)
			var tip := hand + Vector2.from_angle(-PI / 2 + wave) * 14
			_backdrop.draw_line(at + Vector2(5, -8), hand, shade, 2.0)
			_backdrop.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(8, 3), tip + Vector2(0, 6)]), Color(color, 0.7))


## Wally's song is 168 beats per minute; his arena flashes and bursts along with it.
const WALLY_BPM := 168.0
const ARENA_COLORS := [Color(1, 0.3, 0.3), Color(1, 0.85, 0.2), Color(0.3, 0.8, 1), Color(0.5, 1, 0.4), Color(1, 0.5, 1)]


## Wally's halftime show, behind everything: a scoreboard with chasing marquee bulbs
## flashing "WALLY! WALLY!" on the beat, colored light pools sweeping the floor,
## lasers crisscrossing, fireworks on the beat, and camera flashes in the crowd.
func _backdrop_arena(color: Color, t: float) -> void:
	var song := Game.music_time()
	var beats := (song if song >= 0.0 else t) * WALLY_BPM / 60.0
	var on_beat := pow(1.0 - fmod(beats, 1.0), 3.0)
	var calm := Game.reduce_flashing()
	# Light pools sweeping across the floor.
	for k in 3:
		var x := BACKDROP.get_center().x + sin(t * (0.6 + k * 0.25) + k * 2.1) * 230.0
		var pool := Vector2(x, BACKDROP.end.y - 26)
		_backdrop.draw_set_transform(pool, 0.0, Vector2(1.0, 0.3))
		_backdrop.draw_circle(Vector2.ZERO, 70.0, Color(ARENA_COLORS[(k * 2 + int(beats / 4.0)) % ARENA_COLORS.size()], 0.14))
		_backdrop.draw_set_transform(Vector2.ZERO)
	# Lasers from the top corners, sweeping back and forth.
	for corner in 2:
		var from := Vector2(BACKDROP.position.x + 10 if corner == 0 else BACKDROP.end.x - 10, BACKDROP.position.y + 6)
		for k in 3:
			var angle := PI / 2 + (0.9 - k * 0.45) * (1.0 if corner == 0 else -1.0) + sin(t * 1.3 + k + corner * 2.0) * 0.35
			var to := from + Vector2.from_angle(angle) * 340.0
			var laser: Color = ARENA_COLORS[(k + corner * 2) % ARENA_COLORS.size()]
			_backdrop.draw_line(from, to, Color(laser, 0.18), 3.0)
			_backdrop.draw_line(from, to, Color(laser.lightened(0.5), 0.45), 1.0)
	# The scoreboard.
	var board := Rect2(BACKDROP.get_center().x - 100, BACKDROP.position.y + 10, 200, 46)
	_backdrop.draw_rect(board, Color(0.05, 0.05, 0.07))
	_backdrop.draw_rect(board, Color(0.85, 0.65, 0.15), false, 2.0)
	var flash := int(beats) % 2 == 0
	var shout := "WALLY! WALLY!" if flash or calm else "GO WOLVERINES!"
	var width := _font.get_string_size(shout, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_backdrop.draw_string(_font, Vector2(board.get_center().x - width / 2, board.position.y + 22), shout, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.2, 0.75 + 0.25 * on_beat))
	_backdrop.draw_string(_font, Vector2(board.position.x + 30, board.end.y - 7), "HOME 7      AWAY 3", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.35, 0.3))
	# Chasing bulbs all the way around the board.
	var bulbs := 26
	for k in bulbs:
		var f := float(k) / bulbs
		var at: Vector2
		if f < 0.5:
			at = board.position + Vector2(board.size.x * f * 2.0, -4)
		else:
			at = Vector2(board.end.x - board.size.x * (f - 0.5) * 2.0, board.end.y + 4)
		var lit := (k + int(t * 10.0)) % 3 == 0
		_backdrop.draw_circle(at, 2.0, Color(1.0, 0.9, 0.5, 0.95) if lit else Color(0.4, 0.3, 0.1, 0.6))
	# Fireworks: a burst every other bar, up in the rafters.
	var bar := int(beats / 4.0)
	var into := beats / 4.0 - bar
	if bar % 2 == 0 and into < 0.6:
		var rng := RandomNumberGenerator.new()
		rng.seed = bar * 131 + 7
		for burst in 2:
			var middle := Vector2(BACKDROP.position.x + rng.randf_range(60.0, BACKDROP.size.x - 60.0), BACKDROP.position.y + rng.randf_range(30.0, 90.0))
			var spark: Color = ARENA_COLORS[rng.randi() % ARENA_COLORS.size()]
			for s in 14:
				var dir := Vector2.from_angle(s * TAU / 14)
				var reach := 8.0 + into * 60.0
				_backdrop.draw_line(middle + dir * reach * 0.6, middle + dir * reach, Color(spark, 0.9 * (1.0 - into / 0.6)), 2.0)
	# Camera flashes in the crowd (not with Reduce flashing on).
	if not calm:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(t * 7.0)
		for f in 3:
			var at := Vector2(BACKDROP.position.x + rng.randf_range(20.0, BACKDROP.size.x - 20.0), BACKDROP.end.y - rng.randf_range(12.0, 30.0))
			_backdrop.draw_circle(at, 3.0 + rng.randf() * 3.0, Color(1, 1, 1, 0.5 * rng.randf()))


## Hopkuna's song is 184 beats per minute; his background pulses along with it.
const HOPKUNA_BPM := 184.0


## A red heartbeat pulsing in from the edges, and glowing orbs (his eyes, and a
## ring of smaller ones circling them) that throb on every beat of the music,
## hardest on the first beat of each bar. Every couple of bars, a BLACK FLASH bolt
## strikes somewhere in the background (Hopkuna).
func _backdrop_heartbeat(color: Color, t: float) -> void:
	var song := Game.music_time()
	var beats := (song if song >= 0.0 else t) * HOPKUNA_BPM / 60.0
	var into_beat := fmod(beats, 1.0)
	var downbeat := int(beats) % 4 == 0
	var pulse := pow(1.0 - into_beat, 3.0) * (1.0 if downbeat else 0.6)
	for i in 6:
		var inset := i * 10.0
		_backdrop.draw_rect(BACKDROP.grow(-inset), Color(color, (0.07 - i * 0.01) * (0.4 + pulse)), false, 10.0)
	var center := BACKDROP.get_center()
	# The ring of small orbs, turning slowly, each one throbbing a little after the last.
	for k in 8:
		var angle := t * 0.4 + k * TAU / 8
		var orb := center + Vector2(cos(angle) * 150.0, sin(angle) * 70.0)
		var late := pow(1.0 - fmod(beats - k * 0.06 + 1.0, 1.0), 3.0)
		_backdrop.draw_circle(orb, 7.0 + late * 8.0, Color(color, 0.08 + 0.25 * late))
		_backdrop.draw_circle(orb, 2.5 + late * 2.5, Color(color.lightened(0.5), 0.3 + 0.6 * late))
	# His eyes.
	for side in [-1, 1]:
		var eye := center + Vector2(side * 30, -10)
		_backdrop.draw_circle(eye, 20.0 + pulse * 14.0, Color(color, 0.06 + 0.16 * pulse))
		_backdrop.draw_circle(eye, 10.0 + pulse * 6.0, Color(color, 0.15 + 0.35 * pulse))
		_backdrop.draw_circle(eye, 3.0 + pulse * 2.5, Color(1, 0.75, 0.75, 0.3 + 0.6 * pulse))
	_backdrop_black_flash(color, beats)


## Every two bars, on the downbeat, a black-and-red bolt cracks down through the
## background and the whole thing flickers.
func _backdrop_black_flash(color: Color, beats: float) -> void:
	var window := int(beats / 8.0)
	var into := beats - window * 8.0
	if into > 1.2:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = window * 977 + 13
	var x := BACKDROP.position.x + rng.randf_range(60.0, BACKDROP.size.x - 60.0)
	var from := Vector2(x, BACKDROP.position.y)
	var to := Vector2(x + rng.randf_range(-80.0, 80.0), BACKDROP.end.y)
	var fade := 1.0 - into / 1.2
	# A dark flicker over everything for the first instant.
	if into < 0.25 and not Game.reduce_flashing():
		_backdrop.draw_rect(BACKDROP, Color(0, 0, 0, 0.35 * (1.0 - into / 0.25)))
	var shape_seed := window * 31 + int(into * 6.0)
	_draw_bolt(from, to, Color(color, 0.25 * fade), 12.0, shape_seed, _backdrop)
	_draw_bolt(from, to, Color(0.02, 0.0, 0.0, 0.9 * fade), 5.0, shape_seed, _backdrop)
	_draw_bolt(from, to, Color(1.0, 0.15, 0.2, fade), 1.5, shape_seed, _backdrop)
