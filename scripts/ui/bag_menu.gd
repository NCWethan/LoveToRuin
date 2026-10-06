class_name BagMenu
extends CanvasLayer
## Your bag, opened with B while walking around. Under the items: TEAM (once you've
## met Hop), the ENCYCLOPEDIA (every enemy you've met: picture, stats, attacks, what
## they can do to you) and the settings.
## TEAM shows each member of the team: their picture, stats, and what they're
## holding and wearing. Pick something they're wearing to take it off. At the
## Corps' base, "Change partner" picks who comes along with Elric.
## The left side shows the party's HP and your money; the right side lists your items.
## Pick an item, then:
##   USE    eat it (pick who, if there's more than one of you)
##   CHECK  read what it is and how much it heals
##   DROP   throw it away
## X goes back (or closes the bag).

enum Step { LIST, ACTIONS, TARGET, MESSAGE, TEAM, PARTNER, BOOK }

## The partner list: this many names per column.
const TEAM_ROWS := 6
## The team screen: one card per member.
const CARD_SIZE := Vector2(280, 290)

const ACTIONS := ["USE", "CHECK", "DROP"]
const STATS := Rect2(30, 40, 200, 200)
const LIST := Rect2(250, 40, 360, 280)
const MESSAGE := Rect2(30, 340, 580, 110)
const FONT_SIZE := 16
const ROW := 26

signal _closed

var _panel: Control
var _font: Font
var _open: bool = false
var _opened_frame: int = -1
var _step: Step = Step.LIST
var _cursor: int = 0
var _action: int = 0
var _target: int = 0
var _message: String = ""
var _team_cursor: int = 0
## On the team screen: which member (0 or 1), and which row (the three slots, then
## "Change partner").
var _team_member: int = 0
var _team_slot: int = 0
## Where a message goes back to when it's closed.
var _message_return: Step = Step.LIST
## The Encyclopedia: which entry is open, and the enemies themselves (made when it opens).
var _book_cursor: int = 0
var _book_enemies: Array = []
var _effects_script: GDScript
## Set when the team changes, so the area can swap who's following Elric.
var _team_changed: bool = false


func _ready() -> void:
	layer = 60
	_font = ThemeDB.fallback_font
	_panel = Control.new()
	_panel.size = Vector2(640, 480)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)
	_panel.draw.connect(_draw_panel)


## Opens the bag and waits until it's closed.
func open() -> void:
	var was_busy := Game.busy
	Game.busy = true
	_opened_frame = Engine.get_process_frames()
	_open = true
	_step = Step.LIST
	_cursor = 0
	_message = ""
	_team_changed = false
	_panel.visible = true
	Game.play_sfx("select")
	await _closed
	_panel.visible = false
	await get_tree().process_frame
	Game.busy = was_busy
	# A new partner: the area brings them in (see corps_base.gd).
	if _team_changed and get_tree().current_scene.has_method("refresh_partner"):
		get_tree().current_scene.refresh_partner()


