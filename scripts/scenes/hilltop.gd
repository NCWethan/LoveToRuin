extends Area
## Westview Field: the REVOLUTION Corps' base, and Chapter 1's climax.
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
## Chapter 2: the hatch under the shelter leads down into the Corps' base, and the
## road south goes back through Westview (into the gym, by the emergency exit).
const CORPS_BASE_SCENE := "res://scenes/corps_base.tscn"
const HOP_HOUSE_SCENE := "res://scenes/hop_house.tscn"
const WESTVIEW_SCENE := "res://scenes/westview.tscn"
const HATCH := Vector2(7 * 20 + 10, 5 * 20 + 10)
const T := Room.TILE

## Where Elric ends up the morning after going their own way (by the benches).
const MORNING_SPOT := Vector2(420, 520)
## The foot of the ladder down in the Corps' base.
const BASE_LADDER := Vector2(20 * 20, 5 * 20)
## Where Elric arrives (the path at the bottom of the park).
const ENTRY := Vector2(400, 548)
## The middle of the big field, where fragment 3 is buried.
const CRATER := Vector2(410, 270)
## How close to the crater Elric has to get for it to erupt.
const ERUPT_DISTANCE := 95.0

## Who arrives with the REVOLUTION Corps, in the order they stand around Hopkuna
## (going around the circle from Elric).
const CORPS := ["Rooster", "Ronin", "Nat", "Agent", "Nassan", "MuffinMage", "Crayola", "Supreme", "BigJoe6", "Sansworth", "Eggo", "NCWethan"]
## The circle they make around Hopkuna (an oval, since the ground is seen at an angle).
const CORPS_RING := Vector2(100, 66)

## The field's sprinklers, one per corner (named like the compass). While a corner's
## sprinkler is on, the water pushes Elric back out of it. The control box by the
## benches turns them off.
const SPRINKLERS := ["NW", "NE", "SW", "SE"]
const FIELD_RECT := Rect2(160, 120, 480, 320)
const CONTROL_BOX := Vector2(630, 474)
## Two old tent stakes in the grass past the edge of the field, blackened by a fire,
## years ago. (The night Relic died; see DESIGN.md.)
const TENT_STAKES := Vector2(690, 232)
## Where someone walks their dog, at the bottom-left of the park.
const DOG_WALKER := Vector2(180, 470)

var hop: Character
var corps: Dictionary = {}
## Where Elric last stood that wasn't soaking wet (to push them back to).
var _dry_spot: Vector2
## Marks where the buried fragment is (removed once it erupts).
var _crater_marker: Node2D
var _decor: Node2D
var _night: CanvasModulate
var _font: Font
var _time: float = 0.0
## While above 0, a red beam is drawn from the crater toward `_beam_target`.
var _beam_time: float = 0.0
var _beam_target: Vector2
const BEAM_LENGTH := 1.0
## While above 0, the fragment is charging up: red light pours into the crater and
## a thin aiming line flickers toward Elric. Counts down from CHARGE_LENGTH.
var _charge_time: float = 0.0
const CHARGE_LENGTH := 1.6
## Keeps the charge at full (while Hop runs in) until it fires.
var _charge_hold: bool = false
## While above 0, sparks and flames fly around Hopkuna.
var _spark_time: float = 0.0
## While above 0, NCWethan's lightning / Ronin's fire stream into Hopkuna.
var _lightning_time: float = 0.0
var _fire_time: float = 0.0
## While above 0, NCWethan is zapping everyone in his group hug.
var _hug_zap_time: float = 0.0
var _hug_center: Vector2
var _fx: Node2D


func _ready() -> void:
	setup_area(ENTRY)
	# (Only once the night on the field is over: no wild fights in the middle of it.)
	if flag("chapter1_done"):
		add_wild_encounters(SCENE, Rect2(Vector2.ZERO, room.pixel_size()))
	Game.play_music("hilltop")
	_font = ThemeDB.fallback_font

	_night = CanvasModulate.new()
	# (Chapter 2 visits are by day.)
	_night.color = Color(1, 1, 1) if _day() else Color(0.6, 0.62, 0.85)
	add_child(_night)

	_decor = Node2D.new()
	add_child(_decor)
	_decor.draw.connect(_draw_decor)
	# Drawn just above the ground but below everyone walking around.
	move_child(_decor, world.get_index())

	# Effects that glow on top of everyone, unaffected by the night tint (they're on
	# their own layer, which still scrolls with the camera).
	var fx_layer := CanvasLayer.new()
	fx_layer.follow_viewport_enabled = true
	add_child(fx_layer)
	_fx = Node2D.new()
	fx_layer.add_child(_fx)
	_fx.draw.connect(_draw_fx)

	_place_people()
	world.add_child(Hotspot.create(Vector2(110, 96), _read_map))
	world.add_child(Hotspot.create(CONTROL_BOX, _control_box))
	world.add_child(Hotspot.create(TENT_STAKES + Vector2(0, 8), _tent_stakes))
	# The buried fragment: a red glow in the field, and eerie music when you get close.
	if not flag("hp_erupted"):
		_crater_marker = Node2D.new()
		_crater_marker.position = CRATER
		_crater_marker.add_to_group("fragment")
		_crater_marker.set_meta("music_range", 1.8)
		_crater_marker.add_child(make_light(Color(0.9, 0.1, 0.15), 70.0, 0.9))
		world.add_child(_crater_marker)
	_dry_spot = player.position
	fit_camera_to_room()
	_start.call_deferred()


# --- The map --------------------------------------------------------------

## The blast from the crater: how far it scorched the ground and burned the trees
## (in tiles), measured from the crater.
const BLAST_RADIUS := 13.0
const TREE_BLAST_RADIUS := 19.0
## True once the shockwave has gone off (from the moment it happens, and on every
## visit after).
var _blasted: bool = false
## While above 0, the shockwave ring is spreading out from the crater.
var _shock_time: float = 0.0
const SHOCK_LENGTH := 1.0


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
	# After the eruption, the blast has torn up the park, for good.
	if flag("hp_erupted"):
		_blast_tiles()


