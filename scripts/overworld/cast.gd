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
	var base := FOLDER + Game.sprite_base(who)
	var back: Texture2D = load(base + "_back.png") if ResourceLoader.exists(base + "_back.png") else null
	var character := Character.new().setup(load(base + ".png"), back, is_solid)
	if ResourceLoader.exists(base + "_side.png") and ResourceLoader.exists(base + "_side2.png"):
		character.with_side(load(base + "_side.png"), load(base + "_side2.png"))
		# A third side frame swings the arm the other way, if there is one.
		if ResourceLoader.exists(base + "_side3.png"):
			character.side.append(load(base + "_side3.png"))
	character.front_walk.assign(walk_frames(base))
	character.back_walk.assign(walk_frames(base + "_back"))
	character.front_run.assign(run_frames(base))
	character.back_run.assign(run_frames(base + "_back"))
	character.side_run.assign(run_frames(base + "_side"))
	return character


## The running frames for a picture (base + "_run1.png", "_run2.png", and for side
## views "_run3.png"), or none.
static func run_frames(base: String) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	for i in range(1, 4):
		var path := base + "_run%d.png" % i
		if not ResourceLoader.exists(path):
			break
		result.append(load(path))
	return result


## The two walking frames for a picture (base + "_walk1/2.png"), or none.
static func walk_frames(base: String) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if ResourceLoader.exists(base + "_walk1.png") and ResourceLoader.exists(base + "_walk2.png"):
		result.assign([load(base + "_walk1.png"), load(base + "_walk2.png")])
	return result


## The picture used for someone's dialogue portrait, or null if there isn't one.
## `mood` picks a facial expression ("happy", "angry", ...); "" is their normal face.
## If a character doesn't have that expression, their normal face is used.
static func portrait(who: String, mood: String = "") -> Texture2D:
	if who == "":
		return null
	var key := Game.sprite_base(who) + "/" + mood
	if not _portraits.has(key):
		var texture: Texture2D = null
		var mood_path := PORTRAIT_FOLDER + Game.sprite_base(who) + "_" + mood + ".png"
		var normal_path := FOLDER + Game.sprite_base(who) + ".png"
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
