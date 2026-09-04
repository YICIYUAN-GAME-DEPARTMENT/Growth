extends Node2D
## ============================================================================
## Main  —  根场景控制器
## ----------------------------------------------------------------------------
## 挂在 Scenes/Main.tscn。持有 WorldRoot / UIRoot 两个容器层；具体玩法场景
## 通过 ResourceManager.get_scene() 实例化后挂到 WorldRoot 下。转场与暂停
## 覆盖层在此处理，让玩法场景只关心逻辑。
## ============================================================================

@onready var world_root: Node2D = $WorldRoot
@onready var ui_root: CanvasLayer = $UIRoot


func _ready() -> void:
	EventManager.game_paused.connect(_on_game_paused)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			GameManager.resume_game()
		else:
			GameManager.pause_game()


# ── Hook：UI 团队在此挂暂停覆盖层 ────────────────────────────
func _on_game_paused(paused: bool) -> void:
	pass
