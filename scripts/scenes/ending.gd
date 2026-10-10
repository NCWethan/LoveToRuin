extends Node2D
## The endings. Which one is in Game.flags["ending"]:
##   home      Corps: Hop lets go, the token holds Hopkuna, Relic says goodbye.
##             A month later, on Westview Field. "...I think I'll stay." HOME.
##   road      Own way: Elric keeps their fragments and walks away. THE ROAD.
##   gift      Own way: Elric gives the Corps their fragments, and leaves. Hop
##             carries Hopkuna alone. THE GIFT.
##   bargain   Own way: Elric gives Hopkuna their fragments. The city burns.
##   one       With Hop: Relic keeps Hop in the token. The Santa Ana wind. One.
##   let_go    With Hop, under 75 kills: Elric lets go. Relic fades. Harsh, quiet.
## Each is a few pages of text, one at a time (ENTER for the next), then its title,
## and (on the paths with anyone left) where everyone is now.

const SLIDE_FADE := 0.8

var _font: Font
var _time: float = 0.0
var _page: int = 0
var _pages: Array = []
var _title: String = ""
var _title_color: Color = Color.WHITE
var _ending: String = "home"
var _done: bool = false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	_font = ThemeDB.fallback_font
	_ending = str(Game.flags.get("ending", "home"))
	_build()
	match _ending:
		"home": Game.play_music("revolution", 2.0)
		"road", "gift": Game.play_music("relic_slow", 2.0)
		"bargain": Game.play_music("hopkuna", 2.0)
		"one": Game.play_music("genocide", 2.0)
		_: Game.stop_music(2.0)
	Game.flags["game_finished"] = true


func _process(delta: float) -> void:
	_time += delta
	if _time > 1.2 and Input.is_action_just_pressed("confirm") and not Game.transitioning:
		_next()
	queue_redraw()


func _next() -> void:
	_time = 0.0
	if _page < _pages.size():
		_page += 1
		return
	if not _done:
		_done = true
		Game.change_scene(Game.TITLE_SCENE)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color.BLACK)
	var alpha := clampf(_time / SLIDE_FADE, 0.0, 1.0)
	if _page < _pages.size():
		var page: Dictionary = _pages[_page]
		var lines: Array = page["lines"]
		var color: Color = page.get("color", Color.WHITE)
		var y := 240.0 - lines.size() * 13.0
		for line in lines:
			var w := _font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_string(_font, Vector2(320 - w / 2, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(color, alpha))
			y += 26
	else:
		# The title card. (For "one": just a pair of green eyes in the dark.)
		if _ending == "one":
			var blink := 1.0 if fmod(_time, 4.0) < 3.8 else 0.0
			for x in [300.0, 340.0]:
				draw_rect(Rect2(x - 5, 236, 10, 6), Color(0.25, 0.85, 0.4, alpha * blink))
			return
		var size := 40
		var w := _font.get_string_size(_title, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(_font, Vector2(320 - w / 2, 230), _title, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(_title_color, alpha))
		var sub := "LOVE TO RUIN"
		var w2 := _font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(_font, Vector2(320 - w2 / 2, 270), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, alpha * 0.6))
		if _ending == "home":
			# A small purple light that doesn't move.
			draw_circle(Vector2(320, 320), 5.0 + sin(_time * 2.0), Color(0.8, 0.6, 1.0, alpha))
	if _time > 1.2:
		draw_string(_font, Vector2(560, 465), "ENTER", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.3))


func _page_of(lines: Array, color: Color = Color.WHITE) -> Dictionary:
	return {"lines": lines, "color": color}