## The shockwave's damage: grass and field burned to scorched ground in a ragged
## circle around the crater, and every tree in reach burned down to a stump.
func _blast_tiles() -> void:
	_blasted = true
	var middle := CRATER / Room.TILE
	for y in room.height:
		for x in room.width:
			var tile := room.get_tile(x, y)
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(middle)
			var ragged := float((x * 7 + y * 13) % 5) * 0.6 - 1.2
			if tile in [Room.GRASS, Room.FIELD, Room.FIELD_LINE] and distance < BLAST_RADIUS + ragged:
				room.set_tile(x, y, Room.SCORCHED)
			elif tile == Room.TREE and distance < TREE_BLAST_RADIUS:
				room.set_tile(x, y, Room.STUMP)


func _process(delta: float) -> void:
	_time += delta
	_beam_time = maxf(_beam_time - delta, 0.0)
	_shock_time = maxf(_shock_time - delta, 0.0)
	if not _charge_hold:
		_charge_time = maxf(_charge_time - delta, 0.0)
	_spark_time = maxf(_spark_time - delta, 0.0)
	_lightning_time = maxf(_lightning_time - delta, 0.0)
	_fire_time = maxf(_fire_time - delta, 0.0)
	_hug_zap_time = maxf(_hug_zap_time - delta, 0.0)
	_decor.queue_redraw()
	_fx.queue_redraw()


func _draw_decor() -> void:
	# The old tent stakes: two short, blackened spikes, half buried, a scrap of
	# melted fabric caught on one.
	for k in 2:
		var stake := TENT_STAKES + Vector2(k * 14 - 7, 0)
		_decor.draw_line(stake + Vector2(0, -6), stake + Vector2(1, 3), Color8(40, 34, 30), 2.0)
		_decor.draw_circle(stake + Vector2(0, -6), 1.5, Color8(60, 52, 46))
	_decor.draw_rect(Rect2(TENT_STAKES + Vector2(-9, -2), Vector2(5, 3)), Color8(80, 90, 60))
	# Chapter 2: the hatch down to the base, in front of the shelter.
	if _day():
		_decor.draw_rect(Rect2(HATCH + Vector2(-14, -10), Vector2(28, 18)), Color8(85, 90, 98))
		_decor.draw_rect(Rect2(HATCH + Vector2(-14, -10), Vector2(28, 18)), Color8(50, 54, 60), false, 2.0)
		_decor.draw_arc(HATCH + Vector2(0, -1), 5.0, 0.0, TAU, 12, Color8(150, 155, 165), 2.0)
	# The REVOLUTION banner on the shelter.
	var banner := Rect2(52, 46, 86, 16)
	_decor.draw_rect(banner, Color8(235, 225, 200))
	_decor.draw_string(_font, banner.position + Vector2(4, 12), "REVOLUTION", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color8(170, 30, 30))

	# The sprinkler control box by the benches.
	_decor.draw_rect(Rect2(CONTROL_BOX + Vector2(-8, -18), Vector2(16, 16)), Color8(60, 105, 70))
	_decor.draw_rect(Rect2(CONTROL_BOX + Vector2(-8, -18), Vector2(16, 16)), Color8(35, 60, 40), false, 1.0)
	_decor.draw_rect(Rect2(CONTROL_BOX + Vector2(-5, -15), Vector2(10, 4)), Color8(200, 200, 190))
	_decor.draw_rect(Rect2(CONTROL_BOX + Vector2(-2, -2), Vector2(4, 4)), Color8(80, 80, 80))

	# Sprinklers spraying in each corner of the field that's still switched on.
	if not flag("hp_erupted"):
		for corner in SPRINKLERS:
			if _sprinkler_on(corner):
				_draw_sprinkler(_quadrant(corner))

	# The glow from the buried fragment, then the crater it leaves behind.
	if not flag("hp_erupted"):
		var pulse := 0.35 + 0.25 * sin(_time * 2.5)
		_decor.draw_circle(CRATER, 14, Color(1, 0.15, 0.2, pulse))
		_decor.draw_circle(CRATER, 6, Color(1, 0.5, 0.5, pulse))
	elif not _blasted:
		_decor.draw_circle(CRATER, 16, Color8(70, 50, 35))
		_decor.draw_arc(CRATER, 16, 0, TAU, 20, Color8(45, 30, 20), 3.0)
	else:
		# A deep crater, with scorch marks raying out from it.
		for k in 12:
			var dir := Vector2.from_angle(k * TAU / 12 + 0.3)
			_decor.draw_line(CRATER + dir * 30, CRATER + dir * (60 + (k * 17) % 40), Color8(25, 18, 14), 3.0)
		_decor.draw_circle(CRATER, 36, Color8(40, 30, 24))
		_decor.draw_circle(CRATER, 26, Color8(28, 20, 16))
		_decor.draw_arc(CRATER, 36, 0, TAU, 32, Color8(80, 62, 48), 3.0)
		# The wrecked sprinkler heads, one in each corner of what was the field.
		for corner in SPRINKLERS:
			var head := _quadrant(corner).get_center()
			_decor.draw_line(head, head + Vector2(6, -3), Color8(70, 70, 76), 2.0)
			_decor.draw_circle(head, 3, Color8(60, 60, 66))
			_decor.draw_rect(Rect2(head + Vector2(-6, 3), Vector2(12, 3)), Color(0.4, 0.55, 0.7, 0.4))
		if not flag("has_fragment_3"):
			_decor.draw_circle(CRATER, 4, Color(1, 0.2, 0.25, 0.6 + 0.3 * sin(_time * 6)))

	# Cracks splitting the ground around the crater while it charges and fires.
	if _charge_time > 0.0 or _beam_time > 0.0:
		var grow := 1.0 - _charge_time / CHARGE_LENGTH if _charge_time > 0.0 else 1.0
		for c in 7:
			var dir := Vector2.from_angle(c * TAU / 7 + 0.4)
			var points := PackedVector2Array([CRATER + dir * 10])
			for k in 4:
				points.append(points[-1] + dir.rotated(sin(c * 3.0 + k) * 0.6) * 9.0 * grow)
			_decor.draw_polyline(points, Color(0.08, 0.02, 0.02), 2.0)
			_decor.draw_polyline(points, Color(1, 0.2, 0.25, 0.5 * grow), 1.0)



