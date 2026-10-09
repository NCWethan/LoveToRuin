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
##
## In Chapter 2 (after the Corps' base: base_arrived), it's daytime: see the
## bottom of this file.

const SCENE := "res://scenes/westview.tscn"
const HILLTOP_SCENE := "res://scenes/hilltop.tscn"
const MALL_SCENE := "res://scenes/pq_mall.tscn"
const NEIGHBORHOOD_SCENE := "res://scenes/hop_house.tscn"
## Where Elric arrives on Westview's street, coming back from the neighborhood.
const FROM_NEIGHBORHOOD := Vector2(32 * T - 30, 370)
## Where Elric arrives at the PQ Mall coming from Westview (by the east exit).
const MALL_FROM_WESTVIEW := Vector2(1030, 535)
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

## Where Wally sits at center court.
const MASCOT_SPOT := Vector2(100 * T + 10, 42 * T)

## The order the bells must be rung in (1st, 2nd, 3rd period).
const BELL_ORDER := [3, 1, 2]

var hop: Character
## Chapter 2: whoever's coming along with Elric (Game.partner()).
var partner: Character
## Chapter 2: the school by day (see the bottom of this file).
var _day: bool = false
var mascot: Character
## Fragment 2, floating over Wally's costume until Elric takes it.
var floating_fragment: Character
var _decor: Node2D
var _font: Font
## The bells rung so far, in order. Kept in the game's flags (not just here), so a
## random fight in the middle of the puzzle doesn't reset it.
var _bells_rung: Array:
	get:
		if not Game.flags.has("bells_rung"):
			Game.flags["bells_rung"] = []
		return Game.flags["bells_rung"]
var _glow_time: float = 0.0


func _ready() -> void:
	_day = Game.daytime()
	rooms.assign([_px(OUTSIDE), _px(HALLWAY), _px(CLASSROOM), _px(GYM)])
	# Random fights in the hallway and the classroom (see westview_battles.gd for how
	# often each one shows up). There are no enemies wandering around: just these.
	# (None by day: it's just a school again.)
	if not _day:
		encounter_zones = [
			[_px(HALLWAY), WestviewBattles.HALLWAY_ENCOUNTERS],
			[_px(CLASSROOM), WestviewBattles.CLASSROOM_ENCOUNTERS],
		]
	setup_area(ENTRY)
	add_wild_encounters(SCENE, _px(OUTSIDE))
	Game.play_music("mt_carmel" if _day else "westview")
	_font = ThemeDB.fallback_font

	# Night: everything in the world is drawn darker and bluer. (The text box and
	# menus are on their own layers, so they stay bright.)
	if not _day:
		var night := CanvasModulate.new()
		night.color = Color(0.5, 0.5, 0.72)
		add_child(night)

	_add_decor()
	_add_marquee_block()
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
	# The trophy case, built into the wall where two lockers would be.
	room.fill(65, 8, 2, 1, Room.INTERIOR_WALL)
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


