class_name LevelHUD
extends CanvasLayer
## ============================================================================
## LevelHUD — 局内顶栏 + 结算覆盖（全部场景树布局；脚本只更新文字/显隐）
## ============================================================================

@onready var _max_len: Label = $Root/Top/Panel/HBox/LabelLen
@onready var _food: Label = $Root/Top/Panel/HBox/LabelFood
@onready var _steps: Label = $Root/Top/Panel/HBox/LabelSteps
@onready var _overlay: Control = $Root/Overlay
@onready var _overlay_text: Label = $Root/Overlay/Center/Panel/VBox/Text
@onready var _restart: Button = $Root/Top/Panel/RestartBtn
@onready var _back: Button = $Root/Top/Panel/BackBtn
@onready var _overlay_restart: Button = $Root/Overlay/Center/Panel/VBox/RestartBtn
@onready var _overlay_back: Button = $Root/Overlay/Center/Panel/VBox/BackBtn


func _ready() -> void:
	_restart.pressed.connect(GameManager.restart_level)
	_back.pressed.connect(GameManager.back_to_level_select)
	_overlay_restart.pressed.connect(GameManager.restart_level)
	_overlay_back.pressed.connect(GameManager.back_to_level_select)
	hide_result()


func update_stats(max_len: int, food_eaten: int, total_food: int, steps: int) -> void:
	_max_len.text = "最大身长 L: %d" % max_len
	_food.text = "食物: %d/%d" % [food_eaten, total_food]
	_steps.text = "步数: %d" % steps


func show_result(text: String) -> void:
	_overlay_text.text = text
	_overlay.visible = true


func hide_result() -> void:
	_overlay.visible = false