func _process(_delta: float) -> void:
	# Ignore the key press that opened this menu (it would otherwise buy / move / pick
	# something immediately).
	if not _open or Engine.get_process_frames() == _opened_frame:
		return
	var up := Input.is_action_just_pressed("ui_up")
	var down := Input.is_action_just_pressed("ui_down")
	var left := Input.is_action_just_pressed("ui_left")
	var right := Input.is_action_just_pressed("ui_right")
	var confirm := Input.is_action_just_pressed("confirm")
	var back := Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("menu")

	# The settings screen is open on top of the bag: leave the keys to it.
	if Game.settings_menu.is_open():
		return

	match _step:
		Step.LIST:
			# Under the items: "Team" (once you've met Hop), "Encyclopedia", "Settings".
			var rows := Game.items.size() + (3 if _team_shown() else 2)
			if up or down:
				_cursor = wrapi(_cursor + (1 if down else -1), 0, rows)
				Game.play_sfx("move")
			elif confirm:
				Game.play_sfx("select")
				if _on_settings():
					await Game.settings_menu.open()
				elif _on_team():
					_open_team()
				elif _on_book():
					_open_book()
				else:
					_step = Step.ACTIONS
					_action = 0
			elif back:
				_close()
		Step.ACTIONS:
			if left or right:
				_action = wrapi(_action + (1 if right else -1), 0, ACTIONS.size())
				Game.play_sfx("move")
			elif confirm:
				Game.play_sfx("select")
				_do_action()
			elif back:
				_step = Step.LIST
		Step.TARGET:
			# The names are side by side: left and right (A and D) to pick.
			if left or right:
				_target = wrapi(_target + (1 if right else -1), 0, Game.party.size())
				Game.play_sfx("move")
			elif confirm:
				_use_on(Game.party[_target])
			elif back:
				_step = Step.ACTIONS
		Step.TEAM:
			var rows := Game.SLOTS.size() + (1 if _can_change_partner() else 0)
			if left or right:
				_team_member = wrapi(_team_member + (1 if right else -1), 0, Game.party.size())
				Game.play_sfx("move")
			elif up or down:
				_team_slot = wrapi(_team_slot + (1 if down else -1), 0, rows)
				Game.play_sfx("move")
			elif confirm:
				_team_choose()
			elif back:
				_step = Step.LIST
		Step.PARTNER:
			var choices := Game.team_choices()
			if up or down:
				_team_cursor = wrapi(_team_cursor + (1 if down else -1), 0, choices.size())
				Game.play_sfx("move")
			elif left or right:
				_team_cursor = clampi(_team_cursor + (TEAM_ROWS if right else -TEAM_ROWS), 0, choices.size() - 1)
				Game.play_sfx("move")
			elif confirm:
				var id: String = choices[_team_cursor]
				if id != Game.partner():
					Game.set_partner(id)
					_team_changed = true
				Game.play_sfx("select")
				_show("* (%s will come with you.)" % DialogueBox.display_name(id), Step.TEAM)
			elif back:
				_step = Step.TEAM
		Step.BOOK:
			if up or down:
				_book_cursor = wrapi(_book_cursor + (1 if down else -1), 0, _book_enemies.size())
				Game.play_sfx("move")
			elif back or confirm:
				_step = Step.LIST
		Step.MESSAGE:
			if confirm or back:
				_message = ""
				_step = _message_return
				if _step == Step.LIST:
					_cursor = clampi(_cursor, 0, maxi(0, Game.items.size() - 1))

	_panel.queue_redraw()


## The "Team" row only shows up once Hop has joined.
func _team_shown() -> bool:
	return Game.flags.get("met_hop", false)


## True when the cursor is on the "Settings" row (the last one).
func _on_settings() -> bool:
	return _cursor >= Game.items.size() + (2 if _team_shown() else 1)


## True when the cursor is on the "Encyclopedia" row (between Team and Settings).
func _on_book() -> bool:
	return _cursor == Game.items.size() + (1 if _team_shown() else 0)


func _effects() -> GDScript:
	if _effects_script == null:
		_effects_script = load("res://scripts/effects.gd")
	return _effects_script


## Opens the Encyclopedia. The enemies are made fresh from their battles (for their
## pictures, stats, attacks and ACTs).
func _open_book() -> void:
	_book_enemies.clear()
	for entry in _effects().ENCYCLOPEDIA:
		_book_enemies.append([entry[1], _effects().enemy_for(entry)])
	_book_cursor = 0
	_step = Step.BOOK


## True when the cursor is on the "Team" row (right below the items).
func _on_team() -> bool:
	return _team_shown() and _cursor == Game.items.size()


## The partner can only be changed at the Corps' base.
func _can_change_partner() -> bool:
	return Game.flags.get("base_arrived", false) and get_tree().current_scene.has_method("refresh_partner")


