extends GutTest


func before_each() -> void:
	GameState.reset_for_test(4242)
	TurnManager.reset_for_test()


func test_winter_exposure_damages_family() -> void:
	GameState.season = GameState.Season.WINTER
	GameState.resources["food"] = 50
	GameState.resources["water"] = 50
	GameState.resources["firewood"] = 0
	GameState.structures.clear()
	var health_before: int = GameState.persons[0].health
	GameState._check_family_vitality()
	assert_lt(GameState.persons[0].health, health_before)


func test_family_death_triggers_game_over() -> void:
	GameState.season = GameState.Season.WINTER
	GameState.resources["food"] = 0
	GameState.resources["water"] = 0
	GameState.resources["berries"] = 0
	GameState.resources["roots"] = 0
	GameState.resources["mushrooms"] = 0
	GameState.resources["meat"] = 0
	GameState.structures.clear()
	for person in GameState.persons:
		person.health = 5
	GameState._check_family_vitality()
	assert_true(GameState.game_lost)
