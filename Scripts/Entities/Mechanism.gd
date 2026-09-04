@tool
class_name Mechanism
extends Node2D
## ============================================================================
## Mechanism — 生长机关（关卡中放置 1 个节点 = 机关核心）
## ----------------------------------------------------------------------------
## 逻辑权威：MechanicShapes.shape(lv)。实际占据集合 claimed 由本节点维护，
## 生长时由 Level 调 claim_missing()（玩家身体阻挡的格跳过，下次生长重试）。
## 内含 5 个阶段子场景 Stage0..Stage4，仅编辑器预览用；运行时按 claimed 自绘。
## ============================================================================

## 中心格（C）；拖动即吸附格子
@export var cell: Vector2i = Vector2i.ZERO:
	set(v):
		cell = v
		if is_inside_tree():
			position = GridMetrics.cell_to_pos(cell)
		queue_redraw()

## 初始阶段（默认 0）
@export var initial_level: int = 0

## 当前阶段
var level: int = 0

## 实际占据的绝对格（Vector2i -> true），含中心；只增不减，跳过格待下次生长
var claimed: Dictionary = {}

## 地图逻辑范围（由 Level 启动时注入，用于丢弃越界占格）
var grid_size := Vector2i(1000, 1000)

var _last_pos := Vector2(-999999, -999999)


func set_grid_size(v: Vector2i) -> void:
	grid_size = v


func _ready() -> void:
	position = GridMetrics.cell_to_pos(cell)
	set_level(initial_level)
	# 运行时隐藏编辑器预览阶段；占格由 _draw 按 claimed 绘制
	if not Engine.is_editor_hint():
		for i in 5:
			var stage := get_node_or_null("Stage%d" % i)
			if stage:
				stage.visible = false
		queue_redraw()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if position != _last_pos:
		cell = GridMetrics.pos_to_cell(position)
		position = GridMetrics.cell_to_pos(cell)
		_last_pos = position
		queue_redraw()


func set_level(v: int) -> void:
	level = clampi(v, 0, MechanicShapes.max_level())
	# 编辑器预览：按 lv 显示对应阶段子场景
	if Engine.is_editor_hint():
		for i in 5:
			var stage := get_node_or_null("Stage%d" % i)
			if stage:
				stage.visible = (i == level)
	queue_redraw()


## 补占：把 shape(level) 中尚未占据且未被 blocked 阻挡的格加入 claimed。
## blocked = 玩家身体当前占用的绝对格（dict 查寻用）。返回本次新增数。
func claim_missing(blocked: Dictionary) -> int:
	var added := 0
	for off in MechanicShapes.cells(level):
		var abs_cell := cell + off
		if claimed.has(abs_cell):
			continue
		if blocked.has(abs_cell):
			continue
		if abs_cell.x < 0 or abs_cell.y < 0 or abs_cell.x >= grid_size.x or abs_cell.y >= grid_size.y:
			continue  # 越界不占
		claimed[abs_cell] = true
		added += 1
	if added > 0:
		queue_redraw()
	return added


## 当前逻辑占格（绝对格）
func claimed_cells() -> Dictionary:
	return claimed


func _draw() -> void:
	if Engine.is_editor_hint():
		return  # 编辑器里由 Stage 子场景预览
	var px := GridMetrics.cell_px()
	var color: Color = Palette.MECH[clampi(level, 0, MechanicShapes.max_level())]
	for abs_cell in claimed:
		var local := Vector2(abs_cell - cell) * px
		var r := Rect2(local, Vector2(px, px))
		draw_rect(r, color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(px, px)), Palette.MECH_CORE, false, 2.0)
