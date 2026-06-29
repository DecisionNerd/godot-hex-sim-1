# Requirements

Status: **Done** | **Partial** | **Planned**.

## Spatial buckets

One hex = **10 m**. L1–L3 are **fixed spatial buckets**, not nested hex clusters.

| Level | Size | Role |
|---|---|---|
| L0 hex | 10 m | Authoritative simulation |
| L1 patch | 100 m | Aggregate cache |
| L2 block | 1 km | Aggregate cache |
| L3 zone | 10 km | Aggregate cache |

| ID | Requirement | Status |
|---|---|---|
| FR-S1 | One hex = 10 m. | Planned |
| FR-S2 | At map generation, assign each hex `patch_id`, `block_id`, `zone_id` (fixed buckets). | Planned |
| FR-S3 | Each hex belongs to exactly one patch, one block, one zone. | Planned |
| FR-S4 | L1–L3 are never authored separately; only aggregated from children. | Planned |
| FR-S5 | Simulation (spread, local rules) runs on L0 hexes and neighbor hexes only — not via hierarchy. | Planned |
| FR-S6 | When hex fields change, mark patch → block → zone dirty; recompute only dirty buckets at end of tick. | Planned |
| FR-S7 | Same field set at all levels; each field has one aggregation rule (SUM, AVG, majority, all, max). | Planned |

**Shared fields (example):** `terrain`, `population`, `food`, `ownership`, `roads`, `forest`,
`water`, `disease`, `armies`, `passable`.

## Rendering

| ID | Requirement | Status |
|---|---|---|
| FR-R1 | One simulation map; no separate authored map per zoom. | Planned |
| FR-R2 | Renderer selects draw level from camera zoom (hex / patch / block / zone). | Planned |
| FR-R3 | Hex view draws visible L0 cells; coarser zooms draw one tile per bucket at that level. | Planned |
| FR-R4 | Render reads from hex state (L0) or aggregate cache (L1–L3), never simulates. | Planned |

## Actors and persons

| Kind | Behavior |
|---|---|
| **Actor** | Player or agent; explicit labor choices per day (plant, tend, harvest) |
| **Person** | Seeded RNG vs fixed probabilities on turn end |

At L0 scale (~10 m hex), a person can traverse hundreds of hexes per day. **Position on the map
is visual** — walking does not consume the daily labor budget.

| ID | Requirement | Status |
|---|---|---|
| FR-A1 | Actor shown on map; farm labor consumes daily budget. | Partial |
| FR-A2 | Person has hex position + probability rules. | Planned |
| FR-A3 | Persons resolve after actors, before hex sim tick. | Planned |
| FR-A4 | Seeded RNG; same seed + inputs → same rolls. | Planned |
| FR-A5 | Agents use same action model as player actor. | Planned |
| FR-A6 | Click farm plot to select; walk to plot is free. | Done |

## Implemented scaffold

| ID | Requirement | Status |
|---|---|---|
| FR-1 | Hex map via `TileMapLayer`. | Done |
| FR-2 | Mouse → hex. | Done |
| FR-5–8 | Turn counter, actions, end turn. | Done |
| FR-11–12 | Click plot to select; farmer walks visually (no labor cost). | Done |
| FR-20 | HUD turn + hints. | Done |

## Non-functional

| ID | Requirement |
|---|---|
| NFR-1 | Godot 4.7, desktop, offline |
| NFR-2 | Deterministic sim (seeded RNG for persons) |
| NFR-3 | Dirty aggregates — avoid full-map recompute each tick |
| NFR-4 | Keep design simple: hex sim + cache + zoom render |

## Open questions

- Bucket geometry: axis-aligned grid buckets vs projected hex coords? — decide at map gen
- Which person actions in v1? — owner
