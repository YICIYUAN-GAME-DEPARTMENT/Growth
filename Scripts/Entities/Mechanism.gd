@tool
class_name Mechanism
extends Node2D
## ============================================================================
## Mechanism — 生长机关（关卡中放置 1 个节点 = 机关核心 C）
## ----------------------------------------------------------------------------
## 画面：本节点 Core(Sprite2D) 画核心；机关生长体由关卡同步到
##       MechanismCells(TileMapLayer)。逻辑占格 = MechanicShapes + 占格冲突。
## 本脚本只维护 cell / lv / claimed（不画图）。
## ============================================================================

## 中心格（C）；拖动即吸附格子
@export var cell: Vector2i = Vector2i.ZERO:
	set(v):
		cell = v
		if Engine.is_editor_hint() or is_inside_tree():
			position = GridMetrics.cell_center(cell)
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
	position = GridMetrics.cell_center(cell)
	set_level(initial_level)
	if Engine.is_editor_hint():
		set_process(true)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if position != _last_pos:
		cell = GridMetrics.pos_to_cell(position)
		position = GridMetrics.cell_center(cell)
		_last_pos = position
		queue_redraw()


func set_level(v: int) -> void:
	level = clampi(v, 0, MechanicShapes.max_level())


## 补占：把 shape(level) 中尚未占据且未被 blocked 阻挡的格加入 claimed。
## blocked = 玩家身体当前占用的绝对格 + 起点/终点保护格。返回本次新增数。
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
	return added


## 生长体格子 = claimed 去掉核心格 C（核心由 Core 贴图单独画）
func body_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for abs_cell in claimed:
		if abs_cell != cell:
			out.append(abs_cell)
	return out
