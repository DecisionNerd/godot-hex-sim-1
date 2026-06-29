extends GutTest

const WorkZone = preload("res://scripts/work/work_zone.gd")
const StructureRes = preload("res://scripts/world/structure.gd")
const ScenarioCatalog = preload("res://scripts/scenarios/scenario_catalog.gd")


func before_each() -> void:
	GameState.reset_for_test(5150)
	TurnManager.reset_for_test()
	GameState.weather = GameState.Weather.CLEAR
	GameState.season = GameState.Season.SPRING


func _neighbor_hex() -> Vector2i:
	for coords in GameState.world_coords():
		if coords == GameState.home_hex:
			continue
		if GameState.is_settleable(coords) and GameState.get_hex(coords).structure_id == "":
			return coords
	return GameState.home_hex


func test_build_zone_places_cabin() -> void:
	var coords := _neighbor_hex()
	assert_eq(GameState.assign_zone_hex(coords, WorkZone.ZoneType.BUILD, "house"), "ok")
	GameState.labor_pool = 20
	GameState._worked_today = false
	GameState.work_today()
	assert_true(GameState.has_cabin())
	assert_true(GameState.structures.has(coords))


func test_trap_bootstraps_then_can_check() -> void:
	var coords := _neighbor_hex()
	assert_eq(GameState.assign_zone_hex(coords, WorkZone.ZoneType.TRAP, "trap"), "ok")
	GameState.labor_pool = 10
	GameState._worked_today = false
	GameState.work_today()
	assert_eq(GameState.get_hex(coords).structure_id, "trap")
	GameState._worked_today = false
	GameState.labor_pool = 10
	GameState.work_today()
	assert_eq(GameState.get_hex(coords).structure_id, "trap")


func test_harvest_tracks_proved_hexes() -> void:
	var field_id := GameState.create_field()
	GameState.add_hex_to_field(field_id, GameState.home_hex)
	GameState.plant_field(field_id, "corn")
	var field = GameState.fields[field_id]
	field.growth_days = 28
	GameState.labor_pool = 10
	GameState._harvest_field(field_id)
	assert_true(GameState.proved_hexes.has(GameState._hex_key(GameState.home_hex)))


func test_prove_up_when_requirements_met() -> void:
	GameState.year = 5
	var cabin := StructureRes.new()
	cabin.kind = StructureRes.Kind.HOUSE
	cabin.coords = GameState.home_hex
	cabin.display_name = "Cabin"
	GameState.structures[GameState.home_hex] = cabin
	for i in range(6):
		GameState.proved_hexes["%d,%d" % [i, 0]] = true
	assert_true(GameState.can_prove_up())
	assert_true(GameState.prove_up())
	assert_true(GameState.game_won)


func test_resolve_day_runs_family_tend() -> void:
	var field_id := GameState.create_field()
	GameState.add_hex_to_field(field_id, GameState.home_hex)
	GameState.plant_field(field_id, "corn")
	var field = GameState.fields[field_id]
	field.growth_days = 5
	GameState.weather = GameState.Weather.DROUGHT
	for person in GameState.persons:
		person.rules = [{"action": "tend", "probability": 1.0}]
	GameState.resolve_day(1)
	assert_true(field.tended)


func test_scenario_has_prove_up_fields() -> void:
	var scenario = ScenarioCatalog.get_default()
	assert_eq(scenario.prove_up_years, 5)
	assert_eq(scenario.required_field_hexes, 6)
	assert_true(scenario.requires_dwelling)
	assert_false(scenario.objective_text.is_empty())
	assert_false(scenario.victory_log.is_empty())


func test_can_continue_false_after_win() -> void:
	GameState.game_won = true
	GameState.save_game()
	assert_false(GameState.can_continue())