## ENTER on the team screen: take off whatever's in that slot, or change partner.
func _team_choose() -> void:
	if _team_slot >= Game.SLOTS.size():
		Game.play_sfx("select")
		_step = Step.PARTNER
		_team_cursor = maxi(0, Game.team_choices().find(Game.partner()))
		return
	var member: PartyMember = Game.party[_team_member]
	var slot: String = Game.SLOTS[_team_slot]
	var item: Dictionary = Game.worn_by(member.name).get(slot, {})
	if item.is_empty():
		Game.play_sfx("miss")
		return
	if not Game.unequip(member.name, slot):
		Game.play_sfx("miss")
		_show("* (Your bag is full. Make some room first.)", Step.TEAM)
		return
	Game.play_sfx("item")
	var who := "You" if member.name == "Elric" else member.name
	_show("* %s took off the %s.\n* (It went back in the bag.)" % [who, item["name"]], Step.TEAM)


## The team screen.
func _open_team() -> void:
	_step = Step.TEAM
	_team_member = 0
	_team_slot = 0


func _do_action() -> void:
	var item: Dictionary = Game.items[_cursor]
	match ACTIONS[_action]:
		"USE":
			if Game.party.size() > 1:
				_step = Step.TARGET
				_target = 0
			else:
				_use_on(Game.party[0])
		"CHECK":
			_show(Items.describe(item))
		"DROP":
			Game.items.remove_at(_cursor)
			_show("* (You dropped the %s.)" % item["name"])


## "USE" reads "EQUIP" for accessories.
func _action_name(index: int) -> String:
	if ACTIONS[index] == "USE" and not Game.items.is_empty() and _cursor < Game.items.size() and Items.is_accessory(Game.items[_cursor]):
		return "EQUIP"
	return ACTIONS[index]


## Puts an accessory on someone (whatever they wore in that slot goes back in the bag).
func _equip_on(member: PartyMember, item: Dictionary) -> void:
	var old := Game.equip(member.name, item)
	Game.play_sfx("item")
	var who := "You" if member.name == "Elric" else member.name
	var text := "* %s equipped the %s.\n* (%s)" % [who, item["name"], Items.stats_text(item)]
	if not old.is_empty():
		text += "\n* (The %s went back in the bag.)" % old["name"]
	_show(text)


func _use_on(member: PartyMember) -> void:
	var item: Dictionary = Game.items[_cursor]
	if Items.is_accessory(item):
		_equip_on(member, item)
		return
	Game.items.remove_at(_cursor)
	var heal := Items.food_heal(item, member.name)
	var healed := mini(heal, member.max_hp - member.hp)
	member.hp += healed
	Game.play_sfx("heal")
	var who := "You" if member.name == "Elric" else member.name
	var text := "* %s ate the %s." % [who, item["name"]]
	if healed >= heal:
		text += "\n* %s recovered %d HP!" % [member.name, healed]
	elif healed > 0:
		text += "\n* %s's HP was maxed out." % member.name
	else:
		text += "\n* (%s was already at full HP.)" % member.name
	_show(text)


func _show(text: String, return_to: Step = Step.LIST) -> void:
	_message = text
	_message_return = return_to
	_step = Step.MESSAGE


func _close() -> void:
	_open = false
	_closed.emit()


# --- Drawing ----------------------------------------------------------------

func _box(rect: Rect2) -> void:
	_panel.draw_rect(rect.grow(4), Color.WHITE)
	_panel.draw_rect(rect, Color.BLACK)


