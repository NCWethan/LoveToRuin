extends Area
## Torrey Pines (fragment 9): cliffs over the ocean, the rarest pines in the world
## bent sideways by the wind, a lodge, a gliderport with a windsock. And over the
## edge, a hang glider with nobody in the harness, hanging in the air for five
## years. It won't come down.
##
## The Glider (torrey_battles.gd) has the fragment. Its KEEPSAKE is this same cliff
## at dawn, five years ago: Relic, packed to leave town like every town before,
## standing at the edge a long time. Then unpacking. "First place I ever wanted to
## stay."
##
## Reached by bus (from any stop) once fragment 8 is found.
##
##   Corps      Hop left the base after the vote. He's here, at the viewpoint.
##              Rooster has to help with the Glider (he's terrified of heights).
##              Then Hopkuna takes Hop over, stronger than ever, beats everyone
##              (a fight you can't win, only survive), and takes the fragments.
##              "You've been breaking my things. Thank you."
##   Own way    The voice of Relic: "You keep walking away from people. I did
##              that too." Hop finds Elric at the viewpoint, and tells them
##              everything. Rooster is at the gliderport, roasting, not helping.
##   With Hop   Rooster is at the gliderport. The jokes fall apart.
##
## Story flags: tp_arrived, tp_hop_talk, tp_glider_done, tp_fragment,
## has_fragment_9, tp_stolen (Corps: Hopkuna took the fragments).

const SCENE := "res://scenes/torrey_pines.tscn"
const T := Room.TILE
const OUTSIDE := Rect2i(0, 0, 64, 32)
const ENTRY := Vector2(60 * T, 28 * T + 10)
## The Glider, hanging over the cliff edge; the viewpoint where Hop sits; the
## gliderport, where Rooster is.
const GLIDER_SPOT := Vector2(10 * T, 6 * T)
const GLIDER_EDGE := Vector2(17 * T, 6 * T + 10)
const VIEWPOINT := Vector2(17 * T, 21 * T + 10)
const ROOSTER_SPOT := Vector2(24 * T, 7 * T)
const LODGE_DOOR := Vector2(48 * T + 10, 9 * T + 4)
const DORIS := Vector2(38 * T + 10, 21 * T)

var partner: Character
var hop: Character
var rooster: Character
var glider: Character
var _decor: Node2D
var _shade: Node2D
var _font: Font
var _time: float = 0.0
var _engaged: bool = false
var _from_memory: bool = false


func _ready() -> void:
	_from_memory = not Game.keepsake_after.is_empty() and not Game.playing_relic
	_engaged = str(Game.battle_result.get("id", "")) in ["glider", "corps_rooster", "hopkuna_cliffs"]
	rooms.assign([_px(OUTSIDE)])
	setup_area(ENTRY)
	add_wild_encounters(SCENE, Rect2(16 * T, 13 * T, 46 * T, 18 * T))
	_font = ThemeDB.fallback_font
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	_shade = Node2D.new()
	add_child(_shade)
	_shade.draw.connect(_draw_shade)
	_place_people()
	_dress()
	for spot in [[ENTRY + Vector2(10, -8), _bus_stop], [LODGE_DOOR, _lodge], [Vector2(19 * T + 10, 4 * T + 4), _windsock],
			[Vector2(18 * T + 10, 25 * T + 4), _plaque], [DORIS + Vector2(0, 24), _doris]]:
		world.add_child(Hotspot.create(spot[0], spot[1]))
	Game.play_music("torrey")
	fit_camera_to_room()
	_start.call_deferred()


static func _px(r: Rect2i) -> Rect2:
	return Rect2(r.position * T, r.size * T)


func _genocide() -> bool:
	return Game.on_genocide_route()


func _route() -> String:
	return str(Game.flags.get("route", ""))


func _process(delta: float) -> void:
	_time += delta
	_decor.queue_redraw()
	# The Glider bobs on the wind.
	if glider and is_instance_valid(glider):
		glider.position = GLIDER_SPOT + Vector2(sin(_time * 0.7) * 10.0, sin(_time * 1.3) * 6.0)


