extends GutTest

const Trader = preload("res://scripts/systems/trader.gd")
const HexTopology = preload("res://scripts/world/hex_topology.gd")
const HS = preload("res://scripts/world/hex_state.gd")


func test_trader_buy_and_sell() -> void:
	var resources := {"coins": 10, "food": 5}
	assert_true(Trader.try_buy(resources, "food"))
	assert_eq(resources["coins"], 7)
	assert_eq(resources["food"], 6)
	assert_true(Trader.try_sell(resources, "food"))
	assert_eq(resources["coins"], 9)
	assert_eq(resources["food"], 5)


func test_settlement_validation() -> void:
	GameState.reset_for_test(4242)
	var settleable := 0
	for coords in GameState.world_coords():
		if GameState.is_settleable(coords):
			settleable += 1
	assert_gt(settleable, 100, "valley should have many homestead sites")
	var water: Vector2i = Vector2i(99999, 99999)
	for coords in GameState.world_coords():
		var hex = GameState.get_hex(coords)
		if hex.is_water():
			water = coords
			break
	assert_false(GameState.is_settleable(water))
	for coords in GameState.world_coords():
		if GameState.is_settleable(coords):
			assert_true(HexTopology.is_settleable(GameState.get_hex(coords)))
			return
	fail_test("expected at least one settleable hex")
