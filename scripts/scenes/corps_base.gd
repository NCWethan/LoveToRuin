extends Area
## The REVOLUTION Corps' base: an old bunker under the shelter at Westview Field.
## Joining the Corps on Westview Field leads straight down here; going their own
## way, Elric can come down whenever they like.
##
## Three parts, each its own rectangle on one big tile grid:
##   Main hall   the ladder down from the hatch, a map table with the twelve
##               fragments, monitors, a couch, bunks, a kitchen corner, a SAVE
##               point and a training dummy to spar with
##   Corridor    a long hallway with a steel door for each member, names on them
##   Rooms       one for each of the twelve Corps members, decorated like them, with
##               them inside
##
## Story flags (in Game.flags): base_arrived, plus talks_base_<id> for each chat.

const SCENE := "res://scenes/corps_base.tscn"
const HILLTOP_SCENE := "res://scenes/hilltop.tscn"
const T := Room.TILE

const HALL := Rect2i(0, 0, 40, 26)
const CORRIDOR := Rect2i(0, 30, 184, 24)
## The corridor's walkway runs along these rows (the rest is wall).
const WALK_TOP := 39
const WALK_BOTTOM := 44
## Where the members' doors are along the corridor's top wall (tile x of the left half).
const DOOR_XS := [8, 23, 38, 53, 68, 83, 98, 113, 128, 143, 158, 173]

## Where Elric arrives: at the foot of the ladder.
const LADDER_FOOT := Vector2(20 * T, 5 * T)
const HALL_DOOR_INSIDE := Vector2(37 * T, 14 * T)
const CORRIDOR_START := Vector2(3 * T, 42 * T)

## Each member's room, in the same order as the doors. `spot` is where they stand
## (in tiles, inside their room).
const MEMBERS := [
	{"id": "BigJoe6", "room": "The Knight's Quarters", "color": Color(0.85, 0.2, 0.2), "spot": Vector2i(16, 11)},
	{"id": "Eggo", "room": "Eggo's Nest", "color": Color(1.0, 0.85, 0.3), "spot": Vector2i(12, 13)},
	{"id": "Nassan", "room": "Planning Room", "color": Color(0.45, 0.6, 0.95), "spot": Vector2i(16, 12)},
	{"id": "Nat", "room": "The Library", "color": Color(0.4, 0.75, 0.45), "spot": Vector2i(20, 11)},
	{"id": "NCWethan", "room": "THE LAB!!!", "color": Color(0.45, 0.85, 1.0), "spot": Vector2i(14, 13)},
	{"id": "Ronin", "room": "Studio / Observatory", "color": Color(1.0, 0.5, 0.15), "spot": Vector2i(17, 13)},
	{"id": "Supreme", "room": "Data Center", "color": Color(0.8, 0.82, 0.9), "spot": Vector2i(16, 10)},
	{"id": "Crayola", "room": "Art & Cards", "color": Color(1.0, 0.55, 0.8), "spot": Vector2i(19, 13)},
	{"id": "Rooster", "room": "Rooster's Royal Chamber", "color": Color(0.95, 0.95, 0.95), "spot": Vector2i(15, 9)},
	{"id": "Agent", "room": "Strategy", "color": Color(0.7, 0.5, 1.0), "spot": Vector2i(13, 12)},
	{"id": "MuffinMage", "room": "The Kitchen", "color": Color(0.95, 0.5, 0.2), "spot": Vector2i(15, 13)},
	{"id": "Sansworth", "room": "The Garage", "color": Color(0.7, 0.7, 0.75), "spot": Vector2i(16, 12)},
]

## Whoever's coming along with Elric (Game.partner()), following behind.
var partner: Character
## Hop, waiting in the hall when someone else is coming along instead.
var hop: Character
var _decor: Node2D
var _font: Font
var _time: float = 0.0
## Whose room Elric is in (-1: the hall or the corridor).
var _in_room: int = -1


static func _px(r: Rect2i) -> Rect2:
	return Rect2(r.position * T, r.size * T)


## A member's room, in tiles.
static func room_rect(i: int) -> Rect2i:
	return Rect2i((i % 5) * 36 + 2, 58 + (i / 5) * 30, 32, 24)


func _ready() -> void:
	var all_rooms: Array[Rect2] = [_px(HALL), _px(CORRIDOR)]
	for i in MEMBERS.size():
		all_rooms.append(_px(room_rect(i)))
	rooms.assign(all_rooms)
	setup_area(LADDER_FOOT)
	Game.play_music("bunker")
	_font = ThemeDB.fallback_font

	# Underground: dim, with warm caged lamps along the walls.
	var dim := CanvasModulate.new()
	dim.color = Color(0.6, 0.6, 0.66)
	add_child(dim)

	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	_add_lamps()
	_place_people()
	_place_hotspots()
	fit_camera_to_room()
	_start.call_deferred()


func _process(delta: float) -> void:
	_time += delta
	_decor.queue_redraw()


# --- The map --------------------------------------------------------------------

func build_map() -> void:
	room.setup(184, 144, Room.VOID)
	_build_hall()
	_build_corridor()
	for i in MEMBERS.size():
		_build_member_room(i)


## A room's shell: concrete floor, a tall wall along the top, and walls around.
func _shell(r: Rect2i) -> void:
	room.fill(r.position.x, r.position.y, r.size.x, r.size.y, Room.BUNKER_WALL)
	room.fill(r.position.x + 1, r.position.y + 3, r.size.x - 2, r.size.y - 4, Room.BUNKER_FLOOR)


## Marks a block of tiles (relative to the room) as solid furniture.
func _prop(r: Rect2i, x: int, y: int, w: int, h: int) -> void:
	room.fill(r.position.x + x, r.position.y + y, w, h, Room.PROP)


func _build_hall() -> void:
	_shell(HALL)
	# The door to the corridor, in the right wall.
	room.fill(39, 13, 1, 2, Room.BUNKER_DOOR)
	_prop(HALL, 17, 10, 6, 3)    # the map table
	_prop(HALL, 2, 3, 8, 1)      # the monitors
	_prop(HALL, 3, 19, 6, 2)     # the couch
	_prop(HALL, 4, 22, 3, 1)     # the coffee table
	_prop(HALL, 31, 19, 3, 4)    # the bunk beds
	_prop(HALL, 35, 19, 3, 4)
	_prop(HALL, 29, 3, 8, 1)     # the kitchen counter
	_prop(HALL, 37, 3, 2, 2)     # the fridge


func _build_corridor() -> void:
	var r := CORRIDOR
	room.fill(r.position.x, r.position.y, r.size.x, r.size.y, Room.BUNKER_WALL)
	room.fill(1, WALK_TOP, r.size.x - 2, WALK_BOTTOM - WALK_TOP + 1, Room.BUNKER_FLOOR)
	for x in DOOR_XS:
		room.fill(x, WALK_TOP - 1, 2, 1, Room.BUNKER_DOOR)
	# Back to the main hall, at the left end.
	room.fill(0, 41, 1, 2, Room.BUNKER_DOOR)


func _build_member_room(i: int) -> void:
	var r := room_rect(i)
	_shell(r)
	# The door out, in the bottom wall.
	room.fill(r.position.x + 15, r.end.y - 1, 2, 1, Room.BUNKER_DOOR)
	match MEMBERS[i]["id"]:
		"BigJoe6":
			_prop(r, 3, 4, 2, 3)      # bed
			_prop(r, 25, 3, 2, 2)     # armor stand
			_prop(r, 21, 15, 2, 2)    # sparring mannequin
			_prop(r, 7, 3, 5, 1)      # trophy shelf
		"Eggo":
			_prop(r, 4, 5, 3, 3)      # egg beanbag
			_prop(r, 22, 4, 4, 2)     # bunny hutch
			_prop(r, 28, 3, 2, 2)     # fridge
			_prop(r, 22, 16, 3, 2)    # bed
		"Nassan":
			_prop(r, 12, 6, 7, 2)     # desk
			_prop(r, 3, 3, 2, 3)      # filing cabinets
			_prop(r, 26, 3, 3, 2)     # radio table
			_prop(r, 3, 17, 2, 3)     # cot
		"Nat":
			for x in [2, 7, 23, 27]:
				_prop(r, x, 3, 3, 1)  # bookshelves
			_prop(r, 2, 10, 1, 8)     # long shelf
			_prop(r, 14, 8, 2, 2)     # the book on its stand
			_prop(r, 22, 12, 2, 2)    # armchair
		"NCWethan":
			_prop(r, 22, 5, 3, 3)     # tesla coil
			_prop(r, 3, 4, 7, 2)      # workbench
			_prop(r, 18, 15, 3, 2)    # checkers table
			_prop(r, 4, 16, 2, 3)     # bed
		"Ronin":
			_prop(r, 5, 6, 2, 2)      # amp
			_prop(r, 24, 5, 2, 3)     # telescope
			_prop(r, 22, 16, 3, 2)    # bed
			_prop(r, 28, 3, 1, 2)     # fire extinguisher
		"Supreme":
			_prop(r, 8, 3, 15, 2)     # the monitor wall desk
			_prop(r, 3, 15, 4, 3)     # boxes of printouts
			_prop(r, 25, 16, 3, 2)    # bed
		"Crayola":
			_prop(r, 5, 6, 2, 3)      # easel
			_prop(r, 18, 11, 4, 3)    # card table
			_prop(r, 25, 4, 3, 2)     # pool float
			_prop(r, 3, 17, 3, 2)     # bed
		"Rooster":
			_prop(r, 14, 4, 3, 3)     # throne
			_prop(r, 26, 3, 2, 3)     # mirror
			_prop(r, 4, 12, 4, 2)     # desk
			_prop(r, 24, 16, 3, 2)    # bed
		"MuffinMage":
			_prop(r, 4, 4, 4, 2)      # the grill
			_prop(r, 23, 3, 6, 2)     # the fish tank
			_prop(r, 25, 16, 3, 2)    # bed
		"Sansworth":
			_prop(r, 4, 3, 8, 1)      # the pegboard of keys
			_prop(r, 24, 3, 2, 2)     # the steering wheel on the wall
			_prop(r, 24, 15, 4, 3)    # the race car bed
		"Agent":
			_prop(r, 10, 6, 3, 3)     # chess table
			_prop(r, 25, 4, 2, 2)     # sunglasses display
			_prop(r, 3, 16, 3, 2)     # bed


