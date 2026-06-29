class_name Unit
extends Node2D

## Visual farmer on the map. Walking is free — at ~10 m per hex a worker covers
## hundreds of tiles per day; only farm work costs daily actions.

const WALK_SECONDS_PER_HEX := 0.06
const WALK_SECONDS_MIN := 0.08
const WALK_SECONDS_MAX := 0.45

var hex_coords: Vector2i = Vector2i.ZERO
var tile_map: TileMapLayer
var _walk_tween: Tween


func setup(map: TileMapLayer, start_coords: Vector2i = Vector2i(999999, 999999)) -> void:
	tile_map = map
	if start_coords == Vector2i(999999, 999999):
		hex_coords = _default_spawn()
	else:
		hex_coords = start_coords
	_snap_to_hex()


func walk_to(target: Vector2i) -> bool:
	if tile_map == null:
		return false
	if tile_map.get_cell_source_id(target) == -1:
		return false
	if target == hex_coords:
		return true
	hex_coords = target
	var dest := tile_map.map_to_local(hex_coords)
	if _walk_tween != null and _walk_tween.is_valid():
		_walk_tween.kill()
	var distance := float(position.distance_to(dest))
	var duration := clampf(
		distance / tile_map.tile_set.tile_size.x * WALK_SECONDS_PER_HEX,
		WALK_SECONDS_MIN,
		WALK_SECONDS_MAX
	)
	_walk_tween = create_tween()
	_walk_tween.tween_property(self, "position", dest, duration)
	return true


func _default_spawn() -> Vector2i:
	var used_cells := tile_map.get_used_cells()
	if used_cells.is_empty():
		return Vector2i.ZERO
	return used_cells[used_cells.size() >> 1]


func _snap_to_hex() -> void:
	position = tile_map.map_to_local(hex_coords)
