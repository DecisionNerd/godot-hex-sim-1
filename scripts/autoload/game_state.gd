extends Node

const PlotState = preload("res://scripts/farming/plot_state.gd")
const CropDefinition = preload("res://scripts/farming/crop_definition.gd")
const HexSim = preload("res://scripts/world/hex_sim.gd")
const HexState = preload("res://scripts/world/hex_state.gd")
const Person = preload("res://scripts/entities/person.gd")
const Holding = preload("res://scripts/entities/holding.gd")
const Agent = preload("res://scripts/entities/agent.gd")
const PersonSystem = preload("res://scripts/systems/person_system.gd")
const SaveManager = preload("res://scripts/autoload/save_manager.gd")

signal season_changed(season: int, year: int)
signal weather_changed(weather: int)
signal resources_changed()
signal plot_changed(coords: Vector2i)
signal log_added(message: String)
signal day_batch_finished(days: int)
signal game_over(reason: String)
signal game_started()

enum Season { SPRING, SUMMER, AUTUMN, WINTER }
enum Weather { CLEAR, RAIN, DROUGHT, FROST }

const DAYS_PER_SEASON := 91
const DAYS_PER_YEAR := DAYS_PER_SEASON * 4
const HOUSEHOLD_FOOD_PER_DAY := 2.0 / 7.0
const HUNGRY_DAYS_TO_LOSE := 7
const CLAIM_PLOT_FOOD_COST := 2

var rng := RandomNumberGenerator.new()
var year: int = 1
var season: Season = Season.SPRING
var weather: Weather = Weather.CLEAR
var food_consumption_accumulator: float = 0.0
var resources: Dictionary = {
	"food": 10,
	"wheat_seed": 6,
	"barley_seed": 6,
}
var plots: Dictionary = {}
var crops: Dictionary = {}
var log_lines: PackedStringArray = []
var home_hex: Vector2i = Vector2i.ZERO
var hex_sim: HexSim
var persons: Array = []
var holdings: Array = []
var agents: Array = []
var person_system: PersonSystem = PersonSystem.new()
var player_holding: Holding
var game_active: bool = false
var game_lost: bool = false
var consecutive_hungry_days: int = 0
var _map: TileMapLayer
var _batch_mode: bool = false
var _batch_stats: Dictionary = {}
var _pending_load: Dictionary = {}


func _ready() -> void:
	_register_crops()
	TurnManager.turn_ended.connect(_on_day_ended)


func start_new_game(seed: int = -1) -> void:
	if seed < 0:
		seed = int(Time.get_ticks_msec())
	year = 1
	season = Season.SPRING
	weather = Weather.CLEAR
	food_consumption_accumulator = 0.0
	resources = {
		"food": 10,
		"wheat_seed": 6,
		"barley_seed": 6,
	}
	plots.clear()
	log_lines.clear()
	_batch_mode = false
	_batch_stats = {}
	home_hex = Vector2i.ZERO
	game_lost = false
	consecutive_hungry_days = 0
	game_active = true
	_pending_load = {}
	rng.seed = seed
	if crops.is_empty():
		_register_crops()
	TurnManager.reset_for_test()
	_roll_weather()


func has_save() -> bool:
	return SaveManager.exists()


func save_game() -> bool:
	if not game_active:
		return false
	var plot_data: Array = []
	for coords in plots:
		var plot: PlotState = plots[coords]
		plot_data.append({
			"x": coords.x,
			"y": coords.y,
			"crop_id": plot.crop_id,
			"growth_days": plot.growth_days,
			"tended": plot.tended,
		})
	return SaveManager.write({
		"version": 1,
		"seed": rng.seed,
		"turn": TurnManager.turn_number,
		"year": year,
		"season": season,
		"weather": weather,
		"food_accum": food_consumption_accumulator,
		"resources": resources.duplicate(),
		"home_x": home_hex.x,
		"home_y": home_hex.y,
		"plots": plot_data,
		"hungry_days": consecutive_hungry_days,
		"game_lost": game_lost,
		"log": Array(log_lines),
	})