## The buried fragment charging up and firing. While charging, the field goes dark,
## red light spirals down into the crater, a black-and-red orb swells out of it, and
## a thin aiming line flickers toward Elric. Then the blast: a huge beam with a black
## edge and a white-hot core, black lightning crawling along it, shockwaves pumping
## out of the crater, and a burst of shards where it hits.
func _draw_crater_blast() -> void:
	var red := Color(1.0, 0.12, 0.18)
	var black := Color(0.04, 0.0, 0.01)
	if _charge_time > 0.0:
		var charge := 1.0 - _charge_time / CHARGE_LENGTH
		# Everything else dims.
		_fx.draw_rect(Rect2(CRATER - Vector2(900, 700), Vector2(1800, 1400)), Color(0.05, 0.0, 0.02, 0.45 * charge))
		# Light spiraling in.
		for i in 18:
			var spin := _time * 3.0 + i * TAU / 18
			var dist := fmod(1.0 - _time * 0.9 - i * 0.13, 1.0) * 110.0
			var at := CRATER + Vector2.from_angle(spin + dist * 0.03) * dist
			_fx.draw_line(at, at + (CRATER - at).normalized() * 6.0, Color(red, charge), 2.0)
		# The swelling orb.
		var orb := 4.0 + 16.0 * charge + sin(_time * 30.0) * 1.5 * charge
		_fx.draw_circle(CRATER + Vector2(0, -6), orb * 2.2, Color(red, 0.18 * charge))
		_fx.draw_circle(CRATER + Vector2(0, -6), orb, black)
		_fx.draw_arc(CRATER + Vector2(0, -6), orb, 0, TAU, 24, red, 2.0)
		_fx.draw_circle(CRATER + Vector2(0, -6), orb * 0.3, Color(1, 0.7, 0.7))
		# The aiming line, locked onto Elric.
		if charge > 0.35 and int(_time * 18.0) % 2 == 0:
			_fx.draw_line(CRATER + Vector2(0, -6), player.position + Vector2(0, -16), Color(red, 0.7), 1.0)
			_fx.draw_arc(player.position + Vector2(0, -16), 10.0 - 4.0 * charge, 0, TAU, 16, Color(red, 0.8), 1.0)
	if _beam_time <= 0.0:
		return
	var age := BEAM_LENGTH - _beam_time
	var fade := clampf(_beam_time / 0.35, 0.0, 1.0)
	var from := CRATER + Vector2(0, -6)
	var to := _beam_target
	var dir := (to - from).normalized()
	var side := dir.orthogonal()
	# The beam swells in fast, then thins as it fades.
	var width := (1.0 - pow(1.0 - clampf(age / 0.08, 0.0, 1.0), 2.0)) * (1.0 + 0.15 * sin(age * 70.0)) * fade
	# Push past the target a little, so it looks like it goes THROUGH.
	var end := to + dir * 30.0
	_fx.draw_line(from, end, Color(red, 0.18), 46.0 * width)
	_fx.draw_line(from, end, black, 26.0 * width)
	_fx.draw_line(from, end, red, 16.0 * width)
	_fx.draw_line(from, end, Color(1, 0.75, 0.75), 6.0 * width)
	_fx.draw_line(from, end, Color(1, 1, 1), 2.0 * width)
	# Black lightning crawling up and down the beam.
	for b in 3:
		var points := PackedVector2Array()
		for k in 12:
			var along := from.lerp(end, k / 11.0)
			points.append(along + side * randf_range(-16.0, 16.0) * width)
		_fx.draw_polyline(points, Color(black, fade), 2.5)
		_fx.draw_polyline(points, Color(red, 0.6 * fade), 1.0)
	# Shockwave rings pumping out of the crater.
	for r in 3:
		var ring := fmod(age * 2.5 + r / 3.0, 1.0)
		_fx.draw_arc(from, 10.0 + ring * 70.0, 0, TAU, 32, Color(red, (1.0 - ring) * fade), 3.0)
	# The hit: a flash and shards flying off.
	_fx.draw_circle(to, 22.0 * width, Color(red, 0.4))
	_fx.draw_circle(to, 10.0 * width, Color(1, 1, 1, fade))
	for s in 10:
		var shard_dir := dir.rotated(randf_range(-1.3, 1.3))
		var at := to + shard_dir * (8.0 + age * 90.0 + s * 3.0)
		_fx.draw_line(at, at + shard_dir * 6.0, Color(red if s % 2 == 0 else black, fade), 2.0)


## The shockwave: a ring of force tears out of the crater, and everything it passes
## burns. The damage stays (see _blast_tiles).
func _shockwave() -> void:
	_shock_time = SHOCK_LENGTH
	Game.play_sfx("black_flash", 0.7)
	Game.play_sfx("shatter")
	shake(14.0, 1.0)
	await get_tree().create_timer(SHOCK_LENGTH * 0.35).timeout
	_blast_tiles()
	room.build()
	await get_tree().create_timer(SHOCK_LENGTH * 0.65 + 0.4).timeout


