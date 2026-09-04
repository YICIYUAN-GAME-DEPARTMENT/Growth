class_name GridSystem
extends RefCounted
## ============================================================================
## GridSystem — 关卡网格数据与判定（纯逻辑，不渲染）
## ----------------------------------------------------------------------------
## 坐标一律用格子 Vector2i；(0,0) 为地图左上。地图范围由 size 决定，
## 越界一律不可走。提供：可走判定 + BFS 通路检测（死局判定用）。
## ============================================================================

var size: Vector2i = Vector2i(32, 32)

var obstacles: Dictionary = {}    # Vector2i -> true（静态障碍）
var mech_cells: Dictionary = {}   # Vector2i -> true（机关当前实际占据，含跳过逻辑）
var goal_cell := Vector2i.ZERO
var spawn_cell := Vector2i.ZERO


func setup(map_size: Vector2i) -> void:
	size = map_size


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < size.x and c.y < size.y


func add_obstacle(c: Vector2i) -> void:
	obstacles[c] = true


## 该格是否被静态障碍或机关占据（越界视为不可走）
func is_blocked(c: Vector2i) -> bool:
	if not in_bounds(c):
		return true
	return obstacles.has(c) or mech_cells.has(c)


## 供主角移动用：越界/障碍/机关占格 -> 不可走（食物/终点格可走）
func can_step_into(c: Vector2i) -> bool:
	return not is_blocked(c)


## BFS 判定 from -> to 是否存在通路（忽略身长/自身身体，可走格同 can_step）
func has_path(from: Vector2i, to: Vector2i) -> bool:
	if not in_bounds(from) or not in_bounds(to):
		return false
	if is_blocked(to):
		return false
	if from == to:
		return true
	var visited := {from: true}
	var queue: Array[Vector2i] = [from]
	var idx := 0
	while idx < queue.size():
		var cur: Vector2i = queue[idx]
		idx += 1
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = cur + d
			if n == to:
				return true
			if not visited.has(n) and can_step_into(n):
				visited[n] = true
				queue.append(n)
	return false
