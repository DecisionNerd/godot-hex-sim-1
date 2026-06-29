extends GutTest

const HOME := Vector2i(0, 0)


func before_each() -> void:
	GameState.reset_for_test(7)
	TurnManager.reset_for_test()
	GameState.weather = GameState.Weather.CLEAR


func test_assign_and_cancel_order() -> void:
	assert_eq(GameState.assign_order(HOME, "plant", "wheat"), "ok")
	assert_true(GameState.has_order(HOME))
	assert_eq(GameState.order_count(), 1)
	assert_true(GameState.cancel_order(HOME))
	assert_false(GameState.has_order(HOME))


func test_work_today_executes_planting_order() -> void:
	var seeds_before: int = GameState.resources["wheat_seed"]
	GameState.assign_order(HOME, "plant", "wheat")
	GameState.refresh_labor()
	GameState.work_today()
	assert_false(GameState.has_order(HOME), "completed order should clear")
	assert_false(GameState.get_plot(HOME).is_empty(), "plot should be planted")
	assert_eq(GameState.resources["wheat_seed"], seeds_before - 1)
	assert_eq(GameState.labor_pool, GameState.labor_per_day - GameState.task_cost("plant"))


func test_work_today_only_runs_once_per_day() -> void:
	GameState.assign_order(HOME, "plant", "wheat")
	GameState.refresh_labor()
	GameState.work_today()
	var pool_after: int = GameState.labor_pool
	GameState.work_today()
	assert_eq(GameState.labor_pool, pool_after, "second work_today same day should be a no-op")


func test_harvest_order_waits_until_mature() -> void:
	var plot = GameState.get_plot(HOME)
	plot.crop_id = "wheat"
	plot.growth_days = 5
	GameState.assign_order(HOME, "harvest")
	GameState.refresh_labor()
	GameState.work_today()
	assert_true(GameState.has_order(HOME), "harvest should wait while crop is immature")
	assert_eq(GameState.labor_pool, GameState.labor_per_day, "waiting order spends no labour")
	plot.growth_days = 28
	GameState.refresh_labor()
	GameState.work_today()
	assert_false(GameState.has_order(HOME), "mature crop should be harvested")
	assert_true(plot.is_empty())


func test_multi_day_work_accumulates() -> void:
	var plot = GameState.get_plot(HOME)
	plot.crop_id = "wheat"
	plot.growth_days = 28
	GameState.assign_order(HOME, "harvest")
	GameState.labor_pool = 1
	GameState._worked_today = false
	GameState.work_today()
	assert_true(GameState.has_order(HOME), "harvest costs 2, only 1 worked so far")
	assert_eq(int(GameState.orders[HOME]["work"]), 1)
	GameState.labor_pool = 5
	GameState._worked_today = false
	GameState.work_today()
	assert_false(GameState.has_order(HOME), "second day's labour finishes the job")
	assert_true(plot.is_empty())


func test_labor_priority_harvest_before_plant() -> void:
	var home_plot = GameState.get_plot(HOME)
	home_plot.crop_id = "wheat"
	home_plot.growth_days = 28
	var empty_coords := Vector2i(99, 99)
	GameState.plots[empty_coords] = preload("res://scripts/farming/plot_state.gd").new()
	GameState.assign_order(empty_coords, "plant", "wheat")
	GameState.assign_order(HOME, "harvest")
	GameState.labor_pool = 2
	GameState._worked_today = false
	GameState.work_today()
	assert_true(home_plot.is_empty(), "harvest should run first and consume the labour")
	assert_true(GameState.has_order(empty_coords), "planting waits for the next day's labour")


func test_needs_attention_ignores_ordered_plots() -> void:
	var plot = GameState.get_plot(HOME)
	plot.crop_id = "wheat"
	plot.growth_days = 28
	assert_true(GameState.needs_attention(), "mature unordered crop needs attention")
	GameState.assign_order(HOME, "harvest")
	assert_false(GameState.needs_attention(), "an ordered plot no longer demands attention")
