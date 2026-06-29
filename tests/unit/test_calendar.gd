extends GutTest


func before_each() -> void:
	GameState.reset_for_test()


func test_day_in_season_wraps() -> void:
	assert_eq(GameState.day_in_season(1), 1)
	assert_eq(GameState.day_in_season(91), 91)
	assert_eq(GameState.day_in_season(92), 1)


func test_season_changes_on_day_92() -> void:
	GameState._sync_calendar_from_turn(91)
	assert_eq(GameState.season, GameState.Season.SPRING)
	GameState._sync_calendar_from_turn(92)
	assert_eq(GameState.season, GameState.Season.SUMMER)


func test_year_increments_after_full_cycle() -> void:
	GameState._sync_calendar_from_turn(GameState.DAYS_PER_YEAR + 1)
	assert_eq(GameState.year, 2)
	assert_eq(GameState.season, GameState.Season.SPRING)
