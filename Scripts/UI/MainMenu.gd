extends Control
## ============================================================================
## MainMenu — 开始界面（场景树布局；脚本只接线）
## ============================================================================

@onready var _start: Button = $MenuFrame/Margin/Content/StartButton
@onready var _settings: Button = $MenuFrame/Margin/Content/SettingsButton
@onready var _quit: Button = $MenuFrame/Margin/Content/QuitButton
@onready var _settings_overlay: Control = $SettingsOverlay
@onready var _fullscreen: Button = $SettingsOverlay/Center/Panel/Content/FullscreenButton
@onready var _settings_back: Button = $SettingsOverlay/Center/Panel/Content/BackButton


func _ready() -> void:
	_start.pressed.connect(_on_start)
	_settings.pressed.connect(_open_settings)
	_quit.pressed.connect(_on_quit)
	_fullscreen.pressed.connect(_toggle_fullscreen)
	_settings_back.pressed.connect(_close_settings)
	_refresh_fullscreen_text()
	_start.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _settings_overlay.visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		_close_settings()
		get_viewport().set_input_as_handled()


func _on_start() -> void:
	GameManager.change_scene(GameManager.level_select_scene)


func _open_settings() -> void:
	_settings_overlay.visible = true
	_refresh_fullscreen_text()
	_fullscreen.grab_focus()


func _close_settings() -> void:
	_settings_overlay.visible = false
	_settings.grab_focus()


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	var fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	_refresh_fullscreen_text()


func _refresh_fullscreen_text() -> void:
	var mode := DisplayServer.window_get_mode()
	var fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	_fullscreen.text = "全屏: 开" if fullscreen else "全屏: 关"


func _on_quit() -> void:
	get_tree().quit()
