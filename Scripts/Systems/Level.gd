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
##   │  ├─ MechanismCells  (TileMapLayer)  机关生长体（运行时同步实际占格，含核心格）
##   │  ├─ PlayerCells     (TileMapLayer)  玩家管道中段 + 头/尾端点半截瓦（运行时按 trail 同步）
##   │  └─ PlayerFx        (Node2D)       Head/Tail 两个 Sprite（Head z 高于 Tail，头可叠尾上）
##   ├─ LevelHUD           (instance)
##   └─ Cam                (Camera2D)  运行时不移动、不缩放；作者自己摆放
## 规则权威：[docs/design/功能需求文档.md]；数值 = 全局 Balance 基准，可被本关 *_override 覆盖。
## ============================================================================

@export var level_id: int = 1
@export var level_name: String = "关卡"
@export var map_size: Vector2i = Vector2i(32, 32)

@export_group("本关数值（0 = 沿用全局 Balance.tres）")
## 初始最大身长 L；>0 时本关覆盖全局
@export var initial_max_len_override: int = 0
## 吃到 1 个食物增长的最大身长 ΔL；>0 时本关覆盖全局
@export var food_len_gain_override: int = 0
## 机关最高阶段（0..4）；>0 时本关覆盖全局
@export var mechanism_max_level_override: int = 0
## 每累计多少有效步机关生长一次；>0 时本关覆盖全局
@export var growth_step_interval_override: int = 0
## 说明：grow_anim_sec（生长动画时长）只在全局 Balance.tres，不进关卡。

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
## 本关机关生长周期（_place_player 时解析 override/全局）
var _growth_interval := 6

## 头部动画状态：方向行（0=E 1=W 2=S 3=N）与帧列（0/1=移动循环 2=停留）
var _head_dir_row := 0
var _head_col := HEAD_IDLE_COL
var _head_walk_flip := false
var _head_idle_seq := 0

const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## 4 个对角邻格（列号掩码位：bit0=TL bit1=TR bit2=BL bit3=BR，与 Terrain* 瓦片集一致）
const CORNER_OFFS := [
	Vector2i(-1, -1), Vector2i(1, -1),
	Vector2i(-1, 1), Vector2i(1, 1),
]

## 地形层：Ground/Obstacles/MechanismCells 各自使用 TerrainFloor/Wall/Mech.tres
## （三张独立纹理），每套只有 1 个 terrain（terrain_set=0, terrain=0）；运行期用
## _paint_auto 按格集几何直写 4 角掩码瓦片（确定性贴边，绝不外扩）。
## 玩家视觉：
##   · PlayerCells 画身体"管道"（PlayerSnek.tres row0）：
##     · 中间格（前后都有格）用连接件 0=横直 1=竖直 2=弯NE 3=弯NW 4=弯SW 5=弯SE，
##       每格连接前格与后格，相邻瓦片拼成连续管道；
##     · 头格/尾格垫"端点"半截瓦 6=E 7=W 8=S 9=N（中心→边），把管道接进头/尾底下。
##   · 头/尾是独立 Sprite 贴图（非瓦片，画布可大于单格）：头位于 head 格，方向用
##     贴图行选片（player_head.svg = 4 行方向 × 3 列帧精灵表，E/W/S/N 各画各的、
##     不旋转），移动时帧列 0/1 两帧循环，停下 HEAD_IDLE_SEC 秒后固定停留帧 2；
##     尾固定在出生点 S 格（起步即显示），朝身体延伸方向旋转。Head 在场景里
##     z_index=1，起步/回到起点（n=1）时"头叠放在尾之上"。二者挂在 World/PlayerFx
##     下，贴图与 hframes/vframes 由场景直接绑定。
const TILE_SOURCE := 0
## 机关生长体动画帧行（terrain_mech.svg 3 行：0=冒出 1=生长中 2=完成）
const MECH_FRAME_DONE := 2
## 头部动画规格（player_head.svg 4 行方向 × 3 列帧）
## 帧列：0/1=移动两帧循环 2=停留固定；停留判定：HEAD_IDLE_SEC 秒内无新步
const HEAD_IDLE_COL := 2
const HEAD_IDLE_SEC := 0.35

