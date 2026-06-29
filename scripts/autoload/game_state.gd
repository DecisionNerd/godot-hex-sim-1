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
const FarmBuilding = preload("res://scripts/world/farm_building.gd")
const TerrainClassifier = preload("res://scripts/world/terrain_classifier.gd")
const MapGenerator = preload("res://scripts/world/map_generator.gd")
const HexGrid = preload("res://scripts/world/hex_grid.gd")

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
const CLEAR_WOOD_FOOD_COST := 3

## Labour model: a hex is ~10 m², so a worker covers several per day.
## The head of household contributes this many work-units; family add their own.
const LABOR_HEAD := 10
const SPOUSE_LABOR := 10
const CHILD_LABOR := 5
## Work-unit cost to complete one task on a single ~10 m² hex.
const TASK_COST := {
	"tend": 1,
	"plant": 2,
	"harvest": 2,
	"claim": 6,
	"clear_wood": 12,
}
## Order in which queued orders claim the day's labour.
const ORDER_PRIORITY: Array[String] = ["harvest", "tend", "plant", "claim", "clear_wood"]

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
## Queued work the player has planned: Vector2i -> {type, crop_id, work}.
var orders: Dictionary = {}
## Household labour for the current day.
var labor_per_day: int = LABOR_HEAD
var labor_pool: int = LABOR_HEAD
var log_lines: PackedStringArray = []
var home_hex: Vector2i = Vector2i.ZERO
var hex_sim: HexSim
var buildings: Dictionary = {}
var cleared_woods: Array[Vector2i] = []
var persons: Array = []
var holdings: Array = []
var agents: Array = []
var person_system: PersonSystem = PersonSystem.new()
var player_holding: Holding
var game_active: bool = false
var game_lost: bool = false
var consecutive_hungry_days: int = 0
var last_game_over_reason: String = ""
var _map: TileMapLayer
var _terrain_cells: Dictionary = {}
var _batch_mode: bool = false
var _batch_stats: Dictionary = {}
var _pending_load: Dictionary = {}
var _worked_today: bool = false


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
	orders.clear()
	log_lines.clear()
	buildings.clear()
	cleared_woods.clear()
	_batch_mode = false
	_batch_stats = {}
	_worked_today = false
	home_hex = Vector2i.ZERO
	game_lost = false
	consecutive_hungry_days = 0
	last_game_over_reason = ""
	game_active = true
	_pending_load = {}
	_terrain_cells = {}
	rng.seed = seed
	if crops.is_empty():
		_register_crops()
	TurnManager.reset_for_test()
	_roll_weather()


func has_save() -> bool:
	return SaveManager.exists()


func can_continue() -> bool:
	if not SaveManager.exists():
		return false
	var data := SaveManager.read()
	if data.is_empty():
		return false
	return not bool(data.get("game_lost", false))


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
		"buildings": _serialize_buildings(),
		"cleared_woods": _serialize_coords_list(cleared_woods),
		"hungry_days": consecutive_hungry_days,
		"game_lost": game_lost,
		"game_over_reason": last_game_over_reason,
		"labor_pool": labor_pool,
		"labor_per_day": labor_per_day,
		"orders": _serialize_orders(),
		"log": Array(log_lines),
	})


