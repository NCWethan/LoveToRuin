extends Area
## KEEPSAKE memories: a piece of Relic's life, inside each fragment.
##
## Picking up the fragments, Elric sees what Relic saw, years ago, and plays it as
## Relic (Game.playing_relic): a short walk through one moment of that summer,
## tinted green. They play in order (by how many fragments Elric has), so on
## every path the story of Relic and Hop unfolds the same way. Start them with
## Game.play_keepsakes(); when one ends, Game.next_keepsake() plays the next, or
## brings Elric back.
##
##   1  A road into San Diego, at dawn. "Just passing through."
##   2  Sneaking into Westview's gym to sleep. The trophy case.
##   3  Westview Field, the first morning: a boy with two orders of curly fries,
##      and where the name "Relic" came from.
##   4  Mission Beach: the first time Relic sees the ocean. Hop teaches them to
##      bodysurf, badly.
##
## On the Genocide path, Relic narrates the end of each one, bitterly ("we").

const SCENE := "res://scenes/keepsake.tscn"
const T := Room.TILE
## The memory filter: everything a little green, like light through the fragment.
const TINT := Color(0.74, 0.98, 0.8)
## What Relic carries: a backpack that clinks.
const RELIC_GREEN := Color(0.45, 0.95, 0.55)

var memory: int = 1
var hop: Character
var _decor: Node2D
var _font: Font
var _card: Control
var _card_time: float = 0.0
var _flags := {}


func _ready() -> void:
	memory = Game.current_keepsake()
	if memory < 1:
		memory = 1
	setup_area(_spawn())
	_font = ThemeDB.fallback_font
	var tint := CanvasModulate.new()
	tint.color = TINT if memory != 1 else TINT * Color(1.0, 0.92, 0.85)
	add_child(tint)
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	Game.play_music("relic", 1.0)
	_place()
	_add_title_card()
	fit_camera_to_room()
	_start.call_deferred()


func _spawn() -> Vector2:
	match memory:
		2: return Vector2(2 * T + 10, 14 * T + 10)
		3: return Vector2(8 * T, 11 * T + 10)
		4: return Vector2(10 * T, 5 * T + 10)
	return Vector2(2 * T, 9 * T + 12)


# --- The maps ---------------------------------------------------------------------

func build_map() -> void:
	match Game.current_keepsake():
		2: _build_gym()
		3: _build_field()
		4: _build_ocean()
		_: _build_road()


## A road into the city at dawn: grass, a dirt shoulder, four lanes, nobody.
func _build_road() -> void:
	room.setup(44, 24, Room.GRASS)
	room.fill(0, 0, 44, 1, Room.TREE)
	room.fill(0, 9, 44, 1, Room.DIRT)
	room.fill(0, 10, 44, 5, Room.ROAD)
	room.fill(0, 12, 44, 1, Room.ROAD_LINE)
	room.fill(0, 15, 44, 1, Room.DIRT)
	room.fill(0, 23, 44, 1, Room.TREE)
	for x in [3, 6, 11, 14, 21, 26, 33, 37, 40]:
		room.set_tile(x, 2 + (x % 5), Room.TREE)
		room.set_tile(x + 1, 17 + (x % 5), Room.TREE)


## Westview's gym, at night, five years ago.
func _build_gym() -> void:
	room.setup(32, 24, Room.INTERIOR_WALL)
	room.fill(1, 2, 30, 4, Room.BLEACHERS)
	room.fill(1, 6, 30, 17, Room.GYM_FLOOR)
	room.fill(16, 6, 1, 17, Room.GYM_LINE)
	room.fill(0, 14, 1, 1, Room.DOOR)
	room.fill(5, 6, 3, 1, Room.PROP)     # the trophy case
	room.fill(22, 15, 5, 2, Room.PROP)   # the mats


## Mission Beach, one afternoon that summer.
func _build_ocean() -> void:
	room.setup(40, 24, Room.SAND)
	room.fill(0, 0, 40, 2, Room.BOARDWALK)
	room.fill(0, 15, 40, 9, Room.WATER)
	for spot in [Vector2i(4, 4), Vector2i(31, 6), Vector2i(36, 3)]:
		room.set_tile(spot.x, spot.y, Room.PALM)


## Westview Field, the first morning of the summer.
func _build_field() -> void:
	room.setup(34, 24, Room.FIELD)
	room.fill(0, 0, 34, 1, Room.TREE)
	room.fill(0, 23, 34, 1, Room.TREE)
	room.fill(0, 0, 1, 24, Room.TREE)
	room.fill(33, 0, 1, 24, Room.TREE)
	room.fill(4, 6, 7, 3, Room.PROP)     # the picnic shelter
	room.fill(20, 1, 1, 22, Room.FIELD_LINE)


