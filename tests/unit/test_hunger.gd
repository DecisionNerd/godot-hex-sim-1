extends GutTest

const HOME := Vector2i(0, 0)


func before_each() -> void:
	GameState.reset_for_test(7)
	TurnManager.reset_for_test()


func test_seven_hungry_days_triggers_game_over() -> void:
	GameState.resources["food"] = -1
	GameState.consecutive_hungry_days = 6
	GameState.resolve_day(1)
	assert_true(GameState.game_lost)
