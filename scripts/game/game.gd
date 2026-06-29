extends Node2D

const Actor = preload("res://scripts/units/actor.gd")

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var camera: Camera2D = $Camera2D
@onready var map_renderer: Node2D = $MapRenderer
@onready var plot_highlight: Node2D = $PlotHighlight
@onready var actor: Node2D = $Actor
@onready var season_label: Label = $UI/Panel/Margin/VBox/SeasonLabel
@onready var resources_label: Label = $UI/Panel/Margin/VBox/ResourcesLabel
@onready var family_label: Label = $UI/Panel/Margin/VBox/FamilyLabel
@onready var plot_label: Label = $UI/Panel/Margin/VBox/PlotLabel
@onready var actions_label: Label = $UI/Panel/Margin/VBox/ActionsLabel
@onready var zoom_label: Label = $UI/Panel/Margin/VBox/ZoomLabel
@onready var log_label: Label = $UI/Panel/Margin/VBox/LogLabel
@onready var hint_label: Label = $UI/Panel/Margin/VBox/HintLabel
@onready var plant_wheat_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/PlantWheatBtn
@onready var plant_barley_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/PlantBarleyBtn
@onready var tend_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/TendBtn
@onready var harvest_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/HarvestBtn
@onready var claim_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/ClaimBtn
@onready var end_day_btn: Button = $UI/Panel/Margin/VBox/DayRow/EndDayBtn
@onready var skip_week_btn: Button = $UI/Panel/Margin/VBox/DayRow/SkipWeekBtn
@onready var skip_to_work_btn: Button = $UI/Panel/Margin/VBox/DayRow/SkipToWorkBtn
@onready var save_btn: Button = $UI/Panel/Margin/VBox/MenuRow/SaveBtn
@onready var menu_btn: Button = $UI/Panel/Margin/VBox/MenuRow/MenuBtn
@onready var game_over_panel: PanelContainer = $UI/GameOverPanel

var selected_hex: Vector2i = Vector2i.ZERO
const MIN_ZOOM := 0.05
const MAX_ZOOM := 1.6


func _ready() -> void:
	TurnManager.turn_started.connect(_on_turn_started)
	TurnManager.action_consumed.connect(_on_action_consumed)
	GameState.season_changed.connect(func(_s, _y): _update_ui())
	GameState.weather_changed.connect(func(_w): _update_ui())
	GameState.resources_changed.connect(_update_ui)
	GameState.plot_changed.connect(func(_c): _update_ui())
	GameState.log_added.connect(func(_m): _update_log())
	GameState.day_batch_finished.connect(func(_d): _update_ui())
	GameState.game_over.connect(_on_game_over)
	GameState.init_plots_from_map(tile_map)
	selected_hex = GameState.home_hex
	actor.setup(tile_map, selected_hex)
	plot_highlight.setup(tile_map)
	plot_highlight.set_selected(selected_hex)
	map_renderer.setup(tile_map, camera)
	camera.position = tile_map.map_to_local(selected_hex)
	plant_wheat_btn.pressed.connect(_on_plant_wheat)
	plant_barley_btn.pressed.connect(_on_plant_barley)
	tend_btn.pressed.connect(_on_tend)
	harvest_btn.pressed.connect(_on_harvest)
	claim_btn.pressed.connect(_on_claim)
	end_day_btn.pressed.connect(_on_end_day)
	skip_week_btn.pressed.connect(_on_skip_week)
	skip_to_work_btn.pressed.connect(_on_advance_until_work)
	save_btn.pressed.connect(_on_save)
	menu_btn.pressed.connect(_on_menu)
	game_over_panel.visible = false
	$UI/GameOverPanel/Margin/VBox/MenuBtn.pressed.connect(_on_menu)
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if GameState.game_lost:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_set_zoom(camera.zoom.x * 1.1)
				get_viewport().set_input_as_handled()
			elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_set_zoom(camera.zoom.x / 1.1)
				get_viewport().set_input_as_handled()
			elif mouse_event.button_index == MOUSE_BUTTON_LEFT:
				_try_select_at_mouse()
				get_viewport().set_input_as_handled()
	if event.is_action_pressed(&"advance_until_work"):
		_on_advance_until_work()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"end_turn"):
		_on_end_day()
		get_viewport().set_input_as_handled()


