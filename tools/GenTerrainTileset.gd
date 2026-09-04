extends Node
## ============================================================================
## GenTerrainTileset — 程序化生成含 Terrain 的 Art/Tiles/TerrainFloor.tres
## ----------------------------------------------------------------------------
## 图源：Art/Tiles/terrain_placeholder.svg（row0=floor,row1=wall,row2=mech）
## 每行 16 列 = 4 角位掩码（bit0=TL,bit1=TR,bit2=BL,bit3=BR），实测与 engine 选择一致。
## 运行：godot --headless res://tools/GenTerrainTileset.tscn
## ============================================================================

const ATLAS := "res://Art/Tiles/terrain_placeholder.svg"
const OUTS := {
	"floor": "res://Art/Tiles/TerrainFloor.tres",
	"wall": "res://Art/Tiles/TerrainWall.tres",
	"mech": "res://Art/Tiles/TerrainMech.tres",
}
const ROW := { "floor": 0, "wall": 1, "mech": 2 }

const CORNER_BITS := [
	TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
]


func _ready() -> void:
	for terrain_name in OUTS:
		_build(terrain_name)
	print("完成：TerrainFloor/Wall/Mech.tres 已生成")
	get_tree().quit(0)


func _build(terrain_name: String) -> void:
	var tex: Texture2D = load(ATLAS)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	# 每套独立 TerrainSet：互不连接
	ts.add_terrain_set(-1)
	var tset := ts.get_terrain_sets_count() - 1
	ts.set_terrain_set_mode(tset, TileSet.TERRAIN_MODE_MATCH_CORNERS)
	ts.add_terrain(tset, -1)
	var terr := ts.get_terrains_count(tset) - 1
	ts.set_terrain_name(tset, terr, terrain_name)
	ts.set_terrain_color(tset, terr, Color(0.4, 0.6, 0.4))

	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(32, 32)
	var row: int = ROW[terrain_name]
	for mask in 16:
		var coords := Vector2i(mask, row)
		src.create_tile(coords)
		var td := src.get_tile_data(coords, 0)
		td.terrain_set = tset
		td.terrain = terr
		for b in 4:
			td.set_terrain_peering_bit(CORNER_BITS[b], terr if mask & (1 << b) else -1)
	ts.add_source(src, 0)

	var err := ResourceSaver.save(ts, OUTS[terrain_name])
	if err != OK:
		push_error("%s 保存失败 err=%d" % [OUTS[terrain_name], err])
