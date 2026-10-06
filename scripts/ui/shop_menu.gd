class_name ShopMenu
extends CanvasLayer
## A shop, Undertale style: going in fades to a whole different screen, with the
## shopkeeper behind their counter at the top, what they're saying in the box at
## the bottom left, and the menu (Buy, Sell, Talk, Exit) at the bottom right.
##
## Usage:
##   await Game.shop.open(Shops.vons())
## (see shops.gd for everything a shop can have). Up/Down to pick, ENTER to choose,
## X to go back.
##
## On the Genocide route the shopkeepers have gone (Shops.gone()). The shop is
## empty, there's a note on the counter, and Elric can take whatever they want:
## the menu becomes Steal, Register, Read, Exit.

signal _closed

const TOP := Rect2(0, 0, 640, 240)
const LEFT := Rect2(12, 252, 404, 216)
const RIGHT := Rect2(428, 252, 200, 216)
const FONT_SIZE := 16
const SMALL := 14
const ROW := 20
const TYPE_SPEED := 40.0
## The shopkeeper is drawn this many times bigger, standing behind the counter.
const KEEPER_SCALE := 8.0
const COUNTER_Y := 196.0

enum Mode { MAIN, BUY, CONFIRM, SELL, SELL_CONFIRM, TALK, SAYING, LEAVING }

var _panel: Control
var _font: Font
var _open: bool = false
var _opened_frame: int = -1
var _clock: float = 0.0
var _shop: Dictionary = {}
var _empty: bool = false
var _mode: Mode = Mode.MAIN
var _cursor: int = 0
var _menu_cursor: int = 0
var _yes: bool = true

## The text in the left box, typed out a letter at a time, and the mood on the
## shopkeeper's face while they say it.
var _text: String = ""
var _typed: float = 0.0
var _mood: String = ""
var _last_beep: int = 0
## Lines still to come (when talking), and what to do after the last one.
var _queue: Array = []
var _after: Mode = Mode.MAIN
## What the shopkeeper says in the small right box (in the Buy list).
var _reply: String = ""
var _reply_typed: float = 0.0
## The line typed in the left box is the note (drawn on paper instead).
var _reading: bool = false


func _ready() -> void:
	layer = 60
	_font = ThemeDB.fallback_font
	_panel = Control.new()
	_panel.size = Vector2(640, 480)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)
	_panel.draw.connect(_draw_shop)


## Goes into the shop and waits until the player leaves.
func open(shop: Dictionary) -> void:
	var was_busy := Game.busy
	Game.busy = true
	var song_before := Game.current_music()
	await Game.fade_out(0.3)
	_shop = shop
	_empty = Shops.gone()
	_mode = Mode.MAIN
	_menu_cursor = 0
	_reading = false
	_queue = []
	if _empty:
		_say("* (Nobody's here.)\n* (There's a note on the counter.)")
	else:
		_say(_line(shop["greeting"]))
	_opened_frame = Engine.get_process_frames()
	_open = true
	_panel.visible = true
	# An empty shop plays its song slowed way down and wrong (see make_music.gd).
	Game.play_music(str(shop["music"]) + ("_gone" if _empty else ""), 0.3)
	await Game.fade_in(0.3)
	await _closed
	await Game.fade_out(0.3)
	_panel.visible = false
	Game.play_music(song_before, 0.3)
	await Game.fade_in(0.3)
	Game.busy = was_busy


## A line as {"text", "mood"} (it can be written as just a String).
func _line(line) -> Dictionary:
	if line is Dictionary:
		return line
	return {"text": str(line), "mood": ""}


func _say(line) -> void:
	var said := _line(line)
	_text = said["text"]
	_mood = said.get("mood", "")
	_typed = 0.0
	_last_beep = 0


func _say_lines(lines: Array, then: Mode) -> void:
	_queue = lines.duplicate()
	_after = then
	_mode = Mode.SAYING
	_say(_queue.pop_front())


func _reply_with(text: String) -> void:
	_reply = text
	_reply_typed = 0.0


func _typing() -> bool:
	return _typed < _text.length()


# --- Input -------------------------------------------------------------------