## The shockwave ring: a bright edge of force, a wall of dust and embers behind it.
func _draw_shockwave() -> void:
	if _shock_time <= 0.0:
		return
	var progress := 1.0 - _shock_time / SHOCK_LENGTH
	var radius := (1.0 - pow(1.0 - progress, 2.0)) * (BLAST_RADIUS + 3.0) * Room.TILE
	var fade := 1.0 - progress
	_fx.draw_circle(CRATER, radius, Color(1.0, 0.45, 0.2, 0.12 * fade))
	_fx.draw_arc(CRATER, radius, 0, TAU, 64, Color(0.35, 0.25, 0.2, 0.7 * fade), 26.0)
	_fx.draw_arc(CRATER, radius, 0, TAU, 64, Color(1.0, 0.6, 0.3, fade), 6.0)
	_fx.draw_arc(CRATER, radius, 0, TAU, 64, Color(1, 1, 0.9, fade), 2.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for k in 60:
		var dir := Vector2.from_angle(rng.randf() * TAU)
		var at := CRATER + dir * radius * rng.randf_range(0.7, 1.05)
		_fx.draw_rect(Rect2(at, Vector2(3, 3)), Color(1.0, 0.5, 0.2, fade) if k % 3 == 0 else Color(0.3, 0.25, 0.22, 0.8 * fade))


## Effects drawn on top of everyone: the Corps' lightning and fire, and the group hug zap.
func _draw_fx() -> void:
	_draw_crater_blast()
	_draw_shockwave()
	# NCWethan's lightning and Ronin's fire.
	if _lightning_time > 0.0 and hop and corps.has("NCWethan"):
		_draw_lightning(corps["NCWethan"].position + Vector2(0, -20), hop.position + Vector2(0, -16), _lightning_time)
	if _fire_time > 0.0 and hop and corps.has("Ronin"):
		_draw_fire(corps["Ronin"].position + Vector2(0, -18), hop.position + Vector2(0, -16), _fire_time)
	# Sparks where they hit.
	if _spark_time > 0.0 and hop:
		for i in 14:
			var dir := Vector2.from_angle(randf() * TAU)
			var color := Color(0.5, 0.85, 1.0) if i % 2 == 0 else Color(1.0, 0.55, 0.15)
			var from := hop.position + Vector2(0, -16) + dir * randf_range(6, 16)
			_fx.draw_line(from, from + dir * randf_range(6, 14), color, 2.0)
	# The group hug: little bolts crackling all over the huddle.
	if _hug_zap_time > 0.0:
		var fade := clampf(_hug_zap_time / 0.3, 0.0, 1.0)
		_fx.draw_circle(_hug_center, 46.0, Color(0.6, 0.9, 1.0, 0.18 * fade))
		for i in 12:
			var start := _hug_center + Vector2(randf_range(-36, 36), randf_range(-40, 4))
			var points := PackedVector2Array([start])
			for s in 3:
				points.append(points[-1] + Vector2(randf_range(-8, 8), randf_range(-9, 9)))
			_fx.draw_polyline(points, Color(0.6, 0.92, 1.0, fade), 3.0)
			_fx.draw_polyline(points, Color(1, 1, 1, fade), 1.0)


## A crackling bolt from `from` to `to`: a jagged line that re-forks every frame,
## with a cyan glow, a white-hot core, little side branches, and flashes at both ends.
func _draw_lightning(from: Vector2, to: Vector2, left: float) -> void:
	var fade := clampf(left / 0.3, 0.0, 1.0)
	var points := PackedVector2Array([from])
	var steps := 9
	var side := (to - from).orthogonal().normalized()
	for i in range(1, steps):
		var along := from.lerp(to, float(i) / steps)
		points.append(along + side * randf_range(-11.0, 11.0))
	points.append(to)
	var cyan := Color(0.45, 0.85, 1.0)
	_fx.draw_polyline(points, Color(cyan, 0.3 * fade), 14.0)
	_fx.draw_polyline(points, Color(cyan, fade), 5.0)
	_fx.draw_polyline(points, Color(1, 1, 1, fade), 2.0)
	# Branches that fork off and fizzle.
	for i in range(2, steps - 1, 2):
		var start := points[i]
		var branch := start + (to - from).normalized().rotated(randf_range(-1.2, 1.2)) * randf_range(10, 22)
		_fx.draw_line(start, branch, Color(cyan, 0.8 * fade), 1.5)
	for end in [from, to]:
		_fx.draw_circle(end, 7.0 + randf() * 4.0, Color(cyan, 0.35 * fade))
		_fx.draw_circle(end, 3.0, Color(1, 1, 1, fade))


## A roaring stream of fire from `from` to `to`: flame blobs racing along a wavy
## path, big and yellow near Ronin, smaller and redder as they fly, bursting on impact.
func _draw_fire(from: Vector2, to: Vector2, left: float) -> void:
	var fade := clampf(left / 0.3, 0.0, 1.0)
	var side := (to - from).orthogonal().normalized()
	for k in 22:
		var t := fmod(_time * 1.8 + k / 22.0, 1.0)
		var wobble := sin(t * 9.0 + k) * 7.0 * sin(t * PI)
		var at := from.lerp(to, t) + side * wobble
		var size := lerpf(7.0, 3.0, t) + (k % 3)
		var color := Color(1.0, 0.9, 0.3).lerp(Color(1.0, 0.25, 0.1), t)
		_fx.draw_circle(at, size * 1.8, Color(color, 0.25 * fade))
		_fx.draw_circle(at, size, Color(color, 0.9 * fade))
	# Flames licking up off the target.
	for k in 8:
		var flick := fmod(_time * 3.0 + k * 0.125, 1.0)
		var at := to + Vector2((k - 3.5) * 4.0, -flick * 22.0)
		_fx.draw_circle(at, 4.0 * (1.0 - flick), Color(1.0, 0.5 + 0.4 * (1.0 - flick), 0.15, 0.8 * fade))


## A sprinkler head in the middle of a corner of the field, sweeping a fan of
## water back and forth, with a faint mist over the whole corner.
func _draw_sprinkler(area: Rect2) -> void:
	_decor.draw_rect(area, Color(0.55, 0.75, 1.0, 0.12))
	var head := area.get_center()
	_decor.draw_circle(head, 3, Color8(90, 90, 96))
	var sweep := sin(_time * 1.6) * 1.4
	for i in 7:
		var angle := -PI / 2 + sweep + (i - 3) * 0.12
		for d in 6:
			var reach := fmod(_time * 90.0 + d * 22.0 + i * 7.0, 130.0)
			var drop := head + Vector2.from_angle(angle) * reach + Vector2(0, reach * reach * 0.004)
			if area.has_point(drop):
				_decor.draw_rect(Rect2(drop, Vector2(2, 2)), Color(0.75, 0.9, 1.0, 0.85 - reach / 160.0))


func _quadrant(corner: String) -> Rect2:
	var west := corner.ends_with("W")
	var north := corner.begins_with("N")
	var left := FIELD_RECT.position.x if west else CRATER.x
	var right := CRATER.x if west else FIELD_RECT.end.x
	var top := FIELD_RECT.position.y if north else CRATER.y
	var bottom := CRATER.y if north else FIELD_RECT.end.y
	return Rect2(left, top, right - left, bottom - top)


func _sprinkler_on(corner: String) -> bool:
	# (The blast wrecked them all.)
	return not _blasted and not flag("sprinkler_off_" + corner)


## True if Elric is standing in a corner of the field that's being sprayed.
func _in_spray() -> bool:
	if flag("hp_erupted"):
		return false
	for corner in SPRINKLERS:
		if _sprinkler_on(corner) and _quadrant(corner).has_point(player.position):
			return true
	return false


## Walked into the water: get pushed back out.
func _soaked() -> void:
	Game.play_sfx("miss")
	var back := _dry_spot - player.position
	await push_player((back.normalized() if back.length() > 0.1 else Vector2.DOWN) * 26.0)
	# Only the first couple of soakings get any comment.
	var times := int(Game.flags.get("hp_soaked", 0))
	Game.flags["hp_soaked"] = times + 1
	if times == 0:
		await Game.dialogue.say([
			"* (Sprinkler water blasts you in the face.)",
			{"who": "Hop", "text": "BLEGH. Who runs sprinklers at night?!", "mood": "angry"},
			{"who": "Hop", "text": "...Revolution practically lives out here.\nThey've gotta have a way to shut these off.", "mood": "sad"},
		])
	elif times == 1:
		await Game.dialogue.say(["* (Still wet. Still sprinkling.)"])


## The control box: four switches, one for each corner of the field.
func _control_box() -> void:
	if flag("hp_erupted"):
		await Game.dialogue.say(["* (The sprinkler control box. Nobody needs it now.)"])
		return
	if not flag("hp_box_seen"):
		Game.flags["hp_box_seen"] = true
		await Game.dialogue.say([
			"* (A sprinkler control box. The lid is unlocked.)",
			"* (Four switches inside, each with a faded label.)",
		])
	while true:
		var states: Array[String] = []
		for corner in SPRINKLERS:
			states.append("%s %s" % [corner, "ON" if _sprinkler_on(corner) else "off"])
		var choice := await Game.dialogue.ask("* (" + "    ".join(states) + ")\n* (Flip which switch?)", SPRINKLERS + ["Leave"])
		if choice >= SPRINKLERS.size():
			return
		var corner: String = SPRINKLERS[choice]
		var turning_off := _sprinkler_on(corner)
		Game.flags["sprinkler_off_" + corner] = turning_off
		Game.play_sfx("select")
		await Game.dialogue.say(["* (Click. Out on the field, a sprinkler %s.)" % ("hisses and stops" if turning_off else "sputters back on")])


# --- People -----------------------------------------------------------------

## Chapter 2: daytime at the park, after the Corps' base.
func _day() -> bool:
	return Game.daytime()


func _place_people() -> void:
	if _day():
		# Whoever's coming along follows Elric. (The Corps is down in the base.)
		# Going their own way, Elric is alone until they go down there.
		hop = Cast.make(Game.partner())
		add_character(hop, player.position + Vector2(-20, -4))
		hop.follow = player
		if Game.walking_alone():
			hop.queue_free()
		world.add_child(Hotspot.create(HATCH, _go_down_hatch))
		var star := make_save_star()
		star.glow = true
		star.glow_color = Color(1.0, 1.0, 1.0, 0.55)
		star.on_interact = _use_save_point
		add_storage_box(Vector2(322, 500))
		add_character(star, Vector2(360, 500))
		add_person("dogwalker", DOG_WALKER, SCENE, "talk_later")
		return
	hop = Cast.make("Hop")
	add_character(hop, player.position + Vector2(-20, -4))

	if flag("chapter1_done"):
		# After the chapter: Hop is with the Corps unless Elric went with him.
		hop.position = Vector2(150, 140) if Game.flags.get("route") != "genocide" else player.position + Vector2(-20, -4)
		if Game.flags.get("route") == "genocide":
			hop.follow = player
		hop.on_interact = _talk_to_hop_after
		hop.add_to_group("interactable")
		return

	# Someone walking their dog, at the edge of the park (until the field erupts).
	if not flag("hp_erupted"):
		add_person("dogwalker", DOG_WALKER, SCENE)

	if flag("hp_erupted") and not flag("has_fragment_3"):
		# Coming back from the Hopkuna fight: he's still standing over the crater.
		hop.set_look("Hopkuna")
		hop.position = CRATER + Vector2(0, 30)
	else:
		hop.follow = player

	var star := make_save_star()
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
	if await handle_person_return():
		return
	if Game.battle_result.get("id", "") == "hopkuna":
		await run_cutscene(_corps_arrives)
	elif not flag("hp_arrived"):
		await run_cutscene(_arrival)
	elif flag("morning_after") and not flag("seen_morning"):
		await run_cutscene(_morning)


func _physics_process(_delta: float) -> void:
	if is_blocked() or flag("chapter1_done"):
		if flag("chapter1_done") and not is_blocked() and player.position.y > 555:
			run_cutscene(_leave_after_chapter)
		elif flag("chapter1_done") and not is_blocked():
			check_random_encounter(SCENE)
		return
	if _in_spray():
		run_cutscene(_soaked)
		return
	_dry_spot = player.position
	if not flag("hp_erupted") and player.position.distance_to(CRATER) < ERUPT_DISTANCE:
		run_cutscene(_eruption)
	elif player.position.y > 555:
		run_cutscene(_not_leaving)


func _arrival() -> void:
	await Game.dialogue.say([
		"* (Westview Field. The big field is dark and empty.)",
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
		Game.restored_line(),
	])
	var choice := await Game.dialogue.ask("* (Save your progress?)", ["Save", "Return"])
	if choice == 0:
		Game.save_game(SCENE, player.position)
		Game.play_sfx("save")
		await Game.dialogue.say(Game.saved_lines())


# --- The eruption -----------------------------------------------------------

func _eruption() -> void:
	Game.flags["hp_erupted"] = true
	# The eruption takes over the music from here.
	forget_fragment_music()
	if _crater_marker:
		_crater_marker.queue_free()
		_crater_marker = null
	Game.stop_music(1.0)
	hop.follow = null
	await Game.dialogue.say([
		"* (The ground in the middle of the field is shaking.)",
		{"who": "Hop", "text": "Uh. Elric?", "mood": "shocked"},
	])
	# The fragment charges up, aiming right at Elric.
	Game.play_sfx("fragment")
	_charge_time = CHARGE_LENGTH
	shake(2.0, CHARGE_LENGTH)
	await get_tree().create_timer(0.9).timeout
	Game.play_sfx("alert")
	shake(4.0, 0.7)
	await get_tree().create_timer(0.7).timeout
	_charge_time = 0.05
	_charge_hold = true

	# The fragment fires at Elric... and Hop jumps in the way.
	await Game.dialogue.say([{"who": "Hop", "text": "ELRIC, MOVE!!", "mood": "shocked"}])
	var between := player.position.lerp(CRATER, 0.35)
	await hop.walk_to(between, 320.0)
	_charge_hold = false
	_charge_time = 0.0
	_beam_target = hop.position + Vector2(0, -16)
	_beam_time = BEAM_LENGTH
	Game.play_sfx("black_flash")
	Game.play_sfx("hurt")
	shake(12.0, 0.9)
	await _flash(Color(1.0, 0.35, 0.4), 0.15)
	hop.lie_down()
	await get_tree().create_timer(0.6).timeout
	await _shockwave()

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
	])
	await Game.dialogue.say(_reset_lines())
	# He'll remember this, even if you go back.
	Game.met_hopkuna = true
	Game.save_settings()
	await Game.dialogue.say([
		{"who": "Hopkuna", "text": "He was always so careful.\nOnly let me out when he had no other choice."},
		{"who": "Hopkuna", "text": "The last time was years ago. Right here,\non this field. He had a friend back then, too."},
		{"who": "Hopkuna", "text": "...Hm. You have the same look.\nNowhere to go, and walking anyway."},
		{"who": "Hopkuna", "text": "I know that look.\nI killed the last one who had it."},
		"* (Something in the fragments goes cold.)",
		{"who": "Hopkuna", "text": "Tonight, he had no other choice. Thanks to you."},
		{"who": "Hopkuna", "text": "And look. You've been carrying two of my\nfragments for me. How thoughtful."},
		{"who": "Hopkuna", "text": "Hand them over."},
		{"who": "Elric", "choices": ["...No.", "Never."], "mood": "angry"},
		{"who": "Hopkuna", "text": "Then I'll take them."},
	])
	await Game.start_battle("hopkuna", SCENE, player.position)


