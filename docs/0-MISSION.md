# Mission

**Hex Sim** v1 is a **farm management sim** at **household scale**: you are the head of a family,
directing work across a small plot cluster through seasons and weather. One turn = one day. Keep
the family fed and grow the holding.

Each hex is **~10 m**. A farmer can cross hundreds of hexes in a day — **walking is not the
gameplay**; you assign labor (plant, tend, harvest) while the household member on the map shows
where work is happening.

The county hex map and spatial buckets (10 m → 10 km) are **later** — the first playable loop
is manage plots, survive the year, then expand.

## Goals

- Clear daily loop: select plots → spend labor → end day → growth + weather + food use
- Simple crops with readable attributes
- Deterministic weather rolls (seeded RNG in GameState)
- Foundation to grow into county sim later

## Non-goals (v1)

- Tile-by-tile movement as a resource cost
- County-wide propagation, patches/blocks/zones
- Multiplayer, combat, 3D

## Success

Player can finish a full in-game year without docs, understanding seasons, weather, and crops.
