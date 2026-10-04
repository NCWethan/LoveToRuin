extends Area
## Hilltop Park: the REVOLUTION Corps' base, and Chapter 1's climax.
##
## What happens here, in order (flags in Game.flags):
##   hp_arrived        Elric and Hop arrive. Hop is quiet.
##   hp_saw_map        (optional) The map at the Corps' shelter: a circle drawn on this very field.
##   hp_erupted        At the center of the field, fragment 3 erupts at Elric. Hop takes the
##                     hit, and Hopkuna takes over. Then: the Hopkuna battle (survive it).
##   has_fragment_3    The REVOLUTION Corps arrives and drives Hopkuna back. Hop wakes up.
##   route             The route choice: "genocide", "neutral" or "pacifist".
##   chapter1_done     The chapter ends.

const SCENE := "res://scenes/hilltop.tscn"
const DEMO_END_SCENE := "res://scenes/demo_end.tscn"
const T := Room.TILE

## Where Elric arrives (the path at the bottom of the park).
const ENTRY := Vector2(400, 548)
## The middle of the big field, where fragment 3 is buried.
const CRATER := Vector2(410, 270)
## How close to the crater Elric has to get for it to erupt.
const ERUPT_DISTANCE := 95.0

## Who arrives with the REVOLUTION Corps, and where they end up standing
## (relative to Hopkuna).
const CORPS := {
	"BigJoe6": Vector2(-70, -40),
	"Eggo": Vector2(-90, 0),
	"Nassan": Vector2(70, -40),
	"Nat": Vector2(90, 0),
	"NCWethan": Vector2(-60, 45),
	"Ronin": Vector2(60, 45),
	"Supreme": Vector2(-30, -70),
	"Crayola": Vector2(30, -70),
	"Rooster": Vector2(0, 75),
}

var hop: Character
var corps: Dictionary = {}
var _decor: Node2D
var _night: CanvasModulate
var _font: Font
var _time: float = 0.0
## While above 0, a red beam is drawn from the crater toward `_beam_target`.
var _beam_time: float = 0.0
var _beam_target: Vector2
## While above 0, sparks and flames fly around Hopkuna.
var _spark_time: float = 0.0


func _ready() -> void:
	setup_area(ENTRY)
	Game.play_music("hilltop")
	_font = ThemeDB.fallback_font

	_night = CanvasModulate.new()
	_night.color = Color(0.6, 0.62, 0.85)
	add_child(_night)

	_decor = Node2D.new()
	add_child(_decor)
	_decor.draw.connect(_draw_decor)
	# Drawn just above the ground but below everyone walking around.
	move_child(_decor, world.get_index())

	_place_people()
	world.add_child(Hotspot.create(Vector2(110, 96), _read_map))
	fit_camera_to_room()
	_start.call_deferred()


# --- The map --------------------------------------------------------------

func build_map() -> void:
	room.setup(40, 30, Room.GRASS)
	room.fill(0, 0, 40, 1, Room.TREE)
	room.fill(0, 1, 1, 27, Room.TREE)
	room.fill(39, 1, 1, 27, Room.TREE)
	for spot in [Vector2i(4, 10), Vector2i(5, 18), Vector2i(34, 8), Vector2i(35, 16), Vector2i(33, 24), Vector2i(6, 24), Vector2i(35, 3)]:
		room.set_tile(spot.x, spot.y, Room.TREE)

	# The big field, with a center line.
	room.fill(8, 6, 24, 16, Room.FIELD)
	room.fill(20, 6, 1, 16, Room.FIELD_LINE)

	# The Corps' base: a wooden picnic shelter in the top-left corner.
	room.fill(2, 1, 7, 1, Room.ROOF)
	room.fill(2, 2, 7, 3, Room.WOOD_WALL)
	room.fill(10, 23, 2, 1, Room.BENCH)
	room.fill(28, 23, 2, 1, Room.BENCH)

	# The path in from the road at the bottom.
	room.fill(19, 22, 3, 6, Room.SIDEWALK)
	room.fill(0, 28, 40, 2, Room.ROAD)


func _process(delta: float) -> void:
	_time += delta
	_beam_time = maxf(_beam_time - delta, 0.0)
	_spark_time = maxf(_spark_time - delta, 0.0)
	_decor.queue_redraw()


