extends Area
## Hop's street, and Hop's house. Where Elric ends up after going with Hop from
## Westview Field.
##
## Two parts, on one tile grid:
##   Street   a quiet residential street at night. Halfway along, a little lost
##            glowbug sits on the sidewalk: the fight that can't be avoided, and
##            that starts the Genocide route (see street_battles.gd).
##   House    Hop's house: small, humble, one of everything. Little things around
##            it hint at Hopkuna (a covered mirror, tally marks, a note) and at
##            Relic (a photo, a jar of bottle caps, a calendar, a melted tent).
##
## At the end (fragment 11): the jar of bottle caps on the windowsill, labeled KEEP
## in Relic's handwriting. Hop found the eleventh fragment in the burned field at
## dawn, five years ago, and never broke it and never told anyone. Picking it up
## plays its KEEPSAKE (the fire: "Hop. Let go."). Then the windows go red: Hopkuna
## takes it, and flies north to the last one. (Corps and own way: after the
## junkyard. With Hop: after the last of the Corps, Hop gives it to them himself.)
##
## Story flags (in Game.flags): hh_arrived, glowbug_done, hh_inside, hh_slept,
## hh_seen_morning, plus seen_<thing> for things Hop reacts to once.

const SCENE := "res://scenes/hop_house.tscn"
const DEMO_END_SCENE := "res://scenes/demo_end.tscn"
const T := Room.TILE

const STREET := Rect2i(0, 0, 50, 24)
const HOUSE := Rect2i(0, 30, 30, 20)

## Where Elric arrives (the left end of the sidewalk), where the glowbug sits,
## and how far along the sidewalk it notices you.
const ENTRY := Vector2(2 * T, 14 * T + 10)
const GLOWBUG_SPOT := Vector2(24 * T, 14 * T + 10)
const GLOWBUG_AT_X := 20 * T
## Hop's front door (outside), and just inside it.
const FRONT_DOOR := Vector2(42 * T, 9 * T + 6)
const HOUSE_ENTRY := Vector2(10 * T, 47 * T)
## The couch (where Elric sleeps), and where Hop stands at night / in the morning.
const COUCH := Vector2(5 * T, 43 * T + 10)
## Just outside Hop's front door, on the street side.
const OUTSIDE_DOOR := Vector2(42 * T, 10 * T + 14)
## Where Elric gets up in the morning: just in front of the couch (not on it).
const WAKE_SPOT := Vector2(5 * T, 46 * T + 14)
const HOP_NIGHT := Vector2(14 * T, 39 * T)
const HOP_MORNING := Vector2(15 * T, 35 * T + 10)

var hop: Character
var glowbug: Character
## Back from fragment 11's KEEPSAKE.
var _from_memory: bool = false
var _engaged: bool = false
var _decor: Node2D
var _font: Font


func _morning() -> bool:
	return flag("hh_slept")


## Just walking through the neighborhood (not the night of going with Hop, or
## after it on the Genocide route).
func _visiting() -> bool:
	return not Game.flags.get("route", "") in ["with_hop", "genocide"]


const WESTVIEW_SCENE := "res://scenes/westview.tscn"
## Coming back from here, Elric arrives at the east end of Westview's street.
const WESTVIEW_FROM_HERE := Vector2(32 * T - 30, 370)


func _ready() -> void:
	_from_memory = not Game.keepsake_after.is_empty() and not Game.playing_relic
	rooms.assign([_px(STREET), _px(HOUSE)])
	setup_area(ENTRY)
	if _visiting() or flag("glowbug_done"):
		add_wild_encounters(SCENE, _px(STREET))
	_font = ThemeDB.fallback_font
	# Night on the street; warm lamplight inside; plain daylight in the morning.
	if _visiting():
		if not Game.daytime():
			var dusk := CanvasModulate.new()
			dusk.color = Color(0.5, 0.52, 0.76)
			add_child(dusk)
		Game.play_music("mt_carmel" if Game.daytime() else "mall_night")
	elif not _morning():
		var tint := CanvasModulate.new()
		tint.color = Color(0.5, 0.52, 0.76) if not _px(HOUSE).has_point(player.position) else Color(0.82, 0.74, 0.66)
		tint.name = "Tint"
		add_child(tint)
		Game.play_music("mall_night")
	else:
		Game.stop_music(1.0)
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	_add_streetlights()
	_dress()
	_place_people()
	_place_hotspots()
	fit_camera_to_room()
	_start.call_deferred()


static func _px(r: Rect2i) -> Rect2:
	return Rect2(r.position * T, r.size * T)


# --- The map --------------------------------------------------------------------

func build_map() -> void:
	room.setup(50, 50, Room.VOID)
	_build_street()
	_build_house()


func is_night() -> bool:
	if _visiting():
		return not Game.daytime()
	return not _morning()