func _set_zoom(value: float) -> void:
	var z := clampf(value, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(z, z)
	_update_ui()


func _try_select_at_mouse() -> void:
	var local_pos := tile_map.to_local(get_global_mouse_position())
	var target := tile_map.local_to_map(local_pos)
	if GameState.is_farm_plot(target):
		selected_hex = target
		actor.walk_to(target)
		plot_highlight.set_selected(target)
		_update_ui()
		return
	if GameState.can_claim_plot(target):
		selected_hex = target
		plot_highlight.set_selected(target)
		_update_ui()
		return
	hint_label.text = "Click your plots or adjacent wild land to claim."


func _run_action(result: String) -> void:
	if result != "ok":
		hint_label.text = result
	else:
		hint_label.text = _default_hint()
	_update_ui()


func _on_plant_wheat() -> void:
	_run_action(GameState.try_plant(selected_hex, "wheat"))


func _on_plant_barley() -> void:
	_run_action(GameState.try_plant(selected_hex, "barley"))


func _on_tend() -> void:
	_run_action(GameState.try_tend(selected_hex))


func _on_harvest() -> void:
	_run_action(GameState.try_harvest(selected_hex))


func _on_claim() -> void:
	_run_action(GameState.try_claim_plot(selected_hex))
	if GameState.is_farm_plot(selected_hex):
		actor.walk_to(selected_hex)


func _on_end_day() -> void:
	if not GameState.game_lost:
		TurnManager.end_turn()


func _on_skip_week() -> void:
	if not GameState.game_lost:
		TurnManager.skip_days(7)


func _on_advance_until_work() -> void:
	if not GameState.game_lost:
		TurnManager.advance_until_actionable()
		_update_ui()


func _on_save() -> void:
	if GameState.save_game():
		hint_label.text = "Game saved."
	else:
		hint_label.text = "Save failed."


func _on_menu() -> void:
	GameState.save_game()
	SceneRouter.go_to_start()


func _on_game_over(reason: String) -> void:
	game_over_panel.visible = true
	$UI/GameOverPanel/Margin/VBox/ReasonLabel.text = reason
	_update_ui()


func _on_turn_started(_turn_number: int) -> void:
	_update_ui()


func _on_action_consumed(_actions_remaining: int) -> void:
	_update_ui()


func _default_hint() -> String:
	if GameState.game_lost:
		return ""
	if TurnManager.has_actions() and GameState.has_actionable_work():
		return "Select a plot, then plant / tend / harvest / claim. Scroll to zoom out."
	if TurnManager.has_actions():
		return "Quiet day — Shift+Space to skip ahead, or end the day."
	return "No labor left — end the day (Space) or Shift+Space to skip ahead."


func _update_log() -> void:
	log_label.text = "\n".join(GameState.log_lines)


func _update_ui() -> void:
	season_label.text = GameState.calendar_label(TurnManager.turn_number)
	resources_label.text = "Food %d · Wheat seed %d · Barley seed %d" % [
		GameState.resources["food"],
		GameState.resources["wheat_seed"],
		GameState.resources["barley_seed"],
	]
	family_label.text = GameState.family_summary() + "\n" + GameState.holdings_summary()
	plot_label.text = GameState.plot_status(selected_hex)
	actions_label.text = "Labor today: %d / %d" % [
		TurnManager.actions_remaining,
		TurnManager.actions_per_turn,
	]
	zoom_label.text = GameState.render_level_name(camera.zoom.x)
	hint_label.text = _default_hint()
	_update_log()
	var can_act := TurnManager.has_actions() and not GameState.game_lost
	plant_wheat_btn.disabled = not can_act
	plant_barley_btn.disabled = not can_act
	tend_btn.disabled = not can_act
	harvest_btn.disabled = not can_act
	claim_btn.disabled = not can_act or not GameState.can_claim_plot(selected_hex)
	end_day_btn.disabled = GameState.game_lost
	skip_week_btn.disabled = GameState.game_lost
	skip_to_work_btn.disabled = GameState.game_lost
