extends Node
## ============================================================================
## SimLevel — 无头自动化试玩（临时校验）：载入示例关并走到终点
## 运行：godot --headless res://tools/SimLevel.tscn --quit-after 400
## 期望输出：SIM OK
## ============================================================================

const LEVEL := "res://Scenes/Levels/Level_Example.tscn"


func _ready() -> void:
	await _run()


func _run() -> void:
	var packed: PackedScene = load(LEVEL)
	if packed == null:
		print("SIM FAIL: 关卡加载失败")
		get_tree().quit(1)
		return
	var level := packed.instantiate()
	add_child(level)
	await get_tree().process_frame

	# 示例：一直向右，途经两个食物后到终点 (row 1)
	for i in 8:
		level.call("_step", Vector2i.RIGHT)
		await get_tree().process_frame
		await get_tree().process_frame

	var cleared: bool = level.get("finished") if level.get("finished") != null else false
	var st: int = level.get("steps") if level.get("steps") != null else -1
	print("SIM %s finished=%s steps=%d" % ["OK" if cleared else "FAIL", cleared, st])
	get_tree().quit(0 if cleared else 1)
