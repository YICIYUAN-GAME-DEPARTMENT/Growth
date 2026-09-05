class_name LevelHUD
extends CanvasLayer
## ============================================================================
## LevelHUD — 局内顶栏 + 结算覆盖（全部场景树布局；脚本只更新数值/显隐）
## ============================================================================

@onready var _remaining_steps_value: Label = $Root/TopArea/HBoxContainer/RemainingCard/RemainingValue
@onready var _petal_value: Label = $Root/TopArea/HBoxContainer/PetalCard/PetalValue
@onready var _overlay: Control = $Root/Overlay
@onready var _overlay_text: Label = $Root/Overlay/Center/Panel/Content/Text
@onready var _restart: Button = $Root/TopArea/ActionsPanel/Actions/RestartBtn
@onready var _back: Button = $Root/TopArea/ActionsPanel/Actions/BackBtn
@onready var _overlay_restart: Button = $Root/Overlay/Center/Panel/Content/RestartBtn
@onready var _overlay_back: Button = $Root/Overlay/Center/Panel/Content/BackBtn
@onready var _next: Button = $Root/Overlay/Center/Panel/Content/NextBtn
@onready var _pause_overlay: Control = $Root/PauseOverlay
@onready var _pause_continue: Button = $Root/PauseOverlay/Center/Panel/Content/ContinueButton
@onready var _pause_restart: Button = $Root/PauseOverlay/Center/Panel/Content/RestartButton
@onready var _pause_exit: Button = $Root/PauseOverlay/Center/Panel/Content/ExitButton

## 剧情演出期间由 Level 置位：忽略 Esc（交给剧情层做"跳过"），防误开暂停菜单
var dialogue_active := false


func _ready() -> void:
	_restart.pressed.connect(_restart_level)
	_back.pressed.connect(_exit_level)
	_overlay_restart.pressed.connect(_restart_level)
	_overlay_back.pressed.connect(_exit_level)
	_next.pressed.connect(_next_level)
	_pause_continue.pressed.connect(_close_pause_menu)
	_pause_restart.pressed.connect(_restart_level)
	_pause_exit.pressed.connect(_exit_level)
	hide_result()
	_close_pause_menu()


func _input(event: InputEvent) -> void:
	if dialogue_active:
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and not _overlay.visible:
		if _pause_overlay.visible:
			_close_pause_menu()
		else:
			_open_pause_menu()
		get_viewport().set_input_as_handled()


func update_remaining_steps(remaining_steps: int) -> void:
	_remaining_steps_value.text = str(remaining_steps)


## 花瓣提供的步长：每片食物给最大身长增加的格数（Level 解析 override/全局后传入）
func set_petal_gain(gain: int) -> void:
	_petal_value.text = str(gain)


## 结算面板：victory=true 时显示"下一关"按钮；失败隐藏。
## 若是最后一关，"下一关"同样可用——GameManager 会返回选关界面。
func show_result(text: String, victory := false) -> void:
	_close_pause_menu()
	_overlay_text.text = text
	_next.visible = victory
	_overlay.visible = true
	if victory:
		_next.grab_focus()
	else:
		_overlay_restart.grab_focus()


func hide_result() -> void:
	_overlay.visible = false


func set_dialogue_active(value: bool) -> void:
	dialogue_active = value


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


## "下一关"：进入关卡列表中当前关的下一位；已是最后一关则回选关界面
func _next_level() -> void:
	_close_pause_menu()
	GameManager.start_next_level()


func _exit_tree() -> void:
	get_tree().paused = false
