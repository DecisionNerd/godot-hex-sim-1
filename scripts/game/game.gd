extends Node2D

const HexGrid = preload("res://scripts/world/hex_grid.gd")
const TerrainLayout = preload("res://scripts/render/terrain_layout.gd")
const Trader = preload("res://scripts/systems/trader.gd")
const WestTheme = preload("res://scripts/theme/west_theme.gd")

enum ViewMode { MAP, TERRAIN }

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var camera: Camera2D = $Camera2D
@onready var map_renderer: Node2D = $MapRenderer
@onready var plot_overlay: Node2D = $PlotOverlay
@onready var terrain_view: Node3D = $TerrainView
@onready var top_bar: PanelContainer = $UI/TopBar
@onready var plot_panel: PanelContainer = $UI/PlotPanel
@onready var season_label: Label = $UI/TopBar/Margin/HBox/InfoBlock/SeasonLabel
@onready var resources_label: Label = $UI/TopBar/Margin/HBox/InfoBlock/ResourcesLabel
@onready var family_label: Label = $UI/TopBar/Margin/HBox/InfoBlock/FamilyLabel
@onready var actions_label: Label = $UI/TopBar/Margin/HBox/StatusBlock/ActionsLabel
@onready var hint_label: Label = $UI/TopBar/Margin/HBox/StatusBlock/HintLabel
@onready var zoom_label: Label = $UI/TopBar/Margin/HBox/ZoomLabel
@onready var view_toggle_btn: Button = $UI/TopBar/Margin/HBox/ViewToggleBtn
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
@onready var plant_corn_btn: Button = $UI/PlotPanel/Margin/VBox/ActionsRow3/PlantCornBtn
@onready var plant_beans_btn: Button = $UI/PlotPanel/Margin/VBox/ActionsRow3/PlantBeansBtn
@onready var prove_up_btn: Button = $UI/PlotPanel/Margin/VBox/ActionsRow3/ProveUpBtn
@onready var trade_select: OptionButton = $UI/PlotPanel/Margin/VBox/TradeRow/TradeSelect
@onready var trade_buy_btn: Button = $UI/PlotPanel/Margin/VBox/TradeRow/TradeBuyBtn
@onready var trade_sell_btn: Button = $UI/PlotPanel/Margin/VBox/TradeRow/TradeSellBtn
@onready var trade_price_label: Label = $UI/PlotPanel/Margin/VBox/TradeRow/TradePriceLabel
@onready var game_over_panel: PanelContainer = $UI/GameOverPanel
@onready var game_over_title_label: Label = $UI/GameOverPanel/Margin/VBox/TitleLabel

const TRADE_COMMODITIES: Array[String] = [
	"food", "water", "firewood", "wood", "berries", "roots", "mushrooms", "meat",
	"corn_seed", "bean_seed", "tools",
]

var selected_hex: Vector2i = Vector2i.ZERO
var selected_hexes: Array[Vector2i] = []
var view_mode: ViewMode = ViewMode.MAP
var _ui_update_queued := false
var _overlay_refresh_queued := false
var _select_dragging := false
var _pan_dragging := false
var _pointer_press_screen := Vector2.ZERO
var _drag_last_screen := Vector2.ZERO
var _marquee: Control
const MIN_ZOOM := 0.05
const MAX_ZOOM := 1.6
const TERRAIN_MIN_ZOOM := 0.35
const TERRAIN_MAX_ZOOM := 3.0
const TERRAIN_DEFAULT_ZOOM := 1.15
const HEX_VIEW_ZOOM := 0.55
const PAN_SPEED := 900.0
const DEFAULT_ZOOM_RETINA := 0.85
const DRAG_THRESHOLD := 6.0
const ROTATE_STEP_DEG := 15.0
const ZOOM_KEY_FACTOR := 1.15

var map_rotation_deg := 0.0