func _menu() -> Array:
	if _empty:
		return ["Steal", "Register", "Read", "Exit"]
	return ["Buy", "Sell", "Talk", "Exit"]


func _process(delta: float) -> void:
	if not _open:
		return
	_clock += delta
	_typed += delta * TYPE_SPEED * Game.text_speed()
	_reply_typed += delta * TYPE_SPEED * Game.text_speed()
	var shown := mini(int(_typed), _text.length())
	# A beep every other letter: the shopkeeper's voice, or plain text for
	# narration (and nothing for the note).
	if shown > _last_beep and shown % 2 == 0 and _text[shown - 1] != " " and not _reading:
		if _empty or _text.begins_with("* ("):
			Game.play_sfx("text")
		else:
			Game.play_sfx("voice", DialogueBox.SPEAKERS.get(_shop["keeper"], {}).get("pitch", 1.0))
	_last_beep = shown
	_panel.queue_redraw()
	# Ignore the key press that opened the shop.
	if Engine.get_process_frames() == _opened_frame:
		return
	var up := Input.is_action_just_pressed("ui_up")
	var down := Input.is_action_just_pressed("ui_down")
	var confirm := Input.is_action_just_pressed("confirm")
	var cancel := Input.is_action_just_pressed("cancel")
	match _mode:
		Mode.MAIN:
			if up or down:
				_menu_cursor = wrapi(_menu_cursor + (1 if down else -1), 0, 4)
				Game.play_sfx("move")
			elif confirm:
				Game.play_sfx("select")
				_choose(_menu()[_menu_cursor])
		Mode.BUY, Mode.SELL, Mode.TALK:
			var rows := _rows().size()
			if up or down:
				_cursor = wrapi(_cursor + (1 if down else -1), 0, rows)
				Game.play_sfx("move")
			elif cancel or (confirm and _cursor == rows - 1):
				Game.play_sfx("select")
				_back_to_main()
			elif confirm:
				Game.play_sfx("select")
				_pick_row()
		Mode.CONFIRM, Mode.SELL_CONFIRM:
			if up or down:
				_yes = not _yes
				Game.play_sfx("move")
			elif cancel or (confirm and not _yes):
				Game.play_sfx("select")
				_mode = Mode.BUY if _mode == Mode.CONFIRM else Mode.SELL
				_reply_with("")
			elif confirm:
				if _mode == Mode.CONFIRM:
					_buy(_list()[_cursor])
				else:
					_sell(_cursor)
		Mode.SAYING, Mode.LEAVING:
			if confirm or cancel:
				if _typing():
					_typed = _text.length()
				elif not _queue.is_empty():
					_say(_queue.pop_front())
				elif _mode == Mode.LEAVING:
					_open = false
					_closed.emit()
				else:
					_reading = false
					if _after == Mode.MAIN:
						_back_to_main()
					else:
						_mode = _after
						_text = ""


func _choose(option: String) -> void:
	_cursor = 0
	_reply_with("")
	match option:
		"Buy", "Steal":
			_mode = Mode.BUY
			_text = ""
			_reply_with("" if _empty else _shop["buy_prompt"])
		"Sell":
			if _shop.has("buys"):
				if Game.items.is_empty():
					_say_lines([{"text": "* You don't have anything to sell.\n* ...I'll still be here.", "mood": "sad"}], Mode.MAIN)
				else:
					_mode = Mode.SELL
					_say(_shop["sell_intro"])
					_typed = _text.length()
			else:
				# They don't buy things. What they say about it changes each time.
				var lines: Array = _shop["sell"]
				var tries := int(Game.flags.get("sell_tries_" + _shop["sprite"], 0))
				Game.flags["sell_tries_" + _shop["sprite"]] = tries + 1
				_say_lines([lines[mini(tries, lines.size() - 1)]], Mode.MAIN)
		"Talk":
			_mode = Mode.TALK
			_text = ""
		"Register":
			var key: String = "robbed_" + _shop["sprite"]
			if Game.flags.get(key, false):
				_say_lines(["* (The register is empty.)\n* (You already made sure of that.)"], Mode.MAIN)
			else:
				var cash: int = Shops.REGISTERS.get(_shop["sprite"], 10)
				Game.flags[key] = true
				Game.money += cash
				Game.play_sfx("item")
				_say_lines(["* (You open the register.)\n* (You took $%d.)" % cash, "* (Nobody stops you.)"], Mode.MAIN)
		"Read":
			_reading = true
			_say_lines([Shops.NOTES.get(_shop["sprite"], "...")], Mode.MAIN)
		"Exit":
			_mode = Mode.LEAVING
			_queue = []
			if _empty:
				_say("* (You leave.)\n* (The door doesn't chime.)")
			else:
				_say(_line(_shop["exit"]))