## Hopkuna has DETERMINATION too. If you've ever RESET, he knows. (Nothing at all
## if you never have.)
func _reset_lines() -> Array:
	if Game.resets == 0:
		return []
	if not Game.met_hopkuna:
		# You reset before ever reaching him. He can't quite place it.
		return [
			{"who": "Hopkuna", "text": "...Hm."},
			{"who": "Hopkuna", "text": "Strange. This feels... familiar.\nLike I've waited for this moment before."},
			{"who": "Hopkuna", "text": "No... not me. YOU.\nYou went back, didn't you?"},
			{"who": "Hopkuna", "text": "Interesting."},
		]
	var lines: Array = [
		"* (Hopkuna tilts his head. He's studying you.)",
		{"who": "Hopkuna", "text": "...Oh. It's you again."},
		{"who": "Hopkuna", "text": "Don't give me that look. You RESET.\nI felt it."},
		{"who": "Hopkuna", "text": "Everything rolled back. The road. The city.\nThat little club. They all forgot."},
		{"who": "Hopkuna", "text": "Everyone except me."},
		{"who": "Hopkuna", "text": "You're not the only one with DETERMINATION,\nlittle wanderer."},
	]
	if Game.resets > 1:
		lines.append({"who": "Hopkuna", "text": "That's %d times now. I've been counting." % Game.resets})
	lines.append({"who": "Hopkuna", "text": "Go back as many times as you like.\nThe ending doesn't change."})
	return lines


