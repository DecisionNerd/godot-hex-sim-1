extends GutTest

const ScenarioCatalog = preload("res://scripts/scenarios/scenario_catalog.gd")


func test_default_scenario_is_homestead_1863() -> void:
	var scenario = ScenarioCatalog.get_default()
	assert_eq(scenario.id, "homestead_1863")
	assert_eq(scenario.start_year, 1863)
	assert_eq(scenario.calendar_year(1), 1863)
	assert_eq(scenario.calendar_year(2), 1864)


func test_scenario_calendar_stays_in_scenario_time_not_full_history() -> void:
	var scenario = ScenarioCatalog.get_default()
	assert_eq(scenario.calendar_year(10), 1872)
	assert_ne(scenario.calendar_year(1), 1540)


func test_game_state_uses_scenario_year() -> void:
	GameState.reset_for_test(42)
	assert_eq(GameState.scenario_calendar_year(), 1863)
