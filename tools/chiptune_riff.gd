extends SceneTree
## Turns Ronin's riff into 8-bit sound, to match the rest of the game's music.
## Reads the original recording (audio/sfx/ronin_riff_original.wav) and writes the
## version the game plays (audio/sfx/ronin_riff.wav). Same performance, same
## timing, so his animation stays in sync. Three steps, like an old sound chip:
##   1. Squarer: the wave is pushed toward a square wave (like a pulse channel).
##   2. Fewer samples: each one is held for a few steps (sample-and-hold), which
##      gives that gritty, low-fi crunch.
##   3. Fewer levels: every sample is rounded to one of 32 levels (5-bit).
##
## Run with:  godot --headless --path . --script tools/chiptune_riff.gd

const SOURCE := "res://audio/sfx/ronin_riff_original.wav"
const OUT := "res://audio/sfx/ronin_riff.wav"
## Samples per second of the result, how many in a row are held the same, and
## how many volume levels there are.
const RATE := 22050
const HOLD := 3
const LEVELS := 32
## How hard the wave is pushed toward square (higher is squarer).
const SQUARE := 3.5


func _initialize() -> void:
	var source := _read_wav(ProjectSettings.globalize_path(SOURCE))
	var source_rate: int = source[0]
	var mono: PackedFloat32Array = source[1]
	var count := int(mono.size() * float(RATE) / source_rate)
	# Loudest point, so the result uses the full range.
	var peak := 0.0001
	for v in mono:
		peak = maxf(peak, absf(v))
	var data := PackedByteArray()
	data.resize(count * 2)
	var held := 0.0
	for i in count:
		if i % HOLD == 0:
			var v: float = mono[mini(int(i * float(source_rate) / RATE), mono.size() - 1)] / peak
			v = tanh(v * SQUARE) / tanh(SQUARE)
			held = roundf(v * (LEVELS / 2 - 1)) / (LEVELS / 2 - 1)
		data.encode_s16(i * 2, int(clampf(held * 0.8, -1.0, 1.0) * 32767.0))
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
	print("wrote ", OUT, ": ", count / float(RATE), " s")
	quit()


## [sample rate, mono samples from -1 to 1] from a 16-bit PCM WAV file.
func _read_wav(path: String) -> Array:
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
