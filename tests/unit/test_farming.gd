extends GutTest

const HOME := Vector2i(0, 0)


func before_each() -> void:
	GameState.reset_for_test()
	TurnManager.reset_for_test()


func test_plant_wheat_consumes_seed() -> void:
	var seeds_before: int = GameState.resources["wheat_seed"]
	assert_eq(GameState.try_plant(HOME, "wheat"), "ok")
	assert_eq(GameState.resources["wheat_seed"], seeds_before - 1)
	assert_false(GameState.get_plot(HOME).is_empty())


func test_harvest_mature_crop_adds_food() -> void:
	var plot = GameState.get_plot(HOME)
	plot.crop_id = "wheat"
	plot.growth_days = 28
	var food_before: int = GameState.resources["food"]
	assert_eq(GameState.try_harvest(HOME), "ok")
	assert_eq(GameState.resources["food"], food_before + 8)
	assert_true(plot.is_empty())


func test_frost_kills_untended_wheat() -> void:
	var plot = GameState.get_plot(HOME)
	plot.crop_id = "wheat"
	plot.growth_days = 5
	GameState.persons.clear()
	GameState.weather = GameState.Weather.FROST
	GameState.resolve_day(1)
	assert_true(plot.is_empty())


func test_drought_stalls_growth_without_tend() -> void:
	var plot = GameState.get_plot(HOME)
	plot.crop_id = "wheat"
	plot.growth_days = 5
	GameState.persons.clear()
	GameState.weather = GameState.Weather.DROUGHT
	GameState.resolve_day(1)
	assert_eq(plot.growth_days, 5)


func test_drought_growth_with_tend() -> void:
	var plot = GameState.get_plot(HOME)
	plot.crop_id = "wheat"
	plot.growth_days = 5
	plot.tended = true
	GameState.weather = GameState.Weather.DROUGHT
	GameState.resolve_day(1)
	assert_eq(plot.growth_days, 6)


func test_has_actionable_work_when_harvest_ready() -> void:
	var plot = GameState.get_plot(HOME)
	plot.crop_id = "wheat"
	plot.growth_days = 28
	assert_true(GameState.has_actionable_work())
