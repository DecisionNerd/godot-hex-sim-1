extends GutTest

const TerrainLayout = preload("res://scripts/render/terrain_layout.gd")
const HexGrid = preload("res://scripts/world/hex_grid.gd")


func test_hex_to_screen_and_back_round_trip() -> void:
	var samples: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(5, 3),
		Vector2i(10, 8),
		Vector2i(15, 12),
		Vector2i(8, 20),
	]
	for coords in samples:
		var screen := TerrainLayout.hex_to_screen(coords, 0.0)
		var back := TerrainLayout.screen_to_hex(screen)
		assert_eq(back, coords, "round-trip at %s" % coords)


func test_elevation_raises_world_height() -> void:
	var coords := Vector2i(10, 10)
	var low := TerrainLayout.hex_to_world_3d(coords, 0.0)
	var high := TerrainLayout.hex_to_world_3d(coords, 20.0)
	assert_gt(high.y, low.y, "higher elevation should raise world Y")
	assert_eq(low.x, high.x)
	assert_eq(low.z, high.z)


func test_planar_neighbors_have_regular_3d_spacing() -> void:
	var coords := Vector2i(0, 0)
	var center := TerrainLayout.planar_position(coords)
	var expected_spacing := TerrainLayout.HEX_RADIUS * sqrt(3.0)
	for neighbor in HexGrid.neighbors(coords):
		var neighbor_center := TerrainLayout.planar_position(neighbor)
		assert_almost_eq(
			center.distance_to(neighbor_center),
			expected_spacing,
			0.01,
			"3D terrain should use a regular axial hex plane"
		)


func test_edge_height_averages_neighbors() -> void:
	assert_almost_eq(TerrainLayout.edge_height(10.0, 30.0), 7.0, 0.01)


func test_depth_sort_is_stable() -> void:
	var coords: Array[Vector2i] = [
		Vector2i(12, 14),
		Vector2i(8, 10),
		Vector2i(15, 16),
		Vector2i(5, 6),
	]
	var sorted := TerrainLayout.sort_coords_back_to_front(coords)
	for i in range(sorted.size() - 1):
		assert_lte(
			TerrainLayout.depth_key(sorted[i]),
			TerrainLayout.depth_key(sorted[i + 1]),
			"back-to-front order"
		)


func test_top_corners_form_hexagon() -> void:
	var center := Vector2(100.0, 80.0)
	var corners := TerrainLayout.top_corners(center)
	assert_eq(corners.size(), 6)
	for corner in corners:
		var dist := center.distance_to(corner)
		assert_almost_eq(dist, TerrainLayout.HEX_RADIUS, 0.01)


func test_pick_hex_prefers_nearest_center() -> void:
	var hexes: Dictionary = {}
	var coords := Vector2i(10, 10)
	var hex := HexState.new()
	hex.elevation = 12.0
	hexes[coords] = hex
	var center := TerrainLayout.planar_position(coords)
	var picked := TerrainLayout.pick_hex_at_screen(center + Vector2(4.0, -2.0), hexes)
	assert_eq(picked, coords)
