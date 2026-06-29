extends GutTest

const Person = preload("res://scripts/entities/person.gd")
const PersonSystem = preload("res://scripts/systems/person_system.gd")

const HOME := Vector2i(0, 0)


func before_each() -> void:
	GameState.reset_for_test(99)
	TurnManager.reset_for_test()


func test_person_tends_on_drought() -> void:
	var plot = GameState.get_plot(HOME)
	plot.crop_id = "wheat"
	plot.growth_days = 5
	GameState.weather = GameState.Weather.DROUGHT
	var person := Person.new()
	person.id = "test"
	person.display_name = "Helper"
	person.rules = [{"action": "tend", "probability": 1.0}]
	var system := PersonSystem.new()
	system.resolve_day([person], GameState.rng, GameState)
	assert_true(plot.tended)


func test_person_skips_when_no_work() -> void:
	var plot = GameState.get_plot(HOME)
	plot.crop_id = "wheat"
	plot.growth_days = 5
	plot.tended = true
	GameState.weather = GameState.Weather.DROUGHT
	var person := Person.new()
	person.id = "test"
	person.display_name = "Helper"
	person.rules = [{"action": "tend", "probability": 1.0}]
	var system := PersonSystem.new()
	system.resolve_day([person], GameState.rng, GameState)
	assert_true(plot.tended)