@onready var _ground: TileMapLayer = $World/Ground
@onready var _obstacles: TileMapLayer = $World/Obstacles
@onready var _mech_cells: TileMapLayer = $World/MechanismCells
@onready var _player_cells: TileMapLayer = $World/PlayerCells
@onready var _player_fx: Node2D = $World/PlayerFx
@onready var _head_sprite: Sprite2D = $World/PlayerFx/Head
@onready var _tail_sprite: Sprite2D = $World/PlayerFx/Tail
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
	# PlayerFx 容器在场景里可能被作者隐藏（编辑器不挡眼）；运行时必须打开，
	# 否则 Head/Tail 各自 visible=true 也不会渲染（父节点不可见）。
	_player_fx.visible = true
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


## 确定性贴边：给整层清空后，按"格集"几何写瓦片（列号=4 角掩码，行号=frame），
## 只写给定格、绝不外扩。floor/wall 单行图（frame 恒 0）；mech 3 帧行，
## 停留外观=MECH_FRAME_DONE（完成帧）。
func _paint_auto(layer: TileMapLayer, cells: Array, frame: int = 0) -> void:
	layer.clear()
	var set := {}
	for c: Vector2i in cells:
		set[c] = true
	for c: Vector2i in cells:
		var mask := 0
		for b in 4:
			if set.has(c + CORNER_OFFS[b]):
				mask |= 1 << b
		layer.set_cell(c, TILE_SOURCE, Vector2i(mask, frame))


## 地板兜底：把地图矩形内整块涂成地板（已涂格位置不变，整层按几何重贴边）
func _fill_ground_fallback() -> void:
	var cells: Array = []
	for c: Vector2i in _ground.get_used_cells():
		cells.append(c)
	for y in _board_size.y:
		for x in _board_size.x:
			var cell := _board_origin + Vector2i(x, y)
			if not cells.has(cell):
				cells.append(cell)
	if cells.is_empty():
		return
	_paint_auto(_ground, cells)


## override 为 0 时沿用全局 Balance 数值
func _resolve(override_val: int, global_val: int) -> int:
	return global_val if override_val <= 0 else override_val


func _place_player() -> void:
	# 障碍集：来自 Obstacles 层的每个被涂格子
	grid.obstacles.clear()
	for c in _obstacles.get_used_cells():
		grid.add_obstacle(c)

	if _spawn == null or _goal == null:
		push_error("Level %d: 需要 PlayerSpawn 与 Goal" % level_id)
		return
	grid.goal_cell = _goal.cell
	trail = [_spawn.cell]
	_head_cell = _spawn.cell
	max_len = _resolve(initial_max_len_override, GameManager.balance.initial_max_len)
	_growth_interval = _resolve(growth_step_interval_override, GameManager.balance.growth_step_interval)
	steps = 0
	food_eaten = 0
	finished = false
	_spawn.visible = false  # 出生点标识由玩家身体覆盖
	# 机关本关最高阶段（在首次占格前注入）
	var cap := _resolve(mechanism_max_level_override, GameManager.balance.mechanism_max_level)
	for m in _mechanisms:
		m.set_level_cap(cap)
	var added := _claim_initial_mechanisms()
	_update_hud()
	_sync_mech_layer()
	_pop_mech_cells(added)  # 范围初建同样播一次出场动画


# ── 机关占格（身体/保护格挡住→跳过；lv 照升，下次生长重试）────────
func _blocked_cells() -> Dictionary:
	var blocked := {}
	for c in trail:
		blocked[c] = true
	if _spawn: blocked[_spawn.cell] = true
	if _goal: blocked[_goal.cell] = true
	return blocked


## 首次占格：把 shape(level) 中未占的格加入 claimed。返回本次新增占格
## （= 范围初建"更新的部分"，供出场动画播放）。
func _claim_initial_mechanisms() -> Array:
	var blocked := _blocked_cells()
	var added: Array = []
	for m in _mechanisms:
		m.claim_missing(blocked)
		for c in m.claimed:
			added.append(c)
	_rebuild_mech_grid()
	return added


## 机关生长：未满级则 +1 阶段；满级后每次生长仍刷新——把此前被玩家身体
## 挡住、现已空出的 shape 格补齐（阶段维持在本关最高 level_cap）。
## 新增占格 = "范围更新的部分"，同步铺瓦后播一次出场动画。
func _grow_all_mechanisms() -> void:
	var before := {}
	for m in _mechanisms:
		for c in m.claimed:
			before[c] = true
	var blocked := _blocked_cells()
	for m in _mechanisms:
		if m.level < m.level_cap:
			m.set_level(m.level + 1)
		m.claim_missing(blocked)
	var added: Array = []
	for m in _mechanisms:
		for c in m.claimed:
			if not before.has(c):
				added.append(c)
	_sync_mech_layer()
	_rebuild_mech_grid()
	_pop_mech_cells(added)