# --- Lights, people, and things to look at -----------------------------------------

func _add_lamps() -> void:
	var spots: Array[Vector2] = [Vector2(6 * T, 3 * T), Vector2(20 * T, 3 * T), Vector2(33 * T, 3 * T), Vector2(20 * T, 16 * T)]
	for x in range(6, 184, 12):
		spots.append(Vector2(x * T, (WALK_TOP - 1) * T + 4))
	for i in MEMBERS.size():
		var r := _px(room_rect(i))
		spots.append(r.position + Vector2(8 * T, 3 * T))
		spots.append(r.position + Vector2(24 * T, 3 * T))
	for spot in spots:
		var lamp := Node2D.new()
		lamp.position = spot
		lamp.add_child(make_light(Color(1.0, 0.82, 0.55), 110.0, 0.75))
		world.add_child(lamp)


func _place_people() -> void:
	for i in MEMBERS.size():
		var member: Dictionary = MEMBERS[i]
		# Whoever's out with Elric isn't in their room.
		if member["id"] == Game.partner():
			continue
		var r := room_rect(i)
		var spot: Vector2i = r.position + member["spot"]
		var id: String = member["id"]
		add_npc(id, Vector2(spot.x * T + 10, spot.y * T + 10), func() -> void: await _talk(id))
	# The SAVE point and the shared storage box, by the ladder.
	var star := make_save_star()
	star.glow = true
	star.glow_color = Color(1.0, 1.0, 1.0, 0.55)
	star.on_interact = _save_point
	add_character(star, Vector2(14 * T, 6 * T))
	add_storage_box(Vector2(25 * T, 6 * T))
	# The training dummy.
	var dummy := Character.new().setup(load("res://art/sprites/training_dummy.png"))
	dummy.on_interact = _spar
	add_character(dummy, Vector2(33 * T, 13 * T))
	# Whoever's coming along follows Elric. If that isn't Hop, Hop hangs out on the
	# couch in the hall.
	# (Coming back on your own, the first time: Hop isn't with you yet. He runs in
	# from the hall in the arrival scene.)
	if _guest_arrival():
		return
	partner = Cast.make(Game.partner())
	add_character(partner, player.position + Vector2(-20, 0))
	partner.follow = player
	if Game.partner() != "Hop":
		hop = Cast.make("Hop")
		hop.on_interact = func() -> void:
			hop.face(player.position - hop.position)
			await chat("base_hop", [
				{"who": "Hop", "text": "Taking someone else out, huh? It's cool.\nI'll guard the couch.", "mood": "smug"},
				{"who": "Hop", "text": "...Come get me if things get weird, okay?", "mood": "sad"},
			], [[{"who": "Hop", "text": "Couch status: guarded.", "mood": "happy"}], [{"who": "Hop", "text": "Nine fragments to go. We'll get there.", "mood": "happy"}]])
		add_character(hop, Vector2(6 * T, 17 * T))


## A new partner was picked in the bag: reload the base, so they're the one
## following Elric (and back out of their room).
func refresh_partner() -> void:
	await Game.change_scene(SCENE, player.position)


func _place_hotspots() -> void:
	var spots := [
		[Vector2(20 * T, 2 * T + 10), _ladder],
		[Vector2(20 * T, 13 * T + 4), _map_table],
		[Vector2(6 * T, 4 * T + 6), _monitors],
		[Vector2(6 * T, 21 * T + 2), _couch],
		[Vector2(34 * T, 23 * T + 2), _bunks],
		[Vector2(33 * T, 4 * T + 6), _kitchen],
	]
	for spot in spots:
		world.add_child(Hotspot.create(spot[0], spot[1]))
	# Rooster's mirror, in his room (room 8).
	var rooster_room := room_rect(8)
	world.add_child(Hotspot.create(Vector2((rooster_room.position.x + 27) * T, (rooster_room.position.y + 6) * T - 4), _rooster_mirror))
	# Each member's door: ENTER in front of it (or just walk up into it).
	for i in DOOR_XS.size():
		var door_middle := Vector2((DOOR_XS[i] + 1) * T, WALK_TOP * T - 8)
		world.add_child(Hotspot.create(door_middle, _enter_room.bind(i)))


# --- Arriving ----------------------------------------------------------------------

## Coming down the hatch for the first time after going your own way.
func _guest_arrival() -> bool:
	return not flag("base_arrived") and Game.flags.get("route", "") == "neutral"


func _start() -> void:
	await wait_for_fade()
	if flag("base_arrived"):
		return
	Game.flags["base_arrived"] = true
	var guest: bool = Game.flags.get("route", "") == "neutral"
	await run_cutscene(func() -> void:
		var big_joe := add_character(Cast.make("BigJoe6"), Vector2(23 * T, 8 * T))
		var nassan := add_character(Cast.make("Nassan"), Vector2(17 * T, 8 * T))
		big_joe.face(player.position - big_joe.position)
		nassan.face(player.position - nassan.position)
		if guest:
			await Game.dialogue.say([
				"* (Under the shelter at Westview Field, a hatch.)",
				"* (It isn't locked. Somebody left it open for you.)",
				{"who": "Nassan", "text": "The offer stood. And here you are."},
				{"who": "BigJoe6", "text": "...Fine. But you're on dish duty.", "mood": "angry"},
				"* (Running footsteps in the hall.)",
			])
			# Hop comes running in from the hall, and from now on he's with Elric.
			partner = add_character(Cast.make("Hop"), HALL_DOOR_INSIDE)
			await partner.walk_to(player.position + Vector2(-22, 0), 150.0)
			partner.face(player.position - partner.position)
			await Game.dialogue.say([
				{"who": "Hop", "text": "ELRIC! You came back!", "mood": "happy"},
				{"who": "Nassan", "text": "There's a spare bunk by the wall.\nEveryone's room is down the hall.\nTheir names are on the doors."},
			])
		else:
			await Game.dialogue.say([
				"* (Under the shelter at Westview Field, a hatch.)",
				"* (A ladder goes down. And down.)",
				{"who": "BigJoe6", "text": "WELCOME TO THE BUNKER, RECRUIT!!", "mood": "happy"},
				{"who": "Nassan", "text": "The REVOLUTION Corps' base. Officially, it doesn't exist."},
				{"who": "Nassan", "text": "Everyone has a room down the hall.\nTheir names are on the doors."},
				{"who": "Nassan", "text": "Yours is the bunk by the wall. It isn't much. But it's yours."},
				{"who": "Hop", "text": "Home sweet underground home, huh?", "mood": "happy"},
				{"who": "BigJoe6", "text": "And that's Gerald. The training dummy.\nGo on. Give him a whack. He's used to it.", "mood": "smug"},
			])
		await Game.dialogue.say([
			{"who": "Nassan", "text": "Rest up. When you're ready, we'll talk about\nwhere the next fragment is."},
		])
		# They head off to their rooms.
		big_joe.walk_to(HALL_DOOR_INSIDE, 90.0)
		await nassan.walk_to(HALL_DOOR_INSIDE + Vector2(0, 20), 90.0)
		big_joe.queue_free()
		nassan.queue_free()
		if partner and partner.follow == null:
			partner.follow = player
		Game.set_objective("Explore the Corps' base. Everyone has a room.")
	)


# --- Moving between rooms ------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if Game.busy or Game.transitioning or _cutscene_running:
		return
	var p := player.position
	# Hall -> corridor (walking into the door in the right wall).
	if _px(HALL).has_point(p) and p.x > 38 * T + 4 and p.y > 13 * T and p.y < 15 * T + 10:
		_go(CORRIDOR_START, -1)
	# Corridor -> hall (the door at the left end).
	elif _px(CORRIDOR).has_point(p) and p.x < T + 12 and p.y > 41 * T and p.y < 43 * T + 10:
		_go(HALL_DOOR_INSIDE, -1)
	# Corridor -> a room (walking up into its door).
	elif _px(CORRIDOR).has_point(p) and p.y < WALK_TOP * T + 14 and Input.is_action_pressed("ui_up"):
		for i in DOOR_XS.size():
			if absf(p.x - (DOOR_XS[i] + 1) * T) < 18:
				_enter_room(i)
				return
	# A room -> the corridor (walking down into its door).
	elif _in_room >= 0:
		var r := _px(room_rect(_in_room))
		if p.y > r.end.y - T - 6 and absf(p.x - (r.position.x + 16 * T)) < 22:
			var door := Vector2((DOOR_XS[_in_room] + 1) * T, (WALK_TOP + 1) * T)
			_go(door, -1)


func _enter_room(i: int) -> void:
	if Game.busy or Game.transitioning:
		return
	var r := room_rect(i)
	_go(Vector2((r.position.x + 16) * T, (r.end.y - 3) * T), i)


func _go(to: Vector2, room_index: int) -> void:
	Game.busy = true
	Game.play_sfx("door")
	_in_room = room_index
	await go_through_door(to)
	Game.busy = false


# --- Talking -----------------------------------------------------------------------

