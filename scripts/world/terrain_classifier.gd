extends RefCounted

const HexState = preload("res://scripts/world/hex_state.gd")


static func is_passable(terrain: int) -> bool:
	return terrain != HexState.TERRAIN_WATER


static func terrain_from_tile(tile_map: TileMapLayer, coords: Vector2i) -> int:
	if tile_map.get_cell_source_id(coords) == -1:
		return HexState.TERRAIN_GRASS
	return HexState.TERRAIN_GRASS
