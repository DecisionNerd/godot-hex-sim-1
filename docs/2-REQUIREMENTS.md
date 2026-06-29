# Requirements

Status: **Done** | **Partial** | **Planned**.

## Scenario And Time

| ID | Requirement | Status |
|---|---|---|
| FR-SC1 | Game supports scenario definitions with id, title, place, persona, start year, opening log, and settlement title. | Partial |
| FR-SC2 | First scenario is a Homestead Act settlement focused on survival and claim-building. | Partial |
| FR-SC3 | Setting frame supports 1540-1890 without simulating the whole period as one continuous campaign. | Partial |
| FR-SC4 | Scenario date/place constrain technology, institutions, markets, crops, conflict, and politics. | Planned |
| FR-SC5 | Later scenarios can reuse agent/resource systems with different historical constraints. | Planned |

## Agents And Persons

| Kind | Behavior |
|---|---|
| **Actor** | Player or AI agent; explicit choices using the same action model |
| **Person** | Household or local individual with traits, skills, relationships, and seeded resolution |
| **Holding** | Land, structures, stores, obligations, and reputation attached to an agent or household |

At L0 scale (~10 m hex), a person can traverse hundreds of hexes per day. Walking can be shown
visually, but day-scale labor and opportunity cost are the gameplay.

| ID | Requirement | Status |
|---|---|---|
| FR-A1 | Player actor can select hexes and assign daily chores. | Done |
| FR-A2 | AI agents can eventually use the same chore/action model as the player. | Planned |
| FR-A3 | Persons contribute labor, skill, risk, health, and seeded daily outcomes. | Partial |
| FR-A4 | Same seed plus same inputs produces the same rolls. | Partial |
| FR-A5 | Agents can own or occupy holdings. | Partial |
| FR-A6 | Actions should explain why they failed: insufficient labor, unsuitable land, missing tools, missing skill, season, law, or relationship. | Planned |

## Survival And Resources

| ID | Requirement | Status |
|---|---|---|
| FR-RS1 | Track survival resources: provisions, water, fuelwood, lumber, tools, money, seed, shelter, and labor. | Partial |
| FR-RS2 | Weather, season, terrain, water access, vegetation, and shelter affect risk and productivity. | Partial |
| FR-RS3 | Households consume food and suffer consequences when food/shelter/water fail. | Partial |
| FR-RS4 | Work transforms land over time: gather, clear brush, haul water, set snares, build shelter, create fields. | Partial |
| FR-RS5 | Resource flows should be readable in the UI and logs. | Partial |
| FR-RS6 | Scarcity should create tradeoffs rather than busywork. | Planned |

## Economics

| ID | Requirement | Status |
|---|---|---|
| FR-E1 | Local trade supports buying and selling basic provisions and materials. | Partial |
| FR-E2 | Markets vary by scenario, distance, season, supply, demand, and technology access. | Planned |
| FR-E3 | Holdings can carry debt, obligations, taxes/fees, liens, wages, rent, or shared labor arrangements. | Planned |
| FR-E4 | Production should distinguish subsistence, surplus, storage, spoilage, and sale. | Planned |
| FR-E5 | AI agents can trade, compete, cooperate, or fail economically. | Planned |

## Politics, Law, And Reputation

| ID | Requirement | Status |
|---|---|---|
| FR-P1 | Claims, ownership, settlement rules, and local authority are scenario-specific. | Planned |
| FR-P2 | Reputation tracks trust, reliability, conflict, religious/community standing, and institutional relationships. | Planned |
| FR-P3 | Indigenous nations and communities are modeled as active political and social actors where relevant, not backdrop. | Planned |
| FR-P4 | Political pressure can appear through courts, agents, forts, churches, militias, territorial officials, traders, or neighbors. | Planned |
| FR-P5 | Player choices can change access to help, trade, information, protection, land, and conflict risk. | Planned |

## Skills And Technology

| ID | Requirement | Status |
|---|---|---|
| FR-ST1 | Progression is primarily skill acquisition, local knowledge, relationships, and household capacity. | Planned |
| FR-ST2 | Technology availability depends on scenario time/place and spreads through markets, institutions, migration, and contact. | Planned |
| FR-ST3 | Skills improve action reliability, speed, yield, risk handling, diplomacy, and information quality. | Planned |
| FR-ST4 | New tools and techniques should have costs, dependencies, and maintenance burdens. | Planned |
| FR-ST5 | The game should not use a universal abstract tech tree divorced from historical spread. | Planned |

## Spatial Buckets

One hex = **10 m**. L1-L3 are **fixed spatial buckets**, not nested hex clusters.

| Level | Size | Role |
|---|---|---|
| L0 hex | 10 m | Authoritative simulation |
| L1 patch | 100 m | Aggregate cache |
| L2 block | 1 km | Aggregate cache |
| L3 zone | 10 km | Aggregate cache |

| ID | Requirement | Status |
|---|---|---|
| FR-SP1 | One hex is about 10 m. | Done |
| FR-SP2 | At map generation, assign each hex `patch_id`, `block_id`, `zone_id`. | Done |
| FR-SP3 | L1-L3 are aggregates derived from children, not separately authored maps. | Done |
| FR-SP4 | Simulation runs on L0 hexes and neighbor hexes only. | Done |
| FR-SP5 | Dirty aggregate cache updates affected patch/block/zone data after hex changes. | Done |
| FR-SP6 | Render reads from hex state or aggregate cache, never simulates. | Done |

## Rendering And Input

| ID | Requirement | Status |
|---|---|---|
| FR-I1 | One simulation map supports hex, patch, block, zone, and terrain views. | Partial |
| FR-I2 | Player can rotate, zoom, pan, click-select, and box-select hexes. | Done |
| FR-I3 | Terrain side view is a 3D render sourced from the same hex elevation data. | Partial |
| FR-I4 | Controls should remain understandable when the map rotates. | Partial |

## Non-functional

| ID | Requirement |
|---|---|
| NFR-1 | Godot 4.7, desktop, offline |
| NFR-2 | Deterministic sim for reproducibility |
| NFR-3 | Keep the sim explainable: logs and UI should reveal cause and effect |
| NFR-4 | Prefer historically plausible constraints over generic abstraction |
| NFR-5 | Keep scope modular: scenario rules, agent logic, resources, and rendering should stay separable |
