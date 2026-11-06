extends Node
## Sound effects and music. A few cues are recorded files; the rest are
## synthesised here at start-up (no outside audio), so there is nothing to
## license. Call Sfx.play(&"boom").

const RATE: int = 22050
const VOICES: int = 12

const FILES: Dictionary = {
	&"pickup": "res://audio/sfx/pickup.wav",
	&"click": "res://audio/sfx/ui_click.wav",
	&"win": "res://audio/sfx/level_complete.wav",
	&"step": "res://audio/sfx/step.wav",
	&"error": "res://audio/sfx/error.wav",
	&"whoosh": "res://audio/sfx/whoosh.wav",
	&"teleport": "res://audio/sfx/bounce.wav",
	&"snap": "res://audio/sfx/snap.wav",
}
const GAIN: Dictionary = {&"crunch": -1.0, &"boom": -3.0, &"place": -4.0, &"step": -14.0, &"pop": -5.0}

var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _last_play: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for cue: StringName in FILES:
		var s: AudioStream = load(FILES[cue])
		if s != null:
			_streams[cue] = s
	_streams[&"boom"] = _make_boom()
	_streams[&"crunch"] = _make_crunch()
	_streams[&"place"] = _make_tone([520.0, 380.0], 0.09, 0.5, true)
	_streams[&"pop"] = _make_tone([300.0, 900.0], 0.16, 0.45, false)
	_streams[&"hurt"] = _make_tone([620.0, 140.0], 0.55, 0.5, false)
	_streams[&"kick"] = _make_tone([180.0, 90.0], 0.1, 0.6, true)
	_streams[&"gate"] = _make_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.09)
	_streams[&"boss_hit"] = _make_tone([160.0, 60.0], 0.35, 0.7, true)
	_streams[&"fail"] = _make_arpeggio([392.0, 329.6, 261.6, 196.0], 0.16)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_voices.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -10.0
	add_child(_music)
	track(DEFAULT_TRACK)


const DEFAULT_TRACK := "res://audio/music/sorbet_skies.wav"
var _track: String = ""


## Switches the music to a looping .wav ("" for the default tune). Keeps
## playing if it was playing; does nothing when that track is already on.
func track(path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		path = DEFAULT_TRACK
	if path == _track:
		return
	var m: AudioStreamWAV = load(path)
	if m == null:
		return
	_track = path
	m.loop_mode = AudioStreamWAV.LOOP_FORWARD
	m.loop_begin = 0
	m.loop_end = int(m.get_length() * m.mix_rate)
	var was: bool = _music.playing
	_music.stream = m
	if was:
		_music.play()


static func play(cue: StringName, pitch_jitter: float = 0.06) -> void:
	var s: Node = Engine.get_main_loop().root.get_node_or_null(^"/root/Sfx")
	if s != null:
		s._play(cue, pitch_jitter)


func music(on: bool) -> void:
	if on and Save.music_on:
		if not _music.playing:
			_music.play()
	else:
		_music.stop()


func _play(cue: StringName, jitter: float) -> void:
	if not Save.sound_on or not _streams.has(cue):
		return
	var now: int = Time.get_ticks_msec()
	if now - int(_last_play.get(cue, -1000)) < 30:
		return
	_last_play[cue] = now
	for p: AudioStreamPlayer in _voices:
		if not p.playing:
			p.stream = _streams[cue]
			p.volume_db = GAIN.get(cue, -2.0)
			p.pitch_scale = 1.0 + randf_range(-jitter, jitter)
			p.play()
			return


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	return w


## A cartoon explosion: a sharp crack up front, a deep thump and
## low-passed rumble that fades.
func _make_boom() -> AudioStreamWAV:
	var n: int = int(RATE * 0.8)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp: float = 0.0
	var phase: float = 0.0
	for i in n:
		var t: float = float(i) / RATE
		var env: float = exp(-t * 5.5)
		var white: float = randf_range(-1.0, 1.0)
		lp += (white - lp) * (0.07 + 0.3 * exp(-t * 12.0))
		phase += TAU * (140.0 * exp(-t * 7.0) + 38.0) / RATE
		var crack: float = white * exp(-t * 90.0) * 0.9
		var thump: float = sin(phase) * 1.0 * exp(-t * 7.0)
		out[i] = (lp * 1.5 + thump) * env + crack
	return _wav(out)


## Wood giving way: three quick knocks of resonant, filtered noise.
func _make_crunch() -> AudioStreamWAV:
	var n: int = int(RATE * 0.32)
	var out := PackedFloat32Array()
	out.resize(n)
	for hit: Array in [[0.0, 520.0, 1.0], [0.028, 760.0, 0.7], [0.07, 380.0, 0.55]]:
		var start: int = int(RATE * float(hit[0]))
		# A two-pole resonator rung by a burst of noise.
		var w: float = TAU * float(hit[1]) / RATE
		var r: float = 0.985
		var a1: float = 2.0 * r * cos(w)
		var a2: float = -r * r
		var y1: float = 0.0
		var y2: float = 0.0
		for i in range(start, n):
			var t: float = float(i - start) / RATE
			var x: float = randf_range(-1.0, 1.0) * exp(-t * 60.0)
			var y: float = x + a1 * y1 + a2 * y2
			y2 = y1
			y1 = y
			out[i] += y * 0.09 * float(hit[2]) * exp(-t * 18.0)
	for i in n:
		var t2: float = float(i) / RATE
		out[i] += sin(TAU * 170.0 * t2) * exp(-t2 * 30.0) * 0.4
	var peak: float = 0.0
	for v: float in out:
		peak = maxf(peak, absf(v))
	if peak > 0.0:
		for i in n:
			out[i] *= 0.85 / peak
	return _wav(out)


## A gliding tone from freqs[0] to freqs[1]; [param square] gives a chunkier timbre.
func _make_tone(freqs: Array, length: float, vol: float, square: bool) -> AudioStreamWAV:
	var n: int = int(RATE * length)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	for i in n:
		var u: float = float(i) / n
		var f: float = lerpf(freqs[0], freqs[1], u)
		phase += TAU * f / RATE
		var v: float = sin(phase)
		if square:
			v = clampf(v * 3.0, -1.0, 1.0)
		var env: float = minf(u * 40.0, 1.0) * (1.0 - u) * (1.0 - u)
		out[i] = v * env * vol
	return _wav(out)


func _make_arpeggio(freqs: Array, step: float) -> AudioStreamWAV:
	var n: int = int(RATE * (step * freqs.size() + 0.3))
	var out := PackedFloat32Array()
	out.resize(n)
	for k in freqs.size():
		var start: int = int(RATE * step * k)
		var phase: float = 0.0
		for i in range(start, n):
			var t: float = float(i - start) / RATE
			phase += TAU * float(freqs[k]) / RATE
			out[i] += (sin(phase) + 0.3 * sin(phase * 2.0)) * exp(-t * 7.0) * 0.3
	return _wav(out)
