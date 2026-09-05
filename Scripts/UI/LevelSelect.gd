extends Control
## ============================================================================
## LevelSelect — 选关界面（场景树布局；列表项为唯一运行期动态内容）
## ----------------------------------------------------------------------------
## 每关一行按钮，显示 "序号 | 关卡名"；关卡来源=GameManager.list_levels()，
## "下一关"跳转与这里共用同一份列表，保证顺序一致。
## ============================================================================

const LEVEL_CARD_SCENE: PackedScene = preload("res://Scenes/UI/LevelCard.tscn")

@onready var _list: VBoxContainer = $Frame/Margin/Layout/Scroll/CardMargin/List
@onready var _scroll: ScrollContainer = $Frame/Margin/Layout/Scroll
@onready var _empty_state: Label = $Frame/Margin/Layout/EmptyState
@onready var _back: Button = $Frame/Margin/Layout/Header/BackButton


func _ready() -> void:
	_back.pressed.connect(GameManager.back_to_main_menu)
	_scan_levels()


func _scan_levels() -> void:
	var levels := GameManager.list_levels()
	if levels.is_empty():
		_show_empty_state()
		return

	for entry: Dictionary in levels:
		var btn := LEVEL_CARD_SCENE.instantiate() as Button
		if btn == null:
			push_error("LevelSelect: LevelCard.tscn 根节点必须是 Button")
			return
		btn.text = "%d | %s" % [entry.id, entry.name]
		var path: String = entry.path
		btn.pressed.connect(func(): GameManager.start_level(path))
		_list.add_child(btn)
	# 不自动 grab_focus：默认聚焦会触发 JuicyButton 缩放+焦点框，使第一行
	# 与其他行不一致；键盘用户 Tab/方向键即可聚焦。


func _show_empty_state() -> void:
	_scroll.visible = false
	_empty_state.visible = true
