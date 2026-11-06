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
const GAIN: Dictionary = {&"boom": -3.0, &"place": -4.0, &"step": -14.0, &"pop": -5.0}

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
	var m: AudioStreamWAV = load("res://audio/music/meadow.wav")
	if m != null:
		m.loop_mode = AudioStreamWAV.LOOP_FORWARD
		m.loop_begin = 0
		m.loop_end = int(m.get_length() * m.mix_rate)
		_music.stream = m


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


## A soft cartoon explosion: a thump plus low-passed noise that fades.
func _make_boom() -> AudioStreamWAV:
	var n: int = int(RATE * 0.75)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp: float = 0.0
	var phase: float = 0.0
	for i in n:
		var t: float = float(i) / RATE
		var env: float = exp(-t * 6.0)
		lp += (randf_range(-1.0, 1.0) - lp) * (0.08 + 0.25 * exp(-t * 10.0))
		phase += TAU * (110.0 * exp(-t * 4.0) + 40.0) / RATE
		out[i] = (lp * 1.6 + sin(phase) * 0.7 * exp(-t * 9.0)) * env
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
