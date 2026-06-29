extends GutTest

const HexGrid = preload("res://scripts/world/hex_grid.gd")


func test_neighbors_match_tile_map_layer() -> void:
	var tile_map := TileMapLayer.new()
	tile_map.tile_set = HexGrid.create_tileset()
	add_child_autofree(tile_map)
	await wait_process_frames(1)
	var center := Vector2i(0, 0)
	var engine_neighbors: Array[Vector2i] = []
	for coords in tile_map.get_surrounding_cells(center):
		engine_neighbors.append(coords)
	var grid_neighbors := HexGrid.neighbors(center)
	assert_eq(grid_neighbors.size(), engine_neighbors.size())
	for coords in engine_neighbors:
		assert_true(coords in grid_neighbors, "missing neighbor %s" % coords)
