extends RefCounted

const TERRAIN_DEFAULT := 0
const TERRAIN_FARMLAND := 1

var coords: Vector2i = Vector2i.ZERO
var patch_id: Vector2i = Vector2i.ZERO
var block_id: Vector2i = Vector2i.ZERO
var zone_id: Vector2i = Vector2i.ZERO
var terrain: int = 0
var population: int = 0
var food: int = 0
var ownership: String = "player"
var dirty: bool = false