func _build() -> void:
	var green := Color(0.45, 0.95, 0.55)
	match _ending:
		"home":
			_pages = [
				_page_of(["With Hopkuna gone from them,", "the fragments are just Relic."]),
				_page_of(["In the park where Elric was born,", "the green light inside them unfolds", "into the shape of a kid in a green hoodie."], green),
				_page_of(["Relic, to Hop:", "\"It wasn't your fault.", "I told you to let go. You did.", "That's the bravest thing I ever saw.\""], green),
				_page_of(["Relic, to Elric:", "\"You found it. Didn't you?", "...Keep it.\""], green),
				_page_of(["Then the wind. The same wind.", "Warm, this time.", "And they're gone."]),
				_page_of(["A month later. Westview Field.", "The field is green again."]),
				_page_of(["A new tent. Room for three.", "The whole Corps crammed around it.", "Way more than three."]),
				_page_of(["Hop wears the token on a cord around his neck.", "Sometimes he talks to it.", "Sometimes, very quietly, it talks back."]),
				_page_of(["Down in the bunker, the sign on the spare bunk", "has been fixed. Somebody turned the E", "the right way round."]),
			] + _epilogue() + [
				_page_of(["\"...I think I'll stay.\""], Color(0.85, 0.7, 1.0)),
			]
			_title = "HOME"
			_title_color = Color(0.85, 0.7, 1.0)
		"road":
			_pages = [
				_page_of(["You keep your fragments, and walk away."]),
				_page_of(["Without them, Hopkuna can never be whole.", "And he can never stop hunting."]),
				_page_of(["You leave San Diego with Relic's pieces", "in your backpack. It clinks when you walk."]),
				_page_of(["The pull never stops.", "Nothing is solved.", "Everyone is still out there."]),
				_page_of(["\"Keep walking.\""], green),
			] + _epilogue()
			_title = "THE ROAD"
		"gift":
			_pages = [
				_page_of(["You give the Corps your fragments.", "Then you leave."]),
				_page_of(["They know breaking them only feeds him.", "So they do what Relic did.", "They seal him in the curly-fry token."]),
				_page_of(["But without you, there are only twelve of them.", "The weight lands on one person."]),
				_page_of(["Hop carries Hopkuna alone."]),
				_page_of(["Relic is freed, and says goodbye to Hop.", "You aren't there to hear it."], green),
				_page_of(["Hop looks for you on the road", "for a long, long time."]),
			] + _epilogue()
			_title = "THE GIFT"
		"bargain":
			_pages = [
				_page_of(["You give Hopkuna your fragments."]),
				_page_of(["He's whole.", "The city burns."], Color(1.0, 0.4, 0.3)),
				_page_of(["You walk away, and you don't look back."]),
				_page_of(["\"You didn't even pick a side.", "You just didn't care.", "...That's worse.\""], Color(1.0, 0.3, 0.3)),
			]
			_title = "THE BARGAIN"
			_title_color = Color(1.0, 0.3, 0.3)
		"one":
			_pages = [
				_page_of(["KEEPSAKE, one last time."], green),
				_page_of(["Hop. All of him.", "Into the curly-fry token."], green),
				_page_of(["The token goes dark.", "Relic puts it on its cord, around their neck."], green),
				_page_of(["The Santa Ana wind comes in, hot, off the hills.", "The park catches. Then the city.", "Orange, all the way to the horizon."], Color(1.0, 0.55, 0.3)),
				_page_of(["A green-eyed figure stands alone in the burning grass,", "where Elric was born."]),
				_page_of(["There were two, when there were meant to be three."], green),
				_page_of(["Now there is one."], green),
			]
			_title = ""
		_:
			_pages = [
				_page_of(["You let go."]),
				_page_of(["Relic fades. Slowly, then all at once.", "The green goes out of your hands."], green),
				_page_of(["You fall down in the grass, next to Hop."]),
				_page_of(["The Corps is still dead.", "The city is still empty.", "Nothing is fixed."]),
				_page_of(["But Hop isn't in a token.", "And he doesn't walk away."]),
				_page_of(["Hopkuna is gone too,", "broken apart somewhere in all of it."]),
				_page_of(["The sun comes up over the park.", "Neither of you says anything."]),
			]
			_title = "LET GO"
			_title_color = Color(0.7, 0.7, 0.75)