func _ready() -> void:
	_connect_signals()
	_connect_buttons()
	_setup_trade_select()
	GameState.init_plots_from_map(tile_map)
	TurnManager.begin_game_scene()
	SceneRouter.entering_new_game = false
	selected_hex = GameState.home_hex
	selected_hexes = [selected_hex]
	plot_overlay.setup(tile_map, camera)
	plot_overlay.set_selected_hexes(selected_hexes)
	terrain_view.setup(camera)
	terrain_view.set_map_rotation(map_rotation_deg)
	terrain_view.set_selected_hexes(selected_hexes)
	map_renderer.setup(tile_map, camera)
	camera.position = GameState.map_to_world(selected_hex)
	_set_zoom(_default_camera_zoom())
	_apply_view_mode()
	_refresh_game_over_ui()
	_setup_selection_marquee()
	_request_ui_update(true)


func _setup_selection_marquee() -> void:
	_marquee = preload("res://scripts/ui/selection_marquee.gd").new()
	$UI.add_child(_marquee)
	_marquee.z_index = 50


func _process(delta: float) -> void:
	if GameState.game_lost or GameState.game_won:
		return
	var pan := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if pan != Vector2.ZERO:
		_pan_camera_world(pan * PAN_SPEED * delta)
	if _pan_dragging:
		var screen_pos := get_viewport().get_mouse_position()
		_pan_camera_screen(screen_pos - _drag_last_screen)
		_drag_last_screen = screen_pos
	if _select_dragging:
		var screen_pos := get_viewport().get_mouse_position()
		_marquee.set_marquee(_pointer_press_screen, screen_pos)


func _exit_tree() -> void:
	_disconnect_signals()


func _disconnect_signals() -> void:
	if TurnManager.turn_started.is_connected(_on_turn_started):
		TurnManager.turn_started.disconnect(_on_turn_started)
	if GameState.resources_changed.is_connected(_request_ui_update):
		GameState.resources_changed.disconnect(_request_ui_update)
	if GameState.game_over.is_connected(_on_game_over):
		GameState.game_over.disconnect(_on_game_over)
	if GameState.victory_achieved.is_connected(_on_game_won):
		GameState.victory_achieved.disconnect(_on_game_won)
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
	if not GameState.victory_achieved.is_connected(_on_game_won):
		GameState.victory_achieved.connect(_on_game_won)
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
	_connect_btn(plant_corn_btn, _on_plant_corn)
	_connect_btn(plant_beans_btn, _on_plant_beans)
	_connect_btn(prove_up_btn, _on_prove_up)
	_connect_btn(trade_buy_btn, _on_trade_buy)
	_connect_btn(trade_sell_btn, _on_trade_sell)
	if not trade_select.item_selected.is_connected(_on_trade_item_selected):
		trade_select.item_selected.connect(_on_trade_item_selected)
	_connect_btn(work_day_btn, _on_work_day)
	_connect_btn(end_day_btn, _on_end_day)
	_connect_btn(skip_week_btn, _on_skip_week)
	_connect_btn(skip_to_work_btn, _on_advance_until_work)
	_connect_btn(save_btn, _on_save)
	_connect_btn(menu_btn, _on_menu)
	_connect_btn(view_toggle_btn, _on_toggle_view)
	_connect_btn($UI/GameOverPanel/Margin/VBox/MenuBtn, _on_menu)


func _setup_trade_select() -> void:
	trade_select.clear()
	for commodity in TRADE_COMMODITIES:
		trade_select.add_item(WestTheme.resource_name(commodity))
		trade_select.set_item_metadata(trade_select.item_count - 1, commodity)
	_on_trade_item_selected(0)


func _selected_trade_commodity() -> String:
	var idx := trade_select.selected
	if idx < 0 or idx >= TRADE_COMMODITIES.size():
		return "food"
	return str(trade_select.get_item_metadata(idx))


func _on_trade_item_selected(_index: int) -> void:
	var commodity := _selected_trade_commodity()
	trade_price_label.text = "Buy $%d · Sell $%d" % [
		Trader.buy_price(commodity),
		Trader.sell_price(commodity),
	]


func _on_trade_buy() -> void:
	var commodity := _selected_trade_commodity()
	if GameState.buy_resource(commodity):
		hint_label.text = "Bought %s at the general store." % commodity.replace("_", " ")
	else:
		hint_label.text = "Cannot buy %s." % commodity.replace("_", " ")
	_request_ui_update()


