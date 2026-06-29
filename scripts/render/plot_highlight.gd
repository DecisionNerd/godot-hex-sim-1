extends Node2D

var tile_map: TileMapLayer
var selected_hex: Vector2i = Vector2i(999999, 999999)


func setup(map: TileMapLayer) -> void:
	tile_map = map


func set_selected(coords: Vector2i) -> void:
	selected_hex = coords
	queue_redraw()


func _draw() -> void:
	if tile_map == null or selected_hex == Vector2i(999999, 999999):
		return
	if tile_map.get_cell_source_id(selected_hex) == -1:
		return
	var center := tile_map.map_to_local(selected_hex)
	var size := float(tile_map.tile_set.tile_size.x) * 0.42
	var points := PackedVector2Array([
		Vector2(center.x, center.y - size),
		Vector2(center.x + size * 0.866, center.y - size * 0.5),
		Vector2(center.x + size * 0.866, center.y + size * 0.5),
		Vector2(center.x, center.y + size),
		Vector2(center.x - size * 0.866, center.y + size * 0.5),
		Vector2(center.x - size * 0.866, center.y - size * 0.5),
	])
	draw_colored_polygon(points, Color(1.0, 0.92, 0.2, 0.28))
	draw_polyline(points + PackedVector2Array([points[0]]), Color(1.0, 0.85, 0.1, 0.9), 2.0)
