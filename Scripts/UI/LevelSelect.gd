extends Control
## ============================================================================
## LevelSelect — 选关界面（场景树布局；列表项为唯一运行期动态内容）
## ============================================================================

const LEVELS_DIR := "res://Scenes/Levels"

@onready var _list: VBoxContainer = $Layout/Scroll/List
@onready var _back: Button = $Layout/Footer/BackButton


func _ready() -> void:
	_back.pressed.connect(GameManager.back_to_main_menu)
	_scan_levels()


func _scan_levels() -> void:
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		push_warning("LevelSelect: 找不到关卡目录 %s" % LEVELS_DIR)
		return
	var entries: Array = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.begins_with("Level_") and fname.ends_with(".tscn") \
				and fname != "LevelTemplate.tscn":
			var scene := load(LEVELS_DIR.path_join(fname)) as PackedScene
			if scene == null:
				fname = dir.get_next()
				continue
			var root := scene.instantiate()
			var id := int(root.get("level_id")) if root.get("level_id") != null else 0
			var disp: String = root.get("level_name") if root.get("level_name") != null else fname.trim_suffix(".tscn")
			root.free()
			entries.append({"id": id, "disp": disp, "path": LEVELS_DIR.path_join(fname)})
		fname = dir.get_next()
	dir.list_dir_end()
	entries.sort_custom(func(a, b): return a.id < b.id)

	for e in entries:
		var btn := Button.new()
		var best := SaveManager.best_steps_for("level_%d" % e.id)
		btn.text = "%s%s" % [e.disp, ("  最佳步数: %d" % best) if best >= 0 else ""]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 44)
		var path: String = e.path
		btn.pressed.connect(func(): GameManager.start_level(path))
		_list.add_child(btn)