func _back_to_main() -> void:
	_mode = Mode.MAIN
	_reply_with("")
	if _empty:
		_say("* (It's quiet.)")
	else:
		_say(_line(_shop["back"]))


## The things in the open list (left box): stock, bag items or topics.
func _list() -> Array:
	match _mode:
		Mode.BUY, Mode.CONFIRM:
			return _shop["stock"]
		Mode.SELL, Mode.SELL_CONFIRM:
			return Game.items
		Mode.TALK:
			return _shop["talk"]
	return []


## The rows of the open list, as text, with "Exit" at the end.
func _rows() -> Array:
	var rows: Array = []
	for thing in _list():
		match _mode:
			Mode.BUY, Mode.CONFIRM:
				if ShopMenu.sold_out(thing):
					rows.append("SOLD OUT")
				elif _empty:
					rows.append(thing["name"])
				else:
					rows.append("$%d - %s" % [thing["price"], thing["name"]])
			Mode.SELL, Mode.SELL_CONFIRM:
				rows.append(thing["name"])
			Mode.TALK:
				rows.append(thing["topic"])
	rows.append("Exit")
	return rows


func _pick_row() -> void:
	match _mode:
		Mode.BUY:
			var item: Dictionary = _list()[_cursor]
			if ShopMenu.sold_out(item):
				Game.play_sfx("miss")
				_reply_with("" if _empty else _shop["sold_out"])
			elif _empty:
				_buy(item)
			else:
				_mode = Mode.CONFIRM
				_yes = true
				_reply_with("Buy it for\n$%d?" % item["price"])
				_reply_typed = 99.0
		Mode.SELL:
			_mode = Mode.SELL_CONFIRM
			_yes = true
			_reply_with("Sell the\n%s for $%d?" % [Game.items[_cursor]["name"], _shop["buys"]])
			_reply_typed = 99.0
		Mode.TALK:
			_say_lines(_shop["talk"][_cursor]["lines"], Mode.TALK)


## Gear (weapons and things to wear) is one of a kind: once bought, it's SOLD OUT.
static func sold_out(item: Dictionary) -> bool:
	return Items.is_accessory(item) and Game.flags.get("bought_" + str(item["name"]), false)


func _buy(item: Dictionary) -> void:
	_mode = Mode.BUY
	if Game.items.size() >= Game.MAX_ITEMS:
		Game.play_sfx("miss")
		_reply_with("* (Your bag is\n  full.)" if _empty else _shop["full"])
		return
	if not _empty and Game.money < int(item["price"]):
		Game.play_sfx("miss")
		_reply_with(_shop["poor"])
		return
	if not _empty:
		Game.money -= int(item["price"])
	var bought: Dictionary = item.duplicate()
	bought.erase("price")
	Game.items.append(bought)
	if Items.is_accessory(item):
		Game.flags["bought_" + str(item["name"])] = true
	Game.play_sfx("item")
	if _empty:
		_reply_with("* (You took the\n  %s.)" % item["name"])
	else:
		var special: Dictionary = _shop.get("bought_special", {})
		var lines: Array = _shop["bought"]
		_reply_with(special.get(item["name"], lines[randi() % lines.size()]))


func _sell(index: int) -> void:
	Game.items.remove_at(index)
	Game.money += int(_shop["buys"])
	Game.play_sfx("item")
	_reply_with(_shop["sold"])
	if Game.items.is_empty():
		_back_to_main()
		return
	_mode = Mode.SELL
	_cursor = mini(_cursor, Game.items.size())