func _text(text: String, at: Vector2, color: Color = Color.WHITE, size: int = FONT_SIZE) -> void:
	_panel.draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_panel() -> void:
	_panel.draw_rect(Rect2(Vector2.ZERO, Vector2(640, 480)), Color(0, 0, 0, 0.55))

	# The Encyclopedia covers the whole bag (nothing else is drawn under it).
	if _step == Step.BOOK:
		_draw_book()
		_text("W/S: choose   X: close", Vector2(30, 474), Color(0.55, 0.55, 0.55), 12)
		return

	# The party and your money.
	_box(STATS)
	var left := STATS.position.x + 14
	var y := STATS.position.y + 24
	for member in Game.party:
		_text(member.name.to_upper(), Vector2(left, y), DialogueBox.SPEAKERS.get(member.id, {}).get("color", member.color))
		_text("HP %d/%d" % [member.hp, member.max_hp], Vector2(left + 76, y), Color.WHITE, 14)
		_text("ATK %d   DEF %d" % [member.attack, member.defense], Vector2(left, y + 18), Color(0.75, 0.75, 0.75), 13)
		y += 42
	# Levels, and how far to the next one.
	_text("LV %d" % Game.lv(), Vector2(left, y), Color.WHITE, 15)
	_text(_progress(Game.exp_points, Game.next_lv_exp(), "EXP"), Vector2(left + 52, y), Color(1, 0.6, 0.6), 13)
	_text("BOND LV %d" % Game.bond_level(), Vector2(left, y + 20), Color(0.7, 0.85, 1.0), 15)
	_text(_progress(Game.bond, Game.next_bond(), ""), Vector2(left + 100, y + 20), Color(0.7, 0.85, 1.0), 13)
	_text("$%d" % Game.money, Vector2(left, y + 42), Color.YELLOW, 15)
	_text("Fragments: %d / 12" % int(Game.flags.get("fragments", 0)), Vector2(left + 52, y + 42), Color(1, 0.5, 0.55), 13)

	# What you're doing right now.
	if Game.objective() != "":
		var goal := Rect2(STATS.position.x, STATS.end.y + 16, STATS.size.x, 68)
		_box(goal)
		_text("OBJECTIVE", goal.position + Vector2(14, 20), Color.YELLOW, 12)
		_panel.draw_multiline_string(_font, goal.position + Vector2(14, 38), Game.objective(), HORIZONTAL_ALIGNMENT_LEFT, goal.size.x - 24, 13)

	# The team screen (and the partner list) cover the whole bag.
	if _step == Step.TEAM or _step == Step.PARTNER or (_step == Step.MESSAGE and _message_return == Step.TEAM):
		_draw_team_cards()
		if _step == Step.PARTNER:
			_draw_partner_list()
		if _step == Step.MESSAGE:
			_box(MESSAGE)
			var message_lines := _message.split("\n")
			for i in message_lines.size():
				_text(message_lines[i], MESSAGE.position + Vector2(16, 28 + i * 22))
		_text("A/D: member   W/S: slot   ENTER: take off   X: back" if _step == Step.TEAM else "ENTER: choose   X: back", Vector2(30, 474), Color(0.55, 0.55, 0.55), 12)
		return
	# Your items.
	_box(LIST)
	_text("BAG   (%d / %d)" % [Game.items.size(), Game.MAX_ITEMS], Vector2(LIST.position.x + 14, LIST.position.y + 26), Color.YELLOW)
	if Game.items.is_empty():
		_text("(Your bag is empty.)", Vector2(LIST.position.x + 40, LIST.position.y + 60), Color.GRAY)
	for i in Game.items.size():
		var item: Dictionary = Game.items[i]
		var row_y := LIST.position.y + 58 + i * ROW
		var selected := i == _cursor and _step != Step.MESSAGE
		_text(item["name"], Vector2(LIST.position.x + 40, row_y), Color.YELLOW if selected else Color.WHITE)
		if selected and _step == Step.LIST:
			_heart(Vector2(LIST.position.x + 22, row_y - 6))

	# "Settings", along the bottom of the list (where USE / CHECK / DROP go when
	# an item is picked).
	if _step != Step.ACTIONS:
		var team_at := Vector2(LIST.position.x + 32, LIST.end.y - 16)
		var on_team := _on_team() and _step == Step.LIST
		if _team_shown():
			_text("Team", team_at, Color.YELLOW if on_team else Color(0.75, 0.75, 0.75))
		if on_team:
			_heart(team_at + Vector2(-18, -6))
		var book_at := Vector2(LIST.position.x + (122 if _team_shown() else 32), LIST.end.y - 16)
		var on_book := _on_book() and _step == Step.LIST
		_text("Encyclopedia", book_at, Color.YELLOW if on_book else Color(0.75, 0.75, 0.75))
		if on_book:
			_heart(book_at + Vector2(-18, -6))
		var settings_at := Vector2(LIST.position.x + (262 if _team_shown() else 172), LIST.end.y - 16)
		var on_it := _on_settings() and _step == Step.LIST
		_panel.draw_line(Vector2(LIST.position.x + 14, LIST.end.y - 38), Vector2(LIST.end.x - 14, LIST.end.y - 38), Color(0.3, 0.3, 0.3), 1.0)
		_text("Settings", settings_at, Color.YELLOW if on_it else Color(0.75, 0.75, 0.75))
		if on_it:
			_heart(settings_at + Vector2(-18, -6))

	# USE / CHECK / DROP, or who to give the item to.
	if _step == Step.ACTIONS:
		for i in ACTIONS.size():
			var at := Vector2(LIST.position.x + 50 + i * 105, LIST.end.y - 16)
			_text(_action_name(i), at, Color.YELLOW if i == _action else Color.WHITE)
			if i == _action:
				_heart(at + Vector2(-16, -6))
	elif _step == Step.TARGET:
		_box(MESSAGE)
		var gear := Items.is_accessory(Game.items[_cursor])
		_text("* Who wears it?" if gear else "* Give it to who?", MESSAGE.position + Vector2(16, 28))
		for i in Game.party.size():
			var member: PartyMember = Game.party[i]
			var at := MESSAGE.position + Vector2(60 + i * 220, 64)
			var label := "%s  (%d/%d)" % [member.name, member.hp, member.max_hp]
			if gear:
				# Show what they're wearing in that slot now.
				var slot: String = Game.items[_cursor]["slot"]
				var current: Dictionary = Game.worn_by(member.name).get(slot, {})
				label = "%s  (now: %s)" % [member.name, current.get("name", "nothing")]
			_text(label, at, Color.YELLOW if i == _target else Color.WHITE)
			if i == _target:
				_heart(at + Vector2(-16, -6))

	if _step == Step.MESSAGE:
		_box(MESSAGE)
		var lines := _message.split("\n")
		for i in lines.size():
			_text(lines[i], MESSAGE.position + Vector2(16, 28 + i * 22))

	var hint := "ENTER: choose   X: back   B: close"
	_text(hint, Vector2(30, 474), Color(0.55, 0.55, 0.55), 12)


