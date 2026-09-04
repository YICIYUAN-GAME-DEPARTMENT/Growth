extends Node
## ============================================================================
## GenSnek — 生成玩家视觉资产
## ----------------------------------------------------------------------------
## 产出（布局固定，替换美术时保持即可）：
##   Art/Tiles/player_snek.svg（320×32，只有 row0）：
##     身体连接件（瓦片）：0=横直 1=竖直 2=弯NE 3=弯NW 4=弯SW 5=弯SE
##       每个连接件 = 从本格中心到相邻格边的电线带身（宽 14），中段身体只画
##       "前后都有格子"的格，相邻瓦片拼起来是连续"管道"。
##     端点瓦片（col 6..9，中心→边 半截带身）：
##       6=E 7=W 8=S 9=N —— 垫在头/尾所在格底下，把管道平滑接进头/尾底部。
##   Art/Sprites/player_head.svg（44×44，人物占位圆，无内嵌带身；基准朝右）
##   Art/Sprites/player_tail.svg（48×48，机器占位圆，无内嵌带身；接端朝右）
## 注意：头/尾是 Sprite2D 按纹理中心定位，接口点（默认=纹理中心）对齐格中心；
##       画布可大于单格（纹理中心=格中心即居中溢出）。若正式美术的接口点不在
##       纹理中心，用 Sprite2D 的 offset 属性把接口点挪到格中心（旋转绕该点）。
##       不要再在头/尾贴图内画接线带身——带身已收敛为 PlayerSnek 端点瓦片。
## 运行：godot --headless res://tools/GenSnek.tscn            （生成 svg）
##       godot --headless --import
##       godot --headless res://tools/GenSnek.tscn -- --tres-only
## ============================================================================

const TILE_SVG := "res://Art/Tiles/player_snek.svg"
const HEAD_SVG := "res://Art/Sprites/player_head.svg"
const TAIL_SVG := "res://Art/Sprites/player_tail.svg"
const TRES_OUT := "res://Art/Tiles/PlayerSnek.tres"
const CELL := 32
const HW := 7  # 管道半宽（总宽 14）

const COL_BODY := "#c8a24a"
const COL_HEAD_FILL := "#ffd9a1"
const COL_HEAD_STROKE := "#b98a4a"
const COL_FACE := "#5a3a17"
const COL_MACH_FILL := "#aab6c4"
const COL_MACH_STROKE := "#5f6d7c"
const COL_MACH_DARK := "#3f4a56"

# 头/尾占位画布尺寸（> 单格：圆把本格内的端点带身压在底下，管道从圆缘下接入）
const HEAD_PX := 44
const HEAD_R := 20.0
const TAIL_PX := 48
const TAIL_R := 23.0

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
	_write_svg(TILE_SVG, _body_svg(), CELL * 10, CELL)
	_write_svg(HEAD_SVG, _head_svg(), HEAD_PX, HEAD_PX)
	_write_svg(TAIL_SVG, _tail_svg(), TAIL_PX, TAIL_PX)
	print("已生成 player_snek.svg / player_head.svg / player_tail.svg")
	get_tree().quit(0)


func _write_svg(path: String, inner: String, w: int, h: int) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("无法写文件: " + path)
		get_tree().quit(1)
		return
	f.store_string("<svg width=\"%d\" height=\"%d\" xmlns=\"http://www.w3.org/2000/svg\">%s</svg>"
			% [w, h, inner])
	f.close()


# ── 身体管道瓦片（row0：直2 + 弯4 + 端点4）────────────────────────
func _body_svg() -> String:
	var sb := PackedStringArray()
	_bar_cell(sb, 0, W, E)  # 横直
	_bar_cell(sb, 1, N, S)  # 竖直
	_bar_cell(sb, 2, N, E)  # 弯NE
	_bar_cell(sb, 3, N, W)  # 弯NW
	_bar_cell(sb, 4, S, W)  # 弯SW
	_bar_cell(sb, 5, S, E)  # 弯SE
	# 端点半截瓦：只从格中心连向邻边，垫在头/尾底下（6=E 7=W 8=S 9=N）
	_endpoint_cell(sb, 6, E)
	_endpoint_cell(sb, 7, W)
	_endpoint_cell(sb, 8, S)
	_endpoint_cell(sb, 9, N)
	return "\n".join(sb)


