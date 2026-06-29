extends GutTest

const WestTheme = preload("res://scripts/theme/west_theme.gd")


func test_resource_display_names() -> void:
	assert_eq(WestTheme.resource_name("food"), "Provisions")
	assert_eq(WestTheme.resource_name("coins"), "Dollars")
	assert_eq(WestTheme.resource_name("corn_seed"), "Corn seed")


func test_crop_id_migration_aliases() -> void:
	assert_eq(WestTheme.normalize_crop_id("wheat"), "corn")
	assert_eq(WestTheme.normalize_crop_id("barley"), "beans")
	assert_eq(WestTheme.normalize_crop_id("corn"), "corn")


func test_era_name_tracks_history() -> void:
	assert_eq(WestTheme.era_name(1545), "Spanish exploration")
	assert_eq(WestTheme.era_name(1775), "mission country")
	assert_eq(WestTheme.era_name(1865), "homestead and rail")
	assert_eq(WestTheme.era_name(1890), "the frontier closes")


func test_history_span_covers_game_setting() -> void:
	assert_eq(WestTheme.history_span(), "1540–1890")


func test_zone_display_labels() -> void:
	assert_eq(WestTheme.zone_display("forage"), "gather")
	assert_eq(WestTheme.zone_display("build shelter"), "raise dugout")
