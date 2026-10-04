class_name Cast
extends RefCounted
## Makes overworld characters and dialogue portraits by name, using whatever
## pictures exist for them:
##   art/sprites/name.png          front view (required)
##   art/sprites/name_back.png     back view, for walking up (optional)
##   art/sprites/name_side.png     side view, legs together (optional)
##   art/sprites/name_side2.png    side view, mid-step (optional)
##   art/portraits/name_mood.png   facial expressions for dialogue (optional)
## "Hop" -> art/sprites/hop.png, "BigJoe6" -> art/sprites/bigjoe6.png, and so on.

const FOLDER := "res://art/sprites/"
const PORTRAIT_FOLDER := "res://art/portraits/"

## The moods that have portraits (made by tools/make_sprites.ps1).
const MOODS := ["happy", "angry", "sad", "shocked", "smug"]

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


## The picture used for someone's dialogue portrait, or null if there isn't one.
## `mood` picks a facial expression ("happy", "angry", ...); "" is their normal face.
## If a character doesn't have that expression, their normal face is used.
static func portrait(who: String, mood: String = "") -> Texture2D:
	if who == "":
		return null
	var key := who + "/" + mood
	if not _portraits.has(key):
		var texture: Texture2D = null
		var mood_path := PORTRAIT_FOLDER + who.to_lower() + "_" + mood + ".png"
		var normal_path := FOLDER + who.to_lower() + ".png"
		if mood != "" and ResourceLoader.exists(mood_path):
			texture = load(mood_path)
		elif ResourceLoader.exists(normal_path):
			texture = load(normal_path)
		_portraits[key] = texture
	return _portraits[key]


## The head-and-shoulders part of a sprite, used as the portrait. Wider sprites
## (like Wally) get the same-size window, centered on their head.
static func portrait_region(texture: Texture2D) -> Rect2:
	var extra := texture.get_width() - (PORTRAIT_REGION.size.x + 2)
	if extra <= 0:
		return PORTRAIT_REGION
	return Rect2(Vector2(floorf(extra / 2.0) + 1, PORTRAIT_REGION.position.y), PORTRAIT_REGION.size)