## What each member says in their room: the first time, then later visits. On the
## Neutral route, they first have a word about Elric coming back.
const ROOM_TALK := {
	"BigJoe6": [
		[["happy", "WELCOME to the Knight's Quarters!"], ["smug", "Every member of the Corps gets a room.\nThis one's MINE. Obviously."], ["", "That armor? Hand-polished. Every night.\nJustice doesn't rust."], ["", "...Okay, Eggo polished it once.\nDon't tell him I said thanks."]],
		[[["", "Truth and justice, Elric. Truth. And. Justice."]], [["happy", "Want to hear the Revolution oath?\n...I haven't finished writing it."]]],
		"...So you came back. Good. Justice gives second chances.",
	],
	"Eggo": [
		[["", "yo."], ["", "this is my room."], ["", "the beanbag is an egg. i'm aware."], ["happy", "the bunny's name is Toast.\nshe's the real boss here."]],
		[[["happy", "egg-cellent to have you here."]], [["", "toast says hi."]]],
		"oh hey. you came back. egg-cellent.",
	],
	"Nassan": [
		[["", "Ah, Elric. Come in."], ["", "This wall is everything we know about the fragments.\nEvery report. Every sighting."], ["", "Twelve fragments. Three in our hands now.\nThe red string goes... well. Everywhere."], ["", "Rest while you can.\nPlanning is my job. Surviving is yours."]],
		[[["", "Nine left. I'm already working on where to look next."]], [["", "When it's time, you'll be the first to know."]], [["smug", "Gloria gave me Sundays off. For planning."], ["", "She thinks it's a book club.\nI didn't correct her."]]],
		"I hoped you'd come back. I planned for it, actually.",
	],
	"Nat": [
		[["", "...I'm reading."], ["", "This is the library.\nMostly old stories nobody else believes."], ["", "That book on the stand is the one with the torn last page.\nStill haven't found the page."], ["", "Don't touch the dusty ones.\nThey're dusty for a reason."]],
		[[["", "...Still reading."]], [["", "History repeats. That's why I read it."]]],
		"...You came back. Huh. Didn't see that in any book.",
	],
	"NCWethan": [
		[["happy", "ELRIC!!! WELCOME TO THE LAB!!!"], ["happy", "THIS IS A TESLA COIL!!! I BUILT IT!!!\nIT DOES LIGHTNING!!!"], ["smug", "ME AND RONIN PLAY CHECKERS IN HERE.\nI AM UNDEFEATED!!!"], ["happy", "DON'T TOUCH THE COIL!!!\n...OKAY TOUCH IT A LITTLE!!!"]],
		[[["happy", "KING ME!!!"]], [["happy", "LIGHTNING TIME!!! ...SORRY. HABIT!!!"]]],
		"YOU CAME BACK!!! I KNEW IT!!! I TOTALLY KNEW IT!!!",
	],
	"Ronin": [
		[["happy", "YO! Welcome to my studio slash observatory slash...\nyeah!"], ["", "The scorch marks? Guitar solo.\nTotally on purpose."], ["", "That's a fire extinguisher. Nassan made me get it. Twice."], ["happy", "At night you can see real stars through the vent.\nKinda."]],
		[[["", "I'm gonna beat Wethan at checkers. Someday."]], [["shocked", "*plays a chord*\n...the amp's on fire again."]]],
		"YOOO you came back! Wanna hear a song about it?",
	],
	"Supreme": [
		[["happy", "Welcome! Fun fact: this bunker is 74% concrete\nby volume."], ["", "These seven monitors track seven spreadsheets.\nEach one tracks the other six."], ["", "Your odds of finding all twelve fragments are...\nimproving. Slightly. Statistically."]],
		[[["", "Did you know? You've walked about 0.3 miles\nin this bunker today."]], [["happy", "New spreadsheet: \"Times Elric Visited My Room.\"\nIt's going great."]]],
		"You came back! That was a 31% chance. I'm thrilled.",
	],
	"Crayola": [
		[["", "Oh! Um. Hi."], ["", "This is... my art room. And cards.\nMostly cards."], ["happy", "I could teach you a game sometime.\nIf you want. No pressure."], ["", "The pool float is from swimming with N.C. Wethan.\nHe makes really big splashes."]],
		[[["", "...Seven of Hearts?"]], [["happy", "I drew you. It's not very good. Don't look."]]],
		"Oh... you're back. I'm glad. Um. That's all.",
	],
	"Rooster": [
		[["smug", "Oh great, the new kid found my room.\nBow, I guess."], ["smug", "Yes, that's a throne.\nSome of us are just built different."], ["", "Half white, half black. It's called DUALITY.\nLook it up."], ["smug", "Your outfit, on the other hand... no comment.\nActually, one comment: yikes."]],
		[[["smug", "I'm not roasting you. I'm SEASONING you."]], [["angry", "...Did you just laugh at my throne?"]]],
		"Look who crawled back. Couldn't stay away from me, huh?",
	],
	"MuffinMage": [
		[["", "Yo. Welcome to the Kitchen."], ["", "That's a grill. That's a fish tank.\nThey are NOT related. Don't ask."], ["smug", "The fish's name is Burger.\nHe knows what he did."], ["", "Salmon burgers every Friday. It's the law.\n...My law."]],
		[[["", "Brain food. Want one? Too bad. Last one."]], [["", "Burger says hi.\n...He's judging you. He judges everyone."]]],
		"You came back. Good. More salmon burgers for...\nno. Still mine.",
	],
	"Sansworth": [
		[["happy", "Welcome to the Garage!"], ["", "That's my parking spot. It's reserved.\nFor my car. Which I'll find."], ["", "Those are my car keys. Thirty-one of them.\nNone of them open anything."], ["happy", "The bed is a race car.\nIt's the closest I've gotten."]],
		[[["", "Still no car. But the spot's ready."]], [["happy", "Vroom. ...That was me. Not a car."]]],
		"You came back! Like a car that remembers\nwhere it parked!",
	],
	"Agent": [
		[["", "Strategy room. Sit. Or don't."], ["smug", "That's the math on the fragments.\nYou won't follow it."], ["", "The dartboard is for thinking. I don't miss."], ["", "Welcome to the Corps.\nDon't make me recalculate."]],
		[[["", "Still here? Efficient use of time? No."]], [["smug", "Four. Next."]]],
		"You came back. Predictable. Good.",
	],
}


func _talk(id: String) -> void:
	var talk: Array = ROOM_TALK[id]
	var first: Array = []
	if Game.flags.get("route", "") == "neutral":
		first.append({"who": id, "text": talk[2]})
	for line in talk[0]:
		first.append({"who": id, "text": line[1], "mood": line[0]})
	var repeats: Array = []
	for visit in talk[1]:
		var lines: Array = []
		for line in visit:
			lines.append({"who": id, "text": line[1], "mood": line[0]})
		repeats.append(lines)
	await chat("base_" + id.to_lower(), first, repeats)


func _save_point() -> void:
	Game.play_sfx("heal")
	Game.heal_party()
	await Game.dialogue.say(["* (Down here, it's quiet. Safe.)", "* (The hum of the generators fills you with DETERMINATION.)", Game.restored_line()])
	var choice := await Game.dialogue.ask("* (Save your progress?)", ["Save", "Return"])
	if choice == 0:
		Game.save_game(SCENE, player.position)
		Game.play_sfx("save")
		await Game.dialogue.say(Game.saved_lines())


func _spar() -> void:
	var choice := await Game.dialogue.ask("* (Gerald, the training dummy.\n*  Spar with him?)", ["Spar", "Leave him be"])
	if choice == 0:
		await Game.start_battle("training", SCENE, player.position)


## Up the ladder: the hatch comes out in front of the shelter at Westview Field.
func _ladder() -> void:
	var choice := await Game.dialogue.ask("* (The ladder up to the hatch.\n*  Westview Field is up there.)", ["Climb up", "Stay"])
	if choice == 0:
		Game.play_sfx("door")
		await Game.change_scene(HILLTOP_SCENE, Vector2(7 * T + 10, 7 * T))


func _map_table() -> void:
	await Game.dialogue.say([
		"* (A big map of the city, covered in notes.)",
		"* (Twelve red circles. Three are crossed out.)",
		"* (Someone has drawn a tiny crown next to Rooster's\n*  neighborhood. In Rooster's handwriting.)",
	])


func _monitors() -> void:
	await Game.dialogue.say(["* (Security monitors. One shows the hatch.\n*  One shows the field. One shows... Supreme's room?)", "* (Supreme is waving at the camera.)"])


func _couch() -> void:
	await Game.dialogue.say(["* (A worn-out couch. There's a checkers board on\n*  the coffee table, mid-game.)", "* (Red is winning. Red is always winning.)"])


func _bunks() -> void:
	var line := "* (Your bunk. Someone put a little sign on it:\n*  \"ELRIC\". The E is backwards.)" if Game.flags.get("route", "") == "pacifist" else "* (A spare bunk. Hop's jacket is on the top one.)"
	if flag("dreamed_relic"):
		await Game.dialogue.say([line])
		return
	await Game.dialogue.say([line])
	var rest: int = await Game.dialogue.ask("* (Lie down for a while?)", ["Rest", "Not now"])
	if rest == 0:
		await _dream()


