extends Node
## ============================================================================
## GenBlob47MechWall — 由正式美术重新生成 机关(花)/墙 的 blob47 TileSet（corners+sides）
## ----------------------------------------------------------------------------
## 就地重写既有 Art/Tiles/TerrainMech.tres 与 TerrainWall.tres（文件名/uid 不变），
## 因此所有引用它们的场景（含模板/旧关）自动换用新图集，无需改动场景 ext_resource。
##   TerrainMech.tres ← ImportArt/TILE_Flower_Blob47_Animated_01.png（47 列 × 3 帧行）
##   TerrainWall.tres ← ImportArt/TILE_Wall_Blob47__01.png          （47 列 × 1 行）
## peering 参考 Art/Tiles/TerrainGrassBlob47.tres 逐列读入，确保列序语义一致。
## 运行：godot --headless res://tools/GenBlob47MechWall.tscn
## 注意：ResourceSaver.save 不写 gd_resource uid 头，本工具保存后自行补写。
## ============================================================================

const REF := "res://Art/Tiles/TerrainGrassBlob47.tres"
## 就地覆盖既有资源（保留原 uid = 场景引用不失联）
const OUT_MECH := "res://Art/Tiles/TerrainMech.tres"
const OUT_WALL := "res://Art/Tiles/TerrainWall.tres"
const TEX_MECH := "res://ImportArt/TILE_Flower_Blob47_Animated_01.png"
const TEX_WALL := "res://ImportArt/TILE_Wall_Blob47__01.png"
## 原 TerrainMech/TerrainWall 的 uid（不变）
const MECH_TS_UID := "uid://dt67is7gr5ute"
const WALL_TS_UID := "uid://dbo1r0lej0lvf"
## 新贴图已导入的 uid（.import 登记）
const MECH_TEX_UID := "uid://c101km362fno0"
const WALL_TEX_UID := "uid://3u0mjlasj55t"

const CELL := Vector2i(32, 32)
## 8 邻接位序（0=TL 1=T 2=TR 3=L 4=R 5=BL 6=B 7=BR，与地板参考一致）
const DIRS := [
	TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_TOP_SIDE,
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
]

## 从地板 blob 集读每列 mask（8 位：位序 = DIRS）
var _col_masks: Array[int] = []


func _ready() -> void:
	_read_col_masks()
	if _col_masks.size() != 47:
		push_error("参考列 mask 读取异常：%d 列（应为 47）" % _col_masks.size())
		get_tree().quit(1)
		return
	print("已读参考列 mask 数=", _col_masks.size())
	_build_tileset(TEX_MECH, OUT_MECH, 3, "mech_blob47", MECH_TS_UID, MECH_TEX_UID)
	_build_tileset(TEX_WALL, OUT_WALL, 1, "wall_blob47", WALL_TS_UID, WALL_TEX_UID)
	print("完成：TerrainMech.tres(花 47×3帧) / TerrainWall.tres(墙 47×1) 已就地重写")
	get_tree().quit(0)


func _read_col_masks() -> void:
	var ts: TileSet = load(REF)
	if ts == null:
		push_error("无法加载参考 %s" % REF)
		return
	var src := ts.get_source(0) as TileSetAtlasSource
	for col in 47:
		var td := src.get_tile_data(Vector2i(col, 0), 0)
		if td == null:
			push_error("参考缺瓦 col=%d" % col)
			return
		var mask := 0
		for i in 8:
			if td.get_terrain_peering_bit(DIRS[i]) >= 0:
				mask |= 1 << i
		_col_masks.append(mask)


func _build_tileset(tex_path: String, out_path: String, rows: int, tname: String, ts_uid: String, tex_uid: String) -> void:
	var tex: Texture2D = load(tex_path)
	if tex == null:
		push_error("无法加载贴图 %s" % tex_path)
		return
	var ts := TileSet.new()
	ts.tile_size = CELL
	ts.add_terrain_set(-1)
	var tset := ts.get_terrain_sets_count() - 1
	ts.set_terrain_set_mode(tset, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
	ts.add_terrain(tset, -1)
	var terr := ts.get_terrains_count(tset) - 1
	ts.set_terrain_name(tset, terr, tname)
	ts.set_terrain_color(tset, terr, Color(0.5, 0.3, 0.3))

	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = CELL
	for row in rows:
		for col in 47:
			var coords := Vector2i(col, row)
			src.create_tile(coords)
			var td := src.get_tile_data(coords, 0)
			td.terrain_set = tset
			td.terrain = terr
			var m := _col_masks[col]
			for i in 8:
				td.set_terrain_peering_bit(DIRS[i], terr if (m & (1 << i)) else -1)
	ts.add_source(src, 0)

	var err := ResourceSaver.save(ts, out_path)
	if err != OK:
		push_error("%s 保存失败 err=%d" % [out_path, err])
		return
	_patch_tres(out_path, ts_uid, tex_uid, tex_path)
	print("%s 已生成（%d 列 × %d 行）" % [out_path, 47, rows])


## 补写：gd_resource uid 头 + ext_resource 缺 uid 时补贴图 uid（ResourceSaver 可能省略）
func _patch_tres(out_path: String, ts_uid: String, tex_uid: String, tex_path: String) -> void:
	var f := FileAccess.open(out_path, FileAccess.READ)
	var lines := f.get_as_text().split("\n")
	f.close()
	var changed := false
	for i in lines.size():
		var line := lines[i]
		if line.begins_with("[gd_resource type=\"TileSet\""):
			var header := "[gd_resource type=\"TileSet\" format=3 uid=\"%s\"]" % ts_uid
			if line != header:
				lines[i] = header
				changed = true
			continue
		if line.begins_with("[ext_resource type=\"Texture2D\"") and ("path=\"%s\"" % tex_path) in line:
			if not " uid=" in line:
				lines[i] = line.replace("type=\"Texture2D\"", "type=\"Texture2D\" uid=\"%s\"" % tex_uid)
				changed = true
	if not changed:
		return
	var w := FileAccess.open(out_path, FileAccess.WRITE)
	w.store_string("\n".join(lines))
	w.close()
