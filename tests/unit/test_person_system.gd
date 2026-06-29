extends GutTest

const Person = preload("res://scripts/entities/person.gd")
const PersonSystem = preload("res://scripts/systems/person_system.gd")


func before_each() -> void:
	GameState.reset_for_test(99)
	TurnManager.reset_for_test()
	GameState.season = GameState.Season.SPRING


func test_person_tends_on_drought() -> void:
	var field_id := GameState.create_field()
	GameState.add_hex_to_field(field_id, GameState.home_hex)
	GameState.plant_field(field_id, "corn")
	var field = GameState.fields[field_id]
	field.growth_days = 5
	GameState.weather = GameState.Weather.DROUGHT
	var person := Person.new()
	person.id = "test"
	person.display_name = "Helper"
	person.rules = [{"action": "tend", "probability": 1.0}]
	var system := PersonSystem.new()
	system.resolve_day([person], GameState.rng, GameState)
	assert_true(field.tended)


func test_person_skips_when_no_work() -> void:
	var field_id := GameState.create_field()
	GameState.add_hex_to_field(field_id, GameState.home_hex)
	GameState.plant_field(field_id, "corn")
	var field = GameState.fields[field_id]
	field.growth_days = 5
	field.tended = true
	GameState.weather = GameState.Weather.DROUGHT
	var person := Person.new()
	person.id = "test"
	person.display_name = "Helper"
	person.rules = [{"action": "tend", "probability": 1.0}]
	var system := PersonSystem.new()
	system.resolve_day([person], GameState.rng, GameState)
	assert_true(field.tended)