func load_game() -> bool:
	var data := SaveManager.read()
	if data.is_empty():
		return false
	_pending_load = data
	game_active = true
	return true


func apply_loaded_state() -> void:
	if _pending_load.is_empty():
		return
	var data := _pending_load
	_pending_load = {}
	rng.seed = int(data.get("seed", 12345))
	TurnManager.reset_for_test(int(data.get("turn", 1)))
	year = int(data.get("year", 1))
	season = data.get("season", Season.SPRING) as Season
	weather = data.get("weather", Weather.CLEAR) as Weather
	food_consumption_accumulator = float(data.get("food_accum", 0.0))
	resources = data.get("resources", resources).duplicate()
	home_hex = Vector2i(int(data.get("home_x", 0)), int(data.get("home_y", 0)))
	consecutive_hungry_days = int(data.get("hungry_days", 0))
	game_lost = bool(data.get("game_lost", false))
	log_lines = PackedStringArray()
	for line in data.get("log", []):
		log_lines.append(str(line))
	plots.clear()
	for entry in data.get("plots", []):
		var coords := Vector2i(int(entry["x"]), int(entry["y"]))
		var plot := PlotState.new()
		plot.crop_id = str(entry.get("crop_id", ""))
		plot.growth_days = int(entry.get("growth_days", 0))
		plot.tended = bool(entry.get("tended", false))
		plots[coords] = plot
	_setup_household()
	game_started.emit()


func begin_day_batch(day_count: int) -> void:
	_batch_mode = day_count > 1
	_batch_stats = {
		"days": day_count,
		"food_consumed": 0,
		"hungry_days": 0,
		"crops_killed": 0,
		"growth_days": 0,
		"drought_stalls": 0,
	}


func end_day_batch() -> void:
	if not _batch_mode:
		return
	var stats: Dictionary = _batch_stats
	_batch_mode = false
	if stats.get("days", 0) <= 0:
		return
	var msg := "Passed %d days: %d food eaten" % [stats["days"], stats["food_consumed"]]
	if stats["hungry_days"] > 0:
		msg += ", %d hungry days" % stats["hungry_days"]
	if stats["crops_killed"] > 0:
		msg += ", %d crop frost losses" % stats["crops_killed"]
	if stats["drought_stalls"] > 0:
		msg += ", %d drought stalls" % stats["drought_stalls"]
	_log(msg)
	day_batch_finished.emit(stats["days"])


func init_plots_from_map(tile_map: TileMapLayer) -> void:
	_map = tile_map
	if not _pending_load.is_empty():
		apply_loaded_state()
		_rebuild_world_from_map(tile_map)
		_sync_hex_from_plots()
		game_started.emit()
		return
	if plots.is_empty():
		plots.clear()
		var used: Array[Vector2i] = []
		for coords in tile_map.get_used_cells():
			used.append(coords)
		if used.is_empty():
			return
		used.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			if a.x == b.x:
				return a.y < b.y
			return a.x < b.x
		)
		home_hex = used[used.size() >> 1]
		plots[home_hex] = PlotState.new()
		var neighbors: Array[Vector2i] = tile_map.get_surrounding_cells(home_hex)
		var added := 1
		for coords in neighbors:
			if added >= 8:
				break
			if tile_map.get_cell_source_id(coords) == -1:
				continue
			if plots.has(coords):
				continue
			plots[coords] = PlotState.new()
			added += 1
	_setup_household()
	_rebuild_world_from_map(tile_map)
	_sync_hex_from_plots()
	_log("Spring day 1. Click a plot, assign labor, end the day. Family will help when they can.")
	if game_active:
		game_started.emit()


