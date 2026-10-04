extends Area
## Westview High School, after midnight: Chapter 1's dungeon. Fragment 2 has
## twisted the school, and it's hiding inside.
##
## The map has four rooms, each its own rectangle on one big tile grid:
##   Outside      the front of the school at night (SAVE point, front doors)
##   Hallway      loops back on itself until Elric opens the humming locker
##   Classroom    ring the three bells in the order on the chalkboard to unlock the gym
##   Gym          SAVE point, then the boss: Wally Wolverine, Westview's mascot, with fragment 2 inside
##
## Story flags (in Game.flags):
##   ww_arrived, ww_inside, ww_loops (a count), loop_broken, ww_classroom,
##   read_board, bells_solved, ww_gym, mascot_started, has_fragment_2

const SCENE := "res://scenes/westview.tscn"
const HILLTOP_SCENE := "res://scenes/hilltop.tscn"
const T := Room.TILE

# The four rooms, in tiles: Rect2(x, y, width, height). Each is at least one
# screen big (32 x 24 tiles) so the camera can stay inside it.
const OUTSIDE := Rect2i(0, 0, 32, 24)
const HALLWAY := Rect2i(40, 0, 80, 24)
const CLASSROOM := Rect2i(40, 30, 32, 24)
const GYM := Rect2i(80, 30, 40, 24)

## Where Elric arrives from the PQ Mall (left end of the sidewalk outside).
const ENTRY := Vector2(50, 370)

# Spots Elric appears at when going through doors.
const HALL_START := Vector2(46 * T, 12 * T + 10)
const OUTSIDE_FRONT_DOOR := Vector2(16 * T, 11 * T + 10)
const CLASSROOM_START := Vector2(47 * T, 47 * T)
const HALL_END_DOOR := Vector2(114 * T + 10, 10 * T)
const GYM_START := Vector2(84 * T, 42 * T + 10)
const CLASSROOM_GYM_DOOR := Vector2(65 * T, 42 * T)

## In the hallway, walking past this x (before the loop is broken) sends you back to the start.
const LOOP_X := 108 * T
const LOOP_LENGTH := (108 - 47) * T

## The order the bells must be rung in (1st, 2nd, 3rd period).
const BELL_ORDER := [3, 1, 2]

var hop: Character
var mascot: Character
var _decor: Node2D
var _font: Font
var _bells_rung: Array = []
var _glow_time: float = 0.0


func _ready() -> void:
	rooms.assign([_px(OUTSIDE), _px(HALLWAY), _px(CLASSROOM), _px(GYM)])
	setup_area(ENTRY)
	Game.play_music("westview")
	_font = ThemeDB.fallback_font

	# Night: everything in the world is drawn darker and bluer. (The text box and
	# menus are on their own layers, so they stay bright.)
	var night := CanvasModulate.new()
	night.color = Color(0.5, 0.5, 0.72)
	add_child(night)

	_add_decor()
	_place_people()
	_place_hotspots()
	fit_camera_to_room()
	_start.call_deferred()


static func _px(r: Rect2i) -> Rect2:
	return Rect2(r.position * T, r.size * T)


# --- The map --------------------------------------------------------------

func build_map() -> void:
	room.setup(120, 54, Room.VOID)
	_build_outside()
	_build_hallway()
	_build_classroom()
	_build_gym()


func _build_outside() -> void:
	room.fill(0, 0, 32, 24, Room.GRASS)
	room.fill(0, 0, 32, 1, Room.TREE)
	room.fill(0, 1, 1, 16, Room.TREE)
	room.fill(31, 1, 1, 16, Room.TREE)
	# The school, with its front doors in the middle.
	room.fill(4, 1, 24, 2, Room.ROOF)
	room.fill(4, 3, 24, 7, Room.WALL)
	for x in range(6, 27, 3):
		room.set_tile(x, 4, Room.WINDOW)
		room.set_tile(x, 7, Room.WINDOW)
	room.fill(15, 8, 2, 2, Room.DOOR)
	# Front walk, lawn and trees, sidewalk and road.
	room.fill(1, 10, 30, 2, Room.SIDEWALK)
	room.fill(14, 12, 4, 5, Room.SIDEWALK)
	for spot in [Vector2i(5, 13), Vector2i(10, 15), Vector2i(22, 14), Vector2i(27, 13)]:
		room.set_tile(spot.x, spot.y, Room.TREE)
	room.fill(0, 17, 32, 2, Room.SIDEWALK)
	room.fill(0, 19, 32, 5, Room.ROAD)
	room.fill(0, 21, 32, 1, Room.ROAD_LINE)


