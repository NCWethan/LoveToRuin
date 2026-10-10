class_name Collection
extends RefCounted
## Relic's lost collection: the things Relic picked up and kept that summer. Every
## one of them is somebody's pain. (Old Town is where Elric finds that out; from
## then on, they turn up around the city, glinting green.)
##
## Each belongs to a townsperson. Give it back, and their pain comes back with it:
## all of it, at once. Elric stays and sits with them (a little BOND). Or keep it,
## and carry it like Relic did: Elric's max HP drops a little for good (the
## backpack gets heavier). With Hop, Relic just keeps them.
##
## The Pigeon Man's feather (Old Town's KEEPSAKE) is the first; see area.gd.
## Flags: kc_<id> = "found", "returned" or "kept".

## id -> {name, scene, offset from the scene's ENTRY, owner (townsfolk id),
##        find (lines when Elric picks it up), back (the owner, getting it back)}
const ITEMS := {
	"key": {
		"name": "Rusted House Key", "scene": "res://scenes/burned_hills.tscn", "offset": Vector2(-50, -10), "owner": "coach",
		"find": ["* (In the ash by the trailhead: a rusted house key,\n*  on a ring with a little whistle charm.)", "* (The house it opened isn't there anymore.)"],
		"back": ["* Coach: \"...My house key. The old house.\"", "* \"It burned. Five years ago. The fire on the hill.\n*  I keep losing my keys. Every set, every week.\"", "* \"I always thought I was just careless.\n*  I wasn't. I was trying not to have that one.\"", "* (He holds it a long time. He doesn't yell.\n*  For once, Coach Ramirez doesn't yell at all.)"],
	},
	"transfer": {
		"name": "Bus Transfer", "scene": "res://scenes/downtown.tscn", "offset": Vector2(-50, 10), "owner": "waiting",
		"find": ["* (By the trolley stop: a faded bus transfer,\n*  good for one ride, home. It expired years ago.)"],
		"back": ["* Waiting Ghost: \"...My transfer. I thought I lost it.\"", "* \"I was waiting for the bus home. That night.\n*  It never came. I never stopped waiting.\"", "* \"I don't think I'm waiting for a bus.\"", "* (The ghost smiles, very faintly, and walks away\n*  down the road. Not waiting anymore.\n*  Going home.)"],
	},
	"compass": {
		"name": "Cracked Compass", "scene": "res://scenes/torrey_pines.tscn", "offset": Vector2(-50, -10), "owner": "sailor",
		"find": ["* (On the trail: a brass compass with a cracked face.\n*  The needle still points north. Mostly.)"],
		"back": ["* Old Sailor: \"...That's off the Mary Ellen. My old boat.\"", "* \"Went down off the point, twenty years back.\n*  My mate didn't come up. I stopped telling\n*  that story. I tell the squid one instead.\"", "* \"...Thanks, lad. It's heavy. It should be.\""],
	},
	"knight": {
		"name": "White Knight", "scene": "res://scenes/old_town.tscn", "offset": Vector2(-50, 10), "owner": "statue",
		"find": ["* (By the plaza: a white knight from a chess set,\n*  worn smooth by somebody's thumb.)"],
		"back": ["* (The Living Statue moves. Fast, this time.\n*  He takes the chess piece.)", "* Living Statue: \"My dad's. He played chess in the plaza\n*  every day. He could sit still for hours.\"", "* \"That's why I do this. I didn't know that\n*  until right now.\"", "* (He stands very still, holding it.\n*  It's different from how he usually stands still.)"],
	},
	"ticket": {
		"name": "Ticket Stub", "scene": "res://scenes/mission_beach.tscn", "offset": Vector2(-60, 0), "owner": "superfan",
		"find": ["* (Under the boardwalk: a ticket stub from a ball game.\n*  Two seats, side by side. Section 112.)"],
		"back": ["* Superfan: \"...Section 112. That's my seat.\n*  That was my mom's seat. Next to mine.\"", "* \"Last game we went to together. We lost.\n*  She laughed the whole way home anyway.\"", "* (He doesn't cheer. He doesn't need to.)"],
	},
	"ribbon": {
		"name": "Hair Ribbon", "scene": "res://scenes/balboa_park.tscn", "offset": Vector2(-60, 10), "owner": "rosa",
		"find": ["* (Caught on a bench by the Prado: a red hair\n*  ribbon, the kind a little girl would wear.)"],
		"back": ["* Doña Rosa: \"...¡Ay! Mi Lucía's ribbon.\"", "* \"My daughter. She moved to Texas, ten years ago.\n*  She doesn't call. I stopped calling too.\"", "* \"...I should call her. Right? I should call her.\"", "* (Her hands are shaking. She keeps them\n*  very busy with the tortillas.)"],
	},
	"dogtag": {
		"name": "Dog Tag", "scene": "res://scenes/junkyard.tscn", "offset": Vector2(-50, -10), "owner": "dogwalker",
		"find": ["* (In a pile of hubcaps: a little dog tag.\n*  It says PEANUT. There's a phone number.)"],
		"back": ["* Dog Walker: \"Peanut. Oh, Peanut.\"", "* \"My first dog. She got out one night. The night\n*  of the fire. I never found her.\"", "* \"I walk six dogs now. I never thought about why.\"", "* (All six dogs sit down around her feet,\n*  very quietly.)"],
	},
	"postcard": {
		"name": "Postcard", "scene": "res://scenes/pq_mall.tscn", "offset": Vector2(60, -10), "owner": "tourist",
		"find": ["* (By the curb: a postcard of the ocean.\n*  \"Wish you were here. -Grandma\")"],
		"back": ["* Tourist: \"...Grandma's postcard. She sent it from\n*  HERE. She always wanted to take me to the ocean.\"", "* \"She didn't get to. So I came by myself.\n*  I've been taking pictures for her.\"", "* (The Tourist puts the camera down,\n*  and just looks at the water.)"],
	},
	"badge": {
		"name": "Firefighter's Badge", "scene": "res://scenes/harbor.tscn", "offset": Vector2(-50, 0), "owner": "firefighter",
		"find": ["* (On the pier: a firefighter's badge, scorched\n*  at one corner. Not the dalmatian's. Someone else's.)"],
		"back": ["* Firefighter: \"...That's Reyes's badge. My partner.\n*  He was on the line with me. That night.\"", "* \"He didn't make it off the hill.\n*  I plant a tree for every one that burned.\"", "* \"I never planted one for him. I couldn't.\"", "* \"...I'm gonna plant one for him. Today.\""],
	},
}