func _setup_household() -> void:
	persons.clear()
	holdings.clear()
	agents.clear()

	player_holding = Holding.new()
	player_holding.id = "player_farm"
	player_holding.name = "Your holding"
	player_holding.owner_id = "player"
	player_holding.home_hex = home_hex
	holdings.append(player_holding)

	var spouse := Person.new()
	spouse.id = "spouse"
	spouse.display_name = "Spouse"
	spouse.hex_coords = home_hex
	spouse.rules = [{"action": "tend", "probability": 0.6}, {"action": "idle", "probability": 0.4}]
	persons.append(spouse)

	var child := Person.new()
	child.id = "child"
	child.display_name = "Child"
	child.hex_coords = home_hex
	child.rules = [{"action": "tend", "probability": 0.35}, {"action": "idle", "probability": 0.65}]
	persons.append(child)

	var player_agent := Agent.new()
	player_agent.id = "player"
	player_agent.name = "You"
	player_agent.holding_id = player_holding.id
	player_agent.hex_coords = home_hex
	player_agent.is_player = true
	agents.append(player_agent)

	_setup_neighbor_holding()


func _setup_neighbor_holding() -> void:
	if hex_sim == null:
		return
	var candidate: Vector2i = home_hex + Vector2i(12, 4)
	if hex_sim.get_hex(candidate) == null:
		for coords in hex_sim.hexes:
			if coords.distance_to(home_hex) > 8 and coords.distance_to(home_hex) < 20:
				candidate = coords
				break
	var neighbor := Holding.new()
	neighbor.id = "miller_farm"
	neighbor.name = "Miller holding"
	neighbor.owner_id = "miller"
	neighbor.home_hex = candidate
	holdings.append(neighbor)
	var steward := Agent.new()
	steward.id = "miller_steward"
	steward.name = "Miller steward"
	steward.holding_id = neighbor.id
	steward.hex_coords = candidate
	steward.is_player = false
	agents.append(steward)
	if hex_sim.get_hex(candidate) != null:
		hex_sim.get_hex(candidate).ownership = "miller"
		hex_sim.get_hex(candidate).population = 3


func _rebuild_world_from_map(tile_map: TileMapLayer) -> void:
	hex_sim = HexSim.new()
	var plot_list: Array[Vector2i] = []
	for coords in plots:
		plot_list.append(coords)
	if player_holding != null:
		player_holding.plot_coords = plot_list
	hex_sim.build_from_map(tile_map, plot_list)
	_setup_neighbor_holding()


func _sync_hex_from_plots() -> void:
	if hex_sim == null:
		return
	for coords in plots:
		var hex: HexState = hex_sim.get_hex(coords)
		if hex == null:
			continue
		var plot: PlotState = plots[coords]
		hex.terrain = HexState.TERRAIN_FARMLAND
		hex.food = 0
		if not plot.is_empty():
			var crop: CropDefinition = get_crop(plot.crop_id)
			if crop != null:
				hex.food = crop.yield_food if plot.is_mature(crop) else 0
		hex.population = 1 if coords == home_hex else 0
		hex_sim.mark_dirty(coords)
	hex_sim.get_hex(home_hex).population = 1 + persons.size()
	hex_sim.flush_aggregates()


func _log(message: String) -> void:
	log_lines.append(message)
	if log_lines.size() > 12:
		log_lines.remove_at(0)
	log_added.emit(message)


func player_message(message: String) -> void:
	_log(message)


func reset_for_test(seed: int = 12345) -> void:
	year = 1
	season = Season.SPRING
	weather = Weather.CLEAR
	food_consumption_accumulator = 0.0
	resources = {
		"food": 10,
		"wheat_seed": 6,
		"barley_seed": 6,
	}
	plots.clear()
	log_lines.clear()
	_batch_mode = false
	_batch_stats = {}
	home_hex = Vector2i(0, 0)
	plots[home_hex] = PlotState.new()
	game_lost = false
	consecutive_hungry_days = 0
	rng.seed = seed
	if crops.is_empty():
		_register_crops()
	_sync_calendar_from_turn(1)
	_setup_household()


func resolve_day(ended_day: int) -> void:
	_resolve_day(ended_day)


