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
		"honk": tone([392, 0, 392], 0.12, 0.25),
		"door": noise(0.06, 0.25),
		# A shop door's bell: ding-dong.
		"chime": tone([1318, 1046], 0.16, 0.14),
		"punch": slide(260, 70, 0.09, 0.32),
		"thud": slide(140, 40, 0.25, 0.35),
		"ping": slide(1400, 1100, 0.18, 0.12),
		"zap": noise(0.18, 0.28),
		"stinger": stinger(),
		"engine": engine(),
		"brakes": slide(1900, 1500, 0.4, 0.07),
		"alert": tone([784, 1175, 1568, 2093], 0.04, 0.24),
		"shing": slide(2600, 3400, 0.09, 0.13),
		"bonk": slide(520, 140, 0.16, 0.38),
		# The sound a hit makes, by attack style.
		"claw_hit": slide(2400, 450, 0.16, 0.26),
		"punch_hit": slide(240, 50, 0.2, 0.42),
		"file_hit": tone([2349, 3136, 2794], 0.05, 0.17),
		"squeak": slide(800, 1600, 0.1, 0.18),
		"black_flash": black_flash(),
	}


## A dramatic hit, like a door slamming open: a low, buzzy chord that rings out,
## with a crack of noise on top. (For "HOLD IT!")
static func stinger() -> AudioStreamWAV:
	var length := 1.1
	var count := int(length * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var notes := [82.4, 123.5, 164.8, 196.0, 246.9]   # E minor, low and wide
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var phases := [0.0, 0.0, 0.0, 0.0, 0.0]
	for s in count:
		var t := float(s) / RATE
		var value := 0.0
		for n in notes.size():
			phases[n] = fmod(phases[n] + notes[n] / RATE, 1.0)
			value += (phases[n] * 2.0 - 1.0) * 0.22 + (1.0 if phases[n] < 0.5 else -1.0) * 0.1
		# The hit: a burst of noise right at the start.
		if t < 0.08:
			value += rng.randf_range(-1.0, 1.0) * (1.0 - t / 0.08) * 0.9
		var envelope := minf(1.0, t / 0.004) * pow(1.0 - t / length, 1.6)
		data.encode_s16(s * 2, int(clampf(value * envelope * 0.55, -1.0, 1.0) * 32767.0))
	return _wav(data)


## BLACK FLASH: a split-second of silence, a sharp electric crack, then a deep
## boom with a distorted ring that tears off at the end.
static func black_flash() -> AudioStreamWAV:
	var length := 1.3
	var count := int(length * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	var boom_phase := 0.0
	var ring_phase := 0.0
	var held := 0.0
	for s in count:
		var t := float(s) / RATE
		var value := 0.0
		# The crack: crunchy noise that crackles on and off.
		if t < 0.25:
			if s % 3 == 0:
				held = rng.randf_range(-1.0, 1.0)
			var flicker := 1.0 if int(t * 90.0) % 3 != 2 else 0.2
			value += held * flicker * (1.0 - t / 0.25)
		# The boom: a pitch that drops from 160 Hz to 35 Hz.
		boom_phase = fmod(boom_phase + lerpf(160.0, 35.0, minf(t / 0.6, 1.0)) / RATE, 1.0)
		value += sin(boom_phase * TAU) * 1.2 * pow(maxf(0.0, 1.0 - t / 1.1), 1.5)
		# The ring: a high, wobbly tone, clipped hard for distortion.
		ring_phase = fmod(ring_phase + (1240.0 + sin(t * 40.0) * 60.0) / RATE, 1.0)
		value += clampf(sin(ring_phase * TAU) * 3.0, -1.0, 1.0) * 0.18 * pow(maxf(0.0, 1.0 - t / length), 2.0)
		data.encode_s16(s * 2, int(clampf(value * 0.5, -1.0, 1.0) * 32767.0))
	return _wav(data)



## A car engine: a low, rumbling buzz that revs up and settles.
static func engine() -> AudioStreamWAV:
	var length := 1.6
	var count := int(length * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for s in count:
		var t := float(s) / count
		var freq := 48.0 + 34.0 * sin(t * PI) + 4.0 * sin(t * 90.0)
		phase = fmod(phase + freq / RATE, 1.0)
		var value := (phase * 2.0 - 1.0) * 0.7 + rng.randf_range(-1.0, 1.0) * 0.15
		var envelope := minf(1.0, t * 8.0) * minf(1.0, (1.0 - t) * 5.0)
		data.encode_s16(s * 2, int(value * envelope * 0.28 * 32767.0))
	return _wav(data)



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
