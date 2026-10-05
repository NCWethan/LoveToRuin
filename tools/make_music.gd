extends SceneTree
## Composes the game's music as chiptune (like an old game console) and saves each
## song as a looping audio file in res://audio/music/.
##
## Run it from the project folder:
##   Godot --headless --path . --script tools/make_music.gd
##
## HOW SONGS ARE WRITTEN
## Each song has a tempo (beats per minute) and up to four parts:
##   lead   the melody (a bright square wave)
##   harm   harmony / arpeggios (a softer square wave)
##   bass   the bass line (a smooth triangle wave)
##   drums  K = kick, S = snare, H = hi-hat
## A song can also change a part's sound with e.g. "lead_wave": "saw" (a harsh,
## buzzing sound, good for villains). Waves: "square", "triangle", "saw".
## Each part is a list of bars. A bar is 16 steps (four steps per beat), separated by spaces:
##   C4, D#5, A#3 ...  start a note (letter, optional #, octave)
##   .                 keep holding the previous note
##   -                 silence
## All parts of a song need the same number of bars.

const RATE := 22050
const OUT_DIR := "res://audio/music/"

const SONGS := {
	# Title screen, opening story, ending screen. Mysterious, a little sad.
	"title": {
		"bpm": 76,
		"lead": [
			"A4 . . . . . . . C5 . . . B4 . . .",
			"A4 . . . . . . . F4 . . . . . . .",
			"G4 . . . . . . . E4 . . . G4 . . .",
			"D4 . . . . . . . . . . . - - - -",
			"A4 . . . . . . . C5 . . . E5 . . .",
			"D5 . . . . . . . C5 . . . A4 . . .",
			"B4 . . . . . . . A4 . . . F4 . . .",
			"G#4 . . . . . . . . . . . - - - -",
		],
		"harm": [
			"A3 . C4 . E4 . C4 . A3 . C4 . E4 . C4 .",
			"F3 . A3 . C4 . A3 . F3 . A3 . C4 . A3 .",
			"C4 . E4 . G4 . E4 . C4 . E4 . G4 . E4 .",
			"G3 . B3 . D4 . B3 . G3 . B3 . D4 . B3 .",
			"A3 . C4 . E4 . C4 . A3 . C4 . E4 . C4 .",
			"F3 . A3 . C4 . A3 . F3 . A3 . C4 . A3 .",
			"D4 . F4 . A4 . F4 . D4 . F4 . A4 . F4 .",
			"E3 . G#3 . B3 . G#3 . E3 . G#3 . B3 . G#3 .",
		],
		"bass": [
			"A2 . . . . . . . . . . . . . . .",
			"F2 . . . . . . . . . . . . . . .",
			"C3 . . . . . . . . . . . . . . .",
			"G2 . . . . . . . . . . . . . . .",
			"A2 . . . . . . . . . . . . . . .",
			"F2 . . . . . . . . . . . . . . .",
			"D2 . . . . . . . . . . . . . . .",
			"E2 . . . . . . . . . . . . . . .",
		],
	},

	# Mt. Carmel High School. Sunny and easygoing.
	"mt_carmel": {
		"bpm": 112,
		"lead": [
			"E5 . D5 . C5 . . . G4 . A4 . C5 . . .",
			"C5 . . . A4 . . . E4 . . . A4 . C5 .",
			"F5 . E5 . D5 . . . C5 . . . A4 . . .",
			"B4 . C5 . D5 . . . G4 . . . . . . .",
			"E5 . D5 . C5 . . . G4 . A4 . C5 . E5 .",
			"A5 . . . G5 . . . E5 . . . C5 . . .",
			"F5 . . . E5 . D5 . G5 . . . F5 . D5 .",
			"C5 . . . . . . . . . . . - - - -",
		],
		"harm": [
			"- - G4 . - - G4 . - - G4 . - - G4 .",
			"- - E4 . - - E4 . - - E4 . - - E4 .",
			"- - A4 . - - A4 . - - A4 . - - A4 .",
			"- - B4 . - - B4 . - - D5 . - - B4 .",
			"- - G4 . - - G4 . - - G4 . - - G4 .",
			"- - E4 . - - E4 . - - E4 . - - E4 .",
			"- - A4 . - - A4 . - - B4 . - - B4 .",
			"- - G4 . - - E4 . - - C4 . - - - -",
		],
		"bass": [
			"C3 . . . G2 . . . C3 . . . G2 . . .",
			"A2 . . . E2 . . . A2 . . . E2 . . .",
			"F2 . . . C3 . . . F2 . . . C3 . . .",
			"G2 . . . D3 . . . G2 . . . D3 . . .",
			"C3 . . . G2 . . . C3 . . . G2 . . .",
			"A2 . . . E2 . . . A2 . . . E2 . . .",
			"F2 . . . C3 . . . G2 . . . D3 . . .",
			"C3 . . . G2 . . . C3 . . . . . . .",
		],
		"drums": [
			"K - H - S - H - K - H - S - H -",
			"K - H - S - H - K - K - S - H -",
			"K - H - S - H - K - H - S - H -",
			"K - H - S - H - K - K - S - H H",
			"K - H - S - H - K - H - S - H -",
			"K - H - S - H - K - K - S - H -",
			"K - H - S - H - K - H - S - H -",
			"K - H - S - H - K - - - S S S S",
		],
	},

	# The PQ Mall. Bouncy hometown hangout.
	"mall": {
		"bpm": 120,
		"lead": [
			"A4 . C5 . F5 . . . E5 . F5 . G5 . . .",
			"F5 . . . D5 . . . A4 . . . D5 . . .",
			"D5 . F5 . A#5 . . . A5 . G5 . F5 . . .",
			"E5 . . . G5 . . . C5 . . . - - - -",
			"A4 . C5 . F5 . . . E5 . F5 . A5 . . .",
			"G5 . F5 . D5 . . . F5 . . . A5 . . .",
			"G5 . . . A#5 . . . A5 . G5 . E5 . C5 .",
			"F5 . . . . . . . - - - - - - - -",
		],
		"harm": [
			"- - A4 . - - A4 . - - A4 . - - A4 .",
			"- - F4 . - - F4 . - - F4 . - - F4 .",
			"- - D5 . - - D5 . - - D5 . - - D5 .",
			"- - C5 . - - C5 . - - E5 . - - E5 .",
			"- - A4 . - - A4 . - - A4 . - - A4 .",
			"- - F4 . - - F4 . - - F4 . - - F4 .",
			"- - D5 . - - D5 . - - E5 . - - E5 .",
			"- - A4 . - - F4 . - - - - - - - -",
		],
		"bass": [
			"F2 . . . C3 . . . F2 . . . C3 . . .",
			"D2 . . . A2 . . . D2 . . . A2 . . .",
			"A#1 . . . F2 . . . A#1 . . . F2 . . .",
			"C2 . . . G2 . . . C2 . . . G2 . . .",
			"F2 . . . C3 . . . F2 . . . C3 . . .",
			"D2 . . . A2 . . . D2 . . . A2 . . .",
			"G2 . . . D3 . . . C2 . . . G2 . . .",
			"F2 . . . C3 . . . F2 . . . . . . .",
		],
		"drums": [
			"K - - H S - - H K - K H S - - H",
			"K - - H S - - H K - K H S - - H",
			"K - - H S - - H K - K H S - - H",
			"K - - H S - - H K - K H S - S S",
			"K - - H S - - H K - K H S - - H",
			"K - - H S - - H K - K H S - - H",
			"K - - H S - - H K - K H S - - H",
			"K - - H S - - H K - - - S - - -",
		],
	},

	# Westview High School after dark. Eerie, like a music box in an empty building.
	"westview": {
		"bpm": 68,
		"lead": [
			"E5 . . . . . . . . . . . D#5 . . .",
			"E5 . . . . . . . C5 . . . . . . .",
			"A4 . . . . . . . . . . . G#4 . . .",
			"A4 . . . . . . . . . . . - - - -",
			"C5 . . . . . . . B4 . . . . . . .",
			"A4 . . . . . . . F4 . . . . . . .",
			"E4 . . . . . . . F4 . . . G#4 . . .",
			"A4 . . . . . . . . . . . - - - -",
		],
		"harm": [
			"A5 . E5 . C5 . E5 . A5 . E5 . C5 . E5 .",
			"A5 . E5 . C5 . E5 . A5 . E5 . C5 . E5 .",
			"A5 . F5 . C5 . F5 . A5 . F5 . C5 . F5 .",
			"G#5 . E5 . B4 . E5 . G#5 . E5 . B4 . E5 .",
			"A5 . E5 . C5 . E5 . A5 . E5 . C5 . E5 .",
			"A5 . F5 . D5 . F5 . A5 . F5 . D5 . F5 .",
			"G#5 . E5 . B4 . E5 . G#5 . E5 . D5 . B4 .",
			"A5 . E5 . C5 . E5 . A4 . - - - - - -",
		],
		"bass": [
			"A1 . . . . . . . . . . . . . . .",
			"A1 . . . . . . . . . . . . . . .",
			"F1 . . . . . . . . . . . . . . .",
			"E1 . . . . . . . . . . . . . . .",
			"A1 . . . . . . . . . . . . . . .",
			"D2 . . . . . . . . . . . . . . .",
			"E1 . . . . . . . . . . . . . . .",
			"A1 . . . . . . . . . . . . . . .",
		],
		"drums": [
			"- - - - - - - - H - - - - - - -",
			"- - - - - - - - - - - - - - - -",
			"- - - - - - - - H - - - - - - -",
			"- - - - - - - - - - - - - - - -",
			"- - - - - - - - H - - - - - - -",
			"- - - - - - - - - - - - - - - -",
			"- - - - - - - - H - - - - - - -",
			"- - - - - - - - - - - - - - - -",
		],
	},

	# Regular battles. Fast and driving.
	"battle": {
		"bpm": 150,
		"lead": [
			"E5 . . B4 . . E5 . G5 . F#5 . E5 . D5 .",
			"E5 . . . C5 . . . G4 . . . C5 . E5 .",
			"F#5 . . D5 . . F#5 . A5 . G5 . F#5 . E5 .",
			"D#5 . . . B4 . . . F#4 . . . B4 . D#5 .",
			"E5 . . B4 . . E5 . G5 . F#5 . E5 . G5 .",
			"A5 . . . G5 . E5 . C5 . . . E5 . G5 .",
			"A5 . G5 . F#5 . E5 . C5 . E5 . A4 . C5 .",
			"B4 . . . . . . . D#5 . . . F#5 . . .",
		],
		"bass": [
			"E2 . E3 . E2 . E3 . E2 . E3 . E2 . E3 .",
			"C2 . C3 . C2 . C3 . C2 . C3 . C2 . C3 .",
			"D2 . D3 . D2 . D3 . D2 . D3 . D2 . D3 .",
			"B1 . B2 . B1 . B2 . B1 . B2 . B1 . B2 .",
			"E2 . E3 . E2 . E3 . E2 . E3 . E2 . E3 .",
			"C2 . C3 . C2 . C3 . C2 . C3 . C2 . C3 .",
			"A1 . A2 . A1 . A2 . A1 . A2 . A1 . A2 .",
			"B1 . B2 . B1 . B2 . B1 . B2 . B1 . B2 .",
		],
		"drums": [
			"K - H - S - H - K - K - S - H -",
			"K - H - S - H - K - K - S - H -",
			"K - H - S - H - K - K - S - H -",
			"K - H - S - H - K - K - S - S S",
			"K - H - S - H - K - K - S - H -",
			"K - H - S - H - K - K - S - H -",
			"K - H - S - H - K - K - S - H -",
			"K - H K S - H - K - K - S S S S",
		],
	},

	# Wally Wolverine's boss fight. Intense, with a chant-like rhythm.
	"boss": {
		"bpm": 160,
		"lead": [
			"D5 . D5 . F5 . D5 . A5 . . . G5 . F5 .",
			"F5 . . . D5 . . . A#4 . D5 . F5 . . .",
			"E5 . E5 . G5 . E5 . C6 . . . A#5 . G5 .",
			"A5 . . . E5 . . . C#5 . . . E5 . A5 .",
			"D5 . D5 . F5 . D5 . A5 . . . G5 . F5 .",
			"F5 . G5 . A5 . . . A#5 . A5 . G5 . F5 .",
			"G5 . . . D5 . . . A#4 . D5 . G5 . A#5 .",
			"A5 . . . . . . . C#6 . . . E6 . . .",
		],
		"harm": [
			"D4 . - - D4 . - - D4 . - - D4 . - -",
			"A#3 . - - A#3 . - - A#3 . - - A#3 . - -",
			"C4 . - - C4 . - - C4 . - - C4 . - -",
			"A3 . - - A3 . - - C#4 . - - E4 . - -",
			"D4 . - - D4 . - - D4 . - - D4 . - -",
			"A#3 . - - A#3 . - - A#3 . - - A#3 . - -",
			"G3 . - - G3 . - - A#3 . - - D4 . - -",
			"A3 . - - C#4 . - - E4 . - - A4 . - -",
		],
		"bass": [
			"D2 . D3 . D2 . D3 . D2 . D3 . D2 . D3 .",
			"A#1 . A#2 . A#1 . A#2 . A#1 . A#2 . A#1 . A#2 .",
			"C2 . C3 . C2 . C3 . C2 . C3 . C2 . C3 .",
			"A1 . A2 . A1 . A2 . A1 . A2 . A1 . A2 .",
			"D2 . D3 . D2 . D3 . D2 . D3 . D2 . D3 .",
			"A#1 . A#2 . A#1 . A#2 . A#1 . A#2 . A#1 . A#2 .",
			"G1 . G2 . G1 . G2 . G1 . G2 . G1 . G2 .",
			"A1 . A2 . A1 . A2 . A1 . A2 . A1 . A2 .",
		],
		"drums": [
			"K - H K S - H - K - K H S - S S",
			"K - H K S - H - K - K H S - H -",
			"K - H K S - H - K - K H S - S S",
			"K - H K S - H - K - K H S S S S",
			"K - H K S - H - K - K H S - S S",
			"K - H K S - H - K - K H S - H -",
			"K - H K S - H - K - K H S - S S",
			"K K S - K K S - K K S - S S S S",
		],
	},

	# Hilltop Park at night. Wistful and tense: the calm before the storm.
	"hilltop": {
		"bpm": 84,
		"lead": [
			"D5 . . . . . . . F5 . . . E5 . . .",
			"D5 . . . . . . . A#4 . . . . . . .",
			"C5 . . . . . . . A4 . . . C5 . . .",
			"G4 . . . . . . . . . . . - - - -",
			"D5 . . . . . . . F5 . . . A5 . . .",
			"G5 . . . F5 . . . D5 . . . A#4 . . .",
			"A#4 . . . . . . . D5 . . . G5 . . .",
			"E5 . . . . . . . C#5 . . . A4 . . .",
		],
		"harm": [
			"D4 . F4 . A4 . F4 . D4 . F4 . A4 . F4 .",
			"A#3 . D4 . F4 . D4 . A#3 . D4 . F4 . D4 .",
			"F3 . A3 . C4 . A3 . F3 . A3 . C4 . A3 .",
			"C4 . E4 . G4 . E4 . C4 . E4 . G4 . E4 .",
			"D4 . F4 . A4 . F4 . D4 . F4 . A4 . F4 .",
			"A#3 . D4 . F4 . D4 . A#3 . D4 . F4 . D4 .",
			"G3 . A#3 . D4 . A#3 . G3 . A#3 . D4 . A#3 .",
			"A3 . C#4 . E4 . C#4 . A3 . C#4 . E4 . C#4 .",
		],
		"bass": [
			"D2 . . . . . . . . . . . . . . .",
			"A#1 . . . . . . . . . . . . . . .",
			"F2 . . . . . . . . . . . . . . .",
			"C2 . . . . . . . . . . . . . . .",
			"D2 . . . . . . . . . . . . . . .",
			"A#1 . . . . . . . . . . . . . . .",
			"G1 . . . . . . . . . . . . . . .",
			"A1 . . . . . . . . . . . . . . .",
		],
		"drums": [
			"- - - - - - - - H - - - - - - -",
			"- - - - - - - - H - - - - - - -",
			"- - - - - - - - H - - - - - - -",
			"- - - - - - - - H - - - H - - -",
			"- - - - - - - - H - - - - - - -",
			"- - - - - - - - H - - - - - - -",
			"- - - - - - - - H - - - - - - -",
			"K - - - - - - - H - - - K - - -",
		],
	},

	# Hopkuna takes over. Slow and menacing: a low, buzzing line creeping downward,
	# clashing notes ringing above it, and a heartbeat.
	"hopkuna_reveal": {
		"bpm": 64,
		"lead_wave": "saw",
		"lead": [
			"C4 . . . . . . . . . . . B3 . . .",
			"A#3 . . . . . . . . . . . A3 . . .",
			"G#3 . . . . . . . . . . . G3 . . .",
			"F#3 . . . . . . . . . . . - - - -",
			"C4 . . . . . . . C#4 . . . . . . .",
			"C4 . . . . . . . B3 . . . . . . .",
			"F#3 . . . . . . . G3 . . . G#3 . . .",
			"G3 . . . . . . . . . . . - - - -",
		],
		"harm": [
			"- - - - - - - - F#5 . . . - - - -",
			"- - - - - - - - - - - - - - - -",
			"- - - - - - - - D5 . . . - - - -",
			"- - - - - - - - - - - - C#5 . . .",
			"- - - - - - - - F#5 . . . - - - -",
			"- - - - - - - - - - - - G5 . . .",
			"- - - - C5 . . . - - - - C#5 . . .",
			"- - - - - - - - - - - - - - - -",
		],
		"bass": [
			"C2 . . . . . . . . . . . . . . .",
			"C2 . . . . . . . . . . . . . . .",
			"C2 . . . . . . . . . . . . . . .",
			"F#1 . . . . . . . . . . . . . . .",
			"C2 . . . . . . . . . . . . . . .",
			"C2 . . . . . . . . . . . . . . .",
			"F#1 . . . . . . . . . . . . . . .",
			"G1 . . . . . . . . . . . . . . .",
		],
		"drums": [
			"K - K - - - - - - - - - - - - -",
			"K - K - - - - - - - - - - - - -",
			"K - K - - - - - - - - - - - - -",
			"K - K - - - - - - - - - - - - -",
			"K - K - - - - - - - - - - - - -",
			"K - K - - - - - - - - - - - - -",
			"K - K - - - - - K - K - - - - -",
			"K - K - - - - - K - K - K K K K",
		],
	},

	# Fighting Hopkuna. Fast and urgent: a relentless chugging bass, sharp stabs,
	# and a frantic melody that ends in a falling chromatic run.
	"hopkuna": {
		"bpm": 184,
		"lead_wave": "saw",
		"harm_wave": "saw",
		"lead": [
			"C5 . D#5 . F#5 . G5 . . . F#5 . D#5 . C5 .",
			"B4 . C5 . D#5 . . . C5 . B4 . G4 . . .",
			"C5 . D#5 . F#5 . G5 . . . A#5 . G5 . F#5 .",
			"G5 . . . F#5 . . . D#5 . . . B4 . . .",
			"C6 . . . B5 . . . G#5 . . . G5 . . .",
			"F#5 . G5 . G#5 . G5 . F#5 . D#5 . C5 . . .",
			"C5 . C5 . D#5 . C5 . F#5 . . . G5 . . .",
			"G5 . F#5 . F5 . E5 . D#5 . D5 . C#5 . B4 .",
		],
		"harm": [
			"- C4 - C4 - D#4 - D#4 - C4 - C4 - F#4 - F#4",
			"- B3 - B3 - D4 - D4 - B3 - B3 - G3 - G3",
			"- C4 - C4 - D#4 - D#4 - C4 - C4 - F#4 - F#4",
			"- B3 - B3 - D4 - D4 - B3 - B3 - G3 - G3",
			"- G#3 - G#3 - C4 - C4 - G#3 - G#3 - D#4 - D#4",
			"- F#3 - F#3 - A3 - A3 - C4 - C4 - D#4 - D#4",
			"- C4 - C4 - D#4 - D#4 - C4 - C4 - F#4 - F#4",
			"- G3 - G3 - B3 - B3 - D4 - D4 - F4 - F4",
		],
		"bass": [
			"C2 C2 C3 C2 C2 C2 C3 C2 C2 C2 C3 C2 C2 C3 C2 C3",
			"G1 G1 G2 G1 G1 G1 G2 G1 G1 G1 G2 G1 G1 G2 G1 G2",
			"C2 C2 C3 C2 C2 C2 C3 C2 C2 C2 C3 C2 C2 C3 C2 C3",
			"G1 G1 G2 G1 G1 G1 G2 G1 G1 G1 G2 G1 G1 G2 G1 G2",
			"G#1 G#1 G#2 G#1 G#1 G#1 G#2 G#1 G#1 G#1 G#2 G#1 G#1 G#2 G#1 G#2",
			"F#1 F#1 F#2 F#1 F#1 F#1 F#2 F#1 F#1 F#1 F#2 F#1 F#1 F#2 F#1 F#2",
			"C2 C2 C3 C2 C2 C2 C3 C2 C2 C2 C3 C2 C2 C3 C2 C3",
			"G1 G1 G2 G1 G1 G1 G2 G1 G1 G1 G2 G1 G1 G2 G1 G2",
		],
		"drums": [
			"K - H K S - H K K - H K S K S S",
			"K - H K S - H K K - H K S - H H",
			"K - H K S - H K K - H K S K S S",
			"K - H K S - H K K K H K S S S S",
			"K - H K S - H K K - H K S K S S",
			"K - H K S - H K K - H K S - H H",
			"K - H K S - H K K - H K S K S S",
			"S S S S S S S S K K K K S S S S",
		],
	},

	# Eggo and BigJoe6 show up. A bold, determined march: Revolution's theme.
	"revolution": {
		"bpm": 132,
		"lead": [
			"E5 . . E5 G5 . . . B5 . . . A5 . G5 .",
			"E5 . . . . . . . C5 . D5 . E5 . . .",
			"D5 . . D5 G5 . . . B5 . . . A5 . G5 .",
			"F#5 . . . . . . . D5 . E5 . F#5 . . .",
			"E5 . . E5 G5 . . . B5 . . . D6 . B5 .",
			"C6 . . . B5 . A5 . G5 . . . E5 . . .",
			"A5 . . . G5 . F#5 . E5 . . . C5 . . .",
			"B4 . . . D#5 . . . F#5 . . . B5 . . .",
		],
		"harm": [
			"- - B4 . - - B4 . - - B4 . - - B4 .",
			"- - G4 . - - G4 . - - G4 . - - G4 .",
			"- - D5 . - - D5 . - - D5 . - - D5 .",
			"- - A4 . - - A4 . - - A4 . - - A4 .",
			"- - B4 . - - B4 . - - B4 . - - B4 .",
			"- - G4 . - - G4 . - - G4 . - - G4 .",
			"- - E4 . - - E4 . - - E4 . - - E4 .",
			"- - D#5 . - - D#5 . - - F#4 . - - F#4 .",
		],
		"bass": [
			"E2 . . . B2 . . . E2 . . . B2 . . .",
			"C2 . . . G2 . . . C2 . . . G2 . . .",
			"G2 . . . D3 . . . G2 . . . D3 . . .",
			"D2 . . . A2 . . . D2 . . . A2 . . .",
			"E2 . . . B2 . . . E2 . . . B2 . . .",
			"C2 . . . G2 . . . C2 . . . G2 . . .",
			"A2 . . . E2 . . . A2 . . . E2 . . .",
			"B1 . . . F#2 . . . B1 . . . F#2 . . .",
		],
		"drums": [
			"K - S - K - S - K K S - K - S S",
			"K - S - K - S - K K S - K - S -",
			"K - S - K - S - K K S - K - S S",
			"K - S - K - S - K K S - S S S S",
			"K - S - K - S - K K S - K - S S",
			"K - S - K - S - K K S - K - S -",
			"K - S - K - S - K K S - K - S S",
			"K - S - K K S - K K S - S S S S",
		],
	},

	# Wally Wolverine. A chase: serious and driving, but still upbeat. Pounding
	# eighth-note bass, an urgent minor-key melody, drums that don't let up.
	"wally": {
		"bpm": 168,
		"lead": [
			"E5 . . . G5 . . . B5 . A5 . G5 . F#5 .",
			"E5 . . . . . . . D5 . E5 . F#5 . G5 .",
			"A5 . . . G5 . . . F#5 . G5 . A5 . B5 .",
			"B5 . . . . . . . - - B5 - B5 - D6 .",
			"E6 . . . D6 . . . B5 . A5 . G5 . A5 .",
			"B5 . . . G5 . . . E5 . F#5 . G5 . A5 .",
			"C6 . . . B5 . . . A5 . G5 . F#5 . G5 .",
			"E5 . . . . . . . E5 - E5 - D#5 . . .",
		],
		"harm": [
			"- B4 - B4 - B4 - B4 - B4 - B4 - B4 - B4",
			"- G4 - G4 - G4 - G4 - G4 - G4 - G4 - G4",
			"- C5 - C5 - C5 - C5 - A4 - A4 - A4 - A4",
			"- D#5 - D#5 - D#5 - D#5 - F#4 - F#4 - F#4 - F#4",
			"- B4 - B4 - B4 - B4 - B4 - B4 - B4 - B4",
			"- G4 - G4 - G4 - G4 - G4 - G4 - G4 - G4",
			"- E5 - E5 - E5 - E5 - C5 - C5 - C5 - C5",
			"- D#5 - D#5 - D#5 - D#5 - B4 - B4 - B4 - B4",
		],
		"bass": [
			"E2 E3 E2 E3 E2 E3 E2 E3 E2 E3 E2 E3 E2 E3 E2 E3",
			"E2 E3 E2 E3 E2 E3 E2 E3 E2 E3 E2 E3 E2 E3 E2 E3",
			"A2 A3 A2 A3 A2 A3 A2 A3 A2 A3 A2 A3 A2 A3 A2 A3",
			"B1 B2 B1 B2 B1 B2 B1 B2 B1 B2 B1 B2 B1 B2 B1 B2",
			"E2 E3 E2 E3 E2 E3 E2 E3 E2 E3 E2 E3 E2 E3 E2 E3",
			"E2 E3 E2 E3 E2 E3 E2 E3 E2 E3 E2 E3 E2 E3 E2 E3",
			"C2 C3 C2 C3 C2 C3 C2 C3 C2 C3 C2 C3 C2 C3 C2 C3",
			"B1 B2 B1 B2 B1 B2 B1 B2 B1 B2 B1 B2 B1 B2 B1 B2",
		],
		"drums": [
			"K H S H K H S H K H S H K K S H",
			"K H S H K H S H K H S H K K S H",
			"K H S H K H S H K H S H K K S H",
			"K H S H K H S H S S S S S S S S",
			"K H S H K H S H K H S H K K S H",
			"K H S H K H S H K H S H K K S H",
			"K H S H K H S H K H S H K K S H",
			"K K S K K K S K S S S S K K K K",
		],
	},

	# Rock Paper Scissors. Absurdly, overly epic, for a game about hand shapes.
	# Heroic leaps, thundering drums, rolling arpeggios.
	"rps": {
		"bpm": 150,
		"lead": [
			"D5 . . . A5 . . . D6 . . . C6 . A5 .",
			"A#5 . . . A5 . G5 . A5 . . . . . . .",
			"F5 . . . G5 . A5 . A#5 . . . C6 . D6 .",
			"E6 . . . . . . . C#6 . . . . . . .",
			"D6 . A5 . D6 . A5 . F6 . E6 . D6 . C6 .",
			"A#5 . . . C6 . . . D6 . . . E6 . . .",
			"F6 . E6 . D6 . C6 . A#5 . A5 . G5 . A5 .",
			"D6 . . . . . . . D6 - D6 - D6 . . .",
		],
		"harm": [
			"D4 F4 A4 D5 D4 F4 A4 D5 D4 F4 A4 D5 D4 F4 A4 D5",
			"A#3 D4 F4 A#4 A#3 D4 F4 A#4 A#3 D4 F4 A#4 A#3 D4 F4 A#4",
			"F4 A4 C5 F5 F4 A4 C5 F5 G4 A#4 D5 G5 G4 A#4 D5 G5",
			"A3 C#4 E4 A4 A3 C#4 E4 A4 A3 C#4 E4 A4 A3 C#4 E4 A4",
			"D4 F4 A4 D5 D4 F4 A4 D5 D4 F4 A4 D5 D4 F4 A4 D5",
			"A#3 D4 F4 A#4 A#3 D4 F4 A#4 A#3 D4 F4 A#4 A#3 D4 F4 A#4",
			"G4 A#4 D5 G5 G4 A#4 D5 G5 A3 C#4 E4 A4 A3 C#4 E4 A4",
			"D4 F4 A4 D5 D4 F4 A4 D5 D4 F4 A4 D5 D4 F4 A4 D5",
		],
		"bass": [
			"D2 . . . D3 . . . D2 . . . D3 . . .",
			"A#1 . . . A#2 . . . A#1 . . . A#2 . . .",
			"F2 . . . F3 . . . G2 . . . G3 . . .",
			"A1 . . . A2 . . . A1 . . . A2 . . .",
			"D2 . . . D3 . . . D2 . . . D3 . . .",
			"A#1 . . . A#2 . . . A#1 . . . A#2 . . .",
			"G2 . . . G3 . . . A1 . . . A2 . . .",
			"D2 . . . D3 . . . D2 . D2 . D2 . . .",
		],
		"drums": [
			"K - - K S - K - K - K K S - S S",
			"K - - K S - K - K - K K S - S S",
			"K - - K S - K - K - K K S - S S",
			"K - K - S - K - S S S S S S S S",
			"K - - K S - K - K - K K S - S S",
			"K - - K S - K - K - K K S - S S",
			"K - - K S - K - K - K K S - S S",
			"S S S S S S S S K K K K S S S S",
		],
	},

	# The PQ Mall at night. Soft and slow: everyone's going home.
	"mall_night": {
		"bpm": 84,
		"lead_wave": "triangle",
		"lead": [
			"A4 . . . C5 . . . F5 . . . E5 . . .",
			"D5 . . . . . . . C5 . . . . . . .",
			"A#4 . . . D5 . . . G5 . . . F5 . . .",
			"E5 . . . . . . . - - - - - - - -",
			"A4 . . . C5 . . . F5 . . . A5 . . .",
			"G5 . . . F5 . . . D5 . . . C5 . . .",
			"A#4 . . . A4 . . . G4 . . . C5 . . .",
			"F4 . . . . . . . . . . . - - - -",
		],
		"harm": [
			"F3 . A3 . C4 . A3 . F3 . A3 . C4 . A3 .",
			"D3 . F3 . A3 . F3 . D3 . F3 . A3 . F3 .",
			"A#2 . D3 . F3 . D3 . A#2 . D3 . F3 . D3 .",
			"C3 . E3 . G3 . E3 . C3 . E3 . G3 . E3 .",
			"F3 . A3 . C4 . A3 . F3 . A3 . C4 . A3 .",
			"C3 . E3 . G3 . E3 . C3 . E3 . G3 . E3 .",
			"A#2 . D3 . F3 . D3 . A#2 . D3 . F3 . D3 .",
			"F3 . A3 . C4 . A3 . F3 . A3 . C4 . A3 .",
		],
		"bass": [
			"F2 . . . . . . . . . . . . . . .",
			"D2 . . . . . . . . . . . . . . .",
			"A#1 . . . . . . . . . . . . . . .",
			"C2 . . . . . . . . . . . . . . .",
			"F2 . . . . . . . . . . . . . . .",
			"C2 . . . . . . . . . . . . . . .",
			"A#1 . . . . . . . . . . . . . . .",
			"F2 . . . . . . . . . . . . . . .",
		],
	},

	# Near a fragment. Almost silence: a low drone and a few notes that don't
	# quite fit together.
	"eerie": {
		"bpm": 50,
		"lead_wave": "triangle",
		"harm_wave": "triangle",
		"lead": [
			"E5 . . . . . . . F5 . . . . . . .",
			"- - - - - - - - - - - - - - - -",
			"A#4 . . . . . . . A4 . . . . . . .",
			"- - - - - - - - - - - - D#5 . . .",
		],
		"harm": [
			"E3 . . . . . . . . . . . . . . .",
			"F3 . . . . . . . . . . . . . . .",
			"E3 . . . . . . . . . . . . . . .",
			"A#2 . . . . . . . . . . . . . . .",
		],
		"bass": [
			"E2 . . . . . . . . . . . . . . .",
			"E2 . . . . . . . . . . . . . . .",
			"A#1 . . . . . . . . . . . . . . .",
			"E2 . . . . . . . . . . . . . . .",
		],
	},

	# GAME OVER. Slow and somber.
	"game_over": {
		"bpm": 60,
		"lead": [
			"E5 . . . D5 . . . C5 . . . B4 . . .",
			"A4 . . . . . . . . . . . - - - -",
			"C5 . . . B4 . . . A4 . . . G#4 . . .",
			"A4 . . . . . . . . . . . - - - -",
		],
		"harm": [
			"A3 . C4 . E4 . C4 . A3 . C4 . E4 . C4 .",
			"F3 . A3 . C4 . A3 . F3 . A3 . C4 . A3 .",
			"D4 . F4 . A4 . F4 . E4 . G#4 . B4 . G#4 .",
			"A3 . C4 . E4 . C4 . A3 . - - - - - -",
		],
		"bass": [
			"A2 . . . . . . . . . . . . . . .",
			"F2 . . . . . . . . . . . . . . .",
			"D2 . . . . . . . E2 . . . . . . .",
			"A2 . . . . . . . . . . . . . . .",
		],
	},
}

