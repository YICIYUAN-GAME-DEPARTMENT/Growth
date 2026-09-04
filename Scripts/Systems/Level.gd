@tool
extends Node2D
## ============================================================================
## Level — 关卡场景（场景直编：Ground/Obstacles 用 TileMap 涂格，实体=子节点）
## ----------------------------------------------------------------------------
## 场景树（纯作者驱动：World / Cam 摆哪就显示哪，脚本不做任何运行时位移）：
##   Level (本脚本，只做规则逻辑)
##   ├─ World              (Node2D)  内容容器（位置随你摆；默认 (0,0)）
##   │  ├─ Ground          (TileMapLayer)  手涂地板；地图范围=涂格包围盒
##   │  ├─ Obstacles       (TileMapLayer)  涂障碍（每个被涂的格=不可走）
##   │  ├─ EntityRoot      (Node2D)   PlayerSpawn / Goal / Food ×N / Mechanism ×N
##   │  ├─ MechanismCells  (TileMapLayer)  机关生长体（运行时同步实际占格）
##   │  └─ PlayerCells     (TileMapLayer)  玩家头/身（运行时按 trail 同步）
##   ├─ LevelHUD           (instance)
##   └─ Cam                (Camera2D)  运行时不移动、不缩放；作者自己摆放
## 规则权威：[docs/design/功能需求文档.md]；数值来自 GameManager.balance。
## ============================================================================

@export var level_id: int = 1
@export var level_name: String = "关卡"
@export var map_size: Vector2i = Vector2i(32, 32)

## 逻辑
var trail: Array[Vector2i] = []
var max_len: int = 3
var steps := 0
var food_eaten := 0
var total_food := 0
var input_locked := false
var finished := false

var grid := GridSystem.new()
var _board_origin := Vector2i.ZERO
var _board_size := Vector2i.ZERO

var _mechanisms: Array = []
var _foods: Array = []
var _goal: Goal = null
var _spawn: PlayerSpawn = null
var _head_cell := Vector2i.ZERO

const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

## 静态瓦片（PlayerCells 用 GameTiles.tres：头/身两块固定贴图）。
## Ground/Obstacles/MechanismCells 各自使用 TerrainFloor/Wall/Mech.tres，
## 每套只有 1 个 terrain（terrain_set=0, terrain=0），画格用 terrain connect 自动贴边。
const TILE_PLAYER_HEAD := 3
const TILE_PLAYER_BODY := 4
const TILE_SOURCE := 0

@onready var _ground: TileMapLayer = $World/Ground
@onready var _obstacles: TileMapLayer = $World/Obstacles
@onready var _mech_cells: TileMapLayer = $World/MechanismCells
@onready var _player_cells: TileMapLayer = $World/PlayerCells
@onready var _hud: CanvasLayer = $LevelHUD


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_collect_entities()
	_compute_board_rect()
	grid.setup(_board_origin, _board_size)
	for m in _mechanisms:
		m.set_grid_bounds(_board_origin, _board_size)
	_fill_ground_fallback()
	_place_player()
	_sync_player_layer()
	EventManager.level_loaded.emit(level_id)
	_check_deadlock()


# ── 实体收集（递归，任意层级都行）────────────────────────────────
func _collect_entities() -> void:
	_scan(self)


func _scan(node: Node) -> void:
	for child in node.get_children():
		if child is Food:
			_foods.append(child as Food)
			total_food += 1
		elif child is Goal:
			_goal = child as Goal
		elif child is PlayerSpawn:
			_spawn = child as PlayerSpawn
		elif child is Mechanism:
			_mechanisms.append(child as Mechanism)
		else:
			_scan(child)


