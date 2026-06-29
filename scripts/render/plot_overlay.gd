extends Node2D

const HexState = preload("res://scripts/world/hex_state.gd")
const FarmBuilding = preload("res://scripts/world/farm_building.gd")

const COLOR_EMPTY := Color(0.58, 0.45, 0.28, 0.62)
const COLOR_WHEAT := Color(0.72, 0.78, 0.32, 0.78)
const COLOR_WHEAT_MATURE := Color(0.92, 0.76, 0.18, 0.88)
const COLOR_BARLEY := Color(0.55, 0.72, 0.28, 0.78)
const COLOR_BARLEY_MATURE := Color(0.85, 0.72, 0.22, 0.88)
const COLOR_CLAIMABLE := Color(0.28, 0.62, 0.38, 0.45)
const COLOR_WOOD := Color(0.12, 0.38, 0.16, 0.72)
const COLOR_WOOD_CLEAR := Color(0.95, 0.55, 0.15, 0.9)
const COLOR_GRASS := Color(0.35, 0.55, 0.28, 0.35)
const COLOR_WATER := Color(0.15, 0.35, 0.62, 0.75)
const COLOR_HOME := Color(0.45, 0.55, 0.85, 0.5)
const COLOR_NEED_WORK := Color(0.95, 0.42, 0.12, 0.95)
const COLOR_TENDED := Color(0.35, 0.65, 0.95, 0.9)
const COLOR_SELECT := Color(1.0, 0.95, 0.55, 1.0)
const COLOR_HOUSE := Color(0.55, 0.38, 0.22, 0.95)
const COLOR_BARN := Color(0.62, 0.28, 0.18, 0.92)
const COLOR_ROOF := Color(0.45, 0.22, 0.12, 0.95)

var tile_map: TileMapLayer
var selected_hex: Vector2i = Vector2i(999999, 999999)
var _hex_view: bool = true
var _font: Font


func setup(map: TileMapLayer) -> void:
	tile_map = map
	_font = ThemeDB.fallback_font


func set_hex_view(enabled: bool) -> void:
	_hex_view = enabled
	visible = enabled
	queue_redraw()


func set_selected(coords: Vector2i) -> void:
	selected_hex = coords
	queue_redraw()


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if tile_map == null or not _hex_view:
		return
	for coords in tile_map.get_used_cells():
		if GameState.is_farm_plot(coords):
			continue
		_draw_wild_hex(coords)
	for coords in GameState.plots:
		_draw_farm_plot(coords)
	for coords in GameState.buildings:
		_draw_building(coords, GameState.buildings[coords])
	if selected_hex != Vector2i(999999, 999999):
		_draw_selection(selected_hex)


func _draw_wild_hex(coords: Vector2i) -> void:
	var terrain := GameState.hex_terrain(coords)
	var work := GameState.plot_work_type(coords)
	if terrain == HexState.TERRAIN_WATER:
		_draw_hex_fill(coords, COLOR_WATER)
		return
	if terrain == HexState.TERRAIN_WOOD:
		_draw_hex_fill(coords, COLOR_WOOD)
		_draw_trees(coords)
		_draw_label(coords, "WOOD", 11)
		if work == "clear_wood":
			_draw_hex_border(coords, COLOR_WOOD_CLEAR, 3.0, false)
	elif work == "claim":
		_draw_hex_fill(coords, COLOR_GRASS)
		_draw_hex_border(coords, COLOR_CLAIMABLE.lightened(0.2), 2.0, true)
		_draw_label(coords, "CLAIM", 11)
	else:
		_draw_hex_fill(coords, COLOR_GRASS.darkened(0.08))


func _draw_farm_plot(coords: Vector2i) -> void:
	var plot = GameState.get_plot(coords)
	if plot == null:
		return
	var work := GameState.plot_work_type(coords)
	var fill := COLOR_EMPTY
	var label := "empty"
	if plot.is_empty():
		if work == "plant":
			label = "plant?"
	else:
		var crop = GameState.get_crop(plot.crop_id)
		if plot.is_mature(crop):
			fill = COLOR_WHEAT_MATURE if plot.crop_id == "wheat" else COLOR_BARLEY_MATURE
			label = "HARVEST"
		else:
			var ratio := GameState.plot_growth_ratio(coords)
			var base := COLOR_WHEAT if plot.crop_id == "wheat" else COLOR_BARLEY
			var mature := COLOR_WHEAT_MATURE if plot.crop_id == "wheat" else COLOR_BARLEY_MATURE
			fill = base.lerp(mature, ratio * 0.65)
			var abbr := "W" if plot.crop_id == "wheat" else "B"
			label = "%s %d/%d" % [abbr, plot.growth_days, crop.grow_days]
	_draw_hex_fill(coords, fill)
	_draw_growth_bar(coords, GameState.plot_growth_ratio(coords), plot.is_empty())
	if coords == GameState.home_hex:
		_draw_hex_border(coords, COLOR_HOME, 2.5, false)
	if work == "harvest" or work == "tend" or work == "plant":
		_draw_hex_border(coords, COLOR_NEED_WORK, 3.0, false)
	if plot.tended and not plot.is_empty():
		_draw_tended_marker(coords)
	var label_size := 13 if work == "harvest" else 12
	if not GameState.get_building(coords):
		_draw_label(coords, label, label_size)


