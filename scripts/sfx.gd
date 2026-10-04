class_name Sfx
extends RefCounted
## Makes the game's sound effects out of simple waves, like old game consoles did.
## Nothing is loaded from files: each sound is a list of notes turned into audio.

const RATE := 22050


## Every sound effect in the game, by name.
static func make_all() -> Dictionary:
	return {
		"text": tone([520], 0.035, 0.12),
		"voice": tone([300], 0.045, 0.14),
		"move": tone([900], 0.035, 0.15),
		"select": tone([700, 1050], 0.045, 0.18),
		"hurt": slide(420, 110, 0.2, 0.3),
		"hit": slide(700, 180, 0.14, 0.28),
		"miss": slide(300, 250, 0.1, 0.15),
		"spare": tone([523, 659, 784, 1046], 0.07, 0.2),
		"heal": tone([660, 880, 990], 0.06, 0.2),
		"item": tone([880, 1320], 0.06, 0.18),
		"save": tone([784, 988, 1175, 1568], 0.09, 0.2),
		"encounter": tone([880, 0, 880, 0, 880], 0.05, 0.22),
		"crack": noise(0.12, 0.3),
		"shatter": noise(0.35, 0.3),
		"fragment": slide(120, 60, 0.6, 0.3),
		"slash": slide(1600, 250, 0.14, 0.22),
	}


## Plays the notes one after another (0 means a short silence).
## `volume` is 0 to 1. Uses a square wave, the classic "chiptune" sound.
static func tone(notes: Array, note_length: float, volume: float) -> AudioStreamWAV:
	var samples_per_note := int(note_length * RATE)
	var data := PackedByteArray()
	data.resize(samples_per_note * notes.size() * 2)
	var i := 0
	for freq in notes:
		for s in samples_per_note:
			var value := 0.0
			if freq > 0:
				var phase := fmod(float(s) * freq / RATE, 1.0)
				value = 1.0 if phase < 0.5 else -1.0
			# Fade out the end of each note so it doesn't click.
			var fade := minf(1.0, float(samples_per_note - s) / (samples_per_note * 0.3))
			data.encode_s16(i * 2, int(value * volume * fade * 32767.0))
			i += 1
	return _wav(data)


## One note that slides from `from_freq` to `to_freq` (good for hits and hurts).
static func slide(from_freq: float, to_freq: float, length: float, volume: float) -> AudioStreamWAV:
	var count := int(length * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for s in count:
		var t := float(s) / count
		phase = fmod(phase + lerpf(from_freq, to_freq, t) / RATE, 1.0)
		var value := 1.0 if phase < 0.5 else -1.0
		data.encode_s16(s * 2, int(value * volume * (1.0 - t) * 32767.0))
	return _wav(data)


## Random crackle (for breaking things).
static func noise(length: float, volume: float) -> AudioStreamWAV:
	var count := int(length * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var held := 0.0
	for s in count:
		# Changing value only every few samples makes a crunchier sound.
		if s % 6 == 0:
			held = rng.randf_range(-1.0, 1.0)
		var t := float(s) / count
		data.encode_s16(s * 2, int(held * volume * (1.0 - t) * 32767.0))
	return _wav(data)


static func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
