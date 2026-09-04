extends Node
## 实验5：scene 入口验证 16-corner terrain 选择（用完即删）

func _ready() -> void:
	_run()

func _run() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(32, 32)
	ts.add_terrain_set(-1)
	var tset := ts.get_terrain_sets_count() - 1
	ts.set_terrain_set_mode(tset, TileSet.TERRAIN_MODE_MATCH_CORNERS)
	ts.add_terrain(tset, -1)
	var terr := ts.get_terrains_count(tset) - 1
	ts.set_terrain_name(tset, terr, "g")

	var img := Image.create(512, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	var tex := ImageTexture.create_from_image(img)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(32, 32)
	for idx in 16:
		var coords := Vector2i(idx, 0)
		src.create_tile(coords)
		var td := src.get_tile_data(coords, 0)
		td.terrain_set = tset
		td.terrain = terr
		var corners := [TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
				TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
				TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
				TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER]
		for b in 4:
			td.set_terrain_peering_bit(corners[b], terr if idx & (1 << b) else -1)
	ts.add_source(src, 0)

	var layer := TileMapLayer.new()
	layer.tile_set = ts
	add_child(layer)
	var cells: Array[Vector2i] = []
	for y in 4:
		for x in 4:
			cells.append(Vector2i(x, y))
	layer.set_cells_terrain_connect(cells, tset, terr, true)
	await get_tree().process_frame

	print("selected per cell (atlas x):")
	for y in 4:
		var line := ""
		for x in 4:
			line += " %02d" % layer.get_cell_atlas_coords(Vector2i(x, y)).x
		print(line)
	layer.queue_free()
	get_tree().quit(0)