## The first dream: the voice that came with the fragments. It doesn't know Elric
## yet, only that Elric is carrying it. (It's Relic: Hop's friend, who died on
## Westview Field the first night Hopkuna came out, and broke Hopkuna's power
## into the twelve fragments. What's left of them is in the fragments, and rides
## along with whoever carries them.) What it wants depends on the route.
const DREAM_START := [
	"* (You close your eyes.)",
	"* (...)",
	"* (Somewhere, something is humming.)",
	{"who": "Relic", "tag": "???", "face": false, "text": "...You're carrying them."},
	{"who": "Relic", "tag": "???", "face": false, "text": "I don't know who you are. But you walk like I used to.\nLike there's nowhere you're allowed to stop."},
]
const DREAM_PACIFIST := [
	{"who": "Relic", "tag": "???", "face": false, "text": "He's close, isn't he. Hop."},
	{"who": "Relic", "tag": "???", "face": false, "text": "He saved me once. Or he tried.\nIt wasn't his fault. Tell him that. Someday."},
	{"who": "Relic", "tag": "???", "face": false, "text": "And when you find the rest of me...\nbreak it. All of it. It's the only way he gets to be free."},
]
const DREAM_NEUTRAL := [
	{"who": "Relic", "tag": "???", "face": false, "text": "You keep walking away from people. I did that too."},
	{"who": "Relic", "tag": "???", "face": false, "text": "It doesn't stop the pull.\nIt just makes you lonely while it pulls."},
	{"who": "Relic", "tag": "???", "face": false, "text": "Don't stop. Not yet.\nThere's more of me out there."},
]
## Waking up from the first three keepsakes.
const KEEPSAKES_AFTER := [
	"* (A road at dawn. A gym at night.\n*  A boy with two orders of curly fries.)",
	"* (None of it happened to you.\n*  You remember all of it.)",
]
const DREAM_END := [
	"* (You wake up.)",
	"* (Your hand is closed tight around nothing.)",
]


func _dream() -> void:
	Game.flags["dreamed_relic"] = true
	await Game.fade_out(1.2)
	Game.stop_music(1.0)
	# The dark, with a faint green glow breathing in it (Relic's color; red is
	# Hopkuna's), under the text box.
	var dark := CanvasLayer.new()
	dark.layer = 45
	var screen := Control.new()
	screen.size = Vector2(640, 480)
	var clock := [0.0]
	screen.draw.connect(func() -> void:
		screen.draw_rect(Rect2(0, 0, 640, 480), Color.BLACK)
		var glow := 0.18 + 0.08 * sin(clock[0] * 1.6)
		for ring in 6:
			screen.draw_circle(Vector2(320, 180), 90.0 - ring * 14.0, Color(0.1, 0.6, 0.25, glow * 0.25))
	)
	# (A timer keeps the glow breathing; it goes away with the dream.)
	var timer := Timer.new()
	timer.wait_time = 0.05
	timer.autostart = true
	timer.timeout.connect(func() -> void:
		clock[0] += 0.05
		screen.queue_redraw()
	)
	dark.add_child(timer)
	dark.add_child(screen)
	add_child(dark)
	await Game.fade_in(1.2)
	var lines: Array = DREAM_START.duplicate()
	# How many fragments Elric is carrying right now.
	var count := int(Game.flags.get("fragments", 3))
	var said: String = ["None", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"][clampi(count, 0, 12)]
	lines.insert(4, {"who": "Relic", "tag": "???", "face": false, "text": "The pieces. I can feel every one of them.\n%s now." % said})
	lines.append_array(DREAM_PACIFIST if Game.flags.get("route", "") == "pacifist" else DREAM_NEUTRAL)
	# The first time: the fragments show Elric what's inside them.
	var first_keepsakes: bool = int(Game.flags.get("keepsakes_seen", 0)) < 3
	if first_keepsakes:
		lines.append({"who": "Relic", "tag": "???", "face": false, "text": "...Here. Let me show you."})
	await Game.dialogue.say(lines)
	if first_keepsakes:
		await Game.play_keepsakes([1, 2, 3], SCENE, player.position, KEEPSAKES_AFTER + DREAM_END)
		return
	await Game.fade_out(1.2)
	dark.queue_free()
	Game.play_music("bunker")
	await Game.fade_in(1.0)
	await Game.dialogue.say(DREAM_END)


## Rooster's mirror. The first time, the reflection isn't quite Elric for a second
## (Relic, riding along). With dread, it looks away before Elric does.
func _rooster_mirror() -> void:
	var lines: Array = [
		"* (Rooster's mirror. There's a sticky note on it:\n*  \"LOOKING GOOD, KING.\")",
		"* (In the glass: it's you.)",
	]
	if Game.dread() > 0:
		lines.append("* (...Your reflection looks away a moment\n*  before you do.)")
	elif not flag("mirror_relic"):
		Game.flags["mirror_relic"] = true
		lines.append("* (For a second, the reflection looks like\n*  someone else.)")
		lines.append("* (Then it's just you again.)")
	lines.append({"who": "Rooster", "text": "Hey! HEY. That's MY mirror.", "mood": "angry"})
	lines.append({"who": "Rooster", "text": "...Fine. You can borrow it.\nYou look like you need it.", "mood": "smug"})
	await Game.dialogue.say(lines)


func _kitchen() -> void:
	await Game.dialogue.say(["* (A tiny kitchen. The fridge has a sign on it:\n*  \"EGGO'S EGGS. DO NOT TOUCH.\")", "* (Below it, in different handwriting:\n*  \"THEY'RE NOT EVEN REAL EGGS.\")"])


# --- Drawing --------------------------------------------------------------------------

func _draw_decor() -> void:
	_draw_hall()
	_draw_corridor()
	for i in MEMBERS.size():
		var r := _px(room_rect(i))
		_room_extras(r, MEMBERS[i]["color"])
		match MEMBERS[i]["id"]:
			"BigJoe6": _draw_big_joe(r)
			"Eggo": _draw_eggo(r)
			"Nassan": _draw_nassan(r)
			"Nat": _draw_nat(r)
			"NCWethan": _draw_wethan(r)
			"Ronin": _draw_ronin(r)
			"Supreme": _draw_supreme(r)
			"Crayola": _draw_crayola(r)
			"Rooster": _draw_rooster(r)
			"Agent": _draw_agent(r)
			"MuffinMage": _draw_muffinmage(r)
			"Sansworth": _draw_sansworth(r)


func _text(at: Vector2, text: String, size: int, color: Color) -> void:
	_decor.draw_string(_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _centered(middle: Vector2, text: String, size: int, color: Color) -> void:
	var width := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(middle - Vector2(width / 2, 0), text, size, color)


## A rectangle with a darker outline and a lighter top edge (furniture).
func _block(rect: Rect2, color: Color) -> void:
	_decor.draw_rect(rect, color)
	_decor.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), color.lightened(0.2))
	_decor.draw_rect(rect, color.darkened(0.4), false, 1.0)


func _rug(rect: Rect2, color: Color) -> void:
	_decor.draw_rect(rect, color)
	_decor.draw_rect(rect.grow(-3), color.lightened(0.15), false, 2.0)


func _bed(at: Vector2, w: float, h: float, blanket: Color) -> void:
	_block(Rect2(at, Vector2(w, h)), Color8(110, 80, 55))
	_decor.draw_rect(Rect2(at + Vector2(3, 3), Vector2(w - 6, 10)), Color8(235, 235, 230))
	_decor.draw_rect(Rect2(at + Vector2(2, 15), Vector2(w - 4, h - 18)), blanket)
	_decor.draw_rect(Rect2(at + Vector2(2, 15), Vector2(w - 4, 3)), blanket.lightened(0.2))


func _poster(at: Vector2, size: Vector2, color: Color, text: String, text_color: Color) -> void:
	_decor.draw_rect(Rect2(at, size), color)
	_decor.draw_rect(Rect2(at, size), color.darkened(0.5), false, 1.0)
	_centered(at + Vector2(size.x / 2, size.y / 2 + 4), text, 10, text_color)


## A row of books on a shelf, `w` pixels wide.
func _bookshelf(at: Vector2, w: float, h: float) -> void:
	_block(Rect2(at, Vector2(w, h)), Color8(95, 65, 40))
	var colors := [Color8(170, 50, 50), Color8(50, 90, 160), Color8(60, 130, 70), Color8(190, 150, 60), Color8(120, 70, 140)]
	var rows := int(h / 12)
	for row in rows:
		var x := 3.0
		var k := row * 3
		while x < w - 5:
			var book_w := 3.0 + (k * 7 % 3)
			_decor.draw_rect(Rect2(at + Vector2(x, 2 + row * 12), Vector2(book_w, 9)), colors[k % colors.size()])
			x += book_w + 1
			k += 1


