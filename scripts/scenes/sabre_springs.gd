extends Area
## Sabre Springs Community Park, in Carmel Mountain Ranch, at night: just up the
## road from Mt. Carmel High, where Elric first walked into the story. Ball fields,
## a playground, a creek, and in the middle, the grass torn open where Hopkuna dug.
## He's standing over fragment 12, the biggest of them all, and he absorbs it.
##
## The last keepsake floods out as he does, into Elric, because it was always
## Elric's: the night of the fire, Relic breaking, their blood on the last piece,
## and their wish for a home, too big for a bottle cap, made into a keepsake that
## could walk. At dawn, in this park, someone with purple skin opens their eyes.
##
##   Corps      The whole Corps steps out of the van. "Thirteen of us. One of you."
##              Hopkuna, Unbound: talk to Hop, call your friends, BOND, and
##              "Hop. Let go." The token holds him. Then the ending: HOME.
##   Own way    Elric learns what they are, alone. Hopkuna and the Corps both turn
##              to Elric for the fragments: The Road, The Gift, or The Bargain.
##   With Hop   Relic turns on Hopkuna, and keeps him. (Or, under 75 kills, Elric
##              is still in there, and can let go.)
##
## Story flags: ss_arrived, ss_absorbed, ss_done, ending.

const SCENE := "res://scenes/sabre_springs.tscn"
const ENDING_SCENE := "res://scenes/ending.tscn"
const T := Room.TILE
const OUTSIDE := Rect2i(0, 0, 50, 36)
const ENTRY := Vector2(36 * T, 32 * T)
const CENTER := Vector2(25 * T, 15 * T)
const CORPS := ["BigJoe6", "Eggo", "Nassan", "Nat", "NCWethan", "Ronin", "Supreme", "Crayola", "Rooster", "Agent", "MuffinMage", "Sansworth"]

var partner: Character
var hopkuna: Character
var _decor: Node2D
var _shade: Node2D
var _font: Font
var _time: float = 0.0
var _engaged: bool = false
## The green-white of the last keepsake, washing over everything.
var _flood: float = 0.0
var _circle: Array[Character] = []


func _ready() -> void:
	_engaged = str(Game.battle_result.get("id", "")) in ["hopkuna_unbound", "hopkuna_underdog"]
	rooms.assign([_px(OUTSIDE)])
	setup_area(ENTRY)
	_font = ThemeDB.fallback_font
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	_shade = Node2D.new()
	add_child(_shade)
	_shade.draw.connect(_draw_shade)
	_place_people()
	world.add_child(Hotspot.create(Vector2(8 * T + 10, 30 * T + 4), _sign))
	Game.stop_music(1.0)
	fit_camera_to_room()
	_start.call_deferred()


static func _px(r: Rect2i) -> Rect2:
	return Rect2(r.position * T, r.size * T)


func _route() -> String:
	return str(Game.flags.get("route", ""))


func _genocide() -> bool:
	return Game.on_genocide_route()


func _process(delta: float) -> void:
	_time += delta
	_decor.queue_redraw()
	_shade.queue_redraw()


# --- The map -----------------------------------------------------------------------

func build_map() -> void:
	room.setup(50, 36, Room.GRASS)
	room.fill(0, 0, 50, 1, Room.TREE)
	room.fill(49, 0, 1, 36, Room.TREE)
	room.fill(0, 35, 50, 1, Room.TREE)
	room.fill(0, 0, 3, 36, Room.WATER)          # the creek
	room.fill(3, 0, 1, 36, Room.SAND)
	# The ball field, the playground, the parking lot.
	room.fill(6, 2, 14, 10, Room.FIELD)
	room.fill(6, 2, 14, 1, Room.FIELD_LINE)
	room.fill(36, 3, 8, 6, Room.PROP)
	room.fill(26, 28, 22, 7, Room.ASPHALT)
	room.fill(26, 28, 22, 1, Room.PARKING_LINE)
	# The torn ground in the middle, where he dug.
	room.fill(21, 12, 9, 6, Room.DIRT)
	for spot in [Vector2i(10, 18), Vector2i(14, 25), Vector2i(34, 14), Vector2i(41, 20), Vector2i(8, 30), Vector2i(20, 30), Vector2i(44, 12), Vector2i(30, 6)]:
		room.set_tile(spot.x, spot.y, Room.TREE)