## The Encyclopedia: a list of every enemy down the left ("???" for ones you
## haven't met), and the open page on the right: the enemy's picture, stats,
## description, attacks, what it can do to you, and its ACTs. Enemies you haven't
## met just say "Haven't seen yet."
func _draw_book() -> void:
	var index_box := Rect2(30, 40, 170, 410)
	var page := Rect2(214, 40, 396, 410)
	_box(index_box)
	_box(page)
	_text("ENCYCLOPEDIA", index_box.position + Vector2(12, 24), Color.YELLOW, 15)
	for i in _book_enemies.size():
		var enemy_name: String = _book_enemies[i][0]
		var known: bool = _effects().seen(enemy_name)
		var at := index_box.position + Vector2(30, 54 + i * 26)
		_text(enemy_name if known else "???", at, Color.YELLOW if i == _book_cursor else (Color.WHITE if known else Color(0.45, 0.45, 0.45)), 14)
		if i == _book_cursor:
			_heart(at + Vector2(-16, -5))
	var enemy_name: String = _book_enemies[_book_cursor][0]
	var enemy: Enemy = _book_enemies[_book_cursor][1]
	if not _effects().seen(enemy_name) or enemy == null:
		var note := "Haven't seen yet."
		var width := _font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		_text(note, page.get_center() - Vector2(width / 2, 0), Color(0.55, 0.55, 0.55), 18)
		return
	# The picture.
	var frame := Rect2(page.position + Vector2(14, 14), Vector2(120, 130))
	_panel.draw_rect(frame, Color(1, 1, 1, 0.06))
	_panel.draw_rect(frame, Color(0.4, 0.4, 0.4), false, 1.0)
	if enemy.sprite:
		var picture_size := enemy.sprite.get_size()
		var scale := minf(minf((frame.size.x - 10) / picture_size.x, (frame.size.y - 10) / picture_size.y), 4.0)
		var size := picture_size * scale
		_panel.draw_texture_rect(enemy.sprite, Rect2(frame.get_center() - size / 2, size), false)
	# Name and stats.
	var right := page.position + Vector2(148, 34)
	_text(enemy.name.to_upper(), right, Color.YELLOW, 18)
	_text("HP %d   ATK %d   DEF %d" % [enemy.max_hp, enemy.attack, enemy.defense], right + Vector2(0, 24), Color.WHITE, 13)
	# The description: the CHECK text, without its first (stats) line.
	var check_lines := enemy.check_text.split("\n")
	var description := ""
	for k in range(1, check_lines.size()):
		description += check_lines[k].trim_prefix("* ") + " "
	_panel.draw_multiline_string(_font, right + Vector2(0, 46), description.strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, page.end.x - right.x - 12, 12, -1, Color(0.8, 0.8, 0.8))
	# Attacks, what it can do to you, and how to talk it down.
	var names: Array = []
	for pattern in enemy.patterns:
		names.append(_effects().ATTACK_NAMES.get(pattern, pattern))
	var y := page.position.y + 172
	_text("ATTACKS", Vector2(page.position.x + 14, y), Color(1, 0.6, 0.6), 13)
	_panel.draw_multiline_string(_font, Vector2(page.position.x + 14, y + 18), ", ".join(names), HORIZONTAL_ALIGNMENT_LEFT, page.size.x - 28, 13, -1, Color.WHITE)
	y += 64
	_text("CAN CAUSE", Vector2(page.position.x + 14, y), Color(1, 0.6, 0.6), 13)
	var debuff: Array = _effects().ENEMY_DEBUFFS.get(enemy.name, [])
	if debuff.is_empty():
		_text("Nothing.", Vector2(page.position.x + 14, y + 18), Color.WHITE, 13)
	else:
		var effect: Dictionary = _effects().EFFECTS[debuff[0]]
		_text("%s  (%d%% of hits, %d turns)" % [debuff[0], roundi(float(debuff[1]) * 100.0), debuff[2]], Vector2(page.position.x + 14, y + 18), effect["color"], 13)
		_panel.draw_multiline_string(_font, Vector2(page.position.x + 14, y + 36), effect["what"], HORIZONTAL_ALIGNMENT_LEFT, page.size.x - 28, 12, -1, Color(0.8, 0.8, 0.8))
	y += 82
	_text("ACTS", Vector2(page.position.x + 14, y), Color(1, 0.6, 0.6), 13)
	var acts := ", ".join(enemy.act_names())
	if enemy.spare_refusal != "":
		acts += "   (Can't be spared.)"
	_panel.draw_multiline_string(_font, Vector2(page.position.x + 14, y + 18), acts, HORIZONTAL_ALIGNMENT_LEFT, page.size.x - 28, 13, -1, Color.WHITE)