func _on_trade_sell() -> void:
	var commodity := _selected_trade_commodity()
	if GameState.sell_resource(commodity):
		hint_label.text = "Sold %s at the general store." % commodity.replace("_", " ")
	else:
		hint_label.text = "Cannot sell %s." % commodity.replace("_", " ")
	_request_ui_update()


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
	if GameState.game_won:
		game_over_panel.visible = true
		game_over_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		game_over_title_label.text = "Claim proved up"
		var reason: String = GameState.last_victory_reason
		if reason.is_empty():
			reason = "The homestead claim is proved."
		$UI/GameOverPanel/Margin/VBox/ReasonLabel.text = reason
	elif GameState.game_lost:
		game_over_panel.visible = true
		game_over_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		game_over_title_label.text = "Game over"
		var reason: String = GameState.last_game_over_reason
		if reason.is_empty():
			reason = "The claim failed. The family did not survive the winter."
		$UI/GameOverPanel/Margin/VBox/ReasonLabel.text = reason
	else:
		game_over_panel.visible = false
		game_over_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _unhandled_input(event: InputEvent) -> void:
	if GameState.game_lost or GameState.game_won:
		return
	if event.is_action_pressed(&"advance_until_work"):
		_on_advance_until_work()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"end_turn"):
		_on_end_day()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q:
				_rotate_map(-ROTATE_STEP_DEG)
				get_viewport().set_input_as_handled()
			KEY_E:
				_rotate_map(ROTATE_STEP_DEG)
				get_viewport().set_input_as_handled()
			KEY_R:
				_set_zoom(camera.zoom.x * ZOOM_KEY_FACTOR)
				get_viewport().set_input_as_handled()
			KEY_F:
				_set_zoom(camera.zoom.x / ZOOM_KEY_FACTOR)
				get_viewport().set_input_as_handled()
			KEY_V:
				_toggle_view_mode()
				get_viewport().set_input_as_handled()
			KEY_B:
				_on_trade_buy()
				get_viewport().set_input_as_handled()
			KEY_N:
				_on_trade_sell()
				get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if GameState.game_lost or GameState.game_won:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_apply_wheel_zoom(mouse_event)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMagnifyGesture:
		var mag := event as InputEventMagnifyGesture
		_set_zoom(camera.zoom.x * (1.0 + mag.factor * 0.35))
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_LEFT and _select_dragging:
				_finish_select_drag()
			if mouse_event.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
				_pan_dragging = false
	if _is_pointer_over_ui():
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventPanGesture:
		_pan_camera_screen(-(event as InputEventPanGesture).delta)
		get_viewport().set_input_as_handled()


func _apply_wheel_zoom(mouse_event: InputEventMouseButton) -> void:
	var factor := maxf(mouse_event.factor, 1.0)
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_set_zoom(camera.zoom.x * pow(1.12, factor))
	else:
		_set_zoom(camera.zoom.x / pow(1.12, factor))


func _handle_mouse_button(mouse_event: InputEventMouseButton) -> void:
	match mouse_event.button_index:
		MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_select_dragging = true
				_pointer_press_screen = get_viewport().get_mouse_position()
			get_viewport().set_input_as_handled()
		MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed:
				_pan_dragging = true
				_drag_last_screen = get_viewport().get_mouse_position()
			get_viewport().set_input_as_handled()


func _finish_select_drag() -> void:
	_select_dragging = false
	_marquee.clear_marquee()
	var release_pos := get_viewport().get_mouse_position()
	if release_pos.distance_to(_pointer_press_screen) < DRAG_THRESHOLD:
		_try_select_at_mouse()
		return
	_select_hexes_in_screen_rect(Rect2(_pointer_press_screen, release_pos - _pointer_press_screen))


func _is_pointer_over_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false
	return top_bar.is_ancestor_of(hovered) or plot_panel.is_ancestor_of(hovered) or game_over_panel.is_ancestor_of(hovered)


func _zoom_limits() -> Vector2:
	if view_mode == ViewMode.TERRAIN:
		return Vector2(TERRAIN_MIN_ZOOM, TERRAIN_MAX_ZOOM)
	return Vector2(MIN_ZOOM, MAX_ZOOM)


func _set_zoom(value: float) -> void:
	var limits := _zoom_limits()
	var z := clampf(value, limits.x, limits.y)
	camera.zoom = Vector2(z, z)
	_set_hex_view(z)
	_refresh_world_view()
	_request_ui_update()


