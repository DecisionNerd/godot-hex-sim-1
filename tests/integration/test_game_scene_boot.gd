extends GutTest

const GAME_SCENE := preload("res://scenes/game.tscn")
const TerrainLayout = preload("res://scripts/render/terrain_layout.gd")


func test_game_scene_boots_without_errors() -> void:
	GameState.reset_for_test(42)
	SceneRouter.entering_new_game = false
	var game := GAME_SCENE.instantiate()
	add_child_autofree(game)
	await wait_process_frames(2)
	assert_false(GameState.game_lost)
	assert_gt(GameState.labor_pool, 0)
	assert_false(game.get_node("UI/PlotPanel/Margin/VBox/ActionsRow/PlantWheatBtn").disabled)


func test_terrain_view_exists_and_toggle_is_safe() -> void:
	GameState.reset_for_test(42)
	SceneRouter.entering_new_game = false
	var game := GAME_SCENE.instantiate()
	add_child_autofree(game)
	await wait_process_frames(2)
	var terrain_view := game.get_node("TerrainView")
	assert_not_null(terrain_view)
	assert_false(terrain_view.visible)
	game._toggle_view_mode()
	await wait_process_frames(1)
	assert_true(terrain_view.visible)
	assert_eq(game.view_mode, game.ViewMode.TERRAIN)
	var focus: Vector2i = game.selected_hex
	var terrain_pos := TerrainLayout.camera_position_for_hex(focus)
	assert_almost_eq(game.camera.position.x, terrain_pos.x, 1.0)
	assert_almost_eq(game.camera.position.y, terrain_pos.y, 1.0)
	game._toggle_view_mode()
	await wait_process_frames(1)
	assert_false(terrain_view.visible)
	assert_eq(game.view_mode, game.ViewMode.MAP)
