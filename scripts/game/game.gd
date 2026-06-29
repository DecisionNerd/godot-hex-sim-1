extends Node2D

const HexGrid = preload("res://scripts/world/hex_grid.gd")

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var camera: Camera2D = $Camera2D
@onready var map_renderer: Node2D = $MapRenderer
@onready var plot_overlay: Node2D = $PlotOverlay
@onready var top_bar: PanelContainer = $UI/TopBar
@onready var plot_panel: PanelContainer = $UI/PlotPanel
@onready var season_label: Label = $UI/TopBar/Margin/HBox/InfoBlock/SeasonLabel
@onready var resources_label: Label = $UI/TopBar/Margin/HBox/InfoBlock/ResourcesLabel
@onready var family_label: Label = $UI/TopBar/Margin/HBox/InfoBlock/FamilyLabel
@onready var actions_label: Label = $UI/TopBar/Margin/HBox/StatusBlock/ActionsLabel
@onready var hint_label: Label = $UI/TopBar/Margin/HBox/StatusBlock/HintLabel
@onready var zoom_label: Label = $UI/TopBar/Margin/HBox/ZoomLabel
@onready var work_day_btn: Button = $UI/TopBar/Margin/HBox/DayRow/WorkDayBtn
@onready var end_day_btn: Button = $UI/TopBar/Margin/HBox/DayRow/EndDayBtn
@onready var skip_week_btn: Button = $UI/TopBar/Margin/HBox/DayRow/SkipWeekBtn
@onready var skip_to_work_btn: Button = $UI/TopBar/Margin/HBox/DayRow/SkipToWorkBtn
@onready var save_btn: Button = $UI/TopBar/Margin/HBox/MenuRow/SaveBtn
@onready var menu_btn: Button = $UI/TopBar/Margin/HBox/MenuRow/MenuBtn
@onready var plot_title_label: Label = $UI/PlotPanel/Margin/VBox/PlotTitleLabel
@onready var plot_label: Label = $UI/PlotPanel/Margin/VBox/PlotLabel
@onready var legend_label: Label = $UI/PlotPanel/Margin/VBox/LegendLabel
@onready var log_label: Label = $UI/PlotPanel/Margin/VBox/LogScroll/LogLabel
@onready var plant_wheat_btn: Button = $UI/PlotPanel/Margin/VBox/ActionsRow/PlantWheatBtn
@onready var plant_barley_btn: Button = $UI/PlotPanel/Margin/VBox/ActionsRow/PlantBarleyBtn
@onready var tend_btn: Button = $UI/PlotPanel/Margin/VBox/ActionsRow/TendBtn
@onready var harvest_btn: Button = $UI/PlotPanel/Margin/VBox/ActionsRow/HarvestBtn
@onready var claim_btn: Button = $UI/PlotPanel/Margin/VBox/ActionsRow2/ClaimBtn
@onready var clear_wood_btn: Button = $UI/PlotPanel/Margin/VBox/ActionsRow2/ClearWoodBtn
@onready var cancel_btn: Button = $UI/PlotPanel/Margin/VBox/ActionsRow2/CancelBtn
@onready var game_over_panel: PanelContainer = $UI/GameOverPanel

var selected_hex: Vector2i = Vector2i.ZERO
var _ui_update_queued := false
var _overlay_refresh_queued := false
var _dragging := false
var _drag_last_screen := Vector2.ZERO
const MIN_ZOOM := 0.05
const MAX_ZOOM := 1.6
const HEX_VIEW_ZOOM := 0.55
const PAN_SPEED := 900.0
const DEFAULT_ZOOM_RETINA := 0.85


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
	camera.position = GameState.map_to_world(selected_hex)
	_set_zoom(_default_camera_zoom())
	_refresh_game_over_ui()
	_request_ui_update(true)


func _process(delta: float) -> void:
	if GameState.game_lost:
		return
	var pan := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if pan != Vector2.ZERO:
		_pan_camera(pan * PAN_SPEED * delta)
	if _dragging:
		var screen_pos := get_viewport().get_mouse_position()
		_pan_camera(screen_pos - _drag_last_screen)
		_drag_last_screen = screen_pos


func _exit_tree() -> void:
	_disconnect_signals()


