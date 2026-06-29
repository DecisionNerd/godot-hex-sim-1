# Architecture

Offline Godot 4 game with one authoritative hex simulation, scenario-specific rules, independent
agents, resource/economy systems, and zoom/terrain renderers. No server and no physics-driven
gameplay.

## Layers

| Layer | Role |
|---|---|
| Scenario | Date, place, persona, starting state, institutions, available technology |
| Agent model | Player and AI actors choose from the same action vocabulary |
| Daily sim | Labor, chores, household needs, weather, fields, structures, risk |
| Hex sim | Authoritative L0 map state and neighbor-local rules |
| Aggregates | Dirty patch/block/zone summaries for zoomed rendering and future regional logic |
| Render/UI | Map view, 3D terrain view, selection, logs, controls, action panel |

```text
ScenarioCatalog
      |
      v
GameState -> TurnManager -> Work / Persons / Resources
      |              |
      |              v
      |        HexSim (L0 authoritative)
      |              |
      v              v
MapRenderer <- AggregateCache <- dirty hex changes
TerrainView <- elevation + hex state
```

## Scenario Layer

A scenario is the entry point for historical context and rule variation.

```text
id, title, persona_label, place_name, start_year,
opening_log, menu_blurb, settlement_title,
initial_resources, institutions, technology_context, scenario_rules
```

The first scenario is Homestead Act settlement. Later scenarios can reuse the same agent, resource,
and map systems while changing constraints: who has legal standing, who controls access, what
markets exist, what technologies have spread, and what relationships already matter.

## Agent Model

Actors represent decision-making agents. The player is one actor; AI households, traders,
communities, officials, or guides can be actors later.

| Entity | Scope |
|---|---|
| `Actor` | Chooses explicit actions; may be player-controlled or AI-controlled |
| `Person` | Individual with health, skill, relationships, and seeded outcomes |
| `Holding` | Land, structures, stores, obligations, reputation, and claims |
| `WorkZone` | Chore assignment over one or more hexes |

The target design is actor parity: if the player can assign work, trade, negotiate, migrate, or
invest in skill, AI agents should eventually use the same underlying action model.

## Daily Turn Flow

```text
1. Player and AI actors choose or maintain work zones/actions
2. Work consumes labor and changes hexes, structures, fields, or resources
3. Persons contribute skill, household help, risk, illness, or events
4. Weather, food, water, shelter, and field growth resolve
5. Local hex changes mark aggregate buckets dirty
6. Logs/UI explain the important changes
7. turn_number++
```

Movement across 10 m hexes is not the main cost. Time, labor, tools, weather, skill, terrain,
relationships, and institutions are the costs.

## Resources And Economics

Resources are not only inventory numbers. They are the material state of a holding.

```text
provisions, water, fuelwood, lumber, tools, seed, animals,
cash/debt, shelter, fields, reputation, claims, obligations
```

Economics should be built as flows:

```text
land + labor + skill + weather + tools -> production
production -> consumption + storage + trade + loss
trade/debt/obligation -> future constraints and opportunities
```

Markets should be scenario-dependent. A homesteader near a town, mission, fort, reservation,
railhead, river crossing, or trail should face different prices, access, risk, and politics.

## Skills And Technology

The game should not use a universal abstract tech tree. Progression is mostly:

- learned skill
- household capacity
- relationships and trust
- local knowledge
- reputation and standing
- access to institutions and markets

Technology spreads by scenario context, time, place, trade routes, institutions, migration,
neighbors, and capital. New tools should create tradeoffs: cost, maintenance, training,
dependence, debt, supply, or political exposure.

## Spatial Buckets (Not Hex Clusters)

The hierarchy is fixed spatial buckets over a single hex grid. Do not nest hex shapes inside hex
shapes.

| Level | Name | Size |
|---|---|---|
| L0 | hex | 10 m |
| L1 | patch | 100 m |
| L2 | block | 1 km |
| L3 | zone | 10 km |

At map generation, each hex gets permanent bucket IDs:

```text
hex.patch_id
hex.block_id
hex.zone_id
```

Each hex belongs to exactly one patch, one block, and one zone. IDs are saved with the map.

## Hex Simulation

Hexes are the authoritative terrain and local-state layer. All spread and local rules run on L0
hexes and neighbor hexes only. The hierarchy is not a propagation path.

Examples:

- fire, disease, forage depletion, water flow, road improvement, fence/building impact
- local ownership/claim effects
- vegetation, field, and structure state

## Aggregation

L1-L3 store derived summaries. After hex changes:

```text
changed hexes -> dirty patches -> dirty blocks -> dirty zones
```

End of tick:

```text
for each dirty patch: aggregate from hexes
for each dirty block: aggregate from patches
for each dirty zone: aggregate from blocks
clear dirty sets
```

Aggregation supports rendering and future regional reasoning. It does not replace L0 simulation.

## Rendering

One simulation map; multiple views.

| View | Source |
|---|---|
| Hex map | L0 hex state |
| Patch/block/zone map | aggregate cache |
| Terrain view | same L0 elevation and hex state, rendered as 3D mesh |

The renderer reads state. It does not simulate.

## Data Model Direction

```text
Hex:
  coords, elevation, terrain, water, vegetation, field, structure,
  claim/owner, work zones, patch_id, block_id, zone_id

Actor:
  id, controller, current_hex, holding_id, goals, action_policy

Person:
  id, household/agent, health, skills, traits, relationships, current_hex

Holding:
  id, owner_actor_id, home_hex, claimed_hexes, stores, structures,
  debt, reputation, obligations, legal_status

Scenario:
  id, date/place/persona, opening state, institutions, technology context,
  market access, political context, scenario rules
```

## Godot Components

| Component | Role |
|---|---|
| `GameState` | World state, resources, saves, scenario state |
| `TurnManager` | Turn number, day advancement, signals |
| `HexSim` | L0 map state |
| `AggregateCache` | Dirty patch/block/zone summaries |
| `MapRenderer` | 2D map render by zoom level |
| `TerrainView` | 3D terrain view from hex elevation |
| `WorkZone` | Multi-hex chore assignments |
| `PersonSystem` | Household/person contribution and seeded outcomes |
| `ScenarioCatalog` | Available scenario definitions |

Avoid: physics-driven gameplay, multiplayer, separate authored maps per zoom level, or a single
hardcoded campaign timeline.

## Decisions

- [ADR-0001 - Hex map via TileMapLayer](3-ENGINEERING/ADRs/0001-hex-map-tilemap-layer.md)
- [ADR-0002 - Turn-based, no physics](3-ENGINEERING/ADRs/0002-turn-based-no-physics.md)
- [ADR-0003 - TurnManager autoload](3-ENGINEERING/ADRs/0003-turn-manager-autoload.md)
- [ADR-0004 - Spatial buckets and entities](3-ENGINEERING/ADRs/0004-spatial-scales-and-entities.md)
- [ADR-0005 - Hex sim, aggregate cache, zoom render](3-ENGINEERING/ADRs/0005-sim-aggregate-render-split.md)

## Risks

- Historical systems can become shallow if modeled only as bonuses and penalties.
- AI agents need a constrained action model before they can feel plausible.
- The UI must explain resource changes without burying the player in ledger detail.
- Technology diffusion must stay scenario-aware, not become a generic unlock list.
