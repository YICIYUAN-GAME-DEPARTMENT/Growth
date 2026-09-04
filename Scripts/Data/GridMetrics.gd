class_name GridMetrics
## ============================================================================
## GridMetrics — 逻辑格 <-> 世界像素 换算（占位渲染统一使用）
## 视觉格大小固定 CELL_PX；玩法数值（L/ΔL/步数）不依赖像素。
## ============================================================================

const CELL_PX: int = 32


static func cell_px() -> int:
	return CELL_PX


## 格子(cx,cy) 左上角的世界坐标
static func cell_to_pos(c: Vector2i) -> Vector2:
	return Vector2(c) * CELL_PX


## 世界坐标 -> 格子（向下取整）
static func pos_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL_PX), floori(p.y / CELL_PX))