func _disconnect_signals() -> void:
	if TurnManager.turn_started.is_connected(_on_turn_started):
		TurnManager.turn_started.disconnect(_on_turn_started)
	if GameState.resources_changed.is_connected(_request_ui_update):
		GameState.resources_changed.disconnect(_request_ui_update)
	if GameState.game_over.is_connected(_on_game_over):
		GameState.game_over.disconnect(_on_game_over)
	if GameState.log_added.is_connected(_on_log_added):
		GameState.log_added.disconnect(_on_log_added)
	if GameState.season_changed.is_connected(_on_season_changed):
		GameState.season_changed.disconnect(_on_season_changed)
	if GameState.weather_changed.is_connected(_on_weather_changed):
		GameState.weather_changed.disconnect(_on_weather_changed)
	if GameState.plot_changed.is_connected(_on_plot_changed):
		GameState.plot_changed.disconnect(_on_plot_changed)
	if GameState.day_batch_finished.is_connected(_on_day_batch_finished):
		GameState.day_batch_finished.disconnect(_on_day_batch_finished)


func _connect_signals() -> void:
	if not TurnManager.turn_started.is_connected(_on_turn_started):
		TurnManager.turn_started.connect(_on_turn_started)
	if not GameState.resources_changed.is_connected(_request_ui_update):
		GameState.resources_changed.connect(_request_ui_update)
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
	_connect_btn(plant_wheat_btn, _on_plant_wheat)
	_connect_btn(plant_barley_btn, _on_plant_barley)
	_connect_btn(tend_btn, _on_tend)
	_connect_btn(harvest_btn, _on_harvest)
	_connect_btn(claim_btn, _on_claim)
	_connect_btn(clear_wood_btn, _on_clear_wood)
	_connect_btn(cancel_btn, _on_cancel_order)
	_connect_btn(work_day_btn, _on_work_day)
	_connect_btn(end_day_btn, _on_end_day)
	_connect_btn(skip_week_btn, _on_skip_week)
	_connect_btn(skip_to_work_btn, _on_advance_until_work)
	_connect_btn(save_btn, _on_save)
	_connect_btn(menu_btn, _on_menu)
	_connect_btn($UI/GameOverPanel/Margin/VBox/MenuBtn, _on_menu)


func _connect_btn(button: BaseButton, callable: Callable) -> void:
	if not button.pressed.is_connected(callable):
		button.pressed.connect(callable)


func _on_season_changed(_season: int, _year: int) -> void:
	_request_ui_update()


func _on_weather_changed(_weather: int) -> void:
	_request_ui_update()


func _on_plot_changed(_coords: Vector2i) -> void:
	_request_ui_update(true)


func _on_day_batch_finished(_days: int) -> void:
	_request_ui_update(true)


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
			elif mouse_event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
				_dragging = mouse_event.pressed
				if _dragging:
					_drag_last_screen = get_viewport().get_mouse_position()
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
	return top_bar.is_ancestor_of(hovered) or plot_panel.is_ancestor_of(hovered) or game_over_panel.is_ancestor_of(hovered)


func _set_zoom(value: float) -> void:
	var z := clampf(value, MIN_ZOOM, MAX_ZOOM)
	camera.zoom = Vector2(z, z)
	_set_hex_view(z)
	_request_ui_update()


func _default_camera_zoom() -> float:
	if OS.get_name() == "macOS" and DisplayServer.screen_get_scale() >= 1.5:
		return DEFAULT_ZOOM_RETINA
	return 1.0


func _pan_camera(screen_offset: Vector2) -> void:
	if screen_offset == Vector2.ZERO:
		return
	camera.position += screen_offset / camera.zoom.x


func _set_hex_view(zoom: float) -> void:
	plot_overlay.set_hex_view(zoom >= HEX_VIEW_ZOOM)


func _try_select_at_mouse() -> void:
	var local_pos := to_local(get_global_mouse_position())
	var target := HexGrid.local_to_map(local_pos)
	if GameState.is_farm_plot(target) or GameState.can_claim_plot(target) or GameState.can_clear_wood(target):
		selected_hex = target
		plot_overlay.set_selected(target)
		_request_ui_update()
		return
	hint_label.text = "Click your plots or adjacent wild land to claim."


func _assign(type: String, crop_id: String = "") -> void:
	var result: String = GameState.assign_order(selected_hex, type, crop_id)
	if result != "ok":
		hint_label.text = result
	else:
		hint_label.text = "Queued %s. Work the day or end the day to do it." % GameState.order_label(selected_hex)
	_request_ui_update(true)


func _on_plant_wheat() -> void:
	_assign("plant", "wheat")


