# Backlog

Prioritized work queue. **Now** = finish playable v1 loop. Pull from the top.

## Now — finish Phase 0

| # | Item | Why | Done when |
|---|---|---|---|
| 1 | **Plot selection highlight** | Management sim needs clear “which field am I working?” | Selected farm hex is visibly highlighted on the map |
| 2 | **Hunger lose condition** | Stakes — surviving the year means something | Track consecutive hungry days; game over after N days at food ≤ 0; UI message |
| 3 | **Save / load** | Finish a year across sessions; foundation for county scale | JSON (or Resource) saves rng seed, calendar, resources, plots, selected hex; load restores deterministically |
| 4 | **CI test run** | Regressions caught on push | GitHub Action runs `./scripts/run_tests.sh` on PR |
| 5 | **Tutorial hints polish** | First session without README | Opening log + hints explain select → labor → end day; no stale “move adjacent” copy |

## Next — Phase 1 (family)

| # | Item | Why | Done when |
|---|---|---|---|
| 6 | **Household persons** | Head of household directs, family helps | 2–3 persons with seeded daily RNG (tend, idle, etc.) |
| 7 | **Extra labor slots** | Management depth without micro-movement | Family labor adds actions or auto-resolves tend on assigned plots |
| 8 | **Expand the holding** | Build the farm, not just maintain starter plots | Clear brush / claim adjacent hexes as new plots (cost seeds or days) |

## Later — Phase 2 (county)

| # | Item | Why | Done when |
|---|---|---|---|
| 9 | **Bucket IDs at map gen** | ADR-0004 spatial model | Each hex gets `patch_id`, `block_id`, `zone_id` |
| 10 | **Dirty aggregate cache** | Zoom without re-simming | Patch/block/zone structs recompute when child hexes change |
| 11 | **Zoom-based renderer** | One world, many scales | Camera zoom picks L0 hex vs L1–L3 draw |
| 12 | **Rename Unit → Actor** | Docs/code alignment | Scene, script, references updated |

## Icebox

- County economy, armies, disease propagation
- Multiplayer, agents competing for holdings
- Custom art / tile themes

## Recently shipped

- [x] GUT test suite (20 tests)
- [x] Management sim input — select plot, free walk, labor on work
- [x] Daily calendar, weather, crops, skip-to-work