func _serialize_orders() -> Array:
	var out: Array = []
	for coords in orders:
		var order: Dictionary = orders[coords]
		out.append({
			"x": coords.x,
			"y": coords.y,
			"type": order.get("type", ""),
			"crop_id": order.get("crop_id", ""),
			"work": int(order.get("work", 0)),
		})
	return out


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
	last_game_over_reason = str(data.get("game_over_reason", ""))
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
	orders.clear()
	for entry in data.get("orders", []):
		var ocoords := Vector2i(int(entry["x"]), int(entry["y"]))
		orders[ocoords] = {
			"type": str(entry.get("type", "")),
			"crop_id": str(entry.get("crop_id", "")),
			"work": int(entry.get("work", 0)),
		}
	labor_per_day = int(data.get("labor_per_day", household_labor()))
	labor_pool = int(data.get("labor_pool", labor_per_day))
	_load_buildings_from_save(data.get("buildings", []))
	cleared_woods.clear()
	for entry in data.get("cleared_woods", []):
		cleared_woods.append(Vector2i(int(entry["x"]), int(entry["y"])))
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
	MapGenerator.prepare_tile_map(tile_map)
	if not _pending_load.is_empty():
		rng.seed = int(_pending_load.get("seed", rng.seed))
	if not _pending_load.is_empty() or SceneRouter.entering_new_game or _terrain_cells.is_empty():
		_generate_world_map()
	var needs_fresh_plots := plots.is_empty() or SceneRouter.entering_new_game
	if not _pending_load.is_empty():
		apply_loaded_state()
		_rebuild_world_from_map(tile_map)
		_sync_hex_from_plots()
		game_started.emit()
		return
	if game_lost and not SceneRouter.entering_new_game:
		start_new_game()
		_generate_world_map()
		needs_fresh_plots = true
	if needs_fresh_plots:
		plots.clear()
		home_hex = MapGenerator.pick_home_hex(_terrain_cells)
		plots[home_hex] = PlotState.new()
		var neighbors: Array[Vector2i] = HexGrid.neighbors(home_hex)
		var added := 1
		for coords in neighbors:
			if added >= 8:
				break
			if not _terrain_cells.has(coords):
				continue
			if _terrain_cells[coords] == HexState.TERRAIN_WATER:
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


func _generate_world_map() -> void:
	_terrain_cells = MapGenerator.generate_terrain(rng)


func world_coords() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for coords in _terrain_cells:
		out.append(coords)
	return out


func map_to_world(coords: Vector2i) -> Vector2:
	if _map != null and _map.tile_set != null:
		return _map.map_to_local(coords)
	return HexGrid.map_to_local(coords)


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
	spouse.daily_labor = SPOUSE_LABOR
	spouse.rules = [{"action": "tend", "probability": 0.6}, {"action": "idle", "probability": 0.4}]
	persons.append(spouse)

	var child := Person.new()
	child.id = "child"
	child.display_name = "Child"
	child.hex_coords = home_hex
	child.daily_labor = CHILD_LABOR
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
	refresh_labor()


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
	hex_sim.build_from_terrain(_terrain_cells, plot_list)
	_apply_cleared_woods()
	_place_starting_buildings()
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
	var home: HexState = hex_sim.get_hex(home_hex)
	if home != null:
		home.population = 1 + persons.size()
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
	orders.clear()
	log_lines.clear()
	buildings.clear()
	cleared_woods.clear()
	_batch_mode = false
	_batch_stats = {}
	_worked_today = false
	home_hex = Vector2i(0, 0)
	plots[home_hex] = PlotState.new()
	game_lost = false
	consecutive_hungry_days = 0
	last_game_over_reason = ""
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


func get_building(coords: Vector2i) -> FarmBuilding:
	return buildings.get(coords)


func hex_terrain(coords: Vector2i) -> int:
	if _terrain_cells.has(coords):
		return _terrain_cells[coords]
	if hex_sim == null:
		return HexState.TERRAIN_GRASS
	var hex: HexState = hex_sim.get_hex(coords)
	if hex == null:
		return HexState.TERRAIN_GRASS
	return hex.terrain


func is_adjacent_to_holding(coords: Vector2i) -> bool:
	if _map == null:
		return false
	for owned in plots:
		if coords in HexGrid.neighbors(owned):
			return true
	return false


func can_claim_plot(coords: Vector2i) -> bool:
	if plots.has(coords):
		return false
	if not _terrain_cells.has(coords):
		return false
	if _terrain_cells[coords] == HexState.TERRAIN_WATER:
		return false
	if hex_sim == null or hex_sim.get_hex(coords) == null:
		return false
	if not is_adjacent_to_holding(coords):
		return false
	var terrain := hex_terrain(coords)
	return terrain == HexState.TERRAIN_GRASS


func can_clear_wood(coords: Vector2i) -> bool:
	if plots.has(coords):
		return false
	if hex_terrain(coords) != HexState.TERRAIN_WOOD:
		return false
	return is_adjacent_to_holding(coords)


