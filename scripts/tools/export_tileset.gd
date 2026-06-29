extends SceneTree

const HexGrid = preload("res://scripts/world/hex_grid.gd")


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://resources")
	var err := ResourceSaver.save(HexGrid.create_tileset(), "res://resources/hex_tileset.tres")
	if err != OK:
		push_error("Save failed: %s" % err)
		quit(1)
		return
	print("Saved hex_tileset.tres")
	quit()