# --- Drawing -------------------------------------------------------------------

func _draw_shop() -> void:
	_panel.draw_rect(Rect2(0, 0, 640, 480), Color.BLACK)
	_draw_room()
	if not _empty:
		_draw_keeper()
	_draw_counter()
	if _empty:
		_draw_note_on_counter()
	if _mode in [Mode.BUY, Mode.CONFIRM] and _cursor < _list().size():
		_draw_item_info(_list()[_cursor])
	_draw_box(LEFT)
	_draw_box(RIGHT)
	_draw_left()
	_draw_right()


func _draw_box(rect: Rect2) -> void:
	_panel.draw_rect(rect.grow(4), Color.WHITE)
	_panel.draw_rect(rect, Color.BLACK)


func _text_at(at: Vector2, text: String, color: Color = Color.WHITE, size: int = FONT_SIZE, line_height: float = 22.0) -> void:
	var lines := text.split("\n")
	for i in lines.size():
		_panel.draw_string(_font, at + Vector2(0, i * line_height), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_left() -> void:
	var at := LEFT.position + Vector2(18, 30)
	if _mode in [Mode.BUY, Mode.CONFIRM, Mode.SELL, Mode.SELL_CONFIRM, Mode.TALK]:
		var rows := _rows()
		var start := 0
		if _mode in [Mode.SELL, Mode.SELL_CONFIRM]:
			# The "I buy anything" line stays at the top while you pick.
			_text_at(at, _text, Color(0.75, 0.75, 0.75), SMALL, 18.0)
			start = 2
		for i in rows.size():
			var y := at.y + (start + i) * ROW - (8 if start > 0 else 0)
			var color := Color.WHITE
			if rows[i] == "SOLD OUT":
				color = Color(0.5, 0.5, 0.5)
			if i == _cursor:
				color = Color.YELLOW if rows[i] != "SOLD OUT" else Color(1.0, 0.55, 0.55)
				_draw_heart(Vector2(at.x + 6, y - 6))
			_panel.draw_string(_font, Vector2(at.x + 24, y), rows[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
		return
	var shown := _text.substr(0, mini(int(_typed), _text.length()))
	if _reading:
		_draw_note(shown)
		return
	_text_at(at, shown)


func _draw_right() -> void:
	var at := RIGHT.position + Vector2(18, 34)
	if _mode == Mode.MAIN:
		var options := _menu()
		for i in options.size():
			var y := at.y + i * 32
			var color := Color.YELLOW if i == _menu_cursor else Color.WHITE
			_panel.draw_string(_font, Vector2(at.x + 24, y), options[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE + 2, color)
			if i == _menu_cursor:
				_draw_heart(Vector2(at.x + 6, y - 6))
	elif _mode in [Mode.CONFIRM, Mode.SELL_CONFIRM]:
		_text_at(at, _reply, Color.WHITE, SMALL, 18.0)
		for i in 2:
			var y := at.y + 64 + i * 26
			var chosen := (i == 0) == _yes
			_panel.draw_string(_font, Vector2(at.x + 24, y), ["Yes", "No"][i], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.YELLOW if chosen else Color.WHITE)
			if chosen:
				_draw_heart(Vector2(at.x + 6, y - 6))
	elif _mode in [Mode.BUY, Mode.SELL]:
		var shown := _reply.substr(0, mini(int(_reply_typed), _reply.length()))
		_text_at(at, shown, Color.WHITE, SMALL, 18.0)
	# Money and how full the bag is, always along the bottom.
	var wallet := "$%d" % Game.money
	_panel.draw_string(_font, Vector2(at.x, RIGHT.end.y - 14), wallet, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
	var bag := "%d/%d" % [Game.items.size(), Game.MAX_ITEMS]
	var w := _font.get_string_size(bag, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	_panel.draw_string(_font, Vector2(RIGHT.end.x - 16 - w, RIGHT.end.y - 14), bag, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)


## A little panel over the corner of the room: what the highlighted thing does.
func _draw_item_info(item: Dictionary) -> void:
	var box := Rect2(428, 96, 200, 132)
	_draw_box(box)
	var stats := Items.stats_text(item) if Items.is_accessory(item) else "Heals %d HP" % item["heal"]
	var about: String = Items.DESCRIPTIONS.get(item["name"], "")
	var y := box.position.y + 22
	for line in _wrap(stats, 14, box.size.x - 24):
		_panel.draw_string(_font, Vector2(box.position.x + 12, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.YELLOW)
		y += 18
	y += 4
	for line in _wrap(about.replace("\n* ", " ").replace("\n", " "), 13, box.size.x - 24):
		if y > box.end.y - 6:
			break
		_panel.draw_string(_font, Vector2(box.position.x + 12, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.8, 0.8))
		y += 17


## Splits text into lines that fit in `width` at this font size.
func _wrap(text: String, size: int, width: float) -> Array:
	var lines: Array = []
	var line := ""
	for word in text.split(" "):
		var next := word if line == "" else line + " " + word
		if line != "" and _font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			lines.append(line)
			line = word
		else:
			line = next
	if line != "":
		lines.append(line)
	return lines


## The note, written on a scrap of paper.
func _draw_note(shown: String) -> void:
	var paper := LEFT.grow(-10)
	_panel.draw_rect(paper, Color8(236, 230, 210))
	for i in 9:
		_panel.draw_line(Vector2(paper.position.x + 6, paper.position.y + 26 + i * 20), Vector2(paper.end.x - 6, paper.position.y + 26 + i * 20), Color8(190, 200, 225), 1.0)
	_text_at(paper.position + Vector2(16, 22), shown, Color8(40, 30, 30), FONT_SIZE, 20.0)


func _draw_keeper() -> void:
	var mood := _mood if _mode in [Mode.SAYING, Mode.MAIN, Mode.LEAVING] else ""
	var texture := Cast.portrait(_shop["sprite"], mood)
	if texture == null:
		return
	var size := texture.get_size() * KEEPER_SCALE
	# Breathing, and a little bounce while they talk.
	var bob := sin(_clock * 2.2) * 2.0
	if _typing():
		bob -= absf(sin(_clock * 18.0)) * 3.0
	var at := Vector2(320 - size.x / 2, COUNTER_Y - 19 * KEEPER_SCALE + bob)
	# Only down to the counter.
	var rows := (TOP.end.y - at.y) / KEEPER_SCALE
	_panel.draw_texture_rect_region(texture, Rect2(at, Vector2(size.x, rows * KEEPER_SCALE)), Rect2(0, 0, texture.get_width(), rows))


func _draw_heart(center: Vector2) -> void:
	var red := Color(1, 0, 0)
	_panel.draw_rect(Rect2(center + Vector2(-6, -5), Vector2(5, 4)), red)
	_panel.draw_rect(Rect2(center + Vector2(1, -5), Vector2(5, 4)), red)
	_panel.draw_rect(Rect2(center + Vector2(-6, -2), Vector2(12, 3)), red)
	_panel.draw_rect(Rect2(center + Vector2(-4, 1), Vector2(8, 2)), red)
	_panel.draw_rect(Rect2(center + Vector2(-2, 3), Vector2(4, 2)), red)


# --- The rooms -----------------------------------------------------------------
# Drawn in chunky blocks, like the rest of the game's pixel art. When the shop is
# empty, the lights are half off.

func _r(x: float, y: float, w: float, h: float, color: Color) -> void:
	if _empty:
		color = color.darkened(0.55)
	_panel.draw_rect(Rect2(x, y, w, h), color)


func _draw_room() -> void:
	match _shop.get("scene", ""):
		"vons": _draw_vons()
		"jack": _draw_jack()
		"knotty": _draw_knotty()
		"cards": _draw_cards()


func _draw_counter() -> void:
	var colors := {
		"vons": [Color8(200, 200, 205), Color8(150, 150, 158)],
		"jack": [Color8(205, 40, 45), Color8(150, 25, 30)],
		"knotty": [Color8(150, 95, 55), Color8(110, 68, 38)],
		"cards": [Color8(170, 200, 215), Color8(90, 70, 60)],
	}
	var pair: Array = colors.get(_shop.get("scene", ""), [Color.GRAY, Color.DIM_GRAY])
	_r(0, COUNTER_Y, 640, 8, pair[0].lightened(0.2))
	_r(0, COUNTER_Y + 8, 640, TOP.end.y - COUNTER_Y - 8, pair[1])
	match _shop.get("scene", ""):
		"vons":
			# The register, and groceries riding the little conveyor belt.
			_r(410, COUNTER_Y - 34, 70, 34, Color8(70, 70, 78))
			_r(418, COUNTER_Y - 30, 54, 14, Color8(120, 220, 140))
			_r(120, COUNTER_Y - 6, 180, 6, Color8(40, 40, 44))
			if not _empty:
				_icon("Trail Mix", Vector2(150, COUNTER_Y - 6), 2.0)
				_icon("Soda", Vector2(200, COUNTER_Y - 6), 2.0)
				_icon("Deli Sandwich", Vector2(250, COUNTER_Y - 6), 2.0)
		"jack":
			# A tray of curly fries, and the register.
			_r(150, COUNTER_Y - 6, 80, 6, Color8(150, 25, 30))
			if not _empty:
				_icon("Curly Fries", Vector2(190, COUNTER_Y - 6), 3.0)
			_r(430, COUNTER_Y - 30, 60, 30, Color8(60, 60, 66))
		"knotty":
			# A plate with a salmon burger on it, and a little bell.
			_r(140, COUNTER_Y - 6, 90, 6, Color8(235, 235, 240))
			if not _empty:
				_icon("Salmon Burger", Vector2(185, COUNTER_Y - 6), 3.0)
			_r(392, COUNTER_Y - 14, 20, 14, Color8(210, 180, 60))
			_r(400, COUNTER_Y - 20, 4, 6, Color8(210, 180, 60))
		"cards":
			# The glass display case: every card, and the glove in the middle.
			var case_items := ["Lucky Card", "Heart Card", "Clover Card", "Divergent Glove", "Snack Card", "Clock Card", "Candy Dice"]
			for k in case_items.size():
				var cell := Rect2(40 + k * 82, COUNTER_Y + 12, 50, 26)
				_r(cell.position.x, cell.position.y, cell.size.x, cell.size.y, Color8(120, 150, 165))
				_icon(case_items[k], Vector2(cell.get_center().x, cell.end.y - 2), 2.0)
			_r(0, COUNTER_Y + 8, 640, 3, Color8(220, 240, 250))


## Draws one of ShopArt's pictures standing on `foot` (the middle of its bottom
## edge), dimmed when the lights are off.
func _icon(icon: String, foot: Vector2, scale: float) -> void:
	var size := ShopArt.size_of(icon) * scale
	ShopArt.draw(_panel, icon, foot - Vector2(size.x / 2, size.y), scale, _empty)


func _label(text: String, center: Vector2, size: int, color: Color) -> void:
	if _empty:
		color = color.darkened(0.6)
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_panel.draw_string(_font, center - Vector2(w / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## A shelf of the same thing, side by side. In an empty shop, there are gaps.
func _shelf(icon: String, x0: float, y: float, width: float, scale: float) -> void:
	_r(x0, y, width, 6, Color8(150, 150, 158) if _shop["scene"] == "vons" else Color8(110, 80, 60))
	var step := ShopArt.size_of(icon).x * scale + 6
	var count := int(width / step)
	for k in count:
		if _empty and k % 3 != 0:
			continue
		_icon(icon, Vector2(x0 + (width - count * step) / 2 + step * (k + 0.5), y), scale)


func _draw_note_on_counter() -> void:
	_panel.draw_set_transform(Vector2(320, COUNTER_Y - 4), -0.08)
	_panel.draw_rect(Rect2(-34, -22, 68, 26), Color8(236, 230, 210))
	for i in 3:
		_panel.draw_rect(Rect2(-26, -16 + i * 7, 40 - i * 8, 2), Color8(60, 50, 50))
	_panel.draw_set_transform(Vector2.ZERO)


func _draw_vons() -> void:
	# Cream walls, bright lights, and shelves of what Vons sells: snacks on the
	# left, the seasonal aisle on the right.
	_r(0, 0, 640, 240, Color8(238, 230, 210))
	for k in 4:
		_r(40 + k * 160, 6, 100, 6, Color8(255, 255, 240))
	_r(0, 18, 640, 26, Color8(210, 40, 40))
	_label("VONS", Vector2(320, 39), 22, Color.WHITE)
	_label("SNACKS", Vector2(100, 64), 12, Color8(30, 90, 160))
	_label("SEASONAL", Vector2(540, 64), 12, Color8(30, 90, 160))
	_shelf("Trail Mix", 16, 104, 168, 2.0)
	_shelf("Soda", 16, 140, 168, 2.0)
	_shelf("Granola Bar", 16, 172, 168, 2.0)
	_shelf("Rain Poncho", 456, 104, 168, 2.0)
	_shelf("Flip-Flops", 456, 140, 168, 2.0)
	_shelf("Nail File", 456, 172, 168, 2.0)
	# Aisle signs.
	_r(214, 56, 40, 18, Color8(30, 90, 160))
	_r(386, 56, 40, 18, Color8(30, 90, 160))
	_label("9", Vector2(234, 70), 14, Color.WHITE)
	_label("4", Vector2(406, 70), 14, Color.WHITE)
	_r(0, 180, 640, 16, Color8(200, 200, 190))


func _draw_jack() -> void:
	var late: bool = Game.flags.get("mall_time", "day") in ["evening", "night"]
	_r(0, 0, 640, 240, Color8(250, 245, 238))
	_r(0, 150, 640, 46, Color8(205, 40, 45))
	# Two glowing menu boards, one on each side of Dex, with a picture of
	# everything on the menu.
	_menu_board(Rect2(8, 12, 212, 112), [["Two Tacos", "TACOS", 6], ["Egg Rolls", "EGG ROLLS", 8], ["Curly Fries", "CURLY FRIES", 10]])
	_menu_board(Rect2(420, 12, 212, 112), [["Burger", "BURGERS", 16], ["Shake", "SHAKES", 99], ["", "", 0]])
	# The shake machine's broken. Always.
	_panel.draw_set_transform(Vector2(530, 40), -0.12)
	_panel.draw_rect(Rect2(-44, -9, 88, 18), Color8(250, 250, 250) if not _empty else Color8(110, 110, 110))
	_panel.draw_string(_font, Vector2(-38, 5), "OUT OF ORDER", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(200, 30, 30))
	_panel.draw_set_transform(Vector2.ZERO)
	# The drive-thru window: day or night outside.
	_r(560, 132, 64, 56, Color8(30, 30, 70) if late else Color8(150, 200, 240))
	_r(590, 132, 4, 56, Color8(220, 220, 225))


## A menu board: a panel for each [picture, name, price] ("" leaves it blank).
func _menu_board(board: Rect2, items: Array) -> void:
	_r(board.position.x, board.position.y, board.size.x, board.size.y, Color8(30, 30, 36))
	var width := board.size.x / items.size()
	for k in items.size():
		if items[k][0] == "":
			continue
		var center := board.position.x + width * (k + 0.5)
		_r(center - width / 2 + 4, board.position.y + 4, width - 8, 62, Color8(240, 190, 60) if items[k][0] != "Shake" else Color8(200, 110, 160))
		_icon(items[k][0], Vector2(center, board.position.y + 60), 3.0)
		_label(items[k][1], Vector2(center, board.position.y + 84), 10, Color.WHITE)
		_label("$%d" % items[k][2], Vector2(center, board.position.y + 100), 11, Color(1.0, 0.85, 0.3))


func _draw_knotty() -> void:
	# Wooden planks with knots, barrels, warm hanging lamps, and today's menu.
	for k in 20:
		_r(0, k * 12, 640, 12, Color8(150, 100, 60) if k % 2 == 0 else Color8(138, 90, 54))
	for k in 14:
		_r((k * 97) % 620 + 6, (k * 53) % 170 + 4, 8, 6, Color8(100, 62, 36))
	for x in [70, 170]:
		_panel.draw_line(Vector2(x, 0), Vector2(x, 26), Color(0.1, 0.1, 0.1), 2.0)
		_r(x - 16, 26, 32, 12, Color8(40, 40, 44))
		if not _empty:
			_panel.draw_circle(Vector2(x, 42), 22, Color(1.0, 0.8, 0.4, 0.25))
		_r(x - 8, 38, 16, 6, Color8(255, 220, 140))
	for spot in [Vector2(20, 120), Vector2(76, 120), Vector2(132, 120), Vector2(48, 62), Vector2(104, 62)]:
		_r(spot.x, spot.y, 48, 58, Color8(120, 74, 40))
		_r(spot.x, spot.y + 10, 48, 5, Color8(70, 70, 76))
		_r(spot.x, spot.y + 42, 48, 5, Color8(70, 70, 76))
	# The chalkboard menu, with a drawing of each dish.
	var board := Rect2(440, 12, 190, 172)
	_r(board.position.x - 6, board.position.y - 6, board.size.x + 12, board.size.y + 12, Color8(100, 62, 36))
	_r(board.position.x, board.position.y, board.size.x, board.size.y, Color8(40, 52, 44))
	_label("TODAY'S MENU", Vector2(board.get_center().x, board.position.y + 20), 13, Color(1, 1, 1, 0.9))
	var dishes := [["Clam Chowder", "CHOWDER", 14], ["Fish & Chips", "FISH & CHIPS", 18], ["Salmon Burger", "SALMON BURGER", 22]]
	for k in dishes.size():
		var y := board.position.y + 66 + k * 48
		_icon(dishes[k][0], Vector2(board.position.x + 32, y), 2.5)
		_panel.draw_string(_font, Vector2(board.position.x + 64, y - 14), dishes[k][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.3 if _empty else 0.9))
		_panel.draw_string(_font, Vector2(board.position.x + 64, y), "$%d" % dishes[k][2], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.85, 0.4, 0.3 if _empty else 0.9))


func _draw_cards() -> void:
	# Shelves of board games on the left; on the right, the card wall, candy dice
	# and gum. Dusty, with the old sign hanging crooked.
	_r(0, 0, 640, 240, Color8(70, 92, 80))
	var boxes := [Color8(200, 60, 60), Color8(60, 120, 200), Color8(230, 200, 70), Color8(120, 70, 160), Color8(60, 170, 110), Color8(230, 130, 50)]
	for shelf in 4:
		var y := 24 + shelf * 40
		_r(12, y + 30, 160, 5, Color8(110, 80, 60))
		for k in 5:
			var h := 20 + (k * 5 + shelf * 3) % 10
			_r(16 + k * 31, y + 30 - h, 27, h, boxes[(k + shelf) % boxes.size()])
	var cards := ["Lucky Card", "Heart Card", "Clover Card", "Snack Card", "Clock Card"]
	_r(470, 54, 160, 5, Color8(110, 80, 60))
	_r(470, 94, 160, 5, Color8(110, 80, 60))
	for k in cards.size():
		_icon(cards[k], Vector2(486 + k * 32, 54), 2.0)
		_icon(cards[(k + 2) % cards.size()], Vector2(486 + k * 32, 94), 2.0)
	_shelf("Candy Dice", 468, 134, 160, 2.0)
	_shelf("Card Pack Gum", 468, 174, 160, 2.0)
	_label("CARDS", Vector2(550, 18), 12, Color(1, 1, 1, 0.8))
	# Dust.
	for k in 30:
		_r((k * 131) % 640, (k * 71) % 190, 2, 2, Color8(200, 200, 190))
	# The sign, hanging crooked from one string.
	_panel.draw_line(Vector2(270, 0), Vector2(262, 22), Color(0.2, 0.2, 0.2), 1.0)
	_panel.draw_set_transform(Vector2(320, 22), 0.12)
	_panel.draw_rect(Rect2(-70, 0, 140, 22), Color8(240, 235, 220) if not _empty else Color8(110, 108, 100))
	_panel.draw_string(_font, Vector2(-62, 16), "BACK IN 5 MINUTES", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(40, 40, 40))
	_panel.draw_set_transform(Vector2.ZERO)
