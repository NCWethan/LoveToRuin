class_name Items
extends RefCounted
## Descriptions for every item, shown when you CHECK an item in your bag.
## Food is simple: {"name": "Trail Mix", "heal": 15}.
## Accessories have a slot and stats instead:
##   {"name": "Nail File", "heal": 0, "slot": "weapon", "atk": 2, "def": 0}

const DESCRIPTIONS := {
	"Trail Mix": "Nuts, raisins, and the occasional chocolate candy.",
	"Soda": "Fizzy, sugary, and a little flat.",
	"Granola Bar": "Crunchy. Crumbly. Somehow gets everywhere.",
	"Deli Sandwich": "Turkey and cheese, with a pickle on the side.",
	"Two Tacos": "Cheap, mysterious, and strangely comforting.",
	"Curly Fries": "Perfectly seasoned spirals.",
	"Burger": "A classic. Can't go wrong.",
	"Fish & Chips": "Crispy fish, crispy fries.",
	"Salmon Burger": "MuffinMage's favorite. Changes lives.",
	"Salmon Burger (Cold)": "Still pretty good, honestly.",
	# Accessories.
	"Nail File": "Keeps your nails sharp. Very sharp.",
	"Hoodie": "Soft, warm, and surprisingly hard to hit through.",
	"Sneakers": "Light on your feet. Easier to dodge.",
	"Cleats": "Left under the Mt. Carmel bleachers. Good grip.",
	"Foam Finger": "Wally's giant foam finger. WE'RE NUMBER ONE.",
}


## Is this an accessory (something you wear) rather than food?
static func is_accessory(item: Dictionary) -> bool:
	return item.has("slot")


## A short line of an accessory's stats, like "Weapon: ATK +2".
static func stats_text(item: Dictionary) -> String:
	var parts: Array[String] = []
	if int(item.get("atk", 0)) != 0:
		parts.append("ATK +%d" % int(item["atk"]))
	if int(item.get("def", 0)) != 0:
		parts.append("DEF +%d" % int(item["def"]))
	return "%s: %s" % [Game.SLOT_NAMES.get(item["slot"], "?"), "  ".join(parts)]


## The text shown when you CHECK an item.
static func describe(item: Dictionary) -> String:
	var text: String = DESCRIPTIONS.get(item["name"], "It's... something.")
	if is_accessory(item):
		return "* \"%s\" - %s\n* %s" % [item["name"], stats_text(item), text]
	return "* \"%s\" - Heals %d HP.\n* %s" % [item["name"], int(item["heal"]), text]


## An accessory, ready to put in the bag (or a shop's stock, with a "price").
static func accessory(item_name: String, slot: String, atk: int, def: int) -> Dictionary:
	return {"name": item_name, "heal": 0, "slot": slot, "atk": atk, "def": def}
