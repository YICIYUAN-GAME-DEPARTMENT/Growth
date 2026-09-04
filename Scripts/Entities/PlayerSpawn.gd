@tool
class_name PlayerSpawn
extends CellEntity
## ============================================================================
## PlayerSpawn — 玩家出生点（= 尾部锚点 S，整关固定）每关必须且只能放 1 个
## ============================================================================

func _draw() -> void:
	var px := GridMetrics.cell_px()
	draw_rect(Rect2(Vector2.ZERO, Vector2(px, px)), Palette.SPAWN)
	# 中心小圈，便于一眼认出
	draw_circle(Vector2(px, px) * 0.5, px * 0.18, Color(0.1, 0.2, 0.15))