func _draw_hall() -> void:
	var r := _px(HALL)
	_floor_emblem(Vector2(20 * T, 19 * T))
	# Crates stacked against the left wall, and a plant by the ladder.
	for k in 3:
		_crate(Vector2(T + 2, (9 + k) * T + (k % 2) * 4))
	_crate(Vector2(2 * T + 2, 10 * T))
	_plant(Vector2(23 * T, 4 * T))
	_plant(Vector2(16 * T, 4 * T))
	_clock(Vector2(26 * T, 1 * T + 6))
	# Pipes along the top wall.
	for y in [14.0, 22.0]:
		_decor.draw_line(Vector2(T, y), Vector2(r.end.x - T, y), Color8(120, 110, 95), 4.0)
		_decor.draw_line(Vector2(T, y - 1), Vector2(r.end.x - T, y - 1), Color8(150, 140, 120), 1.0)
	# The ladder down from the hatch.
	var ladder := Rect2(19 * T + 2, 0, 2 * T - 4, 3 * T)
	_decor.draw_rect(Rect2(ladder.position + Vector2(0, 0), Vector2(ladder.size.x, 6)), Color8(40, 40, 44))
	for side in [ladder.position.x, ladder.end.x - 3]:
		_decor.draw_rect(Rect2(side, 0, 3, ladder.size.y), Color8(150, 150, 158))
	for rung in range(8, int(ladder.size.y), 9):
		_decor.draw_rect(Rect2(ladder.position.x, rung, ladder.size.x, 2), Color8(130, 130, 138))
	# The REVOLUTION banner.
	var banner := Rect2(11 * T, 6, 7 * T, 2 * T - 4)
	_decor.draw_rect(banner, Color8(170, 30, 35))
	_decor.draw_rect(banner, Color8(110, 15, 20), false, 2.0)
	_centered(banner.get_center() + Vector2(0, 5), "REVOLUTION", 14, Color8(245, 230, 200))
	# The monitors.
	for i in 4:
		var screen := Rect2((2 + i * 2) * T + 2, 3 * T - 14, 2 * T - 4, 14)
		_block(Rect2(screen.position - Vector2(0, 0), Vector2(screen.size.x, T + 14)), Color8(50, 52, 58))
		var glow := 0.6 + 0.2 * sin(_time * 3.0 + i)
		_decor.draw_rect(screen.grow(-2), Color(0.25 * glow, 0.75 * glow, 0.55 * glow))
		_decor.draw_line(screen.position + Vector2(4, 8), screen.position + Vector2(screen.size.x - 4, 4 + i), Color(0.6, 1.0, 0.8), 1.0)
	# The map table, with the twelve circles (three crossed out).
	var table := Rect2(17 * T, 10 * T, 6 * T, 3 * T)
	_block(table, Color8(105, 75, 48))
	var map := table.grow(-5)
	_decor.draw_rect(map, Color8(222, 210, 175))
	_decor.draw_line(map.position + Vector2(10, 12), map.end - Vector2(20, 8), Color8(160, 140, 110), 2.0)
	_decor.draw_line(map.position + Vector2(5, map.size.y - 10), map.position + Vector2(map.size.x - 5, 15), Color8(160, 140, 110), 2.0)
	for k in 12:
		var spot := map.position + Vector2(10 + (k * 37) % int(map.size.x - 20), 8 + (k * 23) % int(map.size.y - 14))
		_decor.draw_arc(spot, 4.0, 0, TAU, 10, Color8(200, 30, 30), 1.5)
		if k < 3:
			_decor.draw_line(spot - Vector2(4, 4), spot + Vector2(4, 4), Color8(30, 30, 30), 1.5)
			_decor.draw_line(spot + Vector2(-4, 4), spot + Vector2(4, -4), Color8(30, 30, 30), 1.5)
	# The couch, a rug and the coffee table.
	_rug(Rect2(2 * T, 18 * T, 8 * T, 6 * T), Color8(120, 50, 45))
	_block(Rect2(3 * T, 19 * T, 6 * T, 2 * T), Color8(80, 95, 70))
	_decor.draw_rect(Rect2(3 * T + 4, 19 * T + 4, 6 * T - 8, 10), Color8(95, 112, 84))
	_block(Rect2(4 * T, 22 * T, 3 * T, T), Color8(100, 72, 45))
	for k in 8:
		_decor.draw_rect(Rect2(4 * T + 6 + k * 6, 22 * T + 4 + (k % 2) * 6, 5, 5), Color8(200, 40, 40) if k % 2 == 0 else Color8(30, 30, 30))
	# Bunk beds.
	for x in [31, 35]:
		_bed(Vector2(x * T, 19 * T), 3 * T, 4 * T, Color8(70, 85, 130) if x == 31 else Color8(130, 70, 70))
		_decor.draw_rect(Rect2(x * T, 19 * T - 6, 3 * T, 4), Color8(90, 65, 45))
	# The kitchen: a counter, a hot plate and the fridge.
	_block(Rect2(29 * T, 3 * T - 6, 8 * T, T + 6), Color8(150, 150, 150))
	_decor.draw_rect(Rect2(30 * T, 3 * T - 2, 14, 10), Color8(40, 40, 40))
	_decor.draw_rect(Rect2(33 * T, 3 * T - 4, 18, 12), Color8(190, 40, 35))
	_text(Vector2(33 * T + 1, 3 * T + 6), "JIB", 7, Color.WHITE)
	_block(Rect2(37 * T, 2 * T, 2 * T - 2, 3 * T), Color8(215, 215, 210))
	_decor.draw_rect(Rect2(37 * T + 4, 3 * T, 10, 7), Color8(250, 240, 120))
	# Exit sign over the corridor door.
	_decor.draw_rect(Rect2(38 * T - 8, 12 * T - 14, 26, 10), Color8(30, 120, 50))
	_text(Vector2(38 * T - 6, 12 * T - 6), "HALL", 8, Color8(200, 255, 200))


