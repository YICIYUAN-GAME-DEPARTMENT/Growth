@tool
class_name Goal
extends CellEntity
## ============================================================================
## Goal — 终点（占 1 格）。头部踏入即胜利。
## ============================================================================

func _draw() -> void:
	var px := GridMetrics.cell_px()
	draw_rect(Rect2(Vector2(px, px) * 0.12, Vector2(px, px) * 0.76), Palette.GOAL)
	draw_circle(Vector2(px, px) * 0.5, px * 0.22, Color(1, 1, 1, 0.9))
