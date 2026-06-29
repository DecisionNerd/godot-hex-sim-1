extends GutTest

const MapGenerator = preload("res://scripts/world/map_generator.gd")
const HexState = preload("res://scripts/world/hex_state.gd")
const TerrainClassifier = preload("res://scripts/world/terrain_classifier.gd")


func test_generate_terrain_is_deterministic() -> void:
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 4242
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 4242
	var map_a := MapGenerator.generate_terrain(rng_a)
	var map_b := MapGenerator.generate_terrain(rng_b)
	assert_eq(map_a.size(), map_b.size())
	assert_eq(map_a[Vector2i.ZERO], map_b[Vector2i.ZERO])


func test_origin_is_grass() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var terrain := MapGenerator.generate_terrain(rng)
	assert_eq(terrain[Vector2i.ZERO], HexState.TERRAIN_GRASS)


func test_water_is_not_passable() -> void:
	assert_false(TerrainClassifier.is_passable(HexState.TERRAIN_WATER))
	assert_true(TerrainClassifier.is_passable(HexState.TERRAIN_GRASS))