## The team screen: a card for each member with their picture, HP and stats, and
## what's in each slot (Weapon, Torso, Shoes). At the base, "Change partner" below.
func _draw_team_cards() -> void:
	for m in Game.party.size():
		var member: PartyMember = Game.party[m]
		var card := Rect2(Vector2(30 + m * 300, 40), CARD_SIZE)
		var picked := m == _team_member and _step == Step.TEAM
		_box(card)
		if picked:
			_panel.draw_rect(card.grow(4), Color.YELLOW, false, 2.0)
		var color: Color = DialogueBox.SPEAKERS.get(member.id, {}).get("color", member.color)
		_text(member.name.to_upper(), card.position + Vector2(14, 26), color, 18)
		# Their picture, big.
		var picture_path := "res://art/sprites/%s.png" % Game.sprite_base(member.id)
		var picture: Texture2D = load(picture_path) if ResourceLoader.exists(picture_path) else member.sprite
		if picture:
			var size := picture.get_size() * 3.0
			_panel.draw_rect(Rect2(card.position + Vector2(14, 40), Vector2(110, 120)), Color(1, 1, 1, 0.06))
			_panel.draw_texture_rect(picture, Rect2(card.position + Vector2(69 - size.x / 2, 158 - size.y), size), false)
		var stats_at := card.position + Vector2(140, 62)
		_text("HP  %d / %d" % [member.hp, member.max_hp], stats_at, Color.WHITE, 15)
		_text("ATK %d" % member.attack, stats_at + Vector2(0, 26), Color(1, 0.7, 0.6), 15)
		_text("DEF %d" % member.defense, stats_at + Vector2(0, 50), Color(0.6, 0.8, 1.0), 15)
		# What they're holding and wearing.
		for s in Game.SLOTS.size():
			var slot: String = Game.SLOTS[s]
			var item: Dictionary = Game.worn_by(member.name).get(slot, {})
			var row_at := card.position + Vector2(36, 188 + s * 26)
			var here := picked and _team_slot == s
			_text(Game.SLOT_NAMES[slot], row_at, Color(0.6, 0.6, 0.6), 13)
			var label: String = item.get("name", "(nothing)")
			if not item.is_empty():
				label += "  " + Items.stats_text(item).get_slice(": ", 1)
			if slot == "card" and not item.is_empty():
				# Cards show their picture, and just the name (their power is in the bag).
				label = item["name"]
				ShopArt.draw(_panel, item["name"], row_at + Vector2(200, -14), 1.7)
			_text(label, row_at + Vector2(64, 0), Color.YELLOW if here else (Color.WHITE if not item.is_empty() else Color(0.45, 0.45, 0.45)), 14)
			if here:
				_heart(row_at + Vector2(-18, -5))
	if _can_change_partner():
		var at := Vector2(56, 360)
		var here := _step == Step.TEAM and _team_slot == Game.SLOTS.size()
		_box(Rect2(30, 340, 580, 34))
		_text("Change partner  (now: %s)" % DialogueBox.display_name(Game.partner()), at + Vector2(0, 4), Color.YELLOW if here else Color.WHITE)
		if here:
			_heart(at + Vector2(-16, -2))