func _draw_decor() -> void:
	# The fragment, glowing in the torn ground (until he takes it).
	if not flag("ss_absorbed"):
		var pulse := 0.6 + 0.4 * sin(_time * 3.0)
		_decor.draw_circle(CENTER + Vector2(0, 20), 70.0 * pulse, Color(1.0, 0.2, 0.25, 0.12))
		_decor.draw_circle(CENTER + Vector2(0, 20), 9.0, Color(1.0, 0.25, 0.3, 0.9))
	# Furrows in the torn ground.
	for k in 8:
		var a := Vector2(21 * T + k * 22, 12 * T + 6)
		_decor.draw_line(a, a + Vector2(10, 100), Color8(90, 60, 40), 2.0)
	# The playground: a slide and swings.
	_decor.draw_rect(Rect2(36 * T, 3 * T, 8 * T, 6 * T), Color8(120, 100, 80))
	_decor.draw_line(Vector2(38 * T, 3 * T + 10), Vector2(42 * T, 8 * T), Color8(220, 80, 60), 5.0)
	for k in 3:
		_decor.draw_line(Vector2(37 * T + k * 30, 4 * T), Vector2(37 * T + k * 30 + sin(_time + k) * 6.0, 6 * T), Color8(150, 150, 160), 1.0)
	# The park sign by the lot.
	_decor.draw_rect(Rect2(6 * T, 29 * T, 5 * T, 26), Color8(90, 70, 50))
	_decor.draw_string(_font, Vector2(6 * T + 6, 29 * T + 17), "SABRE SPRINGS PARK", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(240, 230, 210))
	# The van, if the Corps came in it.
	if _route() == "pacifist" or flag("jy_van"):
		_decor.draw_rect(Rect2(40 * T, 30 * T, 5 * T, 3 * T), Color8(200, 180, 140))
		_decor.draw_rect(Rect2(40 * T + 6, 30 * T + 6, 30, 16), Color8(120, 160, 190))


## Night. And then the flood of the last keepsake: green-white, everywhere.
func _draw_shade() -> void:
	_shade.draw_rect(_px(OUTSIDE), Color(0.05, 0.05, 0.18, 0.4))
	if _flood > 0.0:
		_shade.draw_rect(_px(OUTSIDE), Color(0.75, 1.0, 0.8, _flood))


# --- People ----------------------------------------------------------------------

func _place_people() -> void:
	if not Game.walking_alone() and not _genocide():
		partner = Cast.make(Game.partner())
		add_character(partner, player.position + Vector2(-20, 0))
		partner.follow = player
	elif _genocide():
		pass
	if not flag("ss_done"):
		hopkuna = Cast.make("hopkuna")
		hopkuna.glow = true
		hopkuna.glow_color = Color(1.0, 0.15, 0.2, 0.5)
		add_character(hopkuna, CENTER)
		hopkuna.face(Vector2.DOWN)


func _sign() -> void:
	await Game.dialogue.say(["* (SABRE SPRINGS COMMUNITY PARK.\n*  PLEASE KEEP OFF THE GRASS.)", "* (The grass is not doing well tonight.)"])


