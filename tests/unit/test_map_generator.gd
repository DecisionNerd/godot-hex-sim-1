extends GutTest

const MapGenerator = preload("res://scripts/world/map_generator.gd")
const HexTopology = preload("res://scripts/world/hex_topology.gd")
const TerrainClassifier = preload("res://scripts/world/terrain_classifier.gd")
const HS = preload("res://scripts/world/hex_state.gd")


func test_generate_world_is_deterministic() -> void:
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 4242
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 4242
	var map_a := MapGenerator.generate_world(rng_a)
	var map_b := MapGenerator.generate_world(rng_b)
	assert_eq(map_a.size(), map_b.size())
	assert_eq(map_a[Vector2i.ZERO].terrain, map_b[Vector2i.ZERO].terrain)


func test_map_radius_is_valley_scale() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var hexes := MapGenerator.generate_world(rng)
	assert_gt(hexes.size(), 800, "valley map should have ~1200 hexes")


func test_water_is_not_passable() -> void:
	assert_false(TerrainClassifier.is_passable(HS.TERRAIN_WATER))
	assert_true(TerrainClassifier.is_passable(HS.TERRAIN_GRASS))


func test_topology_marks_cliffs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var hexes := MapGenerator.generate_world(rng)
	var cliff_count := 0
	for coords in hexes:
		if hexes[coords].cliff_edges != 0:
			cliff_count += 1
	assert_gt(cliff_count, 0, "map should contain cliff edges")