# --- The map -----------------------------------------------------------------------

## Set dressing (props.gd): trail signs, the cliff warning, rocks and fallen logs
## and scrub along the trail, a picnic table by the lodge, the gliderport's gear.
func _dress() -> void:
	add_dressing([
		["sign", Vector2(33 * T + 4, 26 * T + 10), {"text": "GUY FLEMING TRAIL", "color": Color8(110, 80, 50), "look": ["* (GUY FLEMING TRAIL. 0.7 MI. EASY.)", "* (Someone crossed out EASY and wrote: LIAR.)"]}],
		["sign", Vector2(16 * T + 12, 14 * T + 12), {"text": "CLIFF EDGE", "color": Color8(190, 50, 40), "look": ["* (DANGER: UNSTABLE CLIFF EDGE.\n*  STAY BEHIND THE RAIL.)", "* (The rail is very short. The cliff is very tall.)"]}],
		["crates", Vector2(25 * T, 3 * T + 10), {"look": ["* (Harnesses, helmets, a folded wing.\n*  A tag says: RENTALS RETURN BY SUNSET.)"]}],
		["picnic_table", Vector2(42 * T, 13 * T + 10), {"look": ["* (A picnic table with a view of the ocean.\n*  Someone carved a little whale into it.)"]}],
		["trash_can", Vector2(52 * T + 10, 9 * T + 10)],
		["potted_plant", Vector2(46 * T + 10, 9 * T + 6)],
		["potted_plant", Vector2(50 * T + 10, 9 * T + 6)],
		["rock", Vector2(26 * T, 14 * T)],
		["rock", Vector2(34 * T, 18 * T)],
		["rock", Vector2(48 * T, 25 * T + 10), {"look": ["* (A sandstone rock, carved by the wind into\n*  something that looks a lot like a face.)", "* (It looks disappointed in you.)"]}],
		["rock", Vector2(60 * T, 10 * T)],
		["log", Vector2(42 * T, 17 * T)],
		["log", Vector2(55 * T, 25 * T)],
		["bush", Vector2(28 * T, 9 * T + 10)],
		["bush", Vector2(46 * T, 14 * T), {"berries": true}],
		["bush", Vector2(60 * T, 21 * T)],
		["bush", Vector2(23 * T, 26 * T + 4)],
		["tree_small", Vector2(34 * T, 8 * T)],
		["tree_small", Vector2(50 * T, 20 * T)],
	])


func build_map() -> void:
	room.setup(64, 32, Room.GRASS)
	room.fill(0, 0, 10, 32, Room.WATER)
	room.fill(10, 0, 2, 32, Room.SAND)
	room.fill(12, 0, 3, 32, Room.ADOBE)        # the cliff face
	room.fill(15, 13, 1, 19, Room.FENCE)       # the rail along the edge
	room.fill(15, 20, 1, 3, Room.GRASS)        # (the viewpoint, open to the edge)
	room.fill(0, 0, 64, 1, Room.TREE)
	room.fill(63, 0, 1, 32, Room.TREE)
	room.fill(0, 31, 64, 1, Room.TREE)
	# The trail, from the bus stop up to the gliderport.
	room.fill(30, 27, 33, 2, Room.DIRT)
	room.fill(30, 12, 2, 16, Room.DIRT)
	room.fill(17, 11, 15, 2, Room.DIRT)
	room.fill(16, 20, 14, 2, Room.DIRT)        # the spur out to the viewpoint
	# The lodge.
	room.fill(44, 3, 9, 6, Room.WOOD_WALL)
	room.set_tile(48, 8, Room.DOOR)
	room.set_tile(17, 23, Room.BENCH)
	room.set_tile(18, 23, Room.BENCH)
	# Torrey pines, bent by the wind.
	for spot in [Vector2i(36, 4), Vector2i(40, 10), Vector2i(55, 12), Vector2i(58, 5), Vector2i(22, 16), Vector2i(26, 24),
			Vector2i(36, 15), Vector2i(38, 20), Vector2i(46, 18), Vector2i(52, 22), Vector2i(57, 17), Vector2i(20, 29), Vector2i(44, 24)]:
		room.set_tile(spot.x, spot.y, Room.TREE)


