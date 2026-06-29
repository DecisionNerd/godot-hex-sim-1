extends GutTest


func _weather_sequence(seed: int, days: int) -> Array:
	GameState.reset_for_test(seed)
	var seq: Array = []
	for day in range(1, days + 1):
		seq.append(GameState.weather)
		GameState.resolve_day(day)
	return seq


func test_same_seed_same_weather_sequence() -> void:
	var a := _weather_sequence(999, 10)
	var b := _weather_sequence(999, 10)
	assert_eq(a, b)


func test_different_seeds_can_differ() -> void:
	var a := _weather_sequence(1, 20)
	var b := _weather_sequence(2, 20)
	assert_ne(a, b)
