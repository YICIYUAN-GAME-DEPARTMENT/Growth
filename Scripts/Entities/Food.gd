@tool
class_name Food
extends CellEntity
## ============================================================================
## Food — 食物（占 1 格）。被头部踏入即被吃：L + ΔL。
## ============================================================================

func _draw() -> void:
	var px := GridMetrics.cell_px()
	var c := Vector2(px, px) * 0.5
	draw_circle(c, px * 0.32, Palette.FOOD)
	draw_circle(c, px * 0.14, Color(1, 1, 1, 0.85))
