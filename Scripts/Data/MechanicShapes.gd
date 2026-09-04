class_name MechanicShapes
## ============================================================================
## MechanicShapes — 机关生长形状（逻辑权威，与功能需求文档 §4.2.1 一致）
## ----------------------------------------------------------------------------
## 所有偏移均以机关中心格 C 为原点。中心恒占；lv 递增为嵌套扩张：
##   lv0=1(仅C)  lv1=5(+十字)  lv2=9(3x3)  lv3=13(曼哈顿≤2)  lv4=21(5x5去4角)
## ============================================================================


## 返回某阶段所有被占据格相对中心 C 的偏移（含中心本身）
static func cells(level: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = [Vector2i.ZERO]
	var chebyshev := _radius(level)
	for x in range(-chebyshev, chebyshev + 1):
		for y in range(-chebyshev, chebyshev + 1):
			var d := Vector2i(x, y)
			if d == Vector2i.ZERO:
				continue
			if not _in_shape(level, d):
				continue
			out.append(d)
	return out


static func max_level() -> int:
	return 4


## 形状嵌套半径（曼哈顿基准用），lv0 特殊
static func _radius(level: int) -> int:
	match level:
		0: return 0
		1: return 1
		2: return 1   # 3x3（切比雪夫1）
		3: return 2   # 曼哈顿 ≤2 的 5x5 菱形
		4: return 2   # 5x5 去 4 角
		_: return 0


static func _in_shape(level: int, d: Vector2i) -> bool:
	var ax := absi(d.x)
	var ay := absi(d.y)
	match level:
		0: return false
		1: return ax + ay == 1
		2: return ax <= 1 and ay <= 1
		3: return ax + ay <= 2
		4: return ax <= 2 and ay <= 2 and not (ax == 2 and ay == 2)
	return false
