extends Area
## Balboa Park (fragment 5): the Prado walkway, the old museum with its bell
## tower, a fountain and a lily pond; and inside the museum, the arms and armor
## hall (where the Empty Knight walks) and the archives (where Nat's book has a
## second copy, with the last page still in it).
##
## Reached by bus (from the PQ Mall or Mission Beach) once fragment 4 is found.
##
##   Corps      Big Joe and Nat are here. Big Joe wants the Knight beaten fair. In
##              the archives, Nat finds the missing page: "Their name was Relic."
##              He asks Elric to let Hop say it himself.
##   Own way    Big Joe is at the museum doors: a duel for the fragment, by the
##              rules (it can be spared). Elric finds the page alone.
##   With Hop   Big Joe is at the doors, and he dies there, fighting fair.
##
## Story flags: bp_arrived, bp_duel_done, bp_fragment, bp_page, has_fragment_5.

const SCENE := "res://scenes/balboa_park.tscn"
const MALL_SCENE := "res://scenes/pq_mall.tscn"
const BEACH_SCENE := "res://scenes/mission_beach.tscn"
const T := Room.TILE
const OUTSIDE := Rect2i(0, 0, 64, 30)
const INSIDE := Rect2i(0, 32, 40, 24)
## Where the bus lets you off (the east end of the Prado).
const ENTRY := Vector2(60 * T, 12 * T + 10)
## The museum doors, outside and in.
const DOOR_OUT := Vector2(32 * T, 9 * T + 4)
const OUTSIDE_DOOR := Vector2(32 * T, 10 * T + 14)
const INSIDE_ENTRY := Vector2(14 * T + 10, 53 * T + 6)
const INSIDE_EXIT := Vector2(14 * T + 10, 55 * T - 2)
const BIGJOE_SPOT := Vector2(32 * T, 11 * T + 10)
const NAT_SPOT := Vector2(33 * T, 47 * T)
const KNIGHT_SPOT := Vector2(20 * T, 42 * T)
const BOOK_DESK := Vector2(33 * T + 10, 50 * T + 6)

var partner: Character
var bigjoe: Character
var nat: Character
var knight: Character
var _decor: Node2D
var _font: Font
## A fight is starting: don't start it again during the fade.
var _engaged: bool = false


func _ready() -> void:
	rooms.assign([_px(OUTSIDE), _px(INSIDE)])
	setup_area(ENTRY)
	add_wild_encounters(SCENE, Rect2(0, 14 * T, 64 * T, 15 * T))
	_font = ThemeDB.fallback_font
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	Game.play_music("balboa")
	_place_people()
	for spot in [[ENTRY + Vector2(10, -8), _bus_stop], [DOOR_OUT, _museum_door], [INSIDE_EXIT, _leave_museum], [BOOK_DESK, _book]]:
		world.add_child(Hotspot.create(spot[0], spot[1]))
	fit_camera_to_room()
	_start.call_deferred()


static func _px(r: Rect2i) -> Rect2:
	return Rect2(r.position * T, r.size * T)


func _genocide() -> bool:
	return Game.on_genocide_route()


func _route() -> String:
	return str(Game.flags.get("route", ""))


# --- The map -----------------------------------------------------------------------

func build_map() -> void:
	room.setup(64, 56, Room.VOID)
	# Outside: grass, trees, the museum, the Prado, a fountain and a lily pond.
	room.fill(0, 0, 64, 30, Room.GRASS)
	room.fill(0, 0, 64, 1, Room.TREE)
	room.fill(0, 29, 64, 1, Room.TREE)
	room.fill(0, 0, 1, 30, Room.TREE)
	room.fill(20, 1, 24, 1, Room.ROOF)
	room.fill(20, 2, 24, 7, Room.STUCCO)
	for x in [22, 26, 37, 41]:
		room.fill(x, 4, 1, 3, Room.GLASS)
	room.fill(31, 8, 2, 1, Room.DOOR)
	room.fill(1, 10, 63, 4, Room.PATIO)
	room.fill(31, 9, 2, 1, Room.PATIO)
	room.fill(30, 17, 4, 3, Room.WATER)
	room.fill(5, 21, 14, 6, Room.WATER)
	for spot in [Vector2i(4, 4), Vector2i(10, 6), Vector2i(14, 3), Vector2i(50, 4), Vector2i(56, 6), Vector2i(47, 18), Vector2i(55, 22), Vector2i(24, 24), Vector2i(40, 25), Vector2i(60, 26)]:
		room.set_tile(spot.x, spot.y, Room.TREE)
	# Inside: the arms and armor hall, and the archives through a doorway.
	room.fill(0, 32, 40, 24, Room.INTERIOR_WALL)
	room.fill(1, 35, 38, 20, Room.HALL_FLOOR)
	room.fill(28, 35, 1, 20, Room.INTERIOR_WALL)
	room.set_tile(28, 52, Room.HALL_FLOOR)
	room.set_tile(28, 53, Room.HALL_FLOOR)
	room.fill(14, 55, 1, 1, Room.DOOR)
	for x in [4, 8, 12]:
		room.set_tile(x, 37, Room.PROP)      # armor on stands
	room.fill(18, 37, 4, 1, Room.PROP)        # the Knight's empty pedestal
	for y in [37, 41, 45]:
		room.fill(30, y, 8, 1, Room.PROP)     # archive shelves
	room.fill(32, 49, 3, 1, Room.PROP)        # the reading desk


