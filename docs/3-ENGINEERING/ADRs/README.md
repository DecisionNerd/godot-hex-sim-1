# Architecture Decision Records

An **Architecture Decision Record (ADR)** captures one significant decision — the context,
the choice made, and its consequences — so the reasoning lives in the repo alongside the
code. Decisions are immutable once accepted: to change one, add a new ADR that supersedes it.

## Creating an ADR

Copy an existing ADR file with the next number, or:

```
docgen add adr <short-slug>
```

Add a row to the decision log below when accepted.

## Status values

- **Proposed** — under discussion.
- **Accepted** — decided and in effect.
- **Superseded by ADR-NNNN** — replaced by a later decision.
- **Deprecated** — no longer relevant.

## Decision log

| ADR | Title | Status | Date |
|---|---|---|---|
| [0001](0001-hex-map-tilemap-layer.md) | Hex map via TileMapLayer | Accepted | 2026-06-28 |
| [0002](0002-turn-based-no-physics.md) | Turn-based grid, no physics | Accepted | 2026-06-28 |
| [0003](0003-turn-manager-autoload.md) | TurnManager autoload | Accepted | 2026-06-28 |
| [0004](0004-spatial-scales-and-entities.md) | Spatial buckets and actor/person model | Accepted | 2026-06-28 |
| [0005](0005-sim-aggregate-render-split.md) | Hex sim, aggregate cache, zoom rendering | Accepted | 2026-06-28 |