func _default_camera_zoom() -> float:
	if OS.get_name() == "macOS" and DisplayServer.screen_get_scale() >= 1.5:
		return DEFAULT_ZOOM_RETINA
	return 1.0


func _pan_camera_screen(screen_offset: Vector2) -> void:
	if screen_offset == Vector2.ZERO:
		return
	camera.position += screen_offset.rotated(camera.rotation) / camera.zoom.x
	_refresh_world_view()


func _pan_camera_world(world_offset: Vector2) -> void:
	if world_offset == Vector2.ZERO:
		return
	camera.position += world_offset / camera.zoom.x
	_refresh_world_view()


func _rotate_map(delta_deg: float) -> void:
	map_rotation_deg = fposmod(map_rotation_deg + delta_deg, 360.0)
	camera.rotation_degrees = map_rotation_deg
	terrain_view.set_map_rotation(map_rotation_deg)
	_refresh_world_view()
	_request_ui_update()


func _set_hex_view(zoom: float) -> void:
	if view_mode == ViewMode.TERRAIN:
		return
	plot_overlay.set_hex_view(zoom >= HEX_VIEW_ZOOM)


func _focus_hex_for_view() -> Vector2i:
	if GameState.hex_sim != null and GameState.hex_sim.hexes.has(selected_hex):
		return selected_hex
	if view_mode == ViewMode.MAP:
		return HexGrid.local_to_map(camera.position)
	return TerrainLayout.screen_to_hex(camera.position)


func _camera_pos_for_hex(coords: Vector2i, mode: ViewMode) -> Vector2:
	if mode == ViewMode.TERRAIN:
		return TerrainLayout.camera_position_for_hex(coords)
	return GameState.map_to_world(coords)


func _toggle_view_mode() -> void:
	var focus := _focus_hex_for_view()
	if view_mode == ViewMode.MAP:
		view_mode = ViewMode.TERRAIN
		camera.position = _camera_pos_for_hex(focus, ViewMode.TERRAIN)
		_set_zoom(TERRAIN_DEFAULT_ZOOM)
	else:
		view_mode = ViewMode.MAP
		camera.position = _camera_pos_for_hex(focus, ViewMode.MAP)
	_apply_view_mode()
	_request_ui_update(true)


func _on_toggle_view() -> void:
	_toggle_view_mode()


func _apply_view_mode() -> void:
	var is_terrain := view_mode == ViewMode.TERRAIN
	tile_map.visible = not is_terrain
	map_renderer.visible = not is_terrain
	terrain_view.visible = is_terrain
	camera.enabled = not is_terrain
	terrain_view.set_active(is_terrain)
	if is_terrain:
		plot_overlay.visible = false
		terrain_view.set_map_rotation(map_rotation_deg)
		terrain_view.sync_camera(camera)
		terrain_view.refresh()
	else:
		_set_hex_view(camera.zoom.x)
	view_toggle_btn.text = "Map" if is_terrain else "Terrain"


func _mouse_map_coords() -> Vector2i:
	if view_mode == ViewMode.TERRAIN:
		return terrain_view.pick_hex(get_viewport().get_mouse_position())
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	return HexGrid.local_to_map(world_pos)


func _set_selection(hexes: Array[Vector2i]) -> void:
	selected_hexes = hexes
	selected_hex = hexes[0] if hexes.size() > 0 else Vector2i.ZERO
	plot_overlay.set_selected_hexes(selected_hexes)
	terrain_view.set_selected_hexes(selected_hexes)
	_request_ui_update()


func _hex_world_position(coords: Vector2i) -> Vector2:
	if view_mode == ViewMode.TERRAIN:
		return TerrainLayout.planar_position(coords)
	return GameState.map_to_world(coords)


func _screen_rect_to_world(screen_rect: Rect2) -> Rect2:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	var a: Vector2 = inv * screen_rect.position
	var b: Vector2 = inv * screen_rect.end
	return Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), Vector2(absf(b.x - a.x), absf(b.y - a.y)))


func _select_hexes_in_screen_rect(screen_rect: Rect2) -> void:
	if GameState.hex_sim == null:
		return
	var world_rect := _screen_rect_to_world(screen_rect)
	var found: Array[Vector2i] = []
	for coords in GameState.hex_sim.hexes:
		if world_rect.has_point(_hex_world_position(coords)):
			found.append(coords)
	if found.is_empty():
		hint_label.text = "No hexes in that area."
		return
	_set_selection(found)