func _register_crops() -> void:
	var wheat := CropDefinition.new()
	wheat.id = "wheat"
	wheat.display_name = "Wheat"
	wheat.plant_seasons = [Season.SPRING, Season.AUTUMN]
	wheat.grow_days = 28
	wheat.yield_food = 8
	wheat.seed_resource = "wheat_seed"
	wheat.frost_tolerant = false
	crops[wheat.id] = wheat

	var barley := CropDefinition.new()
	barley.id = "barley"
	barley.display_name = "Barley"
	barley.plant_seasons = [Season.SPRING, Season.SUMMER]
	barley.grow_days = 21
	barley.yield_food = 5
	barley.seed_resource = "barley_seed"
	barley.frost_tolerant = true
	crops[barley.id] = barley


func is_farm_plot(coords: Vector2i) -> bool:
	return plots.has(coords)


func can_claim_plot(coords: Vector2i) -> bool:
	if plots.has(coords):
		return false
	if _map != null and _map.get_cell_source_id(coords) == -1:
		return false
	if hex_sim != null and hex_sim.get_hex(coords) == null:
		return false
	for owned in plots:
		var neighbors: Array[Vector2i] = _map.get_surrounding_cells(owned) if _map != null else []
		if _map == null:
			continue
		if coords in neighbors:
			return true
	return false


func try_claim_plot(coords: Vector2i) -> String:
	if game_lost:
		return "Game over."
	if not TurnManager.consume_action():
		return "No labor left today."
	if not can_claim_plot(coords):
		return "Must claim land next to your holding."
	if resources.get("food", 0) < CLAIM_PLOT_FOOD_COST:
		return "Need %d food to clear brush." % CLAIM_PLOT_FOOD_COST
	resources["food"] -= CLAIM_PLOT_FOOD_COST
	plots[coords] = PlotState.new()
	player_holding.plot_coords.append(coords)
	hex_sim.plot_coords[coords] = true
	var hex: HexState = hex_sim.get_hex(coords)
	if hex != null:
		hex.terrain = HexState.TERRAIN_FARMLAND
		hex.ownership = "player"
		hex_sim.mark_dirty(coords)
	hex_sim.flush_aggregates()
	resources_changed.emit()
	plot_changed.emit(coords)
	_log("Cleared new plot (%d food)." % CLAIM_PLOT_FOOD_COST)
	return "ok"


func get_plot(coords: Vector2i) -> PlotState:
	return plots.get(coords)


func get_crop(crop_id: String) -> CropDefinition:
	return crops.get(crop_id)


func family_summary() -> String:
	return "Family: %s, %s" % [persons[0].display_name, persons[1].display_name]


func holdings_summary() -> String:
	var parts: PackedStringArray = []
	for holding in holdings:
		var count := plots.size() if holding.id == player_holding.id else 3
		parts.append("%s (%d plots)" % [holding.name, count])
	return " · ".join(parts)


func season_name() -> String:
	match season:
		Season.SPRING: return "Spring"
		Season.SUMMER: return "Summer"
		Season.AUTUMN: return "Autumn"
		Season.WINTER: return "Winter"
	return "?"


func weather_name() -> String:
	match weather:
		Weather.CLEAR: return "Clear"
		Weather.RAIN: return "Rain"
		Weather.DROUGHT: return "Drought"
		Weather.FROST: return "Frost"
	return "?"


func day_in_season(turn_number: int) -> int:
	return ((turn_number - 1) % DAYS_PER_SEASON) + 1


func calendar_label(turn_number: int) -> String:
	_sync_calendar_from_turn(turn_number)
	return "Year %d · %s · Day %d/%d · %s" % [
		year,
		season_name(),
		day_in_season(turn_number),
		DAYS_PER_SEASON,
		weather_name(),
	]


func render_level_name(zoom: float) -> String:
	if zoom < 0.07:
		return "Zone view"
	if zoom < 0.2:
		return "Block view"
	if zoom < 0.55:
		return "Patch view"
	return "Hex view"


func _sync_calendar_from_turn(turn_number: int) -> void:
	var idx := maxi(turn_number - 1, 0)
	var new_season := (idx / DAYS_PER_SEASON) % 4 as Season
	var new_year := 1 + idx / DAYS_PER_YEAR
	if new_season != season or new_year != year:
		season = new_season
		year = new_year
		season_changed.emit(season, year)


