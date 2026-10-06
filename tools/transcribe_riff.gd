extends SceneTree
## Rebuilds Ronin's riff as 8-bit music, to match the rest of the game.
##
## The notes come from a clean acoustic take of the riff (the audio of a video of it
## being played): each pluck is found, and its pitch measured. Then the notes are
## moved onto the timeline of the electric recording (by matching the two takes'
## loudness over time, like tools/riff_hands.gd), so Ronin's animation stays in
## sync. Finally they're played by a square-wave lead with a soft triangle bass an
## octave below, plucked (a quick attack and a decay), and saved as the sound the
## game plays (audio/sfx/ronin_riff.wav).
##
## Run with (the acoustic take's audio as a WAV):
##   godot --headless --path . --script tools/transcribe_riff.gd -- <take.wav>

const RECORDING := "res://audio/sfx/ronin_riff_original.wav"
const OUT := "res://audio/sfx/ronin_riff.wav"
const RATE := 22050
const STEP := 0.05

var _hands: Object


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Give the acoustic take's audio as a WAV file.")
		quit(1)
		return
	# (riff_hands.gd already knows how to read WAVs, make loudness curves and match them up.)
	_hands = load("res://tools/riff_hands.gd").new()
	var take := _read(args[0])
	var take_rate: int = take[0]
	var mono: PackedFloat32Array = take[1]
	var notes := _find_notes(mono, take_rate)
	# Onto the recording's timeline.
	var recording_curve: PackedFloat32Array = _hands._envelope(ProjectSettings.globalize_path(RECORDING))
	var take_curve: PackedFloat32Array = _hands._envelope(args[0])
	var path: Array = _hands._warp(recording_curve, take_curve)
	var recording_time_of := PackedFloat32Array()
	recording_time_of.resize(take_curve.size())
	for pair in path:
		recording_time_of[pair[1]] = pair[0] * STEP
	for note in notes:
		var frame := clampi(int(note[0] / STEP), 0, take_curve.size() - 1)
		note[0] = recording_time_of[frame] + fmod(note[0], STEP)
	# One note at a time: in order, ones that landed on top of each other merged,
	# and each one lasting until the next.
	notes.sort_custom(func(a, b): return a[0] < b[0])
	var kept: Array = []
	for note in notes:
		if kept.is_empty() or note[0] - kept[-1][0] >= 0.07:
			kept.append(note)
	for k in kept.size():
		var next: float = kept[k + 1][0] if k + 1 < kept.size() else kept[k][0] + 0.5
		kept[k][1] = minf(next - kept[k][0], 0.6)
	notes = kept
	var line := ""
	for note in notes:
		line += "%.2f:%d " % [note[0], note[2]]
	print(notes.size(), " notes: ", line)
	_render(notes, recording_curve.size() * STEP)
	quit()


## The notes in a clean take: [start time, length, MIDI note number].
func _find_notes(mono: PackedFloat32Array, rate: int) -> Array:
	# Plucks: sudden jumps in the "edge" of the sound, every 10 ms.
	var small := int(rate * 0.01)
	var edges := PackedFloat32Array()
	for s in int(mono.size() / small):
		var sum := 0.0
		for i in range(1, small):
			var d := mono[s * small + i] - mono[s * small + i - 1]
			sum += d * d
		edges.append(sqrt(sum / small))
	var loudest := 0.0001
	for e in edges:
		loudest = maxf(loudest, e)
	var starts: Array = []
	var last := -100
	for s in range(3, edges.size()):
		var before := (edges[s - 1] + edges[s - 2] + edges[s - 3]) / 3.0
		if edges[s] > before * 1.3 and edges[s] > loudest * 0.04 and s - last >= 6:
			starts.append(s * 0.01)
			last = s
	print("plucks found: ", starts.size())
	var notes: Array = []
	var previous := 40
	for k in starts.size():
		var start: float = starts[k]
		var end: float = starts[k + 1] if k + 1 < starts.size() else start + 0.4
		var midi := previous
		var pitch := _pitch(mono, int((start + 0.03) * rate), rate)
		if pitch > 0.0:
			midi = _tidy(roundi(69.0 + 12.0 * log(pitch / 440.0) / log(2.0)))
		previous = midi
		notes.append([start, minf(end - start, 0.6), midi])
	return notes


