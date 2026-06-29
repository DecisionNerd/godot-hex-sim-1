extends GutTest


func before_each() -> void:
	GameState.reset_for_test()
	TurnManager.reset_for_test()


func test_seven_days_consumes_two_food() -> void:
	var start_food: int = GameState.resources["food"]
	for day in range(1, 8):
		GameState.resolve_day(day)
	assert_eq(GameState.resources["food"], start_food - 2)


func test_daily_rate_uses_accumulator() -> void:
	GameState.resources["food"] = 100
	GameState.food_consumption_accumulator = 0.0
	GameState.resolve_day(1)
	assert_eq(GameState.resources["food"], 100)
	assert_almost_eq(GameState.food_consumption_accumulator, GameState.HOUSEHOLD_FOOD_PER_DAY, 0.001)
