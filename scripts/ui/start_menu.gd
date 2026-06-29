extends Control

@onready var continue_btn: Button = $Center/VBox/ContinueBtn


func _ready() -> void:
	_refresh_continue()
	$Center/VBox/NewGameBtn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	$Center/VBox/OptionsBtn.pressed.connect(_on_options)
	$Center/VBox/QuitBtn.pressed.connect(_on_quit)


func _on_new_game() -> void:
	SceneRouter.go_to_game(true)


func _refresh_continue() -> void:
	continue_btn.disabled = not GameState.can_continue()


func _on_continue() -> void:
	if GameState.load_game():
		SceneRouter.go_to_game(false)
	else:
		_refresh_continue()


func _on_options() -> void:
	SceneRouter.go_to_options()


func _on_quit() -> void:
	SceneRouter.quit_game()
