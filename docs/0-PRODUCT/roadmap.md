# Roadmap

## Phase 0 — Farming family (done)

- [x] Turn-based days (2 labor actions per day)
- [x] Seasons (91 days each) and weather
- [x] Resources: food, wheat seed, barley seed
- [x] Crops with attributes (seasons, grow time, yield, frost tolerance)
- [x] Labor: plant, tend, harvest; click-to-select plots (free walk)
- [x] Household food consumption (2 food / 7 days)
- [x] Start screen, options shell, 1280×720 window
- [x] Plot selection highlight
- [x] Hunger lose condition
- [x] Save / load
- [x] CI test run

## Phase 1 — Family members (done)

- [x] Persons in household (seeded RNG — spouse & child tend on drought/frost)
- [x] Family labor helps tend (end of day, no action cost)
- [x] Expand the holding (claim adjacent wild hexes)

## Phase 2 — County scale (foundation done)

- [x] Spatial bucket IDs at map build (`patch_id`, `block_id`, `zone_id`)
- [x] Dirty aggregate cache (patch → block → zone)
- [x] Zoom-based renderer (scroll wheel: hex / patch / block / zone)
- [x] Multiple holdings + neighbor agent (Miller holding)
- [x] Rename Unit → Actor

## Next

- [ ] Hex-neighbor propagation (disease, etc.)
- [ ] Agent AI for neighbor holdings
- [ ] Options screen (volume, fullscreen)
- [ ] Larger county map

## Not now

- County-wide economy, armies, full disease sim
- Multiplayer
