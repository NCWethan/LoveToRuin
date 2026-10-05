class_name BagMenu
extends CanvasLayer
## Your bag, opened with B while walking around. The last row opens the settings.
## The left side shows the party's HP and your money; the right side lists your items.
## Pick an item, then:
##   USE    eat it (pick who, if there's more than one of you)
##   CHECK  read what it is and how much it heals
##   DROP   throw it away
## X goes back (or closes the bag).

enum Step { LIST, ACTIONS, TARGET, MESSAGE }

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
	_panel.visible = true
	Game.play_sfx("select")
	await _closed
	_panel.visible = false
	await get_tree().process_frame
	Game.busy = was_busy


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
			# The last row is always "Settings", under the items.
			var rows := Game.items.size() + 1
			if up or down:
				_cursor = wrapi(_cursor + (1 if down else -1), 0, rows)
				Game.play_sfx("move")
			elif confirm:
				Game.play_sfx("select")
				if _on_settings():
					await Game.settings_menu.open()
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
			if up or down:
				_target = wrapi(_target + (1 if down else -1), 0, Game.party.size())
				Game.play_sfx("move")
			elif confirm:
				_use_on(Game.party[_target])
			elif back:
				_step = Step.ACTIONS
		Step.MESSAGE:
			if confirm or back:
				_message = ""
				_step = Step.LIST
				_cursor = clampi(_cursor, 0, maxi(0, Game.items.size() - 1))

	_panel.queue_redraw()


## True when the cursor is on the "Settings" row (below the items).
func _on_settings() -> bool:
	return _cursor >= Game.items.size()


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
	var healed := mini(int(item["heal"]), member.max_hp - member.hp)
	member.hp += healed
	Game.play_sfx("heal")
	var who := "You" if member.name == "Elric" else member.name
	var text := "* %s ate the %s." % [who, item["name"]]
	if healed >= int(item["heal"]):
		text += "\n* %s recovered %d HP!" % [member.name, healed]
	elif healed > 0:
		text += "\n* %s's HP was maxed out." % member.name
	else:
		text += "\n* (%s was already at full HP.)" % member.name
	_show(text)


func _show(text: String) -> void:
	_message = text
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

	# The party and your money.
	_box(STATS)
	var left := STATS.position.x + 14
	var y := STATS.position.y + 24
	for member in Game.party:
		_text(member.name.to_upper(), Vector2(left, y), DialogueBox.SPEAKERS.get(member.name, {}).get("color", Color.WHITE))
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
		var settings_at := Vector2(LIST.position.x + 40, LIST.end.y - 16)
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