func _draw_decor() -> void:
	match memory:
		1:
			# A green highway sign on two posts: SAN DIEGO 12.
			var at := Vector2(30 * T, 7 * T)
			_decor.draw_rect(Rect2(at + Vector2(6, 28), Vector2(3, 14)), Color8(150, 150, 156))
			_decor.draw_rect(Rect2(at + Vector2(62, 28), Vector2(3, 14)), Color8(150, 150, 156))
			_decor.draw_rect(Rect2(at, Vector2(72, 30)), Color8(30, 110, 60))
			_decor.draw_rect(Rect2(at, Vector2(72, 30)), Color8(235, 235, 235), false, 1.0)
			_decor.draw_string(_font, at + Vector2(8, 13), "SAN DIEGO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
			_decor.draw_string(_font, at + Vector2(52, 25), "12", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
			# The sun, just coming up at the end of the road.
			for ring in 5:
				_decor.draw_circle(Vector2(44 * T, 6 * T), 70.0 - ring * 12.0, Color(1.0, 0.75, 0.35, 0.12))
			if not _flags.get("cap", false):
				_decor.draw_circle(Vector2(17 * T + 10, 9 * T + 12), 3.0, Color8(200, 60, 50))
		2:
			# The trophy case: glass, three little trophies, a reflection.
			var case_rect := Rect2(5 * T, 6 * T - 26, 3 * T, 44)
			_decor.draw_rect(case_rect, Color8(90, 64, 40))
			_decor.draw_rect(case_rect.grow(-4), Color(0.75, 0.9, 1.0, 0.35))
			for k in 3:
				_decor.draw_rect(Rect2(case_rect.position + Vector2(10 + k * 16, 18), Vector2(6, 10)), Color8(220, 180, 60))
			# The wrestling mats.
			_decor.draw_rect(Rect2(22 * T, 15 * T, 5 * T, 2 * T), Color8(50, 70, 140))
			_decor.draw_rect(Rect2(22 * T, 15 * T, 5 * T, 2 * T), Color8(25, 35, 80), false, 2.0)
			# A backpack, if Relic has set it down.
			if _flags.get("bag_down", false):
				_decor.draw_rect(Rect2(21 * T + 6, 16 * T, 10, 12), Color8(70, 110, 70))
		4:
			# Two towels on the sand, and Relic's backpack on one of them.
			_decor.draw_rect(Rect2(14 * T, 7 * T, 2 * T, 3 * T), Color8(230, 90, 90))
			_decor.draw_rect(Rect2(17 * T, 7 * T, 2 * T, 3 * T), Color8(80, 140, 220))
			_decor.draw_rect(Rect2(14 * T + 12, 7 * T + 10, 10, 12), Color8(70, 110, 70))
		3:
			# The picnic shelter (years before anyone painted REVOLUTION on it).
			var roof := Rect2(4 * T - 6, 6 * T - 14, 7 * T + 12, 22)
			_decor.draw_rect(Rect2(4 * T, 6 * T, 7 * T, 3 * T), Color8(120, 95, 70))
			_decor.draw_rect(roof, Color8(150, 60, 50))
			_decor.draw_rect(roof, Color8(90, 35, 30), false, 2.0)
			_decor.draw_rect(Rect2(6 * T, 7 * T, 3 * T, T), Color8(140, 110, 80))
			# Relic's backpack, by the bench.
			_decor.draw_rect(Rect2(10 * T + 4, 9 * T + 4, 10, 12), Color8(70, 110, 70))


# --- People and things -------------------------------------------------------

func _place() -> void:
	match memory:
		1:
			world.add_child(Hotspot.create(Vector2(31 * T + 16, 9 * T + 8), _road_sign))
			world.add_child(Hotspot.create(Vector2(17 * T + 10, 9 * T + 12), _bottle_cap))
		2:
			world.add_child(Hotspot.create(Vector2(6 * T + 10, 7 * T + 4), _trophy_case))
			world.add_child(Hotspot.create(Vector2(24 * T + 10, 17 * T + 6), _mats))
		3:
			world.add_child(Hotspot.create(Vector2(10 * T + 10, 10 * T + 4), _backpack))


## "KEEPSAKE" and the number, in green, fading out at the start.
func _add_title_card() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_card = Control.new()
	_card.size = Vector2(640, 480)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_card)
	_card.draw.connect(func() -> void:
		var alpha := clampf(1.0 - (_card_time - 2.0) / 1.0, 0.0, 1.0)
		if alpha <= 0.0:
			return
		_card.draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.7 * alpha))
		var title := "KEEPSAKE"
		var size := 30
		var w := _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		_card.draw_string(_font, Vector2(320 - w / 2, 220), title, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(RELIC_GREEN, alpha))
		var num := "%d / 12" % memory
		var w2 := _font.get_string_size(num, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		_card.draw_string(_font, Vector2(320 - w2 / 2, 250), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.8 * alpha)))