func _draw_decor() -> void:
	# The REVOLUTION banner on the shelter.
	var banner := Rect2(52, 46, 86, 16)
	_decor.draw_rect(banner, Color8(235, 225, 200))
	_decor.draw_string(_font, banner.position + Vector2(4, 12), "REVOLUTION", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(170, 30, 30))

	# The glow from the buried fragment, then the crater it leaves behind.
	if not flag("hp_erupted"):
		var pulse := 0.35 + 0.25 * sin(_time * 2.5)
		_decor.draw_circle(CRATER, 14, Color(1, 0.15, 0.2, pulse))
		_decor.draw_circle(CRATER, 6, Color(1, 0.5, 0.5, pulse))
	else:
		_decor.draw_circle(CRATER, 16, Color8(70, 50, 35))
		_decor.draw_arc(CRATER, 16, 0, TAU, 20, Color8(45, 30, 20), 3.0)
		if not flag("has_fragment_3"):
			_decor.draw_circle(CRATER, 4, Color(1, 0.2, 0.25, 0.6 + 0.3 * sin(_time * 6)))

	# The blast from the fragment.
	if _beam_time > 0.0:
		_decor.draw_line(CRATER, _beam_target, Color(1, 0.2, 0.25, 0.9), 8.0)
		_decor.draw_line(CRATER, _beam_target, Color(1, 0.8, 0.8), 3.0)

	# Lightning and fire from the Corps.
	if _spark_time > 0.0 and hop:
		for i in 14:
			var dir := Vector2.from_angle(randf() * TAU)
			var color := Color(0.5, 0.85, 1.0) if i % 2 == 0 else Color(1.0, 0.55, 0.15)
			var from := hop.position + Vector2(0, -16) + dir * randf_range(6, 16)
			_decor.draw_line(from, from + dir * randf_range(6, 14), color, 2.0)


# --- People -----------------------------------------------------------------

func _place_people() -> void:
	hop = Cast.make("Hop")
	add_character(hop, player.position + Vector2(-20, -4))

	if flag("chapter1_done"):
		# After the chapter: Hop is with the Corps unless Elric went with him.
		hop.position = Vector2(150, 140) if Game.flags.get("route") != "genocide" else player.position + Vector2(-20, -4)
		if Game.flags.get("route") == "genocide":
			hop.follow = player
		return

	if flag("hp_erupted") and not flag("has_fragment_3"):
		# Coming back from the Hopkuna fight: he's still standing over the crater.
		hop.set_look("Hopkuna")
		hop.position = CRATER + Vector2(0, 30)
	else:
		hop.follow = player

	var star := Character.new().setup(preload("res://art/sprites/save_star.png"), null, false)
	star.glow = true
	star.glow_color = Color(1.0, 1.0, 1.0, 0.55)
	star.on_interact = _use_save_point
	add_storage_box(Vector2(322, 500))
	add_character(star, Vector2(360, 500))


