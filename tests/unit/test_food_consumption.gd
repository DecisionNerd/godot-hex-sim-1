extends GutTest


func before_each() -> void:
	GameState.reset_for_test()
	TurnManager.reset_for_test()


func test_seven_days_consumes_food_for_family() -> void:
	var start_food: int = GameState.total_food()
	var mouths := GameState.living_count()
	for day in range(1, 8):
		GameState.resolve_day(day)
	assert_eq(GameState.total_food(), maxi(start_food - mouths * 7, 0))


func test_daily_rate_uses_accumulator() -> void:
	GameState.resources["food"] = 100
	GameState.food_consumption_accumulator = 0.0
	var mouths := GameState.living_count()
	GameState._consume_household_daily()
	assert_eq(GameState.resources["food"], 100 - mouths)
	assert_almost_eq(GameState.food_consumption_accumulator, 0.0, 0.001)
