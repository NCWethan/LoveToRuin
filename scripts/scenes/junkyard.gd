extends Area
## The junkyard by the freeway (no fragment): a chain-link fence, mountains of
## junk, stacks of crushed cars, an office shack, and a crane with a car crusher
## for a body (Scrap Heap). In the back corner, under a tarp, a van that's been
## sitting there for years. Sansworth has been looking for "his car" the whole
## game. It was always this one: an uncle he forgot he had left it to him.
##
## Reached by bus once fragment 10 is found.
##
##   Corps      Everyone cuts through here on Hopkuna's trail. Scrap Heap's in the
##              way (Sansworth's keys calm it down). Sansworth finds the van. One
##              of his 31 keys starts it: "I TOLD you I had a car." Then Nassan
##              admits what he's known all along: one of the twelve circles was
##              always on Hop's house.
##   Own way    Elric gets past Scrap Heap alone, and watches from behind the junk
##              as the Corps finds the van and cheers. Nobody sees Elric.
##   With Hop   Sansworth is at the van. It never starts.
##
## Before anyone can reach the van, Scrap Heap's stacks of crushed cars have to
## move (Chapter 2: the road to each fragment): it walled the back corner in. Its
## cab (its own little room) has three levers, yellow, red and black, and a rhyme
## scratched into the dash. Pull them in the rhyme's order: down (yellow), grab
## (red), up (yellow), swing (black), let go (red).
##
## Story flags: jy_arrived, jy_heap_done, jy_pulls (so far), jy_cleared, jy_van,
## jy_nassan.

const SCENE := "res://scenes/junkyard.tscn"
const T := Room.TILE
const OUTSIDE := Rect2i(0, 0, 56, 36)
const ENTRY := Vector2(51 * T, 32 * T + 10)
const HEAP_SPOT := Vector2(28 * T, 12 * T)
const VAN := Rect2(4 * T, 24 * T, 5 * T, 3 * T)
const VAN_FRONT := Vector2(10 * T, 26 * T)
const SANSWORTH_SPOT := Vector2(10 * T + 10, 25 * T)
const NASSAN_SPOT := Vector2(44 * T, 28 * T)
## The crane's cab: its own little room on the map. The ladder up is by the crane.
const CAB := Rect2i(58, 3, 10, 9)
const CAB_LADDER := Vector2(28 * T + 14, 12 * T + 8)
const CAB_ENTRY := Vector2(63 * T, 9 * T + 10)
const CAB_EXIT := Vector2(63 * T, 11 * T - 2)
const OUTSIDE_CAB := Vector2(28 * T + 14, 13 * T + 16)
const LEVERS := ["Yellow", "Red", "Black"]
const LEVER_SPOTS := [Vector2(60 * T + 10, 6 * T + 4), Vector2(62 * T + 10, 6 * T + 4), Vector2(64 * T + 10, 6 * T + 4)]
const RHYME := Vector2(66 * T + 10, 6 * T + 4)
## Down, grab, up, swing, let go.
const LIFT_ORDER := ["Yellow", "Red", "Yellow", "Black", "Red"]
## The wall of crushed cars Scrap Heap stacked around the back corner.
const CAR_WALL := [Rect2i(1, 22, 12, 1), Rect2i(12, 23, 1, 12)]

var partner: Character
var heap: Character
## Scrap Heap after its fight: back to sorting (or stopped), and its cab's ladder.
var crane: Character
var sansworth: Character
var nassan: Character
var _decor: Node2D
var _shade: Node2D
var _font: Font
var _time: float = 0.0
var _engaged: bool = false
var _van_running: float = -1.0


func _ready() -> void:
	_engaged = str(Game.battle_result.get("id", "")) in ["scrap_heap", "corps_sansworth"]
	rooms.assign([_px(OUTSIDE), _px(CAB)])
	setup_area(ENTRY)
	add_wild_encounters(SCENE, Rect2(T, 14 * T, 54 * T, 20 * T))
	_font = ThemeDB.fallback_font
	_decor = Node2D.new()
	add_child(_decor)
	move_child(_decor, world.get_index())
	_decor.draw.connect(_draw_decor)
	add_static_layer(_draw_scenery)
	_shade = Node2D.new()
	add_child(_shade)
	_shade.draw.connect(_draw_shade)
	_place_people()
	_dress()
	for spot in [[ENTRY + Vector2(10, -8), _bus_stop], [VAN_FRONT + Vector2(0, 10), _van], [Vector2(8 * T + 10, 6 * T + 4), _shack],
			[Vector2(40 * T, 20 * T + 4), _car_stack], [CAB_LADDER, _cab_ladder], [CAB_EXIT, _leave_cab],
			[RHYME, _rhyme]]:
		world.add_child(Hotspot.create(spot[0], spot[1]))
	for i in LEVERS.size():
		world.add_child(Hotspot.create(LEVER_SPOTS[i], _pull.bind(LEVERS[i])))
	Game.play_music("junkyard")
	if flag("jy_van"):
		_van_running = 0.0
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
	if _van_running >= 0.0:
		_van_running += delta
	_decor.queue_redraw()