## Where a Corps member stands: thirteen even spots on a ring around Hopkuna, one
## for each of the twelve of them and one for Elric (wherever Elric already is).
func _corps_spot(who: String) -> Vector2:
	var elric_angle := (player.position - hop.position).angle()
	var slot := CORPS.find(who) + 1
	return hop.position + Vector2.from_angle(elric_angle + slot * TAU / (CORPS.size() + 1)) * CORPS_RING


## Flashes the whole screen a color for a moment.
func _flash(color: Color, time: float) -> void:
	var before := _night.color
	# (Gentler, and slower to fade, with Reduce flashing on.)
	if Game.reduce_flashing():
		time *= 2.0
	_night.color = color * (1.2 if Game.reduce_flashing() else 2.0)
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
		member.walk_to(_corps_spot(who), 220.0)
	await get_tree().create_timer(1.6).timeout
	for member in arrivals:
		member.face(hop.position - member.position)

	await Game.dialogue.say([
		{"who": "BigJoe6", "text": "Get AWAY from them, Hopkuna!", "mood": "angry"},
		{"who": "Eggo", "text": "...hop. dude.", "mood": "sad"},
		{"who": "Hopkuna", "text": "Oh, look. The little club showed up."},
		{"who": "Rooster", "text": "Nice tattoos. Did you lose a fight with a Sharpie?", "mood": "smug"},
		{"who": "Hopkuna", "text": "..."},
		{"who": "MuffinMage", "text": "Let him go. I'm not asking twice.", "mood": "angry"},
		{"who": "Sansworth", "text": "I don't have a car.\nBut if I did, I'd run you over with it.", "mood": "angry"},
		{"who": "Agent", "text": "Thirteen of us. One of you. Do the math.", "mood": "smug"},
		{"who": "Supreme", "text": "Twelve. Elric can barely stand.", "mood": "shocked"},
		{"who": "Agent", "text": "Thirteen. Keep up."},
		{"who": "NCWethan", "text": "LIGHTNING TIME!!!", "mood": "happy"},
	])
	# NCWethan's lightning arcs into Hopkuna...
	_lightning_time = 1.3
	Game.play_sfx("zap")
	shake(4.0, 0.5)
	await get_tree().create_timer(0.35).timeout
	Game.play_sfx("zap", 1.3)
	await get_tree().create_timer(1.0).timeout
	await Game.dialogue.say([{"who": "Ronin", "text": "FIRE TIME!!!", "mood": "angry"}])
	# ...then Ronin's fire roars in...
	_fire_time = 1.3
	Game.play_sfx("shatter")
	shake(4.0, 0.6)
	await get_tree().create_timer(1.3).timeout
	# ...and then both at once.
	await Game.dialogue.say([{"who": "NCWethan", "text": "TOGETHER!!!", "mood": "happy"}])
	_lightning_time = 1.4
	_fire_time = 1.4
	_spark_time = 1.4
	Game.play_sfx("hit")
	Game.play_sfx("zap", 0.8)
	shake(8.0, 1.0)
	await get_tree().create_timer(1.4).timeout
	await Game.dialogue.say([
		"* (A storm of sparks and flame slams into Hopkuna.)",
		"* (For an instant, something behind his eyes flinches\n*  from the fire. It isn't Hopkuna.)",
		"* (He barely moves. But he isn't smiling anymore.)",
		{"who": "Supreme", "text": "Statistically, we can't beat him.\nBut we can make him want to leave.", "mood": "shocked"},
		{"who": "Agent", "text": "He's stalling. He wants the fragments, not a fight.\nElric. Whatever happens, don't let go of them."},
		{"who": "Nat", "text": "Elric. Hop's still in there.\nTalk to him."},
		{"who": "Elric", "choices": ["...Hop.", "Hop. Listen to me."]},
		{"who": "Elric", "choices": ["You jumped in front of that for me.", "You took that hit so I wouldn't have to."]},
		{"who": "Elric", "choices": ["Come back.", "We need you. Come back."]},
		"* (Hopkuna's hand starts to shake.)",
		{"who": "Hopkuna", "text": "...Tch. Sentimental."},
		{"who": "Hopkuna", "text": "Keep him, then. For now."},
		{"who": "Hopkuna", "text": "Three fragments, little wanderer.\nNine to go."},
		{"who": "Hopkuna", "text": "I can wait.\nI'm very, very good at waiting."},
	])
	if Game.resets > 0:
		await Game.dialogue.say([{"who": "Hopkuna", "text": "Even if you go back and do this all again."}])

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
		{"who": "Hop", "text": "The last time I let him out, I lost somebody.\nI swore it would never happen again.", "mood": "sad"},
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
	# No route names here: the player should pick what Elric would want,
	# not what they know will happen.
	var options := ["Go with Hop.", "Go my own way.", "Join the REVOLUTION Corps."]
	var routes := ["genocide", "neutral", "pacifist"]
	var picked := -1
	while picked < 0:
		var choice := await Game.dialogue.ask("* (What do you want to do?)", options)
		var sure := await Game.dialogue.ask("* (Are you sure? You can't take this back.)", ["Yes", "No"])
		if sure == 0:
			picked = choice

	var route: String = routes[picked]
	# (Going with Hop isn't the Genocide route yet: nothing says so. It starts on
	# the way to his house, with the glowbug. Until then, the route is "with_hop".)
	Game.flags["route"] = route if route != "genocide" else "with_hop"
	# (chapter1_done: the choice has been made. There are no chapters; the story
	# just goes on, and where it goes next depends on the choice.)
	match route:
		"pacifist":
			# Joining the Corps closes off the other two paths.
			Game.flags["genocide_locked"] = true
			Game.flags["neutral_locked"] = true
			await _ending_pacifist()
			Game.flags["chapter1_done"] = true
			# Straight down the hatch into the Corps' base.
			Game.save_game(CORPS_BASE_SCENE, BASE_LADDER)
			await Game.change_scene(CORPS_BASE_SCENE, BASE_LADDER)
		"neutral":
			# The Corps' offer stays open; going with Hop does not.
			Game.flags["genocide_locked"] = true
			await _ending_neutral()
			Game.flags["chapter1_done"] = true
			# Elric wanders the city all night, and ends up back here by morning.
			Game.flags["morning_after"] = true
			Game.save_game(SCENE, MORNING_SPOT)
			await Game.change_scene(SCENE, MORNING_SPOT)
		"genocide":
			Game.flags["pacifist_locked"] = true
			Game.flags["neutral_locked"] = true
			await _ending_genocide()
			Game.flags["chapter1_done"] = true
			# Back to Hop's place for the night.
			Game.save_game(HOP_HOUSE_SCENE, Vector2(40, 290))
			await Game.change_scene(HOP_HOUSE_SCENE, Vector2(40, 290))