func _try_select_at_mouse() -> void:
	var target := _mouse_map_coords()
	if target == Vector2i(999999, 999999) or not GameState.hex_sim.hexes.has(target):
		hint_label.text = "Click a hex in the valley."
		return
	_set_selection([target])


func _assign(type: String, crop_id: String = "") -> void:
	if selected_hexes.is_empty():
		hint_label.text = "Select hexes first (click or drag a box)."
		return
	var ok_count := 0
	var last_error := ""
	for coords in selected_hexes:
		var result: String = GameState.assign_order(coords, type, crop_id)
		if result == "ok":
			ok_count += 1
		else:
			last_error = result
	if ok_count == 0:
		hint_label.text = last_error if not last_error.is_empty() else "Could not assign chore."
	elif ok_count == 1:
		hint_label.text = "Marked 1 hex. Press Work day to send labor."
	else:
		hint_label.text = "Marked %d hexes. Press Work day to send labor." % ok_count
	_request_ui_update(true)


func _on_plant_wheat() -> void:
	_assign("forage")


func _on_plant_barley() -> void:
	_assign("clear")


func _on_tend() -> void:
	_assign("collect_water")


func _on_harvest() -> void:
	_assign("trap")


func _on_claim() -> void:
	_assign("build_cabin")


func _on_plant_corn() -> void:
	_assign("plant", "corn")


func _on_plant_beans() -> void:
	_assign("plant", "beans")


func _on_prove_up() -> void:
	if GameState.prove_up():
		_refresh_game_over_ui()
		_request_ui_update(true)
	else:
		hint_label.text = "Claim not ready to prove up yet."


func _on_clear_wood() -> void:
	var chopped := 0
	for coords in selected_hexes:
		if GameState.can_clear_wood(coords):
			if GameState.try_chop_firewood(coords) == "ok":
				chopped += 1
	if chopped > 0:
		hint_label.text = "Chopped firewood on %d hex." % chopped if chopped == 1 else "Chopped firewood on %d hexes." % chopped
		_request_ui_update(true)
		return
	_assign("field")


func _on_cancel_order() -> void:
	var removed := 0
	for coords in selected_hexes:
		if GameState.cancel_order(coords):
			removed += 1
	if removed > 0:
		hint_label.text = "Removed chore from %d hex." % removed if removed == 1 else "Removed chores from %d hexes." % removed
	_request_ui_update(true)


func _selection_has_order() -> bool:
	for coords in selected_hexes:
		if GameState.has_order(coords):
			return true
	return false


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


func _on_game_won(reason: String) -> void:
	GameState.last_victory_reason = reason
	_refresh_game_over_ui()
	_request_ui_update(true)


func _on_turn_started(_turn_number: int) -> void:
	_request_ui_update()


func _refresh_world_view() -> void:
	if view_mode == ViewMode.TERRAIN:
		terrain_view.sync_camera(camera)
		terrain_view.refresh()
	else:
		plot_overlay.refresh()