func _draw_decor() -> void:
	# The bell tower over the museum: tiled dome, arched windows.
	_decor.draw_rect(Rect2(30 * T, 0, 4 * T, 40), Color8(225, 205, 160))
	_decor.draw_circle(Vector2(32 * T, 6), 30.0, Color8(60, 110, 140))
	_decor.draw_rect(Rect2(31 * T + 6, 12, 8, 18), Color8(40, 40, 50))
	_decor.draw_rect(Rect2(32 * T + 6, 12, 8, 18), Color8(40, 40, 50))
	_decor.draw_string(_font, Vector2(24 * T, 3 * T - 4), "MUSEUM OF ART & ARMOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(110, 80, 50))
	# The fountain's stone rim, and a spray.
	_decor.draw_arc(Vector2(32 * T, 18 * T + 10), 46.0, 0, TAU, 32, Color8(220, 215, 200), 6.0)
	for k in 6:
		var dir := Vector2.from_angle(-PI / 2 + (k - 2.5) * 0.25)
		_decor.draw_line(Vector2(32 * T, 18 * T + 6), Vector2(32 * T, 18 * T + 6) + dir * 22.0, Color(0.85, 0.95, 1.0, 0.7), 2.0)
	# Lily pads.
	for spot in [Vector2(7, 22), Vector2(11, 24), Vector2(15, 23), Vector2(9, 26), Vector2(16, 25)]:
		_decor.draw_circle(spot * T, 7.0, Color8(80, 150, 70))
		_decor.draw_circle(spot * T + Vector2(3, -2), 2.0, Color8(240, 170, 200))
	# Inside: armor on stands, paintings, the empty pedestal, the shelves.
	for x in [4, 8, 12]:
		var at := Vector2(x * T + 10, 37 * T + 2)
		_decor.draw_rect(Rect2(at + Vector2(-6, -26), Vector2(12, 26)), Color8(170, 175, 190))
		_decor.draw_rect(Rect2(at + Vector2(-4, -22), Vector2(8, 3)), Color8(40, 40, 50))
	for x in [3, 9, 15, 22]:
		_decor.draw_rect(Rect2(x * T, 33 * T + 4, 2 * T, 30), Color8(120, 85, 50))
		_decor.draw_rect(Rect2(x * T + 4, 33 * T + 8, 2 * T - 8, 22), Color8(70 + x * 5, 90, 120 - x * 2))
	_decor.draw_rect(Rect2(18 * T, 37 * T, 4 * T, T), Color8(140, 130, 120))
	_decor.draw_string(_font, Vector2(18 * T + 4, 37 * T + 14), "1540 (ON LOAN)", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color8(40, 40, 40))
	for y in [37, 41, 45]:
		for k in 16:
			_decor.draw_rect(Rect2(30 * T + k * 10, y * T + 2, 7, 16), Color8(110 + (k * 37) % 90, 60 + (k * 23) % 80, 50 + (k * 51) % 60))
	_decor.draw_rect(Rect2(32 * T, 49 * T, 3 * T, T), Color8(120, 85, 50))
	if not flag("bp_page"):
		_decor.draw_rect(Rect2(33 * T + 2, 49 * T + 4, 16, 10), Color8(200, 190, 160))
	# The bus stop.
	_decor.draw_rect(Rect2(ENTRY + Vector2(8, -46), Vector2(3, 38)), Color8(150, 150, 156))
	_decor.draw_rect(Rect2(ENTRY + Vector2(0, -54), Vector2(20, 12)), Color8(40, 90, 190))
	_decor.draw_string(_font, ENTRY + Vector2(2, -44), "BUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)


# --- People ----------------------------------------------------------------------

func _place_people() -> void:
	if not Game.walking_alone():
		partner = Cast.make(Game.partner())
		add_character(partner, player.position + Vector2(-20, 0))
		partner.follow = player
	# Big Joe: at the doors (own way, with Hop), or in the hall (Corps).
	var joe_gone := _genocide() and flag("beat_corps_bigjoe")
	var joe_aside := _route() == "neutral" and flag("bp_duel_done")
	if not joe_gone and not joe_aside and Game.partner() != "BigJoe6":
		bigjoe = add_npc("BigJoe6", BIGJOE_SPOT if _route() != "pacifist" else Vector2(16 * T, 45 * T), _talk_bigjoe)
	# Nat, in the archives (Corps only; on the other paths he isn't here).
	if _route() == "pacifist" and Game.partner() != "Nat":
		nat = add_npc("Nat", NAT_SPOT, _talk_nat)
	# The Empty Knight, in its hall, until it's beaten.
	if not flag("bp_fragment") and str(Game.battle_result.get("id", "")) != "knight":
		knight = Cast.make("empty_knight")
		knight.glow = true
		knight.glow_color = Color(0.9, 0.15, 0.2, 0.35)
		add_character(knight, KNIGHT_SPOT)


func _talk_bigjoe() -> void:
	match _route():
		"pacifist":
			if flag("bp_fragment"):
				await chat("bp_joe_after", [
					{"who": "BigJoe6", "text": "THAT was a fair fight. Textbook.\nYou saluted. It saluted. I almost cried.", "mood": "happy"},
				], [[{"who": "BigJoe6", "text": "JUSTICE!", "mood": "happy"}]])
			else:
				await chat("bp_joe", [
					{"who": "BigJoe6", "text": "RECRUIT! The fragment's in the Knight.\nThe suit of armor. It WALKS.", "mood": "shocked"},
					{"who": "BigJoe6", "text": "You face it by the rules, got it? It's been\nwaiting 480 years for a worthy opponent.", "mood": ""},
					{"who": "BigJoe6", "text": "Salute first. Never hit it while it's down.\nThat's justice.", "mood": "smug"},
					{"who": "BigJoe6", "text": "...Nat's in the archives. He found something.\nHe went quiet. Nat never goes quiet. Well. He does.\nBut not like that.", "mood": "sad"},
				], [[{"who": "BigJoe6", "text": "Salute first!", "mood": "happy"}]])
		"neutral":
			await Game.dialogue.say([
				{"who": "BigJoe6", "text": "ELRIC. I knew you'd come here.", "mood": ""},
				{"who": "BigJoe6", "text": "The fragment's in the museum, and I'm not\nletting you walk in and take it.", "mood": "angry"},
				{"who": "BigJoe6", "text": "...But I'm not unfair. A DUEL! By the rules!\nWinner goes in. Loser goes home.", "mood": "happy"},
			])
			_engaged = true
			await Game.start_battle("duel_bigjoe", SCENE, player.position)
		_:
			await _confront_bigjoe()


func _talk_nat() -> void:
	if flag("bp_page"):
		await chat("bp_nat_after", [
			{"who": "Nat", "text": "...Let him tell you himself. When he's ready.", "mood": "sad"},
		], [[{"who": "Nat", "text": "Zzz. (He isn't asleep.)", "mood": ""}]])
		return
	Game.flags["bp_page"] = true
	_decor.queue_redraw()
	_onward()
	await Game.dialogue.say([
		"* (Nat is sitting at the reading desk.\n*  The book isn't on his head. It's open in front of him.)",
		{"who": "Nat", "text": "...You know my book. The one with the\nlast page torn out.", "mood": ""},
		{"who": "Nat", "text": "There's a second copy here. In the archives.\nNobody's opened it in years.", "mood": ""},
		{"who": "Nat", "text": "The last page is still in it.", "mood": "sad"},
		"* (He turns it toward you.)",
		"* (\"...Somebody gave everything to break it apart.\n*  Their name was Relic.\")",
		{"who": "Nat", "text": "Relic. That's the name Hop almost said.\nAt Westview. \"Rel-- Elric.\"", "mood": "sad"},
		{"who": "Nat", "text": "My copy didn't tear itself.\nSomebody tore this page out on purpose.", "mood": ""},
		{"who": "Nat", "text": "...I know who. So do you.", "mood": "sad"},
		{"who": "Nat", "text": "Don't tell him we know. Let him say it himself.\nWhen he's ready. It has to be him.", "mood": "sad"},
	])


## The reading desk. On the own-way path Elric finds the page alone; with Hop,
## Relic reads it.
func _book() -> void:
	if _route() == "pacifist":
		if nat:
			await Game.dialogue.say(["* (Nat is reading at the desk.)"])
		return
	if flag("bp_page"):
		await Game.dialogue.say(["* (An old book on the desk. You know what's\n*  on the last page.)"])
		return
	Game.flags["bp_page"] = true
	_decor.queue_redraw()
	_onward()
	if _genocide():
		await Game.dialogue.say([
			"* (An old book on the reading desk.\n*  The last page is still in it.)",
			"* (\"...Somebody gave everything to break it apart.\n*  Their name was Relic.\")",
			{"who": "Relic", "tag": "", "face": false, "text": "* Our name. In a book.\n* Nobody ever said it out loud. Not once."},
			"* (Hop is looking at the page over your shoulder.\n*  His hand is shaking.)",
		])
		return
	await Game.dialogue.say([
		"* (An old book on the reading desk. You've seen it\n*  before: Nat's book, the one he wears on his head.)",
		"* (This copy still has its last page.)",
		"* (\"...Somebody gave everything to break it apart.\n*  Their name was Relic.\")",
		"* (Relic.)",
		"* (\"Rel-- Elric. Stay close, okay?\")",
	])


# --- Story ------------------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if not is_inside_tree():
		return
	var id := str(Game.battle_result.get("id", ""))
	var spared: bool = not Game.battle_result.get("spared", []).is_empty()
	if id in ["knight", "duel_bigjoe", "corps_bigjoe"]:
		Game.battle_result = {}
	match id:
		"knight":
			await run_cutscene(_after_knight.bind(spared))
			return
		"duel_bigjoe":
			await run_cutscene(_after_duel.bind(spared))
			return
		"corps_bigjoe":
			await run_cutscene(_after_bigjoe)
			return
	if not flag("bp_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked() or _engaged:
		return
	check_random_encounter(SCENE)
	# The Knight notices you.
	if knight and is_instance_valid(knight) and player.position.distance_to(knight.position) < 64.0:
		run_cutscene(_meet_knight)
	# With Hop: Big Joe is waiting by the doors.
	elif _genocide() and bigjoe and is_instance_valid(bigjoe) and player.position.distance_to(bigjoe.position) < 70.0:
		run_cutscene(_confront_bigjoe)


func _arrival() -> void:
	Game.flags["bp_arrived"] = true
	await Game.dialogue.say([
		"* (Balboa Park. Old Spanish buildings, a bell tower,\n*  a fountain throwing water at the sky.)",
		"* (A banner over the museum doors: ARMS & ARMOR,\n*  1300 TO 1700. A section of the banner is torn.)",
		"* (Something in there is clanking.)",
	])
	match _route():
		"pacifist":
			Game.set_objective("Find the fragment. (The museum.)")
		"neutral":
			await Game.dialogue.say(["* (Someone in a knight's helmet is standing in\n*  front of the museum doors. Big Joe.)"])
			Game.set_objective("Get into the museum.")
		_:
			await Game.dialogue.say([
				{"who": "Hop", "text": "...That's Big Joe.", "mood": "sad"},
				{"who": "Hop", "text": "Elric, he's- he started all this. Revolution.\nHe's a good guy. He's a GOOD guy.", "mood": "sad"},
				{"who": "Relic", "tag": "", "face": false, "text": "* So were we."},
			])
			Game.set_objective("...")


func _museum_door() -> void:
	if bigjoe and is_instance_valid(bigjoe) and _route() != "pacifist":
		await _talk_bigjoe()
		return
	Game.play_sfx("door")
	await go_through_door(INSIDE_ENTRY)
	fit_camera_to_room()
	if not flag("bp_inside"):
		Game.flags["bp_inside"] = true
		await Game.dialogue.say([
			"* (The arms and armor hall. Suits of armor on\n*  stands, all in a row.)",
			"* (One pedestal is empty. The sign says 1540.)",
		])


func _leave_museum() -> void:
	Game.play_sfx("door")
	await go_through_door(OUTSIDE_DOOR)
	fit_camera_to_room()


func _bus_stop() -> void:
	await ride_bus(SCENE)


## Once the fragment's found and the page is read: on to Old Town.
func _onward() -> void:
	if flag("bp_fragment") and flag("bp_page"):
		Game.set_objective("..." if _genocide() else "5 of 12. Next: Old Town. (Take the bus.)")


func _meet_knight() -> void:
	if _engaged:
		return
	_engaged = true
	knight.face(player.position - knight.position)
	await Game.dialogue.say([
		"* (The Empty Knight turns toward you.\n*  Its visor is empty. Something red glows in its chest.)",
		"* (It raises its sword, straight up.)",
		"* (A salute? Or a challenge?)",
	])
	if _route() == "pacifist" and bigjoe:
		await Game.dialogue.say([{"who": "BigJoe6", "text": "BY THE RULES, RECRUIT!", "mood": "happy"}])
	await Game.start_battle("knight", SCENE, player.position)


func _after_knight(spared: bool) -> void:
	Game.flags["bp_fragment"] = true
	if spared:
		await Game.dialogue.say([
			"* (The Empty Knight lowers its sword.)",
			"* (It bows, very low, and walks back to its pedestal.\n*  It stands there. It doesn't move again.)",
			"* (Its breastplate opens, just a crack.)",
		])
	else:
		await Game.dialogue.say(["* (The armor lies in pieces on the floor.)"])
	Game.play_sfx("fragment")
	await Game.dialogue.say([
		"* (Something red floats up out of the armor.)",
		"* (You take it. It's warm, and it hums.)",
		"* (You got the fifth FRAGMENT.)",
	])
	Game.flags["has_fragment_5"] = true
	Game.flags["fragments"] = maxi(int(Game.flags.get("fragments", 4)), 5)
	match _route():
		"pacifist":
			Game.set_objective("Nat is in the archives. (Through the hall.)")
		"neutral":
			Game.set_objective("5 of 12 FRAGMENTS. (There's an archive here.)")
		_:
			Game.set_objective("...")
	_onward()
	await Game.dialogue.say(["* (The fragment is warm in your hand.\n*  You close your eyes.)"])
	await Game.play_keepsakes([5], SCENE, player.position, [
		"* (The museum steps at night. A boy telling someone\n*  the thing he'd never told anyone.)",
	])


## Own way: the duel with Big Joe, by the rules.
func _after_duel(spared: bool) -> void:
	Game.flags["bp_duel_done"] = true
	if spared:
		await Game.dialogue.say([
			{"who": "BigJoe6", "text": "...FINE. FINE! You win. Fair and square.", "mood": "angry"},
			{"who": "BigJoe6", "text": "Justice says the winner goes in.\nSo go in.", "mood": ""},
			{"who": "BigJoe6", "text": "...The offer stands, you know. The Corps.\nI'm just saying. I'm not ASKING.", "mood": "sad"},
		])
	else:
		await Game.dialogue.say([
			{"who": "BigJoe6", "text": "...You didn't have to hit that hard.", "mood": "sad"},
			{"who": "BigJoe6", "text": "Go on. You won. That's the rule.", "mood": "sad"},
		])
	if bigjoe:
		await bigjoe.walk_to(BIGJOE_SPOT + Vector2(-140, 40), 90.0)
		bigjoe.queue_free()
		bigjoe = null
	Game.set_objective("Find the fragment. (The museum.)")


## With Hop: Big Joe is waiting by the doors.
func _confront_bigjoe() -> void:
	if not bigjoe or not is_instance_valid(bigjoe) or _engaged:
		return
	_engaged = true
	bigjoe.face(player.position - bigjoe.position)
	await Game.dialogue.say([
		{"who": "BigJoe6", "text": "I heard about the beach.", "mood": "sad"},
		{"who": "BigJoe6", "text": "Crayola. N.C. ...I heard.", "mood": "sad"},
		{"who": "BigJoe6", "text": "I'm not going to call you a monster, Elric.\nI'm going to fight you. Fair. By the rules.", "mood": "angry"},
		{"who": "BigJoe6", "text": "Hop. Stand back. This isn't on you.", "mood": ""},
	])
	await Game.start_battle("corps_bigjoe", SCENE, player.position)


func _after_bigjoe() -> void:
	if bigjoe:
		bigjoe.queue_free()
		bigjoe = null
	var kept: Array = Game.flags.get("mementos", [])
	if not "Helmet Crest" in kept:
		kept.append("Helmet Crest")
	Game.flags["mementos"] = kept
	await Game.dialogue.say([
		"* (A spiky black-and-red crest is lying on the Prado.\n*  It came off his helmet.)",
		"* (You keep it.)",
		"* (Hop picks up Big Joe's lance. He holds it for\n*  a long time. Then he puts it down, very carefully.)",
		{"who": "Relic", "tag": "", "face": false, "text": "* The doors are open now."},
	])
	Game.set_objective("...")
