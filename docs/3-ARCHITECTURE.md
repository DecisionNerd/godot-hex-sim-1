# Architecture

Offline Godot 4 game: one **hex simulation** (L0), **aggregate caches** (L1–L3), **zoom-based
rendering**. Turn loop + actors + persons. No server, no physics.

Three separate jobs:

| Job | Where | Rule |
|---|---|---|
| **Simulation** | L0 hexes only | All propagation (disease, movement, etc.) is hex → neighbor hex |
| **Aggregation** | L1 patch, L2 block, L3 zone | Cached summaries; recomputed when hexes change |
| **Rendering** | Camera zoom | Draw hexes, patches, blocks, or zones — one map, no duplicate tiles |

```
Player → UI → TurnManager → Actors / Persons
                          → HexSim (L0 only)
                          → AggregateCache (dirty L1→L3)
                          → MapRenderer (zoom → level)
```

## Spatial buckets (not hex clusters)

The hierarchy is **fixed spatial buckets** over a single hex grid. Do **not** nest hex shapes inside
hex shapes.

| Level | Name | Size |
|---|---|---|
| L0 | hex | 10 m |
| L1 | patch | 100 m |
| L2 | block | 1 km |
| L3 | zone | 10 km |

At **map generation**, each hex gets permanent bucket IDs:

```text
hex.patch_id
hex.block_id
hex.zone_id
```

Each hex belongs to exactly one patch, one block, and one zone. IDs are never inferred at runtime
from neighbor topology — only from the bucket assignment baked into the map.

## Simulation (L0 only)

Hexes are the **authoritative state**. All spread and local rules run here.

Example — disease:

```text
Hex A (infected)
   ↓
Neighbor hexes
   ↓
Neighbor hexes
```

Only hex data changes during the tick. The hierarchy is **not** part of the propagation path.

**Turn end (sim order):**

```text
1. Actors take explicit actions
2. Persons resolve (seeded RNG, fixed order)
3. Hex sim tick (spread, work, etc.) — hex → hex only
4. Flush dirty aggregates (see below)
5. turn_number++
```

## Aggregation (cache, not simulation)

L1–L3 store the **same field names** as hexes, derived from children below.

| Field | Hex rule | Patch rule | Block / zone rule |
|---|---|---|---|
| `population` | source | `SUM(hex)` | `SUM(patch)` / `SUM(block)` |
| `food` | source | `SUM` | `SUM` |
| `forest` | source | `AVG` | `AVG` |
| `terrain` | source | `majority` | `majority` |
| `owner` | source | `majority` | `majority` |
| `passable` | source | `all` | `all` |
| `road_level` | source | `max` | `max` |
| `water` | source | `SUM` or `AVG` | same fn as patch |
| `disease` | source | `SUM` or `max` | same fn as patch |
| `armies` | source | `SUM` | `SUM` |

Define one aggregation function per field; reuse at every level.

**Never propagate through the hierarchy for simulation.** After hex changes:

```text
Changed hexes
      ↓
Recompute affected patch(es)
      ↓
Recompute affected block(s)
      ↓
Recompute affected zone(s)
```

### Dirty updates

Do not recompute the whole map every tick.

When a hex changes:

```text
Hex dirty → patch dirty → block dirty → zone dirty
```

End of tick:

```text
for each dirty patch:   aggregate from its hexes
for each dirty block:   aggregate from its patches
for each dirty zone:    aggregate from its blocks
clear dirty sets
```

## Rendering

No separate map per zoom level. One simulation; renderer picks granularity.

| Zoom | Draw |
|---|---|
| Near | L0 hexes (visible window only) |
| Medium | L1 — one tile per patch |
| Far | L2 — one tile per block |
| Strategic | L3 — one tile per zone |

```text
current_zoom → pick level → read aggregate or hex buffer → draw
```

Predictable cost:

| Zoom | Rough draw count |
|---|---|
| Hex | Many (cull to viewport) |
| Patch | Thousands |
| Block | Hundreds |
| Zone | Dozens |

Patch/block/zone tiles can be simple colored quads or one atlas tile per bucket — still sourced
from aggregate data, not a second authored map.

## Entities

### Actor

Player or agent. Shown at `hex_coords` on the map. **Labor** (plant, tend, harvest) consumes
the daily budget. Walking between plots is free — at 10 m/hex a worker crosses hundreds of tiles
per day.

### Person

Non-player. `hex_coords`, rules `{ action, probability }`. On turn end: seeded `rng.randf()` vs
probabilities; stable sort order by id.

### RNG

One `RandomNumberGenerator` on `GameState` (planned). Person rolls only. Save includes seed.

## Components

| Component | Role |
|---|---|
| `TurnManager` | Turn #, actions, signals |
| `main.gd` | Input, HUD |
| `Unit` → `Actor` | L0 position, visual walk (rename planned) |
| `TileMapLayer` | L0 visuals (hex zoom) |
| **`HexSim`** (planned) | L0 state + hex-neighbor propagation |
| **`AggregateCache`** (planned) | patch/block/zone structs, dirty flush |
| **`MapRenderer`** (planned) | Zoom → draw level |
| **`GameState`** (planned) | Seed, bucket maps, entity lists |
| **`PersonSystem`** (planned) | End-turn person rolls |

## Data model

**Hex (L0)** — authoritative:

```text
coords, patch_id, block_id, zone_id
terrain, population, food, ownership, roads, forest, water, disease, armies, passable, ...
```

**Patch / block / zone** — cached aggregates, same keys, plus `dirty: bool`.

**Actor:** `id`, `hex`, `is_player`, `is_agent`

**Person:** `id`, `hex`, `rules: [{ action, p }]`

## Key flows

### Select plot + labor (done)

Click farm plot → `local_to_map` → select → `walk_to()` (free tween). Plant/tend/harvest →
`consume_action()` on selected plot.

### Sim + aggregate (planned)

Disease on hex A → spread to neighbor hexes → each changed hex marks patch/block/zone dirty →
end tick flush aggregates.

## Godot pieces

`TileMapLayer` (hex view), autoloads, signals, `Resource`, seeded RNG, `Camera2D` zoom for level
pick, optional second draw path for patch/block/zone quads.

Avoid: physics, NavigationAgent2D, multiplayer, separate TileMaps per zoom.

## Decisions

- [ADR-0001 — Hex map via TileMapLayer](3-ENGINEERING/ADRs/0001-hex-map-tilemap-layer.md)
- [ADR-0002 — Turn-based, no physics](3-ENGINEERING/ADRs/0002-turn-based-no-physics.md)
- [ADR-0003 — TurnManager autoload](3-ENGINEERING/ADRs/0003-turn-manager-autoload.md)
- [ADR-0004 — Spatial buckets and entities](3-ENGINEERING/ADRs/0004-spatial-scales-and-entities.md)
- [ADR-0005 — Hex sim, aggregate cache, zoom render](3-ENGINEERING/ADRs/0005-sim-aggregate-render-split.md)

## Risks

- Bucket assignment must be stable and saved with the map
- Dirty flush order: patches before blocks before zones
- Renderer and sim must agree on field list per level