# --- The map -----------------------------------------------------------------------

## Set dressing (props.gd): wrecked cars, a couch and a fridge and a dead arcade
## cabinet out between the piles, a dumpster by the shack, pallets, barrels, crates,
## a stray cart, oil puddles.
func _dress() -> void:
	add_dressing([
		["dumpster", Vector2(15 * T, 4 * T + 10)],
		["trash_bag", Vector2(16 * T + 14, 6 * T + 6), {"walkable": true}],
		["sign", Vector2(13 * T + 10, 7 * T + 4), {"text": "BEWARE OF DOG", "color": Color8(170, 40, 35), "look": ["* (BEWARE OF DOG.)", "* (There is no dog. There's a very old cat on the\n*  shack's roof, and it's looking at you.)"]}],
		["couch", Vector2(26 * T, 9 * T), {"color": Color8(120, 90, 140), "look": ["* (A purple couch, out in the open. It's still\n*  comfy. There's 35 cents in the cushions.)"]}],
		["fridge", Vector2(24 * T, 15 * T), {"look": ["* (An old fridge with no door. Magnets on the side:\n*  a pizza place, a dentist, a little Eiffel Tower.)"]}],
		["arcade", Vector2(12 * T, 20 * T), {"look": ["* (An arcade cabinet. The screen is cracked.\n*  HIGH SCORE: RLC  999999.)"]}],
		["cart", Vector2(31 * T, 14 * T)],
		["pallet", Vector2(40 * T, 11 * T + 6)],
		["crates", Vector2(52 * T, 4 * T)],
		["barrel", Vector2(42 * T, 24 * T), {"look": ["* (A rusty barrel. Something sloshes inside.\n*  You decide not to find out what.)"]}],
		["barrel", Vector2(43 * T + 4, 24 * T + 8)],
		["car", Vector2(8 * T, 31 * T), {"color": Color8(140, 110, 90), "look": ["* (A rusted-out sedan with no wheels, sitting on\n*  cinderblocks. A bird lives in the glovebox.)"]}],
		["car", Vector2(28 * T, 32 * T), {"color": Color8(170, 100, 60)}],
		["car_v", Vector2(52 * T, 20 * T), {"color": Color8(110, 120, 110)}],
		["puddle", Vector2(26 * T, 21 * T + 10), {"size": Vector2(30, 10)}],
		["puddle", Vector2(48 * T, 25 * T), {"size": Vector2(24, 8)}],
		["bike", Vector2(14 * T, 29 * T), {"color": Color8(200, 60, 55), "look": ["* (A kid's bike with one wheel bent into a taco.\n*  The bell still works. Ding.)"]}],
		["lamp", Vector2(46 * T, 34 * T)],
	])


func build_map() -> void:
	room.setup(70, 36, Room.ASPHALT)
	room.fill(56, 0, 14, 36, Room.VOID)
	room.fill(0, 0, 56, 1, Room.FENCE)
	room.fill(0, 0, 1, 36, Room.FENCE)
	room.fill(55, 0, 1, 36, Room.FENCE)
	room.fill(0, 35, 56, 1, Room.FENCE)
	room.fill(47, 35, 8, 1, Room.ASPHALT)        # the gate (open)
	# The office shack.
	room.fill(3, 2, 10, 4, Room.WOOD_WALL)
	room.set_tile(8, 5, Room.DOOR)
	# The crane's pad, and the junk piles all around it.
	for pile in [Rect2i(18, 3, 5, 3), Rect2i(34, 3, 6, 3), Rect2i(44, 6, 7, 4), Rect2i(16, 16, 6, 3), Rect2i(30, 18, 4, 3),
			Rect2i(44, 14, 5, 3), Rect2i(20, 25, 7, 3), Rect2i(34, 27, 5, 3), Rect2i(2, 13, 6, 3)]:
		room.fill(pile.position.x, pile.position.y, pile.size.x, pile.size.y, Room.PROP)
	room.fill(38, 19, 4, 2, Room.PROP)             # the stack of crushed cars
	room.fill(4, 24, 5, 3, Room.PROP)              # the van, under its tarp
	# Scrap Heap's wall of crushed cars around the back corner (until it's moved).
	if not _cleared():
		for r in CAR_WALL:
			room.fill(r.position.x, r.position.y, r.size.x, r.size.y, Room.PROP)
	# The crane's cab: a little steel box, three levers, a window.
	room.fill(CAB.position.x, CAB.position.y, CAB.size.x, CAB.size.y, Room.BUNKER_WALL)
	room.fill(59, 6, 8, 5, Room.BUNKER_FLOOR)
	room.set_tile(63, 11, Room.BUNKER_DOOR)


