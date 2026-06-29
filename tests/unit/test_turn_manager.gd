extends GutTest

const HOME := Vector2i(0, 0)


func before_each() -> void:
	GameState.reset_for_test(42)
	TurnManager.reset_for_test()
	GameState.season = GameState.Season.SPRING


func test_labor_pool_sums_household() -> void:
	GameState.refresh_labor()
	var expected: int = GameState.LABOR_HEAD + GameState.SPOUSE_LABOR + GameState.CHILD_LABOR
	assert_eq(GameState.labor_per_day, expected)
	assert_eq(GameState.labor_pool, GameState.labor_per_day)


func test_advance_days_increments_turn_and_refreshes_labor() -> void:
	GameState.labor_pool = 0
	TurnManager.advance_days(3)
	assert_eq(TurnManager.turn_number, 4)
	assert_eq(GameState.labor_pool, GameState.labor_per_day)


func test_advance_until_stops_when_work_exists() -> void:
	var field_id := GameState.create_field()
	GameState.add_hex_to_field(field_id, GameState.home_hex)
	GameState.plant_field(field_id, "corn")
	GameState.fields[field_id].growth_days = 28
	TurnManager.advance_until_actionable()
	assert_eq(TurnManager.turn_number, 1)


func test_advance_until_skips_idle_days() -> void:
	var field_id := GameState.create_field()
	GameState.add_hex_to_field(field_id, GameState.home_hex)
	GameState.plant_field(field_id, "corn")
	GameState.fields[field_id].growth_days = 5
	GameState.weather = GameState.Weather.CLEAR
	GameState.resources["corn_seed"] = 0
	GameState.resources["bean_seed"] = 0
	for coords in GameState.world_coords():
		var hex = GameState.get_hex(coords)
		if hex != null:
			hex.forage_mask = 0
	assert_false(GameState.has_actionable_work())
	TurnManager.advance_until_actionable()
	assert_gt(TurnManager.turn_number, 1)
