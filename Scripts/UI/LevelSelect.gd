extends Control
## ============================================================================
## LevelSelect — 选关界面
## ----------------------------------------------------------------------------
## 自动扫描 res://Scenes/Levels 下 Level_*.tscn（测试期全开）；
## 记录来源：SaveManager.best_steps。
## ============================================================================

const LEVELS_DIR := "res://Scenes/Levels"

var _entries: Array = []   # [{id:int, name:String, path:String}]


func _ready() -> void:
	_scan_levels()
	_build()


func _scan_levels() -> void:
	_entries.clear()
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		push_warning("LevelSelect: 找不到关卡目录 %s" % LEVELS_DIR)
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.begins_with("Level_") and fname.ends_with(".tscn"):
			var scene := load(LEVELS_DIR.path_join(fname)) as PackedScene
			if scene == null:
				continue
			var root := scene.instantiate()
			var id := int(root.get("level_id")) if root.get("level_id") != null else _entries.size() + 1
			var name_text: String = root.get("level_name") if root.get("level_name") != null else fname.trim_suffix(".tscn")
			root.free()
			_entries.append({"id": id, "name": name_text, "path": LEVELS_DIR.path_join(fname)})
		fname = dir.get_next()
	dir.list_dir_end()
	_entries.sort_custom(func(a, b): return a.id < b.id)


func _build() -> void:
	var title := Label.new()
	title.text = "选择关卡"
	title.add_theme_font_size_override("font_size", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchors_preset = Control.PRESET_CENTER_TOP
	title.anchor_top = 0.0
	title.anchor_bottom = 0.0
	title.offset_top = 24
	add_child(title)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 100
	scroll.offset_bottom = -60
	add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for e in _entries:
		var best := SaveManager.best_steps_for("level_%d" % e.id)
		var suffix := "  (最佳步数: %d)" % best if best >= 0 else ""
		var btn := Button.new()
		btn.text = "%s%s" % [e.name, suffix]
		btn.custom_minimum_size = Vector2(0, 44)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var path: String = e.path
		btn.pressed.connect(func(): GameManager.start_level(path))
		list.add_child(btn)

	var back := Button.new()
	back.text = "返回主菜单"
	back.anchors_preset = Control.PRESET_CENTER_BOTTOM
	back.anchor_top = 1.0
	back.anchor_bottom = 1.0
	back.offset_top = -50
	back.custom_minimum_size = Vector2(200, 40)
	back.pressed.connect(func(): GameManager.back_to_main_menu())
	add_child(back)
