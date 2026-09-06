extends Node
## ============================================================================
## GenTerrainTileset — 程序化生成含 Terrain 的 Art/Tiles/TerrainFloor/Wall/Mech.tres
## ----------------------------------------------------------------------------
## 图源（每类地形一张独立纹理，不再合用单图集）：
##   Art/Tiles/terrain_floor.svg（512×32）           → TerrainFloor.tres
##   Art/Tiles/Terrarin-wall.png（512×32，正式墙图）  → TerrainWall.tres
##   Art/Tiles/terrain_mech.svg （512×96，3 行=生长动画帧 0/1/2） → TerrainMech.tres
## 每行 16 列 = 4 角位掩码（bit0=TL,bit1=TR,bit2=BL,bit3=BR），实测与 engine 选择一致。
## 瓦片坐标 = (mask, row)：floor/wall 只有 row0；mech 的 3 行全建瓦，
## Level 运行时给新增占格按帧行 0→1→2 播一次生长动画，其余格停帧 2（完成外观）。
## 运行：godot --headless res://tools/GenTerrainTileset.tscn
## ============================================================================

const SRCS := {
	"floor": { "tex": "res://Art/Tiles/terrain_floor.svg", "out": "res://Art/Tiles/TerrainFloor.tres", "rows": 1 },
	"wall": { "tex": "res://Art/Tiles/Terrarin-wall.png", "out": "res://Art/Tiles/TerrainWall.tres", "rows": 1 },
	"mech": { "tex": "res://Art/Tiles/terrain_mech.svg", "out": "res://Art/Tiles/TerrainMech.tres", "rows": 3 },
}

const CORNER_BITS := [
	TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
]


func _ready() -> void:
	for terrain_name: String in SRCS:
		_build(terrain_name)
	print("完成：TerrainFloor/Wall/Mech.tres 已生成")
	get_tree().quit(0)


func _build(terrain_name: String) -> void:
	var info: Dictionary = SRCS[terrain_name]
	var tex: Texture2D = load(info["tex"])

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
	for row in info["rows"]:
		for mask in 16:
			var coords := Vector2i(mask, row)
			src.create_tile(coords)
			var td := src.get_tile_data(coords, 0)
			td.terrain_set = tset
			td.terrain = terr
			for b in 4:
				td.set_terrain_peering_bit(CORNER_BITS[b], terr if mask & (1 << b) else -1)
	ts.add_source(src, 0)

	var err := ResourceSaver.save(ts, info["out"])
	if err != OK:
		push_error("%s 保存失败 err=%d" % [info["out"], err])
