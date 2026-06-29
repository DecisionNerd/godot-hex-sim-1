extends GutTest

const WestTheme = preload("res://scripts/theme/west_theme.gd")


func test_migrate_v2_save_renames_seeds_and_crops() -> void:
	var data := {
		"version": 2,
		"resources": {
			"wheat_seed": 3,
			"barley_seed": 2,
			"food": 5,
		},
		"fields": [{"id": "field_1", "crop_id": "wheat", "hexes": []}],
		"work_zones": [{"id": "z1", "type": 0, "crop_id": "barley", "hexes": []}],
	}
	var migrated: Dictionary = GameState._migrate_loaded_data(data)
	assert_eq(int(migrated.get("version", 0)), GameState.SAVE_VERSION)
	var resources: Dictionary = migrated.get("resources", {})
	assert_eq(resources.get("corn_seed", 0), 3)
	assert_eq(resources.get("bean_seed", 0), 2)
	assert_false(resources.has("wheat_seed"))
	var fields: Array = migrated.get("fields", [])
	assert_eq(fields[0].get("crop_id"), "corn")
	var zones: Array = migrated.get("work_zones", [])
	assert_eq(zones[0].get("crop_id"), "beans")
