extends SceneTree
## Ronin's POWER RIFF: an original 8-bit guitar riff, written out note by note
## here, like the songs in tools/make_music.gd.
##
## It writes two things from the same notes, so the music and his animation
## can't drift apart:
##   audio/sfx/ronin_riff.wav   the riff (two square-wave "guitars", a triangle
##                              bass and noise drums)
##   scripts/ronin_riff.gd      what his hands do, every STEP seconds: how loud it
##                              is, where each note is picked, where his fretting
##                              hand is, and when he shreds or holds a note
##
## Run with:  godot --headless --path . --script tools/make_riff.gd

const OUT_WAV := "res://audio/sfx/ronin_riff.wav"
const OUT_DATA := "res://scripts/ronin_riff.gd"
const RATE := 22050
const STEP := 0.05
## 150 beats a minute: a sixteenth note is 0.1 seconds, a bar is 1.6.
const SIXTEENTH := 0.1
const BAR := 16

## E minor, chugging along. Notes are [sixteenth in the bar, length in sixteenths,
## note (MIDI number), kind]. Kinds:
##   chug    a palm-muted low note: short and punchy
##   chord   a power chord (the note, a fifth up and an octave up)
##   lead    a single high note
##   hold    a long lead note, with vibrato (he leans back for these)
##   shred   a fast lead note (his picking hand blurs)
##   ring    the last chord, left to ring out
const RIFF_A := [
	[0, 2, 40, "chord"], [2, 1, 40, "chug"], [3, 1, 40, "chug"],
	[4, 2, 43, "chord"], [6, 1, 40, "chug"], [7, 1, 40, "chug"],
	[8, 2, 45, "chord"], [10, 1, 40, "chug"], [11, 1, 40, "chug"],
	[12, 1, 46, "chord"], [13, 3, 45, "chord"],
]
const RIFF_B := [
	[0, 2, 40, "chord"], [2, 1, 40, "chug"], [3, 1, 40, "chug"],
	[4, 2, 43, "chord"], [6, 1, 40, "chug"], [7, 1, 40, "chug"],
	[8, 2, 45, "chord"], [10, 1, 43, "chord"], [11, 1, 42, "chord"],
	[12, 4, 50, "chord"],
]
## Up the E minor pentatonic, two notes at a time, then over the top.
const SOLO_RUN := [
	[0, 1, 52, "shred"], [1, 1, 55, "shred"], [2, 1, 57, "shred"], [3, 1, 59, "shred"],
	[4, 1, 57, "shred"], [5, 1, 59, "shred"], [6, 1, 62, "shred"], [7, 1, 64, "shred"],
	[8, 1, 62, "shred"], [9, 1, 64, "shred"], [10, 1, 67, "shred"], [11, 1, 69, "shred"],
	[12, 1, 67, "shred"], [13, 1, 69, "shred"], [14, 1, 71, "shred"], [15, 1, 74, "shred"],
]
## The big held note, then tumbling back down.
const SOLO_PEAK := [
	[0, 10, 76, "hold"], [10, 1, 74, "lead"], [11, 1, 71, "lead"], [12, 1, 69, "lead"],
	[13, 1, 67, "lead"], [14, 1, 64, "lead"], [15, 1, 62, "lead"],
]
const ENDING := [
	[0, 2, 40, "chord"], [2, 1, 40, "chug"], [3, 1, 40, "chug"],
	[4, 2, 43, "chord"], [6, 2, 45, "chord"],
	[8, 1, 50, "chord"], [9, 1, 47, "chord"], [10, 18, 40, "ring"],
]
## The bars, in order.
const SONG := [RIFF_A, RIFF_B, RIFF_A, RIFF_B, SOLO_RUN, SOLO_PEAK, ENDING]

## Drums for each bar, a letter per sixteenth: k kick, s snare, h hi-hat,
## c crash, . nothing.
const DRUMS := [
	"k.hkk.hks.hkk.s.",
	"k.hkk.hks.hkk.ss",
	"c.hkk.hks.hkk.h.",
	"k.hkk.hks.hkk.ss",
	"khkhshkhkhkhshss",
	"c.......k...s.s.",
	"c.hkk.hkc.......",
]

var _mix := PackedFloat32Array()
## The guitar notes, for the animation: [start time, length, note, kind].
var _notes: Array = []


