extends RefCounted

const TERRAIN_GRASS := 0
const TERRAIN_FARMLAND := 1
const TERRAIN_WOOD := 2
const TERRAIN_WATER := 3

var coords: Vector2i = Vector2i.ZERO
var patch_id: Vector2i = Vector2i.ZERO
var block_id: Vector2i = Vector2i.ZERO
var zone_id: Vector2i = Vector2i.ZERO
var terrain: int = TERRAIN_GRASS
var forest: float = 0.0
var population: int = 0
var food: int = 0
var ownership: String = "player"
var dirty: bool = false
