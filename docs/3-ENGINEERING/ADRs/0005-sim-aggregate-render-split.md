# ADR-0005: Hex simulation, aggregate cache, zoom rendering

## Status

Accepted

## Date

2026-06-28

## Context

We need simple propagation and simple rendering at four spatial scales. Two bad options:

1. **Hierarchical hex clusters** — nested hex groups; awkward topology and propagation paths
2. **Separate maps per zoom** — duplicate authoring and drift from sim state

## Decision

Split into three responsibilities:

### 1. Simulation (L0 only)

All propagation and local rules run on hexes and **neighbor hexes** only (e.g. disease spread).
The L1–L3 hierarchy is never in the propagation path.

### 2. Aggregation (L1–L3 cache)

After hex changes, recompute **only dirty** buckets bottom-up:

```text
hex change → patch dirty → block dirty → zone dirty
end tick: dirty patches → dirty blocks → dirty zones
```

Each level stores the same fields with fixed reducers, e.g.:

- `population`, `food`, `armies` → SUM
- `forest` → AVG
- `terrain`, `owner` → majority
- `passable` → all
- `road_level` → max

### 3. Rendering (zoom selects level)

One simulation; renderer asks `current_zoom` and draws:

- near → hexes (viewport culled)
- medium → one tile per patch
- far → one tile per block
- strategic → one tile per zone

No second authored map. Read hex buffer or aggregate cache only.

## Consequences

**Positive**

- Single propagation model regardless of zoom
- Predictable render cost at coarse zoom
- Incremental aggregate updates via dirty flags

**Negative**

- MapRenderer must implement multiple draw paths
- Bucket assignment at map gen is mandatory infrastructure

## References

- `docs/3-ARCHITECTURE.md`
- `docs/2-REQUIREMENTS.md` - spatial bucket and rendering requirements
