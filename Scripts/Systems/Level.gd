@tool
extends Node2D
## ============================================================================
## Level — 关卡场景（场景直编：实体=Level 下任意子节点）
## ----------------------------------------------------------------------------
## 设计者：新建关卡 = 复制 LevelTemplate.tscn，把 PlayerSpawn / Obstacle /
##         Food / Goal / Mechanism 拖入场景，拖动即吸附格子；地图范围会
##         自动覆盖所有实体（也可在 Inspector 设 map_size 预留更大空间）。
## 引擎逻辑：身体=轨迹；每有效步 BFS 死局检测；每 balance.growth_step_interval
##         有效步机关全体生长一次（锁输入）；数值只读 GameManager.balance。
## ============================================================================

@export var level_id: int = 1
@export var level_name: String = "关卡"
@export var map_size: Vector2i = Vector2i(32, 32)

## 主角轨迹（身体=轨迹，尾部=trail[0]=S 恒为出生点）
var trail: Array[Vector2i] = []
var max_len: int = 3
var steps := 0
var food_eaten := 0
var total_food := 0
var input_locked := false
var finished := false

var grid := GridSystem.new()
var _board_size := Vector2i.ZERO      # 实际有效地图（>= map_size，覆盖实体）

var _mechanisms: Array = []
var _foods: Array = []
var _goal: Goal = null
var _spawn: PlayerSpawn = null
var _head_cell := Vector2i.ZERO

# UI
var _hud_max_len: Label
var _hud_food: Label
var _hud_steps: Label
var _overlay: Control
var _hud_panel: Label

const DIRS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	_collect_entities()
	_board_size = _compute_board_size()
	grid.setup(_board_size)
	for m in _mechanisms:
		m.set_grid_size(_board_size)   # 机关占格不越界
	_place_player()
	_build_ui()
	_fit_camera()
	EventManager.level_loaded.emit(level_id)
	# 关卡开局校验：出生点若已无通路到终点，直接判失败（关卡校验 §6.3）
	_check_deadlock()


# ── 实体收集（递归，任意层级都行）────────────────────────────────
func _collect_entities() -> void:
	_scan(self)


func _scan(node: Node) -> void:
	for child in node.get_children():
		if child is Obstacle:
			grid.add_obstacle((child as Obstacle).cell)
		elif child is Food:
			_foods.append(child as Food)
			total_food += 1
		elif child is Goal:
			_goal = child as Goal
		elif child is PlayerSpawn:
			_spawn = child as PlayerSpawn
		elif child is Mechanism:
			_mechanisms.append(child as Mechanism)
			(child as Mechanism).visible = true
		else:
			_scan(child)


## 自动地图范围：覆盖所有实体占格（含机关最远 21 格扩展），>= map_size
func _compute_board_size() -> Vector2i:
	var need := Vector2i.ZERO
	var consider: Array[Vector2i] = []
	if _spawn: consider.append(_spawn.cell)
	if _goal: consider.append(_goal.cell)
	for f in _foods: consider.append(f.cell)
	for m in _mechanisms:
		for off in MechanicShapes.cells(MechanicShapes.max_level()):
			consider.append(m.cell + off)
	# obstacles 已在 grid.obstacles
	for c in grid.obstacles:
		consider.append(c)
	for c in consider:
		need.x = maxi(need.x, c.x + 1)
		need.y = maxi(need.y, c.y + 1)
	need.x = maxi(need.x, map_size.x)
	need.y = maxi(need.y, map_size.y)
	return need


func _validate_entities() -> void:
	if _spawn == null:
		push_error("Level %d: 缺少 PlayerSpawn（出生点）" % level_id)
	if _goal == null:
		push_error("Level %d: 缺少 Goal（终点）" % level_id)


func _place_player() -> void:
	if _spawn == null:
		return
	grid.spawn_cell = _spawn.cell
	grid.goal_cell = _goal.cell if _goal else _spawn.cell
	trail = [_spawn.cell]
	_head_cell = _spawn.cell
	max_len = GameManager.balance.initial_max_len
	steps = 0
	food_eaten = 0
	finished = false
	# 出生点标记运行时隐藏（玩家身体会覆盖该格）
	_spawn.visible = false
	_claim_initial_mechanisms()
	queue_redraw()


# ── 机关占格（玩家身体阻挡→跳过；lv 照升，下次生长重试）────────────
## 把 grid.mech_cells 重建为所有机关 claimed 的并集（供可走/BFS 判定）
func _rebuild_mech_grid() -> void:
	grid.mech_cells.clear()
	for m in _mechanisms:
		for abs_cell in m.claimed:
			grid.mech_cells[abs_cell] = true


func _claim_initial_mechanisms() -> void:
	var blocked := _blocked_cells()
	for m in _mechanisms:
		m.claim_missing(blocked)   # 覆盖 initial_level>0 时的初始占格
	_rebuild_mech_grid()


