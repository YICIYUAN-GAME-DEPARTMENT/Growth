extends Control
## ============================================================================
## LevelSelect — 选关界面（场景树布局；列表项为唯一运行期动态内容）
## ============================================================================

const LEVELS_DIR := "res://Scenes/Levels"
const LEVEL_CARD_SCENE: PackedScene = preload("res://Scenes/UI/LevelCard.tscn")

@onready var _list: GridContainer = $Frame/Margin/Layout/Scroll/CardMargin/List
@onready var _scroll: ScrollContainer = $Frame/Margin/Layout/Scroll
@onready var _empty_state: Label = $Frame/Margin/Layout/EmptyState
@onready var _back: Button = $Frame/Margin/Layout/Header/BackButton


func _ready() -> void:
	_back.pressed.connect(GameManager.back_to_main_menu)
	_scan_levels()


func _scan_levels() -> void:
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		push_warning("LevelSelect: 找不到关卡目录 %s" % LEVELS_DIR)
		_show_empty_state()
		return
	var entries: Array[Dictionary] = []
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
			root.free()
			entries.append({"id": id, "path": LEVELS_DIR.path_join(fname)})
		fname = dir.get_next()
	dir.list_dir_end()
	entries.sort_custom(func(a, b): return a.id < b.id)

	if entries.is_empty():
		_show_empty_state()
		return

	var first_button: Button = null
	for entry: Dictionary in entries:
		var btn := LEVEL_CARD_SCENE.instantiate() as Button
		if btn == null:
			push_error("LevelSelect: LevelCard.tscn 根节点必须是 Button")
			return
		btn.text = str(entry.id)
		var path: String = entry.path
		btn.pressed.connect(func(): GameManager.start_level(path))
		_list.add_child(btn)
		if first_button == null:
			first_button = btn

	if first_button != null:
		first_button.grab_focus()


func _show_empty_state() -> void:
	_scroll.visible = false
	_empty_state.visible = true