func _ending_pacifist() -> void:
	await Game.dialogue.say([
		{"who": "Elric", "choices": ["...I'm in.", "Count me in."]},
		{"who": "BigJoe6", "text": "Then welcome to the REVOLUTION Corps.", "mood": "happy"},
		{"who": "Eggo", "text": "membership: a lot more than two now.", "mood": "happy"},
		{"who": "NCWethan", "text": "GROUP HUG!!!", "mood": "happy"},
	])
	await _group_hug()
	await Game.dialogue.say([
		"* (N.C. Wethan hugs everyone at once.\n*  There is a small electrical shock.)",
		{"who": "Rooster", "text": "...My hair is standing up. My HAIR.", "mood": "angry"},
		{"who": "Hop", "text": "...You'd still want me around?\nAfter all that?", "mood": "sad"},
		{"who": "Elric", "choices": ["...You saved me. We'll save you.", "...Of course we would."]},
		{"who": "Hop", "text": "...Okay. Okay.", "mood": "happy"},
		"* (Hop laughs, and wipes his eyes,\n*  and doesn't say anything else for a while.)",
		{"who": "Nat", "text": "If the fragments are destroyed, Hopkuna can never\nfully wake up. That's our job now."},
		{"who": "Agent", "text": "Good. You're smarter than you look.\n...That's a compliment. Take it.", "mood": "smug"},
		{"who": "Nassan", "text": "Nine fragments left. Let's find them before he does."},
		"* (Big Joe hauls open a hatch hidden under\n*  the picnic shelter.)",
		"* (One by one, the Corps climbs down.\n*  Hop waits for you at the top of the ladder.)",
	])


