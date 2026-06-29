# Mission

**Valley Claim** is a plausible frontier survival and settlement simulation. Independent agents
(human player or AI) live on the American frontier, work land, manage scarce resources, trade,
build reputation, learn skills, and try to improve their situation under changing historical
conditions.

The first scenario is a **Homestead Act settlement**: a household arrives in a western valley,
claims land, survives seasons, raises shelter, gathers water and food, clears brush, plants fields,
and slowly turns a claim into a viable holding.

The larger setting spans the American West from **1540-1890**. The game should use that breadth for
scenario context, technology diffusion, institutions, diplomacy, conflict, and cultural contact;
it should not treat 350 years as one continuous day-by-day campaign.

## Design Aim

The game is about surviving and building a situation on the frontier, not optimizing an abstract
empire. Geography, weather, distance, labor, debt, institutions, neighbors, law, and skill should
matter. Progress should feel earned and constrained by plausible material conditions.

## Core Ideas

- **Independent agents:** the player and AI agents use the same basic action model.
- **Survival first:** food, water, shelter, health, tools, labor, and weather create immediate
  pressure.
- **Resources and economics:** holdings produce, consume, trade, borrow, owe, and risk failure.
- **Politics and reputation:** agents deal with claims, neighbors, local authority, indigenous
  nations, traders, churches, militias, courts, and territorial/state institutions.
- **RPG progression:** growth is mostly skill, relationship, reputation, and household capacity,
  not a generic tech tree.
- **Technology spread:** new tools, crops, transport, weapons, communication, and institutions
  become available over time through markets, migration, institutions, and contact.
- **Plausibility over fantasy:** mechanics can be simplified, but should preserve realistic
  tradeoffs and avoid flattening history into generic frontier flavor.

## Current Playable Loop

One turn is one day. The implemented loop is: select hexes, assign chores, spend labor, end the
day, resolve weather, food, fields, and household survival. The map uses 10 m hexes with aggregate
patch/block/zone views and a 3D terrain view.

## Non-goals For The Near Term

- Real-time pathfinding or tile-by-tile walking as the core resource cost.
- Full military, state, or continental simulation.
- Multiplayer.
- Deterministic reenactment of named historical lives.
- Treating indigenous peoples, territorial politics, or violence as decorative background.

## Success

A player can understand the first homestead scenario without outside docs: what is threatening
the household, what work can be assigned, why resources change, and how today's choices improve or
damage future options. Future scenarios should reuse the same agent and resource logic while
changing context, institutions, and constraints.
