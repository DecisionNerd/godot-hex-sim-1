extends GutTest


func before_each() -> void:
	GameState.reset_for_test()
	TurnManager.reset_for_test()
	GameState.weather = GameState.Weather.CLEAR
	GameState.season = GameState.Season.SPRING


func test_plant_field_consumes_seed() -> void:
	var field_id := GameState.create_field()
	GameState.add_hex_to_field(field_id, GameState.home_hex)
	var seeds_before: int = GameState.resources["corn_seed"]
	assert_eq(GameState.plant_field(field_id, "corn"), "ok")
	assert_eq(GameState.resources["corn_seed"], seeds_before - 1)
	assert_false(GameState.fields[field_id].is_empty())


func test_harvest_mature_field_adds_food() -> void:
	var field_id := GameState.create_field()
	GameState.add_hex_to_field(field_id, GameState.home_hex)
	GameState.plant_field(field_id, "corn")
	var field = GameState.fields[field_id]
	field.growth_days = 28
	var food_before: int = GameState.resources["food"]
	GameState.labor_pool = 10
	GameState._work_fields()
	assert_gt(GameState.resources["food"], food_before)
	assert_true(field.is_empty())


func test_frost_kills_untended_field() -> void:
	var field_id := GameState.create_field()
	GameState.add_hex_to_field(field_id, GameState.home_hex)
	GameState.plant_field(field_id, "corn")
	var field = GameState.fields[field_id]
	field.growth_days = 5
	GameState.weather = GameState.Weather.FROST
	GameState.resolve_day(1)
	assert_true(field.is_empty())


func test_has_actionable_work_when_field_mature() -> void:
	var field_id := GameState.create_field()
	GameState.add_hex_to_field(field_id, GameState.home_hex)
	GameState.plant_field(field_id, "corn")
	GameState.fields[field_id].growth_days = 28
	assert_true(GameState.needs_attention())
