extends Node2D
## Runs a battle, Deltarune-style:
##   1. Each party member picks FIGHT, ACT, ITEM, MERCY or DEFEND.
##   2. Their actions play out.
##   3. The enemies attack, and the SOUL dodges inside the box.
##   4. Repeat until every enemy is spared or knocked out.
##
## The fighters and their lines come from tutorial_battle.gd.
## Controls: arrow keys to move, Z / Enter to confirm, X / Shift to go back.

enum State { TEXT, MENU, TARGET_ENEMY, ACT_LIST, ITEM_LIST, TARGET_PARTY, READY, FIGHT_BAR, ENEMY_TURN, GAME_OVER }

const BUTTONS := ["FIGHT", "ACT", "ITEM", "MERCY", "DEFEND"]

## The box is wide while showing text, and small while dodging.
const BOX_CENTER := Vector2(320, 320)
const TEXT_BOX_SIZE := Vector2(570, 120)
const ATTACK_BOX_SIZE := Vector2(160, 120)

## How long each enemy turn lasts, in seconds.
const ENEMY_TURN_TIME := 5.0
## How long the FIGHT bar takes to cross the box, in seconds.
const FIGHT_BAR_TIME := 1.2
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

# Enemy turn
var _enemy_timer: float = 0.0
var _spawn_timers: Dictionary = {}
var _spawn_steps: Dictionary = {}
var _turn_patterns: Dictionary = {}
var _attackers: Array[Enemy] = []
var _speech: Dictionary = {}
var _invincible_timer: float = 0.0

# Floating damage numbers
var _popups: Array[Dictionary] = []

var _overlay: Node2D
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

	if Game.pending_battle != "":
		# Started from the overworld: use the real party and inventory,
		# so HP and used items carry over.
		party = Game.party
		items = Game.items
	else:
		# Started on its own (F6 in the editor): use a fresh party for testing.
		party = TutorialBattle.create_party()
		items = TutorialBattle.create_items()
	enemies = TutorialBattle.create_enemies()

	box.center = BOX_CENTER
	box.size = TEXT_BOX_SIZE
	soul.can_move = false

	_show_messages(TutorialBattle.INTRO, _start_enemy_turn)


func _process(delta: float) -> void:
	_typed += delta * TYPE_SPEED
	_update_effects(delta)
	_text_beeps()

	match state:
		State.TEXT:
			_process_text()
		State.MENU:
			_process_menu()
		State.TARGET_ENEMY, State.ACT_LIST, State.ITEM_LIST, State.TARGET_PARTY:
			_process_list()
		State.READY:
			_process_ready()
		State.FIGHT_BAR:
			_process_fight_bar(delta)
		State.ENEMY_TURN:
			_process_enemy_turn(delta)
		State.GAME_OVER:
			_process_game_over(delta)

	_overlay.queue_redraw()


var _last_beep: int = 0

## A little beep every other letter while text types out.
func _text_beeps() -> void:
	var shown := clampi(int(_typed), 0, _text.length())
	if shown < _last_beep:
		_last_beep = 0
	if shown > _last_beep and shown % 2 == 0 and _text[shown - 1] != " ":
		Game.play_sfx("text")
	_last_beep = shown


# --- Text ------------------------------------------------------------------

## Shows each line in the box, one at a time (press Z for the next), then calls `then`.
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
	_flavor = TutorialBattle.flavor_text(turn, enemies)
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
	lines.append("* (Z: go!     X: change something)")
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
			"FIGHT", "ACT", "MERCY":
				_open_list(State.TARGET_ENEMY, _active_enemies())
			"ITEM":
				var available := _available_items()
				if not available.is_empty():
					_open_list(State.ITEM_LIST, available)
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
	_text = ""
	soul.visible = false
	state = State.FIGHT_BAR


func _process_fight_bar(delta: float) -> void:
	_bar_pos += delta / FIGHT_BAR_TIME
	if _pressed("confirm"):
		# 1.0 for a hit dead in the middle, 0.0 at the very edges.
		_resolve_hit(1.0 - absf(_bar_pos - 0.5) * 2.0)
	elif _bar_pos >= 1.0:
		_resolve_hit(-1.0)