func _initialize() -> void:
	var length := SONG.size() * BAR * SIXTEENTH + 1.2
	_mix.resize(int(length * RATE))
	for bar in SONG.size():
		var bar_start: float = bar * BAR * SIXTEENTH
		for note in SONG[bar]:
			var start: float = bar_start + note[0] * SIXTEENTH
			var size: float = note[1] * SIXTEENTH
			_notes.append([start, size, note[2], note[3]])
			_play_guitar(start, size, note[2], note[3])
		for k in BAR:
			var hit: String = DRUMS[bar][k]
			if hit != ".":
				_play_drum(bar_start + k * SIXTEENTH, hit)
	_save_wav()
	_save_data(length)
	quit()


func _freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## One guitar note. The low notes are played an octave up on the square waves
## (down there they'd just buzz), with the triangle bass on the real note.
func _play_guitar(start: float, size: float, midi: int, kind: String) -> void:
	var tones: Array = []    # [note, duty, volume]
	var bass := 0.0
	var decay := 0.0         # seconds to fade to almost nothing (0: no fade)
	var vibrato := 0.0
	match kind:
		"chug":
			tones = [[midi + 12, 0.5, 0.16]]
			bass = 0.22
			decay = 0.07
		"chord", "ring":
			tones = [[midi + 12, 0.5, 0.14], [midi + 19, 0.25, 0.1], [midi + 24, 0.25, 0.06]]
			bass = 0.26
			decay = 1.4 if kind == "ring" else 0.5
			vibrato = 0.12 if kind == "ring" else 0.0
		"lead", "shred":
			tones = [[midi, 0.125, 0.17], [midi - 12, 0.5, 0.05]]
			decay = 0.5
		"hold":
			tones = [[midi, 0.125, 0.17], [midi - 12, 0.5, 0.06]]
			vibrato = 0.35
	# Notes ring a little past their length (except chugs, which are cut short).
	var sound_length := size + (0.0 if kind == "chug" else 0.04)
	if kind == "ring":
		sound_length = size
	var first := int(start * RATE)
	var count := int(sound_length * RATE)
	for t in tones:
		var phase := 0.0
		for i in count:
			var at := first + i
			if at >= _mix.size():
				break
			var time := float(i) / RATE
			# Vibrato comes in after a moment, like a real held note.
			var wobble := sin(time * TAU * 6.0) * vibrato * clampf((time - 0.25) / 0.3, 0.0, 1.0)
			phase = fmod(phase + _freq(t[0] + wobble) / RATE, 1.0)
			var wave := 1.0 if phase < t[1] else -1.0
			_mix[at] += wave * t[2] * _envelope(time, sound_length, decay)
	if bass > 0.0:
		var phase := 0.0
		for i in count:
			var at := first + i
			if at >= _mix.size():
				break
			var time := float(i) / RATE
			phase = fmod(phase + _freq(midi) / RATE, 1.0)
			var triangle := 4.0 * absf(phase - 0.5) - 1.0
			_mix[at] += triangle * bass * _envelope(time, sound_length, decay * 1.5 if decay > 0.0 else 0.0)


## Snaps on, fades over `decay` seconds (if any), and closes quickly at the end.
func _envelope(time: float, length: float, decay: float) -> float:
	var level := minf(1.0, time / 0.003)
	if decay > 0.0:
		level *= lerpf(1.0, 0.25, minf(1.0, time / decay))
	return level * minf(1.0, (length - time) / 0.012)


var _noise := 0x4001


## Old-sound-chip noise (a shift register), -1 or 1.
func _noise_bit() -> float:
	var bit := (_noise ^ (_noise >> 1)) & 1
	_noise = (_noise >> 1) | (bit << 14)
	return 1.0 if _noise & 1 else -1.0


