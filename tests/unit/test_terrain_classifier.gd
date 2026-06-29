extends GutTest

const TerrainClassifier = preload("res://scripts/world/terrain_classifier.gd")
const HS = preload("res://scripts/world/hex_state.gd")


func test_passable_terrain() -> void:
	assert_true(TerrainClassifier.is_passable(HS.TERRAIN_GRASS))
	assert_true(TerrainClassifier.is_passable(HS.TERRAIN_WOOD))
	assert_false(TerrainClassifier.is_passable(HS.TERRAIN_WATER))
