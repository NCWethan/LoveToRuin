extends Node2D
## Runs a battle, Deltarune-style:
##   1. Each party member picks FIGHT, ACT, ITEM, MERCY or DEFEND.
##   2. Their actions play out.
##   3. The enemies attack, and the SOUL dodges inside the box.
##   4. Repeat until every enemy is spared or knocked out.
##
## The fighters and their lines come from tutorial_battle.gd.
## Controls: arrow keys to move, Enter to confirm, X / Shift to go back.

enum State { TEXT, MENU, TARGET_ENEMY, ACT_LIST, ITEM_LIST, TARGET_PARTY, MERCY_MENU, READY, FIGHT_BAR, FIGHT_ANIM, ENEMY_TURN, GAME_OVER, EVENT, FLEEING, DONE }

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
## Recent bar positions, drawn as a fading afterimage.
var _bar_trail: Array[float] = []

# The attack animation after the bar is stopped.
var _anim_time: float = 0.0
var _anim_damage: int = 0
var _anim_accuracy: float = 0.0
var _anim_landed: bool = false

# Enemy turn
var _enemy_timer: float = 0.0
var _spawn_timers: Dictionary = {}
var _spawn_steps: Dictionary = {}
var _turn_patterns: Dictionary = {}
## The attack each enemy used last turn, so it doesn't repeat right away.
var _last_patterns: Dictionary = {}
var _attackers: Array[Enemy] = []
var _speech: Dictionary = {}
var _invincible_timer: float = 0.0

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
	_typed += delta * TYPE_SPEED * Game.text_speed() * (0.35 if _text_color != Color.WHITE else 1.0)
	_update_effects(delta)
	_text_beeps()

	match state:
		State.TEXT:
			_process_text()
		State.MENU:
			_process_menu()
		State.TARGET_ENEMY, State.ACT_LIST, State.ITEM_LIST, State.TARGET_PARTY, State.MERCY_MENU:
			_process_list()
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
	if _pressed("confirm"):
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
				_open_list(State.MERCY_MENU, ["Spare", "Flee"])
			"ITEM":
				var available := _available_items()
				if not available.is_empty():
					_open_list(State.ITEM_LIST, available)
				else:
					# Say so, instead of silently doing nothing.
					Game.play_sfx("miss")
					_text = "* (You don't have any items.)" if items.is_empty() else "* (Your teammate already picked the last item.)"
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
		elif state == State.TARGET_ENEMY and _pending == "MERCY":
			_open_list(State.MERCY_MENU, ["Spare", "Flee"])
		else:
			_open_menu()
		return

	var area := box.get_inner_rect()
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
			else:
				_try_flee()


# --- Player turn: running the actions -------------------------------------

func _run_actions() -> void:
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


# --- FIGHT bar ------------------------------------------------------------

func _start_fight_bar(member: PartyMember, target: Enemy) -> void:
	_bar_member = member
	_bar_target = target
	_bar_pos = 0.0
	_bar_wait = FIGHT_WINDUP
	_bar_trail.clear()
	_text = ""
	soul.visible = false
	state = State.FIGHT_BAR


