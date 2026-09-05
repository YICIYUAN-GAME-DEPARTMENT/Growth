extends Node
## ============================================================================
## MigrateTerrain — 把关卡场景迁移到 Terrain 自动贴边（确定性直写）
## ----------------------------------------------------------------------------
## 对每个场景的 Ground/Obstacles/MechanismCells/PlayerCells：
##   1. 记录已涂格子位置（来自旧数据）
##   2. 换成对应 TerrainFloor/Wall/Mech/PlayerSnek.tres 并清空
##   3. 逐格写瓦片：列号 = 4 角掩码（按"同层格集"对角邻居计算），绝不外扩
## 注：已是 blob47 地板（corners+sides）的层整层保留，不做 4 角重涂。
## 之后用 PackedScene.pack+save 保存（已验证会保留子场景 instance 引用）。
## 运行：godot --headless res://tools/MigrateTerrain.tscn
## ============================================================================

const SCENES := [
	"res://Scenes/Levels/Level_01_教学关1.tscn",
	"res://Scenes/Levels/LevelTemplate.tscn",
]
const LAYER_TS := {
	"Ground": "res://Art/Tiles/TerrainFloor.tres",
	"Obstacles": "res://Art/Tiles/TerrainWall.tres",
	"MechanismCells": "res://Art/Tiles/TerrainMech.tres",
	"PlayerCells": "res://Art/Tiles/PlayerSnek.tres",
}
## 4 对角邻格（bit0=TL bit1=TR bit2=BL bit3=BR）
const CORNERS := [
	Vector2i(-1, -1), Vector2i(1, -1),
	Vector2i(-1, 1), Vector2i(1, 1),
]


func _ready() -> void:
	for scene_path in SCENES:
		var ps: PackedScene = load(scene_path)
		if ps == null:
			push_error("无法加载场景 " + scene_path)
			continue
		var root: Node = ps.instantiate()
		var world := root.get_node_or_null("World")
		var notes: PackedStringArray = []
		for name in LAYER_TS:
			var layer := world.get_node_or_null(name) as TileMapLayer
			if layer == null:
				notes.append("%s=无节点" % name)
				continue
			# blob47 地板（corners+sides）已是新目标布局：整层保留，不做 4 角重涂
			if _is_blob(layer):
				notes.append("%s=blob保留" % name)
				continue
			var cells := layer.get_used_cells()
			var in_set := {}
			for c in cells:
				in_set[c] = true
			layer.tile_set = load(LAYER_TS[name])
			layer.clear()
			for c in cells:
				var mask := 0
				for b in 4:
					if in_set.has(c + CORNERS[b]):
						mask |= 1 << b
				layer.set_cell(c, 0, Vector2i(mask, 0))
			notes.append("%s:%d格" % [name, cells.size()])
		_ensure_player_fx(world, root)
		var packed := PackedScene.new()
		packed.pack(root)
		var err := ResourceSaver.save(packed, scene_path)
		root.free()
		print("%s → %s 保存err=%d" % [scene_path, " ".join(notes), err])
	get_tree().quit(0)


func _is_blob(layer: TileMapLayer) -> bool:
	var ts := layer.tile_set
	if ts == null or ts.get_terrain_sets_count() <= 0:
		return false
	return ts.get_terrain_set_mode(0) == TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES


## PlayerFx：头/尾独立 Sprite 的容器（Level.gd 运行时驱动位置/帧/可见性，
## 头按方向行选片不旋转、尾按方向旋转）
func _ensure_player_fx(world: Node, root: Node) -> void:
	if world.get_node_or_null("PlayerFx") != null:
		return
	var fx := Node2D.new()
	fx.name = "PlayerFx"
	world.add_child(fx)
	fx.owner = root
	var head := Sprite2D.new()
	head.name = "Head"
	head.texture = load("res://Art/Sprites/player_head.svg")
	# 头精灵表：4 行方向 × 3 列帧（0/1=移动循环 2=停留帧），行选片不旋转
	head.hframes = 3
	head.vframes = 4
	head.visible = false
	fx.add_child(head)
	head.owner = root
	var tail := Sprite2D.new()
	tail.name = "Tail"
	tail.texture = load("res://Art/Sprites/player_tail.svg")
	tail.visible = false
	fx.add_child(tail)
	tail.owner = root
	print("  已创建 PlayerFx/Head+Tail")