## Keeps it simple: every note is moved (by whole octaves) into the low octave the
## riff lives in (E2 up to D#3), then onto the nearest note of E minor pentatonic
## (E G A B D), so the guesses that came out an octave or a half step off can't
## clash.
func _tidy(midi: int) -> int:
	while midi < 40:
		midi += 12
	while midi > 51:
		midi -= 12
	for offset in [0, -1, 1, -2, 2]:
		if (midi + offset) % 12 in [4, 7, 9, 11, 2]:
			return midi + offset
	return midi


## A note's frequency (YIN), or 0 if it can't tell.
func _pitch(mono: PackedFloat32Array, start: int, rate: int) -> float:
	var window := 2048
	var max_lag := int(rate / 70.0)
	var min_lag := int(rate / 900.0)
	if start + window + max_lag >= mono.size():
		return 0.0
	var running := 0.0
	var best := INF
	var best_lag := 0
	for lag in range(1, max_lag + 1):
		var sum := 0.0
		for i in range(0, window, 2):
			var d := mono[start + i] - mono[start + i + lag]
			sum += d * d
		running += sum
		var normalized := sum * lag / maxf(running, 0.000001)
		if lag < min_lag:
			continue
		if normalized < 0.3:
			# The first deep dip: walk down to the bottom of it.
			best_lag = lag
			break
		if normalized < best:
			best = normalized
			best_lag = lag
	if best_lag == 0 or (best > 0.6 and best != INF):
		return 0.0
	return float(rate) / best_lag


## Plays the notes: a 25% pulse lead an octave up (the low notes are too muddy\n## on a square wave), plucked, with a soft triangle bass on the note itself.
func _render(notes: Array, length: float) -> void:
	var count := int(length * RATE)
	var mix := PackedFloat32Array()
	mix.resize(count)
	for note in notes:
		var freq := 440.0 * pow(2.0, (note[2] - 69) / 12.0)
		var start := int(note[0] * RATE)
		var size := int((note[1] + 0.08) * RATE)
		var phase := 0.0
		var low := 0.0
		for i in size:
			var at := start + i
			if at < 0 or at >= count:
				continue
			var t := float(i) / RATE
			phase = fmod(phase + freq * 2.0 / RATE, 1.0)
			low = fmod(low + freq / RATE, 1.0)
			var pulse := 1.0 if phase < 0.25 else -1.0
			var triangle := 4.0 * absf(low - 0.5) - 1.0
			# A pluck: snaps on, settles, fades at the end of the note.
			var env := minf(1.0, t / 0.004) * lerpf(1.0, 0.55, minf(1.0, t / 0.12)) * minf(1.0, float(size - i) / (0.03 * RATE))
			mix[at] += (pulse * 0.18 + triangle * 0.3) * env
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		data.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 30000.0))
	var file := FileAccess.open(ProjectSettings.globalize_path(OUT), FileAccess.WRITE)
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
	print("wrote ", OUT)


func _read(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	file.seek(12)
	var channels := 1
	var rate := 44100
	var mono := PackedFloat32Array()
	while file.get_position() < file.get_length():
		var id := file.get_buffer(4).get_string_from_ascii()
		var size := file.get_32()
		if id == "fmt ":
			file.get_16()
			channels = file.get_16()
			rate = file.get_32()
			file.seek(file.get_position() + size - 8)
		elif id == "data":
			var bytes := file.get_buffer(size)
			var count := size / (2 * channels)
			mono.resize(count)
			for i in count:
				var total := 0.0
				for c in channels:
					total += bytes.decode_s16((i * channels + c) * 2) / 32768.0
				mono[i] = total / channels
			break
		else:
			file.seek(file.get_position() + size + (size % 2))
	return [rate, mono]
