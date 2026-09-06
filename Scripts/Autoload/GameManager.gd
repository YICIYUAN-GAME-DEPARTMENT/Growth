extends Node
## ============================================================================
## GameManager  —  全局游戏状态与场景流转 (Autoload)
## ----------------------------------------------------------------------------
## 职责：持有顶层状态机、当前关卡信息、场景切换；玩法细节下沉到关卡。
## 数值配置：balance（Balance.tres）——实现层唯一读取处，脚本勿再硬编码。
## ============================================================================

const BALANCE_PATH := "res://Resources/Config/Balance.tres"
## 关卡目录（与 LevelSelect 一致；LevelTemplate 不算可玩关）
const LEVELS_DIR := "res://Scenes/Levels"

enum State { BOOT, MENU, PLAYING }

var state: State = State.BOOT

## 全局数值配置（只读使用）
var balance: Balance = null

## 当前运行的关卡（由 LevelSelect 写入；用于重开/结算返回选关）
var current_level_scene := ""
## 选关界面路径（结算"回选关"用）
var level_select_scene := "res://Scenes/UI/LevelSelect.tscn"
## 主菜单路径
var main_menu_scene := "res://Scenes/UI/MainMenu.tscn"


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
	# 经选关进入时重开指定关卡；若直接 F6 运行某关卡场景（无记录），
	# 回退为重载当前场景自身，保证编辑器调试时按钮也可用。
	var target := current_level_scene
	if target == "":
		var cs := get_tree().current_scene
		if cs != null and cs.scene_file_path != "":
			target = cs.scene_file_path
	if target != "":
		change_scene(target)


func back_to_level_select() -> void:
	state = State.MENU
	change_scene(level_select_scene)


func back_to_main_menu() -> void:
	state = State.MENU
	change_scene(main_menu_scene)


# ── 关卡列表 / 下一关 ─────────────────────────────────────────
## 扫描 Scenes/Levels 下的可玩关卡，按 level_id 升序。每项 = {id, name, path}
## （LevelSelect 列表、"下一关"跳转共用同一来源）。
func list_levels() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir():
			# 导出后 PCK 内的场景以 "<名>.tscn.remap" 条目列出（编辑器为原始名），
			# 统一剥掉 .remap 再过滤，保证导出包里也能扫到关卡。
			var scene_name := fname.trim_suffix(".remap")
			if scene_name.begins_with("Level_") and scene_name.ends_with(".tscn") \
					and scene_name != "LevelTemplate.tscn":
				var path := LEVELS_DIR.path_join(scene_name)
				var ps := load(path) as PackedScene
				if ps != null:
					var root := ps.instantiate()
					var id := int(root.get("level_id")) if root.get("level_id") != null else 0
					var name := str(root.get("level_name")) if root.get("level_name") != null else ""
					root.free()
					if name.is_empty():
						name = scene_name.get_basename().trim_prefix("Level_")
					out.append({"id": id, "name": name, "path": path})
		fname = dir.get_next()
	dir.list_dir_end()
	out.sort_custom(func(a, b): return a.id < b.id)
	return out


## "下一关"：进入关卡列表中当前关的下一位；已是最后一关（或当前关不在列表）则回选关界面
func start_next_level() -> void:
	var levels := list_levels()
	if levels.is_empty():
		back_to_level_select()
		return
	var cur := ""
	var cs := get_tree().current_scene
	if cs != null:
		cur = cs.scene_file_path
	var idx := -1
	for i in levels.size():
		if levels[i].path == cur:
			idx = i
			break
	if idx >= 0 and idx < levels.size() - 1:
		start_level(levels[idx + 1].path)
	else:
		back_to_level_select()


# ── 场景流转 ───────────────────────────────────────────────────
func change_scene(target_path: String) -> void:
	get_tree().change_scene_to_file(target_path)
