extends Node
## ============================================================================
## GameManager  —  全局游戏状态与场景流转 (Autoload)
## ----------------------------------------------------------------------------
## 职责：持有顶层状态机、当前关卡信息、场景切换、暂停；玩法细节下沉到关卡。
## 数值配置：balance（Balance.tres）——实现层唯一读取处，脚本勿再硬编码。
## ============================================================================

const BALANCE_PATH := "res://Resources/Config/Balance.tres"

enum State { BOOT, MENU, PLAYING, PAUSED, LEVEL_COMPLETE }

var state: State = State.BOOT

## 全局数值配置（只读使用）
var balance: Balance = null

## 当前运行的关卡（由 LevelSelect 写入；用于重开/结算返回选关）
var current_level_scene := ""
## 选关界面路径（结算"回选关"用）
var level_select_scene := "res://Scenes/UI/LevelSelect.tscn"
## 主菜单路径
var main_menu_scene := "res://Scenes/UI/MainMenu.tscn"

var _score: int = 0


func _ready() -> void:
	_load_balance()
	state = State.MENU


func _load_balance() -> void:
	balance = load(BALANCE_PATH) as Balance
	if balance == null:
		push_error("GameManager: 无法加载 Balance.tres (%s)" % BALANCE_PATH)
	# Balance.tres 为静态配置，运行时禁止修改实例


# ── 关卡入口 ───────────────────────────────────────────────────
## LevelSelect 调用：进入指定关卡场景文件
func start_level(scene_path: String) -> void:
	current_level_scene = scene_path
	state = State.PLAYING
	change_scene(scene_path)


func restart_level() -> void:
	if current_level_scene != "":
		change_scene(current_level_scene)


func back_to_level_select() -> void:
	state = State.MENU
	change_scene(level_select_scene)


func back_to_main_menu() -> void:
	state = State.MENU
	change_scene(main_menu_scene)


# ── 场景流转 ───────────────────────────────────────────────────
func change_scene(target_path: String) -> void:
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


# ── 分数（当前项目不使用，保留通用接口）──────────────────────
func add_score(amount: int) -> void:
	_score += amount
	EventManager.score_changed.emit(_score)


func get_score() -> int:
	return _score