func _process(delta: float) -> void:
	_card_time += delta
	if _card:
		_card.queue_redraw()


func _physics_process(_delta: float) -> void:
	if is_blocked():
		return
	# The end of the road.
	if memory == 1 and player.position.x > 39 * T and not _flags.get("ended", false):
		_flags["ended"] = true
		run_cutscene(_end_road)
	# Down to the water.
	if memory == 4 and hop != null and player.position.y > 13 * T and not _flags.get("ended", false):
		_flags["ended"] = true
		run_cutscene(_end_ocean)


# --- 1: The road ---------------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	match memory:
		1: await run_cutscene(_intro_road)
		2: await run_cutscene(_intro_gym)
		3: await run_cutscene(_intro_field)
		4: await run_cutscene(_intro_ocean)


func _intro_road() -> void:
	await get_tree().create_timer(2.6).timeout
	await Game.dialogue.say([
		"* (Dawn. A road into a city you've never seen.)",
		"* (Your backpack clinks when you walk.\n*  Bottle caps. Keys. A cracked compass.)",
		"* (None of it is yours. All of it is heavy.)",
	])
	Game.set_objective("Keep walking.")


func _road_sign() -> void:
	await Game.dialogue.say([
		"* (SAN DIEGO, 12 miles.)",
		{"who": "Relic", "tag": "???", "text": "...Never been to San Diego.", "mood": ""},
	])


func _bottle_cap() -> void:
	if _flags.get("cap", false):
		return
	_flags["cap"] = true
	_decor.queue_redraw()
	Game.play_sfx("item")
	await Game.dialogue.say([
		"* (A bottle cap, by the side of the road.)",
		"* (You put it in your backpack, with the others.)",
		"* (You don't know why you keep them.\n*  You just do.)",
	])


func _end_road() -> void:
	await Game.dialogue.say([
		"* (The sun comes up over the city.)",
		{"who": "Relic", "tag": "???", "text": "Just passing through.", "mood": "smug"},
		{"who": "Relic", "tag": "???", "text": "...Like always.", "mood": "sad"},
	])
	await _finish(["* We were only passing through.\n* We should have kept walking."])


# --- 2: The gym -----------------------------------------------------------------------

func _intro_gym() -> void:
	await get_tree().create_timer(2.6).timeout
	await Game.dialogue.say([
		"* (Westview High. The side door doesn't lock right.)",
		"* (It's warm in here, and nobody comes until 7.)",
	])
	Game.set_objective("Find somewhere to sleep.")


func _trophy_case() -> void:
	_flags["case"] = true
	await Game.dialogue.say([
		"* (A trophy case. Third place, regional spelling bee.)",
		"* (In the glass: a kid in a green hoodie.\n*  They look tired.)",
		"* (You look at them for a long time.)",
		{"who": "Relic", "tag": "???", "text": "...Where are you even going?", "mood": "sad"},
		"* (The kid in the glass doesn't know either.)",
	])


func _mats() -> void:
	if not _flags.get("case", false):
		await Game.dialogue.say(["* (The mats look soft.)", "* (But something in the glass case\n*  across the gym keeps catching the light.)"])
		return
	_flags["bag_down"] = true
	_decor.queue_redraw()
	await Game.dialogue.say([
		"* (You set the backpack down. It clinks.)",
		"* (You lie down on the mats.)",
		"* (For the first time in a long time,\n*  you don't want to leave in the morning.)",
		"* (You don't know why.)",
	])
	await _finish(["* Nobody looked for us there either.\n* Nobody ever looked for us anywhere."])


# --- 3: Curly fries ------------------------------------------------------------------