func _draw_corridor() -> void:
	var top := (WALK_TOP - 1) * T
	# Pipes and cables running the whole length.
	for y in [top - 3 * T, top - 3 * T + 8]:
		_decor.draw_line(Vector2(0, y), Vector2(CORRIDOR.size.x * T, y), Color8(115, 105, 90), 4.0)
	_decor.draw_line(Vector2(0, top - 2 * T), Vector2(CORRIDOR.size.x * T, top - 2 * T + 3), Color8(30, 30, 34), 2.0)
	# Hazard stripes along the bottom of the walkway.
	var bottom := (WALK_BOTTOM + 1) * T
	for x in range(0, CORRIDOR.size.x * T, 16):
		_decor.draw_colored_polygon(PackedVector2Array([Vector2(x, bottom), Vector2(x + 8, bottom), Vector2(x + 4, bottom + 6), Vector2(x - 4, bottom + 6)]), Color8(200, 170, 40))
	# A name plate over every door, in that member's color.
	for i in DOOR_XS.size():
		var member: Dictionary = MEMBERS[i]
		var middle := Vector2((DOOR_XS[i] + 1) * T, top - 12)
		var plate_name := DialogueBox.display_name(member["id"])
		var width := _font.get_string_size(plate_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 12
		var plate := Rect2(middle - Vector2(width / 2, 10), Vector2(width, 16))
		_decor.draw_rect(plate, Color8(40, 40, 46))
		_decor.draw_rect(plate, member["color"], false, 2.0)
		_centered(middle + Vector2(0, 2), plate_name, 11, member["color"])
	# A sign at the left end.
	_text(Vector2(T + 4, top - 30), "<- MAIN HALL", 10, Color8(200, 255, 200))


## Things every room has: pipes along the top wall, a clock, a plant in each
## bottom corner, a couple of crates, and a stripe of the owner's color.
func _room_extras(r: Rect2, color: Color) -> void:
	for y in [12.0, 20.0]:
		_decor.draw_line(r.position + Vector2(T, y), r.position + Vector2(r.size.x - T, y), Color8(115, 105, 90), 4.0)
	_decor.draw_rect(Rect2(r.position + Vector2(T, 3 * T - 6), Vector2(r.size.x - 2 * T, 4)), Color(color, 0.7))
	_clock(r.position + Vector2(r.size.x - 3 * T, 1 * T + 6))
	_plant(r.position + Vector2(2 * T, 21 * T))
	_plant(r.position + Vector2(29 * T, 21 * T))
	_crate(r.position + Vector2(12 * T, 20 * T + 4))
	_crate(r.position + Vector2(13 * T + 4, 20 * T + 8))


func _plant(at: Vector2) -> void:
	_block(Rect2(at + Vector2(-7, 2), Vector2(14, 12)), Color8(150, 85, 55))
	for k in 5:
		var leaf := at + Vector2(-8 + k * 4, -4 - (k % 2) * 5)
		_decor.draw_circle(leaf, 5, Color8(60, 130, 70) if k % 2 == 0 else Color8(80, 155, 85))


func _crate(at: Vector2) -> void:
	var box := Rect2(at, Vector2(T - 2, T - 4))
	_block(box, Color8(140, 110, 70))
	_decor.draw_line(box.position, box.end, Color8(100, 75, 45), 1.0)
	_decor.draw_line(box.position + Vector2(box.size.x, 0), box.position + Vector2(0, box.size.y), Color8(100, 75, 45), 1.0)


func _clock(at: Vector2) -> void:
	_decor.draw_circle(at, 9, Color8(40, 40, 44))
	_decor.draw_circle(at, 7, Color8(235, 230, 215))
	var t := _time * 0.2
	_decor.draw_line(at, at + Vector2.from_angle(t - PI / 2) * 5, Color8(30, 30, 30), 1.5)
	_decor.draw_line(at, at + Vector2.from_angle(t * 12.0 - PI / 2) * 6, Color8(180, 30, 30), 1.0)


## The Corps' emblem painted on the floor: a ring of twelve pieces, one for each
## fragment, with the three they've found painted red.
func _floor_emblem(middle: Vector2) -> void:
	var outer := 74.0
	var inner := 52.0
	_decor.draw_set_transform(middle, 0.0, Vector2(1.0, 0.7))
	for k in 12:
		var start := k * TAU / 12 + 0.04 - PI / 2
		var end := (k + 1) * TAU / 12 - 0.04 - PI / 2
		var piece := PackedVector2Array()
		for s in 7:
			piece.append(Vector2.from_angle(lerpf(start, end, s / 6.0)) * outer)
		for s in 7:
			piece.append(Vector2.from_angle(lerpf(end, start, s / 6.0)) * inner)
		_decor.draw_colored_polygon(piece, Color8(160, 30, 35) if k < 3 else Color(0.9, 0.9, 0.85, 0.18))
	_decor.draw_arc(Vector2.ZERO, outer + 6, 0, TAU, 48, Color(0.9, 0.9, 0.85, 0.25), 2.0)
	_decor.draw_set_transform(Vector2.ZERO)
	_centered(middle + Vector2(0, 5), "REVOLUTION", 13, Color(0.92, 0.9, 0.85, 0.5))


# Each member's room. `r` is the room, in pixels; furniture positions match the
# solid tiles set in _build_member_room.

func _tile(r: Rect2, x: float, y: float) -> Vector2:
	return r.position + Vector2(x * T, y * T)


func _draw_big_joe(r: Rect2) -> void:
	_rug(Rect2(_tile(r, 10, 9), Vector2(12 * T, 7 * T)), Color8(150, 30, 35))
	_decor.draw_rect(Rect2(_tile(r, 10, 9) + Vector2(8, 8), Vector2(12 * T - 16, 7 * T - 16)), Color8(200, 160, 50), false, 1.0)
	# A JUSTICE banner and crossed lances on the wall.
	_poster(_tile(r, 13, 0) + Vector2(0, 8), Vector2(6 * T, 2 * T - 6), Color8(150, 25, 30), "JUSTICE", Color8(250, 220, 120))
	for side in [-1.0, 1.0]:
		var base := _tile(r, 21, 2) + Vector2(10, 4)
		_decor.draw_line(base + Vector2(side * 30, 10), base + Vector2(-side * 20, -30), Color8(200, 205, 215), 3.0)
	# The armor stand.
	var armor := _tile(r, 25, 3)
	_block(Rect2(armor + Vector2(10, 2), Vector2(20, 14)), Color8(190, 195, 205))
	_decor.draw_rect(Rect2(armor + Vector2(14, 7), Vector2(12, 3)), Color8(60, 60, 70))
	_block(Rect2(armor + Vector2(6, 16), Vector2(28, 22)), Color8(175, 180, 192))
	_decor.draw_rect(Rect2(armor + Vector2(16, -4), Vector2(8, 6)), Color8(200, 30, 30))
	# Trophy shelf.
	_block(Rect2(_tile(r, 7, 2) + Vector2(0, 12), Vector2(5 * T, 10)), Color8(100, 70, 45))
	for k in 4:
		_decor.draw_rect(Rect2(_tile(r, 7, 2) + Vector2(8 + k * 22, 0), Vector2(10, 12)), Color8(230, 190, 60))
	_bed(_tile(r, 3, 4), 2 * T, 3 * T, Color8(150, 30, 35))
	# The sparring mannequin.
	var dummy := _tile(r, 21, 15)
	_decor.draw_rect(Rect2(dummy + Vector2(18, 10), Vector2(4, 30)), Color8(110, 80, 50))
	_block(Rect2(dummy + Vector2(8, 0), Vector2(24, 20)), Color8(200, 170, 110))


func _draw_eggo(r: Rect2) -> void:
	_rug(Rect2(_tile(r, 8, 9), Vector2(10 * T, 8 * T)), Color8(230, 200, 80))
	# Fairy lights across the wall.
	for k in 30:
		var at := _tile(r, 1, 1) + Vector2(k * 20 + 6, 10 + sin(k * 0.8) * 5)
		var on := int(_time * 2.0 + k) % 3 != 0
		_decor.draw_circle(at, 2.5, Color(1.0, 0.85, 0.4) if on else Color(0.5, 0.45, 0.3))
	_poster(_tile(r, 12, 0) + Vector2(0, 10), Vector2(3 * T, 2 * T - 8), Color8(250, 245, 230), "EGG", Color8(220, 160, 30))
	_poster(_tile(r, 16, 0) + Vector2(0, 10), Vector2(3 * T, 2 * T - 8), Color8(250, 245, 230), "CELLENT", Color8(220, 160, 30))
	# The egg beanbag.
	var egg := _tile(r, 4, 5) + Vector2(30, 30)
	_decor.draw_set_transform(egg, 0.0, Vector2(1.0, 1.15))
	_decor.draw_circle(Vector2.ZERO, 28, Color8(245, 240, 225))
	_decor.draw_circle(Vector2(-6, -8), 10, Color8(255, 255, 250))
	_decor.draw_set_transform(Vector2.ZERO)
	# The bunny hutch, with Toast inside.
	var hutch := Rect2(_tile(r, 22, 4), Vector2(4 * T, 2 * T))
	_block(hutch, Color8(150, 110, 70))
	for k in 8:
		_decor.draw_line(hutch.position + Vector2(6 + k * 10, 4), hutch.position + Vector2(6 + k * 10, hutch.size.y - 4), Color8(200, 200, 200), 1.0)
	var toast := hutch.position + Vector2(44 + sin(_time * 1.5) * 8, 28)
	_decor.draw_circle(toast, 7, Color8(240, 240, 245))
	_decor.draw_rect(Rect2(toast + Vector2(2, -14), Vector2(2, 8)), Color8(240, 240, 245))
	_decor.draw_rect(Rect2(toast + Vector2(5, -13), Vector2(2, 7)), Color8(240, 240, 245))
	# The fridge.
	_block(Rect2(_tile(r, 28, 2) + Vector2(0, 8), Vector2(2 * T, 3 * T - 8)), Color8(225, 225, 220))
	_text(_tile(r, 28, 3) + Vector2(4, 16), "EGGS", 8, Color8(200, 140, 20))
	_text(_tile(r, 28, 3) + Vector2(4, 26), "ONLY", 8, Color8(200, 140, 20))
	_bed(_tile(r, 22, 16), 3 * T, 2 * T, Color8(240, 200, 70))


func _draw_nassan(r: Rect2) -> void:
	# The corkboard: the whole top wall, covered in notes, with red string between pins.
	var board := Rect2(_tile(r, 7, 0) + Vector2(0, 6), Vector2(18 * T, 2 * T + 6))
	_decor.draw_rect(board, Color8(170, 125, 80))
	_decor.draw_rect(board, Color8(110, 75, 45), false, 3.0)
	var pins: Array[Vector2] = []
	for k in 12:
		var pin := board.position + Vector2(16 + (k * 61) % int(board.size.x - 30), 8 + (k * 17) % int(board.size.y - 14))
		pins.append(pin)
		_decor.draw_rect(Rect2(pin - Vector2(7, 4), Vector2(14, 10)), Color8(245, 240, 220))
	for k in pins.size() - 1:
		_decor.draw_line(pins[k], pins[(k * 5 + 3) % pins.size()], Color8(200, 30, 30), 1.0)
	for pin in pins:
		_decor.draw_circle(pin, 2, Color8(220, 40, 40))
	# Desk with a lamp and a stack of maps.
	_block(Rect2(_tile(r, 12, 6), Vector2(7 * T, 2 * T)), Color8(90, 65, 45))
	_decor.draw_rect(Rect2(_tile(r, 13, 6) + Vector2(0, 6), Vector2(30, 20)), Color8(230, 220, 190))
	_decor.draw_circle(_tile(r, 17, 6) + Vector2(10, 8), 6, Color8(240, 210, 90))
	# Filing cabinets.
	for k in 3:
		_block(Rect2(_tile(r, 3, 3 + k), Vector2(2 * T, T)), Color8(120, 125, 130))
		_decor.draw_rect(Rect2(_tile(r, 3, 3 + k) + Vector2(15, 8), Vector2(10, 3)), Color8(80, 80, 85))
	# The radio.
	_block(Rect2(_tile(r, 26, 3), Vector2(3 * T, 2 * T)), Color8(70, 60, 50))
	_block(Rect2(_tile(r, 26, 3) + Vector2(10, 4), Vector2(36, 18)), Color8(50, 55, 50))
	_decor.draw_line(_tile(r, 28, 3) + Vector2(6, 4), _tile(r, 28, 3) + Vector2(18, -20), Color8(180, 180, 180), 1.0)
	_bed(_tile(r, 3, 17), 2 * T, 3 * T, Color8(40, 45, 70))


func _draw_nat(r: Rect2) -> void:
	_rug(Rect2(_tile(r, 10, 12), Vector2(10 * T, 6 * T)), Color8(70, 100, 70))
	for x in [2, 7, 23, 27]:
		_bookshelf(_tile(r, x, 0) + Vector2(0, 6), 3 * T, 3 * T - 6)
	_bookshelf(_tile(r, 2, 10), T, 8 * T)
	# The old book on its stand, glowing faintly. The last page is torn out.
	var stand := _tile(r, 14, 8)
	_block(Rect2(stand + Vector2(12, 16), Vector2(16, 24)), Color8(90, 60, 40))
	_block(Rect2(stand + Vector2(0, 4), Vector2(40, 16)), Color8(120, 40, 40))
	_decor.draw_rect(Rect2(stand + Vector2(3, 6), Vector2(16, 12)), Color8(235, 225, 195))
	_decor.draw_colored_polygon(PackedVector2Array([stand + Vector2(21, 6), stand + Vector2(37, 6), stand + Vector2(33, 12), stand + Vector2(37, 18), stand + Vector2(21, 18)]), Color8(235, 225, 195))
	_decor.draw_circle(stand + Vector2(20, 12), 22, Color(1.0, 0.9, 0.5, 0.06 + 0.04 * sin(_time * 2.0)))
	# An armchair and a candle.
	_block(Rect2(_tile(r, 22, 12), Vector2(2 * T, 2 * T)), Color8(120, 70, 50))
	var flame := _tile(r, 25, 13) + Vector2(4, -4)
	_decor.draw_rect(Rect2(flame + Vector2(-2, 4), Vector2(4, 8)), Color8(235, 230, 210))
	_decor.draw_circle(flame + Vector2(0, sin(_time * 9.0)), 2.5, Color8(255, 200, 80))


func _draw_wethan(r: Rect2) -> void:
	# Scorched floor around the tesla coil, and the coil, sparking.
	var coil := _tile(r, 22, 5) + Vector2(30, 40)
	_decor.draw_circle(coil + Vector2(0, 14), 46, Color(0.05, 0.05, 0.08, 0.35))
	_block(Rect2(coil + Vector2(-18, 0), Vector2(36, 18)), Color8(70, 70, 80))
	for k in 6:
		_decor.draw_rect(Rect2(coil + Vector2(-8 + k * 0.5, -6 - k * 7), Vector2(16 - k, 6)), Color8(190, 120, 60) if k % 2 == 0 else Color8(160, 95, 45))
	_decor.draw_circle(coil + Vector2(0, -48), 12, Color8(200, 205, 215))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_time * 12.0)
	for bolt in 3:
		var points := PackedVector2Array([coil + Vector2(0, -48)])
		var dir := Vector2.from_angle(rng.randf() * TAU)
		for k in 4:
			points.append(points[-1] + dir * 9.0 + Vector2(rng.randf_range(-6, 6), rng.randf_range(-6, 6)))
		_decor.draw_polyline(points, Color(0.5, 0.85, 1.0, 0.9), 2.0)
	# The workbench, with tools and a builders club hat.
	_block(Rect2(_tile(r, 3, 4), Vector2(7 * T, 2 * T)), Color8(120, 90, 60))
	_decor.draw_rect(Rect2(_tile(r, 4, 4) + Vector2(4, 6), Vector2(20, 5)), Color8(150, 150, 160))
	_decor.draw_rect(Rect2(_tile(r, 6, 4) + Vector2(2, 4), Vector2(6, 16)), Color8(200, 50, 40))
	var hat := _tile(r, 8, 4) + Vector2(10, 18)
	_decor.draw_rect(Rect2(hat + Vector2(-12, 0), Vector2(24, 4)), Color8(230, 190, 40))
	_decor.draw_rect(Rect2(hat + Vector2(-8, -10), Vector2(16, 10)), Color8(25, 25, 28))
	_decor.draw_rect(Rect2(hat + Vector2(-2, -10), Vector2(4, 10)), Color8(230, 190, 40))
	_poster(_tile(r, 12, 0) + Vector2(0, 10), Vector2(4 * T, 2 * T - 8), Color8(30, 30, 40), "KING ME!!!", Color8(255, 220, 60))
	# The checkers table.
	var table := Rect2(_tile(r, 18, 15), Vector2(3 * T, 2 * T))
	_block(table, Color8(110, 80, 50))
	for k in 16:
		_decor.draw_rect(Rect2(table.position + Vector2(6 + (k % 4) * 12, 6 + (k / 4) * 7), Vector2(12, 7)), Color8(200, 40, 40) if (k + k / 4) % 2 == 0 else Color8(30, 30, 30))
	_bed(_tile(r, 4, 16), 2 * T, 3 * T, Color8(240, 200, 40))