# --- Story ------------------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if not is_inside_tree():
		return
	var id := str(Game.battle_result.get("id", ""))
	if id in ["hopkuna_unbound", "hopkuna_underdog"]:
		var spared: bool = not Game.battle_result.get("spared", []).is_empty()
		Game.battle_result = {}
		await run_cutscene(_after_unbound if id == "hopkuna_unbound" else _after_underdog.bind(spared))
		return
	if not flag("ss_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked() or _engaged:
		return
	if hopkuna and is_instance_valid(hopkuna) and not flag("ss_absorbed") and player.position.distance_to(hopkuna.position) < 110.0:
		run_cutscene(_the_last_keepsake)


func _arrival() -> void:
	Game.flags["ss_arrived"] = true
	match _route():
		"pacifist":
			await Game.dialogue.say([
				"* (The van skids into the lot. Everyone piles out.)",
				"* (Sabre Springs Community Park. Up the road from\n*  Mt. Carmel High, where you first walked into all this.)",
				"* (The grass in the middle of the park is torn open.\n*  Something dug here. Something red is shining in it.)",
				"* (Standing over it: Hop. Hopkuna.)",
			])
		"neutral":
			await Game.dialogue.say([
				"* (You walked all night. The sky is just starting\n*  to go gray.)",
				"* (Sabre Springs Community Park. Up the road from\n*  Mt. Carmel High, where you first walked into all this.)",
				"* (The Corps' van is in the lot. They're hanging back,\n*  by the trees. They don't see you yet.)",
				"* (In the torn grass in the middle: Hopkuna.)",
			])
		_:
			await Game.dialogue.say([
				"* (Sabre Springs Community Park. We walked.\n*  We didn't hurry.)",
				{"who": "Relic", "tag": "", "face": false, "text": "* Up the road from where Elric woke up.\n* Funny."},
				"* (In the torn grass in the middle: Hopkuna,\n*  holding the last fragment over his head.)",
			])
	Game.set_objective("...")


## Hopkuna absorbs the last fragment. The last keepsake floods out, into Elric.
func _the_last_keepsake() -> void:
	if _engaged:
		return
	_engaged = true
	hopkuna.face(player.position - hopkuna.position)
	await Game.dialogue.say([
		{"who": "Hopkuna", "text": "There you are. Just in time.", "mood": ""},
		{"who": "Hopkuna", "text": "Twelve. All twelve. Do you feel it, little wanderer?\nOf course you do. You were always going to.", "mood": ""},
		"* (He closes his hand around the last fragment.)",
		"* (It goes into him. All of them go into him.)",
	])
	Game.flags["ss_absorbed"] = true
	Game.play_sfx("black_flash")
	var flood := create_tween()
	flood.tween_property(self, "_flood", 0.85, 1.6)
	await flood.finished
	Game.play_music("relic", 2.0)
	await Game.dialogue.say([
		"* (And something comes OUT of it. Into you.\n*  It was never his memory. It was always yours.)",
		"* (The fire. Relic, breaking apart, with all of\n*  Hopkuna's power in their hands.)",
		"* (Twelve pieces, scattered on the wind.)",
		"* (Relic is bleeding. Their blood soaks into the last\n*  piece, the biggest, as the wind takes it.)",
		"* (And one more thing goes with it. The one thing Relic\n*  never put in anything, because they never let\n*  anyone carry it for them.)",
		"* (Their wish for a home.)",
		"* (Relic keeps it the only way they know how.\n*  They make it a keepsake.)",
		"* (But a wish that big doesn't fit in a bottle cap.\n*  It needs a shape that can walk.)",
		"* (The wind carries the fragment north, all night,\n*  and drops it in a quiet park.)",
		"* (At dawn, beside it, in the wet grass of Sabre Springs,\n*  someone with purple skin opens their eyes\n*  for the first time.)",
		"* (They don't remember anything. They just know\n*  they have to keep walking.)",
		"* (It's you. It's this park.)",
	])
	var clear := create_tween()
	clear.tween_property(self, "_flood", 0.0, 1.6)
	await clear.finished
	match _route():
		"pacifist":
			await _corps_circle()
		"neutral":
			await _the_choice()
		_:
			await _relic_turns()


# --- Corps: the circle ---------------------------------------------------------------

func _corps_circle() -> void:
	await Game.dialogue.say([
		{"who": "Relic", "tag": "", "face": false, "text": "* It's me. Relic."},
		{"who": "Relic", "tag": "", "face": false, "text": "* I made you."},
		{"who": "Relic", "tag": "", "face": false, "text": "* I'm sorry I made you lonely.\n* I didn't know how to make anything else."},
		{"who": "Elric", "choices": ["...You didn't.", "(Say nothing.)"]},
		{"who": "Hopkuna", "text": "Touching. Now, little keepsake. You're the last\npiece of Relic. Come here and I'll have ALL of them.", "mood": ""},
		"* (Behind you, car doors. Footsteps. A lot of them.)",
	])
	var ids: Array = CORPS.filter(func(id: String) -> bool: return id != Game.partner())
	for i in ids.size():
		var angle := PI * 0.15 + i * PI * 0.7 / maxf(ids.size() - 1, 1)
		var member := add_character(Cast.make(ids[i]), player.position + Vector2(0, 160))
		_circle.append(member)
		member.walk_to(CENTER + Vector2.from_angle(angle) * Vector2(150, 110), 160.0)
	if partner:
		partner.follow = null
		partner.walk_to(player.position + Vector2(-30, 10), 100.0)
	await get_tree().create_timer(2.2).timeout
	for member in _circle:
		member.face(CENTER - member.position)
	await Game.dialogue.say([
		"* (All twelve of them. In a circle, the way they\n*  stood on the field the night you met.)",
		{"who": "Agent", "text": "Thirteen of us. One of you.\nI already did the math.", "mood": "smug"},
		{"who": "BigJoe6", "text": "BY THE RULES, HOPKUNA. All of us. Fair.", "mood": "angry"},
		{"who": "Eggo", "text": "...Hop. We're gonna talk to you now. Okay?\nThat's all. We're just gonna talk.", "mood": "sad"},
		{"who": "Hopkuna", "text": "...", "mood": ""},
		{"who": "Hopkuna", "text": "FINE. ALL of you, then.", "mood": ""},
	])
	await Game.start_battle("hopkuna_unbound", SCENE, player.position)


func _after_unbound() -> void:
	Game.flags["ss_done"] = true
	if hopkuna and is_instance_valid(hopkuna):
		hopkuna.face(player.position - hopkuna.position)
	await Game.dialogue.say([
		"* (You say it. In your voice, and in Relic's,\n*  underneath.)",
		"* (\"Hop. Let go.\")",
		"* (And this time, Hop isn't alone when he does.)",
		"* (He lets go of Hopkuna. He lets go of Relic.)",
		"* (Everything Hopkuna is pours out of Hop, toward you.\n*  It's so heavy. It's the heaviest thing in the world.)",
		"* (Twelve hands are on your shoulders.\n*  Nobody lets you fall.)",
		"* (You do what Relic did. You don't break.)",
		"* (You keep him in the curly-fry token. The last thing\n*  in Relic's collection, holding the thing Relic\n*  died trying to hold.)",
		"* (It doesn't break. Thirteen people are carrying it.)",
	])
	if hopkuna and is_instance_valid(hopkuna):
		var where := hopkuna.position
		hopkuna.queue_free()
		hopkuna = add_character(Cast.make("Hop"), where)
		hopkuna.face(player.position - hopkuna.position)
	await Game.dialogue.say([
		"* (Hop is on his knees in the torn grass.\n*  His eyes are brown.)",
		"* (A voice, from the token. Quiet, for the first time ever.)",
		{"who": "Hopkuna", "text": "...It's dark in here.", "mood": ""},
		{"who": "Hop", "text": "Yeah. I know.", "mood": "sad"},
		{"who": "Hop", "text": "I'll talk to you sometimes.", "mood": ""},
	])
	Game.flags["ending"] = "home"
	await Game.change_scene(ENDING_SCENE)


# --- Own way: the choice ----------------------------------------------------------------

func _the_choice() -> void:
	await Game.dialogue.say([
		{"who": "Relic", "tag": "", "face": false, "text": "* It's me. Relic. I made you."},
		{"who": "Relic", "tag": "", "face": false, "text": "* I'm sorry I made you lonely.\n* I didn't know how to make anything else."},
		"* (You learn what you are alone, in the park\n*  where you were born. Nobody's next to you.)",
		"* (Out of the trees: the Corps. All of them.\n*  They've seen you now.)",
		{"who": "Hopkuna", "text": "The rest of them, little keepsake. The ones in your\npockets. Give them to me, and I'll be whole.", "mood": ""},
		{"who": "Nassan", "text": "Elric. Please. Give them to us.\nWe'll do what Relic did. We'll hold him.", "mood": "sad"},
		{"who": "Hop", "text": "(from somewhere inside) ...Elric. Whatever you do.\nIt's okay. It was always okay.", "mood": "sad"},
	])
	var choice := await Game.dialogue.ask("* (Everyone's looking at you. The fragments\n*  in your pockets are burning.)", ["Walk away.", "Give them to the Corps.", "Give them to Hopkuna."])
	Game.flags["ss_done"] = true
	Game.flags["ending"] = ["road", "gift", "bargain"][choice]
	await Game.change_scene(ENDING_SCENE)


# --- With Hop: Relic turns ---------------------------------------------------------------

func _relic_turns() -> void:
	await Game.dialogue.say([
		{"who": "Relic", "tag": "", "face": false, "text": "* A home.\n* Ha."},
		{"who": "Relic", "tag": "", "face": false, "text": "* We don't need a home. We have everything."},
		{"who": "Relic", "tag": "", "face": false, "text": "* Give them to us."},
		{"who": "Hopkuna", "text": "Ha! You? What are you going to-", "mood": ""},
		{"who": "Hopkuna", "text": "...", "mood": ""},
		{"who": "Hopkuna", "text": "Oh.", "mood": ""},
		"* (He understands. He's the only one who ever did.)",
		{"who": "Hopkuna", "text": "That isn't them. Relic would NEVER smile like that.\nHop. HOP. Wake up. Let me out. RUN-", "mood": ""},
	])
	await Game.start_battle("hopkuna_underdog", SCENE, player.position)


func _after_underdog(_spared: bool) -> void:
	Game.flags["ss_done"] = true
	if hopkuna and is_instance_valid(hopkuna):
		var where := hopkuna.position
		hopkuna.queue_free()
		hopkuna = add_character(Cast.make("Hop"), where)
		hopkuna.face(player.position - hopkuna.position)
	await Game.dialogue.say([
		"* (We pull all of him out of Hop. The way we did\n*  the night of the fire.)",
		"* (This time, we don't break. We keep it.\n*  We've stopped caring what it costs.)",
		"* (Hop, alone with his friend in the torn-up grass.)",
		{"who": "Hop", "text": "Relic. Please.", "mood": "sad"},
		{"who": "Hop", "text": "Let go.", "mood": "sad"},
	])
	var kills := int(Game.flags.get("kills", 0))
	if kills >= 75:
		await Game.dialogue.say([
			{"who": "Relic", "tag": "", "face": false, "text": "* I let go of everything, my whole life.\n* Everyone else's pain."},
			{"who": "Relic", "tag": "", "face": false, "text": "* Now it's my turn to keep something."},
		])
		Game.flags["ending"] = "one"
	else:
		await Game.dialogue.say([
			{"who": "Relic", "tag": "", "face": false, "text": "* I let go of everything, my whole life."},
			"* (But it isn't all Relic, in there. Not yet.\n*  Somewhere under the green, there's still you.)",
		])
		var choice := await Game.dialogue.ask("* (Hop is waiting. So are you.)", ["Let go.", "Keep him."])
		Game.flags["ending"] = "let_go" if choice == 0 else "one"
	await Game.change_scene(ENDING_SCENE)
