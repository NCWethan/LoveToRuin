class_name PixelFont
extends RefCounted
## A chunky 5 x 7 bitmap font, drawn as blocks: for shop signs and marquees, so
## they look like 8-bit signs instead of plain text.
##
##   PixelFont.draw(ci, "VONS", Vector2(10, 10), 3, Color.RED, Color.BLACK)
##
## `px` is the size of one font pixel. Letters are 5 wide with a 1-pixel gap.
## Lowercase is drawn as uppercase. Unknown characters are skipped (a space).

const GLYPHS := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
	"J": ["..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."],
	"K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	"Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
	"X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
	"1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
	"4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
	"5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
	"6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
	"7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
	"8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
	"9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
	"&": [".##..", "#..#.", "#.#..", ".#...", "#.#.#", "#..#.", ".##.#"],
	"'": ["..#..", "..#..", ".....", ".....", ".....", ".....", "....."],
	".": [".....", ".....", ".....", ".....", ".....", ".##..", ".##.."],
	",": [".....", ".....", ".....", ".....", ".##..", "..#..", ".#..."],
	"!": ["..#..", "..#..", "..#..", "..#..", "..#..", ".....", "..#.."],
	"?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
	"-": [".....", ".....", ".....", "#####", ".....", ".....", "....."],
	":": [".....", ".##..", ".##..", ".....", ".##..", ".##..", "....."],
	"$": ["..#..", ".####", "#.#..", ".###.", "..#.#", "####.", "..#.."],
	"#": [".#.#.", ".#.#.", "#####", ".#.#.", "#####", ".#.#.", ".#.#."],
	"/": ["....#", "...#.", "...#.", "..#..", ".#...", ".#...", "#...."],
	"·": [".....", ".....", ".....", "..#..", ".....", ".....", "....."],
}
## Accented capitals: the plain letter, with its mark drawn just above it
## (in the gap over the line), as [letter, mark]. Marks are pixel offsets.
const ACCENTS := {"Í": ["I", "acute"], "Á": ["A", "acute"], "É": ["E", "acute"], "Ó": ["O", "acute"],
	"Ú": ["U", "acute"], "Ñ": ["N", "tilde"]}
const MARKS := {"acute": [Vector2i(3, -2), Vector2i(2, -1)], "tilde": [Vector2i(0, -1), Vector2i(1, -2), Vector2i(2, -1), Vector2i(3, -2)]}


## How wide `text` is when drawn with pixels of size `px` (one line).
static func width(text: String, px: float) -> float:
	if text.is_empty():
		return 0.0
	return (text.length() * 6 - 1) * px


## How tall one line is.
static func height(px: float) -> float:
	return 7 * px


## Draws `text` with its top-left at `at`. A `shadow` (if not transparent) is
## drawn one font pixel down and to the right, like an old arcade title.
static func draw(ci: CanvasItem, text: String, at: Vector2, px: float, color: Color, shadow: Color = Color(0, 0, 0, 0)) -> void:
	if shadow.a > 0.0:
		_draw(ci, text, at + Vector2(px, px), px, shadow)
	_draw(ci, text, at, px, color)


## Draws `text` centered on `center` (both ways).
static func draw_centered(ci: CanvasItem, text: String, center: Vector2, px: float, color: Color, shadow: Color = Color(0, 0, 0, 0)) -> void:
	draw(ci, text, center - Vector2(width(text, px), height(px)) / 2.0, px, color, shadow)


static func _draw(ci: CanvasItem, text: String, at: Vector2, px: float, color: Color) -> void:
	var x := at.x
	for letter in text.to_upper():
		var ch := letter
		if ACCENTS.has(ch):
			for dot in MARKS[ACCENTS[ch][1]]:
				ci.draw_rect(Rect2(x + dot.x * px, at.y + dot.y * px, px, px), color)
			ch = ACCENTS[ch][0]
		var rows: Array = GLYPHS.get(ch, [])
		for r in rows.size():
			var row: String = rows[r]
			# Runs of filled pixels in a row, drawn as one rectangle each.
			var c := 0
			while c < 5:
				if row[c] == "#":
					var start := c
					while c < 5 and row[c] == "#":
						c += 1
					ci.draw_rect(Rect2(x + start * px, at.y + r * px, (c - start) * px, px), color)
				else:
					c += 1
		x += 6 * px
