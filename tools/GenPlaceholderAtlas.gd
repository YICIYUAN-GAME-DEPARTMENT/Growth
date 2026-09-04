extends Node
## ============================================================================
## GenPlaceholderAtlas — 生成 Art/Tiles/terrain_placeholder.svg
## ----------------------------------------------------------------------------
## 布局：单图 512x96（3 行 x 16 列，每格 32px）
##   row0 = floor   row1 = wall(障碍)   row2 = mech(机关体)
## 列 x = 4 角位掩码：bit0=左上角 bit1=右上 bit2=左下 bit3=右下（与 engine 实测一致）
## 画法：整格填充材质色；某角位为 0 时切掉该角三角形（露出外底色），占位可见边缘。
## 运行：godot --headless res://tools/GenPlaceholderAtlas.tscn
## ============================================================================

const OUT := "res://Art/Tiles/terrain_placeholder.svg"
const CELL := 32
const CUT := 10  # 切角大小(px)

const ROWS := [
	{ "name": "floor", "fill": "#3a3f46", "out": "#14161a" },
	{ "name": "wall", "fill": "#5a5f68", "out": "#14161a" },
	{ "name": "mech", "fill": "#3d7a48", "out": "#14161a" },
]


func _ready() -> void:
	var sb := PackedStringArray()
	sb.append("<svg width=\"%d\" height=\"%d\" xmlns=\"http://www.w3.org/2000/svg\">"
			% [CELL * 16, CELL * ROWS.size()])
	for row in ROWS.size():
		for col in 16:
			_cell(sb, col, row, col, ROWS[row])
	sb.append("</svg>")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f == null:
		push_error("无法写文件: " + OUT)
		get_tree().quit(1)
		return
	f.store_string("\n".join(sb))
	f.close()
	print("已生成 ", OUT)
	get_tree().quit(0)


## 画一格：rect + 4 个切角三角形
func _cell(sb: PackedStringArray, x: int, y: int, mask: int, style: Dictionary) -> void:
	var ox := x * CELL
	var oy := y * CELL
	sb.append("<rect x=\"%d\" y=\"%d\" width=\"%d\" height=\"%d\" fill=\"%s\"/>"
			% [ox, oy, CELL, CELL, style.fill])
	# 角顺序与位定义一致：bit0=TL bit1=TR bit2=BL bit3=BR
	# （注意不是顺时针，BL 在 BR 之前，与引擎 peering bit 语义匹配）
	var corners := [
		Vector2i(ox, oy), Vector2i(ox + CELL, oy),
		Vector2i(ox, oy + CELL), Vector2i(ox + CELL, oy + CELL),
	]
	for b in 4:
		if mask & (1 << b):
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
