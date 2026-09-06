extends SceneTree
## 生成原创短促弹性按钮音：衰减正弦、下滑音高和轻微回弹。

func _initialize() -> void:
	const RATE: int = 44100
	const DURATION: float = 0.22
	var samples := PackedByteArray()
	samples.resize(int(RATE * DURATION) * 2)
	var phase: float = 0.0
	for i: int in range(samples.size() / 2):
		var t: float = float(i) / RATE
		var frequency: float = 360.0 + 500.0 * exp(-t * 45.0) + 75.0 * sin(t * 95.0) * exp(-t * 16.0)
		phase += TAU * frequency / RATE
		var envelope: float = minf(t / 0.004, 1.0) * exp(-t * 22.0) * clampf((DURATION - t) / 0.025, 0.0, 1.0)
		var sample: float = (sin(phase) + 0.12 * sin(phase * 2.0)) * envelope * 0.65
		samples.encode_s16(i * 2, int(sample * 32767.0))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = RATE
	sound.data = samples
	DirAccess.make_dir_recursive_absolute("res://Audio/SFX")
	var error: Error = sound.save_to_wav("res://Audio/SFX/SFX_UI_Bounce_01.wav")
	if error != OK:
		push_error("生成按钮音效失败：%s" % error_string(error))
	quit(0 if error == OK else 1)