func _process_fight_bar(delta: float) -> void:
	# A short "READY..." first, so there's time to get set.
	if _bar_wait > 0.0:
		_bar_wait -= delta
		return
	_bar_trail.append(_bar_pos)
	if _bar_trail.size() > 6:
		_bar_trail.pop_front()
	_bar_pos += delta / FIGHT_BAR_TIME
	if _pressed("confirm"):
		# 1.0 for a hit dead in the middle, 0.0 at the very edges.
		_resolve_hit(1.0 - absf(_bar_pos - 0.5) * 2.0)
	elif _bar_pos >= 1.0:
		_resolve_hit(-1.0)


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
	var before := _anim_time
	_anim_time += delta
	var member := _bar_member
	var target := _bar_target
	if member.name == "Hop":
		# Hop's punches each land with their own thump.
		for at in HOP_PUNCHES:
			if before < at and _anim_time >= at:
				Game.play_sfx("punch", randf_range(0.9, 1.15))
				target.shake = 0.15
	if not _anim_landed and _anim_time >= ATTACK_SLASH_TIME:
		_anim_landed = true
		target.hp = maxi(target.hp - _anim_damage, 0)
		target.shake = 0.5
		target.flash = 0.25
		Game.play_sfx("hit")
		var critical := _anim_accuracy >= CRITICAL
		_add_popup(str(_anim_damage), target.position + Vector2(0, -30), YELLOW if critical else Color(1, 0.25, 0.25), 32 if critical else 26, true)
		if critical:
			_add_popup("CRITICAL!", target.position + Vector2(0, -70), YELLOW, 18)
	if _anim_time < ATTACK_SLASH_TIME + 0.9:
		return

	var lines: Array[String] = ["* %s hit %s for %d damage!" % [member.name, target.name, _anim_damage]]
	if _anim_accuracy >= CRITICAL:
		lines[0] = "* CRITICAL HIT!\n" + lines[0]
	if target.hit_line != "":
		lines[0] += "\n" + target.hit_line
	if target.hp == 0:
		target.state = "defeated"
		exp_gained += target.exp_reward
		lines.append("* %s was knocked out!" % target.name)
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
func _hurt_party(amount: int) -> void:
	var member: PartyMember = null
	for candidate in party:
		if not candidate.is_down():
			member = candidate
			break
	if member == null:
		return
	var damage := ceili(amount / 2.0) if member.defending else amount
	member.hp = maxi(member.hp - damage, 0)
	member.shake = 0.4
	_add_popup(str(damage), _panel_position(member), Color.RED)
	Game.play_sfx("hurt")
	_invincible_timer = invincibility_time

	if party.all(func(m: PartyMember) -> bool: return m.is_down()):
		_game_over()


func _end_enemy_turn() -> void:
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
		var base := "res://art/sprites/" + member.name.to_lower()
		_side_frames[member] = [load(base + "_side.png"), load(base + "_side2.png")]
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
## How long each part lasts: silence, the scream, black, and the laugh.
const TENT_SILENCE := 1.6
const TENT_SCREAM_TIME := 3.0
const TENT_BLACK_TIME := 0.5
const TENT_LAUGH_TIME := 3.8

## "silence", "scream", "black" or "laugh".
var _tent_phase: String = ""
var _tent_time: float = 0.0
## The color of the text in the box (red for the tent).
var _text_color: Color = Color.WHITE
## When the tent froze the background (so it stops right where it was).
var _frozen_at: float = 0.0


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
				Game.play_sfx("laugh")
		"laugh":
			if _tent_time >= TENT_LAUGH_TIME:
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
		if not taken:
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
		# The health bar drains smoothly toward the real HP.
		if enemy.shown_hp < 0.0:
			enemy.shown_hp = enemy.hp
		enemy.shown_hp = move_toward(enemy.shown_hp, enemy.hp, enemy.max_hp * 0.8 * delta)
	for member in _member_anim:
		_member_anim[member]["time"] += delta
	for member in party:
		member.shake = maxf(member.shake - delta, 0.0)


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
	_draw_enemies()
	_draw_boss_bar()
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


## The attack animation: three glowing slashes sweep across the enemy, in the
## attacker's color (gold for a CRITICAL), then flare out.
func _draw_slash() -> void:
	if state != State.FIGHT_ANIM or _bar_target == null:
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
			if enemy.dance and enemy.is_active():
				_dance_transform(Vector2(pos.x, pos.y + 40.0))
				var feet_rect := Rect2(Vector2(-sprite_size.x / 2, -sprite_size.y), sprite_size)
				_overlay.draw_texture_rect(enemy.sprite, feet_rect, false, tint)
				if enemy.flash > 0.0:
					_overlay.draw_texture_rect(enemy.sprite, feet_rect, false, Color(4, 4, 4, enemy.flash * 3.0))
				_overlay.draw_set_transform(Vector2.ZERO)
			else:
				# Everyone still fighting bobs gently, each at their own pace.
				var idle := sin(Time.get_ticks_msec() / 1000.0 * 2.2 + pos.x * 0.05) * 2.5 if enemy.is_active() and _data.event == "" else 0.0
				var rect := Rect2(Vector2(pos.x - sprite_size.x / 2, top + idle), sprite_size)
				_overlay.draw_texture_rect(enemy.sprite, rect, false, tint)
				# Flash white for a moment when hit.
				if enemy.flash > 0.0:
					_overlay.draw_texture_rect(enemy.sprite, rect, false, Color(4, 4, 4, enemy.flash * 3.0))
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
			_draw_outlined("HP %d / %d" % [boss.hp, boss.max_hp], Vector2(22, rect.end.y + 15), 12, Color(1, 0.9, 0.6))
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
			_draw_outlined("HP ??? / ???", Vector2(22, rect.end.y + 15), 12, Color(1, 0.5, 0.5))


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


