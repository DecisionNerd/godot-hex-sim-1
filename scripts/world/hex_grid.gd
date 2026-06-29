class_name HexGrid
extends RefCounted

## Coordinate helpers for Godot's vertical odd-r hex layout (pointy-top).

const TILE_SIZE := Vector2i(110, 94)


static func create_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	tileset.tile_layout = TileSet.TILE_LAYOUT_STACKED_OFFSET
	tileset.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	tileset.tile_size = TILE_SIZE
	var source := TileSetAtlasSource.new()
	var image := Image.create(TILE_SIZE.x, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.18, 0.32, 0.16, 1.0))
	source.texture = ImageTexture.create_from_image(image)
	source.create_tile(Vector2i.ZERO)
	tileset.add_source(source, 0)
	return tileset


static func axial_to_map(q: int, r: int) -> Vector2i:
	return Vector2i(q, r + (q + (q & 1)) / 2)


static func map_to_axial(coords: Vector2i) -> Vector2i:
	var q := coords.x
	var r := coords.y - (coords.x + (coords.x & 1)) / 2
	return Vector2i(q, r)


static func cube_distance(a: Vector2i, b: Vector2i) -> int:
	var ac := map_to_axial(a)
	var bc := map_to_axial(b)
	var aq := ac.x
	var ar := ac.y
	var a_s := -aq - ar
	var bq := bc.x
	var br := bc.y
	var b_s := -bq - br
	return maxi(maxi(abs(aq - bq), abs(ar - br)), abs(a_s - b_s))


static func cells_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var center_axial := map_to_axial(center)
	for dq in range(-radius, radius + 1):
		for dr in range(-radius, radius + 1):
			var ds := -dq - dr
			if maxi(maxi(abs(dq), abs(dr)), abs(ds)) > radius:
				continue
			var axial: Vector2i = Vector2i(center_axial.x + dq, center_axial.y + dr)
			out.append(axial_to_map(axial.x, axial.y))
	return out
