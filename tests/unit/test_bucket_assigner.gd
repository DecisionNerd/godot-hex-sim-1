extends GutTest

const BucketAssigner = preload("res://scripts/world/bucket_assigner.gd")


func test_patch_id_div_10() -> void:
	var id := BucketAssigner.patch_id_from_coords(Vector2i(25, -5))
	assert_eq(id, Vector2i(2, -1))


func test_block_id_div_100() -> void:
	var id := BucketAssigner.block_id_from_coords(Vector2i(250, 50))
	assert_eq(id, Vector2i(2, 0))


func test_zone_id_div_1000() -> void:
	var id := BucketAssigner.zone_id_from_coords(Vector2i(2500, 100))
	assert_eq(id, Vector2i(2, 0))
