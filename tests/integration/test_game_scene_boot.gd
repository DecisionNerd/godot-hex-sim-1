extends GutTest

const GAME_SCENE := preload("res://scenes/game.tscn")


func test_game_scene_boots_without_errors() -> void:
	GameState.start_new_game(42)
	SceneRouter.entering_new_game = true
	var game := GAME_SCENE.instantiate()
	add_child_autofree(game)
	await wait_process_frames(2)
	assert_false(GameState.game_lost)
	assert_gt(GameState.labor_pool, 0)
	assert_false(game.get_node("UI/PlotPanel/Margin/VBox/ActionsRow/PlantWheatBtn").disabled)
