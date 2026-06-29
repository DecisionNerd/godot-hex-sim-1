extends Node2D

const Unit = preload("res://scripts/units/unit.gd")

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var unit: Node2D = $Unit
@onready var season_label: Label = $UI/Panel/Margin/VBox/SeasonLabel
@onready var resources_label: Label = $UI/Panel/Margin/VBox/ResourcesLabel
@onready var plot_label: Label = $UI/Panel/Margin/VBox/PlotLabel
@onready var actions_label: Label = $UI/Panel/Margin/VBox/ActionsLabel
@onready var log_label: Label = $UI/Panel/Margin/VBox/LogLabel
@onready var hint_label: Label = $UI/Panel/Margin/VBox/HintLabel
@onready var plant_wheat_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/PlantWheatBtn
@onready var plant_barley_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/PlantBarleyBtn
@onready var tend_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/TendBtn
@onready var harvest_btn: Button = $UI/Panel/Margin/VBox/ActionsRow/HarvestBtn
@onready var end_day_btn: Button = $UI/Panel/Margin/VBox/DayRow/EndDayBtn
@onready var skip_week_btn: Button = $UI/Panel/Margin/VBox/DayRow/SkipWeekBtn
@onready var skip_to_work_btn: Button = $UI/Panel/Margin/VBox/DayRow/SkipToWorkBtn

var selected_hex: Vector2i = Vector2i.ZERO


func _ready() -> void:
	TurnManager.turn_started.connect(_on_turn_started)
	TurnManager.action_consumed.connect(_on_action_consumed)
	GameState.season_changed.connect(func(_s, _y): _update_ui())
	GameState.weather_changed.connect(func(_w): _update_ui())
	GameState.resources_changed.connect(_update_ui)
	GameState.plot_changed.connect(func(_c): _update_ui())
	GameState.log_added.connect(func(_m): _update_log())
	GameState.day_batch_finished.connect(func(_d): _update_ui())
	GameState.init_plots_from_map(tile_map)
	selected_hex = GameState.home_hex
	unit.setup(tile_map, selected_hex)
	plant_wheat_btn.pressed.connect(_on_plant_wheat)
	plant_barley_btn.pressed.connect(_on_plant_barley)
	tend_btn.pressed.connect(_on_tend)
	harvest_btn.pressed.connect(_on_harvest)
	end_day_btn.pressed.connect(_on_end_day)
	skip_week_btn.pressed.connect(_on_skip_week)
	skip_to_work_btn.pressed.connect(_on_advance_until_work)
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"advance_until_work"):
		_on_advance_until_work()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"end_turn"):
		_on_end_day()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_try_select_plot_at_mouse()
			get_viewport().set_input_as_handled()


func _try_select_plot_at_mouse() -> void:
	var local_pos := tile_map.to_local(get_global_mouse_position())
	var target := tile_map.local_to_map(local_pos)
	if not GameState.is_farm_plot(target):
		hint_label.text = "Click a farm plot to select it."
		return
	selected_hex = target
	unit.walk_to(target)
	_update_ui()


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


func _on_end_day() -> void:
	TurnManager.end_turn()


func _on_skip_week() -> void:
	TurnManager.skip_days(7)


func _on_advance_until_work() -> void:
	TurnManager.advance_until_actionable()
	_update_ui()


func _on_turn_started(_turn_number: int) -> void:
	_update_ui()


func _on_action_consumed(_actions_remaining: int) -> void:
	_update_ui()


func _default_hint() -> String:
	if TurnManager.has_actions() and GameState.has_actionable_work():
		return "Select a plot, then plant / tend / harvest. Shift+Space skips idle days."
	if TurnManager.has_actions():
		return "Quiet day — Shift+Space to skip ahead, or end the day."
	return "No actions left — end the day (Space) or Shift+Space to skip ahead."


func _update_log() -> void:
	log_label.text = "\n".join(GameState.log_lines)


func _update_ui() -> void:
	season_label.text = GameState.calendar_label(TurnManager.turn_number)
	resources_label.text = "Food %d · Wheat seed %d · Barley seed %d" % [
		GameState.resources["food"],
		GameState.resources["wheat_seed"],
		GameState.resources["barley_seed"],
	]
	plot_label.text = GameState.plot_status(selected_hex)
	actions_label.text = "Labor today: %d / %d" % [
		TurnManager.actions_remaining,
		TurnManager.actions_per_turn,
	]
	hint_label.text = _default_hint()
	_update_log()
	var can_act := TurnManager.has_actions()
	plant_wheat_btn.disabled = not can_act
	plant_barley_btn.disabled = not can_act
	tend_btn.disabled = not can_act
	harvest_btn.disabled = not can_act
