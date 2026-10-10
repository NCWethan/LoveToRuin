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
##   5  Balboa Park, the museum steps at night: Hop tells Relic about the voice
##      inside him. "Everybody's got something in them they didn't ask for."
##   6  Old Town, the plaza bench: an old man crying over his wife. Relic takes
##      his grief into a pigeon feather, and he laughs at the pigeons ("That one
##      looks like a Gerald"). Hop finds out what the backpack is really full of.
##      The feather goes between the slats of the bench: "I'll come back for it."
##   7  Downtown, the empty ballpark after midnight: Hop wakes up screaming. Relic
##      puts his nightmares into the only thing left in their pocket, a Jack in
##      the Box curly-fry token, and wears it on a cord from then on.
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
		5: return Vector2(4 * T, 14 * T + 10)
		6: return Vector2(3 * T, 12 * T + 10)
		7: return Vector2(15 * T, 14 * T + 10)
	return Vector2(2 * T, 9 * T + 12)


# --- The maps ---------------------------------------------------------------------

func build_map() -> void:
	match Game.current_keepsake():
		2: _build_gym()
		3: _build_field()
		4: _build_ocean()
		5: _build_steps()
		6: _build_plaza()
		7: _build_ballpark()
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


## Balboa Park after closing: the Prado, and the museum steps.
func _build_steps() -> void:
	room.setup(34, 24, Room.GRASS)
	room.fill(0, 0, 34, 1, Room.TREE)
	room.fill(0, 23, 34, 1, Room.TREE)
	room.fill(9, 2, 16, 1, Room.ROOF)
	room.fill(9, 3, 16, 6, Room.STUCCO)
	room.fill(16, 8, 2, 1, Room.DOOR)
	room.fill(12, 9, 10, 3, Room.SIDEWALK)   # the steps
	room.fill(0, 12, 34, 4, Room.PATIO)
	for spot in [Vector2i(3, 5), Vector2i(29, 4), Vector2i(5, 19), Vector2i(27, 20)]:
		room.set_tile(spot.x, spot.y, Room.TREE)


## Old Town's plaza, late in the summer: the same benches, the same pigeons.
func _build_plaza() -> void:
	room.setup(36, 24, Room.DIRT)
	room.fill(0, 0, 36, 1, Room.TREE)
	room.fill(0, 23, 36, 1, Room.TREE)
	room.fill(2, 2, 14, 1, Room.CLAY_ROOF)
	room.fill(2, 3, 14, 3, Room.ADOBE)
	room.fill(20, 2, 14, 1, Room.CLAY_ROOF)
	room.fill(20, 3, 14, 3, Room.ADOBE)
	room.fill(10, 9, 18, 10, Room.GRASS)
	room.fill(15, 13, 2, 1, Room.BENCH)     # the bench
	room.fill(23, 13, 2, 1, Room.BENCH)
	room.set_tile(19, 15, Room.PROP)        # the flagpole


