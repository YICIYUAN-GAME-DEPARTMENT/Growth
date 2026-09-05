class_name LevelHUD
extends CanvasLayer
## ============================================================================
## LevelHUD — 局内顶栏 + 结算覆盖（全部场景树布局；脚本只更新文字/显隐）
## ============================================================================

@onready var _max_len: Label = $Root/TopArea/StatsPanel/Margin/Stats/LengthPill/LabelLen
@onready var _food: Label = $Root/TopArea/StatsPanel/Margin/Stats/FoodPill/LabelFood
@onready var _steps: Label = $Root/TopArea/StatsPanel/Margin/Stats/StepsPill/LabelSteps
@onready var _overlay: Control = $Root/Overlay
@onready var _overlay_text: Label = $Root/Overlay/Center/Panel/Content/Text
@onready var _restart: Button = $Root/TopArea/ActionsPanel/Actions/RestartBtn
@onready var _back: Button = $Root/TopArea/ActionsPanel/Actions/BackBtn
@onready var _overlay_restart: Button = $Root/Overlay/Center/Panel/Content/RestartBtn
@onready var _overlay_back: Button = $Root/Overlay/Center/Panel/Content/BackBtn
@onready var _pause_overlay: Control = $Root/PauseOverlay
@onready var _pause_continue: Button = $Root/PauseOverlay/Center/Panel/Content/ContinueButton
@onready var _pause_restart: Button = $Root/PauseOverlay/Center/Panel/Content/RestartButton
@onready var _pause_exit: Button = $Root/PauseOverlay/Center/Panel/Content/ExitButton


func _ready() -> void:
	_restart.pressed.connect(_restart_level)
	_back.pressed.connect(_exit_level)
	_overlay_restart.pressed.connect(_restart_level)
	_overlay_back.pressed.connect(_exit_level)
	_pause_continue.pressed.connect(_close_pause_menu)
	_pause_restart.pressed.connect(_restart_level)
	_pause_exit.pressed.connect(_exit_level)
	hide_result()
	_close_pause_menu()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and not _overlay.visible:
		if _pause_overlay.visible:
			_close_pause_menu()
		else:
			_open_pause_menu()
		get_viewport().set_input_as_handled()


func update_stats(max_len: int, food_eaten: int, total_food: int, steps: int) -> void:
	_max_len.text = "最大身长 L  ·  %d" % max_len
	_food.text = "食物  ·  %d / %d" % [food_eaten, total_food]
	_steps.text = "步数  ·  %d" % steps


func show_result(text: String) -> void:
	_close_pause_menu()
	_overlay_text.text = text
	_overlay.visible = true
	_overlay_restart.grab_focus()


func hide_result() -> void:
	_overlay.visible = false


func _open_pause_menu() -> void:
	_pause_overlay.visible = true
	get_tree().paused = true
	_pause_continue.grab_focus()


func _close_pause_menu() -> void:
	get_tree().paused = false
	_pause_overlay.visible = false


func _restart_level() -> void:
	_close_pause_menu()
	GameManager.restart_level()


func _exit_level() -> void:
	_close_pause_menu()
	GameManager.back_to_level_select()


func _exit_tree() -> void:
	get_tree().paused = false
