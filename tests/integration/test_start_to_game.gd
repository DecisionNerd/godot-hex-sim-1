extends GutTest

const GAME_SCENE: PackedScene = preload("res://scenes/game.tscn")


func test_new_game_runs_frames_without_crash() -> void:
	GameState.start_new_game(42)
	SceneRouter.entering_new_game = true
	var game: Node2D = GAME_SCENE.instantiate()
	add_child_autofree(game)
	for _i in 30:
		await wait_process_frames(1)
	assert_false(GameState.game_lost)
	assert_gt(GameState.world_coords().size(), 20)


func test_menu_round_trip() -> void:
	var start_scene: PackedScene = load("res://scenes/start.tscn") as PackedScene
	var start: Control = start_scene.instantiate() as Control
	add_child_autofree(start)
	await wait_process_frames(2)
	SceneRouter.go_to_game(true)
	await wait_process_frames(8)
	assert_eq(get_tree().current_scene.scene_file_path, "res://scenes/game.tscn")