## How loud each part is, and its sound: square waves (with a "duty" that changes
## how bright they sound) or a triangle wave.
const PARTS := {
	"lead": {"volume": 0.16, "wave": "square", "duty": 0.25},
	"harm": {"volume": 0.08, "wave": "square", "duty": 0.5},
	"bass": {"volume": 0.22, "wave": "triangle", "duty": 0.5},
}
const DRUM_VOLUME := 0.18


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for song_name in SONGS:
		var stream := render(SONGS[song_name])
		var path: String = OUT_DIR + song_name + ".res"
		var error := ResourceSaver.save(stream, path)
		print("%-10s %5.1f seconds  -> %s %s" % [song_name, stream.get_length(), path, "" if error == OK else "(ERROR %d)" % error])
	quit()


## Turns a song into a looping audio stream.
func render(song: Dictionary) -> AudioStreamWAV:
	var step_seconds := 60.0 / float(song["bpm"]) / 4.0
	var bars := (song["lead"] as Array).size()
	var steps := bars * 16
	var total := int(steps * step_seconds * RATE)
	var mix := PackedFloat32Array()
	mix.resize(total)

	for part in PARTS:
		if song.has(part):
			var sound: Dictionary = PARTS[part].duplicate()
			if song.has(part + "_wave"):
				sound["wave"] = song[part + "_wave"]
				# Saw waves are much brighter, so play them a bit quieter.
				if sound["wave"] == "saw":
					sound["volume"] *= 0.75
			_render_part(mix, _parse(song[part], part), step_seconds, sound)
	if song.has("drums"):
		_render_drums(mix, song["drums"], step_seconds)

	# Convert to 16-bit audio, gently limiting any loud peaks.
	var data := PackedByteArray()
	data.resize(total * 2)
	for i in total:
		var v := clampf(tanh(mix[i] * 1.2), -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 30000.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total
	return stream


## Reads a part's bars into a list of notes: [start step, length in steps, frequency].
func _parse(bars: Array, part: String) -> Array:
	var notes := []
	var step := 0
	for bar in bars:
		var tokens: PackedStringArray = (bar as String).split(" ", false)
		if tokens.size() != 16:
			push_error("A bar in '%s' has %d steps instead of 16: %s" % [part, tokens.size(), bar])
		for token in tokens:
			if token == ".":
				if not notes.is_empty() and notes.back()[0] + notes.back()[1] == step:
					notes.back()[1] += 1
			elif token != "-":
				notes.append([step, 1, _frequency(token)])
			step += 1
	return notes


## "A4" -> 440.0, "C#5" -> 554.4, and so on.
func _frequency(note: String) -> float:
	const NAMES := {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
	var octave := int(note.right(1))
	var semitone: int = NAMES[note.left(note.length() - 1)]
	var midi := (octave + 1) * 12 + semitone
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


func _render_part(mix: PackedFloat32Array, notes: Array, step_seconds: float, sound: Dictionary) -> void:
	var volume: float = sound["volume"]
	var duty: float = sound["duty"]
	var shape: String = sound["wave"]
	for note in notes:
		var start := int(note[0] * step_seconds * RATE)
		var length := int(note[1] * step_seconds * RATE)
		var freq: float = note[2]
		var phase := 0.0
		for s in length:
			var i := start + s
			if i >= mix.size():
				break
			phase = fmod(phase + freq / RATE, 1.0)
			var wave: float
			match shape:
				"triangle": wave = 4.0 * absf(phase - 0.5) - 1.0
				"saw": wave = 2.0 * phase - 1.0
				_: wave = 1.0 if phase < duty else -1.0
			# Envelope: quick attack, settle to 70%, short fade at the end so notes don't click.
			var t := float(s) / RATE
			var env := minf(1.0, t / 0.005)
			env *= lerpf(1.0, 0.7, minf(1.0, t / 0.08))
			env *= minf(1.0, float(length - s) / (0.02 * RATE))
			mix[i] += wave * volume * env


func _render_drums(mix: PackedFloat32Array, bars: Array, step_seconds: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var step := 0
	for bar in bars:
		for token in (bar as String).split(" ", false):
			var start := int(step * step_seconds * RATE)
			match token:
				"K":
					# Kick: a quick low "boom" that drops in pitch.
					var phase := 0.0
					for s in int(0.12 * RATE):
						var t := float(s) / RATE
						phase += lerpf(140.0, 45.0, t / 0.12) / RATE
						if start + s < mix.size():
							mix[start + s] += sin(phase * TAU) * DRUM_VOLUME * 1.6 * (1.0 - t / 0.12)
				"S":
					# Snare: a burst of noise.
					for s in int(0.1 * RATE):
						var t := float(s) / RATE
						if start + s < mix.size():
							mix[start + s] += rng.randf_range(-1, 1) * DRUM_VOLUME * pow(1.0 - t / 0.1, 2)
				"H":
					# Hi-hat: a very short, quiet tick of noise.
					for s in int(0.03 * RATE):
						var t := float(s) / RATE
						if start + s < mix.size():
							mix[start + s] += rng.randf_range(-1, 1) * DRUM_VOLUME * 0.5 * (1.0 - t / 0.03)
			step += 1
