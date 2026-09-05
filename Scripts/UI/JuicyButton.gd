class_name JuicyButton
extends Button
## ==========================================================================
## JuicyButton — CC0 Easy Juicy Buttons hover tween for reusable UI buttons.
## ==========================================================================

var _scale_tween: Tween = null


func _ready() -> void:
	mouse_entered.connect(_refresh_hover)
	mouse_exited.connect(_refresh_hover)
	focus_entered.connect(_refresh_hover)
	focus_exited.connect(_refresh_hover)
	resized.connect(_update_pivot)
	_update_pivot()


func _refresh_hover() -> void:
	var on := is_hovered() or has_focus()
	if is_instance_valid(_scale_tween):
		_scale_tween.kill()
	# 被容器拉伸成全宽（如选关整行按钮、HUD 全宽项）：放大必然超出父级
	# 可视区被裁掉左右两侧 → 用提亮代替缩放；独立尺寸按钮保留缩放动效。
	if size.x > custom_minimum_size.x + 1.0:
		z_index = 0
		scale = Vector2.ONE
		modulate = Color(1.12, 1.08, 0.96, 1) if on else Color.WHITE
	else:
		z_index = 5 if on else 0
		modulate = Color.WHITE
		button_hover(self, on)


## CC0 · Godot 4.5+ · Easy Juicy Buttons
func button_hover(button: Control, hovered: bool) -> Tween:
	if is_instance_valid(_scale_tween):
		_scale_tween.kill()
	var tween := button.create_tween()
	_scale_tween = tween
	var target := Vector2.ONE * (1.08 if hovered else 1.0)
	tween.tween_property(button, "scale", target, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


func _update_pivot() -> void:
	pivot_offset = size * 0.5
