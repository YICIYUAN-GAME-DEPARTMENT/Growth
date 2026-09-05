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
	button_hover(self, is_hovered() or has_focus())


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
