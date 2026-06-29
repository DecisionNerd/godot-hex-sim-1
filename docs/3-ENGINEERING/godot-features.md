# Godot features (short list)

## Use

| Feature | For |
|---|---|
| `TileMapLayer` | L0 hex draw (zoomed in) |
| `Camera2D` zoom | Pick render level (hex / patch / block / zone) |
| Autoloads | TurnManager, GameState, AggregateCache |
| Signals | Turn end → persons → hex sim → flush dirty |
| `RandomNumberGenerator` | Seeded person rolls |
| Custom draw / quads | Patch/block/zone tiles from cache (no second map) |

## Skip

Physics movement, NavigationAgent2D, separate TileMaps per zoom, hierarchical hex clusters.

## Three jobs

1. **HexSim** — L0 only, neighbor propagation  
2. **AggregateCache** — dirty L1→L3  
3. **MapRenderer** — zoom → level  

See [`../3-ARCHITECTURE.md`](../3-ARCHITECTURE.md).