func try_clear_wood(coords: Vector2i) -> String:
	return _spend_labor("clear_wood", _do_clear_wood(coords))


func _do_clear_wood(coords: Vector2i) -> String:
	if game_lost:
		return "Game over."
	if not can_clear_wood(coords):
		return "Select woodland next to your holding."
	if resources.get("food", 0) < CLEAR_WOOD_FOOD_COST:
		return "Need %d food to clear woodland." % CLEAR_WOOD_FOOD_COST
	resources["food"] -= CLEAR_WOOD_FOOD_COST
	var hex: HexState = hex_sim.get_hex(coords)
	if hex != null:
		hex.terrain = HexState.TERRAIN_GRASS
		hex.forest = 0.0
		cleared_woods.append(coords)
		hex_sim.mark_dirty(coords)
		hex_sim.flush_aggregates()
	resources_changed.emit()
	_log("Cleared woodland (%d food)." % CLEAR_WOOD_FOOD_COST)
	return "ok"


func try_claim_plot(coords: Vector2i) -> String:
	return _spend_labor("claim", _do_claim(coords))


func _do_claim(coords: Vector2i) -> String:
	if game_lost:
		return "Game over."
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
		hex.forest = 0.0
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


# --- Labour pool ---------------------------------------------------------

func household_labor() -> int:
	var total := LABOR_HEAD
	for person in persons:
		total += int(person.daily_labor)
	return total


func refresh_labor() -> void:
	labor_per_day = household_labor()
	labor_pool = labor_per_day
	_worked_today = false


func task_cost(type: String) -> int:
	return int(TASK_COST.get(type, 1))


# --- Order queue ---------------------------------------------------------

func order_for(coords: Vector2i) -> Dictionary:
	return orders.get(coords, {})


func has_order(coords: Vector2i) -> bool:
	return orders.has(coords)


func order_count() -> int:
	return orders.size()


func can_order(coords: Vector2i, type: String, _crop_id: String = "") -> bool:
	match type:
		"tend", "harvest", "plant":
			return is_farm_plot(coords)
		"claim":
			return can_claim_plot(coords)
		"clear_wood":
			return can_clear_wood(coords)
	return false


func assign_order(coords: Vector2i, type: String, crop_id: String = "") -> String:
	if game_lost:
		return "Game over."
	if not can_order(coords, type, crop_id):
		return "Can't plan that here."
	orders[coords] = {"type": type, "crop_id": crop_id, "work": 0}
	plot_changed.emit(coords)
	return "ok"


func cancel_order(coords: Vector2i) -> bool:
	if orders.erase(coords):
		plot_changed.emit(coords)
		return true
	return false


func order_label(coords: Vector2i) -> String:
	var order := order_for(coords)
	if order.is_empty():
		return ""
	match String(order.get("type", "")):
		"plant":
			return "plant %s" % String(order.get("crop_id", ""))
		"clear_wood":
			return "clear wood"
		var other:
			return other


## Spend today's labour pool on queued orders, highest priority first.
func work_today() -> void:
	if _worked_today:
		return
	_worked_today = true
	_work_orders()


func _work_orders() -> void:
	if game_lost:
		return
	for type in ORDER_PRIORITY:
		for coords in _orders_of_type(type):
			if labor_pool <= 0:
				return
			_advance_order(coords)


