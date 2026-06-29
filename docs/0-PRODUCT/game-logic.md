# Game Logic

This document describes the long-term simulation model. It is product direction, not a claim that
all systems are implemented today.

## Core Loop

The game is a daily frontier survival loop:

```text
survey land -> select work -> spend labor -> resolve day
    -> consume resources -> update land/holding -> reveal consequences
```

The player should always understand:

- what is scarce
- what work can be done
- why an action failed
- what changed at day end
- what future options improved or worsened

## Agent Model

An **agent** is any actor capable of pursuing goals: the player household, neighboring households,
traders, officials, community leaders, guides, or future AI factions.

Agents should share the same core action vocabulary:

| Action Family | Examples |
|---|---|
| Survival | gather, haul water, chop fuelwood, hunt/trap, rest, treat illness |
| Settlement | claim, clear, build shelter, fence, dig/improve water, plant fields |
| Economic | buy, sell, borrow, hire, lend, share labor, store, transport |
| Social | visit, ask help, offer help, mediate, threaten, negotiate, spread rumor |
| Political | file claim, contest claim, seek protection, appeal to authority, comply/resist |
| Learning | practice, travel, apprentice, observe, learn language/custom, maintain tools |

The player may choose actions directly. AI agents choose from the same families based on needs,
resources, skill, reputation, and scenario rules.

## Persons And Households

A household is more than one avatar. Persons carry the long-term RPG state:

```text
health, age, labor capacity, skills, relationships, morale,
language/cultural knowledge, reputation hooks, risk tolerance
```

Daily labor should come from persons and tools, not from an abstract action counter alone. A person
can become sick, injured, absent, exhausted, trusted, skilled, indebted, or alienated.

## Survival Resources

Resources should remain concrete and legible.

| Resource | Role |
|---|---|
| Provisions | Prevent hunger; can be gathered, grown, bought, traded, spoiled |
| Water | Daily need; constrains settlement, livestock, fields, illness risk |
| Fuelwood | Heat, cooking, winter survival, building support |
| Lumber | Structures, fences, storage, repairs |
| Tools | Work efficiency and enabled actions; wear and breakage matter |
| Seed | Future food, not just inventory |
| Cash | Market access, debt service, fees, wages, tools |
| Shelter | Exposure risk reduction and household stability |
| Labor | Daily capacity shaped by people, health, season, skill, and tools |
| Reputation | Access to help, information, trade, credit, protection, and risk |

Resource changes should be explainable in logs and UI. Avoid hidden survival math.

## Land And Holding

The holding is the strategic body of the player situation:

- home hex and claimed hexes
- shelter and structures
- water access
- fields and cleared land
- woodland/fuel access
- stored goods
- tools and animals
- obligations and disputes
- reputation and relationships

Land should improve slowly. Clearing, field creation, water access, fencing, storage, and shelter
are investments that trade present survival against future resilience.

## Economy

Economics should start local and material.

```text
production -> consumption/storage/trade
trade -> cash/debt/obligation/access
debt/obligation -> future pressure
```

Prices and availability should depend on scenario context:

- distance to store, town, fort, mission, reservation, river, trail, railhead
- season and weather
- local surplus/shortage
- reputation and credit
- technology spread
- conflict or political pressure

The economy should create decisions, not accounting busywork. If a number changes, the player
should know why it matters.

## Politics And Reputation

Frontier life is political because access is political: land, water, protection, credit,
information, trade, labor, and safety all pass through relationships and institutions.

Track reputation in concrete channels rather than one universal alignment score:

| Channel | Meaning |
|---|---|
| Trust | Will others help, trade, guide, warn, or believe the agent? |
| Reliability | Does the agent repay debts, finish bargains, show up, keep peace? |
| Conflict | Prior theft, violence, claim disputes, trespass, insults, betrayal |
| Institutional standing | Land office, court, church/community, military, territorial officials |
| Cultural competence | Language, custom, mediation, kinship/contact knowledge |

Political systems should be scenario-specific. A Homestead Act claim, a mission settlement, a
trading post, and an earlier Spanish frontier scenario should not use the same institutions.

## RPG Progression

Progression is mostly the improvement of a person or household's ability to act in a place.

Useful skill areas:

- farming and irrigation
- animal handling
- carpentry/building
- hunting/trapping
- medicine and care
- trade/accounting
- travel/navigation
- language and mediation
- law/claims
- diplomacy and local politics
- repair and tool use

Skills should affect concrete outcomes: action time, yield, accident risk, information quality,
trade terms, available choices, and social trust.

## Plausibility Rules

Use simplification, not fantasy abstraction.

- A tool should have a source, cost, maintenance burden, and plausible benefit.
- A political choice should affect some relationship or access path.
- A skill should be learned through work, contact, travel, mentorship, or repeated use.
- A historical institution should appear because the scenario needs it, not because every system
  needs a generic version.
- Indigenous nations and communities should be active agents when present in a scenario, not
  scenery or resource modifiers.

## Near-Term Implementation Boundary

For the first scenario, prioritize:

1. clear resource explanations
2. shelter/water/food survival consequences
3. readable chores and work zones
4. simple local trade
5. household health and labor variation
6. one neighbor or trader agent using a small subset of player actions

Do not build broad politics, full AI society, or deep technology systems until the homestead loop
is understandable and fun.