## The ballpark after midnight, five years ago: the outfield grass, the empty
## stands, the scoreboard dark.
func _build_ballpark() -> void:
	room.setup(36, 24, Room.FIELD)
	room.fill(0, 0, 36, 3, Room.BLEACHERS)
	room.fill(0, 3, 36, 1, Room.FENCE)
	room.fill(0, 21, 36, 3, Room.BLEACHERS)
	room.fill(0, 0, 1, 24, Room.BLEACHERS)
	room.fill(35, 0, 1, 24, Room.BLEACHERS)


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
		6:
			# Paper flags, the flagpole, and pigeons (the bread's in his hand).
			var colors := [Color8(230, 70, 110), Color8(250, 190, 50), Color8(80, 190, 120), Color8(70, 150, 230)]
			for k in 18:
				_decor.draw_rect(Rect2(Vector2(10 * T + k * 20, 8 * T + 2), Vector2(12, 12)), colors[k % colors.size()])
			_decor.draw_rect(Rect2(19 * T + 9, 11 * T, 3, 4 * T + 10), Color8(190, 190, 196))
			for spot in [Vector2(14, 15), Vector2(16, 15.5), Vector2(17.5, 14.8), Vector2(13, 14), Vector2(18, 16), Vector2(15, 16.5)]:
				_decor.draw_circle(spot * T, 4.0, Color8(130, 130, 145))
				_decor.draw_circle(spot * T + Vector2(4, -4), 2.5, Color8(110, 120, 140))
			if _flags.get("feather", false):
				_decor.draw_line(Vector2(15 * T + 14, 13 * T + 6), Vector2(16 * T + 4, 13 * T - 2), Color8(150, 150, 160), 3.0)
		7:
			# The dark scoreboard, the stars, two sleeping bags, and the token (if it
			# hasn't been used yet) glinting on Relic's bag.
			_decor.draw_rect(Rect2(12 * T, 0, 12 * T, 3 * T - 4), Color8(16, 16, 22))
			_decor.draw_string(_font, Vector2(14 * T, 2 * T - 2), "HOME 0   VISITORS 0", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.85, 0.3, 0.12))
			for k in 40:
				_decor.draw_rect(Rect2(Vector2((k * 97) % 720, 4 + (k * 31) % 50), Vector2(2, 2)), Color(1, 1, 1, 0.5))
			_decor.draw_rect(Rect2(17 * T, 11 * T, 2 * T, 3 * T), Color8(200, 60, 60))
			_decor.draw_rect(Rect2(14 * T, 11 * T, 2 * T, 3 * T), Color8(60, 110, 70))
			if not _flags.get("token_used", false):
				_decor.draw_circle(Vector2(14 * T + 10, 13 * T + 4), 3.0, Color8(240, 200, 80))
		5:
			# The steps (lines across them), and the stars.
			for k in 3:
				_decor.draw_line(Vector2(12 * T, (9 + k) * T), Vector2(22 * T, (9 + k) * T), Color8(150, 150, 142), 2.0)
			for k in 30:
				_decor.draw_rect(Rect2(Vector2((k * 113) % 680, (k * 47) % 40), Vector2(2, 2)), Color(1, 1, 1, 0.6))
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
	# Up to the steps, where Hop is sitting.
	if memory == 5 and hop != null and player.position.distance_to(hop.position) < 34.0 and not _flags.get("ended", false):
		_flags["ended"] = true
		run_cutscene(_end_steps)
	# Hop, after his nightmare.
	if memory == 7 and hop != null and _flags.get("screamed", false) and player.position.distance_to(hop.position) < 36.0 and not _flags.get("ended", false):
		_flags["ended"] = true
		run_cutscene(_end_ballpark)
	# The old man on the bench.
	if memory == 6 and _flags.has("man") and player.position.distance_to(_flags["man"]) < 40.0 and not _flags.get("ended", false):
		_flags["ended"] = true
		run_cutscene(_end_plaza)
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
		5: await run_cutscene(_intro_steps)
		6: await run_cutscene(_intro_plaza)
		7: await run_cutscene(_intro_ballpark)


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


# --- 5: The museum steps ------------------------------------------------------------

func _intro_steps() -> void:
	var night := CanvasModulate.new()
	night.color = Color(0.45, 0.6, 0.55)
	add_child(night)
	hop = Cast.make("Hop")
	add_character(hop, Vector2(17 * T, 10 * T + 10))
	hop.face(Vector2.DOWN)
	await get_tree().create_timer(2.6).timeout
	await Game.dialogue.say([
		"* (Balboa Park, after closing. The museum steps\n*  are still warm from the sun.)",
		"* (Hop has been quiet all night. That isn't like him.)",
	])
	Game.set_objective("(Sit with Hop on the steps.)")


