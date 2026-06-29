# ADR-0004: Spatial buckets and entities

## Status

Accepted (amended — see ADR-0005 for sim/cache/render split)

## Date

2026-06-28

## Context

County sim needs four spatial scales (10 m → 10 km) and two entity kinds (actors, persons).

## Decision

### Fixed spatial buckets

- **L0 hex = 10 m** — only level that holds authoritative sim state
- **L1 patch = 100 m**, **L2 block = 1 km**, **L3 zone = 10 km** — aggregate caches

At map generation, assign each hex:

```text
hex.patch_id, hex.block_id, hex.zone_id
```

Do **not** use hierarchical hex clusters (nested hex groups). Buckets are fixed spatial regions
over the same grid.

### Entities

- **Actor** — player or agent; explicit turn actions
- **Person** — non-player; seeded RNG vs probabilities on turn end; stable iteration order

## Consequences

**Positive:** One grid, clear IDs, simple rollup ownership  
**Negative:** Map gen must implement bucket assignment once

## References

- `docs/2-REQUIREMENTS.md` — FR-S*, FR-A*
- [ADR-0005](0005-sim-aggregate-render-split.md) — simulation vs aggregation vs rendering
