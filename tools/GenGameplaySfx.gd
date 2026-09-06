extends SceneTree
## 生成 6 个原创玩法音效（WAV，44.1 kHz、16 bit、mono、非循环）：
##   SFX_UI_Type_01  AVG 打字机逐字节拍（运行时随机 pitch 更自然）
##   SFX_Player_Step_01  玩家走格（软质闷步，运行时轻微变调防单调）
##   SFX_Food_Pick_01    取得花瓣（两音上行小铃 + 高音闪烁）
##   SFX_Game_Win_01     胜利（C 大调上行琶音 + 尾部和弦余韵）
##   SFX_Game_Lose_01    失败（柔和下行双音，不刺耳）
##   SFX_Mech_Grow_01    花丛生长（上扫噪声+渐亮 + 上行小铃闪烁）
## 动机：本机无法联网下载 CC0 素材，采用仓库既有 A-07「原创合成」惯例（同
## GenButtonSound.gd），风格与按钮音统一、无版权风险；后续若替换 CC0 素材，
## 直接覆盖同名 wav 并微调 SfxManager.tscn 的 volume_db 即可。
## 运行：godot --headless --path . -s res://tools/GenGameplaySfx.gd

const RATE := 44100
const OUT_DIR := "res://Audio/SFX"

## 白噪声状态（每音效独立重置，保证可复现）
var _noise_state := 1


func _initialize() -> void:
	var specs := [
		["SFX_UI_Type_01.wav", _synth_blip()],
		["SFX_Player_Step_01.wav", _synth_step()],
		["SFX_Food_Pick_01.wav", _synth_pick()],
		["SFX_Game_Win_01.wav", _synth_win()],
		["SFX_Game_Lose_01.wav", _synth_lose()],
		["SFX_Mech_Grow_01.wav", _synth_grow()],
	]
	for spec: Array in specs:
		var name := str(spec[0])
		var data: PackedByteArray = spec[1]
		var error := _save(name, data)
		if error != OK:
			push_error("生成音效 %s 失败：%s" % [name, error_string(error)])
		else:
			print("生成音效 OK: res://Audio/SFX/%s" % name)
	quit(0)


# ── 通用：铃音/软音叠加到缓冲区 ─────────────────────────────
## 带 1/2/2.96 泛音列的"小铃"（非谐波感），指数衰减；t0 起播
func _add_bell(buf: PackedFloat32Array, freq: float, amp: float, t0: float, decay: float) -> void:
	var n := buf.size()
	var start := int(t0 * RATE)
	# 尾部走到 e^-6≈0.25% 再收口，避免中途截断爆音
	var end := mini(n, start + int(6.0 / decay * RATE))
	if end <= start:
		return
	var ratios: Array[float] = [1.0, 2.0, 2.96]
	var weights: Array[float] = [1.0, 0.5, 0.22]
	var phases: Array[float] = [0.0, 0.0, 0.0]
	for i: int in range(start, end):
		var t := float(i - start) / RATE
		var attack := minf(t / 0.005, 1.0)
		var v := 0.0
		for k: int in 3:
			phases[k] += TAU * freq * ratios[k] / RATE
			v += sin(phases[k]) * weights[k] * exp(-decay * (1.0 + 0.55 * k) * t)
		buf[i] += v * attack * amp


## 柔和长音（正弦 + 弱二次谐波，可选下行滑音 0..slide 个半音比例）
func _add_soft(buf: PackedFloat32Array, freq: float, amp: float, t0: float, dur: float, decay: float, slide: float) -> void:
	var n := buf.size()
	var start := int(t0 * RATE)
	var end := mini(n, start + int(dur * RATE))
	if end <= start:
		return
	var phase := 0.0
	for i: int in range(start, end):
		var t := float(i - start) / RATE
		var f := freq * (1.0 - slide * (t / dur))
		phase += TAU * f / RATE
		var attack := minf(t / 0.012, 1.0)
		var env := attack * exp(-decay * t)
		var v := (sin(phase) + 0.22 * sin(phase * 2.0)) * env * amp
		buf[i] += v


func _white() -> float:
	_noise_state = (_noise_state * 1103515245 + 12345) & 0x7FFFFFFF
	return float(_noise_state) / 1073741824.0 - 1.0


## 归一化 + 编码 16 bit mono 字节（不叫 _finalize：避免覆盖 SceneTree._finalize 虚函数）
func _encode(buf: PackedFloat32Array) -> PackedByteArray:
	var peak := 0.0
	for v: float in buf:
		peak = maxf(peak, absf(v))
	var scale := 1.0
	if peak > 0.95:
		scale = 0.95 / peak
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i: int in buf.size():
		bytes.encode_s16(i * 2, clampi(int(buf[i] * scale * 32767.0), -32768, 32767))
	return bytes


