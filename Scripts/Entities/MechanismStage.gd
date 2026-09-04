@tool
class_name MechanismStage
extends Node2D
## ============================================================================
## MechanismStage — 机关某一阶段的可视场景（运行时/编辑器均绘制）
## ----------------------------------------------------------------------------
## Mechanism.tscn（总机关）内含 5 个 Stage 实例，按 lv 只显示对应一个。
## 占格逻辑权威仍是 MechanicShapes；本场景仅负责把该阶段画出来。
## ============================================================================

## 本阶段（0..4），在实例里通过 level 区分
@export var level: int = 0

var _last_px := -1


func _process(_delta: float) -> void:
	if _last_px != GridMetrics.cell_px():
		queue_redraw()


func _draw() -> void:
	var px := GridMetrics.cell_px()
	_last_px = px
	var color: Color = Palette.MECH[clampi(level, 0, MechanicShapes.max_level())]
	for off in MechanicShapes.cells(level):
		var r := Rect2(Vector2(off) * px, Vector2(px, px))
		draw_rect(r, color)
	# 中心格外框加深
	draw_rect(Rect2(Vector2.ZERO, Vector2(px, px)), Palette.MECH_CORE, false, 2.0)