func _draw_building(coords: Vector2i, building: FarmBuilding) -> void:
	var center := tile_map.map_to_local(coords)
	match building.kind:
		FarmBuilding.Kind.HOUSE:
			_draw_house(center)
			_draw_label(coords, "HOUSE", 10, Vector2(0, 28))
		FarmBuilding.Kind.BARN:
			_draw_barn(center)
			_draw_label(coords, "BARN", 10, Vector2(0, 30))


func _draw_house(center: Vector2) -> void:
	var w := 28.0
	var h := 20.0
	var base := Rect2(center.x - w * 0.5, center.y - h * 0.5 + 4, w, h)
	draw_rect(base, COLOR_HOUSE)
	var roof := PackedVector2Array([
		Vector2(center.x, center.y - h * 0.5 - 6),
		Vector2(center.x + w * 0.55, center.y - h * 0.5 + 6),
		Vector2(center.x - w * 0.55, center.y - h * 0.5 + 6),
	])
	draw_colored_polygon(roof, COLOR_ROOF)


func _draw_barn(center: Vector2) -> void:
	var w := 34.0
	var h := 22.0
	draw_rect(Rect2(center.x - w * 0.5, center.y - h * 0.5 + 2, w, h), COLOR_BARN)
	var roof := PackedVector2Array([
		Vector2(center.x, center.y - h * 0.5 - 4),
		Vector2(center.x + w * 0.6, center.y - h * 0.5 + 8),
		Vector2(center.x - w * 0.6, center.y - h * 0.5 + 8),
	])
	draw_colored_polygon(roof, COLOR_ROOF.darkened(0.15))


func _draw_trees(coords: Vector2i) -> void:
	var center := tile_map.map_to_local(coords)
	for offset in [Vector2(-14, -8), Vector2(10, 6), Vector2(-4, 14)]:
		var p: Vector2 = center + offset
		draw_circle(p + Vector2(0, 4), 7.0, Color(0.08, 0.22, 0.08, 0.9))
		var top := PackedVector2Array([
			p + Vector2(0, -10),
			p + Vector2(7, 4),
			p + Vector2(-7, 4),
		])
		draw_colored_polygon(top, Color(0.15, 0.42, 0.18, 0.95))


func _draw_selection(coords: Vector2i) -> void:
	_draw_hex_border(coords, COLOR_SELECT, 4.0, false)


func _draw_hex_fill(coords: Vector2i, color: Color) -> void:
	draw_colored_polygon(_hex_points(coords), color)


func _draw_hex_border(coords: Vector2i, color: Color, width: float, dashed: bool) -> void:
	var points := _hex_points(coords)
	points.append(points[0])
	if dashed:
		for i in points.size() - 1:
			if i % 2 == 0:
				draw_line(points[i], points[i + 1], color, width)
	else:
		draw_polyline(points, color, width)


func _draw_growth_bar(coords: Vector2i, ratio: float, empty: bool) -> void:
	if empty:
		return
	var center := tile_map.map_to_local(coords)
	var w := float(tile_map.tile_set.tile_size.x) * 0.55
	var h := 6.0
	var left := center.x - w * 0.5
	var top := center.y + float(tile_map.tile_set.tile_size.y) * 0.18
	draw_rect(Rect2(left, top, w, h), Color(0.1, 0.1, 0.1, 0.55))
	draw_rect(Rect2(left, top, w * ratio, h), Color(0.25, 0.85, 0.35, 0.9))


func _draw_tended_marker(coords: Vector2i) -> void:
	var center := tile_map.map_to_local(coords)
	draw_circle(center + Vector2(-22, -18), 5.0, COLOR_TENDED)
	draw_circle(center + Vector2(-22, -18), 5.0, Color(0.1, 0.2, 0.35, 0.8), false, 1.0)


func _draw_label(coords: Vector2i, text: String, size: int, offset: Vector2 = Vector2.ZERO) -> void:
	if _font == null or text.is_empty():
		return
	var center := tile_map.map_to_local(coords) + offset
	var text_size := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
	draw_string(
		_font,
		center - text_size * 0.5,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		Color(0.92, 0.92, 0.88, 0.95)
	)


func _hex_points(coords: Vector2i) -> PackedVector2Array:
	var center := tile_map.map_to_local(coords)
	var size := float(tile_map.tile_set.tile_size.x) * 0.44
	return PackedVector2Array([
		Vector2(center.x, center.y - size),
		Vector2(center.x + size * 0.866, center.y - size * 0.5),
		Vector2(center.x + size * 0.866, center.y + size * 0.5),
		Vector2(center.x, center.y + size),
		Vector2(center.x - size * 0.866, center.y + size * 0.5),
		Vector2(center.x - size * 0.866, center.y - size * 0.5),
	])