func _build_hallway() -> void:
	# A long corridor: wall and lockers along the top, floor, wall along the bottom.
	room.fill(40, 7, 80, 1, Room.INTERIOR_WALL)
	room.fill(40, 8, 80, 1, Room.LOCKER)
	room.fill(40, 9, 80, 6, Room.HALL_FLOOR)
	room.fill(40, 15, 80, 1, Room.INTERIOR_WALL)
	room.fill(40, 8, 1, 7, Room.INTERIOR_WALL)
	room.fill(119, 8, 1, 7, Room.INTERIOR_WALL)
	# The front doors (back outside) and the classroom door at the far end.
	room.fill(41, 8, 2, 1, Room.DOOR)
	room.fill(114, 8, 2, 1, Room.DOOR)


func _build_classroom() -> void:
	room.fill(44, 34, 24, 2, Room.INTERIOR_WALL)
	room.fill(44, 36, 24, 13, Room.HALL_FLOOR)
	room.fill(44, 49, 24, 1, Room.INTERIOR_WALL)
	room.fill(44, 34, 1, 16, Room.INTERIOR_WALL)
	room.fill(67, 34, 1, 16, Room.INTERIOR_WALL)
	room.fill(48, 35, 10, 1, Room.CHALKBOARD)
	for y in range(39, 46, 3):
		for x in range(49, 63, 3):
			room.set_tile(x, y, Room.DESK)
	# Door back to the hallway (bottom left) and to the gym (right wall).
	room.fill(46, 49, 2, 1, Room.DOOR)
	room.fill(67, 41, 1, 2, Room.DOOR)


func _build_gym() -> void:
	room.fill(81, 31, 38, 22, Room.INTERIOR_WALL)
	room.fill(82, 32, 36, 2, Room.BLEACHERS)
	room.fill(82, 34, 36, 18, Room.GYM_FLOOR)
	room.fill(100, 34, 1, 18, Room.GYM_LINE)
	# Door back to the classroom (left) and the emergency exit (right).
	room.fill(81, 41, 1, 2, Room.DOOR)
	room.fill(118, 41, 1, 2, Room.DOOR)


## Things drawn on top of the map: posters, bell labels, the humming locker, the gym circle.
func _add_decor() -> void:
	_decor = Node2D.new()
	add_child(_decor)
	_decor.draw.connect(_draw_decor)
	# Drawn just above the ground but below everyone walking around.
	move_child(_decor, world.get_index())


func _process(delta: float) -> void:
	_glow_time += delta
	_decor.queue_redraw()


