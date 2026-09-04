extends Control
## ============================================================================
## MainMenu — 开始界面（场景树布局；脚本只接线）
## ============================================================================

@onready var _start: Button = $Center/VBox/StartButton
@onready var _quit: Button = $Center/VBox/QuitButton


func _ready() -> void:
	_start.pressed.connect(_on_start)
	_quit.pressed.connect(_on_quit)


func _on_start() -> void:
	GameManager.change_scene(GameManager.level_select_scene)


func _on_quit() -> void:
	get_tree().quit()