## 出场动画：新增占格按 3 帧行（0=冒出 1=生长中 2=完成）随 grow_anim_sec
## 播放一次，之后停在完成帧（与既有格外观一致）。
func _pop_mech_cells(cells: Array) -> void:
	if cells.is_empty():
		return
	_set_mech_frame(cells, 0)
	var dur: float = maxf(GameManager.balance.grow_anim_sec, 0.01)
	var tw := create_tween()
	tw.tween_interval(dur / 3.0)
	tw.tween_callback(_set_mech_frame.bind(cells, 1))
	tw.tween_interval(dur / 3.0)
	tw.tween_callback(_set_mech_frame.bind(cells, MECH_FRAME_DONE))


## 批量改机关生长体瓦片的帧行（列 = 4 角掩码不变）
func _set_mech_frame(cells: Array, frame: int) -> void:
	for c: Vector2i in cells:
		var cur := _mech_cells.get_cell_atlas_coords(c)
		if cur.x < 0:
			continue  # 格已不存在（层被重建），跳过
		_mech_cells.set_cell(c, TILE_SOURCE, Vector2i(cur.x, frame))


## 把机关实际占格写入 grid.mech_cells（BFS/可走判定用），含核心格
func _rebuild_mech_grid() -> void:
	grid.mech_cells.clear()
	for m in _mechanisms:
		for cell in m.claimed:
			if grid.in_bounds(cell):
				grid.mech_cells[cell] = true


## 把机关实际占格（含核心格）画到 MechanismCells 层（确定性贴边）。
## 统一铺在完成帧（MECH_FRAME_DONE）——新增格由 _pop_mech_cells 覆盖播放
## 出场动画。核心格同样铺瓦：贴边掩码天然把核心算作生长体的一部分，核心与
## 生长体相邻角点不缺瓦；核心外观由 Core Sprite（z_index=1）浮在瓦片上层绘制。
func _sync_mech_layer() -> void:
	var cells: Array = []
	for m in _mechanisms:
		for cell: Vector2i in m.claimed:
			cells.append(cell)
	if cells.is_empty():
		_mech_cells.clear()
		return
	_paint_auto(_mech_cells, cells, MECH_FRAME_DONE)


## 同步玩家视觉：
## 身体中段只画"前后都有格子的中间格"管道连接件（连前一个格与后一个格）；
## 头/尾格各垫一块"端点"半截瓦（中心→邻边，col6..9），把管道接进头/尾底部——
## 端点瓦先于 PlayerFx 绘制，被头/尾贴图盖住的部分形成"管道从贴图底下接入"。
## 头/尾为独立 Sprite（可大于单格），跟随 head / 出生点 S，按方向旋转，不占瓦片。
func _sync_player_layer() -> void:
	_player_cells.clear()
	var n := trail.size()
	for i in range(1, n - 1):
		_player_cells.set_cell(trail[i], TILE_SOURCE, _body_connector(i))
	if n > 1:
		# 尾格（起点 S）：半截瓦指向身体延伸方向
		_player_cells.set_cell(trail[0], TILE_SOURCE, _endpoint_col(trail[1] - trail[0]))
		# 头格：半截瓦指向"身后那格"（进入该格的方向）
		_player_cells.set_cell(trail[n - 1], TILE_SOURCE, _endpoint_col(trail[n - 1] - trail[n - 2]))
	_update_end_sprites(n)


## 中间身体格连接件：由进入方向 a、离开方向 b 决定 直/弯 列号（row0）
func _body_connector(i: int) -> Vector2i:
	var a := trail[i] - trail[i - 1]
	var b := trail[i + 1] - trail[i]
	if a == b:  # 直
		return Vector2i(0 if a.x != 0 else 1, 0)
	return Vector2i(_corner_col(a, b), 0)


## 端点半截瓦列号：由"邻格 - 本格"定方向（6=E 7=W 8=S 9=N，与 GenSnek 图集一致）
func _endpoint_col(d: Vector2i) -> Vector2i:
	match d:
		Vector2i.RIGHT: return Vector2i(6, 0)
		Vector2i.LEFT: return Vector2i(7, 0)
		Vector2i.DOWN: return Vector2i(8, 0)
	return Vector2i(9, 0)   # UP