static func state(id: String) -> String:
	return str(Game.flags.get("kc_" + id, ""))


## Is the collection open yet? (Old Town, where Elric finds out what it is.)
static func open() -> bool:
	return Game.flags.get("ot_fragment", false)


## The items lying around in this scene, waiting to be found.
static func waiting_in(scene_path: String) -> Array:
	var ids: Array = []
	if not open():
		return ids
	for id in ITEMS:
		if ITEMS[id]["scene"] == scene_path and state(id) == "":
			ids.append(id)
	return ids


## Something Elric is carrying that belongs to this townsperson.
static func carried_for(owner: String) -> String:
	if Game.on_genocide_route():
		return ""
	for id in ITEMS:
		if ITEMS[id]["owner"] == owner and state(id) == "found":
			return id
	return ""


## How many Elric has kept (each one: 2 less max HP, for good).
static func kept_count() -> int:
	var n := 0
	for id in ITEMS:
		if state(id) == "kept":
			n += 1
	if Game.flags.get("has_feather", false) and not Game.flags.get("feather_returned", false) and Game.flags.get("feather_kept", false):
		n += 1
	return n


static func returned_count() -> int:
	var n := 0
	for id in ITEMS:
		if state(id) == "returned":
			n += 1
	if Game.flags.get("feather_returned", false):
		n += 1
	return n
