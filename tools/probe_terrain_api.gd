extends SceneTree
## 反射：打印 TileSet terrain 相关方法完整签名（用完即删）

func _init() -> void:
	for m in ClassDB.class_get_method_list("TileSet"):
		var n: String = m.name
		if "terrain" in n or n == "add_terrain_set" or n == "add_terrain":
			print("  %s(%s) -> %s" % [n, str(m.args), m.return])
	quit(0)