## NCWethan yanks everyone into one big huddle around him, zaps them all, and
## they bounce back to where they were standing.
func _group_hug() -> void:
	var center: Vector2 = corps["NCWethan"].position if corps.has("NCWethan") else player.position
	var people: Array[Node2D] = [player, hop]
	for who in corps:
		if who != "NCWethan":
			people.append(corps[who])
	var home: Array[Vector2] = []
	var pull := create_tween().set_parallel()
	for i in people.size():
		home.append(people[i].position)
		var spot := center + Vector2.from_angle(i * TAU / people.size()) * Vector2(24, 12)
		pull.tween_property(people[i], "position", spot, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await pull.finished
	_hug_center = center
	_hug_zap_time = 0.9
	Game.play_sfx("zap")
	shake(3.0, 0.5)
	await get_tree().create_timer(0.3).timeout
	Game.play_sfx("zap", 1.4)
	await get_tree().create_timer(0.6).timeout
	var release := create_tween().set_parallel()
	for i in people.size():
		release.tween_property(people[i], "position", home[i], 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await release.finished


## Going their own way: Elric wanders all night, and ends up back here anyway.
func _morning() -> void:
	Game.flags["seen_morning"] = true
	await Game.dialogue.say([
		"* (You wander the city all night.)",
		"* (Down streets you don't know.\n*  Past shops with their lights off.)",
		"* (By morning, your feet bring you back to\n*  Westview Field anyway.)",
		"* (The Corps' hatch is right there, by the shelter.\n*  Nobody's watching it.)",
	])
	Game.set_objective("Go anywhere. (The Corps' hatch is by the shelter.)")


func _ending_neutral() -> void:
	await Game.dialogue.say([
		{"who": "Elric", "choices": ["...I need to think. On my own.", "...Not yet. I need some time."]},
		{"who": "Nassan", "text": "I understand. The offer stands.\nWhenever you're ready, you know where we are.", "mood": "sad"},
		{"who": "BigJoe6", "text": "...Just don't make us regret letting you walk.", "mood": "angry"},
		{"who": "Hop", "text": "Take care of yourself, mysterious traveler.", "mood": "sad"},
		{"who": "Hop", "text": "We'll keep an eye on each other. Me and them.", "mood": "sad"},
		"* (You walk away from Westview Field alone.)",
		"* (Behind you, the Corps gathers around Hop.)",
	])


func _ending_genocide() -> void:
	await Game.dialogue.say([
		{"who": "Elric", "choices": ["...I'm going with Hop.", "...Hop's coming with me."]},
		{"who": "BigJoe6", "text": "...What?", "mood": "shocked"},
		{"who": "Eggo", "text": "elric. no.", "mood": "sad"},
		{"who": "Supreme", "text": "That's... that's the worst possible outcome.", "mood": "shocked"},
		{"who": "Agent", "text": "Bad call. You'll figure that out. Probably too late.", "mood": "angry"},
		{"who": "Hop", "text": "Elric, don't. You don't know what he'll-", "mood": "shocked"},
		{"who": "BigJoe6", "text": "Then you're no friend of Revolution.\nGET OUT.", "mood": "angry"},
		"* (The Corps forms a wall between you and the park.)",
		"* (Hop looks back at them. Then at you.)",
		{"who": "Hop", "text": "...I'm sorry, guys.", "mood": "sad"},
		"* (You and Hop walk into the dark.)",
	])


## Talking to Hop after Chapter 1 is over. What he says depends on the choice Elric made.
func _talk_to_hop_after() -> void:
	hop.face(player.position - hop.position)
	match Game.flags.get("route", "neutral"):
		"pacifist":
			await chat("hop_after", [
				{"who": "Hop", "text": "Hey, partner. ...Is that weird? Partner?\nI'm trying it out.", "mood": "happy"},
				{"who": "Hop", "text": "Nassan made me a schedule. For ME.\nIt's color-coded. I'm in purple. I think it means \"danger.\"", "mood": "smug"},
				{"who": "Hop", "text": "...Thanks for not running.", "mood": "sad"},
				{"who": "Hop", "text": "Nine fragments left. Whenever you're ready,\nI'm ready. Probably. Mostly.", "mood": "happy"},
			], [
				[{"who": "Hop", "text": "N.C. Wethan says the zap was \"bonding.\"\nMy left arm is still buzzing.", "mood": "shocked"}],
				[{"who": "Hop", "text": "If he ever comes back out... you'll stop me. Right?", "mood": "sad"}, {"who": "Elric", "choices": ["...Right.", "...I promise."]}, {"who": "Hop", "text": "...Okay. Good.", "mood": "happy"}],
				[{"who": "Hop", "text": "Agent says I'm \"statistically a liability.\"\nSupreme says Agent's math is wrong. They're still arguing.", "mood": "smug"}],
			])
		"genocide":
			await chat("hop_after", [
				{"who": "Hop", "text": "...So. Where are we going, Elric?", "mood": "sad"},
				{"who": "Hop", "text": "They looked at me like I was him.\nMaybe they're right.", "mood": "sad"},
				{"who": "Hopkuna", "tag": "???", "face": false, "text": "They are."},
				{"who": "Hop", "text": "...Did you hear that? ...No? Okay.", "mood": "shocked"},
			], [
				[{"who": "Hop", "text": "I'll follow you. Wherever. That's the deal, right?", "mood": "sad"}],
				[{"who": "Hop", "text": "My head's been really loud since the field.", "mood": "sad"}],
			])
		_:
			await chat("hop_after", [
				{"who": "Hop", "text": "You came back. ...To think, or to stay?", "mood": "sad"},
				{"who": "Hop", "text": "The Corps' offer is still open, you know.\nNassan wrote it down. In pen. That's serious, for him."},
				{"who": "Hop", "text": "No pressure, mysterious traveler.\nI'll be here.", "mood": "happy"},
			], [
				[{"who": "Hop", "text": "Still thinking? That's okay. I think too.\nMostly about tacos.", "mood": "smug"}],
				[{"who": "Hop", "text": "Whatever you decide... thanks. For before.", "mood": "sad"}],
			])


func _leave_after_chapter() -> void:
	if _day():
		# Back to Westview, in through the gym's emergency exit.
		await Game.change_scene(WESTVIEW_SCENE, Vector2(116 * 20, 42 * 20 + 10))
		return
	await Game.change_scene(DEMO_END_SCENE)


## The tent stakes. In Chapter 1, Hop is right there, and doesn't want to talk about it.
func _tent_stakes() -> void:
	var lines: Array = [
		"* (Two old tent stakes, half buried in the grass.)",
		"* (They're blackened. Like they've been through a fire.)",
	]
	if not flag("hp_erupted") and not _day():
		lines.append({"who": "Hop", "text": "...Leave those.", "mood": "sad"})
		lines.append({"who": "Hop", "text": "Probably from somebody's campout.\nA long time ago.", "mood": "sad"})
	else:
		lines.append("* (Someone camped here, once.)")
	await Game.dialogue.say(lines)


func _go_down_hatch() -> void:
	var choice := await Game.dialogue.ask("* (The hatch to the Corps' base.\n*  Climb down?)", ["Climb down", "Stay"])
	if choice == 0:
		Game.play_sfx("door")
		await Game.change_scene(CORPS_BASE_SCENE, Vector2(20 * 20, 5 * 20))
