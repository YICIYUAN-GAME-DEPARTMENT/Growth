extends Node
## ============================================================================
## GameManager  —  全局游戏状态与场景流转 (Autoload)
## ----------------------------------------------------------------------------
## 职责：持有顶层状态机、分数、场景切换；不负责具体玩法逻辑（玩法下沉到
## GameScene 子类与各 System）。状态机可待团队锁定玩法后再细化。
## ============================================================================

enum State { BOOT, MENU, PLAYING, PAUSED, GAME_OVER }

var state: GameManager.State = State.BOOT
var score: int = 0


# ── 场景流转 ───────────────────────────────────────────────────
func change_scene(target_path: String, fade: bool = true) -> void:
	var transition := "fade" if fade else "cut"
	EventManager.scene_change_requested.emit(target_path, transition)
	get_tree().change_scene_to_file(target_path)


# ── 暂停 ───────────────────────────────────────────────────────
func pause_game() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		get_tree().paused = true
		EventManager.game_paused.emit(true)


func resume_game() -> void:
	if state == State.PAUSED:
		state = State.PLAYING
		get_tree().paused = false
		EventManager.game_paused.emit(false)


# ── 结算 ───────────────────────────────────────────────────────
func end_game(result: Dictionary) -> void:
	state = State.GAME_OVER
	EventManager.game_over.emit(result)


func add_score(amount: int) -> void:
	score += amount
	EventManager.score_changed.emit(score)
