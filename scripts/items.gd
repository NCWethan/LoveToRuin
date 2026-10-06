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
	"Card Pack Gum": "Pink, flat, and from 1991. Still chewy. Somehow.",
	"Candy Dice": "Sour candy shaped like dice. Roll them, then eat them.",
	"Egg Rolls": "Crispy, greasy, and gone in four bites.",
	"Clam Chowder": "Big Lou's chowder. Thick enough to stand a spoon in.",
	# Accessories.
	"Nail File": "Keeps your nails sharp. Very sharp.",
	"Hoodie": "Soft, warm, and surprisingly hard to hit through.",
	"Sneakers": "Light on your feet. Easier to dodge.",
	"Cleats": "Left under the Mt. Carmel bleachers. Good grip.",
	"Foam Finger": "Wally's giant foam finger. WE'RE NUMBER ONE.",
	"Lucky Card": "An ace of spades, a little bent. Pip swears it's lucky. It is.",
	"Heart Card": "A queen of hearts. Hold it close and your heart keeps going.",
	"Clover Card": "A four-leaf clover pressed under plastic. Money finds you.",
	"Snack Card": "A rare holo hamburger card. Food tastes better around it.",
	"Clock Card": "An old card with a ticking clock on it. Time drags near it.",
	"Rain Poncho": "Clear plastic, from the seasonal aisle. Crinkly armor.",
	"Flip-Flops": "From the seasonal aisle. Loud, but light on your feet.",
	"Divergent Glove": "Black, with red stitching that pulses. It hums near broken\n* things... It wants a hand the FRAGMENTS have already touched.",
}


## Old Man Pip's cards. They go in the Card slot, and each one does something
## instead of raising stats (worked out in battle.gd and bag_menu.gd):
const CARDS := {
	"Lucky Card": "1 in 6 FIGHT hits are LUCKY (2x)",
	"Heart Card": "Survive one knockout a battle",
	"Clover Card": "+50% money from battles",
	"Snack Card": "Food heals 50% more",
	"Clock Card": "Enemy attacks move 15% slower",
}
const LUCKY_CHANCE := 1.0 / 6.0
const CLOVER_MONEY := 1.5
const SNACK_HEALING := 1.5
const CLOCK_SLOW := 0.85


## How much a food heals someone (more with the Snack Card).
static func food_heal(item: Dictionary, member_name: String) -> int:
	var heal := int(item["heal"])
	if Game.card_of(member_name) == "Snack Card":
		heal = roundi(heal * SNACK_HEALING)
	return heal


## Is this an accessory (something you wear) rather than food?
static func is_accessory(item: Dictionary) -> bool:
	return item.has("slot")


## A short line of an accessory's stats, like "Weapon: ATK +2".
static func stats_text(item: Dictionary) -> String:
	if item["slot"] == "card":
		return "Card: " + str(CARDS.get(item["name"], "?"))
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