func _end_steps() -> void:
	hop.face(player.position - hop.position)
	await Game.dialogue.say([
		{"who": "Hop", "text": "Can I tell you something weird?\nLike. Actually weird.", "mood": "sad"},
		{"who": "Relic", "choices": ["...Yeah.", "(Sit down next to him.)"]},
		{"who": "Hop", "text": "There's... something inside me. A voice.\nIt's been there my whole life.", "mood": "sad"},
		{"who": "Hop", "text": "It doesn't talk much. But when it does,\nit likes bad things. Fire. People getting hurt.", "mood": "sad"},
		{"who": "Hop", "text": "I've never told anyone. Not my dad.\nNot anybody.", "mood": "sad"},
		"* (He's waiting for you to get up and leave.)",
		{"who": "Relic", "text": "Everybody's got something in them\nthey didn't ask for.", "mood": ""},
		{"who": "Hop", "text": "...That's it? You're not freaked out?", "mood": "shocked"},
		{"who": "Relic", "text": "I carry a backpack full of other people's junk.\nI'm not one to judge.", "mood": "smug"},
		"* (Hop laughs. It's the first time all night.)",
		{"who": "Hop", "text": "...Thanks, Relic.", "mood": "happy"},
	])
	await _finish(["* He told us everything.\n* We kept every word."])


# --- 6: The plaza bench ---------------------------------------------------------------

var _man: Character


func _intro_plaza() -> void:
	_man = Cast.make("pigeons")
	add_character(_man, Vector2(16 * T, 14 * T + 4))
	_man.face(Vector2.DOWN)
	_flags["man"] = _man.position
	await get_tree().create_timer(2.6).timeout
	await Game.dialogue.say([
		"* (Old Town, late in the summer. Hop went to get\n*  churros. There's a line. There's always a line.)",
		"* (On a bench in the plaza, an old man is feeding\n*  the pigeons.)",
		"* (No. He's holding the bread, and the pigeons are\n*  waiting, and he's crying.)",
	])
	Game.set_objective("(The old man on the bench.)")


func _end_plaza() -> void:
	_man.face(player.position - _man.position)
	await Game.dialogue.say([
		"* (He doesn't look up when you sit down.)",
		"* The old man: \"...She'd have liked you. My wife.\"",
		"* \"Geraldine. Forty-one years. Last Tuesday\n*  she just... didn't wake up.\"",
		"* \"She fed these birds every day. I don't even\n*  like birds. I don't know why I'm here.\"",
		{"who": "Relic", "choices": ["(Listen.)", "(Stay.)"]},
		"* \"Everybody keeps saying it gets lighter.\n*  It doesn't get lighter. It gets HEAVIER.\"",
		"* (A pigeon walks up and drops a feather at your\n*  feet, like it's paying a toll.)",
		"* (You pick it up. You hold it between your hands.)",
		{"who": "Relic", "text": "Can I carry some of that for you?", "mood": ""},
		"* The old man: \"...What?\"",
		"* (Something moves. Out of him, and into the feather.\n*  It's so heavy your arms shake.)",
		"* (The old man blinks. He looks at the bread in his\n*  hand. He looks at the pigeons like he's never\n*  seen them before.)",
		"* The old man: \"...That one looks like a Gerald.\"",
		"* (He laughs. He can't stop.)",
		"* \"They ALL look like Geralds! Look at them!\n*  Every single one!\"",
	])
	hop = Cast.make("Hop")
	add_character(hop, Vector2(34 * T, 15 * T))
	await hop.walk_to(Vector2(19 * T, 15 * T), 110.0)
	hop.face(player.position - hop.position)
	await Game.dialogue.say([
		{"who": "Hop", "text": "Okay I got churros, the line was INSANE-\n...Who's that? Why's he laughing?", "mood": "happy"},
		"* (The old man is throwing bread to the pigeons and\n*  naming them. They're all named Gerald.)",
		"* (Hop looks at the feather in your hands.\n*  He stops smiling.)",
		{"who": "Hop", "text": "...What did you just do?", "mood": "shocked"},
		{"who": "Relic", "text": "Took some of it. He was carrying too much.", "mood": ""},
		{"who": "Hop", "text": "Is that what's in your backpack?\nAll that stuff? The bottle caps and-", "mood": "sad"},
		{"who": "Relic", "text": "People's worst days. Somebody has to hold them.", "mood": ""},
		{"who": "Hop", "text": "Doesn't it get heavy?", "mood": "sad"},
		{"who": "Relic", "text": "Yeah. That's how you know it's real.", "mood": "smug"},
		"* (The backpack's full. Relic tucks the feather between\n*  two slats of the bench, so it won't blow away.)",
	])
	_flags["feather"] = true
	_decor.queue_redraw()
	await Game.dialogue.say([
		{"who": "Relic", "text": "I'll come back for it.", "mood": ""},
		{"who": "Hop", "text": "...You will?", "mood": "sad"},
		{"who": "Relic", "text": "I always come back for them.", "mood": "happy"},
		"* (Hop hands you a churro. It's still warm.)",
	])
	await _finish(["* We carried his wife for him. Five years.\n* He never even knew.", "* We said we'd come back for it."])


