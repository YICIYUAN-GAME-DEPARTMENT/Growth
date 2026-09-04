extends Node
## ============================================================================
## RebuildLevelTiles — 用确定性格集重建关卡涂格（不产生 terrain connect 扩圈）
## ----------------------------------------------------------------------------
## Level_01 原始布局：Ground = 8x5 矩形(14,7)-(21,11)；Obstacles = 该矩形外圈 22 格。
## 每格瓦片列号 = 4 角掩码（bit0=TL…bit3=BR），按"同层格集"里对角邻居是否涂格计算，
## 与引擎 autotile 语义一致，但只写给定格、绝不外扩。
## 运行：godot --headless res://tools/RebuildLevelTiles.tscn
## ============================================================================

const SCENE := "res://Scenes/Levels/Level_01_教学关1.tscn"
const RECT := Rect2i(14, 7, 8, 5)   # 地板范围（外圈即障碍墙）

const DIRS := [
	Vector2i(-1, -1), Vector2i(1, -1),   # TL TR 邻格（用于 bit0/bit1）
	Vector2i(-1, 1), Vector2i(1, 1),     # BL BR
]


func _ready() -> void:
	var ps: PackedScene = load(SCENE)
	var root: Node = ps.instantiate()

	var ground_set := {}
	for y in RECT.size.y:
		for x in RECT.size.x:
			ground_set[Vector2i(RECT.position.x + x, RECT.position.y + y)] = true
	var wall_set := {}
	for y in RECT.size.y:
		for x in RECT.size.x:
			var c := Vector2i(RECT.position.x + x, RECT.position.y + y)
			var border := x == 0 or y == 0 or x == RECT.size.x - 1 or y == RECT.size.y - 1
			if border:
				wall_set[c] = true

	var world := root.get_node_or_null("World")
	_paint(world.get_node("Ground") as TileMapLayer, ground_set, "res://Art/Tiles/TerrainFloor.tres")
	_paint(world.get_node("Obstacles") as TileMapLayer, wall_set, "res://Art/Tiles/TerrainWall.tres")
	# MechanismCells / PlayerCells 保持空（只确认瓦片集）
	(world.get_node("MechanismCells") as TileMapLayer).tile_set = load("res://Art/Tiles/TerrainMech.tres")
	(world.get_node("PlayerCells") as TileMapLayer).tile_set = load("res://Art/Tiles/PlayerSnek.tres")

	var packed := PackedScene.new()
	packed.pack(root)
	var err := ResourceSaver.save(packed, SCENE)
	root.free()
	print("保存 err=%d Ground=%d Obstacles=%d" % [err, ground_set.size(), wall_set.size()])
	get_tree().quit(0)


func _paint(layer: TileMapLayer, set: Dictionary, ts_path: String) -> void:
	layer.tile_set = load(ts_path)
	layer.clear()
	for c in set:
		var mask := 0
		for b in 4:
			if set.has(c + DIRS[b]):
				mask |= 1 << b
		layer.set_cell(c, 0, Vector2i(mask, 0))
