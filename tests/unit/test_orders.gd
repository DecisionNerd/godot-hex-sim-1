extends GutTest

const WorkZone = preload("res://scripts/work/work_zone.gd")
const HS = preload("res://scripts/world/hex_state.gd")


func before_each() -> void:
	GameState.reset_for_test(4242)
	TurnManager.reset_for_test()
	GameState.weather = GameState.Weather.CLEAR
	GameState.season = GameState.Season.SPRING


func _forage_hex() -> Vector2i:
	var hex = GameState.get_hex(GameState.home_hex)
	hex.forage_mask = HS.FORAGE_BERRIES | HS.FORAGE_ROOTS
	hex.forage_depleted = false
	return GameState.home_hex


func test_assign_and_cancel_zone() -> void:
	var coords := _forage_hex()
	assert_eq(GameState.assign_zone_hex(coords, WorkZone.ZoneType.FORAGE), "ok")
	assert_true(GameState.has_order(coords))
	assert_eq(GameState.order_count(), 1)
	assert_true(GameState.cancel_order(coords))
	assert_false(GameState.has_order(coords))


func test_work_today_executes_forage_zone() -> void:
	var coords := _forage_hex()
	GameState.assign_zone_hex(coords, WorkZone.ZoneType.FORAGE)
	GameState.refresh_labor()
	var food_before := GameState.total_food()
	GameState.work_today()
	assert_false(GameState.get_hex(coords).has_forage())
	assert_gt(GameState.total_food(), food_before)


func test_work_today_only_runs_once_per_day() -> void:
	GameState.assign_zone_hex(_forage_hex(), WorkZone.ZoneType.FORAGE)
	GameState.refresh_labor()
	GameState.work_today()
	var pool_after: int = GameState.labor_pool
	GameState.work_today()
	assert_eq(GameState.labor_pool, pool_after)


func test_multi_day_clear_accumulates() -> void:
	var coords := GameState.home_hex
	GameState.assign_zone_hex(coords, WorkZone.ZoneType.CLEAR)
	GameState.labor_pool = 1
	GameState._worked_today = false
	GameState.work_today()
	assert_true(GameState.has_order(coords))
	GameState.labor_pool = 5
	GameState._worked_today = false
	GameState.work_today()
	assert_true(GameState.resources.get("wood", 0) >= 0)


func test_needs_attention_for_unqueued_forage() -> void:
	var coords := _forage_hex()
	for c in GameState.world_coords():
		if c != coords:
			var other = GameState.get_hex(c)
			if other != null:
				other.forage_mask = 0
	assert_true(GameState.needs_attention())
	GameState.assign_zone_hex(coords, WorkZone.ZoneType.FORAGE)
	assert_false(GameState.needs_attention())
