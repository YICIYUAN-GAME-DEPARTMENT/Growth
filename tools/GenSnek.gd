extends Node
## ============================================================================
## GenSnek — 生成玩家视觉资产
## ----------------------------------------------------------------------------
## 产出（布局固定，替换美术时保持即可）：
##   Art/Tiles/player_snek.svg（192×32，只有 row0）：
##     身体连接件（瓦片）：0=横直 1=竖直 2=弯NE 3=弯NW 4=弯SW 5=弯SE
##     每个连接件 = 从本格中心到"相邻格"边的电线带身（宽 14），
##     中段身体只画前后都有格子的格，因此相邻瓦片拼起来是连续"电线"。
##   Art/Sprites/player_head.svg（32×32，头，基准朝右；运行时按行进方向旋转）
##   Art/Sprites/player_tail.svg（32×32，尾，连接端朝右/尖端朝左；运行时按方向旋转）
## 注意：头/尾是 Sprite2D 按纹理中心定位，画布必须是单格 32×32；
##       若沿用 192×32 图集画布，美术会整体左移 80px（视觉上"不在格子上"）。
## 运行：godot --headless res://tools/GenSnek.tscn            （生成 svg）
##       godot --headless --import
##       godot --headless res://tools/GenSnek.tscn -- --tres-only
## ============================================================================

const TILE_SVG := "res://Art/Tiles/player_snek.svg"
const HEAD_SVG := "res://Art/Sprites/player_head.svg"
const TAIL_SVG := "res://Art/Sprites/player_tail.svg"
const TRES_OUT := "res://Art/Tiles/PlayerSnek.tres"
const CELL := 32
const HW := 7  # 电线半宽（总宽 14）

const COL_BODY := "#c8a24a"
const COL_HEAD := "#ffe08a"
const COL_NOSE := "#d9a441"
const COL_TAIL := "#a3823f"
const COL_EYE := "#6b4f1d"

const E := Vector2i.RIGHT
const S := Vector2i.DOWN
const W := Vector2i.LEFT
const N := Vector2i.UP


func _ready() -> void:
	var only_tres := false
	for a in OS.get_cmdline_user_args():
		if a == "--tres-only":
			only_tres = true
	if only_tres:
		_save_tileset()
		print("已生成 ", TRES_OUT)
		get_tree().quit(0)
		return
	_write_svg(TILE_SVG, _body_svg(), CELL * 6, CELL)
	_write_svg(HEAD_SVG, _head_svg())
	_write_svg(TAIL_SVG, _tail_svg())
	print("已生成 player_snek.svg / player_head.svg / player_tail.svg")
	get_tree().quit(0)


## 头/尾默认 32×32 单格画布（Sprite2D 按纹理中心定位）；身体图集显式传 192×32。
func _write_svg(path: String, inner: String, w: int = CELL, h: int = CELL) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("无法写文件: " + path)
		get_tree().quit(1)
		return
	f.store_string("<svg width=\"%d\" height=\"%d\" xmlns=\"http://www.w3.org/2000/svg\">%s</svg>"
			% [w, h, inner])
	f.close()


# ── 身体连接件瓦片（row0：直2 + 弯4）───────────────────────────────
func _body_svg() -> String:
	var sb := PackedStringArray()
	_bar_cell(sb, 0, W, E)  # 横直
	_bar_cell(sb, 1, N, S)  # 竖直
	_bar_cell(sb, 2, N, E)  # 弯NE
	_bar_cell(sb, 3, N, W)  # 弯NW
	_bar_cell(sb, 4, S, W)  # 弯SW
	_bar_cell(sb, 5, S, E)  # 弯SE
	return "\n".join(sb)


## 一格内画若干条"中心→边"电线带身；两条相对 => 贯通整格；两条垂直 => 直角弯
func _bar_cell(sb: PackedStringArray, col: int, d1: Vector2i, d2: Vector2i) -> void:
	var ox := col * CELL
	var on_edge: bool = d1.x + d2.x == 0 and d1.y + d2.y == 0
	if on_edge:
		_bar(sb, ox, d1)
		_bar(sb, ox, d2)
		return
	# 弯：两条带身 + 中心方块补足转角
	_bar(sb, ox, d1)
	_bar(sb, ox, d2)
	_rect(sb, ox, 0, 16 - HW, 16 - HW, HW * 2, HW * 2, COL_BODY)


## 一条"中心→边缘"的带身（从边缘中点内伸 16px 到中心，宽 14）
func _bar(sb: PackedStringArray, ox: int, d: Vector2i) -> void:
	if d.x != 0:
		var x0: int = 16 if d.x > 0 else 0
		_rect(sb, ox, 0, x0, 16 - HW, 16, HW * 2, COL_BODY)
	else:
		var y0: int = 16 if d.y > 0 else 0
		_rect(sb, ox, 0, 16 - HW, y0, HW * 2, 16, COL_BODY)


# ── 头（基准朝右）：左侧与身体连续，右端是头 ─────────────────────
func _head_svg() -> String:
	var sb := PackedStringArray()
	# 与上一格电线相接的带身（伸到左边缘）
	_rect(sb, 0, 0, 0, 16 - HW, 22, HW * 2, COL_BODY)
	# 鼻子（朝右箭头）
	sb.append("<polygon points=\"32,16 22,7 22,25\" fill=\"%s\"/>" % COL_NOSE)
	# 头脸（盖在带身上）
	sb.append("<circle cx=\"24\" cy=\"16\" r=\"6.5\" fill=\"%s\"/>" % COL_HEAD)
	# 眼睛
	sb.append("<circle cx=\"27\" cy=\"12.5\" r=\"1.6\" fill=\"%s\"/>" % COL_EYE)
	sb.append("<circle cx=\"27\" cy=\"19.5\" r=\"1.6\" fill=\"%s\"/>" % COL_EYE)
	return "\n".join(sb)


# ── 尾（连接端朝右、自由端在左）：右侧连身体，左侧收尖 ─────────────
func _tail_svg() -> String:
	var sb := PackedStringArray()
	# 与身体相接的带身（伸到右边缘）
	_rect(sb, 0, 0, 10, 16 - HW, 22, HW * 2, COL_BODY)
	# 自由端收尖（指向左侧/远离身体）
	sb.append("<polygon points=\"0,16 14,9 14,23\" fill=\"%s\"/>" % COL_TAIL)
	# 尾尖描边点（小圆润）
	sb.append("<circle cx=\"15\" cy=\"16\" r=\"2\" fill=\"%s\"/>" % COL_TAIL)
	return "\n".join(sb)


func _rect(sb: PackedStringArray, ox: int, _oy: int, x: float, y: float, w: float, h: float, color: String) -> void:
	sb.append("<rect x=\"%s\" y=\"%s\" width=\"%s\" height=\"%s\" fill=\"%s\"/>"
			% [str(ox + x).trim_suffix(".0"), str(y).trim_suffix(".0"),
				str(w).trim_suffix(".0"), str(h).trim_suffix(".0"), color])


# ── 瓦片集 .tres ──────────────────────────────────────────────────────
func _save_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	var src := TileSetAtlasSource.new()
	src.texture = load(TILE_SVG)
	src.texture_region_size = Vector2i(32, 32)
	for col in 6:
		src.create_tile(Vector2i(col, 0))
	ts.add_source(src, 0)
	var err := ResourceSaver.save(ts, TRES_OUT)
	if err != OK:
		push_error("PlayerSnek.tres 保存失败 err=%d" % err)
