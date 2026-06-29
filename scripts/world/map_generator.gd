class_name MapGenerator
extends RefCounted

const HexGrid = preload("res://scripts/world/hex_grid.gd")
const HexState = preload("res://scripts/world/hex_state.gd")

const MAP_RADIUS := 9
const ORIGIN := Vector2i.ZERO

const WATER_ELEVATION := -0.22
const WOOD_MOISTURE := 0.18
const WOOD_ELEVATION_MAX := 0.35


static func generate_terrain(rng: RandomNumberGenerator) -> Dictionary:
	var elevation := FastNoiseLite.new()
	elevation.seed = rng.seed
	elevation.noise_type = FastNoiseLite.TYPE_SIMPLEX
	elevation.frequency = 0.085
	elevation.fractal_octaves = 3

	var moisture := FastNoiseLite.new()
	moisture.seed = rng.seed + 7919
	moisture.noise_type = FastNoiseLite.TYPE_SIMPLEX
	moisture.frequency = 0.11
	moisture.fractal_octaves = 2

	var terrain: Dictionary = {}
	for coords in HexGrid.cells_in_radius(ORIGIN, MAP_RADIUS):
		var axial: Vector2i = HexGrid.map_to_axial(coords)
		var sample := Vector2(axial.x * 1.03, axial.y * 1.03)
		var elev := elevation.get_noise_2d(sample.x, sample.y)
		var moist := moisture.get_noise_2d(sample.x + 40.0, sample.y - 25.0)
		if elev < WATER_ELEVATION:
			terrain[coords] = HexState.TERRAIN_WATER
		elif moist > WOOD_MOISTURE and elev < WOOD_ELEVATION_MAX:
			terrain[coords] = HexState.TERRAIN_WOOD
		else:
			terrain[coords] = HexState.TERRAIN_GRASS
	_ensure_start_grass(terrain)
	return terrain


static func prepare_tile_map(tile_map: TileMapLayer) -> void:
	if tile_map.tile_set == null:
		tile_map.tile_set = HexGrid.create_tileset()
	tile_map.clear()


static func pick_home_hex(terrain: Dictionary) -> Vector2i:
	var best: Vector2i = ORIGIN
	var best_score := 999999
	for coords in terrain:
		if terrain[coords] != HexState.TERRAIN_GRASS:
			continue
		var score: int = HexGrid.cube_distance(coords, ORIGIN)
		if score < best_score:
			best_score = score
			best = coords
	return best


static func _ensure_start_grass(terrain: Dictionary) -> void:
	if terrain.get(ORIGIN, HexState.TERRAIN_GRASS) == HexState.TERRAIN_GRASS:
		return
	for coords in HexGrid.cells_in_radius(ORIGIN, 2):
		terrain[coords] = HexState.TERRAIN_GRASS