func _grow_all_mechanisms() -> void:
	var blocked := _blocked_cells()
	for m in _mechanisms:
		if m.level < MechanicShapes.max_level():
			m.set_level(m.level + 1)
			m.claim_missing(blocked)
	_rebuild_mech_grid()


## 生长时不可占据：玩家身体 + 出生点 S + 终点 E（保护格，防机关吞掉胜负点）
func _blocked_cells() -> Dictionary:
	var blocked := {}
	for c in trail:
		blocked[c] = true
	if _spawn:
		blocked[_spawn.cell] = true
	if _goal:
		blocked[_goal.cell] = true
	return blocked


# ── 输入（回合制单步）──────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	# 重开永远可用（含机关动画期间）
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


## 一次走格。
##   - 踏入自己身体 → 截断（重规划）
##   - 踏入空格/食物/终点 → 需满足：格子可走 且 身体尚未到 L 上限
##   （权威：身长受限，trail(S→head) 恒 ≤ L，不可超长前进）
## 成功移动/截断算 1 步；无效移动不计步。
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
	# 身长受限：进入空格会使 trail 超过 L → 禁止（等吃食物 / 截断后）
	if trail.size() >= max_len:
		return
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
			queue_redraw()
			return


## 有效行动后的统一处理：HUD/生长/死局
func _after_action() -> void:
	EventManager.player_moved.emit(_head_cell)
	EventManager.move_count_changed.emit(steps)
	queue_redraw()
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
	_show_result("胜利！ 步数 %d" % steps)


func _fail() -> void:
	if finished:
		return
	finished = true
	EventManager.level_failed.emit(level_id)
	_show_result("无路可走… 重开吧")


# ── 绘制：底格 + 玩家身体（实体子节点自行绘制） ────────────────
func _draw() -> void:
	if _board_size == Vector2i.ZERO and not Engine.is_editor_hint():
		return
	var size := _board_size if _board_size != Vector2i.ZERO else map_size
	var px := GridMetrics.cell_px()
	var world := Vector2(size) * px
	# 空格底
	draw_rect(Rect2(Vector2.ZERO, world), Palette.BG_CELL)
	# 细格线
	for x in range(size.x + 1):
		draw_line(Vector2(x * px, 0), Vector2(x * px, world.y), Palette.BG_GRID, 1.0)
	for y in range(size.y + 1):
		draw_line(Vector2(0, y * px), Vector2(world.x, y * px), Palette.BG_GRID, 1.0)
	# 玩家（尾→头）绘制在底层上方由子节点覆盖；实际置顶由 player_layer 提供
	for i in range(trail.size()):
		var color := Palette.PLAYER_HEAD if i == trail.size() - 1 else Palette.PLAYER_BODY
		draw_rect(Rect2(GridMetrics.cell_to_pos(trail[i]), Vector2(px, px)), color)


# ── UI（顶部信息条 + 结算覆盖）────────────────────────────────────
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var bar := PanelContainer.new()
	bar.position = Vector2(12, 12)
	root.add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 28)
	bar.add_child(hb)

	_hud_max_len = _mk_label(hb, "L: %d" % max_len)
	_hud_food = _mk_label(hb, "")
	_hud_steps = _mk_label(hb, "")
	var btn_restart := Button.new()
	btn_restart.text = "重开 (R)"
	btn_restart.pressed.connect(GameManager.restart_level)
	var btn_back := Button.new()
	btn_back.text = "选关"
	btn_back.pressed.connect(GameManager.back_to_level_select)
	hb.add_child(btn_restart)
	hb.add_child(btn_back)

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	root.add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)
	_hud_panel = Label.new()
	_hud_panel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_panel.add_theme_font_size_override("font_size", 40)
	vbox.add_child(_hud_panel)
	var btn_again := Button.new()
	btn_again.text = "重开本关"
	btn_again.pressed.connect(GameManager.restart_level)
	var btn_select := Button.new()
	btn_select.text = "返回选关"
	btn_select.pressed.connect(GameManager.back_to_level_select)
	vbox.add_child(btn_again)
	vbox.add_child(btn_select)
	_update_hud()


func _mk_label(parent: Control, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20)
	parent.add_child(l)
	return l


func _update_hud() -> void:
	if _hud_max_len == null:
		return
	_hud_max_len.text = "最大身长 L: %d" % max_len
	_hud_food.text = "食物: %d/%d" % [food_eaten, total_food]
	_hud_steps.text = "步数: %d" % steps


func _show_result(text: String) -> void:
	_hud_panel.text = text
	_overlay.visible = true


func _fit_camera() -> void:
	var view := get_viewport().get_visible_rect().size
	var world := Vector2(_board_size) * GridMetrics.cell_px()
	var zoom := minf(view.x / world.x, (view.y - 90.0) / world.y)
	zoom = clampf(zoom, 0.2, 1.0)
	var cam := Camera2D.new()
	cam.zoom = Vector2(zoom, zoom)
	cam.position = world * 0.5
	add_child(cam)