const HEAPS := [Rect2i(18, 3, 5, 3), Rect2i(34, 3, 6, 3), Rect2i(44, 6, 7, 4), Rect2i(16, 16, 6, 3), Rect2i(30, 18, 4, 3),
	Rect2i(44, 14, 5, 3), Rect2i(20, 25, 7, 3), Rect2i(34, 27, 5, 3), Rect2i(2, 13, 6, 3)]


## What never changes: the junk heaps, the stack of crushed cars, the shack's
## tin roof. (Drawn once; see Area.add_static_layer.)
func _draw_scenery(ci: CanvasItem) -> void:
	for i in HEAPS.size():
		var r := _px(HEAPS[i])
		# A little taller than their footprint: junk piles up.
		Scenery.junk_heap(ci, Rect2(r.position + Vector2(-4, -14), r.size + Vector2(8, 14)), 41 + i * 7)
	Scenery.crushed_cars(ci, Rect2(38 * T, 19 * T - 6, 4 * T, 2 * T + 6), 5)
	Scenery.shack_roof(ci, _px(Rect2i(3, 2, 10, 4)))


func _draw_decor() -> void:
	# (The heaps and the crushed cars are on the static layer: _draw_scenery.)
	_draw_car_wall()
	_draw_cab()
	# The ladder up Scrap Heap's side to its cab (until the cars are moved).
	if flag("jy_heap_done") and not _cleared():
		var foot := CAB_LADDER + Vector2(0, 2)
		_decor.draw_line(foot + Vector2(-5, 0), foot + Vector2(-5, -26), Color8(200, 170, 60), 2.0)
		_decor.draw_line(foot + Vector2(5, 0), foot + Vector2(5, -26), Color8(200, 170, 60), 2.0)
		for k in 4:
			_decor.draw_line(foot + Vector2(-5, -4 - k * 6), foot + Vector2(5, -4 - k * 6), Color8(230, 200, 90), 2.0)
		var bob := sin(_time * 4.0) * 2.0
		_decor.draw_colored_polygon(PackedVector2Array([foot + Vector2(-4, -36 + bob), foot + Vector2(4, -36 + bob), foot + Vector2(0, -30 + bob)]), Color8(250, 220, 80))
	# The van: tan, boxy, a tarp half off it, flat tires. (Running, it shakes.)
	var shake := Vector2(sin(_time * 40.0) * 1.0, 0) if _van_running >= 0.0 else Vector2.ZERO
	var van := Rect2(VAN.position + shake, VAN.size)
	Scenery.van(_decor, van, not flag("jy_van"), not flag("jy_van"))
	if flag("jy_van"):
		# Exhaust.
		for k in 3:
			var age := fmod(_time * 2.0 + k * 0.33, 1.0)
			_decor.draw_circle(Vector2(van.position.x - 6 - age * 20, van.end.y - 6 - age * 16), 4.0 + age * 6.0, Color(0.4, 0.4, 0.42, 0.6 * (1.0 - age)))
	# The shack sign, the gate, the bus stop.
	_decor.draw_string(_font, Vector2(3 * T + 6, 3 * T), "OFFICE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color8(240, 230, 210))
	_decor.draw_string(_font, Vector2(46 * T, 35 * T - 4), "GATE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color8(240, 200, 60))
	Scenery.bus_stop(_decor, ENTRY + Vector2(9, -8))
	# The freeway, roaring past beyond the back fence.
	for k in 6:
		var x := fmod(k * 210.0 + _time * 160.0, 56.0 * T + 200.0) - 100.0
		_decor.draw_rect(Rect2(x, -6, 40, 6), Color(0.9, 0.9, 1.0, 0.25))


## Overcast, the freeway's noise, a little dusty.
func _draw_shade() -> void:
	_shade.draw_rect(_px(OUTSIDE), Color(0.5, 0.45, 0.4, 0.1))


# --- People ----------------------------------------------------------------------

func _place_people() -> void:
	if not Game.walking_alone():
		partner = Cast.make(Game.partner())
		add_character(partner, player.position + Vector2(-20, 0))
		partner.follow = player
	add_person("junkdealer", Vector2(10 * T, 7 * T + 4), SCENE)
	match _route():
		"pacifist":
			if Game.partner() != "Sansworth":
				sansworth = add_npc("Sansworth", Vector2(46 * T, 30 * T), _talk_sansworth)
			if Game.partner() != "Nassan":
				nassan = add_npc("Nassan", NASSAN_SPOT, _talk_nassan)
		"neutral":
			pass
		_:
			if not flag("beat_corps_sansworth"):
				sansworth = add_npc("Sansworth", SANSWORTH_SPOT, _talk_sansworth)
	if not flag("jy_heap_done") and str(Game.battle_result.get("id", "")) != "scrap_heap":
		heap = Cast.make("scrap_heap")
		heap.glow = true
		heap.glow_color = Color(1.0, 0.85, 0.5, 0.3)
		add_character(heap, HEAP_SPOT)
	else:
		# After its fight, it's still here: sorting quietly, or stopped for good.
		crane = Cast.make("scrap_heap")
		if Game.battle_result.get("id", "") == "scrap_heap" and Game.battle_result.get("spared", []).is_empty() or flag("jy_heap_stopped"):
			crane.modulate = Color(0.55, 0.55, 0.58)
		crane.on_interact = _talk_crane
		add_character(crane, HEAP_SPOT)


func _talk_sansworth() -> void:
	match _route():
		"pacifist":
			if flag("jy_van"):
				await chat("jy_sans_after", [{"who": "Sansworth", "text": "I TOLD you I had a car.\nI TOLD everyone. Nobody listens to Sansworth.", "mood": "happy"}], [[{"who": "Sansworth", "text": "VROOM. (For real this time.)", "mood": "happy"}]])
				return
			await chat("jy_sans", [
				{"who": "Sansworth", "text": "My car's here. I can FEEL it.\nIn my keys. All thirty-one of them.", "mood": "happy"},
				{"who": "Sansworth", "text": "I have been looking for my car my WHOLE life.\nI don't remember buying a car. But it's here.", "mood": "smug"},
				{"who": "Sansworth", "text": "That big crane thing's in the way, though.\nIt yelled at me. In crane.", "mood": "sad"},
			], [[{"who": "Sansworth", "text": "Back corner. I just know it.", "mood": "happy"}]])
		_:
			await _confront_sansworth()


func _talk_nassan() -> void:
	if flag("jy_nassan"):
		await chat("jy_nassan_after", [{"who": "Nassan", "text": "Hop's house. That's step two.\nIt was always step two.", "mood": "sad"}], [[{"who": "Nassan", "text": "Let's go.", "mood": ""}]])
		return
	await chat("jy_nassan_first", [
		{"who": "Nassan", "text": "The trail goes right through here.\nBurned tire marks. North, then... it just stops.", "mood": ""},
		{"who": "Nassan", "text": "Get past the crane. Help Sansworth find his...\nwhatever it is. We'll need a way to move fast.", "mood": ""},
	], [[{"who": "Nassan", "text": "The crane. Then the back corner.", "mood": ""}]])


# --- Things --------------------------------------------------------------------------

# --- The crane's cab ------------------------------------------------------------------

## The cars have been moved off the back corner (or it's past that in the story).
func _cleared() -> bool:
	return flag("jy_cleared") or flag("jy_van") or flag("jy_nassan") or flag("beat_corps_sansworth")


func _talk_crane() -> void:
	if flag("jy_heap_stopped"):
		await Game.dialogue.say(["* (Scrap Heap. It doesn't move. Its headlights are\n*  dark.)", "* (The ladder up to its cab is still there.)" if not _cleared() else "* (It's very quiet.)"])
	else:
		await Game.dialogue.say(["* (Scrap Heap, sorting. It moves a hubcap from one\n*  pile to another, very carefully.)", "* (A ladder runs up its side to the cab.)" if not _cleared() else "* (It hums at you. Friendly. Probably.)"])


func _cab_ladder() -> void:
	if not flag("jy_heap_done"):
		await Game.dialogue.say(["* (A ladder up to the crane's cab.\n*  The crane is very much still moving. Not now.)"])
		return
	if _cleared():
		await Game.dialogue.say(["* (The crane's cab. The cars are moved.\n*  Scrap Heap is back to sorting, quietly.)"])
		return
	Game.play_sfx("door", 0.8)
	await go_through_door(CAB_ENTRY)
	fit_camera_to_room()
	if not flag("jy_cab_seen"):
		Game.flags["jy_cab_seen"] = true
		await Game.dialogue.say([
			"* (The crane's cab. It smells like coffee and\n*  hydraulic fluid. Three levers: yellow, red, black.)",
			"* (Through the window: the stack of crushed cars, and\n*  the van behind it, in the corner.)",
			"* (Something's scratched into the dash.)",
		])
		if _genocide():
			await Game.dialogue.say([{"who": "Relic", "tag": "", "face": false, "text": "* Sal left instructions.\n* Nobody leaves instructions for the hard part."}])


func _leave_cab() -> void:
	Game.play_sfx("door", 0.8)
	await go_through_door(OUTSIDE_CAB)
	fit_camera_to_room()


func _rhyme() -> void:
	await Game.dialogue.say([
		"* (Scratched into the dash with a key:)",
		"* (\"YELLOW takes it DOWN, RED grabs hold,\n*  YELLOW brings it UP, BLACK swings it 'ROUND,\")",
		"* (\"and RED lets go. - SAL. 1979.\")",
	])


## A lever: the crane does its part, if it's the right one next.
func _pull(lever: String) -> void:
	if _cleared():
		await Game.dialogue.say(["* (The %s lever. The job's done.)" % lever.to_lower()])
		return
	var pulls: Array = Game.flags.get("jy_pulls", [])
	var next: String = LIFT_ORDER[pulls.size()]
	Game.play_sfx("engine", 0.8)
	if lever != next:
		Game.play_sfx("bonk")
		Game.flags["jy_pulls"] = []
		var what: String = {"Yellow": "The boom lurches the wrong way.", "Red": "The magnet hums at nothing.", "Black": "The crane swings, with nothing on it."}[lever]
		await Game.dialogue.say(["* (%s CLANG.\n*  Everything shudders back to where it started.)" % what])
		return
	pulls = pulls.duplicate()
	pulls.append(lever)
	Game.flags["jy_pulls"] = pulls
	var says: Array = [
		"* (The boom groans, and the magnet goes DOWN\n*  onto the stack of crushed cars.)",
		"* (A deep hum. The magnet GRABS the whole stack.)",
		"* (The boom comes UP. The cars come with it,\n*  dripping rust.)",
		"* (The crane swings 'ROUND, cars and all,\n*  out over the open lot.)",
		"* (The magnet lets go. The cars drop: CRASH.\n*  The whole junkyard jumps.)",
	]
	await Game.dialogue.say([says[pulls.size() - 1]])
	if pulls.size() < LIFT_ORDER.size():
		return
	Game.flags["jy_cleared"] = true
	for r in CAR_WALL:
		room.fill(r.position.x, r.position.y, r.size.x, r.size.y, Room.ASPHALT)
	room._build_collision()
	Game.play_sfx("save")
	await Game.dialogue.say(["* (Through the window: the back corner, open.\n*  The van, under its tarp, waiting.)"])
	Game.play_sfx("door", 0.8)
	await go_through_door(OUTSIDE_CAB)
	fit_camera_to_room()
	match _route():
		"pacifist":
			await _van_found()
		"neutral":
			await _watch_from_behind()
		_:
			Game.set_objective("...")


## The crushed cars stacked around the back corner, until they're moved.
func _draw_car_wall() -> void:
	if _cleared():
		return
	var colors := [Color8(140, 70, 60), Color8(70, 90, 120), Color8(110, 110, 100), Color8(150, 120, 60), Color8(80, 100, 80)]
	var k := 0
	for r in CAR_WALL:
		var px: Rect2 = _px(r)
		var horizontal: bool = r.size.x > r.size.y
		var steps: int = r.size.x if horizontal else r.size.y
		for i in steps:
			var at := px.position + (Vector2(i * T, 0) if horizontal else Vector2(0, i * T))
			for layer in 3:
				var c: Color = colors[(k + layer) % colors.size()]
				var slab := Rect2(at + Vector2(1, T - 6 - layer * 6), Vector2(T - 2, 6))
				_decor.draw_rect(slab, c.darkened(0.15))
				_decor.draw_rect(Rect2(slab.position, Vector2(slab.size.x, 1)), c.lightened(0.15))
				_decor.draw_rect(Rect2(slab.position + Vector2(3, 2), Vector2(4, 2)), Color8(120, 160, 190))
			k += 1


## The cab: the window over the junkyard, the dash, the three levers.
func _draw_cab() -> void:
	var r := _px(CAB)
	var window := Rect2(r.position + Vector2(T + 4, T - 6), Vector2(r.size.x - 2 * T - 8, T + 2))
	_decor.draw_rect(window.grow(2), Color8(60, 64, 70))
	_decor.draw_rect(window, Color8(150, 170, 190))
	# Junk heaps through the glass, and the crushed cars.
	for k in 6:
		_decor.draw_circle(window.position + Vector2(14 + k * 26, window.size.y + 4), 14.0, Color8(110, 100, 90))
	if not _cleared():
		_decor.draw_rect(Rect2(window.position + Vector2(20, window.size.y - 12), Vector2(30, 12)), Color8(140, 70, 60))
	var pulls: Array = Game.flags.get("jy_pulls", [])
	# The dash, and the levers (each one pulled back if it's been pulled).
	_decor.draw_rect(Rect2(r.position.x + T, 6 * T - 4, r.size.x - 2 * T, 6), Color8(80, 84, 90))
	var lever_colors := {"Yellow": Color8(240, 200, 40), "Red": Color8(220, 50, 40), "Black": Color8(30, 30, 34)}
	for i in LEVERS.size():
		var at: Vector2 = LEVER_SPOTS[i] + Vector2(0, -6)
		var back := pulls.count(LEVERS[i]) % 2 == 1
		_decor.draw_line(at, at + Vector2(-5 if back else 5, -12), Color8(160, 164, 170), 2.0)
		_decor.draw_circle(at + Vector2(-5 if back else 5, -13), 3.5, lever_colors[LEVERS[i]])
	# The scratches on the dash.
	for k in 3:
		_decor.draw_line(RHYME + Vector2(-8, -12 + k * 3), RHYME + Vector2(6, -12 + k * 3), Color8(200, 200, 200, 120), 1.0)


func _van() -> void:
	if flag("jy_van"):
		await Game.dialogue.say(["* (The van is running. It smells like 1994.)", "* (There's a sticker on the bumper: MY OTHER CAR\n*  IS ALSO THIS CAR.)"])
		return
	await Game.dialogue.say(["* (A van, under a tarp. Tan, boxy, four flat tires.\n*  The registration in the window is very old.)", "* (Under the wiper, a note, sun-faded:\n*  \"FOR MY NEPHEW. HE'LL KNOW WHICH KEY. - UNCLE S.\")"])


func _shack() -> void:
	await Game.dialogue.say(["* (The office. A sign: WE BUY JUNK. WE SELL JUNK.\n*  WE ARE JUNK. - MGMT)"])


func _car_stack() -> void:
	await Game.dialogue.say(["* (Four crushed cars, stacked like pancakes.\n*  One of them still has fuzzy dice.)"])


func _bus_stop() -> void:
	await ride_bus(SCENE)


# --- Story ------------------------------------------------------------------------

func _start() -> void:
	await wait_for_fade()
	if not is_inside_tree():
		return
	var id := str(Game.battle_result.get("id", ""))
	var spared: bool = not Game.battle_result.get("spared", []).is_empty()
	if id in ["scrap_heap", "corps_sansworth"]:
		Game.battle_result = {}
	match id:
		"scrap_heap":
			await run_cutscene(_after_heap.bind(spared))
			return
		"corps_sansworth":
			await run_cutscene(_after_sansworth)
			return
	if await handle_person_return():
		return
	if not flag("jy_arrived"):
		await run_cutscene(_arrival)


func _physics_process(_delta: float) -> void:
	if is_blocked() or _engaged:
		return
	check_random_encounter(SCENE)
	if heap and is_instance_valid(heap) and player.position.distance_to(heap.position) < 80.0:
		run_cutscene(_meet_heap)
		return
	if _genocide() and not heap and _cleared() and sansworth and is_instance_valid(sansworth) and player.position.distance_to(sansworth.position) < 80.0:
		run_cutscene(_confront_sansworth)


func _arrival() -> void:
	Game.flags["jy_arrived"] = true
	await Game.dialogue.say([
		"* (The junkyard, under the freeway. Mountains of\n*  junk. A crane in the middle, moving by itself.)",
		"* (The crane has a car crusher for a body.\n*  It's sorting. It's been sorting for a long time.)",
	])
	match _route():
		"pacifist":
			await Game.dialogue.say([{"who": "Nassan", "text": "Elric. Over here. The trail comes right through.", "mood": ""}])
			Game.set_objective("Get past the crane. (Scrap Heap.)")
		"neutral":
			await Game.dialogue.say(["* (Tire tracks, burned into the asphalt.\n*  Heading north, straight through.)"])
			Game.set_objective("Get past the crane.")
		_:
			await Game.dialogue.say([
				"* (In the back corner, next to a van under a tarp:\n*  Sansworth, sitting on the bumper, smiling.)",
				{"who": "Hop", "text": "...He's still smiling. Why is he smiling.", "mood": "sad"},
				{"who": "Relic", "tag": "", "face": false, "text": "* He doesn't know any better."},
			])
			Game.set_objective("...")


func _meet_heap() -> void:
	if _engaged:
		return
	_engaged = true
	heap.face(player.position - heap.position)
	await Game.dialogue.say([
		"* (Scrap Heap's magnet swings around to face you.)",
		"* (Its headlights snap on. A car alarm goes off,\n*  somewhere inside it, like a growl.)",
	])
	await Game.start_battle("scrap_heap", SCENE, player.position)


func _after_heap(spared: bool) -> void:
	Game.flags["jy_heap_done"] = true
	if spared:
		await Game.dialogue.say([
			"* (Scrap Heap lowers its magnet. Its headlights dim.)",
			"* (It goes back to sorting. It moves a tire\n*  out of your way. Then a whole car.)",
		])
	else:
		Game.flags["jy_heap_stopped"] = true
		await Game.dialogue.say(["* (Scrap Heap shudders, and stops. Steam hisses out\n*  of it. It doesn't move again.)"])
		if _genocide():
			await Game.dialogue.say([{"who": "Relic", "tag": "", "face": false, "text": "* Scrap."}])
	_engaged = false
	if not _cleared():
		await Game.dialogue.say([
			"* (In the back corner, behind Scrap Heap's sorting:\n*  a wall of crushed cars, stacked three high.)",
			"* (It's walled in a van. Under a tarp.)",
		])
		if _route() == "pacifist":
			await Game.dialogue.say([{"who": "Nassan", "text": "Somebody has to work the crane.\nThe cab's up the ladder. Please don't crush anyone.", "mood": ""}])
		Game.set_objective("Move the cars. (The crane's cab.)" if not _genocide() else "...")
		return
	match _route():
		"pacifist":
			await _van_found()
		"neutral":
			await _watch_from_behind()
		_:
			Game.set_objective("...")


## Corps: Sansworth finds his van. One of his 31 keys starts it.
func _van_found() -> void:
	if sansworth:
		sansworth.follow = null
		await sansworth.walk_to(VAN_FRONT + Vector2(20, 20), 140.0)
		sansworth.face(Vector2.LEFT)
	await Game.dialogue.say([
		{"who": "Sansworth", "text": "...", "mood": "shocked"},
		{"who": "Sansworth", "text": "That's my car.", "mood": "shocked"},
		"* (He pulls off the tarp. A van. Tan, boxy,\n*  very old. There's a note under the wiper.)",
		"* (\"FOR MY NEPHEW. HE'LL KNOW WHICH KEY.\")",
		{"who": "Sansworth", "text": "I have an UNCLE?", "mood": "shocked"},
		"* (He tries a key. It doesn't fit. He tries another.)",
		"* (...)",
		"* (Key thirty-one.)",
		"* (The van coughs, and shakes, and STARTS.)",
	])
	Game.flags["jy_van"] = true
	_van_running = 0.0
	Game.play_sfx("honk" if Game.has_sfx("honk") else "brakes")
	await Game.dialogue.say([
		{"who": "Sansworth", "text": "I TOLD you I had a car!", "mood": "happy"},
		{"who": "Sansworth", "text": "I TOLD EVERYONE I HAD A CAR!", "mood": "happy"},
		"* (He did. Nobody believed him. He didn't know\n*  he had a car either.)",
	])
	await _nassan_admits()


func _nassan_admits() -> void:
	if nassan:
		await nassan.walk_to(player.position + Vector2(40, 0), 100.0)
		nassan.face(player.position - nassan.position)
	Game.flags["jy_nassan"] = true
	await Game.dialogue.say([
		{"who": "Nassan", "text": "Elric. I need to tell you something. All of you.", "mood": "sad"},
		{"who": "Nassan", "text": "The map. Twelve circles. I made it the first week.\nOne of them was always on Hop's house.", "mood": "sad"},
		{"who": "Nassan", "text": "I knew. From the start. I never said anything,\nbecause I couldn't plan around my friend lying to me.", "mood": "sad"},
		{"who": "Nassan", "text": "I thought if I didn't say it, it wasn't real.", "mood": "sad"},
		{"who": "Nassan", "text": "Fragment eleven is at Hop's house.\nAnd if Hopkuna knows that, he's going there next.", "mood": ""},
		{"who": "Sansworth", "text": "EVERYBODY IN THE VAN.", "mood": "happy"},
	])
	Game.set_objective("Hop's house. (Fragment eleven. Bus: Hop's Street.)")


## Own way: Elric watches from behind the junk as the Corps finds the van.
func _watch_from_behind() -> void:
	await Game.dialogue.say([
		"* (Voices, at the gate. You duck behind a pile of hubcaps.)",
		"* (The Corps. All of them, minus one. They walk right past.)",
	])
	var crowd: Array[Character] = []
	for i in 4:
		var who: String = ["Sansworth", "Nassan", "BigJoe6", "NCWethan"][i]
		var member := add_character(Cast.make(who), ENTRY + Vector2(-30 * i, 0))
		crowd.append(member)
	for member in crowd:
		member.walk_to(VAN_FRONT + Vector2(30 + crowd.find(member) * 24, 30), 120.0)
	await get_tree().create_timer(2.2).timeout
	Game.flags["jy_van"] = true
	_van_running = 0.0
	await Game.dialogue.say([
		"* (Sansworth pulls a tarp off a van, and starts\n*  trying keys. Thirty-one of them.)",
		"* (The thirty-first one works.)",
		{"who": "Sansworth", "text": "I TOLD you I had a car!", "mood": "happy"},
		"* (Everyone cheers. N.C. picks Sansworth up.\n*  Big Joe is crying a little.)",
		"* (Nobody looks behind the hubcaps.)",
		{"who": "Relic", "tag": "", "face": false, "text": "* (quietly) You could still go over there."},
		"* (You don't.)",
	])
	Game.set_objective("Hop's house. (The last circle on the map.)")


# --- With Hop: Sansworth ---------------------------------------------------------------

func _confront_sansworth() -> void:
	if not sansworth or not is_instance_valid(sansworth) or _engaged:
		return
	_engaged = true
	sansworth.face(player.position - sansworth.position)
	await Game.dialogue.say([
		{"who": "Sansworth", "text": "ELRIC! HOP! You came! I found my CAR!", "mood": "happy"},
		{"who": "Sansworth", "text": "It's a van. It's MY van. I'm gonna drive\neverybody somewhere safe! Where's everybody?", "mood": "happy"},
		"* (He looks at you, and at Hop, and at the gate.\n*  Nobody else is coming.)",
		{"who": "Sansworth", "text": "...Oh.", "mood": "sad"},
		{"who": "Sansworth", "text": "That's okay. Shotgun's open. Get in.\nI'll drive. I just need the right key.", "mood": "happy"},
		{"who": "Hop", "text": "Sansworth. RUN. Please. Just run.", "mood": "sad"},
		{"who": "Sansworth", "text": "I can't run, Hop. I've got a car now.", "mood": "happy"},
	])
	await Game.start_battle("corps_sansworth", SCENE, player.position)


func _after_sansworth() -> void:
	if sansworth:
		sansworth.queue_free()
		sansworth = null
	var kept: Array = Game.flags.get("mementos", [])
	if not "One of His Keys" in kept:
		kept.append("One of His Keys")
	Game.flags["mementos"] = kept
	await Game.dialogue.say([
		"* (Thirty-one keys on the asphalt.)",
		"* (You pick one up. It's the thirty-first.\n*  It would have started the van.)",
		"* (You keep it.)",
		{"who": "Relic", "tag": "", "face": false, "text": Game.corps_dead_count()},
	])
	_engaged = false
	Game.set_objective("...")
