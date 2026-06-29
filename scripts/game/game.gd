extends Node2D

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var camera: Camera2D = $Camera2D
@onready var map_renderer: Node2D = $MapRenderer
@onready var plot_overlay: Node2D = $PlotOverlay
@onready var ui_panel: PanelContainer = $UI/Panel
@onready var season_label: Label = $UI/Panel/Margin/VBox/SeasonLabel
@onready var resources_label: Label = $UI/Panel/Margin/VBox/ResourcesLabel
@onready var family_label: Label = $UI/Panel/Margin/VBox/FamilyLabel
@onready var plot_label: Label = $UI/Panel/Margin/VBox/PlotLabel
@onready var actions_label: Label = $UI/Panel/Margin/VBox/ActionsLabel
@onready var zoom_label: Label = $UI/Panel/Margin/VBox/ZoomLabel
@onready var legend_label: Label = $UI/Panel/Margin/VBox/LegendLabel
@onready var log_label: Label = $UI/Panel/Margin/VBox/LogLabel
@onready var hint_label: Label = $UI/Panel/Margin/VBox/HintLabel
@onready var plant_wheat_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/PlantWheatBtn
@onready var plant_barley_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/PlantBarleyBtn
@onready var tend_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/TendBtn
@onready var harvest_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/HarvestBtn
@onready var claim_btn: Button = $UI/Panel/Margin/VBox/ActionsRow2/ClaimBtn
@onready var clear_wood_btn: Button = $UI/Panel/Margin/VBox/ActionsRow2/ClearWoodBtn
@onready var end_day_btn: Button = $UI/Panel/Margin/VBox/DayRow/EndDayBtn
@onready var skip_week_btn: Button = $UI/Panel/Margin/VBox/DayRow/SkipWeekBtn
@onready var skip_to_work_btn: Button = $UI/Panel/Margin/VBox/DayRow/SkipToWorkBtn
@onready var save_btn: Button = $UI/Panel/Margin/VBox/MenuRow/SaveBtn
@onready var menu_btn: Button = $UI/Panel/Margin/VBox/MenuRow/MenuBtn
@onready var game_over_panel: PanelContainer = $UI/GameOverPanel

var selected_hex: Vector2i = Vector2i.ZERO
const MIN_ZOOM := 0.05
const MAX_ZOOM := 1.6
const HEX_VIEW_ZOOM := 0.55


func _ready() -> void:
	_connect_signals()
	_connect_buttons()
	GameState.init_plots_from_map(tile_map)
	TurnManager.begin_game_scene()
	SceneRouter.entering_new_game = false
	selected_hex = GameState.home_hex
	plot_overlay.setup(tile_map)
	plot_overlay.set_selected(selected_hex)
	map_renderer.setup(tile_map, camera)
	camera.position = tile_map.map_to_local(selected_hex)
	_set_hex_view(camera.zoom.x)
	_refresh_game_over_ui()
	_update_ui()


func _connect_signals() -> void:
	if not TurnManager.turn_started.is_connected(_on_turn_started):
		TurnManager.turn_started.connect(_on_turn_started)
	if not TurnManager.action_consumed.is_connected(_on_action_consumed):
		TurnManager.action_consumed.connect(_on_action_consumed)
	if not GameState.resources_changed.is_connected(_update_ui):
		GameState.resources_changed.connect(_update_ui)
	if not GameState.game_over.is_connected(_on_game_over):
		GameState.game_over.connect(_on_game_over)
	if not GameState.log_added.is_connected(_on_log_added):
		GameState.log_added.connect(_on_log_added)
	if not GameState.season_changed.is_connected(_on_season_changed):
		GameState.season_changed.connect(_on_season_changed)
	if not GameState.weather_changed.is_connected(_on_weather_changed):
		GameState.weather_changed.connect(_on_weather_changed)
	if not GameState.plot_changed.is_connected(_on_plot_changed):
		GameState.plot_changed.connect(_on_plot_changed)
	if not GameState.day_batch_finished.is_connected(_on_day_batch_finished):
		GameState.day_batch_finished.connect(_on_day_batch_finished)