## Draws a party member in their current pose, standing on `feet`.
##   idle      breathing (a gentle stretch and squash)
##   choosing  a little bounce
##   FIGHT     leaning back to wind up while the timing bar runs, then a lunge at the
##             enemy (Hop's fists blur through his three punches)
##   ACT       a hop      ITEM  a squash-and-stretch with sparkles
##   MERCY     a wave     DEFEND  a crouch behind a shimmering shield
##   hurt      a flinch backward, flashing red
##   down      lying on the ground
func _draw_member(member: PartyMember, index: int, feet: Vector2, sprite_size: Vector2, tint: Color) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var offset := Vector2.ZERO
	var rot := 0.0
	var scale := Vector2.ONE
	var anim: Dictionary = _member_anim.get(member, {})
	var anim_time: float = anim.get("time", 99.0)

	if member.is_down():
		rot = -PI / 2
		offset = Vector2(-sprite_size.y * 0.25, 0)
	else:
		var breath := sin(t * 2.4 + index * 1.3)
		scale = Vector2(1.0 - 0.015 * breath, 1.0 + 0.025 * breath)
		if _is_choosing(index):
			offset.y -= absf(sin(t * 5.0)) * 3.0
		if member.defending:
			scale *= Vector2(1.08, 0.86)
		# FIGHT: wind up, then lunge.
		if _bar_member == member and state == State.FIGHT_BAR:
			rot = -0.1 + sin(t * 14.0) * 0.015
			offset.x = -6.0
		elif _bar_member == member and state == State.FIGHT_ANIM:
			var out := clampf(_anim_time / 0.1, 0.0, 1.0)
			var back := clampf((_anim_time - 0.65) / 0.3, 0.0, 1.0)
			var lunge := out * (1.0 - back)
			offset.x = 60.0 * lunge
			offset.y = -sin(clampf(_anim_time / 0.2, 0.0, 1.0) * PI) * 22.0 * (1.0 - back)
			rot = 0.16 * lunge
			if member.name == "Hop" and _anim_time < 0.36:
				offset.x += sin(_anim_time * 90.0) * 6.0
		# The other actions play once, right as they happen.
		match anim.get("type", ""):
			"ACT":
				if anim_time < 0.5:
					offset.y -= sin(anim_time / 0.5 * PI) * 22.0
			"ITEM":
				if anim_time < 0.6:
					var squash := sin(anim_time / 0.6 * PI * 2.0)
					scale *= Vector2(1.0 + 0.12 * squash, 1.0 - 0.12 * squash)
					for s in 6:
						var spark := feet + Vector2(cos(s * 1.1) * 24.0, -20.0 - anim_time * 80.0 - s * 6.0)
						_overlay.draw_rect(Rect2(spark, Vector2(3, 3)), Color(0.4, 1.0, 0.5, 1.0 - anim_time / 0.6))
			"MERCY":
				if anim_time < 0.8:
					rot = sin(anim_time * 20.0) * 0.12 * (1.0 - anim_time / 0.8)
					offset.y -= absf(sin(anim_time * 10.0)) * 6.0
			"DEFEND":
				if anim_time < 0.25:
					offset.y -= sin(anim_time / 0.25 * PI) * 8.0
		# Hit: knocked back a little, flashing red.
		if member.shake > 0.0:
			var hurt := member.shake / 0.4
			rot -= 0.18 * hurt
			offset.x -= 8.0 * hurt
			tint = tint.lerp(Color(1.0, 0.3, 0.3), hurt)

	_overlay.draw_set_transform(feet + offset, rot, scale)
	_overlay.draw_texture_rect(member.sprite, Rect2(Vector2(-sprite_size.x / 2, -sprite_size.y), sprite_size), false, tint)
	_overlay.draw_set_transform(Vector2.ZERO)

	# A shimmering shield in front of anyone defending.
	if member.defending and not member.is_down():
		var shimmer := 0.5 + 0.5 * sin(t * 6.0)
		var center := feet + Vector2(34, -sprite_size.y * 0.45)
		_overlay.draw_arc(center, 30.0, -1.1, 1.1, 16, Color(0.5, 0.8, 1.0, 0.35 + 0.3 * shimmer), 4.0)
		_overlay.draw_arc(center, 24.0, -0.9, 0.9, 12, Color(0.8, 0.95, 1.0, 0.25 + 0.2 * shimmer), 2.0)