func _resolve_hit(accuracy: float) -> void:
	var member := _bar_member
	var target := _bar_target
	if accuracy < 0.0:
		_add_popup("MISS", target.position + Vector2(0, -20), Color.LIGHT_GRAY)
		Game.play_sfx("miss")
		_show_messages(["* %s missed!" % member.name], _run_next_action)
		return

	var damage := maxi(1, roundi(member.attack * (0.8 + 2.2 * accuracy)) - target.defense)
	target.hp = maxi(target.hp - damage, 0)
	target.shake = 0.4
	_add_popup(str(damage), target.position + Vector2(0, -20), Color.RED)
	Game.play_sfx("hit")

	var lines: Array[String] = ["* %s hit %s for %d damage!" % [member.name, target.name, damage]]
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
	_attackers = TutorialBattle.attackers(enemy_turn, enemies)
	enemy_turn += 1

	_spawn_timers.clear()
	_spawn_steps.clear()
	_turn_patterns.clear()
	_speech.clear()
	for enemy in _attackers:
		_spawn_timers[enemy] = 0.0
		_spawn_steps[enemy] = 0
		# A different attack each turn, cycling through the enemy's list.
		# (The very first turn always uses the first one, the easiest.)
		_turn_patterns[enemy] = enemy.patterns[(enemy_turn - 1) % enemy.patterns.size()]
	for enemy in _active_enemies():
		_speech[enemy] = enemy.taunt()

	create_tween().tween_property(box, "size", ATTACK_BOX_SIZE, 0.25)
	soul.global_position = BOX_CENTER
	soul.visible = true
	soul.can_move = true


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
		if bullet and bullet.get_hitbox().intersects(soul_hitbox):
			bullet.queue_free()
			_hurt_party(bullet.damage)
			return


## A bullet hit: a random party member who's still standing takes the damage.
func _hurt_party(amount: int) -> void:
	var standing := party.filter(func(m: PartyMember) -> bool: return not m.is_down())
	var member: PartyMember = standing.pick_random()
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
	_start_player_turn()


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
		var result := {"spared": [], "defeated": [], "bond": bond_gained, "exp": exp_gained, "money": money}
		for enemy in enemies:
			if enemy.state == "spared":
				result["spared"].append(enemy.name)
			elif enemy.state == "defeated":
				result["defeated"].append(enemy.name)
		_show_messages(lines, func() -> void: Game.finish_battle(result))
	else:
		lines.append("* (Press Z to fight again.)")
		_show_messages(lines, get_tree().reload_current_scene)


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
			_draw_centered("(press Z)", Vector2(320, 360), 14, Color.GRAY)


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


func _add_popup(text: String, at: Vector2, color: Color) -> void:
	_popups.append({"text": text, "position": at, "color": color, "time": 0.8})


func _update_effects(delta: float) -> void:
	for popup in _popups:
		popup["time"] -= delta
		popup["position"] += Vector2(0, -30) * delta
	_popups.assign(_popups.filter(func(p: Dictionary) -> bool: return p["time"] > 0.0))
	for enemy in enemies:
		enemy.shake = maxf(enemy.shake - delta, 0.0)
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

	_draw_party_sprites()
	_draw_enemies()
	_draw_party_panel()
	_draw_buttons()
	_draw_box_contents()

	for popup in _popups:
		_draw_centered(popup["text"], popup["position"], 20, popup["color"])


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
			# Pixel art is drawn at 3x so each pixel shows up as a crisp 3x3 block.
			var sprite_size := enemy.sprite.get_size() * 3.0
			top = pos.y + 40.0 - sprite_size.y
			_overlay.draw_texture_rect(enemy.sprite, Rect2(Vector2(pos.x - sprite_size.x / 2, top), sprite_size), false, tint)
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
				_draw_bar(Rect2(pos + Vector2(-30, 48), Vector2(60, 6)), float(enemy.hp) / enemy.max_hp, Color.GREEN)

		if _speech.has(enemy) and _speech[enemy] != "":
			_draw_speech(_speech[enemy], Vector2(pos.x, top - 30))


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
		var tint := Color(0.4, 0.4, 0.4) if member.is_down() else Color.WHITE
		_overlay.draw_texture_rect(member.sprite, Rect2(Vector2(pos.x - sprite_size.x / 2, top), sprite_size), false, tint)

		# Show whose turn it is to choose.
		if _is_choosing(i):
			_draw_centered(member.name, Vector2(pos.x, top - 8), FONT_SIZE, member.color)