func _connect_buttons() -> void:
	plant_wheat_btn.pressed.connect(_on_plant_wheat)
	plant_barley_btn.pressed.connect(_on_plant_barley)
	tend_btn.pressed.connect(_on_tend)
	harvest_btn.pressed.connect(_on_harvest)
	claim_btn.pressed.connect(_on_claim)
	clear_wood_btn.pressed.connect(_on_clear_wood)
	end_day_btn.pressed.connect(_on_end_day)
	skip_week_btn.pressed.connect(_on_skip_week)
	skip_to_work_btn.pressed.connect(_on_advance_until_work)
	save_btn.pressed.connect(_on_save)
	menu_btn.pressed.connect(_on_menu)
	$UI/GameOverPanel/Margin/VBox/MenuBtn.pressed.connect(_on_menu)


func _on_season_changed(_season: int, _year: int) -> void:
	_update_ui()


func _on_weather_changed(_weather: int) -> void:
	_update_ui()


func _on_plot_changed(_coords: Vector2i) -> void:
	_update_ui()


func _on_day_batch_finished(_days: int) -> void:
	_update_ui()


func _on_log_added(_message: String) -> void:
	_update_log()


func _refresh_game_over_ui() -> void:
	if GameState.game_lost:
		game_over_panel.visible = true
		game_over_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		var reason := GameState.last_game_over_reason
		if reason.is_empty():
			reason = "The household could not survive."
		$UI/GameOverPanel/Margin/VBox/ReasonLabel.text = reason
	else:
		game_over_panel.visible = false
		game_over_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _unhandled_input(event: InputEvent) -> void:
	if GameState.game_lost:
		return
	if _is_pointer_over_ui():
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


func _is_pointer_over_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false
	return ui_panel.is_ancestor_of(hovered) or game_over_panel.is_ancestor_of(hovered)


func _set_zoom(value: float) -> void:
	var z := clampf(value, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(z, z)
	_set_hex_view(z)
	_update_ui()


func _set_hex_view(zoom: float) -> void:
	plot_overlay.set_hex_view(zoom >= HEX_VIEW_ZOOM)


func _try_select_at_mouse() -> void:
	var target := tile_map.local_to_map(tile_map.get_local_mouse_position())
	if GameState.is_farm_plot(target) or GameState.can_claim_plot(target) or GameState.can_clear_wood(target):
		selected_hex = target
		plot_overlay.set_selected(target)
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


func _on_clear_wood() -> void:
	_run_action(GameState.try_clear_wood(selected_hex))


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
	GameState.last_game_over_reason = reason
	_refresh_game_over_ui()
	_update_ui()


func _on_turn_started(_turn_number: int) -> void:
	_update_ui()


func _on_action_consumed(_actions_remaining: int) -> void:
	_update_ui()


func _default_hint() -> String:
	if GameState.game_lost:
		return ""
	if TurnManager.has_actions() and GameState.has_actionable_work():
		return "Orange border = needs work. Scroll to zoom out to patch/block view."
	if TurnManager.has_actions():
		return "Quiet day — Shift+Space to skip ahead, or end the day."
	return "No labor left — end the day (Space) or Shift+Space to skip ahead."


func _update_log() -> void:
	log_label.text = "\n".join(GameState.log_lines)


func _update_ui() -> void:
	season_label.text = GameState.calendar_label(TurnManager.turn_number)
	resources_label.text = "Food %d · Wheat seed %d · Barley seed %d · %s" % [
		GameState.resources["food"],
		GameState.resources["wheat_seed"],
		GameState.resources["barley_seed"],
		GameState.weather_name(),
	]
	family_label.text = GameState.family_summary() + "\n" + GameState.holdings_summary()
	plot_label.text = GameState.plot_status(selected_hex)
	actions_label.text = "Labor today: %d / %d" % [
		TurnManager.actions_remaining,
		TurnManager.actions_per_turn,
	]
	zoom_label.text = GameState.render_level_name(camera.zoom.x)
	legend_label.text = (
		"Green=grass · blue=water · dark green WOOD · brown=field · "
		"orange=work · HOUSE/BARN=buildings · CLAIM/CLEAR to expand"
	)
	hint_label.text = _default_hint()
	plot_overlay.refresh()
	_update_log()
	var can_act := TurnManager.has_actions() and not GameState.game_lost
	plant_wheat_btn.disabled = not can_act
	plant_barley_btn.disabled = not can_act
	tend_btn.disabled = not can_act
	harvest_btn.disabled = not can_act
	claim_btn.disabled = not can_act or not GameState.can_claim_plot(selected_hex)
	clear_wood_btn.disabled = not can_act or not GameState.can_clear_wood(selected_hex)
	end_day_btn.disabled = GameState.game_lost
	skip_week_btn.disabled = GameState.game_lost
	skip_to_work_btn.disabled = GameState.game_lost