## 自动地图范围 = Ground/Obstacles 涂格 + 实体格（Spawn/Goal/Food/Mechanism 核心）的外接矩形。
## 完全空白时退回 map_size 默认区（0,0 起）。
## 机关生长体只在"已涂地板范围"内生长；越界格会被 Mechanism.claim_missing 跳过（不铺新地板）。
func _compute_board_rect() -> void:
	var cells: Array[Vector2i] = []
	for c in _ground.get_used_cells():
		cells.append(c)
	for c in _obstacles.get_used_cells():
		cells.append(c)
	if _spawn:
		cells.append(_spawn.cell)
	if _goal:
		cells.append(_goal.cell)
	for f in _foods:
		cells.append(f.cell)
	for m in _mechanisms:
		cells.append(m.cell)
	if cells.is_empty():
		_board_origin = Vector2i.ZERO
		_board_size = map_size
		return
	var min_c := cells[0]
	var max_c := cells[0]
	for c in cells:
		min_c = Vector2i(mini(min_c.x, c.x), mini(min_c.y, c.y))
		max_c = Vector2i(maxi(max_c.x, c.x), maxi(max_c.y, c.y))
	_board_origin = min_c
	_board_size = max_c - min_c + Vector2i.ONE


## 地板兜底 + terrain 重连：把地图矩形内整块涂成地板，
## 用 set_cells_terrain_connect 让引擎按 4 角自动贴边（已涂格位置保持不变形）。
func _fill_ground_fallback() -> void:
	var cells: Array[Vector2i] = []
	for c in _ground.get_used_cells():
		cells.append(c)
	for y in _board_size.y:
		for x in _board_size.x:
			var cell := _board_origin + Vector2i(x, y)
			if not cells.has(cell):
				cells.append(cell)
	if cells.is_empty():
		return
	_ground.clear()
	_ground.set_cells_terrain_connect(cells, 0, 0, true)


func _place_player() -> void:
	# 障碍集：来自 Obstacles 层的每个被涂格子
	grid.obstacles.clear()
	for c in _obstacles.get_used_cells():
		grid.add_obstacle(c)

	if _spawn == null or _goal == null:
		push_error("Level %d: 需要 PlayerSpawn 与 Goal" % level_id)
		return
	grid.spawn_cell = _spawn.cell
	grid.goal_cell = _goal.cell
	trail = [_spawn.cell]
	_head_cell = _spawn.cell
	max_len = GameManager.balance.initial_max_len
	steps = 0
	food_eaten = 0
	finished = false
	_spawn.visible = false  # 出生点标识由玩家身体覆盖
	_claim_initial_mechanisms()
	_update_hud()
	_sync_mech_layer()


# ── 机关占格（身体/保护格挡住→跳过；lv 照升，下次生长重试）────────
func _blocked_cells() -> Dictionary:
	var blocked := {}
	for c in trail:
		blocked[c] = true
	if _spawn: blocked[_spawn.cell] = true
	if _goal: blocked[_goal.cell] = true
	return blocked


func _claim_initial_mechanisms() -> void:
	var blocked := _blocked_cells()
	for m in _mechanisms:
		m.claim_missing(blocked)
	_rebuild_mech_grid()


func _grow_all_mechanisms() -> void:
	var blocked := _blocked_cells()
	for m in _mechanisms:
		if m.level < MechanicShapes.max_level():
			m.set_level(m.level + 1)
			m.claim_missing(blocked)
	_sync_mech_layer()
	_rebuild_mech_grid()


## 把机关实际占格写入 grid.mech_cells（BFS/可走判定用），含核心格
func _rebuild_mech_grid() -> void:
	grid.mech_cells.clear()
	for m in _mechanisms:
		for cell in m.claimed:
			if grid.in_bounds(cell):
				grid.mech_cells[cell] = true


## 把机关实际占格(去掉核心)画到 MechanismCells 层（terrain 自动贴边）
func _sync_mech_layer() -> void:
	_mech_cells.clear()
	var cells: Array[Vector2i] = []
	for m in _mechanisms:
		for cell in m.body_cells():
			cells.append(cell)
	if cells.is_empty():
		return
	_mech_cells.set_cells_terrain_connect(cells, 0, 0, true)


## 把玩家 trail 画到 PlayerCells 层（头=HEAD，其余=BODY）
func _sync_player_layer() -> void:
	_player_cells.clear()
	for i in range(trail.size()):
		var tile := TILE_PLAYER_BODY if i < trail.size() - 1 else TILE_PLAYER_HEAD
		_player_cells.set_cell(trail[i], TILE_SOURCE, Vector2i(tile, 0))


