extends SceneTree
## Listens to Ronin's riff (the original recording, ronin_riff_original.wav) and
## writes scripts/ronin_riff.gd:
## for every 20th of a second, how loud it is, whether a new note was picked, and
## roughly how high the note is. His battle animation follows these, so his hands
## do what the music does.
##
## Run with:  godot --headless --path . --script tools/analyze_riff.gd

const SOURCE := "res://audio/sfx/ronin_riff_original.wav"
const OUT := "res://scripts/ronin_riff.gd"
const STEP := 0.05


func _initialize() -> void:
	var samples := _read_wav(ProjectSettings.globalize_path(SOURCE))
	var rate: int = samples[0]
	var mono: PackedFloat32Array = samples[1]
	var hop := int(rate * STEP)
	var frames := int(mono.size() / hop)
	var loud := PackedFloat32Array()
	loud.resize(frames)
	var peak := 0.0
	for f in frames:
		var sum := 0.0
		for i in hop:
			var v := mono[f * hop + i]
			sum += v * v
		loud[f] = sqrt(sum / hop)
		peak = maxf(peak, loud[f])
	# Pick attacks: the "edge" of the sound (how fast it changes) jumps when a string
	# is picked, even through heavy distortion. Measured every 10 ms.
	var small := int(rate * 0.01)
	var edges := PackedFloat32Array()
	for s in int(mono.size() / small):
		var sum := 0.0
		for i in range(1, small):
			var d := mono[s * small + i] - mono[s * small + i - 1]
			sum += d * d
		edges.append(sqrt(sum / small))
	var picked := PackedByteArray()
	picked.resize(frames)
	for s in range(6, edges.size()):
		var recent := 0.0
		for k in range(1, 6):
			recent += edges[s - k]
		recent /= 5.0
		if edges[s] > recent * 1.6 and edges[s] > 0.004:
			picked[mini(s / 5, frames - 1)] = 1
	var loud_digits := ""
	var onset_digits := ""
	var pitch_digits := ""
	for f in frames:
		var level := int(clampf(loud[f] / peak * 9.99, 0.0, 9.0))
		loud_digits += str(level)
		onset_digits += "1" if picked[f] == 1 and loud[f] > peak * 0.1 else "0"
		pitch_digits += _pitch_digit(mono, f * hop, rate, loud[f] > peak * 0.1)
	var text := "extends RefCounted\n## Ronin's riff, measured every %.2f seconds by tools/analyze_riff.gd (don't edit\n## by hand; run the tool again if the recording changes).\n##   LOUD    how loud it is, 0 to 9\n##   ONSETS  1 where a new note is picked\n##   PITCH   roughly how high the note is, 0 (low, near the headstock) to 9 (high,\n##           up by the body); \"-\" where it's too quiet to tell\n\nconst STEP := %s\nconst LENGTH := %.2f\nconst LOUD := \"%s\"\nconst ONSETS := \"%s\"\nconst PITCH := \"%s\"\n" % [STEP, str(STEP), frames * STEP, loud_digits, onset_digits, pitch_digits]
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("frames ", frames, " (", frames * STEP, " s)")
	print("LOUD   ", loud_digits)
	print("ONSETS ", onset_digits)
	print("PITCH  ", pitch_digits)
	quit()


## The note's pitch, from 0 to 9, by autocorrelation on a short window (or "-").
func _pitch_digit(mono: PackedFloat32Array, start: int, rate: int, loud_enough: bool) -> String:
	if not loud_enough:
		return "-"
	# Work at about 11 kHz: plenty for guitar notes, and much faster.
	var skip := maxi(1, int(rate / 11025))
	var window := 640
	var data := PackedFloat32Array()
	for i in window:
		var index := start + i * skip
		data.append(mono[index] if index < mono.size() else 0.0)
	var low_rate := float(rate) / skip
	# Smooth it a little (the distortion's fizz confuses the pitch).
	for i in range(window - 1, 2, -1):
		data[i] = (data[i] + data[i - 1] + data[i - 2] + data[i - 3]) * 0.25
	# YIN: how different the sound is from itself, shifted by each lag. The first
	# deep dip is the note's period (later dips are just the same note again).
	var min_lag := int(low_rate / 700.0)
	var max_lag := int(low_rate / 75.0)
	var diff := PackedFloat32Array()
	diff.resize(max_lag + 1)
	var running := 0.0
	var best_lag := 0
	var best := INF
	for lag in range(1, max_lag + 1):
		var sum := 0.0
		for i in window - max_lag:
			var d := data[i] - data[i + lag]
			sum += d * d
		running += sum
		var normalized := sum * lag / maxf(running, 0.000001)
		diff[lag] = normalized
		if lag < min_lag:
			continue
		if normalized < 0.2:
			best_lag = lag
			break
		if normalized < best:
			best = normalized
			best_lag = lag
	if best_lag == 0:
		return "-"
	var freq := low_rate / best_lag
	# 75 Hz to 700 Hz, on a log scale, as 0 to 9.
	var position := log(freq / 75.0) / log(700.0 / 75.0)
	return str(int(clampf(position * 9.99, 0.0, 9.0)))


## [sample rate, mono samples from -1 to 1] from a 16-bit PCM WAV file.
func _read_wav(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	file.seek(12)
	var channels := 1
	var rate := 44100
	var bits := 16
	var mono := PackedFloat32Array()
	while file.get_position() < file.get_length():
		var id := file.get_buffer(4).get_string_from_ascii()
		var size := file.get_32()
		if id == "fmt ":
			file.get_16()
			channels = file.get_16()
			rate = file.get_32()
			file.get_32()
			file.get_16()
			bits = file.get_16()
			file.seek(file.get_position() + size - 16)
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
	print("wav: ", rate, " Hz, ", channels, " channels, ", bits, " bit, ", mono.size() / float(rate), " s")
	return [rate, mono]
