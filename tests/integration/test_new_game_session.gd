extends GutTest

const WorkZone = preload("res://scripts/work/work_zone.gd")
const HexState = preload("res://scripts/world/hex_state.gd")

## Simulates menu → settlement → first actions without a full scene tree UI.


func _make_tile_map() -> TileMapLayer:
	var tile_map := TileMapLayer.new()
	add_child_autofree(tile_map)
	return tile_map


func test_new_game_is_playable() -> void:
	GameState.reset_for_test(42)
	var tile_map := _make_tile_map()
	GameState.init_plots_from_map(tile_map)
	TurnManager.begin_game_scene()
	assert_false(GameState.game_lost, "new game should not be lost")
	assert_true(GameState.settlement_chosen)
	assert_gt(GameState.labor_pool, 0, "household should have labour to spend")
	assert_true(GameState.is_home_hex(GameState.home_hex), "home hex should be chosen")
	assert_gt(GameState.world_coords().size(), 800, "generated map should be valley scale")
	var coords := GameState.home_hex
	var hex = GameState.get_hex(coords)
	hex.forage_mask = HexState.FORAGE_BERRIES
	hex.forage_depleted = false
	var result := GameState.assign_zone_hex(coords, WorkZone.ZoneType.FORAGE)
	assert_eq(result, "ok", "forage zone should accept homestead hex")
	GameState.work_today()
	assert_gt(GameState.resources.get("berries", 0) + GameState.resources.get("roots", 0), 0)


func test_stale_game_lost_persists_on_reload_without_new_game() -> void:
	GameState.reset_for_test(42)
	var tile_map := _make_tile_map()
	GameState.init_plots_from_map(tile_map)
	GameState.game_lost = true
	GameState.last_game_over_reason = "stale"
	SceneRouter.entering_new_game = false
	GameState.init_plots_from_map(tile_map)
	assert_true(GameState.game_lost, "reload without new game should keep game over state")
