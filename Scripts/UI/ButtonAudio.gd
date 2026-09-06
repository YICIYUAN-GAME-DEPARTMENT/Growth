extends AudioStreamPlayer
## 全局按钮反馈：跨场景播放，暂停期间有效，覆盖动态选关按钮。

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_bind_buttons(get_tree().root)


func _bind_buttons(node: Node) -> void:
	_on_node_added(node)
	for child: Node in node.get_children():
		_bind_buttons(child)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		if not button.button_down.is_connected(_play_click):
			button.button_down.connect(_play_click)


func _play_click() -> void:
	play()
