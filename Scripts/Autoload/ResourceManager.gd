extends Node
## ============================================================================
## ResourceManager  —  资源懒加载与缓存 (Autoload)
## ----------------------------------------------------------------------------
## 用途：统一登记并缓存 PackedScene / Resource，避免每次 load 重复开销。
## 使用：在游戏启动时（或 MainMenu._ready）调用 register_*；运行中用 get_*。
## 异步预热：prewarm() 用 ResourceLoader.load_threaded_request 预排。
## 规范：见 docs/architecture/架构说明.md §资源管理。
## ============================================================================

var _scenes: Dictionary = {}        # id (StringName) -> PackedScene
var _resources: Dictionary = {}     # id (StringName) -> Resource


# ── 场景 ───────────────────────────────────────────────────────
func register_scene(id: String, path: String) -> void:
	if _scenes.has(id):
		push_warning("ResourceManager: scene id '%s' 已存在，覆盖" % id)
	_scenes[id] = load(path)


func get_scene(id: String) -> PackedScene:
	if not _scenes.has(id):
		push_error("ResourceManager: scene id '%s' 未登记" % id)
		return null
	return _scenes[id]


# ── 资源 ───────────────────────────────────────────────────────
func register_resource(id: String, path: String) -> void:
	if _resources.has(id):
		push_warning("ResourceManager: resource id '%s' 已存在，覆盖" % id)
	_resources[id] = load(path)


func get_resource(id: String) -> Resource:
	if not _resources.has(id):
		push_error("ResourceManager: resource id '%s' 未登记" % id)
		return null
	return _resources[id]


# ── 异步预热（大资源后台加载）────────────────────────────────
func prewarm(paths: Array) -> void:
	for path in paths:
		ResourceLoader.load_threaded_request(path)


func is_prewarmed(path: String) -> Resource:
	return ResourceLoader.load_threaded_get(path)
