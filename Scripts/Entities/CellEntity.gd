@tool
class_name CellEntity
extends Node2D
## ============================================================================
## CellEntity — 可摆放格子的关卡实体基类（@tool，编辑器/运行时通用）
## ----------------------------------------------------------------------------
## 位置语义：本节点 position = 所占据格左上角像素（cell * cell_px）。
## 在编辑器里拖动会自动吸附到格子；也可直接在 Inspector 修改 cell。
## ============================================================================

@export var cell: Vector2i = Vector2i.ZERO:
	set(v):
		cell = v
		if Engine.is_editor_hint() or is_inside_tree():
			position = GridMetrics.cell_to_pos(cell)
		queue_redraw()

var _last_pos := Vector2(-999999, -999999)


func _ready() -> void:
	position = GridMetrics.cell_to_pos(cell)
	if Engine.is_editor_hint():
		set_process(true)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	# 拖动节点时吸附到格子，并回写 cell
	if position != _last_pos:
		var c := GridMetrics.pos_to_cell(position)
		cell = c
		position = GridMetrics.cell_to_pos(c)
		_last_pos = position
		queue_redraw()