# --- Story ------------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if not is_inside_tree():
		return
	if Game.battle_result.get("id", "") == "hopkuna":
		await run_cutscene(_corps_arrives)
	elif not flag("hp_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked() or flag("chapter1_done"):
		if flag("chapter1_done") and not is_blocked() and player.position.y > 555:
			run_cutscene(_leave_after_chapter)
		return
	if not flag("hp_erupted") and player.position.distance_to(CRATER) < ERUPT_DISTANCE:
		run_cutscene(_eruption)
	elif player.position.y > 555:
		run_cutscene(_not_leaving)


func _arrival() -> void:
	await Game.dialogue.say([
		"* (Hilltop Park. The big field is dark and empty.)",
		{"who": "Hop", "text": "This is it. Revolution's base is supposed to be\nthe shelter by the field.", "mood": "sad"},
		{"who": "Hop", "text": "...Nobody's home.", "mood": "sad"},
		"* (In the middle of the field, something is glowing red.)",
		{"who": "Hop", "text": "...", "mood": "sad"},
		{"who": "Hop", "text": "Hey, Elric? Whatever happens out there...\nI'll stay right behind you. Okay?", "mood": "sad"},
	])
	Game.flags["hp_arrived"] = true
	Game.set_objective("Find out what's glowing in the field.")


func _read_map() -> void:
	Game.flags["hp_saw_map"] = true
	await Game.dialogue.say([
		"* (A wooden picnic shelter. Someone hung\n*  a hand-painted banner: REVOLUTION.)",
		"* (A map of San Diego is pinned to the table.\n*  Twelve red circles are drawn on it.)",
		"* (Two are crossed out: Mt. Carmel. Westview.)",
		"* (A third circle is drawn right on this park's big field.)",
		{"who": "Hop", "text": "...Huh. Right here.", "mood": "sad"},
	])


func _not_leaving() -> void:
	await Game.dialogue.say([{"who": "Hop", "text": "We came all this way. Let's at least\nsee what's glowing out there.", "mood": "sad"}])
	await push_player(Vector2(0, -24))


func _use_save_point() -> void:
	Game.play_sfx("heal")
	Game.heal_party()
	await Game.dialogue.say([
		"* (The wind moves through the empty field.)",
		"* (Something is about to happen.\n*  It fills you with DETERMINATION.)",
		"* (Everyone's HP was restored.)",
	])
	var choice := await Game.dialogue.ask("* (Save your progress?)", ["Save", "Return"])
	if choice == 0:
		Game.save_game(SCENE, player.position)
		Game.play_sfx("save")
		await Game.dialogue.say(["* (File saved.)"])


# --- The eruption -----------------------------------------------------------

func _eruption() -> void:
	Game.flags["hp_erupted"] = true
	Game.stop_music(1.0)
	hop.follow = null
	await Game.dialogue.say([
		"* (The ground in the middle of the field is shaking.)",
		{"who": "Hop", "text": "Uh. Elric?", "mood": "shocked"},
	])
	Game.play_sfx("fragment")
	shake(4.0, 0.8)
	await get_tree().create_timer(0.8).timeout

	# The fragment fires at Elric... and Hop jumps in the way.
	await Game.dialogue.say([{"who": "Hop", "text": "ELRIC, MOVE!!", "mood": "shocked"}])
	var between := player.position.lerp(CRATER, 0.35)
	await hop.walk_to(between, 320.0)
	_beam_target = hop.position + Vector2(0, -16)
	_beam_time = 0.6
	Game.play_sfx("hurt")
	shake(10.0, 0.6)
	await _flash(Color(1.0, 0.35, 0.4), 0.15)
	hop.lie_down()
	await get_tree().create_timer(0.6).timeout

	await Game.dialogue.say([
		"* (Hop jumped in front of you.)",
		"* (The blast hit him square in the chest.)",
		{"who": "Hop", "text": "...ow. Okay. That one... actually hurt.", "mood": "sad"},
		{"who": "Hop", "text": "Elric... get back. Get AWAY from me.\nPlease.", "mood": "sad"},
		"* (Black marks crawl across Hop's skin.)",
		{"who": "Hop", "text": "No no no NO- not now- not in front of-", "mood": "shocked"},
	])

	# Hopkuna takes over.
	Game.play_sfx("shatter")
	shake(6.0, 0.5)
	await _flash(Color(1.0, 0.2, 0.25), 0.3)
	hop.set_look("Hopkuna")
	hop.lie_down(false)
	hop.face(player.position - hop.position)
	await _tint_night(Color(0.75, 0.45, 0.5), 0.6)
	Game.play_music("hopkuna_reveal", 1.5)

	# He was the voice at the very start. He remembers what Elric told him.
	var callback: String = {
		"talk": "\"Talk it out,\" you told me. Remember?\nHow's that going?",
		"fight": "\"Fight my way,\" you told me. Remember?\nI was hoping you meant it.",
	}.get(Game.flags.get("first_answer", ""), "You didn't know how you'd do it.\nRemember? I told you the city would decide.")
	await Game.dialogue.say([
		"* (Hop stands up.)",
		"* (It isn't Hop.)",
		{"who": "Hopkuna", "text": "...Finally."},
		{"who": "Hopkuna", "text": "Do you know how long I've waited,\nlittle wanderer?"},
		"* (That voice. You've heard it before.)",
		{"who": "Hopkuna", "text": callback},
		{"who": "Hopkuna", "text": "He was always so careful.\nOnly let me out when he had no other choice."},
		{"who": "Hopkuna", "text": "Tonight, he had no other choice. Thanks to you."},
		{"who": "Hopkuna", "text": "And look. You've been carrying two of my\nfragments for me. How thoughtful."},
		{"who": "Hopkuna", "text": "Hand them over."},
		{"who": "Elric", "text": "...No.", "mood": "angry"},
		{"who": "Hopkuna", "text": "Then I'll take them."},
	])
	await Game.start_battle("hopkuna", SCENE, player.position)


## Flashes the whole screen a color for a moment.
func _flash(color: Color, time: float) -> void:
	var before := _night.color
	_night.color = color * 2.0
	var tween := create_tween()
	tween.tween_property(_night, "color", before, time)
	await tween.finished


func _tint_night(color: Color, time: float) -> void:
	var tween := create_tween()
	tween.tween_property(_night, "color", color, time)
	await tween.finished


# --- The REVOLUTION Corps arrives -------------------------------------------

func _corps_arrives() -> void:
	Game.battle_result = {}
	_night.color = Color(0.75, 0.45, 0.5)
	Game.play_music("hopkuna_reveal", 0.2)

	await Game.dialogue.say([
		"* (You're still standing. Barely.)",
		{"who": "BigJoe6", "tag": "???", "face": false, "text": "REVOLUTION, NOW!!", "mood": "angry"},
	])

	# Everyone runs in from the path.
	var arrivals: Array[Character] = []
	var i := 0
	for who in CORPS:
		var member := Cast.make(who)
		add_character(member, Vector2(380 + (i % 3) * 20, 600 + (i / 3) * 14))
		corps[who] = member
		arrivals.append(member)
		i += 1
	for member in arrivals:
		var who: String = corps.find_key(member)
		member.walk_to(hop.position + CORPS[who], 220.0)
	await get_tree().create_timer(1.6).timeout
	for member in arrivals:
		member.face(hop.position - member.position)

	await Game.dialogue.say([
		{"who": "BigJoe6", "text": "Get AWAY from them, Hopkuna!", "mood": "angry"},
		{"who": "Eggo", "text": "...hop. dude.", "mood": "sad"},
		{"who": "Hopkuna", "text": "Oh, look. The little club showed up."},
		{"who": "Rooster", "text": "Nice tattoos. Did you lose a fight with a Sharpie?", "mood": "smug"},
		{"who": "Hopkuna", "text": "..."},
		{"who": "NCWethan", "text": "LIGHTNING TIME!!!", "mood": "happy"},
		{"who": "Ronin", "text": "FIRE TIME!!!", "mood": "angry"},
	])
	_spark_time = 1.4
	Game.play_sfx("hit")
	shake(8.0, 1.0)
	await get_tree().create_timer(1.2).timeout
	await Game.dialogue.say([
		"* (A storm of sparks and flame slams into Hopkuna.)",
		"* (He barely moves. But he isn't smiling anymore.)",
		{"who": "Supreme", "text": "Statistically, we can't beat him.\nBut we can make him want to leave.", "mood": "shocked"},
		{"who": "Nat", "text": "Elric. Hop's still in there.\nTalk to him."},
		{"who": "Elric", "text": "...Hop."},
		{"who": "Elric", "text": "You jumped in front of that for me."},
		{"who": "Elric", "text": "Come back."},
		"* (Hopkuna's hand starts to shake.)",
		{"who": "Hopkuna", "text": "...Tch. Sentimental."},
		{"who": "Hopkuna", "text": "Keep him, then. For now."},
		{"who": "Hopkuna", "text": "Three fragments, little wanderer.\nNine to go."},
		{"who": "Hopkuna", "text": "I can wait.\nI'm very, very good at waiting."},
	])

	# Hopkuna lets go. Hop collapses.
	Game.stop_music(1.5)
	hop.set_look("Hop")
	await _tint_night(Color(0.6, 0.62, 0.85), 1.0)
	hop.lie_down()
	await Game.dialogue.say([
		"* (The tattoos fade. The red glow drains away.)",
		"* (Hop collapses onto the grass.)",
		{"who": "Crayola", "text": "Is he... okay?", "mood": "sad"},
	])
	await get_tree().create_timer(0.8).timeout
	hop.lie_down(false)
	Game.play_music("hilltop", 2.0)
	await Game.dialogue.say([
		{"who": "Hop", "text": "...ow.", "mood": "sad"},
		{"who": "Hop", "text": "Elric? ...Did I- did he-", "mood": "shocked"},
		{"who": "Hop", "text": "I'm sorry. I should've told you.", "mood": "sad"},
		{"who": "Hop", "text": "He's been in here my whole life. I only ever let him\nout when there's no other choice.", "mood": "sad"},
		{"who": "Hop", "text": "...Tonight there wasn't.", "mood": "sad"},
		{"who": "BigJoe6", "text": "So it's true. Hop IS Hopkuna.", "mood": "angry"},
		{"who": "Eggo", "text": "he's also hop, though.", "mood": "sad"},
		"* (In the crater, something red is glowing.)",
		"* (You pick up the third FRAGMENT.)",
	])
	Game.flags["has_fragment_3"] = true
	Game.flags["fragments"] = 3
	Game.play_sfx("fragment")

	await Game.dialogue.say([
		{"who": "Nassan", "text": "Okay. Everyone, breathe."},
		{"who": "Nassan", "text": "Elric. You've seen what we're up against now.\nAll of it."},
		{"who": "Nassan", "text": "So I'll ask you straight."},
	])
	await _route_choice()


# --- The route choice --------------------------------------------------------

func _route_choice() -> void:
	var options := ["Go with Hop? (Genocide)", "Chart your own path? (Neutral)", "Join the REVOLUTION Corps? (Pacifist)"]
	var routes := ["genocide", "neutral", "pacifist"]
	var picked := -1
	while picked < 0:
		var choice := await Game.dialogue.ask("* (What do you want to do?)", options)
		var sure := await Game.dialogue.ask("* (Are you sure? You can't take this back.)", ["Yes", "No"])
		if sure == 0:
			picked = choice

	var route: String = routes[picked]
	Game.flags["route"] = route
	match route:
		"pacifist":
			# Joining the Corps closes off the other two paths.
			Game.flags["genocide_locked"] = true
			Game.flags["neutral_locked"] = true
			await _ending_pacifist()
		"neutral":
			# The Corps' offer stays open; going with Hop does not.
			Game.flags["genocide_locked"] = true
			await _ending_neutral()
		"genocide":
			Game.flags["pacifist_locked"] = true
			Game.flags["neutral_locked"] = true
			await _ending_genocide()

	Game.flags["chapter1_done"] = true
	Game.save_game(SCENE, player.position)
	await Game.change_scene(DEMO_END_SCENE)


func _ending_pacifist() -> void:
	await Game.dialogue.say([
		{"who": "Elric", "text": "...I'm in."},
		{"who": "BigJoe6", "text": "Then welcome to the REVOLUTION Corps.", "mood": "happy"},
		{"who": "Eggo", "text": "membership: a lot more than two now.", "mood": "happy"},
		{"who": "NCWethan", "text": "GROUP HUG!!!", "mood": "happy"},
		"* (NCWethan hugs everyone at once.\n*  There is a small electrical shock.)",
		{"who": "Hop", "text": "...You'd still want me around?\nAfter all that?", "mood": "sad"},
		{"who": "Elric", "text": "...You saved me. We'll save you."},
		{"who": "Hop", "text": "...Okay. Okay.", "mood": "happy"},
		"* (Hop laughs, and wipes his eyes,\n*  and doesn't say anything else for a while.)",
		{"who": "Nat", "text": "If the fragments are destroyed, Hopkuna can never\nfully wake up. That's our job now."},
		{"who": "Nassan", "text": "Nine fragments left. Let's find them before he does."},
	])


func _ending_neutral() -> void:
	await Game.dialogue.say([
		{"who": "Elric", "text": "...I need to think. On my own."},
		{"who": "Nassan", "text": "I understand. The offer stands.\nWhenever you're ready, you know where we are.", "mood": "sad"},
		{"who": "BigJoe6", "text": "...Just don't make us regret letting you walk.", "mood": "angry"},
		{"who": "Hop", "text": "Take care of yourself, mysterious traveler.", "mood": "sad"},
		{"who": "Hop", "text": "We'll keep an eye on each other. Me and them.", "mood": "sad"},
		"* (You walk away from Hilltop Park alone.)",
		"* (Behind you, the Corps gathers around Hop.)",
	])


func _ending_genocide() -> void:
	await Game.dialogue.say([
		{"who": "Elric", "text": "...I'm going with Hop."},
		{"who": "BigJoe6", "text": "...What?", "mood": "shocked"},
		{"who": "Eggo", "text": "elric. no.", "mood": "sad"},
		{"who": "Supreme", "text": "That's... that's the worst possible outcome.", "mood": "shocked"},
		{"who": "Hop", "text": "Elric, don't. You don't know what he'll-", "mood": "shocked"},
		{"who": "BigJoe6", "text": "Then you're no friend of Revolution.\nGET OUT.", "mood": "angry"},
		"* (The Corps forms a wall between you and the park.)",
		"* (Hop looks back at them. Then at you.)",
		{"who": "Hop", "text": "...I'm sorry, guys.", "mood": "sad"},
		"* (You and Hop walk into the dark.)",
		{"who": "Hopkuna", "tag": "???", "face": false, "text": "Good choice, little wanderer."},
	])


func _leave_after_chapter() -> void:
	await Game.change_scene(DEMO_END_SCENE)