func _save(file_name: String, data: PackedByteArray) -> Error:
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = RATE
	sound.data = data
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	return sound.save_to_wav(OUT_DIR.path_join(file_name))


# ── 6 个音效合成 ───────────────────────────────────────────
## 打字节拍：短促高频轻"嗒"（正弦 + 弱噪声起头），0.055s
func _synth_blip() -> PackedByteArray:
	var dur := 0.055
	var buf := PackedFloat32Array()
	buf.resize(int(RATE * dur))
	_noise_state = 101
	for i: int in buf.size():
		var t := float(i) / RATE
		var attack := minf(t / 0.0015, 1.0)
		var decay := exp(-t * 150.0)
		var body := sin(TAU * 1250.0 * t) + 0.3 * sin(TAU * 2500.0 * t)
		var tick := _white() * exp(-t * 620.0) * 0.25
		buf[i] = (body * decay + tick) * attack * 0.5
	return _encode(buf)


## 走格：低通噪声"噗" + 低频弱体震，软质不刺耳，0.12s
func _synth_step() -> PackedByteArray:
	var dur := 0.12
	var buf := PackedFloat32Array()
	buf.resize(int(RATE * dur))
	_noise_state = 202
	var lp := 0.0
	var lp_alpha := 1.0 - exp(-TAU * 850.0 / RATE)
	var phase := 0.0
	for i: int in buf.size():
		var t := float(i) / RATE
		var attack := minf(t / 0.003, 1.0)
		var env := attack * exp(-t * 32.0)
		lp += (_white() - lp) * lp_alpha
		phase += TAU * 135.0 / RATE
		var body := sin(phase) * exp(-t * 55.0) * 0.5
		buf[i] = (lp * 0.9 + body) * env * 0.55
	return _encode(buf)


## 取得花瓣：A5→E6 上行双铃 + 高八度闪烁，0.55s
func _synth_pick() -> PackedByteArray:
	var dur := 0.55
	var buf := PackedFloat32Array()
	buf.resize(int(RATE * dur))
	_add_bell(buf, 880.0, 0.95, 0.0, 14.0)
	_add_bell(buf, 1318.51, 0.9, 0.11, 17.0)
	_add_bell(buf, 2093.0, 0.28, 0.22, 26.0)
	return _encode(buf)


## 胜利：C 大调上行琶音 C5 E5 G5 C6 + 尾部和弦余韵，1.4s
func _synth_win() -> PackedByteArray:
	var dur := 1.4
	var buf := PackedFloat32Array()
	buf.resize(int(RATE * dur))
	var notes := [523.25, 659.25, 783.99, 1046.5]
	var amps := [0.8, 0.72, 0.85, 1.0]
	var decays := [11.0, 12.0, 13.0, 15.0]
	for k: int in notes.size():
		_add_bell(buf, notes[k], amps[k], 0.13 * k, decays[k])
	# 0.5s 起的长和弦余韵（低衰）
	var chord_amp := 0.3
	var phases: Array[float] = [0.0, 0.0, 0.0, 0.0]
	for i: int in buf.size():
		var trel := float(i) / RATE - 0.5
		if trel < 0.0:
			continue
		var env := minf(trel / 0.06, 1.0) * exp(-3.4 * trel)
		if env <= 0.001:
			break
		var v := 0.0
		for k: int in notes.size():
			phases[k] += TAU * notes[k] / RATE
			v += sin(phases[k])
		buf[i] += v * env * chord_amp
	return _encode(buf)


## 失败：D4→G3 柔和下行双音（轻微下滑、圆润），不刺耳，1.2s
func _synth_lose() -> PackedByteArray:
	var dur := 1.2
	var buf := PackedFloat32Array()
	buf.resize(int(RATE * dur))
	_add_soft(buf, 293.66, 0.85, 0.0, 0.42, 8.0, 0.05)   # D4
	_add_soft(buf, 196.0, 0.95, 0.4, 0.8, 6.5, 0.06)       # G3
	return _encode(buf)


## 花丛生长：噪声亮度上扫"呼" + 上行小铃闪烁，0.6s
func _synth_grow() -> PackedByteArray:
	var dur := 0.6
	var buf := PackedFloat32Array()
	buf.resize(int(RATE * dur))
	_noise_state = 404
	var lp := 0.0
	for i: int in buf.size():
		var t := float(i) / RATE
		var alpha := lerpf(0.1, 0.55, minf(t / dur, 1.0))
		lp += (_white() - lp) * alpha
		var env := minf(t / 0.2, 1.0) * exp(-t * 7.0)
		buf[i] = lp * env * 0.6
	_add_bell(buf, 523.25, 0.4, 0.0, 15.0)
	_add_bell(buf, 659.25, 0.4, 0.08, 15.0)
	_add_bell(buf, 783.99, 0.45, 0.16, 14.0)
	_add_bell(buf, 1046.5, 0.32, 0.24, 17.0)
	return _encode(buf)
