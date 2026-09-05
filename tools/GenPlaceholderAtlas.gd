extends Node
## ============================================================================
## GenPlaceholderAtlas — 生成三张独立地形瓦片占位纹理（每类地形一张，不再合用单图集）
## ----------------------------------------------------------------------------
## 产出（布局契约固定，替换正式美术时保持行列与角序即可）：
##   Art/Tiles/terrain_floor.svg（512×32，16 列 = 4 角位掩码）
##   Art/Tiles/terrain_wall.svg （512×32，16 列 = 4 角位掩码）
##   Art/Tiles/terrain_mech.svg （512×96，3 行 × 16 列：行 = 生长动画帧）
##     row0 = 冒出（中心小圆） row1 = 生长中（中圆） row2 = 完成（全格样式=最终外观）
## 列 x = 4 角位掩码：bit0=左上角 bit1=右上 bit2=左下 bit3=右下（与 engine 实测一致）
## 画法：整格填充材质色；某角位为 0 时切掉该角三角形（露出外底色），占位可见边缘。
## 运行：godot --headless res://tools/GenPlaceholderAtlas.tscn
## ============================================================================

const OUTS := {
	"floor": { "path": "res://Art/Tiles/terrain_floor.svg", "fill": "#3a3f46", "out": "#14161a" },
	"wall": { "path": "res://Art/Tiles/terrain_wall.svg", "fill": "#5a5f68", "out": "#14161a" },
}
const MECH := { "path": "res://Art/Tiles/terrain_mech.svg", "fill": "#3d7a48", "out": "#14161a" }

const CELL := 32
const CUT := 10  # 切角大小(px)


func _ready() -> void:
	for key: String in OUTS:
		_write(OUTS[key]["path"], _terrain_svg(OUTS[key]))
	_write(MECH["path"], _mech_svg())
	print("已生成 terrain_floor / terrain_wall / terrain_mech.svg")
	get_tree().quit(0)


func _write(path: String, inner: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("无法写文件: " + path)
		get_tree().quit(1)
		return
	f.store_string(inner)
	f.close()


## 单行地形图（floor/wall）：16 列掩码，rect + 切角三角
func _terrain_svg(style: Dictionary) -> String:
	var sb := PackedStringArray()
	sb.append("<svg width=\"%d\" height=\"%d\" xmlns=\"http://www.w3.org/2000/svg\">"
			% [CELL * 16, CELL])
	for col in 16:
		_mask_cell(sb, 0, col, style)
	sb.append("</svg>")
	return "\n".join(sb)


## 机关生长体图：3 行动画帧（row0 冒出 / row1 生长中 / row2 完成全格）
func _mech_svg() -> String:
	var sb := PackedStringArray()
	sb.append("<svg width=\"%d\" height=\"%d\" xmlns=\"http://www.w3.org/2000/svg\">"
			% [CELL * 16, CELL * 3])
	for col in 16:
		_bud_cell(sb, 0, col, 6.0)
		_bud_cell(sb, 1, col, 11.0)
		_mask_cell(sb, 2, col, MECH)
	sb.append("</svg>")
	return "\n".join(sb)


## 画一格：rect + 4 个切角三角形（掩码角保留/切除）
func _mask_cell(sb: PackedStringArray, row: int, col: int, style: Dictionary) -> void:
	var ox := col * CELL
	var oy := row * CELL
	sb.append("<rect x=\"%d\" y=\"%d\" width=\"%d\" height=\"%d\" fill=\"%s\"/>"
			% [ox, oy, CELL, CELL, style.fill])
	# 角顺序与位定义一致：bit0=TL bit1=TR bit2=BL bit3=BR
	# （注意不是顺时针，BL 在 BR 之前，与引擎 peering bit 语义匹配）
	var corners := [
		Vector2i(ox, oy), Vector2i(ox + CELL, oy),
		Vector2i(ox, oy + CELL), Vector2i(ox + CELL, oy + CELL),
	]
	for b in 4:
		if col & (1 << b):
			continue  # 该角连接同类地形 -> 保留整角
		var c: Vector2i = corners[b]
		var d := Vector2i.ZERO
		match b:
			0: d = Vector2i(CUT, CUT)       # TL
			1: d = Vector2i(-CUT, CUT)      # TR
			2: d = Vector2i(CUT, -CUT)      # BL
			_: d = Vector2i(-CUT, -CUT)     # BR
		# 三角形：角点 和 两个边中点
		var a: Vector2i = c
		var e1: Vector2i = c + Vector2i(d.x, 0)
		var e2: Vector2i = c + Vector2i(0, d.y)
		sb.append("<polygon points=\"%d,%d %d,%d %d,%d\" fill=\"%s\"/>"
				% [a.x, a.y, e1.x, e1.y, e2.x, e2.y, style.out])


## 画一格"生长中"圆形（掩码无关，从格中心冒出的占位）：
## 外圈深色描边 + 内部材质色小圆
func _bud_cell(sb: PackedStringArray, row: int, col: int, r: float) -> void:
	var cx := col * CELL + CELL * 0.5
	var cy := row * CELL + CELL * 0.5
	sb.append("<circle cx=\"%d\" cy=\"%d\" r=\"%s\" fill=\"%s\" stroke=\"%s\" stroke-width=\"2\"/>"
			% [cx, cy, fnum(r), MECH.fill, MECH.out])
	sb.append("<circle cx=\"%d\" cy=\"%d\" r=\"%s\" fill=\"%s\"/>"
			% [cx, cy, fnum(r * 0.45), MECH.out])


func fnum(v: float) -> String:
	return str(v).trim_suffix(".0")