## The partner list: everyone who could come along, the current partner marked.
func _draw_partner_list() -> void:
	_box(LIST)
	_text("TEAM  -  who comes with you?", Vector2(LIST.position.x + 14, LIST.position.y + 26), Color.YELLOW)
	var choices := Game.team_choices()
	var helpers: Dictionary = load("res://scripts/helpers.gd").HELPERS
	for i in choices.size():
		var id: String = choices[i]
		var at := Vector2(LIST.position.x + 40 + (i / TEAM_ROWS) * 170, LIST.position.y + 62 + (i % TEAM_ROWS) * 32)
		var color: Color = helpers.get(id, {}).get("color", Color(0.85, 0.85, 0.85))
		var label := DialogueBox.display_name(id) + ("  *" if id == Game.partner() else "")
		_text(label, at, Color.YELLOW if i == _team_cursor else color)
		if i == _team_cursor:
			_heart(at + Vector2(-16, -6))
	_text("* = with you now.   Elric always comes.", Vector2(LIST.position.x + 14, LIST.end.y - 14), Color(0.55, 0.55, 0.55), 12)


func _heart(center: Vector2) -> void:
	var red := Color(1, 0, 0)
	_panel.draw_rect(Rect2(center + Vector2(-6, -5), Vector2(5, 4)), red)
	_panel.draw_rect(Rect2(center + Vector2(1, -5), Vector2(5, 4)), red)
	_panel.draw_rect(Rect2(center + Vector2(-6, -2), Vector2(12, 3)), red)
	_panel.draw_rect(Rect2(center + Vector2(-4, 1), Vector2(8, 2)), red)
	_panel.draw_rect(Rect2(center + Vector2(-2, 3), Vector2(4, 2)), red)


## "24 / 30" (how much you have / what the next level needs), or "MAX".
func _progress(have: int, needed: int, label: String) -> String:
	var text := ("%s %d / %d" % [label, have, needed]) if needed >= 0 else ("%s %d (MAX)" % [label, have])
	return text.strip_edges()