## What became of everyone in town, by what Elric did: [usually, if Elric gave
## back what Relic was carrying for them]. (Gone, if Elric killed them; and a line
## of their own if Elric kept their keepsake instead.)
const TOWN := {
	"coach": ["Coach Ramirez still yells. Less, lately.", "Coach Ramirez found his keys. All of them. He has one key ring now, and he never loses it."],
	"janitor": ["The Janitor still finds raccoons in the dumpsters. He's named all of them.", ""],
	"skater": ["The Skater finally landed the kickflip. Nobody saw. He knows.", ""],
	"waiting": ["The Waiting Ghost is still at the stop, waiting for a ride.", "The bus stop at Mt. Carmel is empty now. Someone finally went home."],
	"mallcop": ["The Mall Cop still patrols the lot. He waves at everyone.", ""],
	"mom": ["The Busy Mom is still busy. She stops for coffee now, though.", ""],
	"teen": ["The Teen texted their old friend back. They talk every day.", ""],
	"jogger": ["The Jogger runs the same loop every morning. Faster, lately.", ""],
	"nightjanitor": ["The Night Janitor still cleans Westview's halls. They end now.", ""],
	"guard": ["The Crossing Guard still holds up the sign. Cars still stop.", ""],
	"dogwalker": ["The Dog Walker walks six dogs on Westview Field.", "The Dog Walker walks six dogs. And on Sundays, she visits Peanut's tree."],
	"junkdealer": ["The Junk Dealer still talks about the taco fight.", ""],
	"firefighter": ["The Firefighter still plants a tree every weekend.", "The Firefighter planted a tree for Reyes. It's the tallest one on the hill."],
	"ranger": ["The Park Ranger finished his tree count. He counted Doris twice.", ""],
	"hiker": ["The Hiker went up the trail eleven times yesterday.", ""],
	"birder": ["The Birdwatcher saw the falcon. Finally. Six years.", ""],
	"sailor": ["The Old Sailor still tells the squid story.", "The Old Sailor tells a new story on the tours now. A true one, about the Mary Ellen."],
	"tourist": ["The Tourist went home with 4,000 photos of one seal.", "The Tourist went home with one photo: the ocean, for Grandma."],
	"pelican": ["The Pelican's fish business is still terrible. Lunch is still great.", ""],
	"hotdog": ["The Hot Dog Vendor got a tip jar. It's always full.", ""],
	"statue": ["The Living Statue broke his record. Ten hours.", "The Living Statue plays chess in the plaza now, every day. He is very, very good."],
	"superfan": ["The Superfan never misses a game. They lost again.", "The Superfan sits in Section 112. He saves the seat next to him."],
	"rosa": ["Doña Rosa still makes the best tortillas in Old Town.", "Doña Rosa called Texas. She talks to Lucía every Sunday now."],
	"cactus": ["The Mariachi Cactus learned a fifth song. It's the first song, slower.", ""],
	"guide": ["The Tour Guide still hasn't seen a ghost. He's fine with that.", ""],
	"student": ["The Student passed the test.", ""],
}


## The town, three to a page.
func _town_pages() -> Array:
	var entries: Array = []
	for id in TOWN:
		var item := ""
		for key in Collection.ITEMS:
			if Collection.ITEMS[key]["owner"] == id:
				item = key
		var line: String = TOWN[id][0]
		if Townsfolk.is_gone(id):
			line = "%s isn't around anymore." % Townsfolk.profile(id)["name"]
		elif item != "" and Collection.state(item) == "returned" and TOWN[id][1] != "":
			line = TOWN[id][1]
		elif item != "" and Collection.state(item) == "kept":
			line += " (Elric still carries something of theirs.)"
		entries.append(line)
	var pages: Array = []
	for i in range(0, entries.size(), 3):
		var chunk: Array = []
		for line in entries.slice(i, i + 3):
			# (Long lines, wrapped in two.)
			var text: String = line
			if text.length() > 52:
				var cut: int = text.rfind(" ", 52)
				chunk.append(text.substr(0, cut))
				chunk.append(text.substr(cut + 1))
			else:
				chunk.append(line)
			chunk.append("")
		pages.append(_page_of(chunk))
	return pages


## Where everyone is now (like a phone call): a line for each of the Corps, and for
## the townsfolk Elric helped.
func _epilogue() -> Array:
	var lines: Array = []
	var home := _ending == "home"
	lines.append(_page_of(["Big Joe still salutes the Empty Knight", "every Sunday. It salutes back."]))
	lines.append(_page_of(["Crayola learned a new card trick.", "It's still the Seven of Hearts."]))
	lines.append(_page_of(["N.C. Wethan won at checkers.", "Ronin says he didn't. They're still arguing."]))
	lines.append(_page_of(["Supreme updated the odds. 100%.", "He rounded up." if home else "He's not sure he believes them."]))
	lines.append(_page_of(["Nat finally read the last page.", "He says it ended well." if home else "He won't say how it ended."]))
	lines.append(_page_of(["Sansworth drives everyone everywhere.", "He still doesn't know which key it is."]))
	lines.append_array(_town_pages())
	if Game.flags.get("feather_returned", false):
		lines.append(_page_of(["\"Some kid gave me back the worst year of my life.", "Funny thing. I'm glad they did.\"", "- the man who feeds the pigeons"]))
	if Game.flags.get("ot_dinner_done", false) and Game.flags.get("ot_candles_out", false) == false:
		lines.append(_page_of(["The Casa Vieja's table is set for one now.", "The tour guide swears he heard someone laughing."]))
	return lines
