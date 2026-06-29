# ADR-0001: Hex map via TileMapLayer

## Status

Accepted

## Date

2026-06-28

## Context

Hex Sim needs a county map where terrain, improvements, and simulation metadata align to the
same grid. Alternatives considered:

1. **Godot `TileMapLayer` with hex `TileSet`** (official demo approach)
2. **Custom mesh/grid drawn in `_draw`**
3. **Third-party hex library**

The project started from the [Godot hexagonal_map demo](https://github.com/godotengine/godot-demo-projects/tree/master/2d/hexagonal_map).

## Decision

Use **`TileMapLayer` + hex-shaped `TileSet`** as the single source of hex coordinates and
visual tiles. Use engine methods (`local_to_map`, `map_to_local`, `get_surrounding_cells`) for
adjacency and picking.

Per-hex simulation fields will be added via **TileSet custom data layers**, with dynamic
overrides in a runtime `GameState` when needed.

## Consequences

**Positive**

- Editor-friendly map authoring and tile painting
- Built-in hex adjacency and coordinate conversion
- Multiple layers for terrain, overlays, and fog
- Matches Godot documentation and community patterns

**Negative**

- Couples visual tileset to sim schema unless custom data is designed carefully
- Large counties may need chunking or performance tuning
- Demo tiles are generic, not medieval-specific

## References

- `tileset.tres`, `scenes/main.tscn`
- `docs/3-ARCHITECTURE.md` — Data model, Godot built-ins