func _update_end_sprites(n: int) -> void:
	# 头：位于 head 格；方向用贴图行选片（E/W/S/N 各画各的，不旋转），
	# 帧列由 _head_col 决定（移动循环/停留帧，_advance_head_walk 推进）。
	_head_sprite.visible = n > 0
	var face := trail[n - 1] - trail[n - 2] if n > 1 else Vector2i.RIGHT
	_head_dir_row = _head_row_for(face)
	_head_sprite.position = GridMetrics.cell_center(trail[n - 1])
	_head_sprite.rotation = 0.0
	_apply_head_frame()
	# 尾（机器）：固定在出生点 S，从开局（n=1）就显示——起步/回到起点时头叠放在其上；
	# 朝向"身体延伸方向"，n=1 无身段时默认朝右。
	_tail_sprite.visible = n > 0
	var out_dir := trail[1] - trail[0] if n > 1 else Vector2i.RIGHT
	_tail_sprite.position = GridMetrics.cell_center(trail[0])
	_tail_sprite.rotation = Vector2(out_dir).angle()


## 方向 -> 头贴图行（player_head.svg 4 行：0=E右 1=W左 2=S下 3=N上）
func _head_row_for(face: Vector2i) -> int:
	match face:
		Vector2i.LEFT: return 1
		Vector2i.DOWN: return 2
		Vector2i.UP: return 3
	return 0  # E 右


## 头帧号 = 方向行 × 3 + 帧列（hframes=3 由场景绑定）
func _apply_head_frame() -> void:
	_head_sprite.frame = _head_dir_row * 3 + _head_col


## 每次有效步推进头部"两帧循环"，并重置停留计时：
## HEAD_IDLE_SEC 秒内无新步 -> 固定到停留帧（列 2）。
func _advance_head_walk() -> void:
	_head_walk_flip = not _head_walk_flip
	_head_col = 1 if _head_walk_flip else 0
	_apply_head_frame()
	_head_idle_seq += 1
	get_tree().create_timer(HEAD_IDLE_SEC).timeout.connect(_on_head_idle.bind(_head_idle_seq))


func _on_head_idle(seq: int) -> void:
	if seq != _head_idle_seq:
		return  # 期间又有新步，该计时器已过期
	_head_col = HEAD_IDLE_COL
	_apply_head_frame()


## 弯角瓦片列号：按入口边与出口边围出的外侧拐角（b - a）定 4 种朝向
func _corner_col(a: Vector2i, b: Vector2i) -> int:
	var s := b - a
	if s == Vector2i(1, -1):
		return 2  # NE
	if s == Vector2i(-1, -1):
		return 3  # NW
	if s == Vector2i(-1, 1):
		return 4  # SW
	return 5      # SE


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
			max_len += _resolve(food_len_gain_override, GameManager.balance.food_len_gain)
			EventManager.max_length_changed.emit(max_len)
			EventManager.food_eaten.emit(cell)
			return


func _after_action() -> void:
	_advance_head_walk()  # 头部移动两帧循环 + 停留计时
	EventManager.player_moved.emit(_head_cell)
	EventManager.move_count_changed.emit(steps)
	_sync_player_layer()
	_update_hud()
	if steps > 0 and steps % _growth_interval == 0:
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
		return
	# 身长可达判定（仅身长已达上限时触发）：尾部钉死 S，头可随时踏回身体
	# 截断重规划——等效"从 S 重新出发、最多走 max_len-1 步"（身体不算阻挡，
	# 可踏上即截断）。身长未满时玩家还能继续前进探索，不判定；伸到最长后若
	# 终点与所有剩余食物都超出该范围，L 永不再增长（吃食物是唯一途径）且
	# 可达范围只缩不增（机关不可逆）⇒ 必然死局。
	if trail.size() < max_len:
		return
	if _spawn == null:
		return
	var reach := max_len - 1
	var dist := grid.bfs_dist_map(_spawn.cell)
	if dist.has(grid.goal_cell) and dist[grid.goal_cell] <= reach:
		return  # 终点在当前身长可达范围内
	for f in _foods:
		if dist.has(f.cell) and dist[f.cell] <= reach:
			return  # 还能吃到食物增大 L
	_fail("身长不够… 够不着终点也吃不到食物")


func _win() -> void:
	if finished:
		return
	finished = true
	SaveManager.record_result("level_%d" % level_id, steps)
	EventManager.level_cleared.emit(level_id, steps)
	_hud.show_result("胜利！ 步数 %d" % steps)


func _fail(msg: String = "无路可走… 重开吧") -> void:
	if finished:
		return
	finished = true
	EventManager.level_failed.emit(level_id)
	_hud.show_result(msg)


func _update_hud() -> void:
	var remaining_steps := maxi(max_len - trail.size(), 0)
	_hud.update_remaining_steps(remaining_steps)
