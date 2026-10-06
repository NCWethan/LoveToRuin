extends SceneTree
## Where Ronin's fretting hand goes during his riff, taken from a video of the riff
## being played for real (a different take from the recording he plays).
##
## HAND_IN_VIDEO is where the fretting hand was in the video every quarter second,
## measured by eye from the frames: how far up the neck from the nut, 0.0 (at the
## nut) to 1.0 (where the neck meets the body). To line the video's take up with
## the recording, both are turned into loudness curves and matched up with dynamic
## time warping (stretching and squeezing the video's timeline until the two
## curves agree), so each moment in the recording gets the hand position from the
## same moment of the video.
##
## Writes scripts/ronin_hands.gd. Run with (the video's audio as a WAV):
##   godot --headless --path . --script tools/riff_hands.gd -- <video audio.wav>

const RIFF := "res://audio/sfx/ronin_riff.wav"
const OUT := "res://scripts/ronin_hands.gd"
const STEP := 0.05
const VIDEO_STEP := 0.25
const HAND_IN_VIDEO := [
	0.32, 0.34, 0.34, 0.26, 0.32, 0.32, 0.29, 0.29, 0.47, 0.45, 0.5, 0.5, 0.6, 0.63, 0.63, 0.66,
	0.66, 0.66, 0.66, 0.63, 0.66, 0.68, 0.68, 0.66, 0.66, 0.66, 0.66, 0.42, 0.32, 0.32, 0.34, 0.24,
	0.66, 0.68, 0.66, 0.34, 0.63, 0.63, 0.55, 0.45, 0.33, 0.27, 0.33, 0.24, 0.55, 0.48, 0.45, 0.21,
	0.27, 0.3, 0.3, 0.33, 0.47, 0.42, 0.4, 0.34, 0.45, 0.39, 0.36, 0.33, 0.45, 0.45, 0.42, 0.34,
	0.53, 0.5, 0.5, 0.45, 0.6, 0.66, 0.32, 0.34, 0.6, 0.6,
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Give the video's audio as a WAV file.")
		quit(1)
		return
	var riff := _envelope(ProjectSettings.globalize_path(RIFF))
	var take := _envelope(args[0])
	var path := _warp(riff, take)
	# For every moment of the recording: the matching moment of the video's take.
	var match_for := PackedInt32Array()
	match_for.resize(riff.size())
	for pair in path:
		match_for[pair[0]] = pair[1]
	var hand := ""
	var still := ""
	for f in riff.size():
		var take_time := match_for[f] * STEP
		hand += str(_digit(_hand_at(take_time)))
		# Holding still: the hand barely moves across this moment.
		var spread := absf(_hand_at(take_time - 0.3) - _hand_at(take_time + 0.3))
		still += "1" if spread < 0.04 else "0"
	var text := "extends RefCounted\n## Ronin's fretting hand during his riff, every %.2f seconds of the recording,\n## from a video of the riff being played (made by tools/riff_hands.gd; run it\n## again if the recording or the video changes).\n##   HAND   how far up the neck: 0 (by the headstock) to 9 (by the body)\n##   STILL  1 where the hand holds its place\n\nconst STEP := %s\nconst HAND := \"%s\"\nconst STILL := \"%s\"\n" % [STEP, str(STEP), hand, still]
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("recording ", riff.size(), " frames, video take ", take.size(), " frames")
	print("HAND  ", hand)
	print("STILL ", still)
	quit()


## The hand position in the video at `time` (in between the measurements, it
## slides smoothly from one to the next).
func _hand_at(time: float) -> float:
	var at := clampf(time / VIDEO_STEP, 0.0, HAND_IN_VIDEO.size() - 1.0)
	var low := int(at)
	var high := mini(low + 1, HAND_IN_VIDEO.size() - 1)
	return lerpf(HAND_IN_VIDEO[low], HAND_IN_VIDEO[high], at - low)


## 0.2 to 0.7 of the way up the neck (the range actually used) as 0 to 9.
func _digit(position: float) -> int:
	return clampi(roundi((position - 0.2) / 0.5 * 9.0), 0, 9)


## Matches two loudness curves up in time (dynamic time warping). Returns the pairs
## [frame of a, frame of b] along the best match, start to end.
func _warp(a: PackedFloat32Array, b: PackedFloat32Array) -> Array:
	var n := a.size()
	var m := b.size()
	var cost := PackedFloat32Array()
	cost.resize((n + 1) * (m + 1))
	cost.fill(INF)
	cost[0] = 0.0
	for i in range(1, n + 1):
		for j in range(1, m + 1):
			var here := absf(a[i - 1] - b[j - 1])
			var best := minf(cost[(i - 1) * (m + 1) + j - 1], minf(cost[(i - 1) * (m + 1) + j], cost[i * (m + 1) + j - 1]))
			cost[i * (m + 1) + j] = here + best
	# Walk back from the end along the cheapest route.
	var path: Array = []
	var i := n
	var j := m
	while i > 0 and j > 0:
		path.push_front([i - 1, j - 1])
		var diagonal := cost[(i - 1) * (m + 1) + j - 1]
		var up := cost[(i - 1) * (m + 1) + j]
		var left := cost[i * (m + 1) + j - 1]
		if diagonal <= up and diagonal <= left:
			i -= 1
			j -= 1
		elif up <= left:
			i -= 1
		else:
			j -= 1
	return path


## A loudness curve, every STEP seconds, scaled so its average is 0 and its spread 1
## (so a quiet acoustic take and a loud electric one can be compared).
func _envelope(path: String) -> PackedFloat32Array:
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
			for s in count:
				var total := 0.0
				for c in channels:
					total += bytes.decode_s16((s * channels + c) * 2) / 32768.0
				mono[s] = total / channels
			break
		else:
			file.seek(file.get_position() + size + (size % 2))
	var hop := int(rate * STEP)
	var curve := PackedFloat32Array()
	for f in int(mono.size() / hop):
		var sum := 0.0
		for s in hop:
			var v := mono[f * hop + s]
			sum += v * v
		curve.append(log(sqrt(sum / hop) + 0.0001))
	var mean := 0.0
	for v in curve:
		mean += v
	mean /= curve.size()
	var spread := 0.0
	for v in curve:
		spread += (v - mean) * (v - mean)
	spread = sqrt(spread / curve.size())
	for k in curve.size():
		curve[k] = (curve[k] - mean) / maxf(spread, 0.0001)
	return curve
