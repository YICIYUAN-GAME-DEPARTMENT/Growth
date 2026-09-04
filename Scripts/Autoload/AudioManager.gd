extends Node
## ============================================================================
## AudioManager  —  音效/音乐统一播放 (Autoload)
## ----------------------------------------------------------------------------
## 设计：一个常驻 AudioStreamPlayer 跑 BGM；一个对象池复用跑 SFX，避免每次
## new。总线名遵循 project.godot 的 Audio Bus（默认 Master/Music/SFX）。
## ============================================================================

const SFX_POOL_SIZE := 8
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_sfx_pool.append(p)


# ── 音效 ───────────────────────────────────────────────────────
func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.play()


# ── 音乐 ───────────────────────────────────────────────────────
func play_music(stream: AudioStream, fade_sec: float = 0.5) -> void:
	if stream == null:
		return
	_music_player.stream = stream
	_music_player.volume_db = -40.0
	_music_player.play()
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", 0.0, fade_sec)


func stop_music(fade_sec: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -40.0, fade_sec)
	tween.tween_callback(_music_player.stop)
