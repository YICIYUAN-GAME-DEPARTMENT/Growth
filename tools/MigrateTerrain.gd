extends Node
## ============================================================================
## MigrateTerrain — 把关卡场景迁移到 Terrain 自动贴边
## ----------------------------------------------------------------------------
## 对每个场景的 Ground/Obstacles/MechanismCells：
##   1. 记录已涂格子位置（来自旧 GameTiles.tres 数据）
##   2. 换成对应 TerrainFloor/Wall/Mech.tres 并清空
##   3. 用 set_cells_terrain_connect 重新涂格（引擎按 4 角自动选片）
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
}


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
			var cells: Array[Vector2i] = []
			for c in layer.get_used_cells():
				cells.append(c)
			layer.tile_set = load(LAYER_TS[name])
			layer.clear()
			if not cells.is_empty():
				layer.set_cells_terrain_connect(cells, 0, 0, true)
			notes.append("%s:%d格" % [name, cells.size()])
		var packed := PackedScene.new()
		packed.pack(root)
		var err := ResourceSaver.save(packed, scene_path)
		root.free()
		print("%s → %s 保存err=%d" % [scene_path, " ".join(notes), err])
	get_tree().quit(0)