func _on_plant_barley() -> void:
	_assign("plant", "barley")


func _on_tend() -> void:
	_assign("tend")


func _on_harvest() -> void:
	_assign("harvest")


func _on_claim() -> void:
	_assign("claim")


func _on_clear_wood() -> void:
	_assign("clear_wood")


func _on_cancel_order() -> void:
	if GameState.cancel_order(selected_hex):
		hint_label.text = "Order cancelled."
	_request_ui_update(true)


func _on_work_day() -> void:
	if GameState.game_lost:
		return
	GameState.work_today()
	hint_label.text = _default_hint()
	_request_ui_update(true)


func _on_end_day() -> void:
	if not GameState.game_lost:
		TurnManager.end_turn()


func _on_skip_week() -> void:
	if not GameState.game_lost:
		TurnManager.skip_days(7)


func _on_advance_until_work() -> void:
	if not GameState.game_lost:
		TurnManager.advance_until_actionable()
		_request_ui_update(true)


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
	_request_ui_update(true)


func _on_turn_started(_turn_number: int) -> void:
	_request_ui_update()


func _default_hint() -> String:
	if GameState.game_lost:
		return ""
	if GameState.has_pending_orders():
		if GameState.labor_pool > 0:
			return "Work day spends labour on your queue; end the day to roll it forward."
		return "Out of labour today — end the day (Space) and the household keeps working."
	if GameState.needs_attention():
		return "Orange border = needs work. Click a plot and queue an order."
	return "WASD pans · right/middle-drag pans · scroll zooms · Shift+Space skips ahead."


func _update_log() -> void:
	if log_label == null:
		return
	log_label.text = "\n".join(GameState.log_lines)


func _request_ui_update(refresh_overlay: bool = false) -> void:
	if refresh_overlay:
		_overlay_refresh_queued = true
	if _ui_update_queued:
		return
	_ui_update_queued = true
	call_deferred("_flush_ui_update")


func _flush_ui_update() -> void:
	_ui_update_queued = false
	if not is_inside_tree():
		return
	var refresh_overlay := _overlay_refresh_queued
	_overlay_refresh_queued = false
	_update_ui(refresh_overlay)


func _update_ui(refresh_overlay: bool = false) -> void:
	if not is_node_ready():
		return
	season_label.text = GameState.calendar_label(TurnManager.turn_number)
	resources_label.text = "Food %d · Wheat seed %d · Barley seed %d · %s" % [
		GameState.resources["food"],
		GameState.resources["wheat_seed"],
		GameState.resources["barley_seed"],
		GameState.weather_name(),
	]
	family_label.text = GameState.family_summary() + " · " + GameState.holdings_summary()
	plot_title_label.text = "Plot (%d, %d)" % [selected_hex.x, selected_hex.y]
	plot_label.text = _plot_label_text()
	actions_label.text = "Labour today %d / %d · Queued: %d" % [
		GameState.labor_pool,
		GameState.labor_per_day,
		GameState.order_count(),
	]
	zoom_label.text = GameState.render_level_name(camera.zoom.x)
	legend_label.text = "Green=grass · blue=water · dark green WOOD · brown=field · orange=work · cyan=queued order · HOUSE/BARN=buildings"
	hint_label.text = _default_hint()
	if refresh_overlay:
		plot_overlay.refresh()
	_update_log()
	var live := not GameState.game_lost
	var is_plot := GameState.is_farm_plot(selected_hex)
	plant_wheat_btn.disabled = not live or not is_plot
	plant_barley_btn.disabled = not live or not is_plot
	tend_btn.disabled = not live or not is_plot
	harvest_btn.disabled = not live or not is_plot
	claim_btn.disabled = not live or not GameState.can_claim_plot(selected_hex)
	clear_wood_btn.disabled = not live or not GameState.can_clear_wood(selected_hex)
	cancel_btn.disabled = not live or not GameState.has_order(selected_hex)
	work_day_btn.disabled = not live or not GameState.has_pending_orders() or GameState.labor_pool <= 0
	end_day_btn.disabled = GameState.game_lost
	skip_week_btn.disabled = GameState.game_lost
	skip_to_work_btn.disabled = GameState.game_lost


func _plot_label_text() -> String:
	var text: String = GameState.plot_status(selected_hex)
	if GameState.has_order(selected_hex):
		text += "\nOrder: %s" % GameState.order_label(selected_hex)
	return text
