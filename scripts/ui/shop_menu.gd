class_name ShopMenu
extends CanvasLayer
## A shop screen: a list of things to buy, your money, and how full your bag is.
##
## Usage:
##   await Game.shop.open("Vons", "* (Fluorescent lights. A cart with one bad wheel.)", [
##       {"name": "Trail Mix", "heal": 15, "price": 8},
##   ])
## Up/Down to pick, Enter to buy, X to leave.

signal _closed

const PANEL := Rect2(40, 40, 560, 400)
const FONT_SIZE := 16
const ROW_HEIGHT := 26

var _panel: Control
var _font: Font
var _open: bool = false
var _opened_frame: int = -1
var _title: String = ""
var _greeting: String = ""
var _stock: Array = []
var _cursor: int = 0
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


## Opens the shop and waits until the player leaves.
func open(title: String, greeting: String, stock: Array) -> void:
	var was_busy := Game.busy
	Game.busy = true
	_title = title
	_greeting = greeting
	_stock = stock
	_cursor = 0
	_message = ""
	_opened_frame = Engine.get_process_frames()
	_open = true
	_panel.visible = true
	await _closed
	_panel.visible = false
	await get_tree().process_frame
	Game.busy = was_busy


func _process(_delta: float) -> void:
	# Ignore the key press that opened this menu (it would otherwise buy / move / pick
	# something immediately).
	if not _open or Engine.get_process_frames() == _opened_frame:
		return
	# The extra row at the bottom is "Leave".
	var rows := _stock.size() + 1
	if Input.is_action_just_pressed("ui_up"):
		_cursor = wrapi(_cursor - 1, 0, rows)
		Game.play_sfx("move")
	elif Input.is_action_just_pressed("ui_down"):
		_cursor = wrapi(_cursor + 1, 0, rows)
		Game.play_sfx("move")
	elif Input.is_action_just_pressed("confirm"):
		if _cursor == _stock.size():
			_leave()
		else:
			_buy(_stock[_cursor])
	elif Input.is_action_just_pressed("cancel"):
		_leave()
	_panel.queue_redraw()


func _buy(item: Dictionary) -> void:
	if Game.money < int(item["price"]):
		_message = "* You don't have enough money."
		Game.play_sfx("miss")
	elif Game.items.size() >= Game.MAX_ITEMS:
		_message = "* Your bag is full. (%d items max)" % Game.MAX_ITEMS
		Game.play_sfx("miss")
	else:
		Game.money -= int(item["price"])
		Game.items.append({"name": item["name"], "heal": int(item["heal"])})
		_message = "* You bought the %s." % item["name"]
		Game.play_sfx("item")


func _leave() -> void:
	Game.play_sfx("select")
	_open = false
	_closed.emit()


func _draw_panel() -> void:
	_panel.draw_rect(Rect2(Vector2.ZERO, Vector2(640, 480)), Color(0, 0, 0, 0.6))
	_panel.draw_rect(PANEL.grow(4), Color.WHITE)
	_panel.draw_rect(PANEL, Color.BLACK)

	var left := PANEL.position.x + 24
	var y := PANEL.position.y + 34
	_panel.draw_string(_font, Vector2(left, y), _title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.YELLOW)
	var wallet := "$%d     Items: %d / %d" % [Game.money, Game.items.size(), Game.MAX_ITEMS]
	var wallet_width := _font.get_string_size(wallet, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	_panel.draw_string(_font, Vector2(PANEL.end.x - wallet_width - 24, y), wallet, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)

	y += 34
	for line in _greeting.split("\n"):
		_panel.draw_string(_font, Vector2(left, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0.8, 0.8, 0.8))
		y += 22

	y += 16
	for i in _stock.size() + 1:
		var row_y := y + i * ROW_HEIGHT
		var label := "Leave"
		var detail := ""
		if i < _stock.size():
			var item: Dictionary = _stock[i]
			label = item["name"]
			detail = "$%d     +%d HP" % [item["price"], item["heal"]]
		var color := Color.YELLOW if i == _cursor else Color.WHITE
		_panel.draw_string(_font, Vector2(left + 30, row_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
		_panel.draw_string(_font, Vector2(left + 260, row_y), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
		if i == _cursor:
			_draw_heart(Vector2(left + 12, row_y - 6))

	if _message != "":
		_panel.draw_string(_font, Vector2(left, PANEL.end.y - 46), _message, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
	_panel.draw_string(_font, Vector2(left, PANEL.end.y - 16), "ENTER: buy     X: leave", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.55, 0.55))


func _draw_heart(center: Vector2) -> void:
	var red := Color(1, 0, 0)
	_panel.draw_rect(Rect2(center + Vector2(-6, -5), Vector2(5, 4)), red)
	_panel.draw_rect(Rect2(center + Vector2(1, -5), Vector2(5, 4)), red)
	_panel.draw_rect(Rect2(center + Vector2(-6, -2), Vector2(12, 3)), red)
	_panel.draw_rect(Rect2(center + Vector2(-4, 1), Vector2(8, 2)), red)
	_panel.draw_rect(Rect2(center + Vector2(-2, 3), Vector2(4, 2)), red)