func _draw_decor() -> void:
	# Hallway posters on the wall above the lockers. Their message changes as you loop.
	var loops := int(Game.flags.get("ww_loops", 0))
	var poster_text: String = ["NO RUNNING", "TURN BACK", "TURN BACK!!", "YOU'VE BEEN HERE"][mini(loops, 3)]
	for x in [55, 75, 95]:
		var r := Rect2(x * T - 18, 7 * T + 2, 56, 15)
		_decor.draw_rect(r, Color8(235, 225, 160))
		_decor.draw_string(_font, r.position + Vector2(3, 11), poster_text, HORIZONTAL_ALIGNMENT_LEFT, 50, 8, Color8(150, 30, 30))

	# The humming locker glows faintly red until it's been opened.
	if not flag("loop_broken"):
		var pulse := 0.25 + 0.2 * sin(_glow_time * 3.0)
		_decor.draw_rect(Rect2(80 * T, 8 * T, T, T), Color(1, 0.15, 0.2, pulse))

	# Bell labels on the classroom wall.
	for i in 3:
		var bell := Vector2((60 + i * 2) * T + 10, 35 * T + 10)
		_decor.draw_circle(bell, 7, Color8(200, 170, 60))
		_decor.draw_circle(bell + Vector2(0, 2), 3, Color8(120, 95, 30))
		_decor.draw_string(_font, bell + Vector2(-8, -10), ["1ST", "2ND", "3RD"][i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

	# The center circle on the gym floor.
	_decor.draw_arc(Vector2(100 * T + 10, 43 * T), 50, 0, TAU, 32, Color(1, 1, 1, 0.8), 2.0)


# --- People and things ----------------------------------------------------

func _place_people() -> void:
	hop = Cast.make("Hop")
	add_character(hop, player.position + Vector2(-20, -4))
	hop.follow = player

	add_roamer("pop_quiz", "pop_quiz", Vector2(88 * T, 12 * T), Vector2(102 * T, 12 * T))
	add_roamer("hall_pass", "hall_pass", Vector2(50 * T, 47 * T), Vector2(63 * T, 47 * T))

	_add_save_point(Vector2(9 * T, 12 * T + 10), [
		"* (The school looms in the dark.\n*  A streetlight hums nearby.)",
		"* (It fills you with DETERMINATION.)",
	])
	_add_save_point(Vector2(86 * T, 45 * T), [
		"* (The gym smells like floor polish and old popcorn.)",
		"* (Something in here is waiting.\n*  It fills you with DETERMINATION.)",
	])

	if not flag("has_fragment_2"):
		mascot = Cast.make("wally")
		add_character(mascot, Vector2(100 * T + 10, 42 * T))


func _add_save_point(at: Vector2, lines: Array) -> void:
	var star := Character.new().setup(preload("res://art/sprites/save_star.png"), null, false)
	star.glow = true
	star.glow_color = Color(1.0, 1.0, 1.0, 0.55)
	star.on_interact = func() -> void:
		Game.play_sfx("heal")
		Game.heal_party()
		await Game.dialogue.say(lines + ["* (Everyone's HP was restored.)"])
		var choice := await Game.dialogue.ask("* (Save your progress?)", ["Save", "Return"])
		if choice == 0:
			Game.save_game(SCENE, player.position)
			Game.play_sfx("save")
			await Game.dialogue.say(["* (File saved.)"])
	add_character(star, at)


func _place_hotspots() -> void:
	var spots := [
		[Vector2(16 * T, 10 * T - 4), _front_doors],
		[Vector2(42 * T, 9 * T - 4), _back_outside],
		[Vector2(80 * T + 10, 9 * T - 4), _humming_locker],
		[Vector2(114 * T + 20, 9 * T - 4), _into_classroom],
		[Vector2(55 * T + 10, 7 * T + 10), _read_poster],
		[Vector2(75 * T + 10, 7 * T + 10), _read_poster],
		[Vector2(95 * T + 10, 7 * T + 10), _read_poster],
		[Vector2(53 * T, 36 * T - 4), _read_chalkboard],
		[Vector2(47 * T, 49 * T - 4), _back_to_hallway],
		[Vector2(67 * T - 4, 42 * T), _gym_door],
		[Vector2(82 * T - 4, 42 * T), _back_to_classroom],
		[Vector2(118 * T - 4, 42 * T), _emergency_exit],
	]
	for i in 3:
		spots.append([Vector2((60 + i * 2) * T + 10, 36 * T - 4), _ring_bell.bind(i + 1)])
	for spot in spots:
		world.add_child(Hotspot.create(spot[0], spot[1]))


# --- Story ----------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if not is_inside_tree():
		return
	if await _back_from_battle():
		return
	if not flag("ww_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked():
		return
	check_roamers(SCENE)

	# The endless hallway.
	if not flag("loop_broken") and _px(HALLWAY).has_point(player.position) and player.position.x > LOOP_X:
		run_cutscene(_loop_back)
	# Approaching Wally.
	elif mascot and not flag("mascot_started") and _px(GYM).has_point(player.position) and player.position.x > 93 * T:
		run_cutscene(_wake_mascot)


func _back_from_battle() -> bool:
	if Game.battle_result.get("id", "") == "wally":
		await run_cutscene(_after_mascot)
		return true
	var handled := false
	_cutscene_running = true
	Game.busy = true
	handled = await handle_battle_return({
		"pop_quiz": ["* (Pop Quiz floats away, satisfied with its grade.)", "* (Pop Quiz crumples up and blows away.)"],
		"hall_pass": ["* (Hall Pass finally gets where it was going.)", "* (Hall Pass snaps in half. ...Oops.)"],
	})
	Game.busy = false
	_cutscene_running = false
	return handled


func _arrival() -> void:
	await Game.dialogue.say([
		"* (Westview High School. It's past midnight.)",
		{"who": "Hop", "text": "Okay. Breaking into a school at midnight.\nTotally normal Tuesday.", "mood": "smug"},
		"* (Every window is dark. Then one flickers on.\n*  Then off.)",
		{"who": "Hop", "text": "...Did you see that? Tell me you saw that.", "mood": "shocked"},
		{"who": "Hop", "text": "Let's find the fragment and get OUT.\nFast. Like, speedrun it.", "mood": "sad"},
	])
	Game.flags["ww_arrived"] = true


func _front_doors() -> void:
	if not flag("ww_inside"):
		await Game.dialogue.say([
			"* (The front door is unlocked.)",
			"* (It creaks open on its own.)",
			{"who": "Hop", "text": "Oh, cool. Cool cool cool. That's fine.", "mood": "sad"},
		])
	await go_through_door(HALL_START)
	if not flag("ww_inside"):
		Game.flags["ww_inside"] = true
		await Game.dialogue.say([
			"* (A long hallway. Lockers line one wall.)",
			"* (The far end is very... far.)",
			{"who": "Hop", "text": "Nassan said the hallways were longer than they\nshould be. I thought he was being dramatic.", "mood": "shocked"},
		])


func _back_outside() -> void:
	await go_through_door(OUTSIDE_FRONT_DOOR)


func _loop_back() -> void:
	# Seamlessly jump back to the start of the hallway, as if it repeats forever.
	teleport_player(player.position - Vector2(LOOP_LENGTH, 0))
	var loops := int(Game.flags.get("ww_loops", 0)) + 1
	Game.flags["ww_loops"] = loops
	match loops:
		1:
			await Game.dialogue.say([
				"* (...You're back at the start of the hallway?)",
				{"who": "Hop", "text": "Wait. Didn't we just pass that poster?", "mood": "shocked"},
			])
		2:
			await Game.dialogue.say([
				{"who": "Hop", "text": "Okay, we DEFINITELY passed that poster.", "mood": "angry"},
				"* (Somewhere along the lockers, something is humming.\n*  Just like the fragment.)",
			])
		_:
			await Game.dialogue.say([
				{"who": "Hop", "text": "I'm starting to think this hallway\ndoesn't want us to leave.", "mood": "sad"},
				{"who": "Hop", "text": "...Maybe check that humming locker?", "mood": "sad"},
			])


func _read_poster() -> void:
	var loops := int(Game.flags.get("ww_loops", 0))
	var lines: Array = [
		["* (A poster: NO RUNNING IN THE HALLS.)"],
		["* (A poster: TURN BACK.)", "* (...Wasn't this a different poster before?)"],
		["* (A poster: TURN BACK!!)", {"who": "Hop", "text": "Nope. Don't like that.", "mood": "shocked"}],
		["* (A poster: YOU'VE BEEN HERE BEFORE.)", {"who": "Hop", "text": "Yeah. We KNOW.", "mood": "angry"}],
	][mini(loops, 3)]
	await Game.dialogue.say(lines)


func _humming_locker() -> void:
	if flag("loop_broken"):
		await Game.dialogue.say(["* (An open locker. Empty and quiet now.)"])
		return
	await Game.dialogue.say(["* (One locker is humming.\n*  It sounds just like the fragment.)"])
	var choice := await Game.dialogue.ask("* (Open it?)", ["Yes", "No"])
	if choice == 1:
		return
	Game.play_sfx("fragment")
	await Game.dialogue.say([
		"* (You open the locker.)",
		"* (Inside, there's nothing but a faint red glow...\n*  which slowly fades.)",
		"* (Far down the hall, something clicks into place.)",
		{"who": "Hop", "text": "Did the hallway just get... shorter?", "mood": "shocked"},
		{"who": "Hop", "text": "I hate this school. I don't even GO here.", "mood": "angry"},
	])
	Game.flags["loop_broken"] = true


func _into_classroom() -> void:
	await go_through_door(CLASSROOM_START)
	if not flag("ww_classroom"):
		Game.flags["ww_classroom"] = true
		await Game.dialogue.say([
			"* (A classroom. Desks in neat rows.)",
			"* (The chalkboard is covered in writing.)",
			"* (Three bells are mounted on the wall next to it.)",
		])


func _back_to_hallway() -> void:
	await go_through_door(HALL_END_DOOR + Vector2(0, 30))


func _read_chalkboard() -> void:
	Game.flags["read_board"] = true
	await Game.dialogue.say([
		"* (The chalkboard says:)",
		"* ASSEMBLY DAY BELL SCHEDULE\n*   3rd period, then 1st period, then 2nd period.",
		"* (Underneath, someone scribbled:\n*  RING THEM RIGHT OR STAY FOREVER)",
		{"who": "Hop", "text": "...Love that for us.", "mood": "sad"},
	])


func _ring_bell(bell: int) -> void:
	var names := ["", "1ST PERIOD", "2ND PERIOD", "3RD PERIOD"]
	if flag("bells_solved"):
		await Game.dialogue.say(["* (The %s bell. It's quiet now.)" % names[bell]])
		return
	await Game.dialogue.say(["* (A bell marked %s.)" % names[bell]])
	var choice := await Game.dialogue.ask("* (Ring it?)", ["Yes", "No"])
	if choice == 1:
		return

	_bells_rung.append(bell)
	var expected: int = BELL_ORDER[_bells_rung.size() - 1]
	if bell != expected:
		_bells_rung.clear()
		Game.play_sfx("hurt")
		var hint: Array = ["* BZZZZZT."]
		if not flag("read_board"):
			hint.append({"who": "Hop", "text": "Maybe the chalkboard knows the order?", "mood": "sad"})
		else:
			hint.append({"who": "Hop", "text": "That sounded bad. Let's start over.", "mood": "shocked"})
		await Game.dialogue.say(hint)
		return

	Game.play_sfx("select")
	if _bells_rung.size() < BELL_ORDER.size():
		await Game.dialogue.say(["* DING!"])
		return

	Game.play_sfx("save")
	Game.flags["bells_solved"] = true
	await Game.dialogue.say([
		"* RRRRRRING!",
		"* (Across the room, the door clicks open.)",
		{"who": "Hop", "text": "We're basically geniuses.", "mood": "happy"},
	])


func _gym_door() -> void:
	if not flag("bells_solved"):
		await Game.dialogue.say(["* (Locked. A sign on it says:\n*  GYM - AFTER THE BELL.)"])
		return
	await go_through_door(GYM_START)
	if not flag("ww_gym"):
		Game.flags["ww_gym"] = true
		var lines: Array = ["* (The gym. The lights buzz overhead.)"]
		if mascot:
			lines.append_array([
				"* (Westview's mascot, Wally Wolverine, is sitting\n*  at center court. Perfectly still.)",
				{"who": "Hop", "text": "Is that... Wally Wolverine?\nWhy is he just sitting there? It's midnight.", "mood": "shocked"},
			])
		await Game.dialogue.say(lines)


func _back_to_classroom() -> void:
	await go_through_door(CLASSROOM_GYM_DOOR)


func _wake_mascot() -> void:
	Game.flags["mascot_started"] = true
	await Game.dialogue.say(["* (Wally's head turns toward you.\n*  Slowly.)"])
	await mascot.walk_to(mascot.position + Vector2(-30, 0), 40.0)
	await Game.dialogue.say([
		{"who": "Wally", "text": "GO... WOLVERINES."},
		{"who": "Hop", "text": "Nope. Nope nope nope.", "mood": "shocked"},
		{"who": "Wally", "text": "GIMME A W! GIMME AN O!\nGIMME A... FRAGMENT!"},
	])
	await Game.start_battle("wally", SCENE, player.position)


func _after_mascot() -> void:
	var spared: bool = not Game.battle_result.get("spared", []).is_empty()
	Game.battle_result = {}
	if mascot:
		mascot.queue_free()
		mascot = null

	var lines: Array = []
	if spared:
		lines.append("* (Wally gives one last tired cheer.\n*  Then he slumps to the floor. Just a costume now.)")
	else:
		lines.append("* (Wally crumples. The costume tears open.)")
	lines.append_array([
		"* (Something red rolls out of it.)",
		"* (You pick it up. It's warm, and it hums.)",
		"* (You got the second FRAGMENT.)",
		"* (Hop reaches toward it.)",
		"* (For a second, his shadow looks... wrong.)",
		"* (Then it's gone.)",
		{"who": "Hop", "text": "...Sorry. Spaced out. Must be the late night.", "mood": "sad"},
		{"who": "Hop", "text": "Two down, huh?", "mood": "smug"},
		{"who": "Hop", "text": "I mean! Two fragments! Wow! Go team!", "mood": "happy"},
		{"who": "Elric", "text": "...Are you okay?"},
		{"who": "Hop", "text": "Never better! Let's get out of here before\nthe bleachers come alive too.", "mood": "happy"},
		"* (There's an emergency exit on the far wall.)",
	])
	if not spared:
		lines.insert(lines.size() - 1, {"who": "Hop", "text": "...Also, remind me never to be a mascot.", "mood": "shocked"})
	await Game.dialogue.say(lines)
	Game.flags["has_fragment_2"] = true
	Game.flags["fragments"] = 2


func _emergency_exit() -> void:
	if not flag("has_fragment_2"):
		await Game.dialogue.say([
			"* (An emergency exit.)",
			{"who": "Hop", "text": "Tempting. VERY tempting. But the fragment's\nstill in here somewhere.", "mood": "sad"},
		])
		return
	var choice := await Game.dialogue.ask("* (Leave Westview through the emergency exit?)", ["Yes", "No"])
	if choice == 1:
		return
	await Game.dialogue.say([
		{"who": "Hop", "text": "Fresh air! Sweet, sweet, non-haunted air.", "mood": "happy"},
		{"who": "Hop", "text": "Where to next, mysterious traveler?", "mood": "smug"},
	])
	Game.flags["westview_done"] = true
	await Game.change_scene(HILLTOP_SCENE)
