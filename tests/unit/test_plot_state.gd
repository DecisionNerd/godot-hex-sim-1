extends GutTest

const PlotState = preload("res://scripts/farming/plot_state.gd")
const CropDefinition = preload("res://scripts/farming/crop_definition.gd")


func test_empty_plot_is_not_mature() -> void:
	var plot := PlotState.new()
	var crop := CropDefinition.new()
	crop.grow_days = 10
	assert_true(plot.is_empty())
	assert_false(plot.is_mature(crop))


func test_mature_when_growth_reaches_grow_days() -> void:
	var plot := PlotState.new()
	plot.crop_id = "corn"
	plot.growth_days = 10
	var crop := CropDefinition.new()
	crop.grow_days = 10
	assert_true(plot.is_mature(crop))


func test_clear_resets_plot() -> void:
	var plot := PlotState.new()
	plot.crop_id = "corn"
	plot.growth_days = 5
	plot.tended = true
	plot.clear()
	assert_true(plot.is_empty())
	assert_eq(plot.growth_days, 0)
	assert_false(plot.tended)
