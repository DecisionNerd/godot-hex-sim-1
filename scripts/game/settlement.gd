extends Node2D

const HexGrid = preload("res://scripts/world/hex_grid.gd")
const TerrainLayout = preload("res://scripts/render/terrain_layout.gd")

enum ViewMode { MAP, TERRAIN }

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var camera: Camera2D = $Camera2D
@onready var plot_overlay: Node2D = $PlotOverlay
@onready var map_renderer: Node2D = $MapRenderer
@onready var terrain_view: Node3D = $TerrainView
@onready var hint_label: Label = $UI/Panel/Margin/VBox/HintLabel
@onready var confirm_btn: Button = $UI/Panel/Margin/VBox/ConfirmBtn
@onready var view_toggle_btn: Button = $UI/Panel/Margin/VBox/ViewToggleBtn
@onready var title_label: Label = $UI/Panel/Margin/VBox/TitleLabel

var selected_hex: Vector2i = Vector2i(999999, 999999)
var view_mode: ViewMode = ViewMode.MAP
var _pointer_dragging := false
var _pointer_panned := false
var _pointer_press_screen := Vector2.ZERO
var _drag_last_screen := Vector2.ZERO
const MIN_ZOOM := 0.05
const MAX_ZOOM := 1.6
const TERRAIN_MIN_ZOOM := 0.35
const TERRAIN_MAX_ZOOM := 3.0
const TERRAIN_DEFAULT_ZOOM := 1.15
const PAN_SPEED := 900.0
const DRAG_THRESHOLD := 6.0
const ROTATE_STEP_DEG := 15.0
const ZOOM_KEY_FACTOR := 1.15

var map_rotation_deg := 0.0


func _ready() -> void:
	GameState.ensure_world_map()
	MapGenerator.prepare_tile_map(tile_map)
	plot_overlay.setup(tile_map, camera)
	terrain_view.setup(camera)
	terrain_view.set_map_rotation(map_rotation_deg)
	map_renderer.setup(tile_map, camera)
	camera.position = GameState.map_to_world(Vector2i.ZERO)
	camera.zoom = Vector2(0.35, 0.35)
	_apply_view_mode()
	confirm_btn.pressed.connect(_on_confirm)
	view_toggle_btn.pressed.connect(_on_toggle_view)
	title_label.text = GameState.scenario_settlement_title()
	_update_hint()


func _process(delta: float) -> void:
	var pan := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if pan != Vector2.ZERO:
		_pan_camera(pan.rotated(camera.rotation) * PAN_SPEED * delta)
	if _pointer_dragging:
		var screen_pos := get_viewport().get_mouse_position()
		if not _pointer_panned and screen_pos.distance_to(_pointer_press_screen) >= DRAG_THRESHOLD:
			_pointer_panned = true
		if _pointer_panned:
			_pan_camera(screen_pos - _drag_last_screen)
		_drag_last_screen = screen_pos


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
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


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			_apply_wheel_zoom(mouse_event)
			return
	if event is InputEventMagnifyGesture:
		var mag := event as InputEventMagnifyGesture
		_set_zoom(camera.zoom.x * (1.0 + mag.factor * 0.35))
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_LEFT and _pointer_dragging and not _pointer_panned:
				_try_select_at_mouse()
			_pointer_dragging = false
			_pointer_panned = false
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventPanGesture:
		_pan_camera(-(event as InputEventPanGesture).delta)


func _apply_wheel_zoom(mouse_event: InputEventMouseButton) -> void:
	var factor := maxf(mouse_event.factor, 1.0)
	if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_set_zoom(camera.zoom.x * pow(1.12, factor))
	else:
		_set_zoom(camera.zoom.x / pow(1.12, factor))


func _handle_mouse_button(mouse_event: InputEventMouseButton) -> void:
	match mouse_event.button_index:
		MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed:
				_pointer_dragging = true
				_pointer_panned = false
				_pointer_press_screen = get_viewport().get_mouse_position()
				_drag_last_screen = _pointer_press_screen


func _focus_hex_for_view() -> Vector2i:
	if selected_hex != Vector2i(999999, 999999) and GameState.hex_sim.hexes.has(selected_hex):
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
	_update_hint()


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
		plot_overlay.set_hex_view(true)
	view_toggle_btn.text = "Map view" if is_terrain else "Terrain view"


func _mouse_map_coords() -> Vector2i:
	if view_mode == ViewMode.TERRAIN:
		return terrain_view.pick_hex(get_viewport().get_mouse_position())
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
	return HexGrid.local_to_map(world_pos)


func _try_select_at_mouse() -> void:
	var target := _mouse_map_coords()
	if target == Vector2i(999999, 999999) or not GameState.hex_sim.hexes.has(target):
		return
	selected_hex = target
	plot_overlay.set_selected(target)
	terrain_view.set_selected(target)
	_refresh_views()
	_update_hint()


func _on_confirm() -> void:
	if selected_hex == Vector2i(999999, 999999):
		hint_label.text = "Click a valid hex for your claim."
		return
	if not GameState.is_settleable(selected_hex):
		hint_label.text = "Cannot settle on water or cliffs."
		return
	GameState.begin_settlement(selected_hex)
	SceneRouter.go_to_game_from_settlement()


func _update_hint() -> void:
	if view_mode == ViewMode.TERRAIN:
		if selected_hex == Vector2i(999999, 999999):
			hint_label.text = "Q/E rotate · R/F zoom · drag pan · click a hex to claim. V returns to map."
			confirm_btn.disabled = true
			return
	else:
		if selected_hex == Vector2i(999999, 999999):
			hint_label.text = "Pan the valley and pick a claim site. V toggles terrain view."
			confirm_btn.disabled = true
			return
	var hex = GameState.get_hex(selected_hex)
	if hex == null:
		confirm_btn.disabled = true
		return
	var near_water := "Near freshwater." if hex.is_riparian or hex.is_spring else ""
	var controls := "Q/E rotate · R/F zoom · drag pan · V toggles view." if view_mode == ViewMode.TERRAIN else "Q/E rotate · R/F zoom · V toggles terrain view."
	hint_label.text = "Elev %.0f m. %s %s %s" % [
		hex.elevation,
		"Claimable." if GameState.is_settleable(selected_hex) else "Not claimable.",
		near_water,
		controls,
	]
	confirm_btn.disabled = not GameState.is_settleable(selected_hex)


func _zoom_limits() -> Vector2:
	if view_mode == ViewMode.TERRAIN:
		return Vector2(TERRAIN_MIN_ZOOM, TERRAIN_MAX_ZOOM)
	return Vector2(MIN_ZOOM, MAX_ZOOM)


func _set_zoom(value: float) -> void:
	var limits := _zoom_limits()
	var z := clampf(value, limits.x, limits.y)
	camera.zoom = Vector2(z, z)
	_refresh_views()


func _pan_camera(screen_offset: Vector2) -> void:
	if screen_offset == Vector2.ZERO:
		return
	camera.position += screen_offset.rotated(camera.rotation) / camera.zoom.x
	_refresh_views()


func _rotate_map(delta_deg: float) -> void:
	map_rotation_deg = fposmod(map_rotation_deg + delta_deg, 360.0)
	camera.rotation_degrees = map_rotation_deg
	terrain_view.set_map_rotation(map_rotation_deg)
	_refresh_views()
	_update_hint()


func _refresh_views() -> void:
	if view_mode == ViewMode.TERRAIN:
		terrain_view.sync_camera(camera)
		terrain_view.refresh()
	else:
		plot_overlay.refresh()