## Westview's colors on the outside of the school: the name across the wall in gold,
## a big W over the front doors, black-and-gold pennants hanging from the roof, a
## marquee sign on the lawn, and a flagpole with the school flag.
func _draw_school_front() -> void:
	var gold := Color8(225, 175, 45)
	var black := Color8(15, 15, 18)
	var t := _glow_time
	# The school's name on the wall, between the window rows.
	var school_name := "WESTVIEW HIGH SCHOOL"
	var name_width := _font.get_string_size(school_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	var name_at := Vector2(16 * T - name_width / 2, 6 * T + 4)
	_decor.draw_rect(Rect2(name_at + Vector2(-8, -13), Vector2(name_width + 16, 18)), black)
	_decor.draw_string(_font, name_at, school_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, gold)
	# A big W over the front doors.
	var w_at := Vector2(16 * T - 11, 8 * T - 2)
	_decor.draw_string_outline(_font, w_at, "W", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Color.WHITE)
	_decor.draw_string_outline(_font, w_at, "W", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 3, gold)
	_decor.draw_string(_font, w_at, "W", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, black)
	# Pennants along the edge of the roof, swaying a little.
	for i in 11:
		var x := 5 * T + i * 44.0
		var sway := sin(t * 2.0 + i) * 2.0
		var top := Vector2(x, 3 * T)
		var color := gold if i % 2 == 0 else black
		_decor.draw_colored_polygon(PackedVector2Array([top, top + Vector2(14, 0), top + Vector2(7 + sway, 16)]), color)
		_decor.draw_polyline(PackedVector2Array([top, top + Vector2(14, 0), top + Vector2(7 + sway, 16), top]), Color(1, 1, 1, 0.4), 1.0)
	# The marquee sign on the lawn, letters flickering in the dark.
	var marquee := Rect2(22 * T, 12 * T - 6, 92, 34)
	_decor.draw_rect(Rect2(marquee.position + Vector2(10, marquee.size.y), Vector2(4, 14)), Color8(60, 60, 66))
	_decor.draw_rect(Rect2(marquee.position + Vector2(marquee.size.x - 14, marquee.size.y), Vector2(4, 14)), Color8(60, 60, 66))
	_decor.draw_rect(marquee, black)
	_decor.draw_rect(marquee, gold, false, 2.0)
	var flicker := 0.55 if fmod(t * 3.1, 1.0) < 0.06 else 1.0
	_decor.draw_string(_font, marquee.position + Vector2(8, 14), "GO WOLVERINES!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(gold, flicker))
	_decor.draw_string(_font, marquee.position + Vector2(8, 27), "GAME FRI 7PM", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.85 * flicker))
	# A flagpole with the school flag rippling.
	var pole := Vector2(4 * T + 10, 15 * T)
	_decor.draw_line(pole, pole - Vector2(0, 74), Color8(180, 180, 186), 2.0)
	var flag := PackedVector2Array()
	for k in 7:
		flag.append(pole + Vector2(1 + k * 4, -72 + sin(t * 4.0 + k * 0.8) * 2.0))
	for k in range(6, -1, -1):
		flag.append(pole + Vector2(1 + k * 4, -56 + sin(t * 4.0 + k * 0.8) * 2.0))
	_decor.draw_colored_polygon(flag, gold)
	_decor.draw_string(_font, pole + Vector2(8, -59), "W", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, black)


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
	_draw_school_front()
	# Hallway posters on the wall above the lockers. Their message changes as you loop.
	var loops := int(Game.flags.get("ww_loops", 0))
	var poster_text: String = ["NO RUNNING", "TURN BACK", "TURN BACK!!", "YOU'VE BEEN HERE"][mini(loops, 3)]
	for x in [55, 75, 95]:
		var r := Rect2(x * T - 18, 7 * T + 2, 56, 15)
		_decor.draw_rect(r, Color8(235, 225, 160))
		_decor.draw_string(_font, r.position + Vector2(3, 11), poster_text, HORIZONTAL_ALIGNMENT_LEFT, 50, 8, Color8(150, 30, 30))

	# The trophy case, set into the wall between the posters (two tiles wide, from
	# the top of the wall down to the floor), its glass dark as a mirror.
	var case_rect := Rect2(65 * T + 1, 7 * T + 1, 2 * T - 2, 2 * T - 2)
	_decor.draw_rect(case_rect, Color8(120, 90, 50))
	_decor.draw_rect(case_rect.grow(-3), Color8(28, 34, 48))
	_decor.draw_rect(Rect2(case_rect.position + Vector2(3, 18), Vector2(case_rect.size.x - 6, 2)), Color8(120, 90, 50))
	for k in 3:
		var cup := case_rect.position + Vector2(7 + k * 10, 8 - (k % 2) * 2)
		_decor.draw_rect(Rect2(cup, Vector2(6, 6 + (k % 2) * 2)), Color8(210, 175, 70))
		_decor.draw_rect(Rect2(cup + Vector2(2, 8 + (k % 2) * 2), Vector2(2, 2)), Color8(210, 175, 70))
	_decor.draw_rect(Rect2(case_rect.position + Vector2(9, 25), Vector2(20, 7)), Color8(190, 190, 200))
	_decor.draw_line(case_rect.position + Vector2(5, 4), case_rect.position + Vector2(14, 30), Color(1, 1, 1, 0.22), 1.0)

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
	var center := Vector2(100 * T + 10, 43 * T)
	_decor.draw_arc(center, 50, 0, TAU, 32, Color(1, 1, 1, 0.8), 2.0)
	# Westview's logo at center court: a big black W, outlined in gold, then white.
	var gold := Color8(225, 175, 45)
	var logo_size := 64
	var logo_width := _font.get_string_size("W", HORIZONTAL_ALIGNMENT_LEFT, -1, logo_size).x
	var logo_at := center + Vector2(-logo_width / 2, 22)
	_decor.draw_string_outline(_font, logo_at, "W", HORIZONTAL_ALIGNMENT_LEFT, -1, logo_size, 14, Color.WHITE)
	_decor.draw_string_outline(_font, logo_at, "W", HORIZONTAL_ALIGNMENT_LEFT, -1, logo_size, 8, gold)
	_decor.draw_string(_font, logo_at, "W", HORIZONTAL_ALIGNMENT_LEFT, -1, logo_size, Color8(15, 15, 18))
	# The banner on the gym bleachers.
	var banner_center := Vector2(100 * T + 10, 33 * T)
	var banner := Rect2(banner_center - Vector2(120, 10), Vector2(240, 20))
	_decor.draw_rect(banner, Color8(15, 15, 18))
	_decor.draw_rect(banner, gold, false, 2.0)
	var motto := "HOME OF THE WOLVERINES"
	var motto_width := _font.get_string_size(motto, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	_decor.draw_string(_font, banner_center + Vector2(-motto_width / 2, 5), motto, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, gold)


## The GO WOLVERINES marquee on the lawn (drawn in _add_decor) is solid: you
## walk around it, not through it. (Just its lower part, so you can stand behind it.)
func _add_marquee_block() -> void:
	var body := StaticBody2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(92, 26)
	var box := CollisionShape2D.new()
	box.shape = shape
	box.position = Vector2(22 * T + 46, 12 * T + 29)
	body.add_child(box)
	add_child(body)


# --- People and things ----------------------------------------------------

func _place_people() -> void:
	if _day:
		_place_day_people()
		return
	hop = Cast.make("Hop")
	add_character(hop, player.position + Vector2(-20, -4))
	hop.follow = player


	# The only people here at night (townsfolk.gd): a guard out front, dozing, and
	# the night janitor in the classroom. Either can be challenged.
	add_person("guard", Vector2(24 * T, 11 * T + 10), SCENE)
	add_person("nightjanitor", Vector2(45 * T, 40 * T), SCENE)

	add_storage_box(Vector2(9 * T + 36, 12 * T + 10))
	add_storage_box(Vector2(86 * T + 36, 45 * T))
	_add_save_point(Vector2(9 * T, 12 * T + 10), [
		"* (The school looms in the dark.\n*  A streetlight hums nearby.)",
		"* (It fills you with DETERMINATION.)",
	])
	_add_save_point(Vector2(86 * T, 45 * T), [
		"* (The gym smells like floor polish and old popcorn.)",
		"* (Something in here is waiting.\n*  It fills you with DETERMINATION.)",
	])

	if flag("has_fragment_2"):
		_add_empty_costume()
	elif flag("wally_done"):
		# Wally's beaten, but nobody's picked up the fragment yet.
		_add_empty_costume()
		_add_floating_fragment(MASCOT_SPOT + Vector2(-30, -26))
	else:
		mascot = Cast.make("wally")
		add_character(mascot, MASCOT_SPOT if not flag("mascot_started") else MASCOT_SPOT + Vector2(-30, 0))


## Fragment 2, hovering over Wally's costume and bobbing gently, waiting to be taken.
func _add_floating_fragment(at: Vector2) -> Character:
	floating_fragment = make_fragment()
	floating_fragment.glow = true
	floating_fragment.on_interact = _claim_fragment
	add_character(floating_fragment, at)
	var bob := floating_fragment.create_tween().set_loops()
	bob.tween_property(floating_fragment, "position:y", at.y - 4, 0.8).set_trans(Tween.TRANS_SINE)
	bob.tween_property(floating_fragment, "position:y", at.y, 0.8).set_trans(Tween.TRANS_SINE)
	return floating_fragment


## Wally's empty costume, slumped on the gym floor after the fight.
func _add_empty_costume() -> Character:
	var costume := Character.new().setup(load("res://art/sprites/wally_slump.png"), null, false)
	costume.on_interact = func() -> void:
		await Game.dialogue.say(["* (Wally's costume. Empty and limp.)", "* (It smells like a gym bag.)"])
		# His giant foam finger is still in there.
		if not flag("got_foam_finger") and Game.items.size() < Game.MAX_ITEMS:
			Game.flags["got_foam_finger"] = true
			Game.items.append(Items.accessory("Foam Finger", "weapon", 3, 0))
			Game.play_sfx("item")
			await Game.dialogue.say([
				"* (Something's poking out of the costume's paw.)",
				"* (You got the Foam Finger.)\n* (Weapon: ATK +3. EQUIP it from your bag.)",
				{"who": "Hop", "text": "We're number one. Allegedly.", "mood": "smug"},
			])
	return add_character(costume, MASCOT_SPOT + Vector2(-30, 0))


func _add_save_point(at: Vector2, lines: Array) -> void:
	var star := make_save_star()
	star.glow = true
	star.glow_color = Color(1.0, 1.0, 1.0, 0.55)
	star.on_interact = func() -> void:
		Game.play_sfx("heal")
		Game.heal_party()
		await Game.dialogue.say(lines + [Game.restored_line()])
		var choice := await Game.dialogue.ask("* (Save your progress?)", ["Save", "Return"])
		if choice == 0:
			Game.save_game(SCENE, player.position)
			Game.play_sfx("save")
			await Game.dialogue.say(Game.saved_lines())
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
		[Vector2(66 * T, 8 * T + 10), _trophy_case],
		[Vector2(53 * T, 36 * T - 4), _read_chalkboard],
		[Vector2(47 * T, 49 * T - 4), _back_to_hallway],
		[Vector2(67 * T - 4, 42 * T), _gym_door],
		[Vector2(82 * T - 4, 42 * T), _back_to_classroom],
		[Vector2(118 * T - 4, 42 * T), _emergency_exit],
	]
	for i in 3:
		spots.append([Vector2((60 + i * 2) * T + 10, 36 * T - 4), _ring_bell.bind(i + 1)])
	# By day, the spooky things are just things.
	if _day:
		var daytime := {_read_chalkboard: _day_chalkboard, _humming_locker: _day_locker, _read_poster: _day_poster, _emergency_exit: _day_exit}
		for spot in spots:
			if daytime.has(spot[1]):
				spot[1] = daytime[spot[1]]
	for spot in spots:
		world.add_child(Hotspot.create(spot[0], spot[1]))


# --- Story ----------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if not is_inside_tree():
		return
	if await handle_person_return():
		return
	if await _back_from_battle():
		return
	if not flag("ww_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked():
		return
	check_roamers(SCENE)
	check_random_encounter(SCENE)

	# The ends of the street out front.
	if _px(OUTSIDE).has_point(player.position):
		if player.position.x < 8.0:
			run_cutscene(func() -> void: await Game.change_scene(MALL_SCENE, MALL_FROM_WESTVIEW))
			return
		if player.position.x > OUTSIDE.end.x * T - 8.0:
			run_cutscene(func() -> void: await Game.change_scene(NEIGHBORHOOD_SCENE, null))
			return

	# The endless hallway.
	if not flag("loop_broken") and _px(HALLWAY).has_point(player.position) and player.position.x > LOOP_X:
		run_cutscene(_loop_back)
	# Approaching Wally.
	elif mascot and not flag("mascot_started") and _px(GYM).has_point(player.position) and player.position.x > 93 * T:
		run_cutscene(_wake_mascot)
	# Walking up to the floating fragment takes it.
	elif floating_fragment and player.position.distance_to(MASCOT_SPOT + Vector2(-30, 0)) < 28.0:
		run_cutscene(_claim_fragment)


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
		"mystery_meat": ["* (Mystery Meat slides back onto its tray, content.)", "* (Mystery Meat splats. Nobody will miss it.)"],
		"tardy_bell": ["* (Tardy Bell dings softly and goes back on the wall.)", "* (Tardy Bell cracks. It'll never ring again.)"],
		"overdue_book": ["* (Overdue Book flaps off toward the library. Finally.)", "* (Overdue Book's pages scatter down the hall.)"],
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
		{"who": "Hop", "text": "Rel-- Elric. Stay close, okay?", "mood": "sad"},
		"* (Hop looks away for a second.)",
		{"who": "Hop", "text": "...Wrong name. It's late.\nMy brain's on airplane mode.", "mood": "smug"},
	])
	Game.flags["ww_arrived"] = true
	Game.set_objective("Find the fragment inside Westview High.")


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


