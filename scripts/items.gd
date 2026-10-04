class_name Items
extends RefCounted
## Descriptions for every item, shown when you CHECK an item in your bag.
## Items themselves are simple: {"name": "Trail Mix", "heal": 15}.

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
}


## The text shown when you CHECK an item.
static func describe(item: Dictionary) -> String:
	var text: String = DESCRIPTIONS.get(item["name"], "It's... something.")
	return "* \"%s\" - Heals %d HP.\n* %s" % [item["name"], int(item["heal"]), text]
