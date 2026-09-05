@tool
class_name Mechanism
extends CellEntity
## ============================================================================
## Mechanism — 生长机关（关卡中放置 1 个节点 = 机关核心 C）
## ----------------------------------------------------------------------------
## 画面：机关生长体（含核心格）由关卡同步到 MechanismCells(TileMapLayer) 铺瓦；
##       本节点 Core(Sprite2D) 用 z_index=1 浮在瓦片层之上画核心外观
##       （MechanismCells 在场景树里位于 EntityRoot 之后，不抬层级会被瓦片盖住）。
## 逻辑占格 = MechanicShapes + 占格冲突。本脚本只维护 level / claimed。
## 格子吸附 / position 同步由基类 CellEntity 提供。
## ============================================================================

## 初始阶段（默认 0）
@export var initial_level: int = 0

## 当前阶段
var level: int = 0

## 本关允许的最高阶段（关卡注入，默认 4）；到达后不再升级、但生长仍刷新
var level_cap: int = MechanicShapes.max_level()

## 实际占据的绝对格（Vector2i -> true），含中心；只增不减。
## 被玩家身体挡住的格本次跳过，之后每次生长（含满级）都会重试补齐。
var claimed: Dictionary = {}

## 地图逻辑范围（由 Level 启动时注入，用于丢弃越界占格）
var _grid_min := Vector2i(-1000000, -1000000)
var _grid_max := Vector2i(1000000, 1000000)
## 地板（可走区）集合；机关只在已涂地板上占格（空 = 不限地板）
var _floor_cells: Dictionary = {}


func set_grid_bounds(map_origin: Vector2i, map_size: Vector2i) -> void:
	_grid_min = map_origin
	_grid_max = map_origin + map_size


func set_floor_cells(cells: Dictionary) -> void:
	_floor_cells = cells


func _ready() -> void:
	# 核心格也铺生长体瓦，Core Sprite 必须浮在 MechanismCells(TileMapLayer) 之上
	z_index = 1
	super._ready()
	set_level(initial_level)


func set_level(v: int) -> void:
	level = clampi(v, 0, level_cap)


## 注入本关最高阶段；若当前已超则回落
func set_level_cap(v: int) -> void:
	level_cap = clampi(v, 0, MechanicShapes.max_level())
	level = clampi(level, 0, level_cap)


## 补占：把 shape(level) 中尚未占据且未被 blocked 阻挡的格加入 claimed。
## blocked = 玩家身体当前占用的绝对格 + 起点/终点保护格。返回本次新增数。
## 只在地板（可走区）集合内占格；越界 / 无地板格不占。
func claim_missing(blocked: Dictionary) -> int:
	var added := 0
	for off in MechanicShapes.cells(level):
		var abs_cell := cell + off
		if claimed.has(abs_cell):
			continue
		if blocked.has(abs_cell):
			continue
		if abs_cell.x < _grid_min.x or abs_cell.y < _grid_min.y or abs_cell.x >= _grid_max.x or abs_cell.y >= _grid_max.y:
			continue  # 越界不占
		if not _floor_cells.is_empty() and not _floor_cells.has(abs_cell):
			continue  # 不在已涂地板（可走区）不占
		claimed[abs_cell] = true
		added += 1
	return added
