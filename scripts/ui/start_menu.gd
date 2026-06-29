extends Control

const ScenarioCatalog = preload("res://scripts/scenarios/scenario_catalog.gd")

@onready var continue_btn: Button = $Center/VBox/ContinueBtn
@onready var scenario_label: Label = $Center/VBox/ScenarioLabel
@onready var scenario_blurb: Label = $Center/VBox/ScenarioBlurb


func _ready() -> void:
	_refresh_scenario_copy()
	_refresh_continue()
	_connect_btn($Center/VBox/NewGameBtn, _on_new_game)
	_connect_btn(continue_btn, _on_continue)
	_connect_btn($Center/VBox/OptionsBtn, _on_options)
	_connect_btn($Center/VBox/QuitBtn, _on_quit)


func _connect_btn(button: BaseButton, callable: Callable) -> void:
	if not button.pressed.is_connected(callable):
		button.pressed.connect(callable)


func _on_new_game() -> void:
	GameState.active_scenario = ScenarioCatalog.get_default()
	SceneRouter.go_to_settlement(true)


func _refresh_scenario_copy() -> void:
	var scenario = ScenarioCatalog.get_default()
	scenario_label.text = scenario.menu_line()
	scenario_blurb.text = scenario.menu_blurb


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