# --- 7: The ballpark, after midnight -----------------------------------------------

func _intro_ballpark() -> void:
	var night := CanvasModulate.new()
	night.color = Color(0.4, 0.5, 0.6)
	add_child(night)
	hop = Cast.make("Hop")
	add_character(hop, Vector2(18 * T, 12 * T + 10))
	hop.face(Vector2.DOWN)
	await get_tree().create_timer(2.6).timeout
	await Game.dialogue.say([
		"* (The ballpark, after midnight. You climbed the fence.\n*  Hop said it was the best place in the city for stars.)",
		"* (He was right. He fell asleep an hour ago.\n*  You didn't. You don't, much.)",
	])
	await get_tree().create_timer(1.2).timeout
	Game.play_sfx("hurt", 0.7)
	await Game.dialogue.say([
		"* (Hop sits straight up and SCREAMS.)",
		{"who": "Hop", "text": "- no no no NO, get OUT, get out of my-", "mood": "shocked"},
		"* (He's shaking. He doesn't know where he is.)",
	])
	_flags["screamed"] = true
	Game.set_objective("(Go to Hop.)")


func _end_ballpark() -> void:
	hop.face(player.position - hop.position)
	await Game.dialogue.say([
		{"who": "Hop", "text": "It was the voice. It was- there was fire,\nand it was ME, it was my hands, and everyone was-", "mood": "sad"},
		{"who": "Hop", "text": "Every night. EVERY night, Relic.\nIt's getting worse.", "mood": "sad"},
		{"who": "Relic", "choices": ["(Sit down next to him.)", "...Give me your hand."]},
		"* (You check your pockets. A bottle cap: no, that's\n*  somebody else's. A ticket stub: somebody else's.)",
		"* (The only empty thing left: a token from Jack in the Box.\n*  GOOD FOR ONE FREE CURLY FRIES.)",
		{"who": "Relic", "text": "Hold this. Hold it tight. Think about the dream.", "mood": ""},
		"* (He holds it. You put your hands around his.)",
		"* (Something moves. Out of him, into the token.\n*  It's hot, then heavy, then very, very cold.)",
	])
	_flags["token_used"] = true
	_decor.queue_redraw()
	await Game.dialogue.say([
		{"who": "Hop", "text": "...", "mood": "shocked"},
		{"who": "Hop", "text": "It's quiet.", "mood": "shocked"},
		{"who": "Hop", "text": "It's never quiet. Relic, it's NEVER quiet.\nWhat did you DO?", "mood": "sad"},
		{"who": "Relic", "text": "Put it somewhere else. Go back to sleep.", "mood": ""},
		{"who": "Hop", "text": "...Will you stay up?", "mood": "sad"},
		{"who": "Relic", "text": "Someone has to.", "mood": "happy"},
		"* (You thread the token onto a cord, and hang it\n*  around your neck. It's still cold.)",
		"* (Hop is asleep in about ten seconds.)",
		"* (You watch the dark scoreboard until the sun comes up.)",
	])
	await _finish(["* He slept like a baby.", "* We wore his nightmares around our neck.\n* We never really slept again."])


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
