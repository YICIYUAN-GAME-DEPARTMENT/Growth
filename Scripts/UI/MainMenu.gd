extends Control
## ============================================================================
## MainMenu — 开始界面（进入选关 / 退出）
## ============================================================================

func _ready() -> void:
	_build()


func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Growth"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "绳蛇解谜 · 到达终点！"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.modulate = Color(1, 1, 1, 0.7)
	vbox.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(spacer)

	var play := Button.new()
	play.text = "开始游戏"
	play.custom_minimum_size = Vector2(260, 56)
	play.pressed.connect(_on_play)
	vbox.add_child(play)

	var quit := Button.new()
	quit.text = "退出"
	quit.custom_minimum_size = Vector2(260, 44)
	quit.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit)


func _on_play() -> void:
	GameManager.change_scene(GameManager.level_select_scene)
