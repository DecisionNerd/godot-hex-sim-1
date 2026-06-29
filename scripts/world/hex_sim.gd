extends RefCounted

const BucketAssigner = preload("res://scripts/world/bucket_assigner.gd")
const HexState = preload("res://scripts/world/hex_state.gd")
const AggregateCache = preload("res://scripts/world/aggregate_cache.gd")
const TerrainClassifier = preload("res://scripts/world/terrain_classifier.gd")

var hexes: Dictionary = {}
var aggregate: AggregateCache = AggregateCache.new()
var plot_coords: Dictionary = {}


func build_from_terrain(terrain: Dictionary, plots: Array) -> void:
	hexes.clear()
	plot_coords.clear()
	for coords in plots:
		plot_coords[coords] = true
	for coords in terrain:
		if terrain[coords] == HexState.TERRAIN_WATER:
			continue
		var hex := HexState.new()
		hex.coords = coords
		hex.patch_id = BucketAssigner.patch_id_from_coords(coords)
		hex.block_id = BucketAssigner.block_id_from_coords(coords)
		hex.zone_id = BucketAssigner.zone_id_from_coords(coords)
		if plot_coords.has(coords):
			hex.terrain = HexState.TERRAIN_FARMLAND
			hex.forest = 0.0
		else:
			hex.terrain = terrain[coords]
			hex.forest = 1.0 if hex.terrain == HexState.TERRAIN_WOOD else 0.0
		hexes[coords] = hex
		aggregate.mark_hex_dirty(hex)
	flush_aggregates()


func build_from_map(tile_map: TileMapLayer, plots: Array) -> void:
	var terrain: Dictionary = {}
	for coords in tile_map.get_used_cells():
		terrain[coords] = TerrainClassifier.terrain_from_tile(tile_map, coords)
	build_from_terrain(terrain, plots)


func mark_dirty(coords: Vector2i) -> void:
	var hex := get_hex(coords)
	if hex == null:
		return
	hex.dirty = true
	aggregate.mark_hex_dirty(hex)


func get_hex(coords: Vector2i) -> HexState:
	return hexes.get(coords)


func flush_aggregates() -> void:
	aggregate.flush(hexes, plot_coords)
	for coords in hexes:
		hexes[coords].dirty = false