func try_plant(coords: Vector2i, crop_id: String) -> String:
	if game_lost:
		return "Game over."
	if not TurnManager.consume_action():
		return "No labor left today."
	var plot := get_plot(coords)
	if plot == null:
		return "Not a farm plot."
	if not plot.is_empty():
		return "Plot already has a crop."
	var crop: CropDefinition = get_crop(crop_id)
	if crop == null:
		return "Unknown crop."
	if season not in crop.plant_seasons:
		return "%s cannot be planted in %s." % [crop.display_name, season_name()]
	if weather == Weather.FROST and not crop.frost_tolerant:
		return "Too cold to plant."
	var seed_key: String = crop.seed_resource
	if resources.get(seed_key, 0) < 1:
		return "Not enough seed."
	resources[seed_key] -= 1
	plot.crop_id = crop_id
	plot.growth_days = 0
	plot.tended = false
	_mark_plot_changed(coords)
	_log("Planted %s." % crop.display_name)
	return "ok"


func try_tend(coords: Vector2i) -> String:
	if game_lost:
		return "Game over."
	if not TurnManager.consume_action():
		return "No labor left today."
	var plot := get_plot(coords)
	if plot == null or plot.is_empty():
		return "Nothing to tend here."
	plot.tended = true
	_mark_plot_changed(coords)
	_log("Tended the %s." % get_crop(plot.crop_id).display_name)
	return "ok"


func try_harvest(coords: Vector2i) -> String:
	if game_lost:
		return "Game over."
	if not TurnManager.consume_action():
		return "No labor left today."
	var plot := get_plot(coords)
	if plot == null or plot.is_empty():
		return "Nothing to harvest."
	var crop: CropDefinition = get_crop(plot.crop_id)
	if not plot.is_mature(crop):
		return "%s is not ready (%d/%d days)." % [
			crop.display_name, plot.growth_days, crop.grow_days
		]
	resources["food"] += crop.yield_food
	var name := crop.display_name
	plot.clear()
	_mark_plot_changed(coords)
	_log("Harvested %s (+ %d food)." % [name, crop.yield_food])
	return "ok"


func _mark_plot_changed(coords: Vector2i) -> void:
	resources_changed.emit()
	plot_changed.emit(coords)
	_sync_hex_from_plots()


func plot_status(coords: Vector2i) -> String:
	var plot := get_plot(coords)
	if plot == null:
		if can_claim_plot(coords):
			return "Wild land — claim for %d food + 1 labor." % CLAIM_PLOT_FOOD_COST
		return "Not a farm plot."
	if plot.is_empty():
		return "Empty plot — plant wheat or barley."
	var crop: CropDefinition = get_crop(plot.crop_id)
	if plot.is_mature(crop):
		return "%s — ready to harvest" % crop.display_name
	return "%s — growing (%d/%d days)%s" % [
		crop.display_name,
		plot.growth_days,
		crop.grow_days,
		" (tended)" if plot.tended else "",
	]


func has_actionable_work() -> bool:
	for coords in plots:
		if _plot_has_work(plots[coords]):
			return true
	return false


func _plot_has_work(plot: PlotState) -> bool:
	if plot.is_empty():
		return _can_plant_any_crop()
	var crop: CropDefinition = get_crop(plot.crop_id)
	if plot.is_mature(crop):
		return true
	return _needs_tend(plot, crop)


func _can_plant_any_crop() -> bool:
	for crop_id in crops:
		if _can_plant_crop(crop_id):
			return true
	return false


func _can_plant_crop(crop_id: String) -> bool:
	var crop: CropDefinition = get_crop(crop_id)
	if crop == null:
		return false
	if season not in crop.plant_seasons:
		return false
	if weather == Weather.FROST and not crop.frost_tolerant:
		return false
	return resources.get(crop.seed_resource, 0) >= 1


