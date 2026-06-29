extends Node

const START_SCENE := "res://scenes/start.tscn"
const OPTIONS_SCENE := "res://scenes/options.tscn"
const GAME_SCENE := "res://scenes/game.tscn"


func go_to_start() -> void:
	get_tree().change_scene_to_file(START_SCENE)


func go_to_options() -> void:
	get_tree().change_scene_to_file(OPTIONS_SCENE)


func go_to_game(new_game: bool) -> void:
	if new_game:
		GameState.start_new_game()
	get_tree().change_scene_to_file(GAME_SCENE)


func quit_game() -> void:
	get_tree().quit()
