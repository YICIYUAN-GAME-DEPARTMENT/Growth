class_name GridMetrics
## ============================================================================
## GridMetrics — 逻辑格 <-> 世界像素 换算
## 视觉格大小固定 CELL_PX；玩法数值（L/ΔL/步数）不依赖像素。
## 实体节点位置取"格中心"便于 Sprite 居中；TileMap 格子以格左上为准。
## ============================================================================

const CELL_PX: int = 32


## 格左上角世界坐标（TileMap set_cell 用）
static func cell_to_pos(c: Vector2i) -> Vector2:
	return Vector2(c) * CELL_PX


## 格中心世界坐标（实体 Sprite 摆放用）
static func cell_center(c: Vector2i) -> Vector2:
	return cell_to_pos(c) + Vector2(CELL_PX, CELL_PX) * 0.5


## 世界坐标 -> 格（对"中心"取整）
static func pos_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(roundi((p.x - CELL_PX * 0.5) / CELL_PX),
			roundi((p.y - CELL_PX * 0.5) / CELL_PX))