func _draw_decor() -> void:
	# Waves rolling in on the beach far below, and the cliff's layers.
	for k in 24:
		var y := fmod(k * 37.0 + _time * 12.0, 32.0 * T)
		_decor.draw_line(Vector2(2 * T + (k % 5) * 30, y), Vector2(2 * T + (k % 5) * 30 + 22, y), Color(1, 1, 1, 0.35), 1.0)
	for y in range(0, 32 * T, 24):
		_decor.draw_line(Vector2(12 * T, y), Vector2(15 * T, y + 8), Color8(180, 130, 90, 120), 1.0)
	# The windsock, pointing out to sea.
	var pole := Vector2(19 * T + 10, 4 * T)
	_decor.draw_line(pole + Vector2(0, 16), pole + Vector2(0, -24), Color8(180, 180, 186), 2.0)
	var flap := sin(_time * 4.0) * 3.0
	_decor.draw_colored_polygon(PackedVector2Array([pole + Vector2(0, -24), pole + Vector2(0, -16), pole + Vector2(-26, -19 + flap), pole + Vector2(-26, -21 + flap)]), Color8(240, 120, 40))
	# The gliderport's launch edge.
	_decor.draw_string(_font, Vector2(17 * T, 2 * T + 6), "GLIDERPORT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(255, 255, 240))
	for k in 6:
		_decor.draw_rect(Rect2(15 * T + 4, (2 + k * 2) * T, 6, T), Color8(240, 200, 40, 160))
	# The lodge's sign.
	_decor.draw_string(_font, Vector2(44 * T + 6, 4 * T), "LODGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(240, 230, 210))
	# The viewpoint plaque.
	_decor.draw_rect(Rect2(18 * T + 4, 25 * T - 6, 12, 10), Color8(120, 90, 60))
	# Doris, the four-hundred-year-old pine (a little bigger than the rest).
	_decor.draw_circle(DORIS, 16.0, Color8(40, 90, 55))
	_decor.draw_line(DORIS + Vector2(0, 16), DORIS + Vector2(-6, 30), Color8(90, 65, 40), 4.0)
	# The bus stop.
	_decor.draw_rect(Rect2(ENTRY + Vector2(8, -46), Vector2(3, 38)), Color8(150, 150, 156))
	_decor.draw_rect(Rect2(ENTRY + Vector2(0, -54), Vector2(20, 12)), Color8(40, 90, 190))
	_decor.draw_string(_font, ENTRY + Vector2(2, -44), "BUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	# The Glider's shadow on the water.
	if glider and is_instance_valid(glider):
		_decor.draw_set_transform(glider.position + Vector2(-30, 120), 0.0, Vector2(1.0, 0.35))
		_decor.draw_circle(Vector2.ZERO, 22.0, Color(0, 0, 0, 0.2))
		_decor.draw_set_transform(Vector2.ZERO)


## A golden afternoon, the light coming in low off the sea.
func _draw_shade() -> void:
	if flag("tp_stolen"):
		_shade.draw_rect(_px(OUTSIDE), Color(0.25, 0.05, 0.1, 0.2))
	else:
		_shade.draw_rect(_px(OUTSIDE), Color(1.0, 0.75, 0.4, 0.08))


# --- People ----------------------------------------------------------------------

func _place_people() -> void:
	if not Game.walking_alone():
		partner = Cast.make(Game.partner())
		add_character(partner, player.position + Vector2(-20, 0))
		partner.follow = player
	add_person("ranger", Vector2(40 * T, 22 * T + 10), SCENE)
	add_person("hiker", Vector2(50 * T, 15 * T), SCENE)
	add_person("birder", Vector2(24 * T, 29 * T + 10), SCENE)
	match _route():
		"pacifist":
			if not flag("tp_stolen"):
				hop = add_npc("Hop", VIEWPOINT, _talk_hop)
				if Game.partner() != "Rooster":
					rooster = add_npc("Rooster", ROOSTER_SPOT, _talk_rooster)
		"neutral":
			hop = add_npc("Hop", VIEWPOINT, _talk_hop)
			rooster = add_npc("Rooster", ROOSTER_SPOT, _talk_rooster)
		_:
			if not flag("beat_corps_rooster"):
				rooster = add_npc("Rooster", ROOSTER_SPOT, _talk_rooster)
	if not flag("tp_glider_done") and str(Game.battle_result.get("id", "")) != "glider":
		glider = Cast.make("glider", false)
		glider.glow = true
		glider.glow_color = Color(1.0, 0.35, 0.35, 0.35)
		add_character(glider, GLIDER_SPOT)


func _talk_rooster() -> void:
	match _route():
		"pacifist":
			await chat("tp_rooster", [
				{"who": "Rooster", "text": "Nassan sent me. Because I'm 'the flier.'\nBecause I SAID I'd been hang gliding. Once.", "mood": "smug"},
				{"who": "Rooster", "text": "I have not been hang gliding.\nI have been near a hang glider. In a store.", "mood": "sad"},
				{"who": "Rooster", "text": "That thing's had the fragment for five years.\nIt won't come down. Can't say I blame it.", "mood": ""},
				{"who": "Rooster", "text": "...Hop's at the viewpoint. He won't talk to me.\nI roasted him once. Bad timing. Go.", "mood": "sad"},
			], [[{"who": "Rooster", "text": "I'm fine. I'm FINE. The ground is RIGHT there.\nWay down there. Fine.", "mood": "shocked"}]])
		"neutral":
			await chat("tp_rooster_neutral", [
				{"who": "Rooster", "text": "Well well well. If it isn't Mr. Lone Wolf.\nMx. Lone Wolf. Lone Wolf, Esquire.", "mood": "smug"},
				{"who": "Rooster", "text": "The Corps sent me for the glider.\nI'm not going up there. I'm supervising.", "mood": "smug"},
				{"who": "Rooster", "text": "...You look like you haven't slept in a week.\nThat's not a roast. That's just true.", "mood": ""},
			], [[{"who": "Rooster", "text": "Supervising!", "mood": "smug"}]])
		_:
			await _confront_rooster()


func _talk_hop() -> void:
	match _route():
		"pacifist":
			if flag("tp_hop_talk"):
				await chat("tp_hop_after", [{"who": "Hop", "text": "Go help Rooster. He's about to pass out.\nI'll be right here. I promise.", "mood": "sad"}], [[{"who": "Hop", "text": "Still here.", "mood": "sad"}]])
				return
			Game.flags["tp_hop_talk"] = true
			hop.face(player.position - hop.position)
			await Game.dialogue.say([
				{"who": "Hop", "text": "...You found me. Of course you did.", "mood": "sad"},
				{"who": "Hop", "text": "I left so you wouldn't have to carry me.\nIt was in the note. Did you read the note?", "mood": "sad"},
				{"who": "Elric", "choices": ["You don't get to decide that.", "We read it. All of us."]},
				{"who": "Hop", "text": "...", "mood": "sad"},
				{"who": "Hop", "text": "It's so loud, Elric. He's so loud now.\nEvery fragment we broke. I can feel all of them.", "mood": "sad"},
				{"who": "Hop", "text": "...Okay. Okay. Get the glider down.\nThen I'll come back. I'll try.", "mood": "sad"},
			])
			Game.set_objective("The Glider. (Rooster's at the gliderport.)")
		"neutral":
			if flag("tp_hop_talk"):
				await chat("tp_hop_neutral_after", [{"who": "Hop", "text": "...I wish you'd come with us.\nThat's all. That's all I wanted to say.", "mood": "sad"}], [[{"who": "Hop", "text": "...", "mood": "sad"}]])
				return
			Game.flags["tp_hop_talk"] = true
			hop.face(player.position - hop.position)
			await Game.dialogue.say([
				{"who": "Hop", "text": "...Hey. They let me out for the day.\nI think they wanted me somewhere with a view.", "mood": "smug"},
				{"who": "Hop", "text": "Elric. Can I tell you something? Since nobody\nelse is going to. Since it's just us.", "mood": "sad"},
				{"who": "Hop", "text": "There was someone before you. Their name was Relic.\nThey came here with a backpack that clinked.", "mood": "sad"},
				{"who": "Hop", "text": "We had one summer. The best one. And then the voice\ngot out, and there was fire, and they held it all.", "mood": "sad"},
				{"who": "Hop", "text": "They broke. Twelve pieces. You've been picking\nthem up. ...You walk just like them. You know that?", "mood": "sad"},
				{"who": "Elric", "choices": ["...I know.", "Why are you telling me now?"]},
				{"who": "Hop", "text": "Because you keep walking away. And so did they.\nAnd I never told them to stay.", "mood": "sad"},
				{"who": "Hop", "text": "...I wish you'd come with us.", "mood": "sad"},
			])
		_:
			pass


# --- Things --------------------------------------------------------------------------

func _lodge() -> void:
	await Game.dialogue.say(["* (The lodge. A sign on the door: NO DRONES.\n*  NO KITES. NO GLIDERS LANDING HERE.)", "* (Someone crossed out the last one.)"])


func _windsock() -> void:
	await Game.dialogue.say(["* (The windsock is pointing straight out to sea.)", "* (The wind wants to take everything with it.)"])


func _plaque() -> void:
	await Game.dialogue.say(["* (\"TORREY PINES. These trees grow here and almost\n*  nowhere else on Earth. They stayed.\")"])


func _doris() -> void:
	await Game.dialogue.say(["* (A torrey pine, older than the rest. Someone's\n*  tied a little ribbon on it that says DORIS.)", "* (She's four hundred years old. She stayed.)"])


func _bus_stop() -> void:
	if flag("tp_stolen") and _route() == "pacifist" and not flag("tp_left"):
		await Game.dialogue.say(["* (Not without telling the others.)"])
		return
	await ride_bus(SCENE)


# --- Story ------------------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if not is_inside_tree():
		return
	if _from_memory:
		while is_blocked() or not Game.keepsake_after.is_empty():
			await get_tree().process_frame
		await run_cutscene(_after_memory)
		return
	var id := str(Game.battle_result.get("id", ""))
	var spared: bool = not Game.battle_result.get("spared", []).is_empty()
	if id in ["glider", "corps_rooster", "hopkuna_cliffs"]:
		Game.battle_result = {}
	match id:
		"glider":
			await run_cutscene(_after_glider.bind(spared))
			return
		"corps_rooster":
			await run_cutscene(_after_rooster)
			return
		"hopkuna_cliffs":
			await run_cutscene(_after_hopkuna)
			return
	if await handle_person_return():
		return
	if not flag("tp_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked() or _engaged:
		return
	check_random_encounter(SCENE)
	# With Hop: Rooster is waiting at the gliderport.
	if _genocide() and rooster and is_instance_valid(rooster) and player.position.distance_to(rooster.position) < 80.0:
		run_cutscene(_confront_rooster)
		return
	# Out at the cliff edge, the Glider comes in close.
	if glider and is_instance_valid(glider) and player.position.distance_to(GLIDER_EDGE) < 44.0:
		if _genocide() and rooster and is_instance_valid(rooster):
			return
		if _route() == "pacifist" and not flag("tp_hop_talk"):
			return
		run_cutscene(_meet_glider)


func _arrival() -> void:
	Game.flags["tp_arrived"] = true
	await Game.dialogue.say([
		"* (Torrey Pines. Cliffs over the ocean, and the\n*  rarest pine trees in the world, bent by the wind.)",
		"* (Out past the edge of the cliff, a hang glider\n*  is hanging in the air. Nobody's in it.)",
		"* (It's been there so long the gulls nest on it.)",
	])
	match _route():
		"pacifist":
			await Game.dialogue.say(["* (Out at the viewpoint, someone in a fedora is\n*  sitting by himself, looking at the water.)", "* (Hop.)"])
			Game.set_objective("Hop. (At the viewpoint.)")
		"neutral":
			await Game.dialogue.say([
				{"who": "Relic", "tag": "", "face": false, "text": "* (gently) You keep walking away from people.\n* I did that too."},
				{"who": "Relic", "tag": "", "face": false, "text": "* (It's the first time the voice hasn't sounded angry.\n*  It sounds tired.)"},
			])
			Game.set_objective("The Glider. (Out past the gliderport.)")
		_:
			await Game.dialogue.say([
				{"who": "Hop", "text": "...Rooster.", "mood": "sad"},
				{"who": "Hop", "text": "He's scared of heights. He's standing\nright at the edge anyway.", "mood": "sad"},
				{"who": "Relic", "tag": "", "face": false, "text": "* Then he won't have far to go."},
			])
			Game.set_objective("...")


func _meet_glider() -> void:
	if _engaged:
		return
	_engaged = true
	await Game.dialogue.say([
		"* (You step out to the very edge.)",
		"* (The Glider swings in close on the wind.\n*  Something red is glowing in the empty harness.)",
		"* (It tilts its wing at you, and climbs.\n*  It does NOT want to come down.)",
	])
	if _route() == "pacifist" and rooster:
		await Game.dialogue.say([{"who": "Rooster", "text": "Okay. OKAY. I'm right behind you.\nLike, WAY behind you. Emotionally behind you.", "mood": "shocked"}])
	await Game.start_battle("glider", SCENE, player.position)


func _after_glider(spared: bool) -> void:
	Game.flags["tp_glider_done"] = true
	if spared:
		await Game.dialogue.say([
			"* (The Glider comes down. Slowly.\n*  It circles once over the gliderport...)",
			"* (...and lands. On the grass. It skids a little.\n*  It's fine. It's okay. It came down.)",
			"* (Something red rolls out of the empty harness.)",
		])
		if _route() == "pacifist" and rooster:
			await Game.dialogue.say([{"who": "Rooster", "text": "...It landed. It LANDED. I said a true thing\nout loud and it LANDED.", "mood": "shocked"}])
	else:
		await Game.dialogue.say([
			"* (The Glider folds up in the air, and drops\n*  past the edge of the cliff.)",
			"* (Something red is left on the grass, where it\n*  hit the edge on the way down.)",
		])
		if _genocide():
			await Game.dialogue.say([{"who": "Relic", "tag": "", "face": false, "text": "* Down."}])
	Game.play_sfx("fragment")
	await Game.dialogue.say([
		"* (You pick it up. It's warm, and it hums.)",
		"* (You got the ninth FRAGMENT.)",
	])
	Game.flags["tp_fragment"] = true
	Game.flags["has_fragment_9"] = true
	Game.flags["fragments"] = maxi(int(Game.flags.get("fragments", 8)), 9)
	Game.set_objective("..." if _genocide() else "9 of 12 FRAGMENTS.")
	await Game.dialogue.say(["* (The fragment is warm in your hand.\n*  You close your eyes.)"])
	await Game.play_keepsakes([9], SCENE, player.position, [
		"* (Relic, at the edge of the cliff, with everything\n*  they owned on their back. Unpacking.)",
		"* (\"First place I ever wanted to stay.\")",
	])


func _after_memory() -> void:
	match _route():
		"pacifist":
			await _hopkuna_strikes()
		"neutral":
			Game.set_objective("9 of 12. Next: the burned hills. (Take the bus.)")
		_:
			Game.set_objective("...")


# --- Corps: Hopkuna strikes ------------------------------------------------------------

func _hopkuna_strikes() -> void:
	if not hop or not is_instance_valid(hop):
		hop = add_character(Cast.make("Hop"), VIEWPOINT)
	await hop.walk_to(player.position + Vector2(50, 0), 80.0)
	hop.face(player.position - hop.position)
	await Game.dialogue.say([
		{"who": "Hop", "text": "You got it. You- Elric, put it away.\nPut it AWAY. He can feel it. He can feel ALL of them-", "mood": "shocked"},
		"* (Hop doubles over.)",
		{"who": "Hop", "text": "No. No no no. Not here. Not NOW-", "mood": "shocked"},
		"* (He stands back up. He's smiling.)",
		"* (His eyes are red.)",
	])
	var where := hop.position
	hop.queue_free()
	hop = add_character(Cast.make("hopkuna"), where)
	hop.glow = true
	hop.glow_color = Color(1.0, 0.15, 0.2, 0.5)
	hop.face(player.position - hop.position)
	Game.play_sfx("black_flash")
	await Game.dialogue.say([
		{"who": "Hopkuna", "text": "Hello again, little wanderer.", "mood": ""},
		{"who": "Hopkuna", "text": "Every fragment your friends broke came home to me.\nI've never been this awake.", "mood": ""},
		{"who": "Hopkuna", "text": "You've been breaking my things.", "mood": ""},
		{"who": "Hopkuna", "text": "Thank you.", "mood": ""},
	])
	await Game.start_battle("hopkuna_cliffs", SCENE, player.position)


func _after_hopkuna() -> void:
	if not hop or not is_instance_valid(hop):
		hop = add_character(Cast.make("hopkuna"), player.position + Vector2(50, 0))
		hop.glow = true
		hop.glow_color = Color(1.0, 0.15, 0.2, 0.5)
	hop.face(player.position - hop.position)
	Game.flags["tp_stolen"] = true
	_shade.queue_redraw()
	await Game.dialogue.say([
		"* (You're on the ground. Everyone is.)",
		"* (Hopkuna holds out Hop's hand.)",
		"* (Every fragment in your pockets tears loose,\n*  all at once, and flies to it.)",
		{"who": "Hopkuna", "text": "Nine. Of course, some of them are just dust now.\nYour friends were so helpful.", "mood": ""},
		{"who": "Hopkuna", "text": "The rest, I'll find myself. I know where they are.\nI've always known where they are.", "mood": ""},
		"* (He steps off the edge of the cliff.)",
		"* (He doesn't fall. He flies. North, over the\n*  pines, until he's a red speck, and then nothing.)",
	])
	hop.queue_free()
	hop = null
	if rooster and is_instance_valid(rooster):
		rooster.face(player.position - rooster.position)
		await Game.dialogue.say([
			{"who": "Rooster", "text": "...He took them. All of them.", "mood": "shocked"},
			{"who": "Rooster", "text": "He took HOP.", "mood": "sad"},
			{"who": "Rooster", "text": "No joke. I don't- I don't have one.\nI don't have anything.", "mood": "sad"},
		])
	Game.flags["tp_left"] = true
	Game.set_objective("Hopkuna has them. (Next: the burned hills.)")


# --- With Hop: Rooster -------------------------------------------------------------

func _confront_rooster() -> void:
	if not rooster or not is_instance_valid(rooster) or _engaged:
		return
	_engaged = true
	rooster.face(player.position - rooster.position)
	await Game.dialogue.say([
		{"who": "Rooster", "text": "Oh, LOOK who it is. Mr. Murder. Captain Crime.\nThe Grim Reaper's... green... intern.", "mood": "smug"},
		{"who": "Rooster", "text": "...That one wasn't great. Gimme a sec.", "mood": "sad"},
		{"who": "Rooster", "text": "I'm standing at the edge of a cliff, man.\nI hate cliffs. I'm here anyway.", "mood": "shocked"},
		{"who": "Hop", "text": "Rooster. Go home. Please. PLEASE.", "mood": "sad"},
		{"who": "Rooster", "text": "Can't. Somebody's gotta roast this guy.\nEverybody else is... busy.", "mood": "sad"},
	])
	await Game.start_battle("corps_rooster", SCENE, player.position)


func _after_rooster() -> void:
	if rooster:
		rooster.queue_free()
		rooster = null
	var kept: Array = Game.flags.get("mementos", [])
	if not "Top Hat" in kept:
		kept.append("Top Hat")
	Game.flags["mementos"] = kept
	await Game.dialogue.say([
		"* (His top hat rolls in a little circle on the\n*  grass, and stops at the edge of the cliff.)",
		"* (You keep it.)",
		"* (Hop doesn't say anything. He hasn't said anything\n*  since the Harbor.)",
		{"who": "Relic", "tag": "", "face": false, "text": "* Seven."},
	])
	_engaged = false
	Game.set_objective("...")
