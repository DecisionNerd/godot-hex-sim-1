extends GutTest

const HexGrid = preload("res://scripts/world/hex_grid.gd")


func _make_tile_map() -> TileMapLayer:
	var tile_map := TileMapLayer.new()
	tile_map.tile_set = HexGrid.create_tileset()
	add_child_autofree(tile_map)
	return tile_map


func test_map_to_local_matches_tile_map_layer() -> void:
	var tile_map := _make_tile_map()
	await wait_process_frames(1)
	var samples: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(2, 3),
		Vector2i(-1, 2),
	]
	for coords in samples:
		var engine_pos := tile_map.map_to_local(coords)
		var grid_pos := HexGrid.map_to_local(coords)
		assert_almost_eq(grid_pos.x, engine_pos.x, 0.01, "x mismatch at %s" % coords)
		assert_almost_eq(grid_pos.y, engine_pos.y, 0.01, "y mismatch at %s" % coords)


func test_hex_corners_form_flat_top_hex() -> void:
	var center := Vector2(100.0, 60.0)
	var corners := HexGrid.hex_corners(center)
	assert_eq(corners.size(), 6, "a hex has six corners")
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF
	for p in corners:
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)
	assert_almost_eq(max_x - min_x, float(HexGrid.TILE_SIZE.x), 0.01, "width spans a tile")
	assert_almost_eq(max_y - min_y, float(HexGrid.TILE_SIZE.y), 0.01, "height spans a tile")
	assert_almost_eq((min_x + max_x) * 0.5, center.x, 0.01, "centered on x")
	assert_almost_eq((min_y + max_y) * 0.5, center.y, 0.01, "centered on y")


func test_local_to_map_round_trip() -> void:
	var tile_map := _make_tile_map()
	await wait_process_frames(1)
	for coords in [Vector2i(0, 0), Vector2i(3, 2), Vector2i(-2, 4), Vector2i(1, 1)]:
		var local_pos := tile_map.map_to_local(coords)
		assert_eq(tile_map.local_to_map(local_pos), coords)
		assert_eq(HexGrid.local_to_map(local_pos), coords)
