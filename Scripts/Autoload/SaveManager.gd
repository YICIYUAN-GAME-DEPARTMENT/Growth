extends Node
## ============================================================================
## SaveManager  —  进度存档（Autoload）
## ----------------------------------------------------------------------------
## 文件：user://growth_save.cfg（ConfigFile）
## 内容：best_steps { level_key: int }  每关最优步数（记录展示用）
## 当前为"测试期全开"：不做关卡锁定；保留 unlocked 字段以备后续切换。
## 接口：save() / load() / record_result(level_key, steps) / best_steps_for(key)
## ============================================================================

const SAVE_PATH := "user://growth_save.cfg"
const DEFAULT_UNLOCKED := 1  # 后续如启用线性解锁，从 1 开始

var best_steps: Dictionary = {}   # String(level_key) -> int


func _ready() -> void:
	load_data()


# ── 读取 / 写入 ───────────────────────────────────────────────
func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var stored: Variant = cfg.get_value("progress", "best_steps", {})
	best_steps = stored if stored is Dictionary else {}


func save_data() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "best_steps", best_steps)
	cfg.save(SAVE_PATH)


# ── 关卡记录 ─────────────────────────────────────────────────
## 只保留更优（更小）步数
func record_result(level_key: String, steps: int) -> void:
	var prev: int = best_steps_for(level_key)
	if prev == -1 or steps < prev:
		best_steps[level_key] = steps
		save_data()


func best_steps_for(level_key: String) -> int:
	return best_steps.get(level_key, -1)


func has_cleared(level_key: String) -> bool:
	return best_steps.has(level_key)