func _needs_tend(plot: PlotState, crop: CropDefinition) -> bool:
	if plot.tended or plot.is_mature(crop):
		return false
	if weather == Weather.DROUGHT:
		return true
	if weather == Weather.FROST and not crop.frost_tolerant:
		return true
	return false


func _on_day_ended(ended_day: int) -> void:
	if game_lost:
		return
	_resolve_day(ended_day)


func _resolve_day(ended_day: int) -> void:
	_sync_calendar_from_turn(ended_day)
	person_system.resolve_day(persons, rng, self)
	_advance_crops()
	_consume_household_food_daily()
	_check_hunger_lose()
	var next_day := ended_day + 1
	var prev_season := season
	var prev_year := year
	_sync_calendar_from_turn(next_day)
	if season != prev_season or year != prev_year:
		if not _batch_mode:
			_log("%s of year %d begins." % [season_name(), year])
	_roll_weather()
	for coords in plots:
		plots[coords].tended = false
	_sync_hex_from_plots()


func _check_hunger_lose() -> void:
	if resources["food"] < 0:
		consecutive_hungry_days += 1
		if not _batch_mode and consecutive_hungry_days == 1:
			_log("The household goes hungry today.")
		if consecutive_hungry_days >= HUNGRY_DAYS_TO_LOSE:
			game_lost = true
			var reason := "The household starved after %d hungry days." % consecutive_hungry_days
			_log(reason)
			game_over.emit(reason)
	else:
		consecutive_hungry_days = 0


func _consume_household_food_daily() -> void:
	food_consumption_accumulator += HOUSEHOLD_FOOD_PER_DAY
	var consumed := 0
	while food_consumption_accumulator >= 1.0 - 0.001:
		resources["food"] -= 1
		food_consumption_accumulator -= 1.0
		consumed += 1
	if _batch_mode:
		_batch_stats["food_consumed"] += consumed
		if resources["food"] < 0:
			_batch_stats["hungry_days"] += 1
	resources_changed.emit()


func _advance_crops() -> void:
	for coords in plots:
		var plot: PlotState = plots[coords]
		if plot.is_empty():
			continue
		var crop: CropDefinition = get_crop(plot.crop_id)
		if plot.is_mature(crop):
			continue
		if weather == Weather.FROST and not crop.frost_tolerant:
			if plot.tended:
				if not _batch_mode:
					_log("Frost hit %s but tending helped." % crop.display_name)
			else:
				plot.clear()
				if _batch_mode:
					_batch_stats["crops_killed"] += 1
				else:
					_log("Frost killed the %s." % crop.display_name)
				plot_changed.emit(coords)
			continue
		if weather == Weather.DROUGHT and not plot.tended:
			if _batch_mode:
				_batch_stats["drought_stalls"] += 1
			elif not _batch_mode:
				_log("Drought stalled the %s — tend it." % crop.display_name)
			plot_changed.emit(coords)
			continue
		plot.growth_days += 1
		if _batch_mode:
			_batch_stats["growth_days"] += 1
		elif weather == Weather.RAIN:
			_log("Rain helped the %s grow." % crop.display_name)
		plot_changed.emit(coords)


func _roll_weather() -> void:
	var roll := rng.randf()
	match season:
		Season.SPRING:
			if roll < 0.35:
				weather = Weather.RAIN
			elif roll < 0.75:
				weather = Weather.CLEAR
			elif roll < 0.9:
				weather = Weather.DROUGHT
			else:
				weather = Weather.FROST
		Season.SUMMER:
			if roll < 0.25:
				weather = Weather.RAIN
			elif roll < 0.55:
				weather = Weather.CLEAR
			else:
				weather = Weather.DROUGHT
		Season.AUTUMN:
			if roll < 0.3:
				weather = Weather.RAIN
			elif roll < 0.7:
				weather = Weather.CLEAR
			elif roll < 0.85:
				weather = Weather.DROUGHT
			else:
				weather = Weather.FROST
		Season.WINTER:
			if roll < 0.2:
				weather = Weather.CLEAR
			elif roll < 0.45:
				weather = Weather.RAIN
			else:
				weather = Weather.FROST
	weather_changed.emit(weather)