## The trophy case: its dark glass shows Elric's reflection. Mostly.
func _trophy_case() -> void:
	var lines: Array = ["* (A trophy case. Third place, 1998 regional\n*  spelling bee. The glass is dark.)"]
	# (Relic only says their name on the Genocide route. Before then, a lot of
	# killing just makes the reflection... wrong.)
	if Game.on_genocide_route():
		lines.append("* It's me, RELIC.")
	elif Game.dread() >= 4:
		lines.append("* (In the glass: someone in a scorched\n*  green hoodie.)")
		lines.append("* (...It smiles.)\n* (You can't tell if you are.)")
	elif Game.dread() > 0:
		lines.append("* (In the glass: it's you.)")
		lines.append("* (...Your reflection looks away a moment\n*  before you do.)")
	else:
		lines.append("* (In the glass: it's you.)")
	await Game.dialogue.say(lines)


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

	if spared:
		await Game.dialogue.say(["* (Wally gives one last tired cheer.)"])
	else:
		await Game.dialogue.say(["* (Wally staggers.)"])
	# The costume collapses into an empty pile of fur...
	var at := mascot.position if mascot else MASCOT_SPOT + Vector2(-30, 0)
	if mascot:
		mascot.queue_free()
		mascot = null
	Game.play_sfx("thud")
	shake(4.0, 0.3)
	_add_empty_costume()
	await get_tree().create_timer(0.6).timeout
	await Game.dialogue.say(["* (Then he slumps to the floor.\n*  Just a costume now.)" if spared else "* (The costume crumples to the floor.)"])

	# ...and the fragment rises out of it, glowing, and hangs there.
	Game.flags["wally_done"] = true
	Game.flags["wally_spared"] = spared
	var shard := make_fragment()
	shard.glow = true
	add_character(shard, at + Vector2(0, -4))
	Game.play_sfx("fragment")
	var rise := create_tween()
	rise.tween_property(shard, "position:y", at.y - 26, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await rise.finished
	shard.queue_free()
	_add_floating_fragment(at + Vector2(0, -26))
	await Game.dialogue.say([
		"* (Something red floats up out of the costume.)",
		"* (It hangs in the air, humming.)",
		{"who": "Hop", "text": "...That's it. That's the fragment.", "mood": "shocked"},
		{"who": "Hop", "text": "Go on. You grab it. I'm not touching\nanything that came out of a mascot.", "mood": "smug"},
	])
	Game.set_objective("Take the fragment.")


## Elric walks up to the floating fragment and takes it.
func _claim_fragment() -> void:
	if floating_fragment == null:
		return
	var spared: bool = Game.flags.get("wally_spared", false)
	Game.play_sfx("fragment")
	floating_fragment.queue_free()
	floating_fragment = null

	var lines: Array = []
	lines.append_array([
		"* (You reach up and take it. It's warm, and it hums.)",
		"* (You got the second FRAGMENT.)",
		"* (Hop reaches toward it.)",
		"* (For a second, his shadow looks... wrong.)",
		"* (Then it's gone.)",
		{"who": "Hop", "text": "...Sorry. Spaced out. Must be the late night.", "mood": "sad"},
		{"who": "Hop", "text": "Two down, huh?", "mood": "smug"},
		{"who": "Hop", "text": "I mean! Two fragments! Wow! Go team!", "mood": "happy"},
		{"who": "Elric", "choices": ["...Are you okay?", "...Hop? What was that?"]},
		{"who": "Hop", "text": "Never better! Let's get out of here before\nthe bleachers come alive too.", "mood": "happy"},
		"* (There's an emergency exit on the far wall.)",
	])
	if not spared:
		lines.insert(lines.size() - 1, {"who": "Hop", "text": "...Also, remind me never to be a mascot.", "mood": "shocked"})
	await Game.dialogue.say(lines)
	Game.flags["has_fragment_2"] = true
	Game.set_objective("Get out through the gym's emergency exit.")
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


# --- Chapter 2: Westview by day ---------------------------------------------------
# Once Elric has been to the Corps' base, Westview is just a school again: lights
# on, no random fights, students everywhere, still buzzing about last night. It's
# the way between the PQ Mall side of town and the park (Westview Field) where the
# base is: in the front doors, through the gym, out the emergency exit.

## Where Elric comes in from the park: just inside the gym's emergency exit.
const GYM_FROM_PARK := Vector2(116 * T, 42 * T + 10)

## The students: which picture, where (in tiles), what they say, two answers to
## pick from, and what they say back to each.
## Each student: sprite, where they stand (tiles), what they say, two answers, the
## reaction to each, and the moods for [their line, reaction 1, reaction 2].
const STUDENTS := [
	["Student1", Vector2i(8, 12), "Did you hear? Somebody broke into the school last\nnight. The bells were ringing at like 3 AM.", ["That was weird.", "...That was me."], ["Right?? My mom thought it was a fire drill.", "Ha! Sure. And I'm the principal."], ["shocked", "happy", "smug"]],
	["Student2", Vector2i(23, 12), "Ugh. Pop quiz first period. I didn't study.", ["Me neither.", "Answer C."], ["Solidarity.", "...C? Is it always C? It's always C, isn't it."], ["sad", "happy", "shocked"]],
	["Student3", Vector2i(13, 14), "Is it just me, or is the hallway shorter today?", ["It's just you.", "It used to loop."], ["Yeah, probably. I didn't sleep.", "...Loop? Okay, weirdo."], ["shocked", "sad", "smug"]],
	["Student4", Vector2i(20, 15), "Nice outfit. Very... wanderer.", ["Thanks!", "It's called style."], ["No problem, traveler.", "Okay, okay. Style. Sure."], ["smug", "happy", "smug"]],
	["Student5", Vector2i(58, 12), "My locker was humming this morning.\nLike, a song. I'm not okay.", ["Lockers do that.", "Was it in tune?"], ["They DO?", "...Actually, yeah. Kinda catchy."], ["shocked", "shocked", "happy"]],
	["Student8", Vector2i(68, 10), "Don't stare into the trophy case too long.\nMy friend says her reflection winked at her.", ["Creepy.", "Mine smiled."], ["Right?? It's a SPELLING BEE trophy.\nWhat does it want?", "...Okay. I'm taking the long way to class now."], ["sad", "shocked", "shocked"]],
	["Student6", Vector2i(75, 10), "Have you seen my hall pass? It ran away.", ["It RAN?", "Check the gym."], ["I said what I said.", "Why would it be in the... you know what, I'll check."], ["sad", "angry", "shocked"]],
	["Student7", Vector2i(96, 13), "The library book I returned was 47 years overdue.\nThe fine is insane.", ["Yikes.", "Worth it?"], ["They want $4,000. In 1979 money.", "...It was a good book."], ["sad", "sad", "happy"]],
	["Student8", Vector2i(50, 40), "The chalkboard says \"3, 1, 2.\"\nNobody knows who wrote it.", ["Weird.", "It's the bell order."], ["The teacher won't erase it. She says it's\n\"load-bearing.\"", "Bell... what?"], ["", "smug", "shocked"]],
	["Student3", Vector2i(60, 46), "Shh! I'm trying to nap before class.", ["Sorry.", "WAKE UP!"], ["Zzz...", "AH! ...I was awake. Totally awake."], ["angry", "happy", "shocked"]],
	["Student1", Vector2i(95, 40), "Somebody wrecked Wally's costume.\nHe's just... lying there. Empty.", ["Rest in peace.", "He'll be back."], ["Go Wolverines... :(", "You think?? GO WOLVERINES!!"], ["sad", "sad", "happy"]],
	["Student6", Vector2i(104, 45), "Did you see the foam finger? It's GONE.\nTHE foam finger!", ["No idea.", "...It's in my bag."], ["The whole team's freaking out.", "WHAT. ...Okay, keep it. It looks good on you."], ["shocked", "sad", "happy"]],
	["Student2", Vector2i(112, 38), "The emergency exit goes out to the park.\nPractice is out there today.", ["Thanks.", "Is it safe?"], ["No prob. Watch out for the sprinklers.", "It's a park. What could happen?"], ["happy", "happy", "smug"]],
]


func _place_day_people() -> void:
	# (Going their own way, Elric comes alone until they've been to the base.)
	if not Game.walking_alone():
		partner = Cast.make(Game.partner())
		add_character(partner, player.position + Vector2(-20, -4))
		partner.follow = player
		hop = partner
	add_storage_box(Vector2(9 * T + 36, 12 * T + 10))
	add_storage_box(Vector2(86 * T + 36, 45 * T))
	_add_save_point(Vector2(9 * T, 12 * T + 10), [
		"* (The school's busy. Somebody's playing music\n*  out of their phone.)",
		"* (It fills you with DETERMINATION.)",
	])
	_add_save_point(Vector2(86 * T, 45 * T), [
		"* (The gym smells like floor polish and old popcorn.)",
		"* (It's just a gym now. It fills you with DETERMINATION.)",
	])
	if flag("has_fragment_2"):
		_add_empty_costume()
	for i in STUDENTS.size():
		var student: Array = STUDENTS[i]
		var spot: Vector2i = student[1]
		# (Anyone beaten in a fight is gone for good.)
		if Townsfolk.is_gone(_student_id(i)):
			continue
		add_npc(student[0], Vector2(spot.x * T + 10, spot.y * T + 10), _talk_to_student.bind(i), "the student")


## A student's id in townsfolk.gd: "student-<look>-<n>".
func _student_id(i: int) -> String:
	return "student-%s-%d" % [str(STUDENTS[i][0]).trim_prefix("Student"), i]


## A student says something, and Elric picks one of two answers (they react), or
## challenges them to a fight.
func _talk_to_student(i: int) -> void:
	var student: Array = STUDENTS[i]
	var who: String = student[0]
	var line_moods: Array = student[5] if student.size() > 5 else ["", "", ""]
	await Game.dialogue.say([{"who": who, "tag": "Student", "text": student[2], "mood": line_moods[0]}])
	var options: Array = student[3].duplicate()
	options.append("Challenge")
	var choice := await Game.dialogue.ask("* (What do you say?)", options)
	if choice == 2:
		await challenge(_student_id(i), SCENE)
		return
	var moods: Array = student[5] if student.size() > 5 else ["", "", ""]
	await Game.dialogue.say([{"who": who, "tag": "Student", "text": student[4][choice], "mood": moods[choice + 1]}])


func _day_chalkboard() -> void:
	await Game.dialogue.say([
		"* (Today's lesson is on the board.\n*  Off in the corner, faint: \"3, 1, 2.\")",
		"* (Nobody has erased it.)",
	])


func _day_locker() -> void:
	await Game.dialogue.say(["* (Just a locker. It isn't humming anymore.)", "* (...Probably.)"])


func _day_poster() -> void:
	await Game.dialogue.say(["* (A poster: \"GO WOLVERINES! GAME FRIDAY 7PM.\")", "* (Someone drew a little foam finger on it.)"])


func _day_exit() -> void:
	var choice := await Game.dialogue.ask("* (The emergency exit. Go out to the park?)", ["Go out", "Stay"])
	if choice == 0:
		await Game.change_scene(HILLTOP_SCENE)
