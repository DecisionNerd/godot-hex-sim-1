# Roadmap

The roadmap grows from a playable homestead survival loop into a broader frontier-agent sim. Each
phase should leave the game playable; future systems should reuse the same agent, resource, and
scenario foundations.

## Phase 0 - Homestead Survival Foundation (mostly done)

- [x] Turn-based days, seasons, weather, and food consumption
- [x] American West framing and first Homestead Act scenario shell
- [x] Chores: gather, clear brush, haul water, trap, build shelter, field work
- [x] Household/person scaffold with deterministic behavior
- [x] Claims/holding expansion scaffold
- [x] Save/load and migration path
- [x] Hex map, spatial buckets, zoom renderer, and 3D terrain view
- [x] Box selection, rotation, zoom, and pan controls
- [ ] Better first-session explanation of why chores, resources, and survival outcomes change

## Phase 1 - Playable Frontier Logic

- [ ] Clarify resource ledger: provisions, water, fuelwood, lumber, tools, seed, cash
- [ ] Make shelter, water access, weather exposure, and field work easier to read
- [ ] Add basic market/trader flow with scenario-dependent prices and availability
- [ ] Add household health/risk outcomes tied to food, water, shelter, weather, and work
- [ ] Improve action failure messages: missing resource, unsuitable hex, season, labor, or skill
- [ ] Add simple events grounded in homestead life: illness, animal loss, tool breakage, storms,
  neighbors, debt, claim pressure

## Phase 2 - Independent Agents

- [ ] Give neighbor holdings goals, stores, labor, and survival needs
- [ ] Let AI agents choose chores using the same action model as the player
- [ ] Add trade, help, competition, conflict, and reputation effects between agents
- [ ] Store agent memory: trust, debt, favors, prior conflict, reliability
- [ ] Make agent failure possible: abandonment, sale, merger, death, relocation

## Phase 3 - Skills, Technology, And Institutions

- [ ] Add skills that affect action speed, yield, risk, information, and diplomacy
- [ ] Add technology availability by scenario time/place instead of a universal tech tree
- [ ] Model technology spread through markets, institutions, migration, and contact
- [ ] Add institutional hooks: land office, courts, church/community, military, traders, tribal
  authority, territorial/state government
- [ ] Add scenario-specific law/politics and reputation consequences

## Phase 4 - Richer Scenarios

- [ ] Deepen Homestead Act settlement with legal, economic, and social pressures
- [ ] Add scenarios from other periods in the 1540-1890 frame
- [ ] Support scenario-specific institutions, technology context, political relationships, and
  starting resources
- [ ] Add case-study-informed mechanics without turning the game into biography

## Not Now

- Multiplayer
- Full continental economy or grand-strategy war model
- Deterministic recreation of named historical events
- Unbounded tech-tree or RPG-system complexity before the homestead loop is readable
