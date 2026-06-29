extends GutTest

## Simulates menu → new game → first actions without a full scene tree UI.


func test_new_game_is_playable() -> void:
	GameState.start_new_game(42)
	var tile_map := TileMapLayer.new()
	GameState.init_plots_from_map(tile_map)
	TurnManager.begin_game_scene()
	assert_false(GameState.game_lost, "new game should not be lost")
	assert_true(TurnManager.has_actions(), "player should have labor actions")
	assert_true(GameState.is_farm_plot(GameState.home_hex), "home hex should be a farm plot")
	assert_gt(tile_map.get_used_cells().size(), 20, "generated map should have many land cells")
	GameState.weather = GameState.Weather.CLEAR
	var plant := GameState.try_plant(GameState.home_hex, "wheat")
	assert_eq(plant, "ok", "planting wheat on a clear spring day should succeed")
	assert_eq(TurnManager.actions_remaining, 1)


func test_stale_game_lost_resets_on_init() -> void:
	GameState.start_new_game(42)
	var tile_map := TileMapLayer.new()
	GameState.init_plots_from_map(tile_map)
	GameState.game_lost = true
	GameState.last_game_over_reason = "stale"
	SceneRouter.entering_new_game = false
	GameState.init_plots_from_map(tile_map)
	assert_false(GameState.game_lost, "init should recover from stale game over")
	assert_true(TurnManager.has_actions())