func _orders_of_type(type: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for coords in orders:
		if String(orders[coords].get("type", "")) == type:
			out.append(coords)
	return out


func _advance_order(coords: Vector2i) -> void:
	var order: Dictionary = orders[coords]
	var block := _order_block_reason(coords, order)
	if block == "invalid":
		orders.erase(coords)
		plot_changed.emit(coords)
		return
	if block == "wait":
		return
	var type := String(order.get("type", ""))
	var cost := task_cost(type)
	var need: int = cost - int(order.get("work", 0))
	if need <= 0:
		need = cost
	var spend: int = mini(labor_pool, need)
	order["work"] = int(order.get("work", 0)) + spend
	labor_pool -= spend
	orders[coords] = order
	if int(order["work"]) >= cost:
		_apply_order_effect(coords, order)
		orders.erase(coords)
		plot_changed.emit(coords)


## "" = ready to work, "wait" = blocked by transient conditions, "invalid" = drop it.
func _order_block_reason(coords: Vector2i, order: Dictionary) -> String:
	match String(order.get("type", "")):
		"tend":
			var plot := get_plot(coords)
			if plot == null or plot.is_empty():
				return "invalid"
			return ""
		"harvest":
			var plot := get_plot(coords)
			if plot == null or plot.is_empty():
				return "invalid"
			var crop := get_crop(plot.crop_id)
			if crop == null:
				return "invalid"
			return "" if plot.is_mature(crop) else "wait"
		"plant":
			var plot := get_plot(coords)
			if plot == null:
				return "invalid"
			if not plot.is_empty():
				return "invalid"
			var crop := get_crop(String(order.get("crop_id", "")))
			if crop == null:
				return "invalid"
			if season not in crop.plant_seasons:
				return "wait"
			if weather == Weather.FROST and not crop.frost_tolerant:
				return "wait"
			if resources.get(crop.seed_resource, 0) < 1:
				return "wait"
			return ""
		"claim":
			if not can_claim_plot(coords):
				return "invalid"
			return "wait" if resources.get("food", 0) < CLAIM_PLOT_FOOD_COST else ""
		"clear_wood":
			if not can_clear_wood(coords):
				return "invalid"
			return "wait" if resources.get("food", 0) < CLEAR_WOOD_FOOD_COST else ""
	return "invalid"


func _apply_order_effect(coords: Vector2i, order: Dictionary) -> void:
	match String(order.get("type", "")):
		"tend":
			_do_tend(coords)
		"harvest":
			_do_harvest(coords)
		"plant":
			_do_plant(coords, String(order.get("crop_id", "")))
		"claim":
			_do_claim(coords)
		"clear_wood":
			_do_clear_wood(coords)


func has_pending_orders() -> bool:
	return not orders.is_empty()


## True when an unordered plot needs the player's attention (mature or needs tending).
func needs_attention() -> bool:
	for coords in plots:
		if has_order(coords):
			continue
		var plot: PlotState = plots[coords]
		if plot.is_empty():
			continue
		var crop := get_crop(plot.crop_id)
		if crop == null:
			continue
		if plot.is_mature(crop):
			return true
		if _needs_tend(plot, crop):
			return true
	return false


func family_summary() -> String:
	if persons.size() < 2:
		return "Family: —"
	return "Family: %s, %s" % [persons[0].display_name, persons[1].display_name]


func holdings_summary() -> String:
	if player_holding == null:
		return ""
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
	return _spend_labor("plant", _do_plant(coords, crop_id))


func _do_plant(coords: Vector2i, crop_id: String) -> String:
	if game_lost:
		return "Game over."
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
	return _spend_labor("tend", _do_tend(coords))


func _do_tend(coords: Vector2i) -> String:
	if game_lost:
		return "Game over."
	var plot := get_plot(coords)
	if plot == null or plot.is_empty():
		return "Nothing to tend here."
	plot.tended = true
	_mark_plot_changed(coords)
	_log("Tended the %s." % get_crop(plot.crop_id).display_name)
	return "ok"


func try_harvest(coords: Vector2i) -> String:
	return _spend_labor("harvest", _do_harvest(coords))


func _do_harvest(coords: Vector2i) -> String:
	if game_lost:
		return "Game over."
	var plot := get_plot(coords)
	if plot == null or plot.is_empty():
		return "Nothing to harvest."
	var crop: CropDefinition = get_crop(plot.crop_id)
	if crop == null:
		return "Unknown crop on plot."
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


## Charge the labour pool when an immediate action succeeded. `result` is the
## outcome of the matching `_do_*` call; labour is only spent on "ok".
func _spend_labor(type: String, result: String) -> String:
	if result == "ok":
		labor_pool = maxi(0, labor_pool - task_cost(type))
	return result


func _mark_plot_changed(coords: Vector2i) -> void:
	resources_changed.emit()
	plot_changed.emit(coords)
	_sync_hex_from_plots()


func plot_work_type(coords: Vector2i) -> String:
	if not is_farm_plot(coords):
		if can_clear_wood(coords):
			return "clear_wood"
		return "claim" if can_claim_plot(coords) else "none"
	var plot := get_plot(coords)
	if plot == null:
		return "none"
	if plot.is_empty():
		return "plant" if _can_plant_any_crop() else "none"
	var crop: CropDefinition = get_crop(plot.crop_id)
	if plot.is_mature(crop):
		return "harvest"
	if _needs_tend(plot, crop):
		return "tend"
	return "none"


func plot_growth_ratio(coords: Vector2i) -> float:
	var plot := get_plot(coords)
	if plot == null or plot.is_empty():
		return 0.0
	var crop: CropDefinition = get_crop(plot.crop_id)
	if crop == null or crop.grow_days <= 0:
		return 0.0
	return clampf(float(plot.growth_days) / float(crop.grow_days), 0.0, 1.0)


func plot_status(coords: Vector2i) -> String:
	var plot := get_plot(coords)
	if plot == null:
		if can_clear_wood(coords):
			return "Woodland — clear for %d food + 1 labor, then claim." % CLEAR_WOOD_FOOD_COST
		if can_claim_plot(coords):
			return "Wild land — claim for %d food + 1 labor." % CLAIM_PLOT_FOOD_COST
		return "Not a farm plot."
	if plot.is_empty():
		return "Empty plot — plant wheat or barley."
	var crop: CropDefinition = get_crop(plot.crop_id)
	if crop == null:
		return "Unknown crop on plot."
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
	for owned in plots:
		for neighbor in HexGrid.neighbors(owned):
			if can_clear_wood(neighbor) or can_claim_plot(neighbor):
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
	if crop == null:
		return false
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
			last_game_over_reason = "The household starved after %d hungry days." % consecutive_hungry_days
			_log(last_game_over_reason)
			game_over.emit(last_game_over_reason)
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
		if crop == null:
			continue
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


func _place_starting_buildings() -> void:
	if not buildings.is_empty():
		return
	var house := FarmBuilding.new()
	house.id = "farmhouse"
	house.display_name = "Farmhouse"
	house.kind = FarmBuilding.Kind.HOUSE
	house.hex_coords = home_hex
	buildings[home_hex] = house
	for coords in plots:
		if coords == home_hex:
			continue
		var barn := FarmBuilding.new()
		barn.id = "barn"
		barn.display_name = "Barn"
		barn.kind = FarmBuilding.Kind.BARN
		barn.hex_coords = coords
		buildings[coords] = barn
		break


func _apply_cleared_woods() -> void:
	if hex_sim == null:
		return
	for coords in cleared_woods:
		var hex: HexState = hex_sim.get_hex(coords)
		if hex == null:
			continue
		hex.terrain = HexState.TERRAIN_GRASS
		hex.forest = 0.0
		hex_sim.mark_dirty(coords)


func _serialize_buildings() -> Array:
	var out: Array = []
	for coords in buildings:
		var b: FarmBuilding = buildings[coords]
		out.append({
			"x": coords.x,
			"y": coords.y,
			"id": b.id,
			"name": b.display_name,
			"kind": b.kind,
		})
	return out


func _serialize_coords_list(coords_list: Array[Vector2i]) -> Array:
	var out: Array = []
	for coords in coords_list:
		out.append({"x": coords.x, "y": coords.y})
	return out


func _load_buildings_from_save(data: Array) -> void:
	buildings.clear()
	for entry in data:
		var coords := Vector2i(int(entry["x"]), int(entry["y"]))
		var b := FarmBuilding.new()
		b.id = str(entry.get("id", ""))
		b.display_name = str(entry.get("name", ""))
		b.kind = int(entry.get("kind", FarmBuilding.Kind.HOUSE))
		b.hex_coords = coords
		buildings[coords] = b