func _draw_ronin(r: Rect2) -> void:
	# Stars painted all over the top wall, twinkling.
	for k in 40:
		var at := r.position + Vector2(10 + (k * 97) % int(r.size.x - 20), 6 + (k * 31) % (2 * T + 10))
		var twinkle := 0.5 + 0.5 * sin(_time * 2.0 + k * 1.3)
		_decor.draw_rect(Rect2(at, Vector2(2, 2)), Color(1.0, 0.95, 0.75, 0.4 + 0.6 * twinkle))
	# Scorch marks on the floor.
	for spot in [Vector2(9, 9), Vector2(13, 16), Vector2(19, 8)]:
		_decor.draw_circle(_tile(r, spot.x, spot.y), 14, Color(0.08, 0.05, 0.04, 0.45))
	# The amp (smoking) and the guitar on its stand.
	var amp := Rect2(_tile(r, 5, 6), Vector2(2 * T, 2 * T))
	_block(amp, Color8(40, 40, 42))
	_decor.draw_circle(amp.get_center(), 12, Color8(70, 70, 72))
	for k in 3:
		var rise := fmod(_time * 0.6 + k * 0.33, 1.0)
		_decor.draw_circle(amp.position + Vector2(30 + sin(_time + k) * 6, -rise * 30), 4 + rise * 4, Color(0.5, 0.5, 0.5, 0.4 * (1.0 - rise)))
	var guitar := _tile(r, 8, 6) + Vector2(10, 10)
	_decor.draw_line(guitar, guitar + Vector2(0, -26), Color8(90, 60, 40), 3.0)
	_decor.draw_circle(guitar + Vector2(0, 6), 9, Color8(200, 60, 30))
	_decor.draw_circle(guitar + Vector2(0, 6), 3, Color8(30, 20, 15))
	# The telescope, pointed at the air vent.
	var scope := _tile(r, 24, 5) + Vector2(20, 50)
	_decor.draw_line(scope, scope + Vector2(-12, 14), Color8(60, 60, 60), 2.0)
	_decor.draw_line(scope, scope + Vector2(12, 14), Color8(60, 60, 60), 2.0)
	_decor.draw_line(scope + Vector2(-10, -14), scope + Vector2(14, -34), Color8(200, 190, 170), 7.0)
	_decor.draw_rect(Rect2(_tile(r, 23, 1) + Vector2(0, 8), Vector2(3 * T, 16)), Color8(50, 50, 55))
	for k in 5:
		_decor.draw_line(_tile(r, 23, 1) + Vector2(4 + k * 12, 10), _tile(r, 23, 1) + Vector2(4 + k * 12, 22), Color8(80, 80, 85), 2.0)
	# The fire extinguisher (Nassan's idea).
	_block(Rect2(_tile(r, 28, 3) + Vector2(4, 0), Vector2(12, 34)), Color8(200, 30, 30))
	_bed(_tile(r, 22, 16), 3 * T, 2 * T, Color8(230, 110, 30))


func _draw_supreme(r: Rect2) -> void:
	# Seven monitors, each with a different graph, all going up.
	_block(Rect2(_tile(r, 8, 3), Vector2(15 * T, 2 * T)), Color8(60, 60, 66))
	for k in 7:
		var screen := Rect2(_tile(r, 8, 1) + Vector2(6 + k * 42, 4), Vector2(36, 26))
		_decor.draw_rect(screen, Color8(30, 30, 36))
		_decor.draw_rect(screen.grow(-2), Color8(20, 45, 70))
		var points := PackedVector2Array()
		for p in 6:
			points.append(screen.position + Vector2(4 + p * 5.5, 20 - p * 2.5 - (sin(_time * 2.0 + p + k) + 1.0) * 2.0))
		_decor.draw_polyline(points, [Color8(90, 220, 120), Color8(250, 210, 60), Color8(120, 180, 255)][k % 3], 1.5)
	# A rolling chair.
	_decor.draw_circle(_tile(r, 15, 6) + Vector2(10, 4), 10, Color8(40, 40, 46))
	# Boxes of printouts.
	for k in 4:
		_block(Rect2(_tile(r, 3 + (k % 2) * 2, 15 + (k / 2)), Vector2(2 * T - 2, T - 2)), Color8(170, 140, 100))
		_text(_tile(r, 3 + (k % 2) * 2, 15 + (k / 2)) + Vector2(3, 13), "DATA", 7, Color8(80, 60, 40))
	_poster(_tile(r, 25, 0) + Vector2(0, 10), Vector2(5 * T, 2 * T - 8), Color8(250, 240, 220), "FACTS > FEELINGS", Color8(40, 40, 120))
	_bed(_tile(r, 25, 16), 3 * T, 2 * T, Color8(240, 200, 60))


func _draw_crayola(r: Rect2) -> void:
	# Crayon scribbles all over the walls.
	var colors := [Color8(230, 60, 60), Color8(250, 170, 40), Color8(80, 190, 90), Color8(70, 130, 230), Color8(180, 90, 220), Color8(250, 120, 180)]
	for k in 14:
		var at := r.position + Vector2(20 + (k * 83) % int(r.size.x - 60), 10 + (k * 13) % 36)
		var points := PackedVector2Array()
		for p in 6:
			points.append(at + Vector2(p * 6, sin(p * 1.7 + k) * 6))
		_decor.draw_polyline(points, colors[k % colors.size()], 2.0)
	_rug(Rect2(_tile(r, 14, 9), Vector2(12 * T, 8 * T)), Color8(90, 150, 210))
	# The easel, with a drawing of the whole Corps (stick figures).
	_block(Rect2(_tile(r, 5, 5), Vector2(2 * T, 3 * T)), Color8(250, 248, 240))
	for k in 5:
		var fig := _tile(r, 5, 5) + Vector2(6 + k * 7, 30)
		_decor.draw_circle(fig, 2, colors[k])
		_decor.draw_line(fig, fig + Vector2(0, 8), colors[k], 1.0)
	# The card table, with a game in progress.
	_block(Rect2(_tile(r, 18, 11), Vector2(4 * T, 3 * T)), Color8(40, 110, 60))
	for k in 6:
		_decor.draw_rect(Rect2(_tile(r, 18, 11) + Vector2(8 + k * 12, 18 + (k % 2) * 8), Vector2(10, 14)), Color8(250, 250, 245))
		_decor.draw_rect(Rect2(_tile(r, 18, 11) + Vector2(11 + k * 12, 22 + (k % 2) * 8), Vector2(4, 4)), Color8(210, 40, 50) if k % 2 == 0 else Color8(30, 30, 30))
	# The pool float (a duck).
	var duck := _tile(r, 25, 4) + Vector2(30, 20)
	_decor.draw_arc(duck, 18, 0, TAU, 20, Color8(250, 210, 50), 10.0)
	_decor.draw_circle(duck + Vector2(14, -16), 7, Color8(250, 210, 50))
	_decor.draw_rect(Rect2(duck + Vector2(19, -17), Vector2(6, 3)), Color8(240, 130, 30))
	_bed(_tile(r, 3, 17), 3 * T, 2 * T, Color8(250, 140, 190))