func _is_choosing(member_index: int) -> bool:
	var picking := state in [State.MENU, State.TARGET_ENEMY, State.ACT_LIST, State.ITEM_LIST, State.TARGET_PARTY, State.MERCY_MENU]
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
		_draw_bar(Rect2(x + 64, PANEL_Y - 13, 110, 14), float(member.hp) / member.max_hp, YELLOW)
		_overlay.draw_string(_font, Vector2(x + 182, PANEL_Y), "%d / %d" % [member.hp, member.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
		if member.defending:
			_overlay.draw_string(_font, Vector2(x + 242, PANEL_Y - 1), "DEF", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.SKY_BLUE)


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
		State.TEXT, State.MENU, State.READY:
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
		State.FLEEING:
			_overlay.draw_string(_font, Vector2(area.position.x + 14, _row_y(0)), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
		State.FIGHT_BAR, State.FIGHT_ANIM:
			_draw_fight_bar(area)

	# A reminder of the controls in the corner of the box.
	var hint := ""
	if state == State.MENU:
		hint = "ENTER: choose   X: back" if _can_go_back() else "ENTER: choose"
	elif state in [State.TARGET_ENEMY, State.ACT_LIST, State.ITEM_LIST, State.TARGET_PARTY, State.MERCY_MENU]:
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
	if state == State.FIGHT_ANIM:
		prompt = "CRITICAL!" if _anim_accuracy >= CRITICAL else "HIT!"
	var prompt_color := YELLOW if state == State.FIGHT_ANIM or _bar_wait <= 0.0 else Color.GRAY
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

	# The bar, with an afterimage trail.
	for i in _bar_trail.size():
		var tx := target.position.x + clampf(_bar_trail[i], 0.0, 1.0) * target.size.x
		_overlay.draw_rect(Rect2(tx - 3, target.position.y - 2, 6, target.size.y + 4), Color(color, 0.08 * (i + 1)))
	var x := target.position.x + clampf(_bar_pos, 0.0, 1.0) * target.size.x
	var glow := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 90.0) if _bar_wait > 0.0 else 1.0
	_overlay.draw_rect(Rect2(x - 7, target.position.y - 6, 14, target.size.y + 12), Color(color, 0.3 * glow))
	_overlay.draw_rect(Rect2(x - 3, target.position.y - 6, 6, target.size.y + 12), Color(color, glow))
	_overlay.draw_rect(Rect2(x - 1, target.position.y - 6, 2, target.size.y + 12), Color(1, 1, 1, glow))


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

## A slowly drifting lattice of diamonds behind the fight, in the fight's color,
## fading out toward the edges, with a few twinkling points.
func _draw_backdrop() -> void:
	if state == State.GAME_OVER or _data == null:
		return
	var color := _data.backdrop
	# Once the tent's music cuts out, the background goes dim and stops moving.
	var frozen := _tent_phase != ""
	if frozen:
		color = color.darkened(0.6)
	var t := Time.get_ticks_msec() / 1000.0 if not frozen else _frozen_at
	var drift := Vector2(fmod(t * 8.0, DIAMOND_SPACING), fmod(t * 4.0, DIAMOND_SPACING))
	var columns := int(BACKDROP.size.x / DIAMOND_SPACING) + 2
	var rows := int(BACKDROP.size.y / (DIAMOND_SPACING * 0.5)) + 3
	for gx in range(-1, columns):
		for gy in range(-2, rows):
			var center := BACKDROP.position + drift + Vector2(gx * DIAMOND_SPACING + (DIAMOND_SPACING / 2 if gy % 2 != 0 else 0.0), gy * DIAMOND_SPACING * 0.5)
			var edge := minf(minf(center.x - BACKDROP.position.x, BACKDROP.end.x - center.x), minf(center.y - BACKDROP.position.y, BACKDROP.end.y - center.y))
			if edge < 10.0:
				continue
			var alpha := clampf((edge - 10.0) / 40.0, 0.0, 1.0) * 0.45
			var r := 9.0
			_backdrop.draw_polyline(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0), center + Vector2(0, -r)]), Color(color, alpha), 1.5)
			if posmod(gx * 7 + gy * 13, 11) == 0:
				var twinkle := 0.5 + 0.5 * sin(t * 3.0 + gx + gy)
				_backdrop.draw_circle(center, 2.0, Color(color.lightened(0.5), alpha * twinkle * 1.6))
