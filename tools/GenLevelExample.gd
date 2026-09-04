extends Node
## ============================================================================
## GenLevelExample — 一次性生成 Scenes/Levels/Level_Example.tscn
## ----------------------------------------------------------------------------
## 运行：godot --headless res://tools/GenLevelExample.tscn
## 作用：程序化往 LevelTemplate 实例里涂 Ground/Obstacles TileMap，
##       摆放实体，然后 pack 成 .tscn 保存。之后该关卡即可在编辑器继续编辑。
## 删除本目录不影响运行。
## ============================================================================

const OUT := "res://Scenes/Levels/Level_Example.tscn"
const TEMPLATE := "res://Scenes/Levels/LevelTemplate.tscn"

const TILE_SRC := 0
const ATL_FLOOR := Vector2i(0, 0)
const ATL_WALL := Vector2i(1, 0)

## 示例布局（10 列 x 4 行，行 1 是走廊；机关在右下角演示生长）
const MAP_W := 10
const MAP_H := 4
const SPAWN := Vector2i(1, 1)
const GOAL := Vector2i(7, 1)
const FOODS := [Vector2i(3, 1), Vector2i(5, 1)]
const OBSTACLES := [Vector2i(8, 3), Vector2i(9, 3), Vector2i(4, 0), Vector2i(5, 0)]
const MECH_CELL := Vector2i(5, 3)


func _ready() -> void:
	var tmpl: PackedScene = load(TEMPLATE)
	if tmpl == null:
		push_error("模板缺失")
		get_tree().quit(1)
		return
	var level := tmpl.instantiate()
	var ground := level.get_node("Ground") as TileMapLayer
	var obstacles := level.get_node("Obstacles") as TileMapLayer

	# 地板整片涂满
	for y in MAP_H:
		for x in MAP_W:
			ground.set_cell(Vector2i(x, y), TILE_SRC, ATL_FLOOR)
	# 障碍涂格
	for c in OBSTACLES:
		obstacles.set_cell(c, TILE_SRC, ATL_WALL)

	# 根导出
	level.set("level_id", 1)
	level.set("level_name", "示例：吃食物，走向终点")
	level.set("map_size", Vector2i(MAP_W, MAP_H))

	# 实体（Food/Goal/Mechanism 场景实例直接做子节点）
	var er := level.get_node("EntityRoot") as Node2D

	var spawn_ps: PackedScene = load("res://Scenes/Entities/PlayerSpawn.tscn")
	var spawn := spawn_ps.instantiate()
	spawn.set("cell", SPAWN)
	spawn.position = GridMetrics.cell_center(SPAWN)
	er.add_child(spawn)

	var goal_ps: PackedScene = load("res://Scenes/Entities/Goal.tscn")
	var goal := goal_ps.instantiate()
	goal.set("cell", GOAL)
	goal.position = GridMetrics.cell_center(GOAL)
	er.add_child(goal)

	var food_ps: PackedScene = load("res://Scenes/Entities/Food.tscn")
	for c in FOODS:
		var f := food_ps.instantiate()
		f.set("cell", c)
		f.position = GridMetrics.cell_center(c)
		er.add_child(f)

	var mech_ps: PackedScene = load("res://Scenes/Entities/Mechanism.tscn")
	var mech := mech_ps.instantiate()
	mech.set("cell", MECH_CELL)
	mech.position = GridMetrics.cell_center(MECH_CELL)
	mech.set("initial_level", 0)
	er.add_child(mech)

	# owner 树：把新增节点挂到 level 以便 PackedScene 序列化
	_assign_owners(level, level)

	var packed := PackedScene.new()
	var err := packed.pack(level)
	if err != OK:
		push_error("pack 失败 %d" % err)
		get_tree().quit(1)
		return
	err = ResourceSaver.save(packed, OUT)
	if err != OK:
		push_error("保存失败 %d" % err)
		get_tree().quit(1)
		return
	print("Level_Example.tscn 已生成: ", OUT)
	level.queue_free()
	get_tree().quit(0)


func _assign_owners(node: Node, root: Node) -> void:
	node.owner = root
	for child in node.get_children():
		_assign_owners(child, root)