func _draw_rooster(r: Rect2) -> void:
	# Half the room white, half black. DUALITY.
	var floor_rect := Rect2(_tile(r, 1, 3), Vector2(30 * T, 20 * T))
	_decor.draw_rect(Rect2(floor_rect.position, Vector2(floor_rect.size.x / 2, floor_rect.size.y)), Color(0.92, 0.92, 0.9, 0.55))
	_decor.draw_rect(Rect2(floor_rect.position + Vector2(floor_rect.size.x / 2, 0), Vector2(floor_rect.size.x / 2, floor_rect.size.y)), Color(0.05, 0.05, 0.06, 0.55))
	_poster(_tile(r, 4, 0) + Vector2(0, 10), Vector2(5 * T, 2 * T - 8), Color8(20, 20, 22), "DUALITY", Color8(245, 245, 245))
	_poster(_tile(r, 20, 0) + Vector2(0, 10), Vector2(5 * T, 2 * T - 8), Color8(245, 245, 245), "#1 ROOSTER", Color8(20, 20, 22))
	# The throne: red velvet and gold, on a little platform.
	var throne := _tile(r, 14, 4)
	_block(Rect2(throne + Vector2(-6, 44), Vector2(72, 18)), Color8(150, 30, 40))
	_block(Rect2(throne + Vector2(4, -6), Vector2(52, 52)), Color8(210, 170, 50))
	_decor.draw_rect(Rect2(throne + Vector2(12, 4), Vector2(36, 36)), Color8(170, 25, 40))
	for k in 3:
		_decor.draw_colored_polygon(PackedVector2Array([throne + Vector2(10 + k * 18, -6), throne + Vector2(18 + k * 18, -18), throne + Vector2(26 + k * 18, -6)]), Color8(230, 190, 60))
	# A mirror (for admiring himself).
	_block(Rect2(_tile(r, 26, 3), Vector2(2 * T, 3 * T)), Color8(200, 170, 60))
	_decor.draw_rect(Rect2(_tile(r, 26, 3) + Vector2(4, 4), Vector2(2 * T - 8, 3 * T - 8)), Color8(190, 215, 230))
	_decor.draw_line(_tile(r, 26, 3) + Vector2(8, 10), _tile(r, 26, 3) + Vector2(18, 30), Color(1, 1, 1, 0.6), 2.0)
	# The desk with the roast notebook.
	_block(Rect2(_tile(r, 4, 12), Vector2(4 * T, 2 * T)), Color8(40, 40, 44))
	_decor.draw_rect(Rect2(_tile(r, 5, 12) + Vector2(0, 8), Vector2(24, 18)), Color8(245, 245, 240))
	_text(_tile(r, 5, 12) + Vector2(2, 20), "ROASTS", 6, Color8(200, 40, 40))
	_bed(_tile(r, 24, 16), 3 * T, 2 * T, Color8(30, 30, 34))


## MuffinMage's Kitchen: a grill, a fish tank (the fish is named Burger), and a
## SALMON BURGER FRIDAY poster.
func _draw_muffinmage(r: Rect2) -> void:
	var grill := Rect2(_tile(r, 4, 4), Vector2(4 * T, 2 * T))
	_block(grill, Color8(50, 50, 56))
	for k in 6:
		_decor.draw_line(grill.position + Vector2(6 + k * 12, 8), grill.position + Vector2(6 + k * 12, 32), Color8(120, 120, 128), 2.0)
	_decor.draw_rect(Rect2(grill.position + Vector2(16, 10), Vector2(24, 8)), Color8(230, 140, 110))
	_decor.draw_rect(Rect2(grill.position + Vector2(14, 8), Vector2(28, 3)), Color8(215, 165, 80))
	var tank := Rect2(_tile(r, 23, 3), Vector2(6 * T, 2 * T))
	_block(tank, Color8(60, 60, 70))
	_decor.draw_rect(tank.grow(-4), Color8(70, 140, 210))
	var swim := sin(_time * 1.3) * 30.0
	var fish := tank.get_center() + Vector2(swim, 0)
	_decor.draw_circle(fish, 5, Color8(245, 135, 105))
	var tail := -1.0 if cos(_time * 1.3) > 0.0 else 1.0
	_decor.draw_colored_polygon(PackedVector2Array([fish + Vector2(5 * tail, 0), fish + Vector2(11 * tail, -4), fish + Vector2(11 * tail, 4)]), Color8(245, 135, 105))
	_centered(tank.position + Vector2(tank.size.x / 2, -3), "BURGER", 9, Color8(240, 240, 240))
	var poster := Rect2(_tile(r, 12, 0) + Vector2(0, 10), Vector2(6 * T, 2 * T))
	_decor.draw_rect(poster, Color8(240, 200, 120))
	_centered(poster.position + Vector2(poster.size.x / 2, 16), "SALMON BURGER", 11, Color8(180, 60, 40))
	_centered(poster.position + Vector2(poster.size.x / 2, 30), "FRIDAY", 11, Color8(180, 60, 40))
	_bed(_tile(r, 25, 16), 3 * T, 2 * T, Color8(225, 110, 50))


## Sansworth's Garage: an empty parking spot (reserved), a pegboard of keys that
## don't open anything, a steering wheel on the wall, and a race car bed.
func _draw_sansworth(r: Rect2) -> void:
	var spot := Rect2(_tile(r, 12, 8), Vector2(8 * T, 9 * T))
	for side in [0.0, spot.size.x]:
		_decor.draw_line(spot.position + Vector2(side, 0), spot.position + Vector2(side, spot.size.y), Color8(240, 210, 60), 3.0)
	_decor.draw_line(spot.position, spot.position + Vector2(spot.size.x, 0), Color8(240, 210, 60), 3.0)
	_centered(spot.position + Vector2(spot.size.x / 2, 22), "RESERVED", 12, Color8(240, 210, 60))
	_centered(spot.position + Vector2(spot.size.x / 2, 36), "SANSWORTH", 10, Color8(240, 210, 60))
	var board := Rect2(_tile(r, 4, 3), Vector2(8 * T, T))
	_block(board, Color8(170, 130, 90))
	for k in 16:
		var hook := board.position + Vector2(8 + k * 9.5, 8)
		_decor.draw_circle(hook, 2, Color8(210, 190, 80) if k % 3 else Color8(190, 190, 200))
	var wheel := _tile(r, 24, 3) + Vector2(T, T)
	_decor.draw_arc(wheel, 14, 0, TAU, 20, Color8(40, 40, 46), 4.0)
	_decor.draw_line(wheel + Vector2(-14, 0), wheel + Vector2(14, 0), Color8(40, 40, 46), 3.0)
	_decor.draw_line(wheel, wheel + Vector2(0, 14), Color8(40, 40, 46), 3.0)
	var car := Rect2(_tile(r, 24, 15), Vector2(4 * T, 3 * T))
	_block(car, Color8(210, 40, 40))
	_decor.draw_rect(Rect2(car.position + Vector2(8, 6), Vector2(car.size.x - 16, 14)), Color8(235, 235, 230))
	for wheel_x in [10.0, car.size.x - 18.0]:
		_decor.draw_rect(Rect2(car.position + Vector2(wheel_x, car.size.y - 8), Vector2(10, 8)), Color8(20, 20, 24))


func _draw_agent(r: Rect2) -> void:
	# A chalkboard of probability math.
	var board := Rect2(_tile(r, 4, 0) + Vector2(0, 8), Vector2(14 * T, 2 * T + 2))
	_decor.draw_rect(board, Color8(40, 70, 55))
	_decor.draw_rect(board, Color8(110, 80, 50), false, 3.0)
	var math := ["P(win) = 0.97", "12 - 3 = 9", "E[x] > you", "4. Next."]
	for k in math.size():
		_text(board.position + Vector2(10 + (k % 2) * 140, 18 + (k / 2) * 18), math[k], 11, Color8(230, 235, 225))
	# The dartboard, with every dart in the bullseye.
	var dart := _tile(r, 24, 1) + Vector2(10, 18)
	_decor.draw_circle(dart, 16, Color8(30, 30, 30))
	_decor.draw_circle(dart, 12, Color8(230, 220, 190))
	_decor.draw_circle(dart, 8, Color8(200, 40, 40))
	_decor.draw_circle(dart, 3, Color8(40, 140, 60))
	for k in 3:
		_decor.draw_line(dart + Vector2(-1 + k, -1), dart + Vector2(-8 + k * 4, -12), Color8(250, 250, 250), 1.5)
	# The chess table, mid-game.
	var table := Rect2(_tile(r, 10, 6), Vector2(3 * T, 3 * T))
	_block(table, Color8(90, 60, 40))
	for k in 36:
		_decor.draw_rect(Rect2(table.position + Vector2(6 + (k % 6) * 8, 6 + (k / 6) * 8), Vector2(8, 8)), Color8(235, 225, 200) if (k + k / 6) % 2 == 0 else Color8(60, 45, 30))
	# A pair of sunglasses on a little display stand.
	var shades := _tile(r, 25, 4) + Vector2(20, 16)
	_block(Rect2(shades + Vector2(-18, 6), Vector2(36, 14)), Color8(60, 60, 70))
	_decor.draw_rect(Rect2(shades + Vector2(-14, -4), Vector2(12, 7)), Color8(20, 20, 24))
	_decor.draw_rect(Rect2(shades + Vector2(2, -4), Vector2(12, 7)), Color8(20, 20, 24))
	_decor.draw_line(shades + Vector2(-2, -2), shades + Vector2(2, -2), Color8(20, 20, 24), 2.0)
	_bed(_tile(r, 3, 16), 3 * T, 2 * T, Color8(110, 80, 170))