## Set dressing (props.gd): mailboxes and flower beds and a kid's bike along the
## street, a car at the curb, trash day; a plant and a trash can inside.
func _dress() -> void:
	var T := Room.TILE
	add_dressing([
		["mailbox", Vector2(4 * T + 6, 12 * T + 16), {"look": ["* (A mailbox shaped like a fish. The fish is
*  smiling. The fish has seen things.)"]}],
		["flower_bed", Vector2(4 * T, 9 * T + 8), {"size": Vector2(40, 10), "walkable": true}],
		["bike", Vector2(9 * T, 11 * T), {"color": Color8(230, 80, 120), "walkable": true, "look": ["* (A kid's bike with streamers, lying on the lawn.
*  Training wheels. One of them is missing.)"]}],
		["mailbox", Vector2(15 * T + 6, 12 * T + 16)],
		["bush", Vector2(20 * T, 7 * T), {"berries": true}],
		["mailbox", Vector2(26 * T + 6, 12 * T + 16), {"look": ["* (A mailbox. Someone taped a note to it:
*  PLEASE STOP PUTTING SNAILS IN HERE. -MGMT)"]}],
		["flower_bed", Vector2(30 * T, 9 * T + 8), {"size": Vector2(40, 10), "walkable": true}],
		["mailbox", Vector2(40 * T + 6, 12 * T + 16), {"look": ["* (Hop's mailbox. There's just one name on it.)", "* (Someone scratched off a second name, a long
*  time ago. You can't read what it was.)"]}],
		["lamp", Vector2(8 * T, 13 * T + 4), {"lit": is_night(), "walkable": true}],
		["lamp", Vector2(33 * T, 13 * T + 4), {"lit": is_night(), "walkable": true}],
		["hydrant", Vector2(18 * T, 15 * T + 16)],
		["bin_row", Vector2(34 * T, 15 * T + 16), {"look": ["* (Trash cans out at the curb. Tomorrow is trash day.
*  It's always tomorrow.)"]}],
		["car", Vector2(9 * T, 16 * T + 12), {"color": Color8(60, 100, 180), "look": ["* (A blue car, parked at the curb. A dreamcatcher
*  hangs from the mirror.)"]}],
		["car", Vector2(44 * T, 20 * T + 8), {"color": Color8(160, 160, 165)}],
		# Inside Hop's house.
		["trash_can", Vector2(11 * T + 6, 34 * T + 16)],
		["potted_plant", Vector2(18 * T, 47 * T + 10), {"look": ["* (A potted plant. It's fake. It's still
*  somehow dying.)"]}],
	])


func _build_street() -> void:
	room.fill(0, 0, 50, 24, Room.GRASS)
	room.fill(0, 0, 50, 1, Room.TREE)
	# Four little houses along the top; Hop's is the last, the smallest.
	for house in [[2, 9], [13, 9], [24, 9], [38, 8]]:
		var x: int = house[0]
		var w: int = house[1]
		room.fill(x, 2, w, 2, Room.ROOF)
		room.fill(x, 4, w, 5, Room.WALL)
		room.set_tile(x + 1, 5, Room.WINDOW)
		room.set_tile(x + w - 2, 5, Room.WINDOW)
		var door := x + w / 2 - 1
		room.fill(door, 7, 2, 2, Room.DOOR)
		room.fill(door, 9, 2, 4, Room.SIDEWALK)
	for spot in [Vector2i(11, 6), Vector2i(22, 10), Vector2i(35, 7), Vector2i(47, 9)]:
		room.set_tile(spot.x, spot.y, Room.TREE)
	room.fill(0, 13, 50, 3, Room.SIDEWALK)
	room.fill(0, 16, 50, 5, Room.ROAD)
	room.fill(0, 18, 50, 1, Room.ROAD_LINE)
	room.fill(0, 21, 50, 3, Room.SIDEWALK)


func _build_house() -> void:
	var r := HOUSE
	room.fill(r.position.x, r.position.y, r.size.x, r.size.y, Room.HOUSE_WALL)
	room.fill(1, 33, 28, 16, Room.HOUSE_FLOOR)
	# Hop's room, behind a wall on the right, with a doorway.
	room.fill(19, 33, 1, 16, Room.HOUSE_WALL)
	room.fill(19, 40, 1, 2, Room.HOUSE_FLOOR)
	# The front door, at the bottom.
	room.fill(9, 49, 2, 1, Room.DOOR)
	# Furniture (solid; drawn in _draw_decor).
	_prop(3, 44, 5, 2)     # the couch
	_prop(4, 41, 3, 1)     # the coffee table (checkers)
	_prop(3, 33, 4, 1)     # the TV
	_prop(9, 33, 2, 1)     # the shelf with the photo
	_prop(12, 33, 4, 1)    # the kitchen counter and sink
	_prop(16, 33, 2, 2)    # the fridge
	_prop(12, 46, 3, 1)    # the push-up bar
	_prop(24, 34, 4, 3)    # Hop's bed
	_prop(22, 34, 1, 1)    # the nightstand
	_prop(25, 46, 3, 2)    # the closet


func _prop(x: int, y: int, w: int, h: int) -> void:
	room.fill(x, y, w, h, Room.HOUSE_PROP)


func _tile(x: float, y: float) -> Vector2:
	return Vector2(x * T, y * T)


func _block(rect: Rect2, color: Color) -> void:
	_decor.draw_rect(rect, color)
	_decor.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), color.lightened(0.2))
	_decor.draw_rect(rect, color.darkened(0.4), false, 1.0)


func _draw_decor() -> void:
	# The street: a mailbox at Hop's, with HOP on it in marker.
	_block(Rect2(_tile(44.5, 10.5), Vector2(10, 14)), Color8(80, 85, 95))
	_decor.draw_string(_font, _tile(44.5, 10.5) + Vector2(-2, -3), "HOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color8(240, 240, 240))
	# --- The house ---
	# The couch, with a folded blanket.
	_block(Rect2(_tile(3, 44), Vector2(5 * T, 2 * T)), Color8(120, 70, 60))
	_decor.draw_rect(Rect2(_tile(3, 44) + Vector2(4, 4), Vector2(5 * T - 8, 10)), Color8(150, 92, 80))
	_decor.draw_rect(Rect2(_tile(6.5, 44) + Vector2(0, 14), Vector2(22, 10)), Color8(90, 110, 150))
	# The coffee table, with a checkers game nobody else played.
	var table := Rect2(_tile(4, 41), Vector2(3 * T, T))
	_block(table, Color8(110, 78, 50))
	for k in 12:
		_decor.draw_rect(Rect2(table.position + Vector2(10 + (k % 6) * 7, 4 + (k / 6) * 7), Vector2(5, 5)), Color8(200, 40, 40) if k < 3 else Color8(30, 30, 34))
	# The TV and a game console with one controller.
	_block(Rect2(_tile(3, 33) + Vector2(4, -10), Vector2(4 * T - 8, T + 6)), Color8(40, 40, 46))
	_decor.draw_rect(Rect2(_tile(3, 33) + Vector2(8, -6), Vector2(4 * T - 16, 14)), Color8(70, 90, 110))
	# The shelf, with a photo frame lying face-down.
	_block(Rect2(_tile(9, 33), Vector2(2 * T, T)), Color8(110, 78, 50))
	_decor.draw_rect(Rect2(_tile(9, 33) + Vector2(10, 4), Vector2(18, 6)), Color8(60, 45, 35))
	# The calendar on the wall.
	_decor.draw_rect(Rect2(_tile(7, 31) + Vector2(2, 2), Vector2(16, 20)), Color8(235, 230, 215))
	_decor.draw_rect(Rect2(_tile(7, 31) + Vector2(2, 2), Vector2(16, 5)), Color8(190, 60, 50))
	# The window, with a jar of bottle caps on the sill.
	_decor.draw_rect(Rect2(_tile(13, 31) + Vector2(0, 2), Vector2(2 * T, 2 * T - 4)), Color8(40, 50, 80) if not _morning() else Color8(170, 205, 235))
	_decor.draw_rect(Rect2(_tile(13, 31) + Vector2(0, 2), Vector2(2 * T, 2 * T - 4)), Color8(98, 70, 50), false, 2.0)
	_decor.draw_rect(Rect2(_tile(13.5, 32) + Vector2(4, 4), Vector2(10, 12)), Color(0.8, 0.9, 1.0, 0.6))
	for k in 5:
		_decor.draw_circle(_tile(13.5, 32) + Vector2(6 + (k % 3) * 3, 13 - (k / 3) * 3), 1.5, [Color8(200, 50, 50), Color8(230, 190, 60), Color8(60, 120, 200)][k % 3])
	# The kitchen: counter and sink (one plate, one cup), and the fridge.
	_block(Rect2(_tile(12, 33), Vector2(4 * T, T)), Color8(190, 190, 185))
	_decor.draw_rect(Rect2(_tile(13, 33) + Vector2(2, 4), Vector2(18, 10)), Color8(150, 160, 170))
	_decor.draw_circle(_tile(14.5, 33) + Vector2(6, 10), 4, Color8(240, 240, 235))
	_block(Rect2(_tile(16, 33) + Vector2(0, -8), Vector2(2 * T, 2 * T + 8)), Color8(225, 225, 225))
	_decor.draw_rect(Rect2(_tile(16, 33) + Vector2(10, 4), Vector2(12, 8)), Color8(230, 170, 60))
	# The push-up bar.
	_block(Rect2(_tile(12, 46) + Vector2(0, 8), Vector2(3 * T, 6)), Color8(60, 60, 66))
	# Hop's room: the bed (made, perfectly), the nightstand with a note, tally
	# marks on the wall, a mirror with a towel taped over it, and the closet.
	_block(Rect2(_tile(24, 34), Vector2(4 * T, 3 * T)), Color8(110, 80, 55))
	_decor.draw_rect(Rect2(_tile(24, 34) + Vector2(4, 4), Vector2(4 * T - 8, 12)), Color8(235, 235, 230))
	_decor.draw_rect(Rect2(_tile(24, 34) + Vector2(3, 18), Vector2(4 * T - 6, 3 * T - 22)), Color8(90, 95, 105))
	_block(Rect2(_tile(22, 34), Vector2(T, T)), Color8(110, 78, 50))
	_decor.draw_rect(Rect2(_tile(22, 34) + Vector2(5, 4), Vector2(10, 8)), Color8(245, 245, 235))
	for k in 24:
		var mark := _tile(20.5, 31) + Vector2(4 + (k % 12) * 3 + (k % 12) / 4 * 3, 6 + (k / 12) * 12)
		_decor.draw_line(mark, mark + Vector2(0, 8), Color8(40, 40, 46), 1.0)
	_decor.draw_string(_font, _tile(20.5, 31) + Vector2(10, 4), "DAYS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color8(40, 40, 46))
	_decor.draw_rect(Rect2(_tile(26.5, 31), Vector2(T + 4, 2 * T - 4)), Color8(160, 130, 70))
	_decor.draw_rect(Rect2(_tile(26.5, 31) + Vector2(2, 4), Vector2(T, 2 * T - 10)), Color8(230, 225, 210))
	_decor.draw_rect(Rect2(_tile(26.5, 31) + Vector2(6, 2), Vector2(12, 3)), Color8(200, 200, 190))
	_block(Rect2(_tile(25, 46), Vector2(3 * T, 2 * T)), Color8(120, 88, 60))
	_decor.draw_line(_tile(26.5, 46) + Vector2(0, 2), _tile(26.5, 48), Color8(80, 58, 40), 1.0)


func _add_streetlights() -> void:
	for x in [8, 20, 32, 44]:
		var lamp := Node2D.new()
		lamp.position = _tile(x, 13) + Vector2(0, 4)
		lamp.draw.connect(func() -> void:
			lamp.draw_rect(Rect2(-1.5, -44, 3, 44), Color8(70, 70, 76))
			lamp.draw_rect(Rect2(-1.5, -44, 12, 3), Color8(70, 70, 76))
			lamp.draw_rect(Rect2(6, -42, 8, 4), Color8(255, 190, 90))
		)
		if not _morning():
			var light := make_light(Color(1.0, 0.65, 0.3), 95.0, 1.2)
			light.position = Vector2(10, -6)
			lamp.add_child(light)
		world.add_child(lamp)


# --- People and things ----------------------------------------------------------

func _place_people() -> void:
	if _visiting():
		# Whoever's coming along follows Elric (nobody, if they're on their own).
		if Game.flags.get("met_hop", false) and not Game.walking_alone():
			hop = Cast.make(Game.partner())
			add_character(hop, player.position + Vector2(-20, -4))
			hop.follow = player
		return
	hop = Cast.make("Hop")
	if _px(HOUSE).has_point(player.position):
		add_character(hop, HOP_MORNING if _morning() else HOP_NIGHT)
		hop.on_interact = _talk_to_hop
		hop.add_to_group("interactable")
	else:
		add_character(hop, player.position + Vector2(-20, -4))
		hop.follow = player
	if not flag("glowbug_done"):
		glowbug = Cast.make("glowbug", false)
		glowbug.glow = true
		glowbug.glow_color = Color(1.0, 0.9, 0.4, 0.6)
		add_character(glowbug, GLOWBUG_SPOT)


func _place_hotspots() -> void:
	var spots := [
		[FRONT_DOOR, _front_door],
		[Vector2(10 * T, 48 * T + 10), _leave_house],
		[_tile(5.5, 46) + Vector2(0, 8), _couch],
		[_tile(5.5, 42) + Vector2(0, 8), _checkers],
		[_tile(5, 34) + Vector2(0, 10), _tv],
		[_tile(10, 34) + Vector2(0, 10), _photo],
		[_tile(8, 33) + Vector2(0, 10), _calendar],
		[_tile(14, 34) + Vector2(0, 10), _jar_and_sink],
		[_tile(17, 35) + Vector2(0, 8), _fridge],
		[_tile(13.5, 47) + Vector2(0, 8), _pushup_bar],
		[_tile(21.5, 33) + Vector2(0, 10), _tally_marks],
		[_tile(22.5, 35) + Vector2(0, 8), _note],
		[_tile(27, 33) + Vector2(0, 10), _mirror],
		[_tile(26.5, 45) + Vector2(0, 4), _closet],
		[_tile(26, 37) + Vector2(0, 10), _bed],
	]
	for spot in spots:
		world.add_child(Hotspot.create(spot[0], spot[1]))


# --- Story ------------------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if not is_inside_tree():
		return
	if _from_memory:
		while is_blocked() or not Game.keepsake_after.is_empty():
			await get_tree().process_frame
		await run_cutscene(_hopkuna_takes_it)
		return
	if _endgame() and not flag("hh_end_arrived"):
		Game.flags["hh_end_arrived"] = true
		await run_cutscene(_endgame_arrival)
		return
	if _visiting():
		if not flag("nb_arrived"):
			Game.flags["nb_arrived"] = true
			await run_cutscene(func() -> void:
				await Game.dialogue.say(["* (A quiet neighborhood. Little houses,\n*  porch lights, sprinklers ticking.)"]))
		return
	if Game.battle_result.get("id", "") == "glowbug":
		Game.battle_result = {}
		await run_cutscene(_after_glowbug)
	elif not flag("hh_arrived"):
		await run_cutscene(_arrival)
	elif _morning() and not flag("hh_seen_morning"):
		await run_cutscene(_wake_up)


func _physics_process(_delta: float) -> void:
	if is_blocked():
		return
	check_random_encounter(SCENE)
	if _visiting():
		if _px(STREET).has_point(player.position) and player.position.x < 10.0:
			run_cutscene(func() -> void: await Game.change_scene(WESTVIEW_SCENE, WESTVIEW_FROM_HERE))
		return
	if not flag("glowbug_done") and _px(STREET).has_point(player.position) and player.position.x > GLOWBUG_AT_X:
		run_cutscene(_glowbug)
	elif _px(STREET).has_point(player.position) and player.position.x < 10.0:
		if _morning():
			run_cutscene(func() -> void: await Game.change_scene(WESTVIEW_SCENE, WESTVIEW_FROM_HERE))
		else:
			run_cutscene(_wrong_way)


func _arrival() -> void:
	Game.flags["hh_arrived"] = true
	await Game.dialogue.say([
		"* (A quiet street. Porch lights. Sprinklers ticking\n*  somewhere in the dark.)",
		{"who": "Hop", "text": "My place isn't far.", "mood": ""},
		{"who": "Hop", "text": "...It's not much. It's just me.", "mood": "sad"},
	])
	Game.set_objective("Follow Hop home.")


func _wrong_way() -> void:
	await Game.dialogue.say([{"who": "Hop", "text": "My place is the other way.", "mood": ""}])
	await push_player(Vector2(30, 0))


## The glowbug, sitting on the sidewalk. There's no getting around it.
func _glowbug() -> void:
	Game.flags["glowbug_done"] = true
	await Game.dialogue.say([
		"* (Something small is sitting in the middle\n*  of the sidewalk.)",
		"* (A little glowbug. Its light flickers on and off.)",
		{"who": "Hop", "text": "Oh. Hey, little guy.", "mood": "happy"},
		{"who": "Hop", "text": "You lost too?", "mood": "sad"},
	])
	player.show_alert(true)
	await get_tree().create_timer(0.45).timeout
	await Game.start_battle("glowbug", SCENE, player.position)


func _after_glowbug() -> void:
	if glowbug:
		glowbug.queue_free()
	await Game.dialogue.say([
		"* (...)",
		{"who": "Hop", "text": "...Elric?", "mood": "shocked"},
		{"who": "Hop", "text": "It wasn't- it wasn't doing anything.", "mood": "shocked"},
		"* (Hop stares at the spot where the light was.)",
		{"who": "Hop", "text": "...", "mood": "sad"},
		{"who": "Hop", "text": "My place is just up here.", "mood": "sad"},
	])
	Game.set_objective("Go to Hop's house.")


func _front_door() -> void:
	if _endgame() and not flag("hh_fragment11"):
		await _endgame_door()
		return
	if _visiting():
		if hop and Game.partner() == "Hop":
			await Game.dialogue.say([{"who": "Hop", "text": "That's my place. It's a mess.\n...Maybe some other time.", "mood": "sad"}])
		else:
			await Game.dialogue.say(["* (The smallest house on the street.\n*  The door's locked. Nobody answers.)"])
		return
	if not flag("glowbug_done"):
		return
	if _morning():
		await Game.dialogue.say([{"who": "Hop", "text": "...Let's not go back in. Not yet.", "mood": "sad"}])
		return
	if not flag("hh_inside"):
		Game.flags["hh_inside"] = true
		await Game.dialogue.say([
			"* (Hop stops at the door.\n*  He doesn't open it right away.)",
			{"who": "Hop", "text": "...I said you could stay. So.", "mood": "sad"},
			"* (He unlocks the door.)",
		])
	hop.follow = null
	Game.play_sfx("door")
	await go_through_door(HOUSE_ENTRY)
	hop.position = HOP_NIGHT
	hop.on_interact = _talk_to_hop
	hop.add_to_group("interactable")
	var tint := get_node_or_null("Tint") as CanvasModulate
	if tint:
		tint.color = Color(0.82, 0.74, 0.66)
	if not flag("hh_house_seen"):
		Game.flags["hh_house_seen"] = true
		await Game.dialogue.say([
			{"who": "Hop", "text": "Couch is yours. Blanket's on it.", "mood": ""},
			{"who": "Hop", "text": "...Just don't go in my room. Okay?", "mood": "sad"},
		])
		Game.set_objective("Get some sleep. (The couch.)")


# --- The end: fragment 11 ------------------------------------------------------------

const SABRE_SCENE := "res://scenes/sabre_springs.tscn"


## It's time: Corps or own way, after the junkyard; with Hop, after the last of the Corps.
func _endgame() -> bool:
	if Game.on_genocide_route():
		return Game.corps_dead() >= 12
	return flag("jy_heap_done")


func _endgame_arrival() -> void:
	if Game.on_genocide_route():
		await Game.dialogue.say([
			"* (Hop's street. Quiet. Quieter than it's ever been.\n*  Nobody's sprinklers are on.)",
			{"who": "Hop", "text": "...Come inside.", "mood": ""},
		])
	else:
		await Game.dialogue.say([
			"* (Hop's street. His house is dark.)",
			"* (The circle on Nassan's map was always right here.)",
		])
	Game.set_objective("Hop's house. (The jar on the windowsill.)")


func _endgame_door() -> void:
	Game.play_sfx("door")
	if Game.on_genocide_route():
		await Game.dialogue.say(["* (Hop opens the door. He goes in first.)"])
	else:
		await Game.dialogue.say(["* (The door's unlocked. Hop never locks it.)"])
	await go_through_door(HOUSE_ENTRY)
	if hop and is_instance_valid(hop):
		hop.follow = null
		hop.position = HOP_MORNING
		hop.face(Vector2.DOWN)
	var tint := get_node_or_null("Tint") as CanvasModulate
	if tint:
		tint.color = Color(0.82, 0.74, 0.66)
	if not Game.on_genocide_route():
		await Game.dialogue.say([
			"* (Hop's house. One plate. One cup. One fork.)",
			"* (He's not here. His hat is on the hook by the door.)",
		])


func _fragment_eleven() -> void:
	if Game.on_genocide_route():
		if hop:
			hop.face(player.position - hop.position)
		await Game.dialogue.say([
			"* (Hop takes the jar down off the windowsill.)",
			{"who": "Hop", "text": "Relic wrote that. KEEP. On the jar.\nFor their bottle caps. They had so many.", "mood": "happy"},
			{"who": "Hop", "text": "I found it in the field. That morning.\nAfter. Lying in the ash, still warm.", "mood": "sad"},
			{"who": "Hop", "text": "I never broke it. I never told anyone.\nI couldn't let go of it.", "mood": "sad"},
			{"who": "Hop", "text": "I kept it for you.\nI always kept it for you.", "mood": "happy"},
			"* (He puts something red and warm in your hands.)",
		])
	else:
		await Game.dialogue.say([
			"* (The jar of bottle caps on the windowsill.\n*  KEEP, in someone else's handwriting.)",
			"* (You tip it out. Bottle caps. A ticket stub.\n*  A hair tie. A movie stub from five summers ago.)",
			"* (At the bottom: something red. Warm.)",
			"* (Hop found it in the burned field, at dawn,\n*  five years ago. He never broke it.\n*  He never told anyone.)",
		])
	Game.play_sfx("fragment")
	await Game.dialogue.say(["* (You got the eleventh FRAGMENT.)"])
	Game.flags["hh_fragment11"] = true
	Game.flags["has_fragment_11"] = true
	Game.flags["fragments"] = maxi(int(Game.flags.get("fragments", 10)), 11)
	await Game.dialogue.say(["* (It's warmer than all the others.\n*  You close your eyes.)"])
	await Game.play_keepsakes([11], SCENE, player.position, [
		"* (The fire. Relic, holding all of it.)",
		"* (\"Hop. Let go.\")",
	])


## Then the windows go red.
func _hopkuna_takes_it() -> void:
	# (Only one CanvasModulate works at a time: turn the night tint red, if there is one.)
	var red := get_node_or_null("Tint") as CanvasModulate
	if red == null:
		red = CanvasModulate.new()
		red.color = Color.WHITE
		add_child(red)
	red.color = red.color * Color(1.0, 0.55, 0.55)
	Game.play_sfx("black_flash")
	if Game.on_genocide_route():
		if hop:
			hop.face(player.position - hop.position)
		await Game.dialogue.say([
			"* (Hop's hand closes around the fragment, over yours.)",
			"* (It isn't Hop closing it.)",
			{"who": "Hopkuna", "text": "MINE.", "mood": ""},
			"* (Hopkuna tears it out of your hands. He's terrified.\n*  You can see it. He's never been scared before.)",
			{"who": "Hopkuna", "text": "The last one. North. If I get there first,\nyou can't- you CAN'T-", "mood": ""},
			"* (He goes through the window. He flies. North.)",
			{"who": "Relic", "tag": "", "face": false, "text": "* Let him run.\n* We know where he's going."},
		])
		if hop:
			hop.queue_free()
			hop = null
	else:
		var hk := add_character(Cast.make("hopkuna"), player.position + Vector2(0, -60))
		hk.glow = true
		hk.glow_color = Color(1.0, 0.15, 0.2, 0.5)
		hk.face(Vector2.DOWN)
		await Game.dialogue.say([
			"* (The windows go red.)",
			"* (He's inside. He was always going to come here.)",
			{"who": "Hopkuna", "text": "The one he hid from me. Five years.\nIn a JAR.", "mood": ""},
			"* (The fragment tears out of your hands and into his.)",
			{"who": "Hopkuna", "text": "...There you are. I can feel the last one now.\nNorth. Buried. The biggest one.", "mood": ""},
			"* (He's gone, through the window, over the rooftops,\n*  toward Carmel Mountain Ranch.)",
		])
		hk.queue_free()
		if Game.flags.get("route", "") == "pacifist":
			await Game.dialogue.say([
				"* (Outside: a horn. HONK HONK. A tan van, in the street,\n*  full of people.)",
				{"who": "Sansworth", "text": "EVERYBODY IN THE VAN!", "mood": "happy"},
			])
		else:
			await Game.dialogue.say([
				"* (Outside, a van goes past, full of people,\n*  horn blaring, heading north.)",
				"* (Nobody sees you in the window.)",
				"* (You follow on foot. All night.)",
			])
	Game.set_objective("Sabre Springs. (Where it began.)")
	await Game.change_scene(SABRE_SCENE)


func _talk_to_hop() -> void:
	hop.face(player.position - hop.position)
	if _morning():
		await chat("hop_morning", [], [
			[{"who": "Hop", "text": "...Eat something.", "mood": "sad"}],
			[{"who": "Hop", "text": "...", "mood": "sad"}],
			[{"who": "Hop", "text": "We should probably go. Somewhere.\n...I don't know where.", "mood": "sad"}],
		])
		return
	await chat("hop_night", [], [
		[{"who": "Hop", "text": "...Get some sleep, Elric.", "mood": "sad"}],
		[{"who": "Hop", "text": "...", "mood": "sad"}],
		[{"who": "Hop", "text": "I'm not tired. I'll just... sit up for a while.", "mood": "sad"}],
	])


func _couch() -> void:
	if _morning():
		await Game.dialogue.say(["* (The blanket is folded, the way Hop left it.)"])
		return
	var sleep := await Game.dialogue.ask("* (Hop's couch. A blanket's folded on it.\n*  Sleep?)", ["Sleep", "Not yet"])
	if sleep != 0:
		return
	Game.flags["hh_slept"] = true
	# Dark, but under the text box (Game.fade_out covers the text box too).
	var night := CanvasLayer.new()
	night.layer = 45
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.size = Vector2(640, 480)
	black.modulate.a = 0.0
	night.add_child(black)
	add_child(night)
	await create_tween().tween_property(black, "modulate:a", 1.0, 1.2).finished
	Game.stop_music(1.0)
	await Game.dialogue.say([
		"* (You lie down on Hop's couch.)",
		"* (Across the room, Hop doesn't sleep.\n*  You can hear him sitting in the dark.)",
		"* (You dream. But not your own dreams.)",
	])
	Game.heal_party()
	Game.save_game(SCENE, WAKE_SPOT)
	if int(Game.flags.get("keepsakes_seen", 0)) < 3:
		await Game.play_keepsakes([1, 2, 3], SCENE, WAKE_SPOT)
		return
	await Game.change_scene(SCENE, WAKE_SPOT)


func _wake_up() -> void:
	Game.flags["hh_seen_morning"] = true
	await Game.dialogue.say([
		"* (Morning light comes in through the blinds.)",
		{"who": "Hop", "text": "...Morning.", "mood": "sad"},
		{"who": "Hop", "text": "I made pancakes. They're... pancake-shaped.\nMostly.", "mood": ""},
		"* (He puts the only plate in front of you.)",
		"* (He doesn't sit down. He eats standing up, by\n*  the sink, as far from you as the kitchen allows.)",
		{"who": "Hop", "text": "...Your eyes.", "mood": "shocked"},
		{"who": "Hop", "text": "Are they... green? Were they always green?", "mood": "shocked"},
		{"who": "Hop", "text": "...Ha. Weird lighting in here.\nI should get a new bulb.", "mood": "sad"},
	])
	Game.set_objective("Head out with Hop. (The front door.)")


func _leave_house() -> void:
	if not _morning():
		await Game.dialogue.say([{"who": "Hop", "text": "...It's late. Stay in. Please.", "mood": "sad"}])
		return
	var go := await Game.dialogue.ask("* (Head out?)", ["Go", "Not yet"])
	if go != 0:
		return
	# Out the front door, with Hop.
	hop.on_interact = Callable()
	hop.remove_from_group("interactable")
	Game.play_sfx("door")
	await go_through_door(OUTSIDE_DOOR)
	hop.position = OUTSIDE_DOOR + Vector2(-22, 0)
	hop.follow = player
	if not flag("hh_out"):
		Game.flags["hh_out"] = true
		await _first_warning()
	Game.save_game(SCENE, OUTSIDE_DOOR)


## Out on the porch, the first morning: the voice inside Hop says something.
func _first_warning() -> void:
	await get_tree().create_timer(0.6).timeout
	hop.follow = null
	await Game.dialogue.say([
		"* (On the porch, Hop stops.\n*  His hand goes to his chest.)",
		{"who": "Hopkuna", "face": false, "text": "...Hop."},
		{"who": "Hopkuna", "face": false, "text": "That isn't your friend."},
		{"who": "Hop", "text": "Shut up.", "mood": "angry"},
		{"who": "Elric", "choices": ["...Hop?", "(Say nothing.)"], "replies": [
			[{"who": "Hop", "text": "...Not you. Nothing. Talking to myself.", "mood": "sad"}],
			["* (Hop sees you looking at him.)", {"who": "Hop", "text": "...That wasn't to you. Talking to myself.", "mood": "sad"}]]},
		{"who": "Hop", "text": "Nassan's map had a circle on the beach.\nMission Beach. That's the next one.", "mood": ""},
		{"who": "Hop", "text": "There's a bus from the PQ Mall.\n...Let's just go.", "mood": "sad"},
	])
	hop.follow = player
	Game.set_objective("Take the bus at the PQ Mall to Mission Beach.")


# --- Looking around Hop's house -----------------------------------------------------

func _checkers() -> void:
	await Game.dialogue.say([
		"* (A checkers game, half finished.\n*  Red is losing badly.)",
		"* (Both sides were played by the same person.)",
	])


func _tv() -> void:
	await Game.dialogue.say([
		"* (An old TV, and a game console.)",
		"* (There's a second controller in the drawer.\n*  It doesn't look like it's been touched in years.)",
	])


func _photo() -> void:
	await Game.dialogue.say(["* (A photo frame, lying face-down on the shelf.)"])
	if await Game.dialogue.ask("* (Turn it over?)", ["Turn it over", "Leave it"]) != 0:
		return
	var lines: Array = [
		"* (Two kids in front of a tent, squinting into the\n*  sun. Westview Field, a long time ago.)",
		"* (One of them is Hop.)",
		"* (The other one's face is rubbed away,\n*  like someone touched it too many times.)",
	]
	if not _morning() and not flag("seen_hh_photo"):
		Game.flags["seen_hh_photo"] = true
		lines.append({"who": "Hop", "text": "...Put that back. Please.", "mood": "sad"})
	await Game.dialogue.say(lines)


func _calendar() -> void:
	await Game.dialogue.say([
		"* (A calendar from five years ago. Still on the wall.)",
		"* (It stops at the end of August.\n*  Nobody ever turned the page.)",
	])


func _jar_and_sink() -> void:
	if _endgame() and not flag("hh_fragment11"):
		await run_cutscene(_fragment_eleven)
		return
	await Game.dialogue.say([
		"* (The sink. One plate. One cup. One fork.)",
		"* (On the windowsill above it: a jar of bottle caps.\n*  Hop doesn't drink soda.)",
		"* (The label on the jar is in someone else's\n*  handwriting. It just says: KEEP.)",
	])


func _fridge() -> void:
	await Game.dialogue.say([
		"* (Jack in the Box coupons, held up by magnets.)",
		"* (One is for two orders of curly fries.\n*  It expired years ago. He kept it.)",
	])


func _pushup_bar() -> void:
	await Game.dialogue.say(["* (A push-up bar, with a sticky note on it:\n*  \"FORTY. CAN'T FEEL ARMS = GOOD.\")"])


func _tally_marks() -> void:
	await Game.dialogue.say([
		"* (Tally marks on the wall. Hundreds of them.)",
		"* (Above them, in marker: DAYS.)",
		"* (The count stops at yesterday.)",
	])


func _note() -> void:
	await Game.dialogue.say([
		"* (A note on the nightstand, in Hop's handwriting.)",
		"* DON'T LET HIM OUT.\n* NOT EVER. NOT FOR ANYTHING.",
		"* (It's been underlined so many times\n*  the paper tore.)",
	])


func _mirror() -> void:
	await Game.dialogue.say(["* (A mirror. There's a towel taped over it.)"])
	if await Game.dialogue.ask("* (Lift the towel?)", ["Lift it", "Leave it"]) != 0:
		return
	# (On the Genocide route, Relic finally says their name.)
	if Game.on_genocide_route():
		await Game.dialogue.say(["* (You lift a corner of the towel.)", "* It's me, RELIC."])
	else:
		await Game.dialogue.say(["* (You lift a corner of the towel.)", "* (In the glass: it's you.)"])


func _closet() -> void:
	await Game.dialogue.say([
		"* (The closet. Shoved in the very back:\n*  a tent, folded up small.)",
		"* (One side of it is melted.)",
	])


func _bed() -> void:
	await Game.dialogue.say(["* (Hop's bed. It's made. Perfectly.\n*  Like nobody sleeps in it.)"])
