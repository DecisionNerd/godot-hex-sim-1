# Scenarios

Scenarios are the way the game handles the 1540-1890 American West frame. The game should not run
one continuous 350-year household campaign. Instead, each scenario chooses a date, place, persona,
institutions, relationships, technology context, and starting material situation.

## Scenario Contract

A scenario should define:

```text
id
title
persona_label
place_name
start_year
opening_log
menu_blurb
settlement_title
initial resources
starting people/household
home or arrival location
institutions and law
market access
technology context
political relationships
scenario rules
win/loss/pressure conditions
```

The code already has a thin scenario resource/catalog shape. Future scenario data should grow
inside that pattern rather than scattering historical constants through gameplay code.

## First Scenario: Homestead Act Settlement

### Premise

The player household arrives in a western valley under a Homestead Act style settlement premise.
They need to survive, improve the claim, and turn scarce land, labor, tools, and relationships into
a viable holding.

### Core Pressures

- food and water
- shelter and exposure
- fuelwood and building material
- seed and fields
- tools and repair
- household health and labor
- cash/debt/credit
- weather and season
- claim legitimacy and local standing
- distance to market/help

### Early Loop

```text
arrive -> choose/confirm claim -> raise shelter -> secure water/fuel
      -> gather/trap/trade -> clear/field -> survive season -> expand capacity
```

### Institutions To Introduce Gradually

- land office / claim process
- store, trader, or supply route
- neighbors and reciprocal labor
- church/community pressure where relevant
- county or territorial officials
- indigenous communities and authorities where relevant to place/time
- militia, fort, or federal presence where relevant

### Failure Should Be Plausible

Failure does not need to mean instant death. It can mean:

- abandonment of claim
- sale under pressure
- death or illness
- debt spiral
- loss of tools/livestock/stores
- breakdown of relations
- legal/political displacement

## Later Scenario Directions

Later scenarios can reuse the same systems with different constraints.

| Scenario Type | What Changes |
|---|---|
| Spanish frontier outpost | Crown/church authority, mission/trade relations, different crops/tools/law |
| Trading post | Goods flow, credit, diplomacy, transport, reputation, language |
| Trail or migration camp | Mobility, logistics, illness, weather, route knowledge, group politics |
| Ranching settlement | Grazing, water rights, animals, market distance, conflict over range |
| Mission or mediation scenario | Language, trust, diplomacy, spiritual/political authority |
| Mining boom edge | Price spikes, labor instability, law, violence, supply shocks |

## Scenario Design Rules

- Start with material facts: place, season, water, food, tools, shelter, people.
- Define institutions before defining quests.
- Define technology availability by time/place.
- Use historical inspiration, not deterministic reenactment.
- Treat indigenous nations and communities as agents with interests and institutions.
- Avoid one-size-fits-all law, market, or politics systems.

## Scenario Data Should Drive

- available resources and store inventory
- starting skills and relationships
- available structures and tools
- legal constraints and claim rules
- market access and prices
- event decks or pressure tables
- AI agent goals and constraints
- technology spread and unlock conditions

## Open Design Questions

- How explicit should legal claim status be in the first playable loop?
- How much named historical specificity belongs in scenario text versus hidden rule context?
- Which first AI agent is most useful: neighbor household, trader, local official, or guide?
