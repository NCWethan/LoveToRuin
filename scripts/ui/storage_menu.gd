class_name StorageMenu
extends CanvasLayer
## A storage box: move items between your bag and the box.
## Every box in the game opens the same storage, so you can put something in at
## Mt. Carmel and take it out at Hilltop Park.
## Left/Right to switch sides, Up/Down to pick, Z to move the item across, X to close.

signal _closed

const BAG := Rect2(30, 60, 280, 300)
const BOX := Rect2(330, 60, 280, 300)
const FONT_SIZE := 16
const ROW := 24

var _panel: Control
var _font: Font
var _open: bool = false
var _side: int = 0          # 0 = bag, 1 = box
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


func open() -> void:
	var was_busy := Game.busy
	Game.busy = true
	_open = true
	_side = 0
	_cursor = 0
	_message = ""
	_panel.visible = true
	await _closed
	_panel.visible = false
	await get_tree().process_frame
	Game.busy = was_busy


func _list(side: int) -> Array[Dictionary]:
	return Game.items if side == 0 else Game.box_items


func _process(_delta: float) -> void:
	if not _open:
		return
	var list := _list(_side)
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
		_side = 1 - _side
		_cursor = clampi(_cursor, 0, maxi(0, _list(_side).size() - 1))
		Game.play_sfx("move")
	elif Input.is_action_just_pressed("ui_up") and not list.is_empty():
		_cursor = wrapi(_cursor - 1, 0, list.size())
		Game.play_sfx("move")
	elif Input.is_action_just_pressed("ui_down") and not list.is_empty():
		_cursor = wrapi(_cursor + 1, 0, list.size())
		Game.play_sfx("move")
	elif Input.is_action_just_pressed("confirm") and not list.is_empty():
		_move_item()
	elif Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("menu"):
		Game.play_sfx("select")
		_open = false
		_closed.emit()
	_panel.queue_redraw()


## Moves the highlighted item to the other side, if there's room.
func _move_item() -> void:
	var from := _list(_side)
	var to := _list(1 - _side)
	var room := Game.MAX_BOX_ITEMS if _side == 0 else Game.MAX_ITEMS
	if to.size() >= room:
		_message = "* The %s is full." % ("box" if _side == 0 else "bag")
		Game.play_sfx("miss")
		return
	var item: Dictionary = from[_cursor]
	from.remove_at(_cursor)
	to.append(item)
	_message = "* You put the %s in the %s." % [item["name"], "box" if _side == 0 else "bag"]
	Game.play_sfx("item")
	_cursor = clampi(_cursor, 0, maxi(0, from.size() - 1))


func _draw_panel() -> void:
	_panel.draw_rect(Rect2(Vector2.ZERO, Vector2(640, 480)), Color(0, 0, 0, 0.55))
	for side in 2:
		var rect := BAG if side == 0 else BOX
		var list := _list(side)
		var room := Game.MAX_ITEMS if side == 0 else Game.MAX_BOX_ITEMS
		_panel.draw_rect(rect.grow(4), Color.YELLOW if side == _side else Color.WHITE)
		_panel.draw_rect(rect, Color.BLACK)
		var title := "BAG   (%d / %d)" % [list.size(), room] if side == 0 else "BOX   (%d / %d)" % [list.size(), room]
		_panel.draw_string(_font, rect.position + Vector2(14, 26), title, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.YELLOW)
		if list.is_empty():
			_panel.draw_string(_font, rect.position + Vector2(36, 58), "(empty)", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.GRAY)
		for i in list.size():
			var at := rect.position + Vector2(36, 58 + i * ROW)
			var selected := side == _side and i == _cursor
			_panel.draw_string(_font, at, list[i]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.YELLOW if selected else Color.WHITE)
			if selected:
				_heart(at + Vector2(-16, -6))
	if _message != "":
		_panel.draw_string(_font, Vector2(30, 400), _message, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color.WHITE)
	_panel.draw_string(_font, Vector2(30, 40), "STORAGE BOX", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	_panel.draw_string(_font, Vector2(30, 460), "Left/Right: switch side   Z: move item   X: close", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.55, 0.55, 0.55))


func _heart(center: Vector2) -> void:
	var red := Color(1, 0, 0)
	_panel.draw_rect(Rect2(center + Vector2(-6, -5), Vector2(5, 4)), red)
	_panel.draw_rect(Rect2(center + Vector2(1, -5), Vector2(5, 4)), red)
	_panel.draw_rect(Rect2(center + Vector2(-6, -2), Vector2(12, 3)), red)
	_panel.draw_rect(Rect2(center + Vector2(-4, 1), Vector2(8, 2)), red)
	_panel.draw_rect(Rect2(center + Vector2(-2, 3), Vector2(4, 2)), red)
