extends Node
## ============================================================================
## SfxManager — 全局玩法音效 (Autoload)
## ----------------------------------------------------------------------------
## 职责：
##   1. 订阅 EventManager 玩法信号 → 自动播放对应音效（走格/吃花瓣/花丛生长/胜负）
##   2. 暴露 play_text_blip() 供 DialogueOverlay 打字机逐字调用（AVG 文字浮现）
## 每个音效 = 场景（Scenes/Audio/SfxManager.tscn）里一个 AudioStreamPlayer 子节点，
## 音量/复读在场景中调整；波形由 tools/GenGameplaySfx.gd 原创合成
## （44.1 kHz / 16 bit / mono / 非循环），替换素材=覆盖同名 wav 即可，代码不动。
## 接入方式：只订阅信号+播放，不改任何玩法逻辑（架构说明 §3「audio 订阅」落地）。
## ============================================================================

const STREAM_PATHS := {
	"Type": "res://Audio/SFX/SFX_UI_Type_01.wav",
	"Step": "res://Audio/SFX/SFX_Player_Step_01.wav",
	"Pick": "res://Audio/SFX/SFX_Food_Pick_01.wav",
	"Win": "res://Audio/SFX/SFX_Game_Win_01.wav",
	"Lose": "res://Audio/SFX/SFX_Game_Lose_01.wav",
	"Grow": "res://Audio/SFX/SFX_Mech_Grow_01.wav",
}

## 节点名 -> AudioStreamPlayer（_ready 按场景子节点装配；素材缺失=静默跳过不崩）
var _players: Dictionary = {}


func _ready() -> void:
	for child: Node in get_children():
		var player := child as AudioStreamPlayer
		if player == null:
			continue
		var path := str(STREAM_PATHS.get(player.name, ""))
		if path.is_empty():
			continue
		player.stream = load(path)
		_players[player.name] = player
	_subscribe_events()


func _subscribe_events() -> void:
	EventManager.player_moved.connect(_play_step.unbind(1))       # 每次有效移动/截断
	EventManager.food_eaten.connect(_play_pick.unbind(1))         # 吃到花瓣
	EventManager.mechanism_grew.connect(_play_grow.unbind(1))     # 花丛全体生长一次
	EventManager.level_cleared.connect(_play_win.unbind(2))       # 胜利
	EventManager.level_failed.connect(_play_lose.unbind(1))       # 失败


## AVG 打字机逐字节拍（随机轻微变调避免机械感）；由 DialogueOverlay 每帧新字符调用
func play_text_blip() -> void:
	var p := _players.get("Type") as AudioStreamPlayer
	if p == null or p.stream == null:
		return
	p.pitch_scale = randf_range(0.9, 1.18)
	p.play()


func _play_step() -> void:
	var p := _players.get("Step") as AudioStreamPlayer
	if p == null or p.stream == null:
		return
	p.pitch_scale = randf_range(0.95, 1.06)  # 轻微变调，连走不单调
	p.play()


func _play_pick() -> void:
	var p := _players.get("Pick") as AudioStreamPlayer
	if p == null or p.stream == null:
		return
	p.pitch_scale = 1.0
	p.play()


func _play_grow() -> void:
	var p := _players.get("Grow") as AudioStreamPlayer
	if p == null or p.stream == null:
		return
	p.pitch_scale = randf_range(0.97, 1.03)
	p.play()


func _play_win() -> void:
	var p := _players.get("Win") as AudioStreamPlayer
	if p == null or p.stream == null:
		return
	p.pitch_scale = 1.0
	p.play()


func _play_lose() -> void:
	var p := _players.get("Lose") as AudioStreamPlayer
	if p == null or p.stream == null:
		return
	p.pitch_scale = 1.0
	p.play()