func _is_choosing(member_index: int) -> bool:
	var picking := state in [State.MENU, State.TARGET_ENEMY, State.ACT_LIST, State.ITEM_LIST, State.TARGET_PARTY]
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
		var name_color := member.color if not member.is_down() else Color.DIM_GRAY
		_overlay.draw_string(_font, Vector2(x, PANEL_Y), member.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, name_color)
		_draw_bar(Rect2(x + 70, PANEL_Y - 11, 80, 10), float(member.hp) / member.max_hp, YELLOW)
		_overlay.draw_string(_font, Vector2(x + 160, PANEL_Y), "%d / %d" % [member.hp, member.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
		if member.defending:
			_overlay.draw_string(_font, Vector2(x + 225, PANEL_Y), "DEF", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.SKY_BLUE)
		if choosing:
			_overlay.draw_line(Vector2(x, PANEL_Y + 4), Vector2(x + 250, PANEL_Y + 4), member.color, 2.0)


func _draw_buttons() -> void:
	for i in BUTTONS.size():
		var rect := Rect2(Vector2(22 + i * BUTTON_SPACING, BUTTON_Y), BUTTON_SIZE)
		var selected := state == State.MENU and i == _button
		var color := YELLOW if selected else ORANGE
		_overlay.draw_rect(rect, color, false, 2.0)
		_overlay.draw_string(_font, rect.position + Vector2(30, 22), BUTTONS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)


func _draw_box_contents() -> void:
	var area := box.get_inner_rect()
	match state:
		State.TEXT, State.MENU, State.READY:
			var visible_text := _text.substr(0, int(maxf(_typed, 0.0)))
			var lines := visible_text.split("\n")
			for i in lines.size():
				_overlay.draw_string(_font, Vector2(area.position.x + 14, _row_y(i)), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
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
		State.FIGHT_BAR:
			_draw_fight_bar(area)

	# A reminder of the controls in the corner of the box.
	var hint := ""
	if state == State.MENU:
		hint = "Z: choose   X: back" if _can_go_back() else "Z: choose"
	elif state in [State.TARGET_ENEMY, State.ACT_LIST, State.ITEM_LIST, State.TARGET_PARTY]:
		hint = "Z: choose   X: back"
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


func _draw_fight_bar(area: Rect2) -> void:
	_overlay.draw_string(_font, Vector2(area.position.x + 14, _row_y(0)), "* %s attacks %s!  Press Z in the middle!" % [_bar_member.name, _bar_target.name], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
	var target := Rect2(area.position + Vector2(20, 40), Vector2(area.size.x - 40, area.size.y - 55))
	_overlay.draw_rect(target, Color(0.15, 0.15, 0.15))
	_overlay.draw_rect(target, Color.WHITE, false, 1.0)
	# The sweet spot in the middle.
	_overlay.draw_rect(Rect2(target.get_center().x - 6, target.position.y, 12, target.size.y), Color(0.2, 0.7, 0.2))
	# The moving bar.
	var x := target.position.x + clampf(_bar_pos, 0.0, 1.0) * target.size.x
	_overlay.draw_rect(Rect2(x - 3, target.position.y - 4, 6, target.size.y + 8), Color.WHITE)


func _draw_bar(rect: Rect2, fraction: float, color: Color) -> void:
	_overlay.draw_rect(rect, Color(0.5, 0.0, 0.0))
	_overlay.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(fraction, 0.0, 1.0), rect.size.y)), color)


func _draw_centered(text: String, center: Vector2, font_size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_overlay.draw_string(_font, Vector2(center.x - width / 2, center.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