# ── 输入（回合制单步）──────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	# 节点已脱离场景树（切场景瞬间）时不再处理输入，避免空 Viewport
	var vp := get_viewport()
	if vp == null:
		return
	if event.is_action_pressed("restart") and not event.is_echo():
		GameManager.restart_level()
		vp.set_input_as_handled()
		return
	if finished or input_locked:
		return
	for dir in DIRS:
		if event.is_action_pressed(_action_for(dir)) and not event.is_echo():
			_step(dir)
			vp.set_input_as_handled()
			return


func _action_for(d: Vector2i) -> String:
	match d:
		Vector2i.UP: return "move_up"
		Vector2i.DOWN: return "move_down"
		Vector2i.LEFT: return "move_left"
		Vector2i.RIGHT: return "move_right"
	return ""


## 一次走格。成功移动/截断算 1 步；无效移动不计步。
## 权威：身体 trail 长度 ≤ L（硬上限），禁止超长前进。
func _step(dir: Vector2i) -> void:
	var nxt := _head_cell + dir
	if not grid.in_bounds(nxt):
		return
	# 情况 B：踏入自己身体 → 截断到该格
	if trail.has(nxt):
		trail = trail.slice(0, trail.find(nxt) + 1)
		_head_cell = nxt
		steps += 1
		_after_action()
		return
	# 情况 A：可走格（障碍/机关占格不可入）
	if not grid.can_step_into(nxt):
		return
	if trail.size() >= max_len:
		return   # 身长硬上限：不可再向前进空格
	trail.append(nxt)
	_head_cell = nxt
	_consume_food_at(nxt)
	steps += 1
	_after_action()
	if nxt == grid.goal_cell:
		_win()


func _consume_food_at(cell: Vector2i) -> void:
	for f in _foods:
		if f.cell == cell:
			_foods.erase(f)
			f.queue_free()
			food_eaten += 1
			max_len += GameManager.balance.food_len_gain
			EventManager.max_length_changed.emit(max_len)
			EventManager.food_eaten.emit(cell)
			return


func _after_action() -> void:
	EventManager.player_moved.emit(_head_cell)
	EventManager.move_count_changed.emit(steps)
	_sync_player_layer()
	_update_hud()
	if steps > 0 and steps % GameManager.balance.growth_step_interval == 0:
		_growth_sequence()
	else:
		_check_deadlock()


func _growth_sequence() -> void:
	input_locked = true
	EventManager.input_locked.emit(true)
	var dur := GameManager.balance.grow_anim_sec
	for m in _mechanisms:
		var t := create_tween()
		m.scale = Vector2.ONE
		t.tween_property(m, "scale", Vector2(1.18, 1.18), dur * 0.4)
		t.tween_property(m, "scale", Vector2.ONE, dur * 0.6)
	_grow_all_mechanisms()
	EventManager.mechanism_grew.emit(_current_mech_level())
	await get_tree().create_timer(dur).timeout
	input_locked = false
	EventManager.input_locked.emit(false)
	if not finished:
		_check_deadlock()


func _current_mech_level() -> int:
	var lv := 0
	for m in _mechanisms:
		lv = maxi(lv, m.level)
	return lv


func _check_deadlock() -> void:
	if finished:
		return
	if _head_cell == grid.goal_cell:
		_win()
		return
	if not grid.has_path(_head_cell, grid.goal_cell):
		_fail()


func _win() -> void:
	if finished:
		return
	finished = true
	SaveManager.record_result("level_%d" % level_id, steps)
	EventManager.level_cleared.emit(level_id, steps)
	_hud.show_result("胜利！ 步数 %d" % steps)


func _fail() -> void:
	if finished:
		return
	finished = true
	EventManager.level_failed.emit(level_id)
	_hud.show_result("无路可走… 重开吧")


func _update_hud() -> void:
	_hud.update_stats(max_len, food_eaten, total_food, steps)
