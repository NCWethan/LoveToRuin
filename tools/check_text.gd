extends SceneTree
## Finds dialogue that won't fit in the text box: every line of every piece of
## dialogue in scripts/ is measured in the game's font, and anything too wide (or
## with too many lines) is listed with its file and line number.
##
## What counts as dialogue: a "text": "..." (someone talking: their portrait takes
## up the left of the box, unless the same line says "face": false) and any string
## starting with "* " (narration, which gets the whole width).
##
## Run with:  godot --headless --path . --script tools/check_text.gd

## How wide a line can be: the box is 580 across; narration starts 16 in, and
## lines with a portrait start 112 in. 16 more is kept clear on the right.
const NARRATION_WIDTH := 548.0
const PORTRAIT_WIDTH := 452.0
const MAX_LINES := 4
const FONT_SIZE := 16
## Some files draw their text somewhere else, with its own width: the shop's left
## box is about 380 across; item descriptions are narration (CHECK, in the bag);
## the opening story and Rock Paper Scissors use the whole screen.
const NARROW_FILES := {"res://scripts/shops.gd": 372.0, "res://scripts/ui/shop_menu.gd": 372.0,
	"res://scripts/items.gd": NARRATION_WIDTH, "res://scripts/scenes/intro.gd": 600.0, "res://scripts/ui/rps_game.gd": 600.0,
	# (The ending screen wraps its own long lines.)
	"res://scripts/scenes/ending.gd": 1200.0}


func _initialize() -> void:
	var font := ThemeDB.fallback_font
	var files: Array[String] = []
	_find("res://scripts", files)
	var string_pattern := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	var problems := 0
	for path in files:
		var file := FileAccess.open(path, FileAccess.READ)
		var number := 0
		while not file.eof_reached():
			var line := file.get_line()
			number += 1
			if line.strip_edges().begins_with("#"):
				continue
			var has_portrait := line.contains("\"who\"") and not line.contains("\"face\": false")
			for found in string_pattern.search_all(line):
				var raw: String = found.get_string(1)
				var is_text := line.contains("\"text\": \"" + raw)
				# Other long sentences (conversations written as plain lists, like
				# ["happy", "..."]) are checked as if someone were talking.
				var sentence := raw.length() > 30 and raw.contains(" ") and not raw.contains("res://") and not raw.contains("%-")
				if not is_text and not raw.begins_with("* ") and not sentence:
					continue
				if sentence and not is_text and not raw.begins_with("* "):
					has_portrait = true
				var text := raw.replace("\\n", "\n").replace("\\\"", "\"").replace("\\'", "'")
				var limit := PORTRAIT_WIDTH if has_portrait and not raw.begins_with("* ") else NARRATION_WIDTH
				limit = NARROW_FILES.get(path, limit)
				var rows := text.split("\n")
				for row in rows:
					# Formatting codes (%d, %s) get filled in later; count them as a few letters.
					var width := font.get_string_size(row.replace("%s", "Wally Wolverine").replace("%d", "99"), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
					if width > limit:
						problems += 1
						print("%s:%d  too wide (%d > %d): %s" % [path.trim_prefix("res://"), number, width, limit, row])
				if rows.size() > MAX_LINES and not NARROW_FILES.has(path):
					problems += 1
					print("%s:%d  %d lines (max %d): %s" % [path.trim_prefix("res://"), number, rows.size(), MAX_LINES, rows[0]])
	print("%d problems." % problems)
	quit()


func _find(folder: String, into: Array[String]) -> void:
	for name in DirAccess.get_files_at(folder):
		if name.ends_with(".gd"):
			into.append(folder + "/" + name)
	for sub in DirAccess.get_directories_at(folder):
		_find(folder + "/" + sub, into)
