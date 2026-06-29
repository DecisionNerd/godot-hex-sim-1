extends Control

@onready var continue_btn: Button = $Center/VBox/ContinueBtn


func _ready() -> void:
	_refresh_continue()
	_connect_btn($Center/VBox/NewGameBtn, _on_new_game)
	_connect_btn(continue_btn, _on_continue)
	_connect_btn($Center/VBox/OptionsBtn, _on_options)
	_connect_btn($Center/VBox/QuitBtn, _on_quit)


func _connect_btn(button: BaseButton, callable: Callable) -> void:
	if not button.pressed.is_connected(callable):
		button.pressed.connect(callable)


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