func _default_hint() -> String:
	if GameState.game_lost or GameState.game_won:
		return ""
	if GameState.can_prove_up():
		return "Requirements met — file proof with Prove up claim."
	if view_mode == ViewMode.TERRAIN:
		if GameState.has_pending_orders():
			if GameState.labor_pool > 0:
				return "Work day runs chores on turquoise hexes. Q/E rotate · R/F zoom · drag pan · V map."
			return "Out of labor today — end the day. Q/E rotate · R/F zoom."
		if GameState.has_order(selected_hex):
			return "Chore marked on selected hex. Q/E rotate · R/F zoom · drag pan."
		return "Click hexes or drag a box to select. Q/E rotate · R/F zoom · right-drag pan · V map."
	if GameState.has_pending_orders():
		if GameState.labor_pool > 0:
			return "Work day spends labor on chores; end the day to advance the calendar."
		return "Out of labor today — end the day."
	if GameState.needs_attention():
		return "Gather or harvest is ready. Select the hex, then assign a chore."
	return "Drag box or click to select · assign chores · Work day. WASD pan (map north) · right-drag · Q/E · R/F · V."


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
	resources_label.text = GameState.resources_summary() + " · " + GameState.weather_name()
	family_label.text = GameState.family_summary() + " · " + GameState.holdings_summary()
	if selected_hexes.size() > 1:
		plot_title_label.text = "%d hexes selected" % selected_hexes.size()
	else:
		plot_title_label.text = "Claim hex (%d, %d)" % [selected_hex.x, selected_hex.y]
	plot_label.text = _plot_label_text()
	actions_label.text = GameState.objective_summary() + " · Labor %d/%d · Chores: %d" % [
		GameState.labor_pool,
		GameState.labor_per_day,
		GameState.order_count(),
	]
	zoom_label.text = _zoom_label_text()
	legend_label.text = (
		"Side view: shade=elevation · blue=arroyo · turquoise=chore hex · tan=field"
		if view_mode == ViewMode.TERRAIN
		else "Shade=elevation · blue=arroyo · red=cliffs · turquoise=chore · tan=field"
	)
	hint_label.text = _default_hint()
	if refresh_overlay:
		plot_overlay.refresh()
		terrain_view.refresh()
	_update_log()
	var live: bool = not GameState.game_lost and not GameState.game_won
	plant_wheat_btn.text = "Gather chore"
	plant_barley_btn.text = "Clear brush"
	tend_btn.text = "Haul water"
	harvest_btn.text = "Set snares"
	claim_btn.text = "Build cabin"
	clear_wood_btn.text = "Field / chop fuelwood"
	cancel_btn.text = "Remove chore"
	plant_corn_btn.text = "Plant corn"
	plant_beans_btn.text = "Plant beans"
	prove_up_btn.text = "Prove up claim"
	plant_wheat_btn.disabled = not live
	plant_barley_btn.disabled = not live
	tend_btn.disabled = not live
	harvest_btn.disabled = not live
	claim_btn.disabled = not live
	clear_wood_btn.disabled = not live
	cancel_btn.disabled = not live or not _selection_has_order()
	plant_corn_btn.disabled = not live or not _can_plant_field()
	plant_beans_btn.disabled = not live or not _can_plant_field()
	prove_up_btn.disabled = not live or not GameState.can_prove_up()
	trade_buy_btn.disabled = not live
	trade_sell_btn.disabled = not live
	work_day_btn.disabled = not live or not GameState.has_pending_orders() or GameState.labor_pool <= 0
	end_day_btn.disabled = GameState.game_lost or GameState.game_won
	skip_week_btn.disabled = GameState.game_lost or GameState.game_won
	skip_to_work_btn.disabled = GameState.game_lost or GameState.game_won
	_on_trade_item_selected(trade_select.selected)


func _zoom_label_text() -> String:
	var pct := int(round(camera.zoom.x * 100.0))
	if view_mode == ViewMode.TERRAIN:
		return "Zoom %d%% · rot %d° (R/F · Q/E)" % [pct, int(round(map_rotation_deg))]
	return "Zoom %d%% · %s · rot %d°" % [pct, GameState.render_level_name(camera.zoom.x), int(round(map_rotation_deg))]


func _plot_label_text() -> String:
	var text: String = GameState.hex_status(selected_hex)
	if selected_hexes.size() > 1:
		text += "\n(%d hexes in selection — details for active hex)" % selected_hexes.size()
	if GameState.has_order(selected_hex):
		text += "\nChore: %s" % GameState.order_label(selected_hex)
	var hex = GameState.get_hex(selected_hex)
	if hex != null and hex.field_id != "" and GameState.fields.has(hex.field_id):
		var field = GameState.fields[hex.field_id]
		if not field.is_empty():
			var crop = GameState.get_crop(field.crop_id)
			var crop_name: String = crop.display_name if crop != null else field.crop_id
			text += "\nField crop: %s (%d days)" % [crop_name, field.growth_days]
	text += "\nGeneral store: choose commodity below · B=buy · N=sell"
	return text


func _can_plant_field() -> bool:
	if selected_hexes.is_empty():
		return false
	var field_id: String = GameState.ensure_active_field()
	if not GameState.fields.has(field_id):
		return false
	var field = GameState.fields[field_id]
	return field.hexes.size() > 0 and field.is_empty()
