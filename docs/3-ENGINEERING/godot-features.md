# Godot Features (Short List)

## Use

| Feature | For |
|---|---|
| `TileMapLayer` | L0 hex draw (zoomed in) |
| `Camera2D` zoom | Pick render level (hex / patch / block / zone) |
| Autoloads | TurnManager, GameState, AggregateCache |
| Signals | Turn end -> persons -> hex sim -> flush dirty |
| `RandomNumberGenerator` | Seeded person rolls |
| Custom draw / quads | Patch/block/zone tiles from cache (no second map) |
| `Camera3D` + mesh | Terrain side view from the same hex elevation data |
| `Resource` scripts | Scenario, crop, structure, and future data definitions |

## Skip

Physics movement, NavigationAgent2D for day-scale gameplay, separate TileMaps per zoom,
hierarchical hex clusters, or hardcoded scenario constants spread through UI code.

## Three jobs

1. **HexSim** — L0 only, neighbor propagation  
2. **AggregateCache** — dirty L1→L3  
3. **MapRenderer** — zoom → level  

Game logic adds scenario, agent, resource, and economy layers above those three jobs. Keep those
systems separate so the map renderer never becomes the simulation.

See [`../3-ARCHITECTURE.md`](../3-ARCHITECTURE.md).