func _play_drum(start: float, hit: String) -> void:
	var first := int(start * RATE)
	match hit:
		"k":
			# A kick: a triangle dropping fast in pitch.
			var phase := 0.0
			for i in int(0.12 * RATE):
				var time := float(i) / RATE
				phase = fmod(phase + lerpf(160.0, 45.0, minf(1.0, time / 0.08)) / RATE, 1.0)
				_add(first + i, (4.0 * absf(phase - 0.5) - 1.0) * 0.4 * (1.0 - time / 0.12))
		"s":
			var held := 0.0
			for i in int(0.14 * RATE):
				if i % 2 == 0:
					held = _noise_bit()
				_add(first + i, held * 0.17 * pow(1.0 - float(i) / (0.14 * RATE), 2.0))
		"h":
			for i in int(0.035 * RATE):
				_add(first + i, _noise_bit() * 0.06 * (1.0 - float(i) / (0.035 * RATE)))
		"c":
			var held := 0.0
			for i in int(0.7 * RATE):
				if i % 3 == 0:
					held = _noise_bit()
				_add(first + i, held * 0.11 * pow(1.0 - float(i) / (0.7 * RATE), 1.5))


func _add(at: int, value: float) -> void:
	if at >= 0 and at < _mix.size():
		_mix[at] += value


func _save_wav() -> void:
	var peak := 0.0001
	for v in _mix:
		peak = maxf(peak, absf(v))
	var data := PackedByteArray()
	data.resize(_mix.size() * 2)
	for i in _mix.size():
		data.encode_s16(i * 2, int(_mix[i] / peak * 0.85 * 32767.0))
	var file := FileAccess.open(OUT_WAV, FileAccess.WRITE)
	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(36 + data.size())
	file.store_buffer("WAVEfmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)
	file.store_16(1)
	file.store_32(RATE)
	file.store_32(RATE * 2)
	file.store_16(2)
	file.store_16(16)
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(data.size())
	file.store_buffer(data)
	file.close()
	print("wrote ", OUT_WAV, ": ", _mix.size() / float(RATE), " s")


## Where his fretting hand is for a note, 0 (by the headstock) to 9 (by the body):
## the chugs and chords stay low on the neck, the solo climbs it.
func _hand_for(midi: int, kind: String) -> int:
	if kind in ["lead", "shred", "hold"]:
		return clampi(roundi((midi - 48) * 9.0 / 28.0), 0, 9)
	return clampi(roundi((midi - 40) * 4.0 / 10.0), 0, 9)


func _save_data(length: float) -> void:
	var frames := int(length / STEP)
	# How loud: the sound's strength in each frame, 0 to 9.
	var hop := int(STEP * RATE)
	var strength := PackedFloat32Array()
	var loudest := 0.0001
	for f in frames:
		var sum := 0.0
		for s in hop:
			var at := f * hop + s
			if at < _mix.size():
				sum += _mix[at] * _mix[at]
		strength.append(sqrt(sum / hop))
		loudest = maxf(loudest, strength[f])
	var loud := ""
	var onsets := ""
	var hand := ""
	var shred := ""
	var hold := ""
	var last_hand := 2
	for f in frames:
		var time := f * STEP
		loud += str(clampi(roundi(sqrt(strength[f] / loudest) * 9.0), 0, 9))
		var picked := false
		var playing: Array = []
		for note in _notes:
			if time <= note[0] and note[0] < time + STEP:
				picked = true
			if note[0] <= time and time < note[0] + note[1]:
				playing = note
		onsets += "1" if picked else "0"
		if not playing.is_empty():
			last_hand = _hand_for(playing[2], playing[3])
		hand += str(last_hand)
		shred += "1" if not playing.is_empty() and playing[3] == "shred" else "0"
		hold += "1" if not playing.is_empty() and playing[3] in ["hold", "ring"] else "0"
	var text := "extends RefCounted\n## Ronin's POWER RIFF, every %.2f seconds (made by tools/make_riff.gd along\n## with the music itself; don't edit by hand, change the notes there and run it).\n##   LOUD    how loud it is, 0 to 9\n##   ONSETS  1 where a note is picked\n##   HAND    where his fretting hand is: 0 (by the headstock) to 9 (by the body)\n##   SHRED   1 during fast runs\n##   HOLD    1 on long held notes\n\nconst STEP := %s\nconst LENGTH := %.2f\nconst LOUD := \"%s\"\nconst ONSETS := \"%s\"\nconst HAND := \"%s\"\nconst SHRED := \"%s\"\nconst HOLD := \"%s\"\n" % [STEP, str(STEP), length, loud, onsets, hand, shred, hold]
	var file := FileAccess.open(OUT_DATA, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("wrote ", OUT_DATA)
	print("LOUD  ", loud)
	print("HAND  ", hand)
