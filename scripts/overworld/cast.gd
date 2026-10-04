class_name Cast
extends RefCounted
## Makes overworld characters and dialogue portraits by name, using whatever
## pictures exist in art/sprites/ for them:
##   name.png         front view (required)
##   name_back.png    back view, for walking up (optional)
##   name_side.png    side view, legs together (optional)
##   name_side2.png   side view, mid-step (optional)
## "Hop" -> art/sprites/hop.png, "BigJoe6" -> art/sprites/bigjoe6.png, and so on.

const FOLDER := "res://art/sprites/"

## The part of a front-view sprite used as a portrait (the head and shoulders).
const PORTRAIT_REGION := Rect2(1, 0, 24, 15)

static var _portraits: Dictionary = {}


static func make(who: String, is_solid: bool = true) -> Character:
	var base := FOLDER + who.to_lower()
	var back: Texture2D = load(base + "_back.png") if ResourceLoader.exists(base + "_back.png") else null
	var character := Character.new().setup(load(base + ".png"), back, is_solid)
	if ResourceLoader.exists(base + "_side.png") and ResourceLoader.exists(base + "_side2.png"):
		character.with_side(load(base + "_side.png"), load(base + "_side2.png"))
	return character


## The front-view picture used for someone's dialogue portrait, or null if there isn't one.
static func portrait(who: String) -> Texture2D:
	if who == "":
		return null
	if not _portraits.has(who):
		var path := FOLDER + who.to_lower() + ".png"
		_portraits[who] = load(path) if ResourceLoader.exists(path) else null
	return _portraits[who]
