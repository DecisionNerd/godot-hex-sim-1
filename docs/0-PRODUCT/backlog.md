# Backlog

Prioritized product work queue. Pull from the top when choosing implementation work.

## Now - Make The Homestead Loop Legible

| # | Item | Why | Done when |
|---|---|---|---|
| 1 | **Resource explanation pass** | Players need to know why survival numbers change | UI/logs explain food, water, fuelwood, shelter, labor, and weather effects after each day |
| 2 | **Chore affordance polish** | Work zones are the main interaction | Click, box-select, assign, remove, and work-day flow are obvious without external docs |
| 3 | **Shelter/water survival rules** | Homestead survival needs more than food | Exposure and water access affect risk, with clear feedback and recoverable failure states |
| 4 | **Action failure reasons** | Plausibility requires constraints players can read | Failed chores name the missing condition: labor, terrain, season, resource, tool, or skill |
| 5 | **First-scenario tutorial log** | The first five minutes should explain the premise | Opening log frames Homestead Act settlement and the first survival priorities |

## Next - Basic Frontier Economy

| # | Item | Why | Done when |
|---|---|---|---|
| 6 | **General store model** | Trade turns surplus/shortage into strategy | Buy/sell prices and availability are scenario data, not hardcoded button behavior |
| 7 | **Cash/debt/obligation resource** | Frontier economics were not just barter | Player can take on or reduce simple obligations with consequences |
| 8 | **Storage and spoilage** | Surplus should be useful but fragile | Stored provisions can buffer seasons but can be lost or degraded |
| 9 | **Tool condition** | Technology should have maintenance cost | Tools improve work but can break, wear, or require money/materials |

## Then - Independent Agents

| # | Item | Why | Done when |
|---|---|---|---|
| 10 | **Neighbor holding AI needs** | Agents must feel like households, not markers | A neighbor has stores, labor, goals, and can assign chores |
| 11 | **Agent trade/help/conflict actions** | Politics starts with repeated local interaction | Player and AI can exchange goods/help or damage relations |
| 12 | **Reputation memory** | Choices need social consequences | Trust/conflict/favors persist and affect later options |
| 13 | **Agent failure states** | Plausible frontier life includes attrition | AI holdings can abandon, merge, sell out, relocate, or collapse |

## Later - Skills, Politics, And Technology

| # | Item | Why | Done when |
|---|---|---|---|
| 14 | **Skill model** | RPG growth should be grounded in labor and contact | Skills affect work speed/yield/risk and diplomacy without generic levels |
| 15 | **Technology availability model** | Tech should spread historically | Scenario date/place plus markets/institutions determine available tools |
| 16 | **Claims and local authority** | Homesteading is legal and political, not just farming | Land rules, officials, disputes, and standing affect what the player can do |
| 17 | **Cultural/contact systems** | Frontier politics require active communities | Language, mediation, trust, conflict, and institutions shape access and risk |

## Icebox

- Multiplayer
- Full military model
- Full continental economy
- Character-heavy scripted campaign
- High-fidelity historical reenactment

## Recently Shipped

- [x] GUT test suite
- [x] Homestead-era theme and scenario scaffold
- [x] Work zones and multi-hex chore assignment
- [x] Spatial buckets and aggregate renderer
- [x] 3D terrain side view
- [x] Box selection, rotation, zoom, and pan controls