func _intro_field() -> void:
	await get_tree().create_timer(2.6).timeout
	await Game.dialogue.say([
		"* (Westview Field. You slept under the picnic shelter.)",
		"* (Somebody is coming across the grass.)",
	])
	hop = Cast.make("Hop")
	add_character(hop, Vector2(30 * T, 11 * T))
	await hop.walk_to(player.position + Vector2(28, 0), 70.0)
	hop.face(player.position - hop.position)
	player.facing = Vector2.RIGHT
	await Game.dialogue.say([
		"* (A boy in a fedora. He's holding two orders\n*  of curly fries.)",
		{"who": "Hop", "text": "You've been sleeping here for three days.\nI walk my run past here. I notice things.", "mood": "smug"},
		{"who": "Hop", "text": "Here. Jack in the Box. Curly fries.", "mood": "happy"},
		{"who": "Hop", "text": "You look like you've never had these.\nTragic.", "mood": "smug"},
		{"who": "Relic", "tag": "???", "choices": ["...Why are you giving me these?", "...Thanks."]},
	])
	await Game.dialogue.say([
		{"who": "Hop", "text": "Bought two by accident. Muscle memory.\nI used to buy for two.", "mood": "sad"},
		{"who": "Hop", "text": "...Never mind. Eat them before they get sad.", "mood": "happy"},
		"* (They're the best thing you've ever eaten.\n*  You don't tell him that.)",
		{"who": "Hop", "text": "I'm Hop. What's your name?"},
		"* (You don't say anything. You never do.)",
		{"who": "Hop", "text": "Mysterious. Cool. I respect it.", "mood": "smug"},
	])
	Game.set_objective("(The backpack is by the bench.)")


func _backpack() -> void:
	if hop == null:
		return
	if _flags.get("named", false):
		return
	_flags["named"] = true
	Game.play_sfx("item")
	await Game.dialogue.say([
		"* (You open the backpack. It clinks.)",
		"* (Hop leans over and looks inside.)",
		{"who": "Hop", "text": "...Bottle caps. Keys. A chess piece.\nA COMPASS? What is all this?", "mood": "shocked"},
		{"who": "Hop", "text": "You collect relics or something?\nLike a little museum on legs?", "mood": "smug"},
		{"who": "Hop", "text": "...Relic. Ha. That's what I'm calling you.\nUntil you tell me your real name.", "mood": "happy"},
		"* (You never do.)",
		"* (From then on, that's your name.)",
		{"who": "Hop", "text": "Same time tomorrow, Relic?", "mood": "happy"},
		{"who": "Relic", "text": "...Same time tomorrow.", "mood": "happy"},
	])
	await _finish(["* See how happy we were?\n* Then they let us burn."])


# --- 4: The ocean --------------------------------------------------------------------

func _intro_ocean() -> void:
	hop = Cast.make("Hop")
	add_character(hop, Vector2(20 * T, 12 * T))
	hop.face(Vector2.UP)
	await get_tree().create_timer(2.6).timeout
	await Game.dialogue.say([
		"* (Mission Beach. Hop said it was \"no big deal.\")",
		"* (You've never seen the ocean before.)",
		"* (It doesn't end. It just keeps going.)",
		{"who": "Hop", "text": "C'MON! The water's warm! ...Ish!", "mood": "happy"},
	])
	Game.set_objective("(Go down to the water.)")


func _end_ocean() -> void:
	hop.face(player.position - hop.position)
	await Game.dialogue.say([
		{"who": "Relic", "text": "...Everything's so BIG here.", "mood": "shocked"},
		{"who": "Hop", "text": "Wait till you're IN it.\nI'll teach you to bodysurf. I'm basically a pro.", "mood": "smug"},
		"* (He is not a pro.)",
		"* (You get knocked over by every single wave.\n*  You come up coughing, with sand in your hood.)",
		"* (You've never laughed this hard.\n*  You didn't know you could.)",
		{"who": "Hop", "text": "You're a natural! At DROWNING!", "mood": "happy"},
		{"who": "Relic", "text": "...Again.", "mood": "happy"},
		"* (For one whole afternoon, the backpack\n*  sits on the towel, and you forget about it.)",
	])
	await _finish(["* We laughed. We forgot what we were carrying.\n* For one day."])


# --- The end of a memory ---------------------------------------------------------

## The memory fades. On the Genocide path, Relic has the last word (in green, as
## "we"). Then the next memory, or back to now.
func _finish(bitter: Array) -> void:
	if Game.flags.get("route", "") in ["genocide", "with_hop"]:
		await get_tree().create_timer(0.6).timeout
		var lines: Array = []
		for line in bitter:
			lines.append({"who": "Relic", "tag": "", "face": false, "text": line})
		await Game.dialogue.say(lines)
	await Game.fade_out(1.6)
	await get_tree().create_timer(0.6).timeout
	await Game.next_keepsake()
