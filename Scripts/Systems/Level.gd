@tool
extends Node2D
## ============================================================================
## Level — 关卡场景（场景直编：Ground/Obstacles 用 TileMap 涂格，实体=子节点）
## ----------------------------------------------------------------------------
## 场景树：
##   Level (本脚本，只做规则逻辑)
##   ├─ Ground           (TileMapLayer)  手涂地板；没涂则运行时兜底铺满
##   ├─ Obstacles        (TileMapLayer)  涂障碍（每个被涂的格=不可走）
##   ├─ EntityRoot       (Node2D)        PlayerSpawn / Goal / Food ×N / Mechanism ×N
##   ├─ MechanismCells   (TileMapLayer)  机关生长体（运行时同步实际占格）
##   ├─ PlayerCells      (TileMapLayer)  玩家头/身（运行时按 trail 同步）
##   ├─ LevelHUD         (instance)
##   └─ (Camera2D 由本脚本运行时创建)
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
var _board_size := Vector2i.ZERO

var _mechanisms: Array = []
var _foods: Array = []
var _goal: Goal = null
var _spawn: PlayerSpawn = null
var _head_cell := Vector2i.ZERO

const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

## TileSet 里 atlas 的 x 下标（对应 GameTiles.tres）
const TILE_FLOOR := 0
const TILE_OBSTACLE := 1
const TILE_MECH := 2
const TILE_PLAYER_HEAD := 3
const TILE_PLAYER_BODY := 4
const TILE_SOURCE := 0

@onready var _ground: TileMapLayer = $Ground
@onready var _obstacles: TileMapLayer = $Obstacles
@onready var _mech_cells: TileMapLayer = $MechanismCells
@onready var _player_cells: TileMapLayer = $PlayerCells
@onready var _hud: CanvasLayer = $LevelHUD


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_collect_entities()
	_board_size = _compute_board_size()
	grid.setup(_board_size)
	for m in _mechanisms:
		m.set_grid_size(_board_size)
	_fill_ground_fallback()
	_place_player()
	_sync_player_layer()
	_fit_camera()
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


## 自动地图范围：>= map_size，并覆盖障碍涂格/实体/机关最大扩展
func _compute_board_size() -> Vector2i:
	var need := map_size
	# 背景涂格也参与定界
	for c in _ground.get_used_cells():
		need.x = maxi(need.x, c.x + 1)
		need.y = maxi(need.y, c.y + 1)
	for c in _obstacles.get_used_cells():
		need.x = maxi(need.x, c.x + 1)
		need.y = maxi(need.y, c.y + 1)
	var consider: Array[Vector2i] = []
	if _spawn: consider.append(_spawn.cell)
	if _goal: consider.append(_goal.cell)
	for f in _foods: consider.append(f.cell)
	for m in _mechanisms:
		for off in MechanicShapes.cells(MechanicShapes.max_level()):
			consider.append(m.cell + off)
	for c in consider:
		need.x = maxi(need.x, c.x + 1)
		need.y = maxi(need.y, c.y + 1)
	return need


## 地板兜底：没涂 Ground 或留空的格，运行期铺一层默认地板
func _fill_ground_fallback() -> void:
	for y in _board_size.y:
		for x in _board_size.x:
			var cell := Vector2i(x, y)
			if _ground.get_cell_source_id(cell) == -1:
				_ground.set_cell(cell, TILE_SOURCE, Vector2i(TILE_FLOOR, 0))


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


func _grow_all_mechanisms() -> void:
	var blocked := _blocked_cells()
	for m in _mechanisms:
		if m.level < MechanicShapes.max_level():
			m.set_level(m.level + 1)
			m.claim_missing(blocked)
	_sync_mech_layer()


## 把机关实际占格(去掉核心)画到 MechanismCells 层
func _sync_mech_layer() -> void:
	_mech_cells.clear()
	for m in _mechanisms:
		for cell in m.body_cells():
			_mech_cells.set_cell(cell, TILE_SOURCE, Vector2i(TILE_MECH, 0))


## 把玩家 trail 画到 PlayerCells 层（头=HEAD，其余=BODY）
func _sync_player_layer() -> void:
	_player_cells.clear()
	for i in range(trail.size()):
		var tile := TILE_PLAYER_BODY if i < trail.size() - 1 else TILE_PLAYER_HEAD
		_player_cells.set_cell(trail[i], TILE_SOURCE, Vector2i(tile, 0))


# ── 输入（回合制单步）──────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and not event.is_echo():
		GameManager.restart_level()
		get_viewport().set_input_as_handled()
		return
	if finished or input_locked:
		return
	for dir in DIRS:
		if event.is_action_pressed(_action_for(dir)) and not event.is_echo():
			_step(dir)
			get_viewport().set_input_as_handled()
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


func _fit_camera() -> void:
	var cam := get_node_or_null("Cam") as Camera2D
	if cam == null:
		return
	var view := get_viewport().get_visible_rect().size
	var world := Vector2(_board_size) * GridMetrics.cell_px()
	var zoom := minf(view.x / world.x, (view.y - 90.0) / world.y)
	cam.zoom = Vector2(clampf(zoom, 0.2, 1.0), clampf(zoom, 0.2, 1.0))
	cam.position = world * 0.5
