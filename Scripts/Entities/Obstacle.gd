@tool
class_name Obstacle
extends CellEntity
## ============================================================================
## Obstacle — 静态障碍物（每个节点占据 1 格，玩家不可踏入）
## ============================================================================

func _draw() -> void:
	var px := GridMetrics.cell_px()
	draw_rect(Rect2(Vector2.ZERO, Vector2(px, px)), Palette.OBSTACLE)
	draw_rect(Rect2(Vector2.ZERO, Vector2(px, px)), Color(0, 0, 0, 0.25), false, 1.0)
