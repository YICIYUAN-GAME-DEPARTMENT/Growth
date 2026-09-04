@tool
class_name CellEntity
extends Node2D
## ============================================================================
## CellEntity — 可摆放实体基类（纯逻辑+编辑器吸附；不画任何东西）
## ----------------------------------------------------------------------------
## 实体 = 本节点 + 场景里一个 Sprite2D 子节点（贴图）。
## 本节点 position = 所占据格的中心；拖动自动吸附格子。
## ============================================================================

@export var cell: Vector2i = Vector2i.ZERO:
	set(v):
		cell = v
		if Engine.is_editor_hint() or is_inside_tree():
			position = GridMetrics.cell_center(cell)
		queue_redraw()

var _last_pos := Vector2(-999999, -999999)


func _ready() -> void:
	position = GridMetrics.cell_center(cell)
	if Engine.is_editor_hint():
		set_process(true)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if position != _last_pos:
		cell = GridMetrics.pos_to_cell(position)
		position = GridMetrics.cell_center(cell)
		_last_pos = position