## 一格内画若干条"中心→边"管道带身；两条相对 => 贯通整格；两条垂直 => 直角弯
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


## 单条"中心→边缘"的半截带身（端点瓦片）
func _endpoint_cell(sb: PackedStringArray, col: int, d: Vector2i) -> void:
	_bar(sb, col * CELL, d)


## 一条"中心→边缘"的带身（从边缘中点内伸 16px 到中心，宽 14）
func _bar(sb: PackedStringArray, ox: int, d: Vector2i) -> void:
	if d.x != 0:
		var x0: int = 16 if d.x > 0 else 0
		_rect(sb, ox, 0, x0, 16 - HW, 16, HW * 2, COL_BODY)
	else:
		var y0: int = 16 if d.y > 0 else 0
		_rect(sb, ox, 0, 16 - HW, y0, HW * 2, 16, COL_BODY)


# ── 头（人物占位圆，基准朝右 = 行进方向；接口点=圆心=格中心）────────
func _head_svg() -> String:
	var c := HEAD_PX * 0.5
	var sb := PackedStringArray()
	# 金色圆形"人"
	_circle(sb, c, c, HEAD_R, COL_HEAD_FILL, COL_HEAD_STROKE, 2.0)
	# 中心接口点（管道在此接入圆下，占位提示）
	_circle(sb, c, c, 4.5, COL_BODY, COL_HEAD_STROKE, 1.0)
	# 面朝 +x（眼睛在行进侧）
	_circle(sb, c + HEAD_R * 0.5, c - 7.0, 1.9, COL_FACE, "", 0.0)
	_circle(sb, c + HEAD_R * 0.5, c + 7.0, 1.9, COL_FACE, "", 0.0)
	_circle(sb, c + HEAD_R * 0.78, c, 2.4, COL_FACE, "", 0.0)
	return "\n".join(sb)


# ── 尾（机器占位圆，接端朝右；接口点=圆心=格中心）───────────────────
func _tail_svg() -> String:
	var c := TAIL_PX * 0.5
	var sb := PackedStringArray()
	# 钢灰机器圆 + 外圈
	_circle(sb, c, c, TAIL_R, COL_MACH_FILL, COL_MACH_STROKE, 2.0)
	_circle(sb, c, c, TAIL_R * 0.6, "", COL_MACH_DARK, 1.5)
	# 中心接口点（管道接入处）
	_circle(sb, c, c, 5.0, COL_BODY, COL_MACH_DARK, 1.0)
	# 接端凸嘴朝右（= 身体方向基准）
	_rect(sb, 0, 0, TAIL_PX - 6, c - 4, 6, 8, COL_MACH_DARK)
	return "\n".join(sb)


func _circle(sb: PackedStringArray, cx: float, cy: float, r: float,
		fill: String, stroke: String, sw: float) -> void:
	var s := "<circle cx=\"%s\" cy=\"%s\" r=\"%s\"" % [fnum(cx), fnum(cy), fnum(r)]
	if fill != "":
		s += " fill=\"%s\"" % fill
	if stroke != "":
		s += " stroke=\"%s\" stroke-width=\"%s\"" % [stroke, fnum(sw)]
	sb.append(s + "/>")


func _rect(sb: PackedStringArray, ox: int, _oy: int, x: float, y: float, w: float, h: float, color: String) -> void:
	sb.append("<rect x=\"%s\" y=\"%s\" width=\"%s\" height=\"%s\" fill=\"%s\"/>"
			% [str(ox + x).trim_suffix(".0"), str(y).trim_suffix(".0"),
				str(w).trim_suffix(".0"), str(h).trim_suffix(".0"), color])


func fnum(v: float) -> String:
	return str(v).trim_suffix(".0")


# ── 瓦片集 .tres ──────────────────────────────────────────────────────
func _save_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	var src := TileSetAtlasSource.new()
	src.texture = load(TILE_SVG)
	src.texture_region_size = Vector2i(32, 32)
	for col in 10:
		src.create_tile(Vector2i(col, 0))
	ts.add_source(src, 0)
	var err := ResourceSaver.save(ts, TRES_OUT)
	if err != OK:
		push_error("PlayerSnek.tres 保存失败 err=%d" % err)
